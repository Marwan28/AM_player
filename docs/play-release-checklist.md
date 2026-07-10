# Google Play Release Checklist

## Before the first upload

- Confirm the permanent package name: `com.marwan.amplayer`.
- Configure a protected upload keystore in `android/key.properties`.
- Host `privacy-policy.html` at a public, non-editable HTTPS URL.
- Add the same privacy policy URL in Play Console.
- Confirm the support email: `marwanabdelwahab28@gmail.com`.
- Prepare phone screenshots in portrait and landscape.
- Prepare a feature graphic and the included 512x512 Play Store icon.

## Play Console declarations

- App category: Video Players & Editors.
- Ads: No for this MVP. Update this before adding any advertising SDK.
- Data safety: No data collected or shared for this MVP; local media metadata
  and playback state stay on device.
- Photo and video permissions: declare broad video access as core functionality
  because the app continuously indexes and plays the user's local video library.
- Audio permission: explain that it indexes and plays the local audio library.
- Content rating: complete the questionnaire accurately.
- Target audience: select the intended general audience; do not select children
  unless the app and every future SDK comply with Families requirements.

## Artifact checks

- `versionCode` is greater than every previously uploaded build.
- The uploaded artifact is an Android App Bundle (`.aab`).
- Target SDK is API 35 or newer.
- Native libraries pass the Android 16 KB page-size alignment check.
- The release manifest does not contain `MANAGE_EXTERNAL_STORAGE`,
  `READ_MEDIA_IMAGES`, or cleartext network access.
- Test video, audio, notification controls, lock-screen controls, PiP, resume,
  rotation, denial of permissions, and empty libraries on a physical device.

## Rollout

- Upload to Internal testing first.
- Install the Play-generated build from the test link.
- Review Android vitals and the pre-launch report.
- Promote to Closed testing if the developer account requires it.
- Start production with a staged rollout after the test build is stable.
