import 'package:am_player/models/song.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import 'package:photo_manager/photo_manager.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  List<AssetPathEntity>? songsPathsEntity;
  List<String>? songsPaths = [];
  List<Song>? allSongs = [];
  List<AudioSource>? songAudioSourceList = [];
  final Map<String, int> entitiesLength = <String, int>{};
  final Map<String, List<Song>> folderSongs = <String, List<Song>>{};
  late Song currentPlayingVideo;

  SongsBloc() : super(SongsLoadingState()) {
    on<SongsEvent>((event, emit) {});
    on<LoadSongsEvent>((event, emit) async {
      await loadSongs(emit);
    });
  }

  loadSongs(Emitter emit) async {
    songsPaths = [];
    allSongs = [];
    songAudioSourceList = [];
    entitiesLength.clear();
    folderSongs.clear();

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      emit(SongsLoadedState());
      return;
    }

    songsPathsEntity = await PhotoManager.getAssetPathList(
      type: RequestType.audio,
      hasAll: false,
    );

    for (final path in songsPathsEntity ?? <AssetPathEntity>[]) {
      final count = await path.assetCountAsync;
      //print('entity: ${videosPathsEntity![i].name} + total videos ${entity.length}');
      //entities.
      entitiesLength[path.id] = count;

      List<Song> currentFolderSongsList = [];

      const pageSize = 120;
      for (var page = 0; page * pageSize < count; page++) {
        final entity = await path.getAssetListPaged(
          page: page,
          size: pageSize,
        );

        for (AssetEntity asset in entity) {
          final file = await asset.file;
          if (file == null) continue;

          songsPaths?.add(file.path);
          final song = Song(
            title: asset.title ?? file.uri.pathSegments.last,
            filePath: file.path,
            uri: file.uri,
            id: asset.id,
          );
          allSongs?.add(song);
          currentFolderSongsList.add(song);
        }
      }
      folderSongs[path.id] = currentFolderSongsList;
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

    // final audioQuery = OnAudioQuery();
    // final songsQuery = await audioQuery.querySongs();
    // print(songsQuery[0].getMap);
    // File file = File(songsQuery[0].getMap['_data']);
    // print(file.uri);
    // print(file.path);

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
