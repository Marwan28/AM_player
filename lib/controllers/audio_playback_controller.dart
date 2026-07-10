import 'dart:async';
import 'dart:io';

import 'package:am_player/models/song.dart';
import 'package:am_player/repositories/audio_library_repository.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlaybackController extends ChangeNotifier
    with WidgetsBindingObserver {
  final AudioLibraryRepository repository;
  final AudioPlayer player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  LoopMode _repeatMode = LoopMode.all;
  double _speed = 1;
  Uri? _notificationArtUri;
  Future<Uri?>? _notificationArtFuture;
  Timer? _saveTimer;
  Timer? _stateSaveDebounce;
  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  bool _dismissingSystemSession = false;
  bool _pausedFromApp = false;

  AudioPlaybackController({required this.repository}) {
    WidgetsBinding.instance.addObserver(this);
    _indexSubscription = player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        _schedulePlaybackStateSave();
        notifyListeners();
      }
    });
    _stateSubscription = player.playerStateStream.listen((_) {
      if (player.playing) {
        _pausedFromApp = false;
      }
      if (!_dismissingSystemSession) {
        _schedulePlaybackStateSave();
      }
      notifyListeners();
    });
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_dismissingSystemSession && hasQueue && player.playing) {
        _savePlaybackState();
      }
    });
    unawaited(_resolveNotificationArtUri());
  }

  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  bool get shuffleEnabled => _shuffleEnabled;
  LoopMode get repeatMode => _repeatMode;
  double get speed => _speed;
  bool get hasQueue => _queue.isNotEmpty;

  Future<bool> restore(List<Song> songs) async {
    if (songs.isEmpty) return false;
    final snapshot = await repository.loadPlaybackSnapshot();
    if (snapshot?.assetId == null) return false;
    final savedAssetId = snapshot?.assetId;
    final songsById = {for (final song in songs) song.id: song};
    final savedQueue = [
      for (final assetId in snapshot?.queueAssetIds ?? const <String>[])
        if (songsById[assetId] case final Song song) song,
    ];
    final restoredQueue = savedQueue.isEmpty ? songs : savedQueue;
    final index = restoredQueue.indexWhere((song) => song.id == savedAssetId);
    if (index < 0) return false;

    _shuffleEnabled = snapshot?.shuffleEnabled ?? false;
    _repeatMode = _loopModeFromName(snapshot?.repeatMode ?? 'all');
    _speed = snapshot?.speed ?? 1;
    _pausedFromApp = !(snapshot?.wasPlaying ?? false);
    await _loadQueue(
      restoredQueue,
      initialIndex: index,
      initialPosition: snapshot?.position ?? Duration.zero,
      play: false,
    );
    return true;
  }

  Future<void> playQueue(List<Song> songs, int index) async {
    if (songs.isEmpty) return;
    final safeIndex = index.clamp(0, songs.length - 1).toInt();
    if (_matchesCurrentQueue(songs)) {
      if (_currentIndex != safeIndex) {
        await playAt(safeIndex);
      } else if (!player.playing) {
        _pausedFromApp = false;
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero, index: safeIndex);
        }
        await player.play();
        await _savePlaybackState();
        notifyListeners();
      }
      return;
    }
    await _loadQueue(
      songs,
      initialIndex: safeIndex,
      initialPosition: Duration.zero,
      play: true,
    );
  }

  Future<void> shuffleAll(List<Song> songs) async {
    if (songs.isEmpty) return;
    _shuffleEnabled = true;
    await _loadQueue(
      songs,
      initialIndex: 0,
      initialPosition: Duration.zero,
      play: true,
    );
    await player.shuffle();
    _pausedFromApp = false;
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (!hasQueue) return;
    if (player.playing) {
      _pausedFromApp = true;
      await player.pause();
    } else {
      _pausedFromApp = false;
      await player.play();
    }
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> pauseForVideo() async {
    if (!hasQueue || !player.playing) return;
    _pausedFromApp = false;
    await player.pause();
    await _savePlaybackState(wasPlaying: false);
    notifyListeners();
  }

  Future<void> next() async {
    if (player.hasNext) {
      _pausedFromApp = false;
      await player.seekToNext();
      await player.play();
      await _savePlaybackState();
      notifyListeners();
    }
  }

  Future<void> playAt(int index) async {
    if (!hasQueue) return;
    final safeIndex = index.clamp(0, _queue.length - 1).toInt();
    _currentIndex = safeIndex;
    _pausedFromApp = false;
    await player.seek(Duration.zero, index: safeIndex);
    await player.play();
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> previous() async {
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      await _savePlaybackState();
      notifyListeners();
      return;
    }
    if (player.hasPrevious) {
      _pausedFromApp = false;
      await player.seekToPrevious();
      await player.play();
      await _savePlaybackState();
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await player.setShuffleModeEnabled(_shuffleEnabled);
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    switch (_repeatMode) {
      case LoopMode.off:
        _repeatMode = LoopMode.all;
        break;
      case LoopMode.all:
        _repeatMode = LoopMode.one;
        break;
      case LoopMode.one:
        _repeatMode = LoopMode.off;
        break;
    }
    await player.setLoopMode(_repeatMode);
    await _savePlaybackState();
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await player.setSpeed(speed);
    await _savePlaybackState();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_savePlaybackState());
        break;
      case AppLifecycleState.inactive:
        unawaited(_savePlaybackState());
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_handleLeavingForeground());
        break;
    }
  }

  Future<void> _handleLeavingForeground() async {
    await _savePlaybackState();
    if (!player.playing && _pausedFromApp) {
      await _dismissPausedSystemSession();
    }
  }

  Future<void> _dismissPausedSystemSession() async {
    if (_dismissingSystemSession || player.playing || !hasQueue) return;
    _dismissingSystemSession = true;
    try {
      final pausedPosition = player.position;
      await _savePlaybackState(
        position: pausedPosition,
        wasPlaying: false,
      );
      await player.stop();
      await _savePlaybackState(
        position: pausedPosition,
        wasPlaying: false,
      );
    } catch (error) {
      debugPrint('AM audio notification dismiss failed: $error');
    } finally {
      _dismissingSystemSession = false;
    }
  }

  Future<void> _loadQueue(
    List<Song> songs, {
    required int initialIndex,
    required Duration initialPosition,
    required bool play,
  }) async {
    _queue = songs;
    _currentIndex = initialIndex;
    final queueAssetIds = [for (final song in songs) song.id];
    final artUri = await _resolveNotificationArtUri();
    final source = ConcatenatingAudioSource(
      children: [
        for (final song in songs)
          AudioSource.uri(
            song.uri,
            tag: MediaItem(
              id: song.id,
              title: song.displayTitle,
              album: song.folderName,
              artist: _notificationSubtitle(song),
              artUri: artUri,
              duration: song.duration,
            ),
          ),
      ],
    );

    await player.setAudioSource(
      source,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
    await player.setLoopMode(_repeatMode);
    await player.setShuffleModeEnabled(_shuffleEnabled);
    await player.setSpeed(_speed);
    if (play) await player.play();
    await repository.savePlaybackQueue(queueAssetIds);
    await _savePlaybackState();
    notifyListeners();
  }

  bool _matchesCurrentQueue(List<Song> songs) {
    if (_queue.length != songs.length) return false;
    for (var index = 0; index < songs.length; index++) {
      if (_queue[index].id != songs[index].id) return false;
    }
    return true;
  }

  Future<Uri?> _resolveNotificationArtUri() {
    final cachedUri = _notificationArtUri;
    if (cachedUri != null) return Future<Uri?>.value(cachedUri);
    return _notificationArtFuture ??= _loadNotificationArtUri();
  }

  Future<Uri?> _loadNotificationArtUri() async {
    try {
      final data = await rootBundle.load('assets/images/audio_cover.png');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/am_player_audio_cover.png');
      final exists = await file.exists();
      final cachedLength = exists ? await file.length() : -1;
      final shouldWrite = !exists || cachedLength != data.lengthInBytes;
      if (shouldWrite) {
        await file.writeAsBytes(
          data.buffer.asUint8List(),
          flush: true,
        );
      }
      _notificationArtUri = file.uri;
    } catch (error) {
      debugPrint('AM audio notification art failed: $error');
    }

    return _notificationArtUri;
  }

  String _notificationSubtitle(Song song) {
    final artist = song.artist?.trim();
    if (artist == null ||
        artist.isEmpty ||
        artist == '<unknown>' ||
        artist.toLowerCase() == 'unknown') {
      return song.folderName;
    }
    return artist;
  }

  Future<void> _savePlaybackState({
    Duration? position,
    bool? wasPlaying,
  }) {
    if (!hasQueue) return Future<void>.value();
    _stateSaveDebounce?.cancel();
    _stateSaveDebounce = null;
    return repository.savePlaybackSnapshot(
      assetId: currentSong?.id,
      position: position ?? player.position,
      shuffleEnabled: _shuffleEnabled,
      repeatMode: _loopModeName(_repeatMode),
      speed: _speed,
      wasPlaying: wasPlaying ?? player.playing,
    );
  }

  void _schedulePlaybackStateSave() {
    _stateSaveDebounce?.cancel();
    _stateSaveDebounce = Timer(const Duration(milliseconds: 250), () {
      _stateSaveDebounce = null;
      unawaited(_savePlaybackState());
    });
  }

  String repeatLabel() {
    switch (_repeatMode) {
      case LoopMode.off:
        return 'Off';
      case LoopMode.all:
        return 'All';
      case LoopMode.one:
        return 'One';
    }
  }

  IconData repeatIcon() {
    switch (_repeatMode) {
      case LoopMode.off:
        return Icons.repeat_rounded;
      case LoopMode.all:
        return Icons.repeat_rounded;
      case LoopMode.one:
        return Icons.repeat_one_rounded;
    }
  }

  String _loopModeName(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return 'off';
      case LoopMode.all:
        return 'all';
      case LoopMode.one:
        return 'one';
    }
  }

  LoopMode _loopModeFromName(String mode) {
    switch (mode) {
      case 'off':
        return LoopMode.off;
      case 'one':
        return LoopMode.one;
      case 'all':
      default:
        return LoopMode.all;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _stateSaveDebounce?.cancel();
    unawaited(_indexSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_savePlaybackState());
    player.dispose();
    super.dispose();
  }
}
