import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:am_player/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideosHomeScreen extends StatefulWidget {
  const VideosHomeScreen({super.key});

  @override
  State<VideosHomeScreen> createState() => _VideosHomeScreenState();
}

class _VideosHomeScreenState extends State<VideosHomeScreen>
    with AutomaticKeepAliveClientMixin<VideosHomeScreen> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state.isLoading && state.folders.isEmpty) {
          return const _CenteredProgress();
        }

        if (state.permissionDenied && state.folders.isEmpty) {
          return _MessageView(
            icon: Icons.folder_off_outlined,
            title: 'Media permission needed',
            message:
                'Allow access to videos so AM Player can build your library.',
            actionLabel: 'Try again',
            onAction: () {
              context.read<VideosBloc>().add(const RefreshVideosEvent());
            },
          );
        }

        if (state.folders.isEmpty) {
          return _MessageView(
            icon: Icons.video_library_outlined,
            title: 'No videos found',
            message:
                state.errorMessage ?? 'Pull to refresh after adding videos.',
            actionLabel: 'Refresh',
            onAction: () {
              context.read<VideosBloc>().add(const RefreshVideosEvent());
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<VideosBloc>().add(const RefreshVideosEvent());
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: AmAdBanner()),
              SliverToBoxAdapter(
                child: _SyncStrip(
                  isSyncing: state.isSyncing,
                  folderCount: state.folders.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: AmSectionHeader(label: 'Folders'),
              ),
              SliverList.builder(
                itemCount: state.folders.length,
                itemBuilder: (context, index) {
                  return _FolderRow(folder: state.folders[index]);
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _SyncStrip extends StatelessWidget {
  final bool isSyncing;
  final int folderCount;

  const _SyncStrip({
    required this.isSyncing,
    required this.folderCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$folderCount folders',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
            ),
          ),
          const Spacer(),
          if (isSyncing) ...[
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Syncing',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final VideoFolder folder;

  const _FolderRow({required this.folder});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openFolder(context, folder),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 98.w,
              height: 58.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(
                    assetId: folder.coverAssetId,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  Positioned(
                    left: 7.w,
                    top: 7.h,
                    child: Icon(
                      Icons.folder_rounded,
                      color: Colors.white,
                      size: 18.sp,
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
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${folder.count} items',
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
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageView({
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
            Icon(icon, color: colors.onSurfaceVariant, size: 50.sp),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13.sp),
            ),
            SizedBox(height: 18.h),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}

void _openFolder(BuildContext context, VideoFolder folder) {
  context.read<VideosBloc>().add(OpenVideoFolderEvent(folder.id));
  Navigator.pushNamed(
    context,
    AppRouter.folderVideos,
    arguments: folder,
  );
}
