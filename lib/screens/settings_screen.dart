import 'package:am_player/app_router.dart';
import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmSurface(
        child: Column(
          children: [
            AmTopBar(
              title: 'Settings',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 18.h),
                children: [
                  const _SettingsGroup(
                    title: 'Appearance',
                    children: [_ThemeRow()],
                  ),
                  _SettingsGroup(
                    title: 'Media access',
                    children: [
                      _NavRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'App permissions',
                        description: 'Manage video and audio access',
                        value: 'Open',
                        onTap: openAppSettings,
                      ),
                    ],
                  ),
                  _SettingsGroup(
                    title: 'About',
                    children: [
                      FutureBuilder<PackageInfo>(
                        future: _packageInfo,
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          final version = info == null
                              ? 'Loading'
                              : '${info.version} (${info.buildNumber})';
                          return _NavRow(
                            icon: Icons.info_outline_rounded,
                            label: 'Version',
                            value: version,
                          );
                        },
                      ),
                      _NavRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy policy',
                        description: 'How AM Player handles local media',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.privacyPolicy,
                        ),
                      ),
                      _NavRow(
                        icon: Icons.article_outlined,
                        label: 'Open-source licenses',
                        onTap: () async {
                          final info = await _packageInfo;
                          if (!context.mounted) return;
                          showLicensePage(
                            context: context,
                            applicationName: 'AM Player',
                            applicationVersion:
                                '${info.version} (${info.buildNumber})',
                            applicationIcon: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/images/branding/splash_logo.png',
                                width: 48,
                                height: 48,
                                cacheWidth: 144,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 7.h),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(height: 1.h, indent: 52.w),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final String value;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.description,
    this.value = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 17.sp, color: colors.onSurfaceVariant),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11.sp,
                ),
              ),
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.sp,
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.mode,
      builder: (context, mode, _) {
        final lightSelected = mode == ThemeMode.light;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  lightSelected
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_rounded,
                  size: 17.sp,
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeChoice(
                      label: 'Light',
                      active: lightSelected,
                      onTap: () => AppThemeController.setMode(ThemeMode.light),
                    ),
                    _ThemeChoice(
                      label: 'Dark',
                      active: !lightSelected,
                      onTap: () => AppThemeController.setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
