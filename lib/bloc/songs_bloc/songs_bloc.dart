import 'package:am_player/controllers/audio_playback_controller.dart';
import 'package:am_player/models/song.dart';
import 'package:am_player/repositories/audio_library_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  final AudioLibraryRepository repository;
  late final AudioPlaybackController playback;
  bool _restoredPlayback = false;

  SongsBloc({
    AudioLibraryRepository? repository,
  })  : repository = repository ?? AudioLibraryRepository(),
        super(SongsState.initial()) {
    playback = AudioPlaybackController(repository: this.repository);
    on<LoadSongsEvent>(_loadSongs);
    on<SearchSongsEvent>(_searchSongs);
    on<ChangeAudioSortEvent>(_changeSort);
    on<PlaySongEvent>(_playSong);
    on<ShuffleSongsEvent>(_shuffleSongs);
  }

  Future<void> _loadSongs(
    LoadSongsEvent event,
    Emitter<SongsState> emit,
  ) async {
    if (state.isSyncing) return;

    emit(
      state.copyWith(
        isLoading: state.songs.isEmpty,
        isSyncing: event.refresh || state.songs.isEmpty,
        permissionDenied: false,
        errorMessage: null,
      ),
    );

    try {
      var songs = await repository.loadSongs();
      if (songs.isNotEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            isSyncing: event.refresh,
            permissionDenied: false,
            songs: songs,
            errorMessage: null,
          ),
        );
        await _restorePlaybackOnce(songs);
      }

      final shouldCheckLibrary =
          event.refresh || songs.isNotEmpty || event.syncIfEmpty;
      if (shouldCheckLibrary) {
        emit(
          state.copyWith(
            isLoading: songs.isEmpty,
            isSyncing: true,
            permissionDenied: false,
            errorMessage: null,
          ),
        );
        final changed = await repository.syncDeviceAudio(force: event.refresh);
        if (changed || songs.isEmpty) {
          songs = await repository.loadSongs();
        }
        emit(
          state.copyWith(
            isLoading: false,
            isSyncing: false,
            permissionDenied: false,
            songs: songs,
            errorMessage: null,
          ),
        );
        await _restorePlaybackOnce(songs);
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            isSyncing: false,
            permissionDenied: false,
            songs: songs,
            errorMessage: null,
          ),
        );
      }
    } on AudioLibraryPermissionException {
      emit(
        state.copyWith(
          isLoading: false,
          isSyncing: false,
          permissionDenied: true,
          errorMessage: 'Media permission needed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isSyncing: false,
          permissionDenied: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _searchSongs(SearchSongsEvent event, Emitter<SongsState> emit) {
    emit(state.copyWith(query: event.query, errorMessage: null));
  }

  void _changeSort(ChangeAudioSortEvent event, Emitter<SongsState> emit) {
    emit(state.copyWith(sortMode: event.sortMode, errorMessage: null));
  }

  Future<void> _playSong(
    PlaySongEvent event,
    Emitter<SongsState> emit,
  ) async {
    try {
      final index = event.queue.indexWhere((song) => song.id == event.song.id);
      await playback.playQueue(event.queue, index < 0 ? 0 : index);
      emit(state.copyWith(errorMessage: null));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to play this audio file.'));
    }
  }

  Future<void> _shuffleSongs(
    ShuffleSongsEvent event,
    Emitter<SongsState> emit,
  ) async {
    try {
      await playback.shuffleAll(event.queue);
      emit(state.copyWith(errorMessage: null));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Unable to start audio playback.'));
    }
  }

  Future<void> _restorePlaybackOnce(List<Song> songs) async {
    if (_restoredPlayback || songs.isEmpty || playback.hasQueue) return;
    try {
      _restoredPlayback = await playback.restore(songs);
    } catch (_) {
      _restoredPlayback = true;
    }
  }

  @override
  Future<void> close() {
    playback.dispose();
    return super.close();
  }
}
