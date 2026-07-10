import 'dart:io';

import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class VideoLibraryRepository {
  static const _databaseName = 'am_player_media.db';
  static const _databaseVersion = 4;
  static const _mediaStoreChannel = MethodChannel('am_player/media_store');
  static const _videoSignatureKey = 'video_library_signature';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createVideosTable(db);
        await _createPlaybackPositionsTable(db);
        await _createLibraryMetadataTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPlaybackPositionsTable(db);
        }
        if (oldVersion < 3) {
          await _createLibraryMetadataTable(db);
        }
        if (oldVersion < 4) {
          await _createVideoPerformanceIndexes(db);
        }
      },
    );

    return _database!;
  }

  Future<Duration> loadPlaybackPosition(String assetId) async {
    final db = await _db;
    final rows = await db.query(
      'video_playback_positions',
      columns: ['position_ms'],
      where: 'asset_id = ?',
      whereArgs: [assetId],
      limit: 1,
    );
    if (rows.isEmpty) return Duration.zero;
    return Duration(milliseconds: (rows.first['position_ms'] as num).toInt());
  }

  Future<void> savePlaybackPosition({
    required String assetId,
    required Duration position,
    required Duration duration,
  }) async {
    final durationMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds;

    final shouldClear = durationMs > 0 && positionMs > durationMs - 5000;
    if (shouldClear || positionMs < 1000) {
      await clearPlaybackPosition(assetId);
      return;
    }

    final db = await _db;
    await db.insert(
      'video_playback_positions',
      {
        'asset_id': assetId,
        'position_ms': positionMs,
        'duration_ms': durationMs,
        'updated_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearPlaybackPosition(String assetId) async {
    final db = await _db;
    await db.delete(
      'video_playback_positions',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }

  Future<List<VideoFolder>> loadFolders() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        folder_id,
        folder_name,
        COUNT(*) AS count,
        (
          SELECT asset_id
          FROM videos v2
          WHERE v2.folder_id = videos.folder_id
          ORDER BY modified_ms DESC
          LIMIT 1
        ) AS cover_asset_id,
        MAX(modified_ms) AS latest_modified_ms
      FROM videos
      GROUP BY folder_id, folder_name
      ORDER BY latest_modified_ms DESC
    ''');
    return rows.map(VideoFolder.fromMap).toList();
  }

  Future<List<VideoItem>> loadVideosInFolder(String folderId) async {
    final db = await _db;
    final rows = await db.query(
      'videos',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'modified_ms DESC',
    );
    return rows.map(VideoItem.fromMap).toList();
  }

  Future<bool> syncDeviceVideos({bool force = false}) async {
    final hasPermission = await _ensureVideoPermission();
    if (!hasPermission) {
      throw const VideoLibraryPermissionException();
    }
    PhotoManager.setIgnorePermissionCheck(true);

    final db = await _db;
    final signature = await _queryVideoLibrarySignature();
    if (!force && signature != null) {
      final savedSignature = await _loadLibraryMetadata(
        db,
        _videoSignatureKey,
      );
      if (savedSignature == signature) return false;
    } else if (!force && signature == null && await _hasCachedVideos(db)) {
      return false;
    }

    final videos =
        await _queryNativeVideos() ?? await _queryPhotoManagerVideos();

    return db.transaction<bool>((txn) async {
      var changed = false;
      final existingRows = await txn.query('videos');
      final existingById = <String, Map<String, Object?>>{
        for (final row in existingRows) row['asset_id'] as String: row,
      };
      final batch = txn.batch();
      for (final item in videos) {
        final itemMap = item.toMap();
        final existing = existingById.remove(item.assetId);
        if (existing == null || !_storedRowMatches(existing, itemMap)) {
          changed = true;
          batch.insert(
            'videos',
            itemMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      for (final staleAssetId in existingById.keys) {
        changed = true;
        batch.delete(
          'videos',
          where: 'asset_id = ?',
          whereArgs: [staleAssetId],
        );
      }
      if (signature != null) {
        batch.insert(
          'library_metadata',
          {'key': _videoSignatureKey, 'value': signature},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return changed;
    });
  }

  Future<void> deleteVideo(VideoItem item) async {
    final deletedIds = await PhotoManager.editor.deleteWithIds([item.assetId]);
    if (!deletedIds.contains(item.assetId)) {
      throw const VideoDeleteException();
    }

    final db = await _db;
    await db.delete(
      'videos',
      where: 'asset_id = ?',
      whereArgs: [item.assetId],
    );
    await clearPlaybackPosition(item.assetId);
  }

  Future<bool> _ensureVideoPermission() async {
    if (!Platform.isAndroid) {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      return permission.hasAccess;
    }

    var status = await Permission.videos.status;
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.videos.request();
    }
    if (status.isGranted || status.isLimited) return true;

    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted && !storageStatus.isLimited) {
      storageStatus = await Permission.storage.request();
    }
    return storageStatus.isGranted || storageStatus.isLimited;
  }

  Future<String?> _queryVideoLibrarySignature() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _mediaStoreChannel.invokeMethod<String>(
        'videoLibrarySignature',
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<VideoItem>?> _queryNativeVideos() async {
    if (!Platform.isAndroid) return null;
    try {
      final rawVideos = await _mediaStoreChannel.invokeListMethod<dynamic>(
        'queryVideos',
      );
      if (rawVideos == null) return null;

      final videos = <VideoItem>[];
      for (final rawVideo in rawVideos) {
        if (rawVideo is! Map) continue;
        final assetId = (rawVideo['assetId'] as String? ?? '').trim();
        final path = (rawVideo['path'] as String? ?? '').trim();
        if (assetId.isEmpty || path.isEmpty) continue;
        final folderId =
            (rawVideo['folderId'] as String? ?? p.dirname(path)).trim();
        final folderName =
            (rawVideo['folderName'] as String? ?? p.basename(folderId)).trim();
        final title = (rawVideo['title'] as String? ?? '').trim();

        videos.add(
          VideoItem(
            assetId: assetId,
            title: title.isEmpty ? p.basename(path) : title,
            path: path,
            folderId: folderId.isEmpty ? 'Videos' : folderId,
            folderName: folderName.isEmpty ? 'Videos' : folderName,
            durationMs: _readInt(rawVideo['durationMs']),
            modifiedMs: _readInt(rawVideo['modifiedMs']),
            width: _readInt(rawVideo['width']),
            height: _readInt(rawVideo['height']),
            sizeBytes: _readInt(rawVideo['sizeBytes']),
          ),
        );
      }
      return videos;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<VideoItem>> _queryPhotoManagerVideos() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: false,
    );
    final videos = <VideoItem>[];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      const pageSize = 120;

      for (var page = 0; page * pageSize < count; page++) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        videos.addAll(await _loadVideoPage(assets, album));
      }
    }
    return videos;
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<String?> _loadLibraryMetadata(Database db, String key) async {
    final rows = await db.query(
      'library_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<bool> _hasCachedVideos(Database db) async {
    final rows = await db.rawQuery('SELECT COUNT(*) FROM videos');
    return (Sqflite.firstIntValue(rows) ?? 0) > 0;
  }

  bool _storedRowMatches(
    Map<String, Object?> stored,
    Map<String, Object?> current,
  ) {
    for (final entry in current.entries) {
      if (stored[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<VideoItem> _videoItemFromAsset({
    required AssetEntity asset,
    required AssetPathEntity album,
    required File file,
  }) async {
    final stat = await file.stat();
    final title = asset.title ?? p.basename(file.path);
    final modifiedMs = (asset.modifiedDateSecond ?? 0) > 0
        ? asset.modifiedDateSecond! * 1000
        : stat.modified.millisecondsSinceEpoch;

    return VideoItem(
      assetId: asset.id,
      title: title,
      path: file.path,
      folderId: album.id,
      folderName: album.name,
      durationMs: asset.videoDuration.inMilliseconds,
      modifiedMs: modifiedMs,
      width: asset.orientatedWidth,
      height: asset.orientatedHeight,
      sizeBytes: stat.size,
    );
  }

  Future<List<VideoItem>> _loadVideoPage(
    List<AssetEntity> assets,
    AssetPathEntity album,
  ) async {
    const concurrency = 8;
    final items = <VideoItem>[];

    for (var start = 0; start < assets.length; start += concurrency) {
      final end = start + concurrency < assets.length
          ? start + concurrency
          : assets.length;
      final chunk = assets.sublist(start, end);
      final loaded = await Future.wait([
        for (final asset in chunk) _loadVideoItem(asset, album),
      ]);
      for (final item in loaded) {
        if (item != null) items.add(item);
      }
    }

    return items;
  }

  Future<VideoItem?> _loadVideoItem(
    AssetEntity asset,
    AssetPathEntity album,
  ) async {
    final file = await asset.file;
    if (file == null) return null;
    return _videoItemFromAsset(asset: asset, album: album, file: file);
  }

  Future<void> _createVideosTable(Database db) async {
    await db.execute('''
      CREATE TABLE videos (
        asset_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        path TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        folder_name TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        modified_ms INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_videos_folder ON videos(folder_id, title)',
    );
    await db.execute(
      'CREATE INDEX idx_videos_modified ON videos(modified_ms DESC)',
    );
    await _createVideoPerformanceIndexes(db);
  }

  Future<void> _createVideoPerformanceIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_videos_folder_modified '
      'ON videos(folder_id, modified_ms DESC)',
    );
  }

  Future<void> _createPlaybackPositionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS video_playback_positions (
        asset_id TEXT PRIMARY KEY,
        position_ms INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        updated_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createLibraryMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS library_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}

class VideoLibraryPermissionException implements Exception {
  const VideoLibraryPermissionException();
}

class VideoDeleteException implements Exception {
  const VideoDeleteException();
}
