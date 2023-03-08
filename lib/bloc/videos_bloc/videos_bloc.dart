import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:am_player/models/video.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

part 'videos_event.dart';

part 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  List<AssetPathEntity>? videosPathsEntity;
  List<String>? videosPaths;
  List<Video>? allVideos = [];
  final Map<String, int> entities_lenght = <String, int>{};
  final Map<String, List<Video>> folders_videos = <String, List<Video>>{};
  late Video currentPlayingVideo;

  VideosBloc() : super(VideosLoadingState()) {
    on<VideosEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<LoadVideosEvent>((event, emit) async {
      await loadVideos(emit);
    });
  }

  loadVideos(Emitter emit) async {
    Permission.manageExternalStorage.request();
    Permission.storage.request();
    videosPathsEntity =
        await PhotoManager.getAssetPathList(type: RequestType.video);
    //print('---------- videos ----------');
    videosPathsEntity!.removeAt(0);
    //print(videosPathsEntity);
    for (int i = 0; i < videosPathsEntity!.length; i++) {
      final List<AssetEntity> entity = await videosPathsEntity![i]
          .getAssetListRange(start: 0, end: 999999999);
      entities_lenght[videosPathsEntity![i].id] = entity.length;

      List<Video> currentFolderVideosList = [];

      for (AssetEntity asset in entity) {
        File? file = await asset.file;
        // asset.size;
        videosPaths?.add(file!.path);
        print(asset.relativePath);
        print(file!.path);
        print(file.parent.path);
        // print(asset.title);
        // print(asset.size.aspectRatio);
        // print(asset.relativePath);
        // print('mmmm ' + m!);
        // print('--------file uri: ${file!.uri}');
        // print('--------file path: ${file!.path}');
        // print('query ' + file.uri.path);
        // print(file.uri.scheme);
        // print(file!.path);

        allVideos?.add(Video(
          title: asset.title!
              .replaceAll(asset.title![asset.title!.length - 1], '')
              .replaceAll(asset.title![asset.title!.length - 2], '')
              .replaceAll(asset.title![asset.title!.length - 3], '')
              .replaceAll(asset.title![asset.title!.length - 4], ''),
          path: file!.path,
          duration: asset.duration,
          image: (await asset.thumbnailData)!,
          uri: file!.uri,
          file: file,
          assetEntity: asset,
        ));
        currentFolderVideosList.add(Video(
            title: asset.title!
                .replaceAll(asset.title![asset.title!.length - 1], '')
                .replaceAll(asset.title![asset.title!.length - 2], '')
                .replaceAll(asset.title![asset.title!.length - 3], '')
                .replaceAll(asset.title![asset.title!.length - 4], ''),
            path: file!.path,
            duration: asset.duration,
            image: (await asset.thumbnailData)!,
            uri: file!.uri,
            file: file,
            assetEntity: asset));
        emit(VideosLoadedState());
        //print(' marwan\'file video path: ${file!.path}');
      }
      folders_videos[videosPathsEntity![i].id] = currentFolderVideosList;
      emit(VideosLoadedState());
    }
    //print('878787878787878');
    //print(folders_videos[videosPathsEntity![0].id]);
    //print(allVideos!.length);
    emit(VideosLoadedState());
  }
}
