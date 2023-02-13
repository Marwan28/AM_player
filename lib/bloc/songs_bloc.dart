import 'dart:async';
import 'dart:math';

import 'package:am_player/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

part 'songs_event.dart';
part 'songs_state.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  SongsBloc() : super(SongsInitial()) {
    on<SongsEvent>((event, emit) {
      // TODO: implement event handler
      emit(SongsLoadingState());
    });
  }



  late Future<List<Song>> musics;
  bool shuffle = false;
  Song playing = Song(
    title: null,
    author: null,
    filePath: null,
    rawModel: null,
  );
  final audioPlayer = AudioPlayer();
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Future<List<Song>> getMusic() async {
    Permission.storage.request();
    final audioQuery = OnAudioQuery();

    List<Song> songs = [];

    audioQuery
        .querySongs(
        sortType: SongSortType.TITLE,
        uriType: UriType.EXTERNAL,
        ignoreCase: true)
        .then(
          (value) {
        for (SongModel song in value) {
          String title = song.title;
          String? author = song.artist;
          title = title
              .replaceAll(RegExp(r'\(.*\)'), '')
              .replaceAll(RegExp(r'\[.*\]'), '');

          songs.add(
            Song(
              title: title,
              filePath: song.data,
              author: author,
              rawModel: song,
            ),
          );
        }

        songs.sort(
              (a, b) =>
              b.rawModel!.dateModified!.compareTo(a.rawModel!.dateModified!),
        );
      },
    );
    return songs;
  }
  Future play(Song song) async {
    playing = song;
    audioPlayer.stop();
    audioPlayer.play(DeviceFileSource(song.filePath!));
    audioPlayer.resume();
  }
  Future stop(Song song) async {
    audioPlayer.stop();
    playing =  Song(
      title: null,
      author: null,
      filePath: null,
      rawModel: null,
    );
    position = Duration.zero;
    duration = Duration.zero;
  }
  bool isPlaying(Song song) {
    return song.title == playing.title;
  }

  Future skipToNext() async {
    musics.then((value) {
      Song next = value[value.indexOf(playing)+1];
      if(shuffle) {
        next = value.elementAt(Random().nextInt(value.length));
      }
      play(next);
      playing = next;
       audioPlayer.resume();
    });
  }

  Future skipToLast() async {
    musics.then((value) {
      Song last = value[value.indexOf(playing)-1];
      play(last);
     playing = last;
      audioPlayer.resume();
    });
  }

}
