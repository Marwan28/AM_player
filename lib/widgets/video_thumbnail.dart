import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoThumbnail extends StatelessWidget {
  final String? assetId;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const VideoThumbnail({
    super.key,
    required this.assetId,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (assetId == null) {
      return _fallback();
    }

    return FutureBuilder<Uint8List?>(
      future: _loadThumbnail(assetId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _fallback();
        }

        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            snapshot.data!,
            fit: fit,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _loadThumbnail(String id) async {
    final entity = await AssetEntity.fromId(id);
    return entity?.thumbnailDataWithSize(
      const ThumbnailSize(360, 220),
      quality: 72,
    );
  }

  Widget _fallback() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: const Color(0xFF202124),
        alignment: Alignment.center,
        child: const Icon(
          Icons.movie_outlined,
          color: Colors.white70,
          size: 36,
        ),
      ),
    );
  }
}
