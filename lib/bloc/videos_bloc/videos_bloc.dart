import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/repositories/video_library_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'videos_event.dart';
part 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideoLibraryRepository repository;

  VideosBloc({VideoLibraryRepository? repository})
      : repository = repository ?? VideoLibraryRepository(),
        super(const VideosState()) {
    on<LoadVideosEvent>(_onLoadVideos);
    on<RefreshVideosEvent>(_onRefreshVideos);
    on<OpenVideoFolderEvent>(_onOpenFolder);
    on<SelectVideoEvent>(_onSelectVideo);
    on<RenameVideoEvent>(_onRenameVideo);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    await _loadCachedFolders(emit, loading: true);
    await _syncAndReload(emit);
  }

  Future<void> _onRefreshVideos(
    RefreshVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    await _syncAndReload(emit);
  }

  Future<void> _onOpenFolder(
    OpenVideoFolderEvent event,
    Emitter<VideosState> emit,
  ) async {
    final videos = await repository.loadVideosInFolder(event.folderId);
    final updatedMap = Map<String, List<VideoItem>>.from(state.videosByFolder);
    updatedMap[event.folderId] = videos;
    emit(state.copyWith(videosByFolder: updatedMap, clearError: true));
  }

  void _onSelectVideo(
    SelectVideoEvent event,
    Emitter<VideosState> emit,
  ) {
    emit(state.copyWith(currentVideo: event.video));
  }

  Future<void> _onRenameVideo(
    RenameVideoEvent event,
    Emitter<VideosState> emit,
  ) async {
    try {
      await repository.renameVideo(
        item: event.video,
        newBaseName: event.newBaseName,
      );
      final folders = await repository.loadFolders();
      final videos = await repository.loadVideosInFolder(event.video.folderId);
      final updatedMap =
          Map<String, List<VideoItem>>.from(state.videosByFolder);
      updatedMap[event.video.folderId] = videos;
      emit(
        state.copyWith(
          folders: folders,
          videosByFolder: updatedMap,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> _loadCachedFolders(
    Emitter<VideosState> emit, {
    required bool loading,
  }) async {
    final folders = await repository.loadFolders();
    emit(
      state.copyWith(
        folders: folders,
        isLoading: loading && folders.isEmpty,
        clearError: true,
      ),
    );
  }

  Future<void> _syncAndReload(Emitter<VideosState> emit) async {
    emit(state.copyWith(isSyncing: true, permissionDenied: false));
    try {
      await repository.syncDeviceVideos();
      final folders = await repository.loadFolders();
      emit(
        state.copyWith(
          folders: folders,
          isLoading: false,
          isSyncing: false,
          permissionDenied: false,
          clearError: true,
        ),
      );
    } on VideoLibraryPermissionException {
      emit(
        state.copyWith(
          isLoading: false,
          isSyncing: false,
          permissionDenied: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isSyncing: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
