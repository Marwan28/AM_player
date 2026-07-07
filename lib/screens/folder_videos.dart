import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderVideosScreen extends StatefulWidget {
  const FolderVideosScreen({Key? key}) : super(key: key);

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  VideoFolder? folder;

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
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171D),
        title: Text(
          currentFolder.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<VideosBloc>().add(const RefreshVideosEvent());
              context
                  .read<VideosBloc>()
                  .add(OpenVideoFolderEvent(currentFolder.id));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          final videos = state.videosForFolder(currentFolder.id);

          if (videos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 116,
              color: Color(0xFF262A33),
            ),
            itemBuilder: (ctx, index) {
              return _VideoRow(video: videos[index]);
            },
          );
        },
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  final VideoItem video;

  const _VideoRow({required this.video});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      leading: SizedBox(
        width: 92,
        height: 58,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoThumbnail(
              assetId: video.assetId,
              borderRadius: BorderRadius.circular(6),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Text(
                    _formatDuration(video.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        video.displayTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _formatSize(video.sizeBytes),
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: IconButton(
        color: Colors.white70,
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showVideoActions(context, video),
      ),
      onTap: () {
        context.read<VideosBloc>().add(SelectVideoEvent(video));
        Navigator.pushNamed(context, AppRouter.playVideo);
      },
    );
  }

  void _showVideoActions(BuildContext context, VideoItem video) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                iconColor: Colors.white,
                textColor: Colors.white,
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRenameDialog(context, video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                iconColor: Colors.white,
                textColor: Colors.white,
                title: const Text('Details'),
                subtitle: Text(
                  video.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        );
      },
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

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours == 0) return '$minutes:$seconds';
    return '${twoDigits(hours)}:$minutes:$seconds';
  }

  static String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}
