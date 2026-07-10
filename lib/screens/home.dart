import 'dart:async';

import 'package:am_player/app_router.dart';
import 'package:am_player/repositories/app_state_repository.dart';
import 'package:am_player/screens/songs_screens/songs_home_screen.dart';
import 'package:am_player/screens/videos_screens/videos_home_screen.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> with WidgetsBindingObserver {
  final AppStateRepository _appStateRepository = AppStateRepository();
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreTabIndex());
  }

  Future<void> _restoreTabIndex() async {
    final savedIndex = await _appStateRepository.loadHomeTabIndex();
    if (!mounted || savedIndex == tabIndex) return;
    setState(() => tabIndex = savedIndex);
  }

  void _handleBottomNav(int index) {
    if (index == 3) {
      Navigator.pushNamed(context, AppRouter.settings);
      return;
    }
    setState(() => tabIndex = index);
    unawaited(_appStateRepository.saveHomeTabIndex(index));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_appStateRepository.saveHomeTabIndex(tabIndex));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_appStateRepository.saveHomeTabIndex(tabIndex));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmSurface(
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(child: _HomeTab(index: tabIndex)),
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
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 21.sp,
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
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onPressed: () {},
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

  const _HomeTab({required this.index});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1:
        return const SongsHomeScreen();
      case 2:
        return const _PhotosPlaceholder();
      default:
        return const VideosHomeScreen();
    }
  }
}

class _PhotosPlaceholder extends StatelessWidget {
  const _PhotosPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        AmSectionHeader(label: 'Photos'),
        _EmptyFeature(
          icon: Icons.image_outlined,
          title: 'Photos are next',
          message: 'The design is ready; media indexing for images comes next.',
        ),
      ],
    );
  }
}

class _EmptyFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyFeature({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surface,
      ),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colors.onSurfaceVariant,
              size: 22.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
