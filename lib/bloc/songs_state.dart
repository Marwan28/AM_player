part of 'songs_bloc.dart';

@immutable
abstract class SongsState {}

class SongsInitial extends SongsState {}

class SongsLoadingState extends SongsState{}

class SongsLoadedState extends SongsState{}

class PlayingSongState extends SongsState{}

class PauseSongState extends SongsState{}

class StopSongState extends SongsState{}
