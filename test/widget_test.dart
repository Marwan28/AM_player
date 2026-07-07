import 'package:am_player/models/video_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VideoItem exposes a clean display title without extension', () {
    const item = VideoItem(
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

    expect(item.displayTitle, 'Movie.Sample');
  });
}
