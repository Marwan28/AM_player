import 'dart:io';

import 'package:am_player/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class AudioLibraryRepository {
  static const _databaseName = 'am_player_audio.db';
  static const _databaseVersion = 2;
  static const _mediaStoreChannel = MethodChannel('am_player/media_store');
  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.ogg',
    '.opus',
    '.flac',
    '.amr',
    '.awb',
    '.wma',
    '.mid',
    '.midi',
    '.mka',
    '.3ga',
  };

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createAudioTracksTable(db);
        await _createAudioPlaybackStateTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE audio_playback_state '
            'ADD COLUMN was_playing INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );

    return _database!;
  }

  Future<List<Song>> loadSongs() async {
    final db = await _db;
    final rows = await db.query(
      'audio_tracks',
      orderBy: 'modified_ms DESC',
    );
    return rows.map(Song.fromMap).toList();
  }

  Future<void> syncDeviceAudio() async {
    final audioQuery = OnAudioQuery();
    final hasPermission = await _ensureAudioPermission(audioQuery);
    if (!hasPermission) {
      throw const AudioLibraryPermissionException();
    }

    final songsByPath = <String, Song>{};
    final pluginSongs = await _queryPluginAudio(audioQuery);
    final nativeSongs = await _queryNativeAudio();

    for (final song in [...pluginSongs, ...nativeSongs]) {
      songsByPath[_normalizePath(song.filePath)] = song;
    }

    var fileSystemSongs = <Song>[];
    if (songsByPath.isEmpty) {
      fileSystemSongs = await _scanFileSystemAudio();
      for (final song in fileSystemSongs) {
        songsByPath[_normalizePath(song.filePath)] = song;
      }
    }

    final songs = songsByPath.values.toList()
      ..sort((a, b) => b.modifiedMs.compareTo(a.modifiedMs));
    debugPrint(
      'AM audio sync: on_audio_query=${pluginSongs.length}, '
      'native=${nativeSongs.length}, files=${fileSystemSongs.length}, '
      'saved=${songs.length}',
    );
    final foundAssetIds = <String>{};

    for (final song in songs) {
      foundAssetIds.add(song.id);
    }

    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final song in songs) {
        batch.insert(
          'audio_tracks',
          song.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (foundAssetIds.isEmpty) {
        batch.delete('audio_tracks');
      } else {
        final placeholders = List.filled(foundAssetIds.length, '?').join(',');
        batch.delete(
          'audio_tracks',
          where: 'asset_id NOT IN ($placeholders)',
          whereArgs: foundAssetIds.toList(),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<bool> _ensureAudioPermission(OnAudioQuery audioQuery) async {
    if (await audioQuery.permissionsStatus()) return true;

    final audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted || audioStatus.isLimited) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted || storageStatus.isLimited) {
      return true;
    }

    return audioQuery.permissionsRequest();
  }

  Future<List<Song>> _queryPluginAudio(OnAudioQuery audioQuery) async {
    try {
      final queriedSongs = await audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      return [
        for (final queriedSong in queriedSongs)
          if (_isUsableAudioPath(queriedSong.data)) _songFromModel(queriedSong),
      ];
    } catch (error) {
      debugPrint('AM audio sync: on_audio_query failed: $error');
      return const [];
    }
  }

  Future<List<Song>> _queryNativeAudio() async {
    if (!Platform.isAndroid) return const [];

    try {
      final rawSongs = await _mediaStoreChannel.invokeListMethod<dynamic>(
        'queryAudio',
      );
      if (rawSongs == null || rawSongs.isEmpty) return const [];

      final songs = <Song>[];
      for (final rawSong in rawSongs) {
        if (rawSong is! Map) continue;
        final path = (rawSong['path'] as String? ?? '').trim();
        if (!_isUsableAudioPath(path)) continue;

        final folderId =
            (rawSong['folderId'] as String? ?? p.dirname(path)).trim();
        final folderName =
            (rawSong['folderName'] as String? ?? p.basename(folderId)).trim();
        final title = (rawSong['title'] as String? ?? '').trim();
        final uriText = (rawSong['uri'] as String? ?? '').trim();

        songs.add(
          Song(
            id: _stableAudioId(path),
            title: title.isEmpty ? p.basenameWithoutExtension(path) : title,
            filePath: path,
            uri: uriText.startsWith('content://')
                ? Uri.parse(uriText)
                : Uri.file(path),
            folderId: folderId.isEmpty ? p.dirname(path) : folderId,
            folderName: folderName.isEmpty ? 'Audio' : folderName,
            durationMs: _readInt(rawSong['durationMs']),
            modifiedMs: _readInt(rawSong['modifiedMs']),
            sizeBytes: _readInt(rawSong['sizeBytes']),
            artist: rawSong['artist'] as String?,
          ),
        );
      }
      return songs;
    } catch (error) {
      debugPrint('AM audio sync: native MediaStore failed: $error');
      return const [];
    }
  }

  Future<List<Song>> _scanFileSystemAudio() async {
    if (!Platform.isAndroid) return const [];

    final roots = <String>{
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Notifications',
      '/storage/emulated/0/Ringtones',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Audiobooks',
      '/storage/emulated/0/WhatsApp',
      '/storage/emulated/0/Telegram',
      '/storage/emulated/0/Android/media',
    };
    final songs = <Song>[];

    for (final root in roots) {
      final directory = Directory(root);
      if (!await directory.exists()) continue;

      try {
        await for (final entity in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File || !_isUsableAudioPath(entity.path)) continue;
          final stat = await entity.stat();
          songs.add(_songFromFile(entity, stat));
        }
      } catch (error) {
        debugPrint('AM audio sync: scan skipped $root: $error');
      }
    }

    return songs;
  }

  Future<AudioPlaybackSnapshot?> loadPlaybackSnapshot() async {
    final db = await _db;
    final rows = await db.query(
      'audio_playback_state',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AudioPlaybackSnapshot.fromMap(rows.first);
  }

  Future<void> savePlaybackSnapshot({
    required String? assetId,
    required Duration position,
    required bool shuffleEnabled,
    required String repeatMode,
    required double speed,
    required bool wasPlaying,
  }) async {
    final db = await _db;
    await db.insert(
      'audio_playback_state',
      {
        'id': 1,
        'asset_id': assetId,
        'position_ms': position.inMilliseconds,
        'shuffle_enabled': shuffleEnabled ? 1 : 0,
        'repeat_mode': repeatMode,
        'speed': speed,
        'was_playing': wasPlaying ? 1 : 0,
        'updated_ms': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Song _songFromModel(SongModel model) {
    final path = model.data;
    final folderPath = p.dirname(path);
    final folderName = p.basename(folderPath);
    final dateModified = model.dateModified ?? model.dateAdded ?? 0;
    final title = model.title.trim().isNotEmpty
        ? model.title
        : model.displayNameWOExt.trim().isNotEmpty
            ? model.displayNameWOExt
            : p.basenameWithoutExtension(path);

    return Song(
      id: _stableAudioId(path),
      title: title,
      filePath: path,
      uri: Uri.file(path),
      folderId: folderPath,
      folderName: folderName.isEmpty ? 'Audio' : folderName,
      durationMs: model.duration ?? 0,
      modifiedMs: dateModified * 1000,
      sizeBytes: model.size,
      artist: model.artist,
    );
  }

  Song _songFromFile(File file, FileStat stat) {
    final path = file.path;
    final folderPath = p.dirname(path);
    final folderName = p.basename(folderPath);
    final title = p.basenameWithoutExtension(path);

    return Song(
      id: _stableAudioId(path),
      title: title,
      filePath: path,
      uri: Uri.file(path),
      folderId: folderPath,
      folderName: folderName.isEmpty ? 'Audio' : folderName,
      durationMs: 0,
      modifiedMs: stat.modified.millisecondsSinceEpoch,
      sizeBytes: stat.size,
    );
  }

  bool _isUsableAudioPath(String path) {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) return false;

    final normalized = cleanPath.replaceAll('\\', '/').toLowerCase();
    if (normalized.contains('/android/data/')) return false;
    if (p.basename(normalized).startsWith('._')) return false;

    return _audioExtensions.contains(p.extension(normalized));
  }

  String _normalizePath(String path) {
    return path.trim().replaceAll('\\', '/').toLowerCase();
  }

  String _stableAudioId(String path) {
    return 'audio:${_normalizePath(path)}';
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _createAudioTracksTable(Database db) async {
    await db.execute('''
      CREATE TABLE audio_tracks (
        asset_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        path TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        folder_name TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        modified_ms INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL,
        artist TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_audio_tracks_folder ON audio_tracks(folder_id, title)',
    );
    await db.execute(
      'CREATE INDEX idx_audio_tracks_modified ON audio_tracks(modified_ms DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_audio_tracks_title ON audio_tracks(title COLLATE NOCASE)',
    );
  }

  Future<void> _createAudioPlaybackStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE audio_playback_state (
        id INTEGER PRIMARY KEY,
        asset_id TEXT,
        position_ms INTEGER NOT NULL,
        shuffle_enabled INTEGER NOT NULL,
        repeat_mode TEXT NOT NULL,
        speed REAL NOT NULL,
        was_playing INTEGER NOT NULL DEFAULT 0,
        updated_ms INTEGER NOT NULL
      )
    ''');
  }
}

class AudioPlaybackSnapshot {
  final String? assetId;
  final Duration position;
  final bool shuffleEnabled;
  final String repeatMode;
  final double speed;
  final bool wasPlaying;

  const AudioPlaybackSnapshot({
    required this.assetId,
    required this.position,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.speed,
    required this.wasPlaying,
  });

  factory AudioPlaybackSnapshot.fromMap(Map<String, Object?> map) {
    return AudioPlaybackSnapshot(
      assetId: map['asset_id'] as String?,
      position: Duration(
        milliseconds: (map['position_ms'] as num?)?.toInt() ?? 0,
      ),
      shuffleEnabled: ((map['shuffle_enabled'] as num?)?.toInt() ?? 0) == 1,
      repeatMode: map['repeat_mode'] as String? ?? 'all',
      speed: (map['speed'] as num?)?.toDouble() ?? 1,
      wasPlaying: ((map['was_playing'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}

class AudioLibraryPermissionException implements Exception {
  const AudioLibraryPermissionException();
}
