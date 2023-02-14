part of 'songs_bloc.dart';

@immutable
abstract class SongsState {}

class SongsInitial extends SongsState {}

class SongsLoadingState extends SongsState{}

class SongsLoadedState extends SongsState{}

class PlayingSongState extends SongsState{}

class PausingSongState extends SongsState{}

class StopingSongState extends SongsState{}
