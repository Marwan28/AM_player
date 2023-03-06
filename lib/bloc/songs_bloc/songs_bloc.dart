import 'dart:io';
import 'package:am_player/models/song.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  List<AssetPathEntity>? songsPathsEntity;
  List<String>? songsPaths;
  List<Song>? allSongs = [];
  List<AudioSource>? songAudioSourceList = [];
  final Map<String, int> entities_lenght = <String, int>{};
  final Map<String, List<Song>> folders_songs = <String, List<Song>>{};
  late Song currentPlayingVideo;

  SongsBloc() : super(SongsLoadingState()) {
    on<SongsEvent>((event, emit) {});
    on<LoadSongsEvent>((event, emit) async {
      await loadSongs(emit);
    });
  }

  loadSongs(Emitter emit) async {
    Permission.storage.request();
    songsPathsEntity =
        await PhotoManager.getAssetPathList(type: RequestType.audio);
    print('---------- songs ----------');
    songsPathsEntity!.removeAt(0);
    for (int i = 0; i < songsPathsEntity!.length; i++) {
      final List<AssetEntity> entity =
          await songsPathsEntity![i].getAssetListRange(start: 0, end: 999999999);
      //print('entity: ${videosPathsEntity![i].name} + total videos ${entity.length}');
      //entities.
      entities_lenght[songsPathsEntity![i].id] = entity.length;
      print('-----------------------');
      print(entities_lenght);

      List<Song> currentFolderSongsList = [];


      for (AssetEntity asset in entity) {
        File? file = await asset.file;
        songsPaths?.add(file!.path);
        // print(asset.title);
        // print(asset.id);
        // print(asset.relativePath);
        // print('--------file uri: ${file!.uri}');
        // print('--------file path: ${file!.path}');
        // print(file!.path);

        allSongs?.add(Song(
          title: asset.title!,
          filePath: file!.path,
          uri: file.uri,
          id: asset.id,
        ));
        currentFolderSongsList.add(Song(
          title: asset.title!,
          filePath: file!.path,
          uri: file.uri,
          id: asset.id,
        ));
        //print(' marwan\'file video path: ${file!.path}');
        emit(SongsLoadedState());
      }
      folders_songs[songsPathsEntity![i].id] = currentFolderSongsList;
      emit(SongsLoadedState());
    }
    for (var song in allSongs!) {
      songAudioSourceList!.add(AudioSource.uri(
        song.uri!,
        tag: MediaItem(
          id: song.id!,
          title: song.title!,
        ),
      ));
      emit(SongsLoadedState());
    }
    print('565656565656');


    print(allSongs!.length);







    // final audioQuery = OnAudioQuery();
    // final songsQuery = await audioQuery.querySongs();
    // print(songsQuery[0].getMap);
    // File file = File(songsQuery[0].getMap['_data']);
    // print(file.uri);
    // print(file.path);


    print('----------');



    // List<Song> songs = [];
    // print('marwan ------');
    // await audioQuery.queryAllPath().then((value) {
    //     songsPaths = value;
    //
    //   print(songsPaths);
    // });
    // await audioQuery
    //     .querySongs(
    //     sortType: SongSortType.TITLE,
    //     uriType: UriType.EXTERNAL,
    //     ignoreCase: true)
    //     .then(
    //       (value) {
    //     for (SongModel song in value) {
    //       String title = song.title;
    //       String? author = song.artist;
    //       title = title
    //           .replaceAll(RegExp(r'\(.*\)'), '')
    //           .replaceAll(RegExp(r'\[.*\]'), '');
    //       //print('------marwan------');
    //       //print(song.data);
    //       songs.add(
    //         Song(
    //           title: title,
    //           filePath: song.data,
    //           author: author,
    //           rawModel: song,
    //         ),
    //       );
    //     }
    //
    //     songs.sort(
    //           (a, b) =>
    //           b.rawModel!.dateModified!.compareTo(a.rawModel!.dateModified!),
    //     );
    //   },
    // );
    // print('songs list length: ${songs.length}');
    emit(SongsLoadedState());
  }

//
// late Future<List<Song>> musics;
// bool shuffle = false;
// Song playing = Song(
//   title: null,
//   author: null,
//   filePath: null,
//   rawModel: null,
// );
// final audioPlayer = AudioPlayer();
// Duration duration = Duration.zero;
// Duration position = Duration.zero;
//
// Future play(Song song) async {
//   playing = song;
//   audioPlayer.stop();
//   audioPlayer.play(DeviceFileSource(song.filePath!));
//   audioPlayer.resume();
// }
// Future stop(Song song) async {
//   audioPlayer.stop();
//   playing =  Song(
//     title: null,
//     author: null,
//     filePath: null,
//     rawModel: null,
//   );
//   position = Duration.zero;
//   duration = Duration.zero;
// }
// bool isPlaying(Song song) {
//   return song.title == playing.title;
// }
//
// Future skipToNext() async {
//   musics.then((value) {
//     Song next = value[value.indexOf(playing)+1];
//     if(shuffle) {
//       next = value.elementAt(Random().nextInt(value.length));
//     }
//     play(next);
//     playing = next;
//      audioPlayer.resume();
//   });
// }
//
// Future skipToLast() async {
//   musics.then((value) {
//     Song last = value[value.indexOf(playing)-1];
//     play(last);
//    playing = last;
//     audioPlayer.resume();
//   });
// }

}
