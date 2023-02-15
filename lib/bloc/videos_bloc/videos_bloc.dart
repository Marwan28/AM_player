import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:am_player/models/video.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

part 'videos_event.dart';

part 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  List<AssetPathEntity>? videosPathsEntity;
  List<String>? videosPaths;
  List<Video>? videos=[];

  VideosBloc() : super(VideosLoadingState()) {
    on<VideosEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<LoadVideosEvent>((event, emit)async {
      await loadVideos(emit);

    });
  }

  loadVideos(Emitter emit) async {
    videosPathsEntity =
        await PhotoManager.getAssetPathList(type: RequestType.video);
    print('---------- videos ----------');
    videosPathsEntity!.removeAt(0);
    //print(videosPathsEntity);
    for (int i = 0; i < videosPathsEntity!.length; i++) {
      final List<AssetEntity> entities =
          await videosPathsEntity![i].getAssetListRange(start: 0, end: 80);
      for (AssetEntity asset in entities) {
        File? file = await asset.file;

        videosPaths?.add(file!.path);
        print(asset.title);
        print(file!.path);
        videos?.add(Video(
            title: asset.title!,
            path: file.path,
            duration: asset.duration,
          image: (await asset.thumbnailData)!,
            ));
        //print(' marwan\'file video path: ${file!.path}');
      }
    }
    print(videos!.length);
    emit(VideosLoadedState());
  }
}
