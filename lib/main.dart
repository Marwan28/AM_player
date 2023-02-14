import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/screens/loading.dart';
import 'package:am_player/song_widget.dart';
import 'package:am_player/widget.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

void main() {
  runApp(MyApp(
    appRouter: AppRouter(),
  ));
}

// var audioManagerInstance = AudioManager.instance;
// bool showVol = false;
// PlayMode playMode = audioManagerInstance.playMode;
// bool isPlaying = false;
// double? _slider;

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  const MyApp({super.key, required this.appRouter});
  //
  // Widget bottomPanel() {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 10,
  //         ),
  //         child: songProgress(context),
  //       ),
  //       Container(
  //         padding: const EdgeInsets.symmetric(
  //           vertical: 10,
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             CircleAvatar(
  //               backgroundColor: Colors.cyan.withOpacity(0.3),
  //               child: Center(
  //                 child: IconButton(
  //                   icon: const Icon(
  //                     Icons.skip_previous,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () => audioManagerInstance.previous(),
  //                 ),
  //               ),
  //             ),
  //             CircleAvatar(
  //               radius: 30,
  //               child: Center(
  //                 child: IconButton(
  //                   icon: Icon(
  //                     audioManagerInstance.isPlaying
  //                         ? Icons.pause
  //                         : Icons.play_arrow,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () async {
  //                     audioManagerInstance.playOrPause();
  //                   },
  //                   padding: const EdgeInsets.all(0),
  //                 ),
  //               ),
  //             ),
  //             CircleAvatar(
  //               backgroundColor: Colors.cyan.withOpacity(0.3),
  //               child: Center(
  //                 child: IconButton(
  //                   icon: const Icon(
  //                     Icons.skip_next,
  //                     color: Colors.white,
  //                   ),
  //                   onPressed: () => audioManagerInstance.next(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget songProgress(BuildContext context) {
  //   TextStyle style = const TextStyle(color: Colors.black);
  //   return Row(
  //     children: [
  //       Text(
  //         _formatDuration(audioManagerInstance.position),
  //         style: style,
  //       ),
  //       Expanded(
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 5,
  //           ),
  //           child: SliderTheme(
  //             data: SliderTheme.of(context).copyWith(
  //                 trackHeight: 2,
  //                 thumbColor: Colors.blueAccent,
  //                 overlayColor: Colors.blue,
  //                 thumbShape: const RoundSliderThumbShape(
  //                   disabledThumbRadius: 5,
  //                   enabledThumbRadius: 5,
  //                 ),
  //               overlayShape: const RoundSliderOverlayShape(overlayRadius: 10,),
  //               activeTrackColor: Colors.blueAccent,
  //
  //               inactiveTrackColor: Colors.grey,
  //             ),
  //             child: Slider(
  //               value: _slider??0,
  //               onChanged: (value){
  //                 setState(() {
  //                   _slider = value;
  //                 });
  //               },
  //               onChangeEnd: (value){
  //                 Duration mse = Duration(milliseconds: (audioManagerInstance.duration.inMilliseconds*value).round());
  //                 audioManagerInstance.seekTo(mse);
  //               },
  //             ),
  //           ),
  //         ),
  //       ),
  //       Text(
  //         _formatDuration(audioManagerInstance.duration),
  //         style: style,
  //       ),
  //     ],
  //   );
  // }
  //
  // String _formatDuration(Duration? d){
  //   if(d==null) return '--:--';
  //   int minute = d.inMinutes;
  //   int second = (d.inSeconds>60)? (d.inSeconds%60):d.inSeconds;
  //   String format = '${(minute<10)?'0$minute':'$minute'}:${(second<10)? '0$second':'$second'}';
  //   return format;
  // }
  //

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   setupAudio();
  // }
  // void setupAudio() {
  //   audioManagerInstance.onEvents((events, args) {
  //     switch (events) {
  //       case AudioManagerEvents.start:
  //         _slider = 0;
  //         break;
  //       case AudioManagerEvents.seekComplete:
  //         _slider = audioManagerInstance.position.inMilliseconds /
  //             audioManagerInstance.duration.inMilliseconds;
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.playstatus:
  //         isPlaying = audioManagerInstance.isPlaying;
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.timeupdate:
  //         _slider = audioManagerInstance.position.inMilliseconds /
  //             audioManagerInstance.duration.inMilliseconds;
  //         audioManagerInstance.updateLrc(args["position"].toString());
  //         setState(() {
  //
  //         });
  //         break;
  //       case AudioManagerEvents.ended:
  //         audioManagerInstance.next();
  //         setState(() {
  //
  //         });
  //         break;
  //       default:
  //         break;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: appRouter.generateRoute,
    );
  }
  // Widget scaffold(){
  //   return Scaffold(
  //     drawer: const Drawer(),
  //     appBar: AppBar(
  //       actions: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: InkWell(
  //             onTap: () {
  //               setState(() {
  //                 showVol = !showVol;
  //               });
  //             },
  //             child: const IconText(
  //               textColor: Colors.white,
  //               iconColor: Colors.white,
  //               string: 'volume',
  //               iconSize: 20,
  //               iconData: Icons.volume_down,
  //             ),
  //           ),
  //         ),
  //       ],
  //       elevation: 0,
  //       backgroundColor: Colors.black,
  //       title: showVol
  //           ? Slider(
  //         value: audioManagerInstance.volume,
  //         onChanged: (value) {
  //           setState(() {
  //             audioManagerInstance.setVolume(value, showVolume: true);
  //           });
  //         },
  //       )
  //           : const Text('AM player'),
  //     ),
  //     body: Column(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           child: SingleChildScrollView(
  //             child: SizedBox(
  //               height: 700,
  //               child: FutureBuilder(
  //                 future: OnAudioQuery().querySongs(
  //                   sortType: SongSortType.TITLE,
  //                 ),
  //                 builder: (context, snapshot) {
  //                   List<SongModel>? songInfo = snapshot.data;
  //                   if (snapshot.hasData) return SongWidget(songList: songInfo!);
  //                   return SizedBox(
  //                     height: MediaQuery.of(context).size.height * 0.4,
  //                     child: Center(
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: const [
  //                           CircularProgressIndicator(),
  //                           SizedBox(
  //                             width: 20,
  //                           ),
  //                           Text(
  //                             'Loading...',
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //         bottomPanel(),
  //       ],
  //     ),
  //   );
  // }
}
