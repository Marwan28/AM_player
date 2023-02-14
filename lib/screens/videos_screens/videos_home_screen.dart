import 'dart:io';

import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideosHomeScreen extends StatelessWidget {
  VideosHomeScreen({Key? key}) : super(key: key);
  List<Video>? videos;





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(itemBuilder: (ctx,index){
        return Container(
          margin: EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: Image.memory(BlocProvider.of<VideosBloc>(context).videos![index].image),),
            Expanded(child: Text(BlocProvider.of<VideosBloc>(context).videos![index].title))
          ],),
        );
      },itemCount: BlocProvider.of<VideosBloc>(context).videos?.length??0,),
    );
  }
}
