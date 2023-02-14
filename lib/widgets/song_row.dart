// import 'package:am_player/bloc/songs_bloc.dart';
// import 'package:am_player/main.dart';
// import 'package:am_player/song.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// class SongRow extends StatelessWidget {
//   final Song song;
//
//   SongRow({
//     Key? key,
//     required this.song,
//   }) : super(key: key);
//
//   bool isPlaying = false;
//   final songsBloc = MyApp.songsBloc;
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: songsBloc,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: GestureDetector(
//           onTap: () {
//             // Navigator.push(context, PageTransition(
//             //   type: PageTransitionType.bottomToTop,
//             //   child: MusicPlayer(music: music,),
//             //   opaque: true,
//             // ));
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             height: 75,
//             decoration: BoxDecoration(
//                 color: songsBloc.isPlaying(song)
//                     ? Colors.green
//                     : Colors.red.withOpacity(.1),
//                 borderRadius: BorderRadius.circular(18)),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Padding(
//                       padding: const EdgeInsets.only(left: 8),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Flexible(
//                               child: Text(
//                             song.title??'NO TITLE',
//                             style: const TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                                 overflow: TextOverflow.ellipsis),
//                             maxLines: 1,
//                           )),
//                           Text(
//                             song.author??'NO AUTHOR',
//                             style: TextStyle(
//                                 fontSize: 16,
//                                 color: Color(int.parse("0xfffcfcff")).withOpacity(.65)),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   CircleAvatar(
//                       radius: 25,
//                       child: IconButton(
//                         icon: songsBloc.isPlaying(song)
//                             ? const AnimatedSwitcher(
//                                 duration: Duration(milliseconds: 450),
//                                 child: Icon(
//                                   Icons.stop_rounded,
//                                   color: Colors.green,
//                                 ))
//                             : const AnimatedSwitcher(
//                                 duration: Duration(milliseconds: 450),
//                                 child: Icon(Icons.play_arrow_rounded)),
//                         onPressed: (){
//                           if(songsBloc.playing.filePath!=song.filePath){
//                             songsBloc.play(song);
//                           }
//                           if(songsBloc.playing.filePath==song.filePath){
//                             songsBloc.stop(song);
//                           }
//                         },
//                         iconSize: 30,
//                       )),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
