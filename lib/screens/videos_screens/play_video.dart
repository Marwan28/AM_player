import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PlayVideoScreen extends StatefulWidget {
  PlayVideoScreen({Key? key}) : super(key: key);

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {
  late Video video;

  late FlickManager flickManager;

  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;
  late Chewie playerWidget;
  late FlickVideoPlayer flickVideoPlayerWidget;

  initController() async {
    await videoPlayerController.initialize();
  }

  @override
  void initState() {
    super.initState();
    video = BlocProvider.of<VideosBloc>(context).currentPlayingVideo;

    videoPlayerController = VideoPlayerController.file(video.file,videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true,mixWithOthers: true));
    initController();

    flickManager = FlickManager(
      autoPlay: false,
      videoPlayerController: videoPlayerController,
    );


    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      //allowFullScreen: true,
      autoPlay: true,
      looping: true,
      autoInitialize: true,
      fullScreenByDefault: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.black,
        handleColor: Colors.green,
      ),
      playbackSpeeds : const [0.125,0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2,2.25,2.5,2.75,3,],
      aspectRatio: video.assetEntity.size.aspectRatio,
      placeholder: Center(child: CircularProgressIndicator(),),
      //overlay: Center(child: CircularProgressIndicator(color: Colors.red,)),
      //customControls: Row(children: [IconButton(onPressed: (){}, icon: Icon(Icons.add))],),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        );
      },
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
              onTap: () {
                print('option 1 pressed');
              },
              iconData: Icons.chat,
              title: 'option 1'),
        ];
      },
    );

    flickVideoPlayerWidget = FlickVideoPlayer(
      flickManager: flickManager,
      systemUIOverlay: SystemUiOverlay.values,
      //systemUIOverlayFullscreen: SystemUiOverlay.values,
      flickVideoWithControlsFullscreen: FlickVideoWithControls(
        playerLoadingFallback: const Center(
          child: CircularProgressIndicator(),
        ),
        playerErrorFallback: const Center(
          child: Icon(
            Icons.error,
            color: Colors.white,
          ),
        ),
        videoFit: BoxFit.contain,
        controls: FlickPortraitControls(
          iconSize: 20,
          fontSize: 12,
          progressBarSettings: FlickProgressBarSettings(
            height: 10,
            playedColor: Colors.red,
            handleColor: Colors.green,
            handleRadius: 5,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            curveRadius: 5,
          ),
        ),
      ),
      flickVideoWithControls: FlickVideoWithControls(
        playerLoadingFallback: const Center(
          child: CircularProgressIndicator(),
        ),
        playerErrorFallback: const Center(
          child: Icon(
            Icons.error,
            color: Colors.white,
          ),
        ),
        videoFit: BoxFit.contain,
        controls: FlickPortraitControls(
          iconSize: 20,
          fontSize: 12,
          progressBarSettings: FlickProgressBarSettings(
            height: 10,
            playedColor: Colors.red,
            handleColor: Colors.green,
            handleRadius: 5,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            curveRadius: 5,
          ),
        ),
      ),
    );
    playerWidget = Chewie(
      controller: chewieController,
    );
  }

  @override
  void dispose() {
    super.dispose();
    flickManager.dispose();
    chewieController.dispose();
    videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('--------- play video');
    // return Scaffold(
    //   body: AspectRatio(
    //     aspectRatio: 0.5625,
    //     child: BetterPlayer.file(
    //       "file:///storage/emulated/0/Movies/videos/v1/7e15116667506b7dd65d94357412f13b.mp4",
    //       betterPlayerConfiguration: BetterPlayerConfiguration(
    //         aspectRatio:0.5625,
    //       ),
    //     ),
    //     //child: BetterPlayer.file('${widget.video.uri}',betterPlayerConfiguration: BetterPlayerConfiguration(aspectRatio: 16/9,controlsConfiguration: BetterPlayerControlsConfiguration(),autoPlay: true,),),
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        color: Colors.red,
        //child: flickVideoPlayerWidget,
        child: playerWidget,
      ),
    );
  }
}
