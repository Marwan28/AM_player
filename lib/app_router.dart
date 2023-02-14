import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/screens/home.dart';
import 'package:am_player/screens/loading.dart';
import 'package:am_player/screens/songs_screens/songs_home_screen.dart';
import 'package:am_player/screens/videos_screens/videos_home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class AppRouter {
  VideosBloc videosBloc = VideosBloc();
  SongsBloc songsBloc = SongsBloc();

  static String videosHome = '/videosHome';
  static String songsHome = '/songsHome';
  static String home = '/home';


  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<VideosBloc>.value(value: videosBloc),
              BlocProvider<SongsBloc>.value(value: songsBloc),
            ],
            child: const Loading(),
          ),
        );
      case '/home':
        return MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<VideosBloc>.value(value: videosBloc),
              BlocProvider<SongsBloc>.value(value: songsBloc),
            ],
            child: const Home(),
          ),
        );
      case '/videosHome':
        return MaterialPageRoute(
          builder: (context) => BlocProvider<VideosBloc>.value(
            value: videosBloc,
            child: VideosHomeScreen(),
          ),
        );
      case '/songsHome':
        return MaterialPageRoute(
          builder: (context) => BlocProvider<SongsBloc>.value(
            value:  songsBloc,
            child: SongsHomeScreen(),
          ),
        );
    }
    return null;
  }
}
