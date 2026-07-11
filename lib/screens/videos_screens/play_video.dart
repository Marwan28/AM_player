import 'dart:async';
import 'dart:convert';

import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/repositories/video_library_repository.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:simple_pip_mode/actions/pip_action.dart';
import 'package:simple_pip_mode/actions/pip_actions_layout.dart';
import 'package:simple_pip_mode/simple_pip.dart';

enum _VideoEndMode { playNext, repeatOne }

class _PlaybackPositionSnapshot {
  final String assetId;
  final Duration position;
  final Duration duration;

  const _PlaybackPositionSnapshot({
    required this.assetId,
    required this.position,
    required this.duration,
  });
}

class PlayVideoScreen extends StatefulWidget {
  final VideoItem initialVideo;

  const PlayVideoScreen({super.key, required this.initialVideo});

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen>
    with WidgetsBindingObserver {
  final VideoLibraryRepository repository = VideoLibraryRepository();
  final GlobalKey videoViewKey = GlobalKey();

  late final SimplePip pip;
  late final mk.Player player;
  late final mkv.VideoController controller;
  late VideoItem video;

  StreamSubscription<bool>? playingSubscription;
  StreamSubscription<bool>? completedSubscription;
  StreamSubscription<String>? errorSubscription;
  Timer? hideTimer;
  Timer? positionSaveTimer;

  bool showControls = true;
  bool isInPip = false;
  bool opening = true;
  bool handlingCompletion = false;
  bool savingPosition = false;
  _PlaybackPositionSnapshot? pendingPositionSave;
  bool controlsLocked = false;
  bool showSpeedChoices = false;
  bool showRemainingTime = true;
  double playbackRate = 1.0;
  BoxFit videoFit = BoxFit.contain;
  _VideoEndMode endMode = _VideoEndMode.playNext;
  String? playbackError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    pip = SimplePip(
      onPipEntered: _onPipEntered,
      onPipExited: _onPipExited,
      onPipAction: _handlePipAction,
    );
    unawaited(pip.setPipActionsLayout(PipActionsLayout.mediaWithSeek10));

    video = widget.initialVideo;
    player = mk.Player();
    controller = mkv.VideoController(player);

    playingSubscription = player.stream.playing.listen((playing) {
      pip.setIsPlaying(playing);
    });
    completedSubscription = player.stream.completed.listen((completed) {
      if (completed) unawaited(_handleVideoCompleted());
    });
    errorSubscription = player.stream.error.listen((error) {
      if (!mounted || error.trim().isEmpty) return;
      setState(() {
        opening = false;
        showControls = false;
        playbackError = 'This video could not be played.';
      });
    });

    positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _savePlaybackPosition();
    });

    unawaited(_openVideo(resume: true));
    _scheduleHideControls();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _savePlaybackPosition();
    hideTimer?.cancel();
    positionSaveTimer?.cancel();
    playingSubscription?.cancel();
    completedSubscription?.cancel();
    errorSubscription?.cancel();
    player.dispose();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _savePlaybackPosition();
        break;
      case AppLifecycleState.resumed:
        unawaited(_syncPipState());
        break;
    }
  }

  Future<void> _syncPipState() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    var pipActive = false;
    try {
      pipActive = await SimplePip.isPipActivated;
    } catch (_) {
      pipActive = false;
    }
    if (!mounted || pipActive == isInPip) return;

    setState(() {
      isInPip = pipActive;
      showControls = !pipActive;
      if (!pipActive) showSpeedChoices = false;
    });
    if (!pipActive) _scheduleHideControls();
  }

  Future<void> _openVideo({required bool resume}) async {
    if (mounted) {
      setState(() {
        opening = true;
        showControls = true;
        playbackError = null;
      });
    }
    try {
      final savedPosition = resume
          ? await repository.loadPlaybackPosition(video.assetId)
          : Duration.zero;
      final startPosition = await _resolveStartPosition(savedPosition);
      if (!mounted) return;
      await player.open(
        mk.Media(video.path, start: startPosition),
        play: true,
      );
      if (!mounted) return;
      setState(() {
        opening = false;
        playbackError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        opening = false;
        showControls = false;
        playbackError = 'This video could not be played.';
      });
    }
  }

  Future<Duration> _resolveStartPosition(Duration savedPosition) async {
    if (savedPosition < const Duration(seconds: 2)) return Duration.zero;

    final duration = video.duration;
    if (duration > Duration.zero &&
        savedPosition >= duration - const Duration(seconds: 5)) {
      await repository.clearPlaybackPosition(video.assetId);
      return Duration.zero;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return Duration.zero;

    final shouldResume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resume video?'),
          content: Text(
            'Continue from ${_formatPromptDuration(savedPosition)} or start from the beginning?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Start over'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );

    if (shouldResume == true) return savedPosition;

    await repository.clearPlaybackPosition(video.assetId);
    return Duration.zero;
  }

  String _formatPromptDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours == 0) return '$minutes:$seconds';
    return '${twoDigits(hours)}:$minutes:$seconds';
  }

  Future<void> _handleVideoCompleted() async {
    if (handlingCompletion) return;
    handlingCompletion = true;
    try {
      await repository.clearPlaybackPosition(video.assetId);

      if (endMode == _VideoEndMode.repeatOne) {
        await player.seek(Duration.zero);
        await player.play();
        return;
      }

      final nextVideo = _nextVideo();
      if (nextVideo == null) {
        await player.seek(player.state.duration);
        return;
      }

      video = nextVideo;
      if (mounted) {
        setState(() {
          showControls = true;
          opening = true;
        });
      }
      await _openVideo(resume: false);
    } finally {
      handlingCompletion = false;
    }
  }

  VideoItem? _nextVideo() {
    final videos =
        context.read<VideosBloc>().state.videosForFolder(video.folderId);
    if (videos.length < 2) return null;

    final currentIndex =
        videos.indexWhere((item) => item.assetId == video.assetId);
    if (currentIndex == -1 || currentIndex == videos.length - 1) {
      return videos.first;
    }
    return videos[currentIndex + 1];
  }

  void _savePlaybackPosition() {
    if (opening) return;
    final snapshot = _PlaybackPositionSnapshot(
      assetId: video.assetId,
      position: player.state.position,
      duration: player.state.duration,
    );
    if (savingPosition) {
      pendingPositionSave = snapshot;
      return;
    }
    unawaited(_persistPlaybackPosition(snapshot));
  }

  Future<void> _persistPlaybackPosition(
    _PlaybackPositionSnapshot snapshot,
  ) async {
    savingPosition = true;
    try {
      await repository.savePlaybackPosition(
        assetId: snapshot.assetId,
        position: snapshot.position,
        duration: snapshot.duration,
      );
    } catch (error) {
      debugPrint('AM video position save failed: $error');
    } finally {
      savingPosition = false;
      final pending = pendingPositionSave;
      pendingPositionSave = null;
      if (pending != null) {
        unawaited(_persistPlaybackPosition(pending));
      }
    }
  }

  void _toggleControls() {
    if (isInPip) return;
    setState(() => showControls = !showControls);
    if (showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !isInPip) setState(() => showControls = false);
    });
  }

  Future<void> _seekRelative(Duration delta) async {
    final target = player.state.position + delta;
    final duration = player.state.duration;

    if (delta > Duration.zero &&
        duration > Duration.zero &&
        target >= duration) {
      await player.seek(duration);
      await _handleVideoCompleted();
      return;
    }

    final safeTarget = target < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && target > duration
            ? duration
            : target;
    await player.seek(safeTarget);
    _savePlaybackPosition();
    if (!showControls && !isInPip) setState(() => showControls = true);
    _scheduleHideControls();
  }

  Future<void> _setRate(double rate) async {
    await player.setRate(rate);
    setState(() => playbackRate = rate);
    _scheduleHideControls();
  }

  Future<void> _enterPip() async {
    if (!await SimplePip.isPipAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture in picture is not available on this device.'),
        ),
      );
      return;
    }
    hideTimer?.cancel();

    if (mounted) {
      setState(() {
        isInPip = true;
        showControls = false;
        showSpeedChoices = false;
      });
    }

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    var entered = false;
    try {
      entered = await pip.enterPipMode(
        aspectRatio: _pipAspectRatio(),
        seamlessResize: true,
      );
    } catch (_) {
      entered = false;
    }
    if (!entered && mounted) {
      setState(() {
        isInPip = false;
        showControls = true;
      });
      _scheduleHideControls();
    }
  }

  (int, int) _pipAspectRatio() {
    if (video.width <= 0 || video.height <= 0) return (16, 9);
    final ratio = video.width / video.height;
    if (ratio > 2.39) return (239, 100);
    if (ratio < 1 / 2.39) return (100, 239);
    return (video.width, video.height);
  }

  void _onPipEntered() {
    if (!mounted) return;
    setState(() {
      isInPip = true;
      showControls = false;
      showSpeedChoices = false;
    });
  }

  void _onPipExited() {
    if (!mounted) return;
    setState(() {
      isInPip = false;
      showControls = true;
      showSpeedChoices = false;
    });
    _scheduleHideControls();
  }

  void _handlePipAction(PipAction action) {
    switch (action) {
      case PipAction.play:
        unawaited(player.play());
        break;
      case PipAction.pause:
        unawaited(player.pause());
        break;
      case PipAction.rewind:
      case PipAction.previous:
        unawaited(_seekRelative(const Duration(seconds: -10)));
        break;
      case PipAction.forward:
      case PipAction.next:
        unawaited(_seekRelative(const Duration(seconds: 10)));
        break;
      case PipAction.live:
        break;
    }
  }

  void _toggleFit() {
    setState(() {
      videoFit = videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
    _scheduleHideControls();
  }

  void _toggleEndMode() {
    setState(() {
      endMode = endMode == _VideoEndMode.playNext
          ? _VideoEndMode.repeatOne
          : _VideoEndMode.playNext;
    });
    _scheduleHideControls();
  }

  void _toggleLock() {
    setState(() {
      controlsLocked = !controlsLocked;
      showControls = true;
    });
    _scheduleHideControls();
  }

  void _toggleSpeedChoices() {
    setState(() => showSpeedChoices = !showSpeedChoices);
    _scheduleHideControls();
  }

  void _toggleTimeMode() {
    setState(() => showRemainingTime = !showRemainingTime);
    _scheduleHideControls();
  }

  Future<void> _showSubtitlesSheet() async {
    _scheduleHideControls();
    final tracks = player.state.tracks.subtitle
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList();
    final selectedId = player.state.track.subtitle.id;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171A21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text(
                  'Subtitles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.subtitles_off_rounded,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Off',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: selectedId == 'no'
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () async {
                  await player.setSubtitleTrack(mk.SubtitleTrack.no());
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              for (var i = 0; i < tracks.length; i++)
                ListTile(
                  leading: const Icon(
                    Icons.subtitles_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    _subtitleTrackLabel(tracks[i], i),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: selectedId == tracks[i].id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primary,
                        )
                      : null,
                  onTap: () async {
                    await player.setSubtitleTrack(tracks[i]);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Open subtitle file',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'SRT, VTT, ASS, or SSA',
                  style: TextStyle(color: Colors.white60),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_pickExternalSubtitle());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _subtitleTrackLabel(mk.SubtitleTrack track, int index) {
    final title = track.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final language = track.language?.trim();
    if (language != null && language.isNotEmpty) return language.toUpperCase();
    return 'Subtitle ${index + 1}';
  }

  Future<void> _pickExternalSubtitle() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['srt', 'vtt', 'ass', 'ssa'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.path != null && file.path!.isNotEmpty) {
        await player.setSubtitleTrack(
          mk.SubtitleTrack.uri(file.path!, title: file.name),
        );
      } else if (file.bytes != null) {
        await player.setSubtitleTrack(
          mk.SubtitleTrack.data(
            utf8.decode(file.bytes!, allowMalformed: true),
            title: file.name,
          ),
        );
      } else {
        throw StateError('Subtitle file is unavailable.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} loaded')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load this subtitle file.')),
      );
    }
  }

  void _showMoreSheet() {
    _scheduleHideControls();
    _showPlayerSheet(
      title: 'Playback options',
      children: [
        _SheetTile(
          icon: Icons.info_outline_rounded,
          title: video.displayTitle,
          subtitle:
              '${video.resolutionLabel} - ${video.width}x${video.height} - ${video.folderName}',
        ),
        _SheetTile(
          icon: endMode == _VideoEndMode.playNext
              ? Icons.queue_play_next_rounded
              : Icons.repeat_one_rounded,
          title: endMode == _VideoEndMode.playNext ? 'Play next' : 'Repeat one',
          subtitle: 'Tap the top repeat button to change this mode',
        ),
      ],
    );
  }

  void _showPlayerSheet({
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171A21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isInPip ? _pipOnlyPlayerView() : _normalPlayerView(),
    );
  }

  Widget _pipOnlyPlayerView() {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(
        child: mkv.Video(
          key: videoViewKey,
          controller: controller,
          fit: BoxFit.contain,
          controls: mkv.NoVideoControls,
          pauseUponEnteringBackgroundMode: false,
          resumeUponEnteringForegroundMode: false,
        ),
      ),
    );
  }

  Widget _normalPlayerView() {
    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: mkv.Video(
                key: videoViewKey,
                controller: controller,
                fit: videoFit,
                controls: mkv.NoVideoControls,
                pauseUponEnteringBackgroundMode: true,
                resumeUponEnteringForegroundMode: false,
              ),
            ),
            _LoadingLayer(player: player, opening: opening),
            if (playbackError != null)
              _PlaybackErrorLayer(
                message: playbackError!,
                onRetry: () => _openVideo(resume: true),
                onBack: () => Navigator.pop(context),
              ),
            AnimatedOpacity(
              opacity: showControls ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !showControls,
                child: _VideoControls(
                  player: player,
                  title: video.displayTitle,
                  playbackRate: playbackRate,
                  isCover: videoFit == BoxFit.cover,
                  endMode: endMode,
                  controlsLocked: controlsLocked,
                  showSpeedChoices: showSpeedChoices,
                  onBack: () => Navigator.pop(context),
                  onPip: _enterPip,
                  onToggleFit: _toggleFit,
                  onToggleEndMode: _toggleEndMode,
                  onToggleLock: _toggleLock,
                  onToggleSpeedChoices: _toggleSpeedChoices,
                  onToggleTimeMode: _toggleTimeMode,
                  onSubtitles: _showSubtitlesSheet,
                  onMore: _showMoreSheet,
                  onRateSelected: _setRate,
                  showRemainingTime: showRemainingTime,
                  onSeekBack: () => _seekRelative(
                    const Duration(seconds: -10),
                  ),
                  onSeekForward: () => _seekRelative(
                    const Duration(seconds: 10),
                  ),
                  onInteracted: _scheduleHideControls,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLayer extends StatelessWidget {
  final mk.Player player;
  final bool opening;

  const _LoadingLayer({
    required this.player,
    required this.opening,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.buffering,
      initialData: opening,
      builder: (context, snapshot) {
        final loading = opening || (snapshot.data ?? false);
        if (!loading) return const SizedBox.shrink();
        return DecoratedBox(
          decoration:
              BoxDecoration(color: Colors.black.withValues(alpha: 0.18)),
          child: const Center(
            child: SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaybackErrorLayer extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _PlaybackErrorLayer({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.88),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: onBack,
                      child: const Text('Back'),
                    ),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final mk.Player player;
  final String title;
  final double playbackRate;
  final bool isCover;
  final _VideoEndMode endMode;
  final bool controlsLocked;
  final bool showSpeedChoices;
  final bool showRemainingTime;
  final VoidCallback onBack;
  final VoidCallback onPip;
  final VoidCallback onToggleFit;
  final VoidCallback onToggleEndMode;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleSpeedChoices;
  final VoidCallback onToggleTimeMode;
  final VoidCallback onSubtitles;
  final VoidCallback onMore;
  final ValueChanged<double> onRateSelected;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onInteracted;

  const _VideoControls({
    required this.player,
    required this.title,
    required this.playbackRate,
    required this.isCover,
    required this.endMode,
    required this.controlsLocked,
    required this.showSpeedChoices,
    required this.showRemainingTime,
    required this.onBack,
    required this.onPip,
    required this.onToggleFit,
    required this.onToggleEndMode,
    required this.onToggleLock,
    required this.onToggleSpeedChoices,
    required this.onToggleTimeMode,
    required this.onSubtitles,
    required this.onMore,
    required this.onRateSelected,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onInteracted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = constraints.maxWidth < 430;
        final compactHeight = constraints.maxHeight < 430;
        final compact = compactWidth || compactHeight;
        if (controlsLocked) {
          return Stack(
            children: [
              Positioned(
                right: 12,
                top: 10,
                child: _GlassIconButton(
                  icon: Icons.lock_open_rounded,
                  tooltip: 'Unlock controls',
                  onPressed: onToggleLock,
                  size: compact ? 36 : 40,
                ),
              ),
            ],
          );
        }
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6000000),
                Color(0x22000000),
                Color(0xE6000000),
              ],
            ),
          ),
          child: Stack(
            children: [
              _TopBar(
                title: title,
                isCover: isCover,
                endMode: endMode,
                compact: compact,
                onBack: onBack,
                onPip: onPip,
                onToggleFit: onToggleFit,
                onToggleEndMode: onToggleEndMode,
                onSubtitles: onSubtitles,
                onMore: onMore,
              ),
              Center(
                child: StreamBuilder<bool>(
                  stream: player.stream.playing,
                  initialData: player.state.playing,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleButton(
                          icon: Icons.replay_10_rounded,
                          size: compact ? 50 : 58,
                          iconSize: compact ? 28 : 34,
                          onPressed: () {
                            onSeekBack();
                            onInteracted();
                          },
                        ),
                        SizedBox(width: compact ? 14 : 22),
                        _CircleButton(
                          icon: playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: compact ? 68 : 78,
                          iconSize: compact ? 42 : 50,
                          strong: true,
                          onPressed: () {
                            playing ? player.pause() : player.play();
                            onInteracted();
                          },
                        ),
                        SizedBox(width: compact ? 14 : 22),
                        _CircleButton(
                          icon: Icons.forward_10_rounded,
                          size: compact ? 50 : 58,
                          iconSize: compact ? 28 : 34,
                          onPressed: () {
                            onSeekForward();
                            onInteracted();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                left: compact ? 12 : 20,
                right: compact ? 12 : 20,
                bottom: compact ? 8 : 16,
                child: _ProgressBar(
                  player: player,
                  playbackRate: playbackRate,
                  showSpeedChoices: showSpeedChoices,
                  onRateSelected: onRateSelected,
                  onToggleSpeedChoices: onToggleSpeedChoices,
                  onToggleLock: onToggleLock,
                  onToggleTimeMode: onToggleTimeMode,
                  showRemainingTime: showRemainingTime,
                  compact: compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool isCover;
  final _VideoEndMode endMode;
  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onPip;
  final VoidCallback onToggleFit;
  final VoidCallback onToggleEndMode;
  final VoidCallback onSubtitles;
  final VoidCallback onMore;

  const _TopBar({
    required this.title,
    required this.isCover,
    required this.endMode,
    required this.compact,
    required this.onBack,
    required this.onPip,
    required this.onToggleFit,
    required this.onToggleEndMode,
    required this.onSubtitles,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: compact ? 6 : 10,
      right: compact ? 6 : 10,
      top: compact ? 4 : 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: onBack,
                size: compact ? 36 : 40,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Video - Local - ${isCover ? 'Fill' : 'Fit'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _GlassIconButton(
                  tooltip: isCover ? 'Fit screen' : 'Fill screen',
                  icon: isCover
                      ? Icons.fit_screen_rounded
                      : Icons.crop_free_rounded,
                  onPressed: onToggleFit,
                  size: compact ? 34 : 38,
                ),
                const SizedBox(width: 6),
                _GlassIconButton(
                  tooltip: 'Subtitles',
                  icon: Icons.subtitles_rounded,
                  onPressed: onSubtitles,
                  size: compact ? 34 : 38,
                ),
                const SizedBox(width: 6),
                _GlassIconButton(
                  tooltip: 'Picture in picture',
                  icon: Icons.picture_in_picture_alt_rounded,
                  onPressed: onPip,
                  size: compact ? 34 : 38,
                ),
                const SizedBox(width: 6),
                _GlassIconButton(
                  tooltip: endMode == _VideoEndMode.playNext
                      ? 'Play next'
                      : 'Repeat this video',
                  icon: endMode == _VideoEndMode.playNext
                      ? Icons.queue_play_next_rounded
                      : Icons.repeat_one_rounded,
                  onPressed: onToggleEndMode,
                  size: compact ? 34 : 38,
                ),
                const SizedBox(width: 6),
                _GlassIconButton(
                  tooltip: 'More',
                  icon: Icons.more_vert_rounded,
                  onPressed: onMore,
                  size: compact ? 34 : 38,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final mk.Player player;
  final double playbackRate;
  final bool showSpeedChoices;
  final ValueChanged<double> onRateSelected;
  final VoidCallback onToggleSpeedChoices;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleTimeMode;
  final bool showRemainingTime;
  final bool compact;

  const _ProgressBar({
    required this.player,
    required this.playbackRate,
    required this.showSpeedChoices,
    required this.onRateSelected,
    required this.onToggleSpeedChoices,
    required this.onToggleLock,
    required this.onToggleTimeMode,
    required this.showRemainingTime,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: player.state.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          initialData: player.state.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
            final value = position.inMilliseconds.clamp(0, maxMs).toDouble();
            final displayPosition =
                duration > Duration.zero && position > duration
                    ? duration
                    : position;

            final remaining = duration > displayPosition
                ? duration - displayPosition
                : Duration.zero;
            final displayRemaining = _ceilToSecond(remaining);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpeedChoices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final speed in const [
                            0.25,
                            0.5,
                            0.75,
                            1.0,
                            1.25,
                            1.5,
                            1.75,
                            2.0,
                          ])
                            _SpeedChip(
                              speed: speed,
                              active: playbackRate == speed,
                              onSelected: () => onRateSelected(speed),
                            ),
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      10,
                      compact ? 4 : 6,
                      10,
                      compact ? 6 : 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: compact ? 42 : 50,
                              child: Text(
                                _formatDuration(displayPosition),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: compact ? 3 : 4,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 13,
                                  ),
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: compact ? 6 : 7,
                                  ),
                                ),
                                child: Slider(
                                  min: 0,
                                  max: maxMs,
                                  value: value,
                                  activeColor: AppTheme.primary,
                                  inactiveColor: Colors.white24,
                                  onChanged: (newValue) {
                                    player.seek(
                                      Duration(
                                        milliseconds: newValue.round(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: compact ? 42 : 50,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: onToggleTimeMode,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    showRemainingTime
                                        ? '-${_formatDuration(displayRemaining)}'
                                        : _formatDuration(duration),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: compact ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 2 : 6),
                        Row(
                          children: [
                            _UtilityButton(
                              icon: Icons.speed_rounded,
                              label: '${_formatRate(playbackRate)}x',
                              onPressed: onToggleSpeedChoices,
                            ),
                            const Spacer(),
                            _UtilityButton(
                              icon: Icons.lock_rounded,
                              label: 'Lock',
                              onPressed: onToggleLock,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours == 0) return '$minutes:$seconds';
    return '${twoDigits(hours)}:$minutes:$seconds';
  }

  static Duration _ceilToSecond(Duration duration) {
    if (duration <= Duration.zero) return Duration.zero;
    final milliseconds = duration.inMilliseconds;
    final seconds = (milliseconds / 1000).ceil();
    return Duration(seconds: seconds);
  }

  static String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) return rate.toInt().toString();
    return rate.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }
}

class _SpeedChip extends StatelessWidget {
  final double speed;
  final bool active;
  final VoidCallback onSelected;

  const _SpeedChip({
    required this.speed,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              active ? AppTheme.primary : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${_ProgressBar._formatRate(speed)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UtilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _UtilityButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final bool strong;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.size = 58,
    this.iconSize = 34,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: strong
              ? AppTheme.primary.withValues(alpha: 0.88)
              : Colors.black.withValues(alpha: 0.48),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
            ),
          ],
        ),
        child: IconButton(
          color: Colors.white,
          iconSize: iconSize,
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          color: Colors.white,
          icon: Icon(icon, size: size * 0.55),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
