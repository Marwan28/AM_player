import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/screens/songs_screens/song_controls.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class SongsHomeScreen extends StatefulWidget {
  const SongsHomeScreen({Key? key}) : super(key: key);

  @override
  State<SongsHomeScreen> createState() => _SongsHomeScreenState();
}

class _SongsHomeScreenState extends State<SongsHomeScreen> {
  late AudioPlayer audioPlayer;
  String currentPlayingFilePath = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayer.setLoopMode(LoopMode.one);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          print('---------- bloc builder');
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 50),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  // audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                  //     .allSongs![index]
                  //     .filePath!);

                  if(currentPlayingFilePath == BlocProvider.of<SongsBloc>(context)
                      .allSongs![index]
                      .filePath!){
                    if(audioPlayer.playing){
                      audioPlayer.pause();
                    }else{
                      audioPlayer.play();
                    }

                    setState(() {

                    });
                  }else {
                    audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                      .allSongs![index]
                      .filePath!);
                    currentPlayingFilePath = BlocProvider.of<SongsBloc>(context)
                        .allSongs![index]
                        .filePath!;
                  setState(() {

                  });
                  audioPlayer.play();
                  setState(() {

                  });}

                  // if (audioPlayer.playing) {
                  //   await audioPlayer.pause();
                  // } else {
                  //   await audioPlayer.play();
                  // }
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
      floatingActionButton: Container(
        color: Colors.black,
        height: 50,
        padding: EdgeInsets.only(right: 15),
        child: Row(
          children: [
            Container(
              child: (!audioPlayer.playing)
                  ? IconButton(
                      onPressed: () {
                        audioPlayer.play();
                        setState(() {});
                      },
                      iconSize: 30,
                      color: Colors.white,
                      icon: Icon(Icons.play_arrow_rounded),
                    )
                  : IconButton(
                      onPressed: () {
                        audioPlayer.pause();
                        setState(() {});
                      },
                      iconSize: 30,
                      color: Colors.white,
                      icon: Icon(Icons.pause_rounded),
                    ),
            ),
            SizedBox(
              width: 5,
            ),
            StreamBuilder(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  var pos = snapshot.data;
                  return Text(
                    _printDuration(pos!),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  );
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
                  _printDuration(duration??Duration()),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                );
              }
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
}
