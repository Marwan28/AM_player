import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.only(right: 15),
      child: StreamBuilder<Duration>(
        stream: audioPlayer.positionStream,
        initialData: Duration.zero,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = audioPlayer.duration ?? Duration.zero;
          final max = duration.inMilliseconds <= 0
              ? 1.0
              : duration.inMilliseconds.toDouble();
          final value = position.inMilliseconds.clamp(0, max).toDouble();

          return Row(
            children: [
              IconButton(
                onPressed: () {
                  audioPlayer.playing
                      ? audioPlayer.pause()
                      : audioPlayer.play();
                  setState(() {});
                },
                iconSize: 30,
                color: Colors.white,
                icon: Icon(
                  audioPlayer.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 50,
                child: Text(
                  _printDuration(position),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  activeColor: Colors.red,
                  min: 0,
                  max: max,
                  value: value,
                  onChanged: (value) async {
                    await audioPlayer.seek(
                      Duration(milliseconds: value.round()),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _printDuration(duration),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
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
