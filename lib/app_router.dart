import 'dart:async';

import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/screens/folder_videos.dart';
import 'package:am_player/screens/home.dart';
import 'package:am_player/screens/privacy_policy_screen.dart';
import 'package:am_player/screens/settings_screen.dart';
import 'package:am_player/screens/songs_screens/songs_home_screen.dart';
import 'package:am_player/screens/videos_screens/play_video.dart';
import 'package:am_player/screens/videos_screens/videos_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  VideosBloc videosBloc = VideosBloc();
  SongsBloc songsBloc = SongsBloc();

  static const String videosHome = '/videosHome';
  static const String songsHome = '/songsHome';
  static const String folderVideos = '/folderVideos';
  static const String playVideo = '/playVideo';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacyPolicy';

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
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
            child: const VideosHomeScreen(),
          ),
        );
      case '/songsHome':
        return MaterialPageRoute(
          builder: (context) => BlocProvider<SongsBloc>.value(
            value: songsBloc,
            child: const SongsHomeScreen(),
          ),
        );
      case '/folderVideos':
        final folder = settings.arguments;
        if (folder is! VideoFolder) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('AM Player')),
              body: const Center(child: Text('Folder is no longer available.')),
            ),
          );
        }
        videosBloc.add(OpenVideoFolderEvent(folder.id));
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider<VideosBloc>.value(
            value: videosBloc,
            child: const FolderVideosScreen(),
          ),
        );
      case '/playVideo':
        final video = settings.arguments is VideoItem
            ? settings.arguments as VideoItem
            : null;
        if (video == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('AM Player')),
              body: const Center(child: Text('Video is no longer available.')),
            ),
          );
        }
        unawaited(songsBloc.playback.pauseForVideo());
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider<VideosBloc>.value(
            value: videosBloc,
            child: PlayVideoScreen(initialVideo: video),
          ),
        );
      case '/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SettingsScreen(),
        );
      case '/privacyPolicy':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const PrivacyPolicyScreen(),
        );
    }
    return null;
  }
}
