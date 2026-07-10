import 'package:am_player/repositories/audio_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audio playback snapshot retains the saved queue order', () {
    final snapshot = AudioPlaybackSnapshot.fromMap(
      {
        'asset_id': 'song-b',
        'position_ms': 42000,
        'shuffle_enabled': 1,
        'repeat_mode': 'one',
        'speed': 1.25,
        'was_playing': 0,
      },
      queueAssetIds: const ['song-c', 'song-b', 'song-a'],
    );

    expect(snapshot.assetId, 'song-b');
    expect(snapshot.position, const Duration(seconds: 42));
    expect(snapshot.queueAssetIds, ['song-c', 'song-b', 'song-a']);
    expect(snapshot.shuffleEnabled, isTrue);
    expect(snapshot.repeatMode, 'one');
    expect(snapshot.speed, 1.25);
    expect(snapshot.wasPlaying, isFalse);
  });
}
