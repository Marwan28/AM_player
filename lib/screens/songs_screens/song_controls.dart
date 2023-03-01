import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class SongControls extends StatefulWidget {
  const SongControls({Key? key, required this.filePath}) : super(key: key);
  final String filePath;

  @override
  State<SongControls> createState() => _SongControlsState();
}

class _SongControlsState extends State<SongControls> {
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioPlayer.setFilePath(widget.filePath);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            _printDuration(audioPlayer.duration ?? Duration()),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
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
