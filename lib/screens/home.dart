import 'dart:io';

import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/main.dart';
import 'package:am_player/models/song.dart';
import 'package:am_player/screens/songs_screens/songs_home_screen.dart';
import 'package:am_player/screens/videos_screens/videos_home_screen.dart';
import 'package:am_player/song_player.dart';
import 'package:am_player/widgets/song_row.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line_icons/line_icons.dart';
import 'package:line_icons/line_icon.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  List<String>? songsPaths;
  List<String>? videosPaths;

  // void search(String input) {
  //   tempMusics.then((value) {
  //     List<Song> searchedMusics = value
  //         .where((element) =>
  //             element.title.toString().toLowerCase().startsWith(input))
  //         .toList();
  //     songs = Future.value(searchedMusics) as List<Song>;
  //     setState(() {});
  //   });
  // }
  //
  // void refresh() {
  //   setState(() async {
  //     songs = songsBloc.loadSongs() as List<Song>;
  //     tempMusics = songs as Future<List<Song>>;
  //   });
  // }

  // late Future<List<Song>> tempMusics;
  // late List<Song> songs;
  // List favoriteMusics = [];
  // bool sortAZ = false;
  // bool shuffle = false;
  // bool isFocused = false;
  // bool isPlaying = false;
  //Duration duration = Duration.zero;
  // position = Duration.zero;
  TextEditingController searchController = TextEditingController();
  final audioPlayer = AudioPlayer();

  //List<AssetPathEntity>? videosPathsEntity;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<VideosBloc>(context).add(LoadVideosEvent());
    BlocProvider.of<SongsBloc>(context).add(LoadSongsEvent());

    // refresh();
    //
    // // play pause stop
    // audioPlayer.onPlayerStateChanged.listen((state) {
    //   setState(() {
    //     isPlaying = state == PlayerState.playing;
    //   });
    // });
    //
    // audioPlayer.onPlayerComplete.listen((state) {
    //   if (audioPlayer.releaseMode == ReleaseMode.loop) {
    //     songsBloc.play(songsBloc.playing);
    //     return;
    //   }
    //
    //   songsBloc.skipToNext();
    // });
    //
    // audioPlayer.onDurationChanged.listen((newDuration) {
    //   setState(() {
    //     duration = newDuration;
    //   });
    //   // if (playerKey.currentState != null)
    //   //   playerKey.currentState!.setState(() {});
    // });
    //
    // audioPlayer.onPositionChanged.listen((newPosition) {
    //   setState(() {
    //     position = newPosition;
    //   });
    //   // if (playerKey.currentState != null)
    //   //   playerKey.currentState!.setState(() {});
    // });
  }

  // getVideos() async {
  //   videosPathsEntity = await PhotoManager.getAssetPathList(type: RequestType.video);
  //   print('---------- videos ----------');
  //   print(videosPathsEntity);
  //   print(videosPathsEntity![1].name);
  //   for(int i = 1;i<videosPathsEntity!.length;i++){
  //     final List<AssetEntity> entities = await videosPathsEntity![i].getAssetListRange(start: 0, end: 80);
  //     print(' === all entities $entities');
  //     for(AssetEntity f in entities){
  //       File? s = await f.file;
  //       videosPaths?.add(s!.path);
  //       print(' marwan\'s video path: ${s!.path}');
  //
  //     }
  //   }
  //
  //
  // }

  Directory directory = Directory('/storage/emulated/0');
  late List<FileSystemEntity> files;

  void getDirs() {
    files = directory.listSync();
    for (FileSystemEntity file in files) {
      print('------marwan------');
      print(file.path);
      print(file.uri);
    }
  }

  // Future<List<Song>> getMusic() async {
  //   Permission.storage.request();
  //   final audioQuery = OnAudioQuery();
  //   List<Song> songs = [];
  //   print('marwan ------');
  //   await audioQuery.queryAllPath().then((value) {
  //     setState(() {
  //       songsPaths = value;
  //     });
  //
  //     //print(songsPaths);
  //   });
  //   await audioQuery
  //       .querySongs(
  //           sortType: SongSortType.TITLE,
  //           uriType: UriType.EXTERNAL,
  //           ignoreCase: true)
  //       .then(
  //     (value) {
  //       for (SongModel song in value) {
  //         String title = song.title;
  //         String? author = song.artist;
  //         title = title
  //             .replaceAll(RegExp(r'\(.*\)'), '')
  //             .replaceAll(RegExp(r'\[.*\]'), '');
  //         //print('------marwan------');
  //         //print(song.data);
  //         songs.add(
  //           Song(
  //             title: title,
  //             filePath: song.data,
  //             author: author,
  //             rawModel: song,
  //           ),
  //         );
  //       }
  //
  //       songs.sort(
  //         (a, b) =>
  //             b.rawModel!.dateModified!.compareTo(a.rawModel!.dateModified!),
  //       );
  //     },
  //   );
  //   // await audioQuery.queryAlbums().then((value) {
  //   //   print('------query albums');
  //   //   print(value);
  //   // });
  //   // await audioQuery.queryArtists().then((value) {
  //   //   print('------query artists');
  //   //   print(value);
  //   // });
  //   // await audioQuery.queryDeviceInfo().then((value) {
  //   //   print('------query device info');
  //   //   print(value);
  //   // });
  //   // await audioQuery.queryFromFolder(songsPaths![0]).then((value) {
  //   //   print('------query from folder media');
  //   //   print(value);
  //   // });
  //   // await audioQuery.queryGenres().then((value) {
  //   //   print('------query genres');
  //   //   print(value);
  //   // });
  //   // await audioQuery.queryPlaylists().then((value) {
  //   //   print('------query playlists');
  //   //   print(value);
  //   // });
  //   return songs;
  // }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AM player'),
          bottom: const TabBar(
            tabs: [
              Text(
                'VIDEOS',
              ),
              Text(
                'SONGS',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            VideosHomeScreen(),
            SongsHomeScreen(),
          ],
        ),
      ),
    );
    // TODO: implement build
    // return BlocProvider.value(
    //   value: songsBloc,
    //   child: Scaffold(
    //     body: SafeArea(
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    //         child: RefreshIndicator(
    //           onRefresh: () async {
    //             refresh();
    //           },
    //           color: Colors.red,
    //           child: BlocBuilder<SongsBloc, SongsState>(
    //             builder: (context, state) => Column(
    //               children: [
    //                 const SizedBox(
    //                   height: 10,
    //                 ),
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   children: const [
    //                     Text(
    //                       "AM Player",
    //                       style: TextStyle(
    //                           fontSize: 21, fontWeight: FontWeight.bold),
    //                     )
    //                   ],
    //                 ),
    //                 const SizedBox(
    //                   height: 10,
    //                 ),
    //                 TextField(
    //                   controller: searchController,
    //                   autofocus: false,
    //                   onChanged: (output) {
    //                     output = output.toLowerCase();
    //
    //                     search(output);
    //                   },
    //                   decoration: InputDecoration(
    //                     hintText: "search...",
    //                     fillColor:
    //                         Color(int.parse("0xff909090")).withOpacity(.25),
    //                     filled: true,
    //                     enabledBorder: OutlineInputBorder(
    //                       borderSide:
    //                           const BorderSide(color: Colors.transparent),
    //                       borderRadius: BorderRadius.circular(10),
    //                     ),
    //                     focusedBorder: OutlineInputBorder(
    //                       borderSide: const BorderSide(color: Colors.blue),
    //                       borderRadius: BorderRadius.circular(10),
    //                     ),
    //                     prefixIcon: const Icon(
    //                       Icons.search,
    //                       color: Color(0xff9398a4),
    //                     ),
    //                     suffixIcon: searchController.text.isNotEmpty
    //                         ? GestureDetector(
    //                             onTap: () {
    //                               setState(() {
    //                                 searchController.text = "";
    //                                 search("");
    //                               });
    //                             },
    //                             child: const Icon(Icons.close),
    //                           )
    //                         : const Text(""),
    //                     contentPadding: const EdgeInsets.all(10),
    //                     constraints: const BoxConstraints(maxHeight: 45),
    //                   ),
    //                 ),
    //                 const SizedBox(
    //                   height: 10,
    //                 ),
    //                 Padding(
    //                   padding: const EdgeInsets.only(right: 7),
    //                   child: Row(
    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                     children: [
    //                       const Text(
    //                         "MY SONGS",
    //                         style: TextStyle(fontSize: 19),
    //                       ),
    //                       Row(
    //                         mainAxisAlignment: MainAxisAlignment.end,
    //                         children: [
    //                           GestureDetector(
    //                             onTap: () {
    //                               // setState(() {
    //                               //   if (!sortAZ) {
    //                               //     sortAZ = true;
    //                               //     songs.then((value) {
    //                               //       value.sort((a, b) =>
    //                               //           a.title!.compareTo(b.title!));
    //                               //     });
    //                               //   } else {
    //                               //     sortAZ = false;
    //                               //     songs.then((value) {
    //                               //       value.sort((a, b) =>
    //                               //           b.title!.compareTo(a.title!));
    //                               //     });
    //                               //   }
    //                               // });
    //                             },
    //                             child: Icon(
    //                               sortAZ
    //                                   ? LineIcon.sortAlphabeticalDown().icon
    //                                   : LineIcon.sortAlphabeticalUp().icon,
    //                               size: 32,
    //                               color: Colors.red,
    //                             ),
    //                           )
    //                         ],
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 Divider(
    //                   height: 5,
    //                   thickness: 2,
    //                   color: Colors.red,
    //                 ),
    //                 const SizedBox(
    //                   height: 5,
    //                 ),
    //                 ListView.builder(
    //                   itemBuilder: (context, index) => SongRow(
    //                     song: songs[index],
    //                   ),
    //                   itemCount: songs.length,
    //                 ),
    //                 const SizedBox(
    //                   height: 55,
    //                 )
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //     floatingActionButton: GestureDetector(
    //       onTap: () {
    //         Navigator.push(
    //           context,
    //           PageTransition(
    //             type: PageTransitionType.bottomToTop,
    //             child: SongPlayer(
    //               song: songsBloc.playing,
    //             ),
    //             opaque: true,
    //           ),
    //         );
    //       },
    //       child: Container(
    //         height: 65,
    //         width: double.infinity,
    //         decoration: BoxDecoration(
    //           borderRadius: BorderRadius.circular(15),
    //           color: Color(int.parse("0xff1c2835")),
    //         ),
    //         child: songsBloc.playing.title == null
    //             ? const Center(
    //                 child: Text(
    //                 'Nothing is playing...',
    //                 style: TextStyle(fontSize: 25),
    //               ))
    //             : Padding(
    //                 padding: const EdgeInsets.symmetric(horizontal: 20),
    //                 child: Column(
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   children: [
    //                     Row(
    //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                       children: [
    //                         Flexible(
    //                           child: Column(
    //                             mainAxisAlignment: MainAxisAlignment.center,
    //                             crossAxisAlignment: CrossAxisAlignment.start,
    //                             children: [
    //                               Text(
    //                                 songsBloc.playing.title ?? "",
    //                                 style: const TextStyle(
    //                                     fontWeight: FontWeight.bold,
    //                                     fontSize: 20,
    //                                     overflow: TextOverflow.ellipsis),
    //                                 maxLines: 1,
    //                               ),
    //                               Text(
    //                                 songsBloc.playing.author ?? "",
    //                                 style: const TextStyle(fontSize: 18),
    //                               ),
    //                             ],
    //                           ),
    //                         ),
    //                         CircleAvatar(
    //                             radius: 25,
    //                             child: IconButton(
    //                               icon: isPlaying
    //                                   ? const AnimatedSwitcher(
    //                                       duration: Duration(milliseconds: 450),
    //                                       child: Icon(
    //                                         Icons.pause_rounded,
    //                                         color: Colors.green,
    //                                       ))
    //                                   : const AnimatedSwitcher(
    //                                       duration: Duration(milliseconds: 450),
    //                                       child:
    //                                           Icon(Icons.play_arrow_rounded)),
    //                               onPressed: () async {
    //                                 if (isPlaying) {
    //                                   await audioPlayer.pause();
    //                                 } else {
    //                                   await audioPlayer.resume();
    //                                 }
    //                                 setState(() {});
    //                               },
    //                               iconSize: 30,
    //                             )),
    //                       ],
    //                     ),
    //                     const SizedBox(height: 4),
    //                     ClipRRect(
    //                       borderRadius: BorderRadius.circular(30),
    //                       child: SizedBox(
    //                         height: 2,
    //                         child: TweenAnimationBuilder<double>(
    //                           duration: const Duration(milliseconds: 350),
    //                           curve: Curves.easeOut,
    //                           tween: Tween<double>(
    //                             begin: 0,
    //                             end:
    //                                 ((position.inSeconds / duration.inSeconds) *
    //                                         100) /
    //                                     100,
    //                           ),
    //                           builder: (ctx, value, child) =>
    //                               LinearProgressIndicator(
    //                             value: value,
    //                             minHeight: 2,
    //                             color: Colors.red,
    //                           ),
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //       ),
    //     ),
    //     floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    //   ),
    // );
  }
// return Scaffold(
// appBar: AppBar(
// title: const Text('AM player'),
// ),
// body: Container(
// child: songsPaths == null
// ? const Center(
// child: CircularProgressIndicator(),
// )
//     : GridView.builder(
// gridDelegate:
// const SliverGridDelegateWithFixedCrossAxisCount(
// crossAxisCount: 2,
// childAspectRatio: 3 / 2,
// crossAxisSpacing: 10,
// mainAxisSpacing: 10,
// ),
// itemCount: songsPaths?.length ?? 0,
// itemBuilder: (ctx, index) {
// print(songsPaths![index]);
// return Container(
// alignment: Alignment.center,
// decoration: BoxDecoration(
// color: Colors.amber,
// borderRadius: BorderRadius.circular(15)),
// child: Text(
// songsPaths![index].split('/').last,
// style: const TextStyle(color: Colors.red),
// ),
// );
// }),
// ),
// );
}
