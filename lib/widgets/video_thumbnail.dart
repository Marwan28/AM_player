import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoThumbnail extends StatefulWidget {
  final String? assetId;
  final int cacheVersion;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const VideoThumbnail({
    super.key,
    required this.assetId,
    this.cacheVersion = 0,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  Future<Uint8List?>? _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _futureFor(widget.assetId);
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _thumbnail = _futureFor(widget.assetId);
    } else if (oldWidget.cacheVersion != widget.cacheVersion) {
      _thumbnail = _futureFor(widget.assetId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetId == null) {
      return _fallback();
    }

    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _fallback();
        }

        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => _fallbackContent(),
          ),
        );
      },
    );
  }

  Future<Uint8List?>? _futureFor(String? assetId) {
    return assetId == null
        ? null
        : VideoThumbnailCache.load(
            assetId,
            version: widget.cacheVersion,
          );
  }

  Widget _fallback() {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: _fallbackContent(),
    );
  }

  Widget _fallbackContent() {
    return Container(
      color: const Color(0xFF202124),
      alignment: Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        color: Colors.white70,
        size: 36,
      ),
    );
  }
}

class VideoThumbnailCache {
  static const int _maxEntries = 120;
  static final LinkedHashMap<String, Future<Uint8List?>> _entries =
      LinkedHashMap<String, Future<Uint8List?>>();

  static Future<Uint8List?> load(String assetId, {int version = 0}) {
    final key = '$assetId:$version';
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }

    final future = _loadThumbnail(assetId);
    _entries[key] = future;
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    future.then((data) {
      if (data == null && identical(_entries[key], future)) {
        _entries.remove(key);
      }
    });
    return future;
  }

  static void clear() => _entries.clear();

  static Future<Uint8List?> _loadThumbnail(String id) async {
    try {
      final entity = await AssetEntity.fromId(id);
      final data = await entity?.thumbnailDataWithSize(
        const ThumbnailSize(400, 240),
        quality: 72,
      );
      return data == null || data.isEmpty ? null : data;
    } catch (_) {
      return null;
    }
  }
}
