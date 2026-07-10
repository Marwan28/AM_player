part of 'songs_bloc.dart';

enum AudioSortMode { dateDesc, titleAsc, durationDesc, sizeDesc }

@immutable
class SongsState {
  final bool isLoading;
  final bool isSyncing;
  final bool permissionDenied;
  final List<Song> songs;
  final String query;
  final AudioSortMode sortMode;
  final String? errorMessage;

  const SongsState({
    required this.isLoading,
    required this.isSyncing,
    required this.permissionDenied,
    required this.songs,
    required this.query,
    required this.sortMode,
    required this.errorMessage,
  });

  factory SongsState.initial() {
    return const SongsState(
      isLoading: true,
      isSyncing: false,
      permissionDenied: false,
      songs: [],
      query: '',
      sortMode: AudioSortMode.titleAsc,
      errorMessage: null,
    );
  }

  List<Song> get visibleSongs {
    return _filteredSongs(includeWhatsAppAudio: false);
  }

  List<Song> get visibleFolderSongs {
    return _filteredSongs(includeWhatsAppAudio: true);
  }

  int get visibleFolderCount {
    return visibleFolderSongs.map((song) => song.folderId).toSet().length;
  }

  List<Song> _filteredSongs({required bool includeWhatsAppAudio}) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = songs.where((song) {
      if (!includeWhatsAppAudio && _isWhatsAppAudio(song)) return false;
      if (normalizedQuery.isEmpty) return true;
      return song.displayTitle.toLowerCase().contains(normalizedQuery) ||
          song.folderName.toLowerCase().contains(normalizedQuery) ||
          (song.artist ?? '').toLowerCase().contains(normalizedQuery);
    }).toList();

    switch (sortMode) {
      case AudioSortMode.dateDesc:
        filtered.sort((a, b) => b.modifiedMs.compareTo(a.modifiedMs));
        break;
      case AudioSortMode.titleAsc:
        filtered.sort(
          (a, b) => a.displayTitle
              .toLowerCase()
              .compareTo(b.displayTitle.toLowerCase()),
        );
        break;
      case AudioSortMode.durationDesc:
        filtered.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
      case AudioSortMode.sizeDesc:
        filtered.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    return filtered;
  }

  int get folderCount => songs.map((song) => song.folderId).toSet().length;

  bool _isWhatsAppAudio(Song song) {
    final path = song.filePath.replaceAll('\\', '/').toLowerCase();
    final folder = song.folderName.toLowerCase();
    return path.contains('/android/media/com.whatsapp/') ||
        path.contains('/whatsapp/audio/') ||
        path.contains('/whatsapp audio/') ||
        path.contains('/whatsapp voice notes/') ||
        folder.contains('whatsapp audio') ||
        folder.contains('whatsapp voice');
  }

  SongsState copyWith({
    bool? isLoading,
    bool? isSyncing,
    bool? permissionDenied,
    List<Song>? songs,
    String? query,
    AudioSortMode? sortMode,
    String? errorMessage,
  }) {
    return SongsState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      songs: songs ?? this.songs,
      query: query ?? this.query,
      sortMode: sortMode ?? this.sortMode,
      errorMessage: errorMessage,
    );
  }
}
