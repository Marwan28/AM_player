part of 'songs_bloc.dart';

@immutable
abstract class SongsEvent {
  const SongsEvent();
}

class LoadSongsEvent extends SongsEvent {
  final bool refresh;
  final bool syncIfEmpty;

  const LoadSongsEvent({
    this.refresh = false,
    this.syncIfEmpty = true,
  });
}

class SearchSongsEvent extends SongsEvent {
  final String query;

  const SearchSongsEvent(this.query);
}

class ChangeAudioSortEvent extends SongsEvent {
  final AudioSortMode sortMode;

  const ChangeAudioSortEvent(this.sortMode);
}

class PlaySongEvent extends SongsEvent {
  final Song song;
  final List<Song> queue;

  const PlaySongEvent({
    required this.song,
    required this.queue,
  });
}

class ShuffleSongsEvent extends SongsEvent {
  final List<Song> queue;

  const ShuffleSongsEvent(this.queue);
}
