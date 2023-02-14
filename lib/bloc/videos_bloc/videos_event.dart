part of 'videos_bloc.dart';

@immutable
abstract class VideosEvent {}

class LoadVideosEvent extends VideosEvent{}

class PlayVideosEvent extends VideosEvent{}

class PauseVideosEvent extends VideosEvent{}

class StopVideosEvent extends VideosEvent{}
