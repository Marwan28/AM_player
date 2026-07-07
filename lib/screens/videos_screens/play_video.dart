import 'dart:async';

import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:simple_pip_mode/simple_pip.dart';

class PlayVideoScreen extends StatefulWidget {
  const PlayVideoScreen({Key? key}) : super(key: key);

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {
  late final mk.Player player;
  late final mkv.VideoController controller;
  late final VideoItem video;
  final SimplePip pip = SimplePip();

  bool showControls = true;
  double playbackRate = 1.0;
  BoxFit videoFit = BoxFit.contain;
  Timer? hideTimer;

  @override
  void initState() {
    super.initState();
    video = context.read<VideosBloc>().state.currentVideo!;
    player = mk.Player();
    controller = mkv.VideoController(player);
    player.open(mk.Media(video.path), play: true);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => showControls = !showControls);
    if (showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => showControls = false);
    });
  }

  Future<void> _seekRelative(Duration delta) async {
    final position = player.state.position + delta;
    final safePosition = position < Duration.zero ? Duration.zero : position;
    await player.seek(safePosition);
    if (!showControls) setState(() => showControls = true);
    _scheduleHideControls();
  }

  Future<void> _setRate(double rate) async {
    await player.setRate(rate);
    setState(() => playbackRate = rate);
    _scheduleHideControls();
  }

  Future<void> _enterPip() async {
    if (await SimplePip.isPipAvailable) {
      await pip.enterPipMode();
    }
  }

  void _toggleFit() {
    setState(() {
      videoFit = videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.localPosition.dx < width / 2) {
              _seekRelative(const Duration(seconds: -10));
            } else {
              _seekRelative(const Duration(seconds: 10));
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: mkv.Video(
                  controller: controller,
                  fit: videoFit,
                  controls: mkv.NoVideoControls,
                ),
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
                    onBack: () => Navigator.pop(context),
                    onPip: _enterPip,
                    onToggleFit: _toggleFit,
                    onRateSelected: _setRate,
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
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final mk.Player player;
  final String title;
  final double playbackRate;
  final bool isCover;
  final VoidCallback onBack;
  final VoidCallback onPip;
  final VoidCallback onToggleFit;
  final ValueChanged<double> onRateSelected;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onInteracted;

  const _VideoControls({
    required this.player,
    required this.title,
    required this.playbackRate,
    required this.isCover,
    required this.onBack,
    required this.onPip,
    required this.onToggleFit,
    required this.onRateSelected,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onInteracted,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Color(0x22000000),
            Color(0xCC000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          _TopBar(
            title: title,
            playbackRate: playbackRate,
            isCover: isCover,
            onBack: onBack,
            onPip: onPip,
            onToggleFit: onToggleFit,
            onRateSelected: onRateSelected,
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
                      icon: Icons.replay_10,
                      onPressed: () {
                        onSeekBack();
                        onInteracted();
                      },
                    ),
                    const SizedBox(width: 18),
                    _CircleButton(
                      icon: playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 74,
                      iconSize: 46,
                      onPressed: () {
                        playing ? player.pause() : player.play();
                        onInteracted();
                      },
                    ),
                    const SizedBox(width: 18),
                    _CircleButton(
                      icon: Icons.forward_10,
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
            left: 14,
            right: 14,
            bottom: 12,
            child: _ProgressBar(player: player),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final double playbackRate;
  final bool isCover;
  final VoidCallback onBack;
  final VoidCallback onPip;
  final VoidCallback onToggleFit;
  final ValueChanged<double> onRateSelected;

  const _TopBar({
    required this.title,
    required this.playbackRate,
    required this.isCover,
    required this.onBack,
    required this.onPip,
    required this.onToggleFit,
    required this.onRateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      right: 4,
      top: 4,
      child: Row(
        children: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: isCover ? 'Fit screen' : 'Fill screen',
            color: Colors.white,
            icon: Icon(isCover ? Icons.fit_screen : Icons.crop_free),
            onPressed: onToggleFit,
          ),
          IconButton(
            tooltip: 'Picture in picture',
            color: Colors.white,
            icon: const Icon(Icons.picture_in_picture_alt),
            onPressed: onPip,
          ),
          PopupMenuButton<double>(
            tooltip: 'Playback speed',
            initialValue: playbackRate,
            onSelected: onRateSelected,
            color: const Color(0xFF1A1D24),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0.5, child: Text('0.5x')),
              PopupMenuItem(value: 1.0, child: Text('1x')),
              PopupMenuItem(value: 1.25, child: Text('1.25x')),
              PopupMenuItem(value: 1.5, child: Text('1.5x')),
              PopupMenuItem(value: 2.0, child: Text('2x')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${_formatRate(playbackRate)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) return rate.toInt().toString();
    return rate.toString();
  }
}

class _ProgressBar extends StatelessWidget {
  final mk.Player player;

  const _ProgressBar({required this.player});

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

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs,
                    value: value,
                    activeColor: const Color(0xFFE53935),
                    inactiveColor: Colors.white24,
                    onChanged: (newValue) {
                      player.seek(
                        Duration(milliseconds: newValue.round()),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
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
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    this.size = 58,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.52),
          shape: BoxShape.circle,
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
