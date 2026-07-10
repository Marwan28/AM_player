import 'package:am_player/app_router.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 48 * 1024 * 1024;
  MediaKit.ensureInitialized();
  await Future.wait([
    AppThemeController.initialize(),
    JustAudioBackground.init(
      androidNotificationChannelId: 'com.marwan.amplayer.audio.playback',
      androidNotificationChannelName: 'AM Player playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  ]);

  runApp(MyApp(appRouter: AppRouter()));
}

class MyApp extends StatefulWidget {
  final AppRouter appRouter;

  const MyApp({super.key, required this.appRouter});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const Size _portraitDesignSize = Size(390, 844);
  static const Size _landscapeDesignSize = Size(844, 390);

  Size _designSize = _portraitDesignSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncDesignSize();
  }

  @override
  void didChangeMetrics() {
    _syncDesignSize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: _designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      rebuildFactor: _shouldRebuildScreenUtil,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeController.mode,
          builder: (context, themeMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'AM Player',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              onGenerateRoute: widget.appRouter.generateRoute,
            );
          },
        );
      },
    );
  }

  void _syncDesignSize() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;

    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    if (_isPipWindow(logicalSize)) return;

    final nextDesignSize = logicalSize.width > logicalSize.height
        ? _landscapeDesignSize
        : _portraitDesignSize;
    if (nextDesignSize == _designSize) return;

    if (mounted) {
      setState(() => _designSize = nextDesignSize);
    } else {
      _designSize = nextDesignSize;
    }
  }

  bool _shouldRebuildScreenUtil(MediaQueryData oldData, MediaQueryData data) {
    if (_isPipWindow(data.size)) return false;
    return oldData.size != data.size ||
        oldData.orientation != data.orientation ||
        oldData.devicePixelRatio != data.devicePixelRatio;
  }

  bool _isPipWindow(Size size) {
    return size.shortestSide < 300 || size.longestSide < 500;
  }
}
