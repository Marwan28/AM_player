import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:am_player/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum VideoSortMode { dateDesc, nameAsc, sizeDesc, durationDesc }

class FolderVideosScreen extends StatefulWidget {
  const FolderVideosScreen({super.key});

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  VideoFolder? folder;
  bool gridMode = false;
  VideoSortMode sortMode = VideoSortMode.dateDesc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VideoFolder && folder?.id != args.id) {
      folder = args;
      context.read<VideosBloc>().add(OpenVideoFolderEvent(args.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = folder;
    if (currentFolder == null) {
      return const Scaffold(
        body: AmSurface(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      body: AmSurface(
        child: Column(
          children: [
            AmTopBar(
              title: currentFolder.name,
              subtitle: '${currentFolder.count} items',
              onBack: () => Navigator.pop(context),
              showSearch: true,
              actions: [
                AmIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onPressed: () {
                    context.read<VideosBloc>().add(const RefreshVideosEvent());
                    context
                        .read<VideosBloc>()
                        .add(OpenVideoFolderEvent(currentFolder.id));
                  },
                ),
              ],
            ),
            _FolderToolbar(
              gridMode: gridMode,
              onGridChanged: (value) => setState(() => gridMode = value),
              sortMode: sortMode,
              onSortChanged: (value) => setState(() => sortMode = value),
            ),
            Expanded(
              child: BlocBuilder<VideosBloc, VideosState>(
                builder: (context, state) {
                  final videos = state.videosForFolder(currentFolder.id);
                  if (videos.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final sortedVideos = _sortedVideos(videos);
                  return CustomScrollView(
                    slivers: [
                      if (gridMode)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 16.h),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.crossAxisExtent;
                              final columns = width > 640
                                  ? 4
                                  : width > 430
                                      ? 3
                                      : 2;
                              return SliverGrid.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: 0.78,
                                  crossAxisSpacing: 10.w,
                                  mainAxisSpacing: 10.h,
                                ),
                                itemCount: sortedVideos.length,
                                itemBuilder: (ctx, index) {
                                  return _VideoGridTile(
                                    video: sortedVideos[index],
                                  );
                                },
                              );
                            },
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount: sortedVideos.length,
                          itemBuilder: (ctx, index) {
                            return _VideoRow(
                              video: sortedVideos[index],
                            );
                          },
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: 14.h)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<VideoItem> _sortedVideos(List<VideoItem> videos) {
    final sorted = [...videos];
    switch (sortMode) {
      case VideoSortMode.dateDesc:
        sorted.sort((a, b) => b.modifiedMs.compareTo(a.modifiedMs));
        break;
      case VideoSortMode.nameAsc:
        sorted.sort(
          (a, b) => a.displayTitle
              .toLowerCase()
              .compareTo(b.displayTitle.toLowerCase()),
        );
        break;
      case VideoSortMode.sizeDesc:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case VideoSortMode.durationDesc:
        sorted.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
    }
    return sorted;
  }
}

class _FolderToolbar extends StatelessWidget {
  final bool gridMode;
  final ValueChanged<bool> onGridChanged;
  final VideoSortMode sortMode;
  final ValueChanged<VideoSortMode> onSortChanged;

  const _FolderToolbar({
    required this.gridMode,
    required this.onGridChanged,
    required this.sortMode,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          PopupMenuButton<VideoSortMode>(
            initialValue: sortMode,
            onSelected: onSortChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: VideoSortMode.dateDesc,
                child: Text('Date modified'),
              ),
              PopupMenuItem(
                value: VideoSortMode.nameAsc,
                child: Text('Name'),
              ),
              PopupMenuItem(
                value: VideoSortMode.sizeDesc,
                child: Text('Size'),
              ),
              PopupMenuItem(
                value: VideoSortMode.durationDesc,
                child: Text('Duration'),
              ),
            ],
            child: _ToolbarChip(
              icon: Icons.swap_vert_rounded,
              label: _sortLabel(sortMode),
              active: true,
              onTap: null,
            ),
          ),
          const Spacer(),
          _ToolbarChip(
            label: 'Grid',
            active: gridMode,
            onTap: () => onGridChanged(true),
          ),
          SizedBox(width: 6.w),
          _ToolbarChip(
            label: 'List',
            active: !gridMode,
            onTap: () => onGridChanged(false),
          ),
        ],
      ),
    );
  }

  static String _sortLabel(VideoSortMode mode) {
    switch (mode) {
      case VideoSortMode.dateDesc:
        return 'Date modified';
      case VideoSortMode.nameAsc:
        return 'Name';
      case VideoSortMode.sizeDesc:
        return 'Size';
      case VideoSortMode.durationDesc:
        return 'Duration';
    }
  }
}

class _ToolbarChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ToolbarChip({
    this.icon,
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: active ? colors.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.sp),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  final VideoItem video;

  const _VideoRow({required this.video});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        context.read<VideosBloc>().add(SelectVideoEvent(video));
        Navigator.pushNamed(context, AppRouter.playVideo, arguments: video);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 138.w,
              height: 78.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(
                    assetId: video.assetId,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 21.sp,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5.w,
                    bottom: 5.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        amFormatDuration(video.duration),
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '${video.width}p - ${amFormatSize(video.sizeBytes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 2.h,
                    children: [
                      _ActionChip(
                        icon: Icons.drive_file_rename_outline_rounded,
                        label: 'Rename',
                        onTap: () => _showRenameDialog(context, video),
                      ),
                      _ActionChip(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
                      _ActionChip(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        danger: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, VideoItem video) {
    final controller = TextEditingController(text: video.displayTitle);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename video'),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<VideosBloc>().add(
                      RenameVideoEvent(
                        video: video,
                        newBaseName: controller.text,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _VideoGridTile extends StatelessWidget {
  final VideoItem video;

  const _VideoGridTile({required this.video});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        context.read<VideosBloc>().add(SelectVideoEvent(video));
        Navigator.pushNamed(context, AppRouter.playVideo, arguments: video);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(
                    assetId: video.assetId,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8.r),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 21.sp,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5.w,
                    bottom: 5.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        amFormatDuration(video.duration),
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 7.h, 8.w, 2.h),
              child: Text(
                video.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
              child: Text(
                amFormatSize(video.sizeBytes),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppTheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.sp, color: color),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
