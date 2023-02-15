import 'package:am_player/models/video.dart';
import 'package:flutter/material.dart';

class PlayVideoScreen extends StatefulWidget {
  PlayVideoScreen({Key? key}) : super(key: key);
  late Video video;

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {


  @override
  Widget build(BuildContext context) {
    widget.video = ModalRoute.of(context)?.settings.arguments as Video;
    return Scaffold(body: Container(child: Center(child: Text(widget.video.title,style: TextStyle(fontSize: 28,color: Colors.red,),),),),);
  }
}
