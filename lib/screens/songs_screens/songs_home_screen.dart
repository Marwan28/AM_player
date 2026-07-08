import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/models/song.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

class SongsHomeScreen extends StatefulWidget {
  const SongsHomeScreen({super.key});

  @override
  State<SongsHomeScreen> createState() => _SongsHomeScreenState();
}

class _SongsHomeScreenState extends State<SongsHomeScreen>
    with AutomaticKeepAliveClientMixin<SongsHomeScreen> {
  late final AudioPlayer audioPlayer;
  int currentIndex = 0;
  String currentPath = '';

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayer.setLoopMode(LoopMode.all);
    final bloc = context.read<SongsBloc>();
    if (bloc.allSongs?.isEmpty ?? true) {
      bloc.add(LoadSongsEvent());
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        final songs = context.read<SongsBloc>().allSongs ?? [];
        if (songs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: songs.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return const AmAdBanner();
                  if (index == 1) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.shuffle_rounded,
                              label: 'Shuffle all',
                              onTap: () {},
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Smart mix',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final song = songs[index - 2];
                  return _SongRow(
                    index: index - 1,
                    song: song,
                    active: currentPath == song.filePath,
                    playing:
                        audioPlayer.playing && currentPath == song.filePath,
                    onTap: () => _playSong(song, index - 2),
                  );
                },
              ),
            ),
            _MiniAudioPlayer(
              player: audioPlayer,
              title: currentPath.isEmpty
                  ? 'Nothing is playing'
                  : songs[currentIndex].title ?? 'Unknown track',
              onPrevious: _previous,
              onToggle: _togglePlay,
              onNext: _next,
            ),
          ],
        );
      },
    );
  }

  Future<void> _playSong(Song song, int index) async {
    final bloc = context.read<SongsBloc>();
    if (currentPath == song.filePath) {
      await _togglePlay();
      return;
    }

    currentIndex = index;
    currentPath = song.filePath ?? '';
    if ((bloc.songAudioSourceList ?? []).isNotEmpty) {
      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: bloc.songAudioSourceList!),
        initialIndex: currentIndex,
      );
    } else if (currentPath.isNotEmpty) {
      await audioPlayer.setFilePath(currentPath);
    }
    await audioPlayer.play();
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    if (currentPath.isEmpty) return;
    if (audioPlayer.playing) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _previous() async {
    if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
      await audioPlayer.play();
      currentIndex = audioPlayer.currentIndex ?? currentIndex;
      if (mounted) setState(() {});
    }
  }

  Future<void> _next() async {
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
      await audioPlayer.play();
      currentIndex = audioPlayer.currentIndex ?? currentIndex;
      if (mounted) setState(() {});
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final int index;
  final Song song;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  const _SongRow({
    required this.index,
    required this.song,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? AppTheme.primary : colors.onSurfaceVariant,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color:
                    active ? AppTheme.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.music_note_rounded,
                color: active ? Colors.white : colors.onSurfaceVariant,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title ?? 'Unknown track',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _songSubtitle(song),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            AmIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: 'More',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _songSubtitle(Song song) {
    final path = song.filePath;
    if (path == null || path.isEmpty) return 'Local audio';
    final parts = path.split(RegExp(r'[\\/]'));
    if (parts.length < 2) return 'Local audio';
    return parts[parts.length - 2];
  }
}

class _MiniAudioPlayer extends StatelessWidget {
  final AudioPlayer player;
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  const _MiniAudioPlayer({
    required this.player,
    required this.title,
    required this.onPrevious,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
                ),
              ),
              AmIconButton(
                icon: Icons.skip_previous_rounded,
                tooltip: 'Previous',
                onPressed: onPrevious,
              ),
              StreamBuilder<bool>(
                stream: player.playingStream,
                initialData: player.playing,
                builder: (context, snapshot) {
                  final playing = snapshot.data ?? false;
                  return Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: onToggle,
                    ),
                  );
                },
              ),
              AmIconButton(
                icon: Icons.skip_next_rounded,
                tooltip: 'Next',
                onPressed: onNext,
              ),
            ],
          ),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            initialData: Duration.zero,
            builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;
              final max = duration.inMilliseconds <= 0
                  ? 1.0
                  : duration.inMilliseconds.toDouble();
              return Slider(
                min: 0,
                max: max,
                value: position.inMilliseconds.clamp(0, max).toDouble(),
                activeColor: AppTheme.primary,
                inactiveColor: colors.surfaceContainerHighest,
                onChanged: (value) {
                  player.seek(Duration(milliseconds: value.round()));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
