import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class SongsHomeScreen extends StatefulWidget {
  const SongsHomeScreen({Key? key}) : super(key: key);

  @override
  State<SongsHomeScreen> createState() => _SongsHomeScreenState();
}

class _SongsHomeScreenState extends State<SongsHomeScreen> with AutomaticKeepAliveClientMixin<SongsHomeScreen>{
  late AudioPlayer audioPlayer;
  int currentIndex = 0;
  String currentPath = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayer.setLoopMode(LoopMode.all);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          return ListView.builder(
            //padding: EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  // audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                  //     .allSongs![index]
                  //     .filePath!);
                  if (currentPath ==
                      BlocProvider.of<SongsBloc>(context)
                          .allSongs![index]
                          .filePath!) {
                    if (audioPlayer.playing) {
                      audioPlayer.pause();
                      setState(() {});
                      setState(() {});
                    } else {
                      audioPlayer.play();
                      setState(() {});
                    }
                  } else {
                    audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                        .allSongs![index]
                        .filePath!);
                    currentIndex = index;
                    currentPath = BlocProvider.of<SongsBloc>(context)
                        .allSongs![index]
                        .filePath!;
                    audioPlayer.setAudioSource(
                        ConcatenatingAudioSource(
                            children:
                            BlocProvider.of<SongsBloc>(context)
                                .songAudioSourceList!),
                        initialIndex: currentIndex);
                    audioPlayer.play();
                    setState(() {});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  color: Colors.red,
                  child: Column(
                    children: [
                      Text(
                        BlocProvider.of<SongsBloc>(context)
                            .allSongs![index]
                            .title!,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: BlocProvider.of<SongsBloc>(context).allSongs!.length,
          );
        },
      ),

      // bottomNavigationBar: SongControls(
      //   filePath: BlocProvider.of<SongsBloc>(context)
      //       .allSongs![0]
      //       .filePath!,
      // ),
      bottomNavigationBar: Container(
        color: Colors.black,
        height: 100,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(right: 15, left: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      var pos = snapshot.data;
                      if(snapshot.hasData){
                        return Text(
                          _printDuration(pos!),
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        );
                      }else{
                        return Text(
                          '00:00',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        );
                      }

                    }),
                Expanded(
                  child: StreamBuilder(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      var position = snapshot.data;
                      return Slider(
                        activeColor: Colors.red,
                        min: 0,
                        max: audioPlayer.duration?.inSeconds.toDouble() ?? 0.0,
                        value: position?.inSeconds.toDouble() ?? 0,
                        onChanged: (value) async {
                          final pos = Duration(seconds: value.toInt());
                          await audioPlayer.seek(pos);
                          position = pos;
                          // setState(() {});
                          // await audioPlayer.resume();
                        },
                      );
                    },
                  ),
                ),
                StreamBuilder(
                    stream: audioPlayer.durationStream,
                    builder: (context, snapshot) {
                      var duration = snapshot.data;
                      return Text(
                        _printDuration(duration ?? const Duration()),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      );
                    }),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    if (audioPlayer.hasPrevious) {
                      audioPlayer.seekToPrevious();
                      audioPlayer.play();
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 30,
                  color: Colors.white,
                ),
                Container(
                  child: (!audioPlayer.playing)
                      ? IconButton(
                          onPressed: () {
                            if (currentPath == '') {
                              audioPlayer.setFilePath(
                                  BlocProvider.of<SongsBloc>(context)
                                      .allSongs![currentIndex]
                                      .filePath!);
                              currentPath = BlocProvider.of<SongsBloc>(context)
                                  .allSongs![currentIndex]
                                  .filePath!;
                              audioPlayer.setAudioSource(
                                  ConcatenatingAudioSource(
                                      children:
                                          BlocProvider.of<SongsBloc>(context)
                                              .songAudioSourceList!),
                                  initialIndex: currentIndex);
                            }

                            audioPlayer.play();
                            setState(() {});
                          },
                          iconSize: 30,
                          color: Colors.white,
                          icon: const Icon(Icons.play_arrow_rounded),
                        )
                      : IconButton(
                          onPressed: () {
                            audioPlayer.pause();
                            setState(() {});
                          },
                          iconSize: 30,
                          color: Colors.white,
                          icon: const Icon(Icons.pause_rounded),
                        ),
                ),
                IconButton(
                  onPressed: () {
                    if (audioPlayer.hasNext) {
                      audioPlayer.seekToNext();
                      audioPlayer.play();
                      setState(() {});
                    }
                    // currentIndex = currentIndex + 1;
                    // currentPlayingFilePath = BlocProvider.of<SongsBloc>(context)
                    //     .allSongs![currentIndex]
                    //     .filePath!;
                    // audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                    //     .allSongs![currentIndex]
                    //     .filePath!);
                    // audioPlayer.setAudioSource(AudioSource.uri(
                    //   BlocProvider.of<SongsBloc>(context)
                    //       .allSongs![currentIndex]
                    //       .uri!,
                    //   tag: MediaItem(id: '1', title: 'Song Name'),
                    // ));
                    // audioPlayer.play();
                    setState(() {});
                  },
                  icon: const Icon(Icons.skip_next),
                  iconSize: 30,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
      //floatingActionButton: Text('marwan',style: TextStyle(fontSize: 30,color: Colors.black),),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (twoDigits(duration.inHours) == '0' ||
        twoDigits(duration.inHours) == '00') {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  bool get wantKeepAlive => true;
}
