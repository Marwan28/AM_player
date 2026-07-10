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
    on<DeleteVideoEvent>(_onDeleteVideo);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    if (state.isSyncing) return;
    try {
      await _loadCachedFolders(emit);
      await _syncAndReload(emit);
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

  Future<void> _onRefreshVideos(
    RefreshVideosEvent event,
    Emitter<VideosState> emit,
  ) async {
    if (state.isSyncing) return;
    await _syncAndReload(emit, force: true);
  }

  Future<void> _onOpenFolder(
    OpenVideoFolderEvent event,
    Emitter<VideosState> emit,
  ) async {
    if (state.videosByFolder.containsKey(event.folderId)) return;
    final videos = await repository.loadVideosInFolder(event.folderId);
    final updatedMap = Map<String, List<VideoItem>>.from(state.videosByFolder);
    updatedMap[event.folderId] = videos;
    emit(state.copyWith(videosByFolder: updatedMap, clearError: true));
  }

  Future<void> _onDeleteVideo(
    DeleteVideoEvent event,
    Emitter<VideosState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearError: true));
    try {
      await repository.deleteVideo(event.video);
      final folders = await repository.loadFolders();
      final videos = await repository.loadVideosInFolder(event.video.folderId);
      final updatedMap =
          Map<String, List<VideoItem>>.from(state.videosByFolder);
      updatedMap[event.video.folderId] = videos;
      emit(
        state.copyWith(
          folders: folders,
          videosByFolder: updatedMap,
          isSyncing: false,
          clearError: true,
        ),
      );
    } on VideoDeleteException {
      emit(
        state.copyWith(
          isSyncing: false,
          errorMessage: 'The video could not be deleted.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSyncing: false,
          errorMessage: 'Unable to delete this video.',
        ),
      );
    }
  }

  Future<void> _loadCachedFolders(Emitter<VideosState> emit) async {
    final folders = await repository.loadFolders();
    emit(
      state.copyWith(
        folders: folders,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> _syncAndReload(
    Emitter<VideosState> emit, {
    bool force = false,
  }) async {
    emit(state.copyWith(isSyncing: true, permissionDenied: false));
    try {
      final changed = await repository.syncDeviceVideos(force: force);
      if (!changed) {
        emit(
          state.copyWith(
            isLoading: false,
            isSyncing: false,
            permissionDenied: false,
            clearError: true,
          ),
        );
        return;
      }
      final folders = await repository.loadFolders();
      final refreshedVideos = <String, List<VideoItem>>{};
      final availableFolderIds = folders.map((folder) => folder.id).toSet();
      for (final folderId in state.videosByFolder.keys) {
        if (availableFolderIds.contains(folderId)) {
          refreshedVideos[folderId] =
              await repository.loadVideosInFolder(folderId);
        }
      }
      emit(
        state.copyWith(
          folders: folders,
          videosByFolder: refreshedVideos,
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
