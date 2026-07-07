import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    BlocProvider.of<VideosBloc>(context).add(const LoadVideosEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideosBloc, VideosState>(
      listener: (ctx, state) {
        if (!state.isLoading) {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.home,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SpinKitRing(
                color: Color(0xFFE53935),
                size: 92,
              ),
              SizedBox(height: 24),
              Text(
                'AM Player',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
