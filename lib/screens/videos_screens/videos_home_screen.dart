import 'dart:io';

import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

class VideosHomeScreen extends StatefulWidget {
  VideosHomeScreen({Key? key}) : super(key: key);

  @override
  State<VideosHomeScreen> createState() => _VideosHomeScreenState();
}

class _VideosHomeScreenState extends State<VideosHomeScreen> {
  List<Video>? videos;

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
                  .videosPathsEntity!
                  .length,
              itemBuilder: (ctx, index) {
                return Container(
                  color: Colors.blue,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        ctx,
                        AppRouter.folderVideos,
                        arguments: index,
                        /*BlocProvider.of<VideosBloc>(context)
                            .videosPathsEntity![index]*/
                      );
                    },
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Folder name: ${BlocProvider.of<VideosBloc>(context).videosPathsEntity![index].name}',
                          ),
                          Text(
                              'number of videos: ${BlocProvider.of<VideosBloc>(context).entities_lenght[BlocProvider.of<VideosBloc>(context).videosPathsEntity![index].id]}'),
                        ],
                      ),
                    ),
                  ),
                );
              });
        },
      ),
    );
  }
}
