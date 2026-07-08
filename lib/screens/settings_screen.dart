import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool resumePlayback = true;
  bool subtitles = true;
  bool hwAcceleration = true;

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
                    title: 'Playback',
                    children: [
                      _SwitchRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Resume playback',
                        desc: 'Continue where you left off',
                        value: resumePlayback,
                        onChanged: (value) {
                          setState(() => resumePlayback = value);
                        },
                      ),
                      _SwitchRow(
                        icon: Icons.subtitles_outlined,
                        label: 'Subtitles',
                        desc: 'Auto-load matching .srt/.vtt files',
                        value: subtitles,
                        onChanged: (value) {
                          setState(() => subtitles = value);
                        },
                      ),
                      _SwitchRow(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Hardware acceleration',
                        desc: 'Use the best decoder available',
                        value: hwAcceleration,
                        onChanged: (value) {
                          setState(() => hwAcceleration = value);
                        },
                      ),
                      const _NavRow(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Default audio track',
                        value: 'Auto',
                      ),
                    ],
                  ),
                  const _SettingsGroup(
                    title: 'About',
                    children: [
                      _NavRow(
                        icon: Icons.info_outline_rounded,
                        label: 'Version',
                        value: 'AM Player 1.0.0',
                      ),
                      _NavRow(
                        icon: Icons.article_outlined,
                        label: 'Licenses',
                        value: '',
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
                letterSpacing: 0,
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

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRowShell(
      icon: icon,
      label: label,
      desc: desc,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: AppTheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRowShell(
      icon: icon,
      label: label,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11.sp,
              ),
            ),
          SizedBox(width: 4.w),
          Icon(
            Icons.chevron_right_rounded,
            size: 18.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
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
        return _SettingsRowShell(
          icon: lightSelected
              ? Icons.light_mode_outlined
              : Icons.dark_mode_rounded,
          label: 'Theme',
          desc: 'Cinematic dark or clean light',
          trailing: Container(
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

class _SettingsRowShell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? desc;
  final Widget trailing;

  const _SettingsRowShell({
    required this.icon,
    required this.label,
    this.desc,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                if (desc != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    desc!,
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
          SizedBox(width: 10.w),
          trailing,
        ],
      ),
    );
  }
}
