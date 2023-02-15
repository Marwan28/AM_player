import 'dart:io';

import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideosHomeScreen extends StatefulWidget {
  VideosHomeScreen({Key? key}) : super(key: key);

  @override
  State<VideosHomeScreen> createState() => _VideosHomeScreenState();
}

class _VideosHomeScreenState extends State<VideosHomeScreen> {
  List<Video>? videos;

  Widget listview() {
    return ListView.builder(
      itemBuilder: (ctx, index) {
        print('---------- listview builder');
        return Container(
          margin: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Image.memory(
                    BlocProvider.of<VideosBloc>(context).videos![index].image),
              ),
              Expanded(
                  child: Text(BlocProvider.of<VideosBloc>(context)
                      .videos![index]
                      .title))
            ],
          ),
        );
      },
      itemCount: BlocProvider.of<VideosBloc>(context).videos?.length ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          print('---------- bloc builder');
          return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: BlocProvider.of<VideosBloc>(context)
                  .videosPathsEntity!.length,
              itemBuilder: (ctx, index) {
                return Container(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      BlocProvider.of<VideosBloc>(context)
                          .videosPathsEntity![index]
                          .name,
                    ),
                  ),
                );
              });
        },
      ),
    );
  }
}
