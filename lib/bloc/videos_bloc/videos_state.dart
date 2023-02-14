part of 'videos_bloc.dart';

@immutable
abstract class VideosState {}


class VideosLoadingState extends VideosState{}

class VideosLoadedState extends VideosState{}

class PlayingVideoState extends VideosState{}

class PausingVideoState extends VideosState{}

class StopingVideoState extends VideosState{}
