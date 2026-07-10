part of 'videos_bloc.dart';

class VideosState extends Equatable {
  final List<VideoFolder> folders;
  final Map<String, List<VideoItem>> videosByFolder;
  final bool isLoading;
  final bool isSyncing;
  final bool permissionDenied;
  final String? errorMessage;

  const VideosState({
    this.folders = const [],
    this.videosByFolder = const {},
    this.isLoading = true,
    this.isSyncing = false,
    this.permissionDenied = false,
    this.errorMessage,
  });

  bool get hasCachedData => folders.isNotEmpty;

  List<VideoItem> videosForFolder(String folderId) {
    return videosByFolder[folderId] ?? const [];
  }

  VideosState copyWith({
    List<VideoFolder>? folders,
    Map<String, List<VideoItem>>? videosByFolder,
    bool? isLoading,
    bool? isSyncing,
    bool? permissionDenied,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VideosState(
      folders: folders ?? this.folders,
      videosByFolder: videosByFolder ?? this.videosByFolder,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        folders,
        videosByFolder,
        isLoading,
        isSyncing,
        permissionDenied,
        errorMessage,
      ];
}
