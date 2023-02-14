import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:photo_manager/photo_manager.dart';

part 'videos_event.dart';
part 'videos_state.dart';

class VideosBloc extends Bloc<VideosEvent, VideosState> {
  List<AssetPathEntity>? videosPathsEntity;
  List<String>? videosPaths;
  VideosBloc() : super(VideosLoadingState()) {
    on<VideosEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<LoadVideosEvent>((event, emit) {
      loadVideos();
      emit(VideosLoadedState());
    });
  }
  loadVideos() async {
      videosPathsEntity = await PhotoManager.getAssetPathList(type: RequestType.video);
      print('---------- videos ----------');
      print(videosPathsEntity);
      for(int i = 1;i<videosPathsEntity!.length;i++){
        final List<AssetEntity> entities = await videosPathsEntity![i].getAssetListRange(start: 0, end: 80);
        for(AssetEntity f in entities){
          File? s = await f.file;
          videosPaths?.add(s!.path);
          print(' marwan\'s video path: ${s!.path}');
        }
      }


    }



}
