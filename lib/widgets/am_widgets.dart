import 'package:am_player/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AmSurface extends StatelessWidget {
  final Widget child;

  const AmSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(child: child),
    );
  }
}

class AmTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showSearch;

  const AmTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.showSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            AmIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Back',
              onPressed: onBack!,
            )
          else
            SizedBox(width: 8.w),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11.sp,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showSearch)
            AmIconButton(
              icon: Icons.search_rounded,
              tooltip: 'Search',
              onPressed: () {},
            ),
          ...actions,
        ],
      ),
    );
  }
}

class AmIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const AmIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38.w,
        height: 38.w,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 20.sp,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class AmSectionHeader extends StatelessWidget {
  final String label;
  final String? action;
  final VoidCallback? onAction;

  const AmSectionHeader({
    super.key,
    required this.label,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 7.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class AmAdBanner extends StatefulWidget {
  const AmAdBanner({super.key});

  @override
  State<AmAdBanner> createState() => _AmAdBannerState();
}

class _AmAdBannerState extends State<AmAdBanner> {
  bool closed = false;

  @override
  Widget build(BuildContext context) {
    if (closed) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'Ad',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upgrade to AM Pro',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Ad-free playback, more controls, unlimited codecs.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          AmIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Close ad',
            onPressed: () => setState(() => closed = true),
          ),
        ],
      ),
    );
  }
}

class AmBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AmBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const items = [
    (Icons.movie_creation_outlined, 'Library'),
    (Icons.music_note_rounded, 'Music'),
    (Icons.image_outlined, 'Photos'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width > size.height;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: compact ? 44.h : 58.h,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    active: i == currentIndex,
                    onTap: () => onChanged(i),
                    compact: compact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmSideNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AmSideNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = 72.w.clamp(64.0, 84.0).toDouble();
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            SizedBox(height: 8.h),
            for (var i = 0; i < AmBottomNav.items.length; i++)
              _SideNavItem(
                icon: AmBottomNav.items[i].$1,
                label: AmBottomNav.items[i].$2,
                active: i == currentIndex,
                onTap: () => onChanged(i),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? AppTheme.primary : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool compact;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppTheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: compact ? 18.sp : 21.sp),
          SizedBox(height: compact ? 1.h : 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: compact ? 9.sp : 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String amFormatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  if (hours == 0) return '${duration.inMinutes}:$seconds';
  return '$hours:$minutes:$seconds';
}

String amFormatSize(int bytes) {
  if (bytes <= 0) return '';
  final mb = bytes / (1024 * 1024);
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}
