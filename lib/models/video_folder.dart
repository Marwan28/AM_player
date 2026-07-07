import 'package:equatable/equatable.dart';

class VideoFolder extends Equatable {
  final String id;
  final String name;
  final int count;
  final String? coverAssetId;
  final int latestModifiedMs;

  const VideoFolder({
    required this.id,
    required this.name,
    required this.count,
    required this.coverAssetId,
    required this.latestModifiedMs,
  });

  factory VideoFolder.fromMap(Map<String, Object?> map) {
    return VideoFolder(
      id: map['folder_id'] as String,
      name: map['folder_name'] as String,
      count: (map['count'] as num).toInt(),
      coverAssetId: map['cover_asset_id'] as String?,
      latestModifiedMs: (map['latest_modified_ms'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        count,
        coverAssetId,
        latestModifiedMs,
      ];
}
