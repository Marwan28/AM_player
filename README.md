# AM Player

AM Player is a private, on-device video and audio player for Android. It scans
the user's local media library, groups videos and audio by folder, remembers
playback positions, supports background audio, and provides picture-in-picture
video playback.

## Android release identity

- Application ID: `com.marwan.amplayer`
- App name: `AM Player`
- Version source: `pubspec.yaml`
- Minimum Android version: determined by the installed Flutter stable SDK
- Target SDK: determined by the installed Flutter stable SDK

The application ID is permanent after the first Google Play upload. Confirm it
before creating the Play Console app.

## Release signing

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Generate or reuse an upload keystore and keep it outside version control.
3. Set `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
4. Build the bundle with `flutter build appbundle --release`.

Release builds intentionally fail when signing is not configured. Keystores and
`key.properties` are ignored by Git.

## Audio background fork

`packages/just_audio_background` is intentionally pinned to the beta.9 API. It
keeps the Android media surface to previous, play/pause, and next, restarts the
current track when previous is pressed after three seconds, and includes the
newer notification-dismissal fix when playback is stopped. Do not replace this
path override without re-testing notification and lock-screen controls.

## Verification

Run these checks before each release:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

The Google Play preparation checklist is in
[`docs/play-release-checklist.md`](docs/play-release-checklist.md). The privacy
policy source to host on a public HTTPS page is
[`docs/privacy-policy.html`](docs/privacy-policy.html).
