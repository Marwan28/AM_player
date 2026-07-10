import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/controllers/audio_playback_controller.dart';
import 'package:am_player/models/song.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

enum _AudioView { songs, folders }

class SongsHomeScreen extends StatefulWidget {
  const SongsHomeScreen({super.key});

  @override
  State<SongsHomeScreen> createState() => _SongsHomeScreenState();
}

class _SongsHomeScreenState extends State<SongsHomeScreen>
    with AutomaticKeepAliveClientMixin<SongsHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  _AudioView view = _AudioView.songs;
  String? selectedFolderId;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<SongsBloc>();
    if (bloc.state.songs.isEmpty && !bloc.state.isSyncing) {
      bloc.add(const LoadSongsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bloc = context.read<SongsBloc>();

    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        final visibleSongs = state.visibleSongs;
        final visibleFolderSongs = state.visibleFolderSongs;
        final folders = _foldersFromSongs(visibleFolderSongs, state.sortMode);
        final selectedFolder = _selectedFolderFrom(folders);

        if (state.isLoading && state.songs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state.permissionDenied && state.songs.isEmpty) {
          return _AudioMessage(
            icon: Icons.library_music_outlined,
            title: 'Media permission needed',
            message: 'Allow audio access so AM Player can build your songs.',
            actionLabel: 'Try again',
            onAction: () => bloc.add(const LoadSongsEvent(refresh: true)),
          );
        }

        if (state.songs.isEmpty) {
          return _AudioMessage(
            icon: Icons.music_off_rounded,
            title: 'No songs found',
            message:
                state.errorMessage ?? 'Pull to refresh after adding audio.',
            actionLabel: 'Refresh',
            onAction: () => bloc.add(const LoadSongsEvent(refresh: true)),
          );
        }

        return Column(
          children: [
            _AudioHeader(
              state: state,
              onQueryChanged: (query) {
                bloc.add(SearchSongsEvent(query));
                if (selectedFolderId != null) {
                  setState(() => selectedFolderId = null);
                }
              },
              onSortChanged: (mode) {
                bloc.add(ChangeAudioSortEvent(mode));
              },
              onRefresh: () {
                bloc.add(const LoadSongsEvent(refresh: true));
              },
            ),
            _AudioQuickActions(
              songs: visibleSongs,
              onShuffle: () {
                bloc.add(ShuffleSongsEvent(visibleSongs));
              },
              onRecentlyAdded: () {
                bloc.add(
                  const ChangeAudioSortEvent(AudioSortMode.dateDesc),
                );
                setState(() {
                  view = _AudioView.songs;
                  selectedFolderId = null;
                });
              },
            ),
            _AudioViewTabs(
              view: view,
              onChanged: (value) {
                setState(() {
                  view = value;
                  selectedFolderId = null;
                });
              },
            ),
            if (view == _AudioView.songs)
              AmSectionHeader(label: '${visibleSongs.length} songs')
            else if (selectedFolder != null)
              _FolderBackHeader(
                title: selectedFolder.name,
                count: selectedFolder.songs.length,
                onBack: () => setState(() => selectedFolderId = null),
              )
            else
              AmSectionHeader(label: '${folders.length} folders'),
            Expanded(
              child: view == _AudioView.songs
                  ? _buildSongsViewport(visibleSongs, bloc)
                  : _buildFoldersViewport(folders, selectedFolder, bloc),
            ),
            AudioMiniPlayer(controller: bloc.playback),
          ],
        );
      },
    );
  }

  Widget _buildSongsViewport(List<Song> songs, SongsBloc bloc) {
    final showFastScroller = songs.length > 30;

    return Row(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const LoadSongsEvent(refresh: true));
            },
            child: _buildSongList(
              songs: songs,
              queue: songs,
              controller: _scrollController,
            ),
          ),
        ),
        if (showFastScroller)
          _AlphabetFastScroller(
            songs: songs,
            controller: _scrollController,
          ),
      ],
    );
  }

  Widget _buildFoldersViewport(
    List<_AudioFolder> folders,
    _AudioFolder? selectedFolder,
    SongsBloc bloc,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const LoadSongsEvent(refresh: true));
      },
      child: selectedFolder == null
          ? _buildFolderList(folders)
          : _buildSongList(
              songs: selectedFolder.songs,
              queue: selectedFolder.songs,
              controller: _scrollController,
            ),
    );
  }

  Widget _buildSongList({
    required List<Song> songs,
    required List<Song> queue,
    required ScrollController controller,
  }) {
    if (songs.isEmpty) {
      return _EmptyScrollable(controller: controller, message: 'No matches');
    }

    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: songs.length + 1,
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return SizedBox(height: 12.h);
        }
        return _SongRow(
          index: index + 1,
          song: songs[index],
          queue: queue,
        );
      },
    );
  }

  Widget _buildFolderList(List<_AudioFolder> folders) {
    if (folders.isEmpty) {
      return const _EmptyScrollable(message: 'No matches');
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: folders.length + 1,
      itemBuilder: (context, index) {
        if (index == folders.length) {
          return SizedBox(height: 12.h);
        }
        final folder = folders[index];
        return _AudioFolderRow(
          folder: folder,
          onTap: () => setState(() => selectedFolderId = folder.id),
        );
      },
    );
  }

  _AudioFolder? _selectedFolderFrom(List<_AudioFolder> folders) {
    for (final folder in folders) {
      if (folder.id == selectedFolderId) {
        return folder;
      }
    }
    return null;
  }

  List<_AudioFolder> _foldersFromSongs(List<Song> songs, AudioSortMode mode) {
    final map = <String, _AudioFolder>{};
    for (final song in songs) {
      final existing = map[song.folderId];
      if (existing == null) {
        map[song.folderId] = _AudioFolder(
          id: song.folderId,
          name: song.folderName,
          songs: [song],
          latestModifiedMs: song.modifiedMs,
        );
      } else {
        existing.songs.add(song);
        if (song.modifiedMs > existing.latestModifiedMs) {
          existing.latestModifiedMs = song.modifiedMs;
        }
      }
    }
    final folders = map.values.toList();
    switch (mode) {
      case AudioSortMode.dateDesc:
        folders
            .sort((a, b) => b.latestModifiedMs.compareTo(a.latestModifiedMs));
        break;
      case AudioSortMode.titleAsc:
        folders.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AudioSortMode.durationDesc:
      case AudioSortMode.sizeDesc:
        folders.sort((a, b) => b.songs.length.compareTo(a.songs.length));
        break;
    }
    return folders;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class _AudioHeader extends StatelessWidget {
  final SongsState state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AudioSortMode> onSortChanged;
  final VoidCallback onRefresh;

  const _AudioHeader({
    required this.state,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Column(
        children: [
          Row(
            children: [
              _CountChip(
                label: '${state.visibleSongs.length} songs',
                icon: Icons.library_music_rounded,
              ),
              SizedBox(width: 8.w),
              _CountChip(
                label: '${state.visibleFolderCount} folders',
                icon: Icons.folder_rounded,
              ),
              const Spacer(),
              if (state.isSyncing)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    color: AppTheme.primary,
                  ),
                ),
              AmIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: TextField(
                    onChanged: onQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search songs',
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18.sp,
                        color: colors.onSurfaceVariant,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 9.h),
                    ),
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              PopupMenuButton<AudioSortMode>(
                initialValue: state.sortMode,
                onSelected: onSortChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AudioSortMode.dateDesc,
                    child: Text('Date modified'),
                  ),
                  PopupMenuItem(
                    value: AudioSortMode.titleAsc,
                    child: Text('Name'),
                  ),
                  PopupMenuItem(
                    value: AudioSortMode.durationDesc,
                    child: Text('Duration'),
                  ),
                  PopupMenuItem(
                    value: AudioSortMode.sizeDesc,
                    child: Text('Size'),
                  ),
                ],
                child: _IconChip(
                  icon: Icons.swap_vert_rounded,
                  label: _sortLabel(state.sortMode),
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.primary, fontSize: 11.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _sortLabel(AudioSortMode mode) {
    switch (mode) {
      case AudioSortMode.dateDesc:
        return 'Date';
      case AudioSortMode.titleAsc:
        return 'Name';
      case AudioSortMode.durationDesc:
        return 'Duration';
      case AudioSortMode.sizeDesc:
        return 'Size';
    }
  }
}

class _AudioQuickActions extends StatelessWidget {
  final List<Song> songs;
  final VoidCallback onShuffle;
  final VoidCallback onRecentlyAdded;

  const _AudioQuickActions({
    required this.songs,
    required this.onShuffle,
    required this.onRecentlyAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle all',
              onTap: songs.isEmpty ? null : onShuffle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _QuickAction(
              icon: Icons.schedule_rounded,
              label: 'Recently added',
              onTap: onRecentlyAdded,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioViewTabs extends StatelessWidget {
  final _AudioView view;
  final ValueChanged<_AudioView> onChanged;

  const _AudioViewTabs({
    required this.view,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              icon: Icons.music_note_rounded,
              label: 'Songs',
              active: view == _AudioView.songs,
              onTap: () => onChanged(_AudioView.songs),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _SegmentButton(
              icon: Icons.folder_rounded,
              label: 'Folders',
              active: view == _AudioView.folders,
              onTap: () => onChanged(_AudioView.folders),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final int index;
  final Song song;
  final List<Song> queue;

  const _SongRow({
    required this.index,
    required this.song,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SongsBloc>();
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: bloc.playback,
      builder: (context, _) {
        final active = bloc.playback.currentSong?.id == song.id;
        return InkWell(
          onTap: () {
            bloc.add(PlaySongEvent(song: song, queue: queue));
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38.w,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$index',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            active ? AppTheme.primary : colors.onSurfaceVariant,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                _AudioArt(
                    active: active, playing: bloc.playback.player.playing),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${song.subtitle} - ${amFormatDuration(song.duration)}',
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
                  onPressed: () => _showSongOptions(context, song),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(song.displayTitle),
                  subtitle: Text(song.filePath),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(song.folderName),
                  subtitle: Text(amFormatSize(song.sizeBytes)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlphabetFastScroller extends StatefulWidget {
  final List<Song> songs;
  final ScrollController controller;

  const _AlphabetFastScroller({
    required this.songs,
    required this.controller,
  });

  @override
  State<_AlphabetFastScroller> createState() => _AlphabetFastScrollerState();
}

class _AlphabetFastScrollerState extends State<_AlphabetFastScroller> {
  bool dragging = false;
  String? activeLabel;

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsFromSongs(widget.songs);
    if (sections.length < 2) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final activeIndex = activeLabel == null
        ? -1
        : sections.indexWhere((section) => section.label == activeLabel);

    return SizedBox(
      width: 24.w,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallbackHeight =
              (sections.length * 13.h).clamp(190.h, 430.h).toDouble();
          final trackHeight =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : fallbackHeight;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) => _handleTouch(
              details.localPosition.dy,
              trackHeight,
              sections,
            ),
            onVerticalDragStart: (details) => _handleTouch(
              details.localPosition.dy,
              trackHeight,
              sections,
            ),
            onVerticalDragUpdate: (details) => _handleTouch(
              details.localPosition.dy,
              trackHeight,
              sections,
            ),
            onTapUp: (_) => _finishTouch(),
            onTapCancel: _finishTouch,
            onVerticalDragEnd: (_) => _finishTouch(),
            onVerticalDragCancel: _finishTouch,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 18.w,
                height: trackHeight,
                padding: EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  color: dragging
                      ? colors.surface.withValues(alpha: 0.82)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999.r),
                  border: dragging
                      ? Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.18),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 90),
                        style: TextStyle(
                          color: i == activeIndex
                              ? AppTheme.primary
                              : colors.onSurfaceVariant.withValues(
                                  alpha: dragging ? 0.92 : 0.56,
                                ),
                          fontSize: i == activeIndex ? 9.5.sp : 7.5.sp,
                          fontWeight: i == activeIndex
                              ? FontWeight.w900
                              : FontWeight.w800,
                          height: 1,
                        ),
                        child: Text(
                          sections[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTouch(
    double localDy,
    double height,
    List<_FastScrollSection> sections,
  ) {
    final normalized =
        height <= 0 ? 0.0 : (localDy.clamp(0.0, height) / height);
    final index = (normalized * (sections.length - 1))
        .round()
        .clamp(0, sections.length - 1);
    final section = sections[index];

    if (!dragging || activeLabel != section.label) {
      setState(() {
        dragging = true;
        activeLabel = section.label;
      });
    }

    _jumpToSection(section);
  }

  void _finishTouch() {
    if (!dragging) return;
    setState(() => dragging = false);
  }

  void _jumpToSection(_FastScrollSection section) {
    if (!widget.controller.hasClients) return;

    final maxScroll = widget.controller.position.maxScrollExtent;
    final rowExtent = 67.h;
    final estimatedTarget = section.songIndex * rowExtent;
    final proportionalTarget =
        maxScroll * (section.songIndex / widget.songs.length);
    final target =
        (estimatedTarget > maxScroll ? proportionalTarget : estimatedTarget)
            .clamp(0.0, maxScroll)
            .toDouble();
    widget.controller.jumpTo(target);
  }

  List<_FastScrollSection> _sectionsFromSongs(List<Song> songs) {
    final sections = <_FastScrollSection>[];
    final seen = <String>{};

    for (var i = 0; i < songs.length; i++) {
      final label = _sectionLabel(songs[i]);
      if (seen.add(label)) {
        sections.add(_FastScrollSection(label: label, songIndex: i));
      }
    }

    return sections;
  }

  String _sectionLabel(Song song) {
    final title = song.displayTitle.trim();
    if (title.isEmpty) return '#';

    final rune = title.runes.first;
    final char = String.fromCharCode(rune);
    if (RegExp(r'[0-9]').hasMatch(char)) return '#';
    if (RegExp(r'[a-zA-Z]').hasMatch(char)) return char.toUpperCase();
    return char;
  }
}

class _FastScrollSection {
  final String label;
  final int songIndex;

  const _FastScrollSection({
    required this.label,
    required this.songIndex,
  });
}

class AudioMiniPlayer extends StatelessWidget {
  final AudioPlaybackController controller;

  const AudioMiniPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.currentSong;
        if (song == null) return const SizedBox.shrink();

        return InkWell(
          onTap: () => _showFullPlayer(context, controller),
          child: Container(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _AudioArt(active: true, playing: controller.player.playing),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            song.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MiniControl(
                      icon: Icons.shuffle_rounded,
                      tooltip: 'Shuffle',
                      active: controller.shuffleEnabled,
                      onPressed: controller.toggleShuffle,
                    ),
                    _MiniControl(
                      icon: Icons.skip_previous_rounded,
                      tooltip: 'Previous',
                      onPressed: controller.previous,
                    ),
                    _PlayPauseButton(controller: controller, size: 40.w),
                    _MiniControl(
                      icon: Icons.skip_next_rounded,
                      tooltip: 'Next',
                      onPressed: controller.next,
                    ),
                    _MiniControl(
                      icon: controller.repeatIcon(),
                      tooltip: 'Repeat ${controller.repeatLabel()}',
                      active: controller.repeatMode != LoopMode.off,
                      onPressed: controller.cycleRepeatMode,
                    ),
                  ],
                ),
                _AudioProgressBar(controller: controller, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullPlayer(
    BuildContext context,
    AudioPlaybackController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: _AudioPlayerSheet(controller: controller),
        );
      },
    );
  }
}

class _AudioPlayerSheet extends StatelessWidget {
  final AudioPlaybackController controller;

  const _AudioPlayerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Now playing',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AmIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
                children: [
                  Container(
                    height: 210.h.clamp(150.0, 260.0).toDouble(),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.primary,
                      size: 82.sp,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    song.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    song.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _AudioProgressBar(controller: controller),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundControl(
                        icon: Icons.shuffle_rounded,
                        active: controller.shuffleEnabled,
                        onPressed: controller.toggleShuffle,
                      ),
                      SizedBox(width: 10.w),
                      _RoundControl(
                        icon: Icons.skip_previous_rounded,
                        onPressed: controller.previous,
                      ),
                      SizedBox(width: 12.w),
                      _PlayPauseButton(controller: controller, size: 58.w),
                      SizedBox(width: 12.w),
                      _RoundControl(
                        icon: Icons.skip_next_rounded,
                        onPressed: controller.next,
                      ),
                      SizedBox(width: 10.w),
                      _RoundControl(
                        icon: controller.repeatIcon(),
                        label: controller.repeatLabel(),
                        active: controller.repeatMode != LoopMode.off,
                        onPressed: controller.cycleRepeatMode,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _IconChip(
                          icon: Icons.speed_rounded,
                          label: '${_formatSpeed(controller.speed)}x',
                          onTap: () => _showSpeedSheet(context, controller),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _IconChip(
                          icon: Icons.queue_music_rounded,
                          label: '${controller.queue.length} queued',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _LiveQueuePanel(controller: controller),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSpeedSheet(
    BuildContext context,
    AudioPlaybackController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final speed in const [0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
                  ChoiceChip(
                    label: Text('${_formatSpeed(speed)}x'),
                    selected: controller.speed == speed,
                    onSelected: (_) {
                      controller.setSpeed(speed);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSpeed(double speed) {
    if (speed == speed.roundToDouble()) return speed.toInt().toString();
    return speed.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }
}

class _LiveQueuePanel extends StatefulWidget {
  final AudioPlaybackController controller;

  const _LiveQueuePanel({required this.controller});

  @override
  State<_LiveQueuePanel> createState() => _LiveQueuePanelState();
}

class _LiveQueuePanelState extends State<_LiveQueuePanel> {
  final ScrollController _queueScrollController = ScrollController();
  int _lastIndex = -1;

  @override
  void dispose() {
    _queueScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final queue = widget.controller.queue;
        final currentIndex = widget.controller.currentIndex;
        final playing = widget.controller.player.playing;
        _scrollToCurrent(currentIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AmSectionHeader(label: 'Queue'),
            Container(
              height: 248.h.clamp(180.0, 320.0).toDouble(),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ListView.builder(
                controller: _queueScrollController,
                primary: false,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  return _QueueRow(
                    index: index + 1,
                    song: queue[index],
                    active: index == currentIndex,
                    playing: playing && index == currentIndex,
                    onTap: () => widget.controller.playAt(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _scrollToCurrent(int currentIndex) {
    if (currentIndex < 0 || currentIndex == _lastIndex) return;
    _lastIndex = currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_queueScrollController.hasClients) return;
      final target = (currentIndex * 50.h).clamp(
        0.0,
        _queueScrollController.position.maxScrollExtent,
      );
      _queueScrollController.animateTo(
        target.toDouble(),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _AudioProgressBar extends StatelessWidget {
  final AudioPlaybackController controller;
  final bool dense;

  const _AudioProgressBar({
    required this.controller,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<Duration>(
      stream: controller.player.positionStream,
      initialData: controller.player.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: controller.player.durationStream,
          initialData: controller.player.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
            final value = position.inMilliseconds.clamp(0, max).toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: dense ? 2 : 4,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: dense ? 4 : 7,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: max,
                    value: value,
                    activeColor: AppTheme.primary,
                    inactiveColor: colors.surfaceContainerHighest,
                    onChanged: (value) {
                      controller.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                if (!dense)
                  Row(
                    children: [
                      Text(
                        amFormatDuration(position),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        amFormatDuration(duration),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
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
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlaybackController controller;
  final double size;

  const _PlayPauseButton({
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: controller.player.playingStream,
      initialData: controller.player.playing,
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              color: Colors.white,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: size * 0.58,
              ),
              onPressed: controller.togglePlay,
            ),
          ),
        );
      },
    );
  }
}

class _MiniControl extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;

  const _MiniControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 32.w,
        height: 38.w,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          color: active ? AppTheme.primary : colors.onSurfaceVariant,
          icon: Icon(icon, size: 20.sp),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _AudioFolderRow extends StatelessWidget {
  final _AudioFolder folder;
  final VoidCallback onTap;

  const _AudioFolderRow({
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: AppTheme.primary,
                size: 25.sp,
              ),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${folder.songs.length} songs',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderBackHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onBack;

  const _FolderBackHeader({
    required this.title,
    required this.count,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 0),
      child: Row(
        children: [
          AmIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              '$title - $count songs',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final int index;
  final Song song;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  const _QueueRow({
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
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34.w,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$index',
                  maxLines: 1,
                  style: TextStyle(
                    color: active ? AppTheme.primary : colors.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Icon(
              playing ? Icons.equalizer_rounded : Icons.music_note_rounded,
              color: active ? AppTheme.primary : colors.onSurfaceVariant,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                song.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppTheme.primary : colors.onSurface,
                  fontSize: 12.sp,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              amFormatDuration(song.duration),
              style: TextStyle(
                color: active ? AppTheme.primary : colors.onSurfaceVariant,
                fontSize: 10.sp,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioArt extends StatelessWidget {
  final bool active;
  final bool playing;

  const _AudioArt({
    required this.active,
    required this.playing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        active && playing ? Icons.equalizer_rounded : Icons.music_note_rounded,
        color: active ? Colors.white : colors.onSurfaceVariant,
        size: 22.sp,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

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
              decoration: BoxDecoration(
                color: onTap == null
                    ? colors.onSurfaceVariant.withValues(alpha: 0.25)
                    : AppTheme.primary,
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

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 38.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : colors.onSurfaceVariant,
              size: 16.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : colors.onSurfaceVariant,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool active;
  final VoidCallback onPressed;

  const _RoundControl({
    required this.icon,
    required this.onPressed,
    this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: label ?? '',
      child: SizedBox(
        width: 44.w,
        height: 44.w,
        child: IconButton(
          style: IconButton.styleFrom(
            backgroundColor:
                active ? AppTheme.primary : colors.surfaceContainerHighest,
            foregroundColor: active ? Colors.white : colors.onSurface,
          ),
          icon: Icon(icon, size: 22.sp),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _IconChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: colors.onSurfaceVariant),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: colors.onSurfaceVariant),
          SizedBox(width: 5.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 104.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _AudioMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 48.sp),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 7.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.sp),
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _EmptyScrollable extends StatelessWidget {
  final ScrollController? controller;
  final String message;

  const _EmptyScrollable({
    required this.message,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: 96.h),
        Center(
          child: Text(
            message,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.sp),
          ),
        ),
      ],
    );
  }
}

class _AudioFolder {
  final String id;
  final String name;
  final List<Song> songs;
  int latestModifiedMs;

  _AudioFolder({
    required this.id,
    required this.name,
    required this.songs,
    required this.latestModifiedMs,
  });
}
