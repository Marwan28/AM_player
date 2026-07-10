import 'package:am_player/models/video_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const landscapeVideo = VideoItem(
    assetId: '1',
    title: 'Movie.Sample.mp4',
    path: '/storage/emulated/0/Movies/Movie.Sample.mp4',
    folderId: 'movies',
    folderName: 'Movies',
    durationMs: 1000,
    modifiedMs: 1000,
    width: 1920,
    height: 1080,
    sizeBytes: 1024,
  );

  test('VideoItem exposes a clean display title without extension', () {
    expect(landscapeVideo.displayTitle, 'Movie.Sample');
  });

  test('VideoItem uses the short edge for resolution labels', () {
    expect(landscapeVideo.resolutionLabel, '1080p');

    const portrait4k = VideoItem(
      assetId: '1',
      title: 'Portrait.mp4',
      path: '/storage/emulated/0/Movies/Portrait.mp4',
      folderId: 'movies',
      folderName: 'Movies',
      durationMs: 1000,
      modifiedMs: 1000,
      width: 2160,
      height: 3840,
      sizeBytes: 1024,
    );
    expect(portrait4k.resolutionLabel, '4K');
  });

  test('VideoItem reports unknown resolution when metadata is missing', () {
    const item = VideoItem(
      assetId: '2',
      title: 'Unknown',
      path: '/storage/emulated/0/Movies/Unknown',
      folderId: 'movies',
      folderName: 'Movies',
      durationMs: 0,
      modifiedMs: 0,
      width: 0,
      height: 0,
      sizeBytes: 0,
    );

    expect(item.resolutionLabel, 'Unknown');
  });
}
