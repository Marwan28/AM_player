import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/screens/home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {

  @override
  void initState() {
    // TODO: implement initState
    BlocProvider.of<VideosBloc>(context).add(LoadVideosEvent());
    BlocProvider.of<SongsBloc>(context).add(LoadSongsEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideosBloc,VideosState>(
      listener: (ctx,state){
        if(BlocProvider.of<VideosBloc>(ctx).state is VideosLoadedState && BlocProvider.of<SongsBloc>(context).state is SongsLoadedState){
          Navigator.pushReplacementNamed(
            context,
            AppRouter.home,
          );
        }
      },
      child: const SpinKitRing(
        color: Colors.red,
        size: 100,
      ),
    );
  }
}
