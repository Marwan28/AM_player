import 'package:am_player/theme/app_theme.dart';
import 'package:am_player/widgets/am_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'What AM Player accesses',
      'AM Player requests access to videos and audio stored on your device so '
          'it can build your local library and play the media you choose.',
    ),
    (
      'Local processing',
      'Media indexing, thumbnails, playback positions, queue state, and app '
          'preferences are processed and stored locally on your device. AM '
          'Player does not upload your media files or library metadata.',
    ),
    (
      'Data collection and sharing',
      'This MVP does not require an account and does not include analytics or '
          'advertising SDKs. It does not sell, share, or transmit personal data '
          'to the developer or to third parties.',
    ),
    (
      'Temporary files',
      'The app may create temporary artwork, thumbnails, or subtitle cache '
          'files on your device. These remain inside app-controlled storage and '
          'can be removed by clearing app data or uninstalling the app.',
    ),
    (
      'Your choices and retention',
      'You can revoke media permissions at any time from Android settings. '
          'Stored playback history and preferences remain until you clear AM '
          'Player data or uninstall the app.',
    ),
    (
      'Policy updates',
      'If a future version adds advertising, analytics, cloud features, or '
          'other data processing, this policy and the Google Play Data safety '
          'declaration will be updated before that version is released.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: AmSurface(
        child: Column(
          children: [
            AmTopBar(
              title: 'Privacy policy',
              subtitle: 'Effective July 10, 2026',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                children: [
                  Text(
                    'AM Player is designed as an on-device media player. This '
                    'policy explains how the current MVP handles your data.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13.sp,
                      height: 1.5,
                    ),
                  ),
                  for (final section in _sections) ...[
                    SizedBox(height: 18.h),
                    Text(
                      section.$1,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      section.$2,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  Text(
                    'Privacy contact',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  SelectableText(
                    'marwanabdelwahab28@gmail.com',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
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
