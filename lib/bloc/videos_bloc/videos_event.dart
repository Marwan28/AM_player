part of 'videos_bloc.dart';

abstract class VideosEvent extends Equatable {
  const VideosEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideosEvent extends VideosEvent {
  const LoadVideosEvent();
}

class RefreshVideosEvent extends VideosEvent {
  const RefreshVideosEvent();
}

class OpenVideoFolderEvent extends VideosEvent {
  final String folderId;

  const OpenVideoFolderEvent(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

class SelectVideoEvent extends VideosEvent {
  final VideoItem video;

  const SelectVideoEvent(this.video);

  @override
  List<Object?> get props => [video];
}

class RenameVideoEvent extends VideosEvent {
  final VideoItem video;
  final String newBaseName;

  const RenameVideoEvent({
    required this.video,
    required this.newBaseName,
  });

  @override
  List<Object?> get props => [video, newBaseName];
}
