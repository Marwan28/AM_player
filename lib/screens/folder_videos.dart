import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderVideosScreen extends StatefulWidget {
  FolderVideosScreen({
    Key? key,
  }) : super(key: key);
  late int entityIndex;

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  @override
  Widget build(BuildContext context) {
    print(MediaQuery.of(context).size.height);
    print(MediaQuery.of(context).size.width);
    print(MediaQuery.of(context).size);
    widget.entityIndex = ModalRoute.of(context)?.settings.arguments as int;
    return Scaffold(
      backgroundColor: Colors.cyan,
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          if (BlocProvider.of<VideosBloc>(context).entities_lenght[
                      BlocProvider.of<VideosBloc>(context)
                          .videosPathsEntity![widget.entityIndex]
                          .id] ==
                  null ||
              BlocProvider.of<VideosBloc>(context).entities_lenght[
                      BlocProvider.of<VideosBloc>(context)
                          .videosPathsEntity![widget.entityIndex]
                          .id] ==
                  0) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
              itemBuilder: (ctx, index) {
                print('---------- listview builder');
                return Container(
                  margin: const EdgeInsetsDirectional.only(
                      bottom: 5, start: 5, end: 5, top: 5),
                  //margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 0.0, style: BorderStyle.none),
                  ),

                  child: InkWell(
                    onTap: () {
                      BlocProvider.of<VideosBloc>(context).currentPlayingVideo =
                          BlocProvider.of<VideosBloc>(context).folders_videos[
                              BlocProvider.of<VideosBloc>(context)
                                  .videosPathsEntity![widget.entityIndex]
                                  .id]![index];
                      Navigator.pushNamed(
                        ctx,
                        AppRouter.playVideo,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(10),
                      child: Row(
                        textBaseline: TextBaseline.alphabetic,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (BlocProvider.of<VideosBloc>(context)
                                  .folders_videos[BlocProvider.of<VideosBloc>(
                                          context)
                                      .videosPathsEntity![widget.entityIndex]
                                      .id]?[index]
                                  .image ==
                              null)
                            Container(
                              width: MediaQuery.of(context).size.width * 0.300,
                              height:
                                  MediaQuery.of(context).size.height * 0.100,
                              child: Image.asset('assets/images/image2.png'),
                            ),
                          if (BlocProvider.of<VideosBloc>(context)
                                  .folders_videos[BlocProvider.of<VideosBloc>(
                                          context)
                                      .videosPathsEntity![widget.entityIndex]
                                      .id]?[index]
                                  .image !=
                              null)
                            Stack(
                              fit: StackFit.loose,
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(),
                                  width:
                                      MediaQuery.of(context).size.width * 0.300,
                                  height: MediaQuery.of(context).size.height *
                                      0.100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    //clipBehavior: Clip.hardEdge,
                                    child: Image.memory(
                                      BlocProvider.of<VideosBloc>(context)
                                          .folders_videos[
                                              BlocProvider.of<VideosBloc>(
                                                      context)
                                                  .videosPathsEntity![
                                                      widget.entityIndex]
                                                  .id]![index]
                                          .image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 10,
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          width: 0.0, style: BorderStyle.none),
                                    ),
                                    child: Text(
                                      _printDuration(
                                          BlocProvider.of<VideosBloc>(context)
                                              .folders_videos[
                                                  BlocProvider.of<VideosBloc>(
                                                          context)
                                                      .videosPathsEntity![
                                                          widget.entityIndex]
                                                      .id]![index]
                                              .assetEntity
                                              .videoDuration),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Expanded(
                              child: Container(
                            margin: const EdgeInsetsDirectional.only(start: 10),
                            child: Text(
                              BlocProvider.of<VideosBloc>(context)
                                      .folders_videos![
                                          BlocProvider.of<VideosBloc>(context)
                                              .videosPathsEntity![
                                                  widget.entityIndex]
                                              .id]?[index]
                                      .title ??
                                  '',
                              style: const TextStyle(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
              itemCount: BlocProvider.of<VideosBloc>(context).entities_lenght[
                      BlocProvider.of<VideosBloc>(context)
                          .videosPathsEntity![widget.entityIndex]
                          .id] ??
                  0,
            );
          }
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
