import 'package:path/path.dart' as p;

class Song {
  final String id;
  final String title;
  final String filePath;
  final Uri uri;
  final String folderId;
  final String folderName;
  final int durationMs;
  final int modifiedMs;
  final int sizeBytes;
  final String? artist;

  const Song({
    required this.id,
    required this.title,
    required this.filePath,
    required this.uri,
    required this.folderId,
    required this.folderName,
    required this.durationMs,
    required this.modifiedMs,
    required this.sizeBytes,
    this.artist,
  });

  factory Song.fromMap(Map<String, Object?> map) {
    final path = map['path'] as String;
    return Song(
      id: map['asset_id'] as String,
      title: map['title'] as String,
      filePath: path,
      uri: path.startsWith('content://') ? Uri.parse(path) : Uri.file(path),
      folderId: map['folder_id'] as String,
      folderName: map['folder_name'] as String,
      durationMs: (map['duration_ms'] as num).toInt(),
      modifiedMs: (map['modified_ms'] as num).toInt(),
      sizeBytes: (map['size_bytes'] as num).toInt(),
      artist: map['artist'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'asset_id': id,
      'title': title,
      'path': filePath,
      'folder_id': folderId,
      'folder_name': folderName,
      'duration_ms': durationMs,
      'modified_ms': modifiedMs,
      'size_bytes': sizeBytes,
      'artist': artist,
    };
  }

  Duration get duration => Duration(milliseconds: durationMs);

  String get displayTitle {
    final clean = title.trim();
    if (clean.isNotEmpty) return clean;
    return p.basenameWithoutExtension(filePath);
  }

  String get subtitle {
    final artistName = artist?.trim();
    if (artistName != null && artistName.isNotEmpty) {
      return '$artistName - $folderName';
    }
    return folderName;
  }
}
