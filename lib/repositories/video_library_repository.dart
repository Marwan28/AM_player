import 'dart:io';

import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';

class VideoLibraryRepository {
  static const _databaseName = 'am_player_media.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
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
      },
    );

    return _database!;
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
      ORDER BY folder_name COLLATE NOCASE ASC
    ''');
    return rows.map(VideoFolder.fromMap).toList();
  }

  Future<List<VideoItem>> loadVideosInFolder(String folderId) async {
    final db = await _db;
    final rows = await db.query(
      'videos',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(VideoItem.fromMap).toList();
  }

  Future<void> syncDeviceVideos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      throw const VideoLibraryPermissionException();
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: false,
    );
    final foundAssetIds = <String>{};
    final videos = <VideoItem>[];

    for (final album in albums) {
      final count = await album.assetCountAsync;
      const pageSize = 120;

      for (var page = 0; page * pageSize < count; page++) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );

        for (final asset in assets) {
          final file = await asset.file;
          if (file == null) continue;

          final item = await _videoItemFromAsset(
            asset: asset,
            album: album,
            file: file,
          );
          foundAssetIds.add(item.assetId);
          videos.add(item);
        }
      }
    }

    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in videos) {
        batch.insert(
          'videos',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (foundAssetIds.isEmpty) {
        batch.delete('videos');
      } else {
        final placeholders = List.filled(foundAssetIds.length, '?').join(',');
        batch.delete(
          'videos',
          where: 'asset_id NOT IN ($placeholders)',
          whereArgs: foundAssetIds.toList(),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> renameVideo({
    required VideoItem item,
    required String newBaseName,
  }) async {
    final extension = p.extension(item.path);
    final cleanName = newBaseName.trim();
    if (cleanName.isEmpty) return;

    final newPath = p.join(p.dirname(item.path), '$cleanName$extension');
    final renamed = await File(item.path).rename(newPath);
    final db = await _db;
    await db.update(
      'videos',
      {
        'title': p.basename(renamed.path),
        'path': renamed.path,
        'modified_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'asset_id = ?',
      whereArgs: [item.assetId],
    );
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
}

class VideoLibraryPermissionException implements Exception {
  const VideoLibraryPermissionException();
}
