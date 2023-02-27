import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class SongControls extends StatefulWidget {
  const SongControls({Key? key, required this.filePath}) : super(key: key);
  final String filePath;

  @override
  State<SongControls> createState() => _SongControlsState();
}

class _SongControlsState extends State<SongControls> {
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioPlayer.setFilePath(widget.filePath);
  }
  @override
  void dispose() {
    // TODO: implement dispose
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      if (!audioPlayer.playing) {
        return IconButton(
          onPressed: (){
            audioPlayer.play();
            setState(() {});
          },
          iconSize: 80,
          color: Colors.white,
          icon: Icon(Icons.play_arrow_rounded),
        );
      } else if (audioPlayer.playing) {
        return IconButton(
          onPressed: (){
            audioPlayer.pause();
            setState(() {});
          },
          iconSize: 80,
          color: Colors.white,
          icon: Icon(Icons.pause_rounded),
        );
      } else {
        return Icon(
          Icons.play_arrow_rounded,
          size: 80,
          color: Colors.white,
        );
      }

  }
}
