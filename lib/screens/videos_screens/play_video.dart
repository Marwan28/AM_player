import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  initController() async{
    await videoPlayerController.initialize();

  }

   @override
   void initState() {
     super.initState();
     video = BlocProvider.of<VideosBloc>(context).currentPlayingVideo;

     initController();
     videoPlayerController = VideoPlayerController.file(
         video.file);


     flickManager = FlickManager(
       videoPlayerController:
       videoPlayerController,
     );




     chewieController = ChewieController(
       videoPlayerController: videoPlayerController,
       autoPlay: true,
       looping: true,
     );
     playerWidget = Chewie(
       controller: chewieController,
     );


   }


  @override
  void dispose(){
    super.dispose();
    flickManager.dispose();
    chewieController.dispose();
    videoPlayerController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    print('--------- play video');
    return Scaffold(
      body: Container(
        child: FlickVideoPlayer(flickManager: flickManager),
        //child: playerWidget,
      ),
    );
  }
}
