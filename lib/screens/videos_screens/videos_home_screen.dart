import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VideosHomeScreen extends StatefulWidget {
  const VideosHomeScreen({Key? key}) : super(key: key);

  @override
  State<VideosHomeScreen> createState() => _VideosHomeScreenState();
}

class _VideosHomeScreenState extends State<VideosHomeScreen>
    with AutomaticKeepAliveClientMixin<VideosHomeScreen> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          if (state.isLoading && state.folders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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
                SliverToBoxAdapter(
                  child: _SyncHeader(
                    isSyncing: state.isSyncing,
                    folderCount: state.folders.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.92,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.folders.length,
                    itemBuilder: (ctx, index) {
                      return _FolderTile(folder: state.folders[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _SyncHeader extends StatelessWidget {
  final bool isSyncing;
  final int folderCount;

  const _SyncHeader({
    required this.isSyncing,
    required this.folderCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(
        children: [
          Text(
            '$folderCount folders',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (isSyncing) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Text(
              'Syncing',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final VideoFolder folder;

  const _FolderTile({required this.folder});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        context.read<VideosBloc>().add(OpenVideoFolderEvent(folder.id));
        Navigator.pushNamed(
          context,
          AppRouter.folderVideos,
          arguments: folder,
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox.expand(
                child: VideoThumbnail(
                  assetId: folder.coverAssetId,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 2),
              child: Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                '${folder.count} videos',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 52),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
