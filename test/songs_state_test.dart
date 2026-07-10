import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final songs = [
    _song(
      id: 'whatsapp',
      title: 'Voice note',
      path:
          '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Voice Notes/note.opus',
      folderId: 'wa',
      folderName: 'WhatsApp Voice Notes',
      durationMs: 9000,
      modifiedMs: 400,
      sizeBytes: 4000,
    ),
    _song(
      id: 'beta',
      title: 'Beta',
      path: '/storage/emulated/0/Music/Beta.mp3',
      folderId: 'music',
      folderName: 'Music',
      durationMs: 3000,
      modifiedMs: 300,
      sizeBytes: 3000,
      artist: 'Second Artist',
    ),
    _song(
      id: 'alpha',
      title: 'alpha',
      path: '/storage/emulated/0/Download/alpha.mp3',
      folderId: 'downloads',
      folderName: 'Downloads',
      durationMs: 5000,
      modifiedMs: 100,
      sizeBytes: 1000,
      artist: 'First Artist',
    ),
  ];

  test('combined song list excludes WhatsApp audio', () {
    final state = _state(songs: songs);

    expect(state.visibleSongs.map((song) => song.id), ['alpha', 'beta']);
    expect(state.visibleFolderSongs.map((song) => song.id), [
      'alpha',
      'beta',
      'whatsapp',
    ]);
    expect(state.visibleFolderCount, 3);
  });

  test('search matches title, artist, and folder', () {
    expect(
      _state(songs: songs, query: 'beta').visibleSongs.single.id,
      'beta',
    );
    expect(
      _state(songs: songs, query: 'first artist').visibleSongs.single.id,
      'alpha',
    );
    expect(
      _state(songs: songs, query: 'downloads').visibleSongs.single.id,
      'alpha',
    );
  });

  test('song sort modes order the visible list correctly', () {
    expect(
      _state(songs: songs, sortMode: AudioSortMode.dateDesc)
          .visibleSongs
          .map((song) => song.id),
      ['beta', 'alpha'],
    );
    expect(
      _state(songs: songs, sortMode: AudioSortMode.durationDesc)
          .visibleSongs
          .map((song) => song.id),
      ['alpha', 'beta'],
    );
    expect(
      _state(songs: songs, sortMode: AudioSortMode.sizeDesc)
          .visibleSongs
          .map((song) => song.id),
      ['beta', 'alpha'],
    );
  });
}

SongsState _state({
  required List<Song> songs,
  String query = '',
  AudioSortMode sortMode = AudioSortMode.titleAsc,
}) {
  return SongsState(
    isLoading: false,
    isSyncing: false,
    permissionDenied: false,
    songs: songs,
    query: query,
    sortMode: sortMode,
    errorMessage: null,
  );
}

Song _song({
  required String id,
  required String title,
  required String path,
  required String folderId,
  required String folderName,
  required int durationMs,
  required int modifiedMs,
  required int sizeBytes,
  String? artist,
}) {
  return Song(
    id: id,
    title: title,
    filePath: path,
    uri: Uri.file(path),
    folderId: folderId,
    folderName: folderName,
    durationMs: durationMs,
    modifiedMs: modifiedMs,
    sizeBytes: sizeBytes,
    artist: artist,
  );
}
