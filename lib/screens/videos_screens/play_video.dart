import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:video_viewer/video_viewer.dart';

class PlayVideoScreen extends StatefulWidget {
  const PlayVideoScreen({Key? key}) : super(key: key);

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {
  late Video video;
  final VideoViewerController videoViewerController = VideoViewerController();
  late VideoViewer videoViewer;
  late VideoPlayerController videoPlayerController;

  @override
  void initState() {
    super.initState();
    video = BlocProvider.of<VideosBloc>(context).currentPlayingVideo;
    videoPlayerController = VideoPlayerController.file(
      video.file,
      videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: true, mixWithOthers: true),
    )..initialize();

    videoViewer = VideoViewer(
      language: VideoViewerLanguage.en,
      style: VideoViewerStyle(
        header: Row(
          children: [
            Flexible(
              child: Text(
                video.title,
                style: const TextStyle(color: Colors.white,overflow: TextOverflow.ellipsis),
                maxLines: 1,
              ),
            ),
          ],
        ),
        volumeBarStyle: VolumeBarStyle(
          alignment: Alignment.centerLeft,
          bar: BarStyle.volume(),
        ),
        progressBarStyle: ProgressBarStyle(
          backgroundColor: Colors.black.withOpacity(0.36),
          bar: BarStyle.progress(),
        ),
        playAndPauseStyle: PlayAndPauseWidgetStyle(
          background: const Color(0xFF295acc).withOpacity(0.5),
          circleRadius: 40,
        ),
        forwardAndRewindStyle: ForwardAndRewindStyle(
          bar: BarStyle.progress(),
        ),
        // settingsStyle: SettingsMenuStyle(items: [
        //   SettingsMenuItem(
        //     secondaryMenu: Icon(
        //       Icons.settings_outlined,
        //       color: Colors.white,
        //       size: 20,
        //     ),
        //     mainMenu: Icon(
        //       Icons.settings_outlined,
        //       color: Colors.white,
        //       size: 20,
        //     ),
        //   ),
        // ],),
      ),
      enableFullscreenScale: true,
      onFullscreenFixLandscape: false,
      volumeManager: VideoViewerVolumeManager.video,
      controller: videoViewerController,
      autoPlay: true,
      looping: true,
      source: {
        "SubRip Text": VideoSource(
          video: VideoPlayerController.file(
            video.file,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: true,
            ),
          ),
        ),
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    videoViewerController.dispose();
    videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AspectRatio(
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        child: SafeArea(child: videoViewer),
      ),
    );
  }
}
