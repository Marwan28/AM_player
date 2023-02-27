import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/screens/songs_screens/song_controls.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    audioPlayer = AudioPlayer();
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
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () async {
                  // audioPlayer.setFilePath(BlocProvider.of<SongsBloc>(context)
                  //     .allSongs![index]
                  //     .filePath!);
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            backgroundColor: Colors.black,
                            content: SongControls(
                              filePath: BlocProvider.of<SongsBloc>(context)
                                  .allSongs![index]
                                  .filePath!,
                            ),
                          ));
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
          // return GridView.builder(
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2,
          //       childAspectRatio: 3 / 2,
          //       crossAxisSpacing: 10,
          //       mainAxisSpacing: 10,
          //     ),
          //     itemCount: BlocProvider.of<SongsBloc>(context)
          //         .songsPathsEntity!
          //         .length,
          //     itemBuilder: (ctx, index) {
          //       return Container(
          //         color: Colors.blue,
          //         child: InkWell(
          //           onTap: () {
          //             Navigator.pushNamed(
          //               ctx,
          //               AppRouter.folderVideos,
          //               arguments: index,
          //               /*BlocProvider.of<VideosBloc>(context)
          //                   .videosPathsEntity![index]*/
          //             );
          //           },
          //           child: Center(
          //             child: Column(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: [
          //                 Text(
          //                   'Folder name: ${BlocProvider.of<SongsBloc>(context).songsPathsEntity![index].name}',
          //                 ),
          //                 Text(
          //                     'number of videos: ${BlocProvider.of<SongsBloc>(context).entities_lenght[BlocProvider.of<SongsBloc>(context).songsPathsEntity![index].id]}'),
          //               ],
          //             ),
          //           ),
          //         ),
          //       );
          //     });
        },
      ),
    );
  }
}
