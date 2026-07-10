import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class VideoItem extends Equatable {
  final String assetId;
  final String title;
  final String path;
  final String folderId;
  final String folderName;
  final int durationMs;
  final int modifiedMs;
  final int width;
  final int height;
  final int sizeBytes;

  const VideoItem({
    required this.assetId,
    required this.title,
    required this.path,
    required this.folderId,
    required this.folderName,
    required this.durationMs,
    required this.modifiedMs,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  String get displayTitle {
    final dotIndex = title.lastIndexOf('.');
    if (dotIndex <= 0) return title;
    return title.substring(0, dotIndex);
  }

  Duration get duration => Duration(milliseconds: durationMs);

  String get resolutionLabel {
    final shortEdge = math.min(width, height);
    if (shortEdge >= 2160) return '4K';
    if (shortEdge >= 1440) return '1440p';
    if (shortEdge >= 1080) return '1080p';
    if (shortEdge >= 720) return '720p';
    if (shortEdge > 0) return '${shortEdge}p';
    return 'Unknown';
  }

  Map<String, Object?> toMap() {
    return {
      'asset_id': assetId,
      'title': title,
      'path': path,
      'folder_id': folderId,
      'folder_name': folderName,
      'duration_ms': durationMs,
      'modified_ms': modifiedMs,
      'width': width,
      'height': height,
      'size_bytes': sizeBytes,
    };
  }

  factory VideoItem.fromMap(Map<String, Object?> map) {
    return VideoItem(
      assetId: map['asset_id'] as String,
      title: map['title'] as String,
      path: map['path'] as String,
      folderId: map['folder_id'] as String,
      folderName: map['folder_name'] as String,
      durationMs: (map['duration_ms'] as num).toInt(),
      modifiedMs: (map['modified_ms'] as num).toInt(),
      width: (map['width'] as num).toInt(),
      height: (map['height'] as num).toInt(),
      sizeBytes: (map['size_bytes'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [
        assetId,
        title,
        path,
        folderId,
        folderName,
        durationMs,
        modifiedMs,
        width,
        height,
        sizeBytes,
      ];
}
