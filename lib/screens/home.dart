import 'package:am_player/app_router.dart';
import 'package:am_player/bloc/songs_bloc/songs_bloc.dart';
import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/screens/songs_screens/songs_home_screen.dart';
import 'package:am_player/screens/videos_screens/videos_home_screen.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  int tabIndex = 0;
  final Set<int> loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    context.read<VideosBloc>().add(const LoadVideosEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SongsBloc>().add(
            const LoadSongsEvent(syncIfEmpty: false),
          );
    });
  }

  void _handleBottomNav(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, AppRouter.settings);
      return;
    }
    setState(() {
      tabIndex = index;
      loadedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmSurface(
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: _HomeTab(
                index: tabIndex,
                loadedTabs: loadedTabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AmBottomNav(
        currentIndex: tabIndex,
        onChanged: _handleBottomNav,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12.w,
        12.h,
        12.w,
        10.h,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Image.asset(
                    'assets/images/branding/splash_logo.png',
                    fit: BoxFit.contain,
                    cacheWidth: 128,
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AM Player',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Local library',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const AmIconButton(
                icon: Icons.sunny,
                tooltip: 'Theme',
                onPressed: AppThemeController.toggle,
              ),
              AmIconButton(
                icon: Icons.more_vert_rounded,
                tooltip: 'More',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final int index;
  final Set<int> loadedTabs;

  const _HomeTab({required this.index, required this.loadedTabs});

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: [
        const VideosHomeScreen(),
        loadedTabs.contains(1)
            ? const SongsHomeScreen()
            : const SizedBox.shrink(),
      ],
    );
  }
}
