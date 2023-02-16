import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderVideosScreen extends StatefulWidget {
  FolderVideosScreen({Key? key,}) : super(key: key);
  late int entityIndex;


  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  @override
  Widget build(BuildContext context) {
    widget.entityIndex = ModalRoute.of(context)?.settings.arguments as int;
    return Scaffold(
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context,state) {
          return ListView.builder(
          itemBuilder: (ctx, index) {
            print('---------- listview builder');
            return InkWell(
              onTap: (){
                BlocProvider.of<VideosBloc>(context).currentPlayingVideo = BlocProvider.of<VideosBloc>(context).folders_videos[BlocProvider.of<VideosBloc>(context).videosPathsEntity![widget.entityIndex].id]![index];
                Navigator.pushNamed(
                ctx,
                AppRouter.playVideo,
              );},
              child: Container(
                margin: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Image.memory(BlocProvider.of<VideosBloc>(context)
                          .folders_videos[BlocProvider.of<VideosBloc>(context).videosPathsEntity![widget.entityIndex].id]![index]
                          .image),
                    ),
                    Expanded(
                        child: Text(BlocProvider.of<VideosBloc>(context)
                            .folders_videos![BlocProvider.of<VideosBloc>(context).videosPathsEntity![widget.entityIndex].id]![index]
                            .title))
                  ],
                ),
              ),
            );
          },
          itemCount:
              BlocProvider.of<VideosBloc>(context).entities_lenght[BlocProvider.of<VideosBloc>(context).videosPathsEntity![widget.entityIndex].id] ?? 0,
        );
        },
      ),
    );
  }
}
