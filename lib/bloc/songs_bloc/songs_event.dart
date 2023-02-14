part of 'songs_bloc.dart';

@immutable
abstract class SongsEvent {}


class PlaySongEvent extends SongsEvent{
  final Song song;

  PlaySongEvent(this.song);
}

class LoadSongsEvent extends SongsEvent{}

class StopSongEvent extends SongsEvent{}

class PauseSongEvent extends SongsEvent{}

