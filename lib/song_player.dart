import 'dart:typed_data';

import 'package:am_player/main.dart';
import 'package:am_player/song.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:line_icons/line_icon.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:on_audio_room/details/extensions/entity_checker_extension.dart';
import 'package:on_audio_room/on_audio_room.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';



class SongPlayer extends StatefulWidget {
  final Song song;
  final songsBloc = MyApp.songsBloc;
   SongPlayer({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<SongPlayer> createState() => SongPlayerState();
}

class SongPlayerState extends State<SongPlayer> {
  List musics = [];

  late Song playing;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    playing = widget.song;

    if(widget.songsBloc.playing.title != playing.title) widget.songsBloc.duration = playing.rawModel!.duration as Duration;

    widget.songsBloc.musics.then((value) {
      musics = value;
      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                      child: IconButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Color(int.parse("0xfffcfcff")),)
                      ),
                    ),
                    const Text("SONG", style: TextStyle(
                      fontSize: 21,
                    ),),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                      child: IconButton(
                          onPressed: () async {
                            // Navigator.push(context, PageTransition(
                            //   type: PageTransitionType.rightToLeftWithFade,
                            //   child: MusicProperties(music: playing,),
                            //   opaque: true,
                            // ));
                          },
                          icon: Icon(Icons.more_horiz_outlined, color: Color(int.parse("0xfffcfcff")),)
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50,),

                // Text(Strings.formatTime(position)),
                const SizedBox(height: 5,),
                CircleAvatar(
                  radius: 167,
                  backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.7),
                  child: CircleAvatar(
                    radius: 165,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.music_note, size: 190, color: Color(int.parse("0xfffcfcff")),),
                  ),
                ),

                const SizedBox(height: 25,),

                Text(widget.songsBloc.playing.title!, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                const SizedBox(height: 7,),
                Text(widget.songsBloc.playing.author!, style: TextStyle(fontSize: 20, color: Color(int.parse("0xfffcfcff")).withOpacity(.65)),),

                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  tween: Tween<double>(
                    begin: 10,
                    end: widget.songsBloc.position.inSeconds.toDouble(),
                  ),
                  builder: (ctx, value, _) => Slider(
                    activeColor: Colors.red,
                    min: 0,
                    max: widget.songsBloc.duration.inSeconds.toDouble(),
                    value: value,
                    onChanged: (value) async {
                      final pos = Duration(seconds: value.toInt());
                      await widget.songsBloc.audioPlayer.seek(pos);
                     widget.songsBloc.position = pos;
                      setState(() {});
                      // await audioPlayer.resume();
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${widget.songsBloc.position.inMinutes.toString().padLeft(2, '0')}:${(widget.songsBloc.position.inSeconds % 60).toString().padLeft(2, '0')}"),
                      Text("${widget.songsBloc.duration.inMinutes.toString().padLeft(2, '0')}:${(widget.songsBloc.duration.inSeconds % 60).toString().padLeft(2, '0')}"),
                    ],
                  ),
                ),

                const SizedBox(height: 10,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                      child: IconButton(
                          onPressed: () async {
                            setState(() {
                              if(widget.songsBloc.audioPlayer.releaseMode != ReleaseMode.loop) {
                                widget.songsBloc.audioPlayer.setReleaseMode(ReleaseMode.loop);
                              } else {
                                widget.songsBloc.audioPlayer.setReleaseMode(ReleaseMode.release);
                              }
                            });
                          },
                          icon: widget.songsBloc.audioPlayer.releaseMode == ReleaseMode.loop
                              ? const Icon(Icons.repeat_one, color: Colors.green,)
                              : Icon(Icons.repeat, color: Color(int.parse("0xfffcfcff")))
                      ),
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                      child: IconButton(
                          onPressed: () async {

                          },
                          icon: Icon(LineIcon.heart().icon, color: Colors.red,)
                      ),
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                      child: IconButton(
                          onPressed: () {
                           widget.songsBloc.shuffle = !widget.songsBloc.shuffle;
                            setState(() {});
                            //homeKey.currentState!.setState(() {});
                          },
                          icon: Icon(LineIcon.random().icon, color: widget.songsBloc.shuffle ? Colors.green : Color(int.parse("0xfffcfcff")),)
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if(musics.indexOf(playing)-1 != -1)
                      CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                          child: IconButton(
                            icon: Icon(Icons.keyboard_double_arrow_left_sharp, color: Color(int.parse("0xfffcfcff")),),
                            onPressed: () async {
                              widget.songsBloc.skipToLast();
                            },
                            iconSize: 50,
                          )
                      ),
                    if(musics.indexOf(playing)-1 == -1)
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.transparent,
                      ),

                    CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green,
                        child: IconButton(
                          color: Color(int.parse("0xfffcfcff")),
                          icon: widget.songsBloc.isPlaying(playing)
                              ? const Icon(Icons.pause)
                              : const Icon(Icons.play_arrow_rounded),
                          iconSize: 50,
                          onPressed: () async {
                            if (widget.songsBloc.isPlaying(playing)) {
                              await widget.songsBloc.audioPlayer.pause();
                            } else {
                              await widget.songsBloc.audioPlayer.resume();
                            }
                            setState(() {});
                          },
                        )
                    ),

                    if(musics.indexOf(playing)+1 != musics.length)
                      CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(int.parse("0xfffcfcff")).withOpacity(.2),
                          child: IconButton(
                            icon: Icon(Icons.keyboard_double_arrow_right_sharp, color: Color(int.parse("0xfffcfcff")),),
                            onPressed: () async{
                              widget.songsBloc.skipToNext();
                            },
                            iconSize: 50,
                          )
                      ),
                    if(musics.indexOf(playing)+1 == musics.length)
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.transparent,
                      ),
                  ],
                )


              ],
            ),
          ),
        ),
      ),
    );
  }
}