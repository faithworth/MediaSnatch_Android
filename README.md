# MediaSnatch Android (Flutter)

Full port of MediaSnatch v4.0 for Android.  
Every menu from the C# app is reproduced as a native Material 3 screen.

---

## What's inside

| Screen | Maps from C# |
|--------|-------------|
| Home   | `Program.cs` main menu |
| Video Download | `MenuVideo` |
| Audio Download | `MenuAudio` |
| Playlist / Channel | `MenuPlaylist` |
| Batch Download | `MenuBatch` |
| Clip / Trim | `MenuClip` |
| Streaming Video | `MenuStream` |
| Full Series | `MenuFullSeries` |
| Settings | `MenuSettings` + `MenuAdvanced` |
| Tools / Update | `MenuTools` |

---

## How it works on Android

Instead of `Process.Start("yt-dlp.exe", ...)` (Windows), the app:

1. **On first launch** — downloads `yt-dlp_linux_aarch64` from GitHub  
   and `ffmpeg` (ARM64 static build) from ffmpeg-kit/BtbN
2. **Saves them to** `<app private dir>/MediaSnatch/bin/` and runs `chmod +x`
3. **Calls them** via `dart:io Process.start()` — exactly like your C# code

Downloads go to `/storage/emulated/0/Download/MediaSnatch` (the normal Downloads folder).

---

## Build steps

### Prerequisites (install once)

```bash
# 1. Install Flutter SDK
# Download from https://docs.flutter.dev/get-started/install
# Add flutter/bin to your PATH

# 2. Install Android Studio
# https://developer.android.com/studio
# In Android Studio: SDK Manager → install Android SDK 34 + NDK

# 3. Accept licenses
flutter doctor --android-licenses

# 4. Verify setup
flutter doctor
```

### Build the APK

```bash
# Navigate to the project
cd mediasnatch_flutter

# Get dependencies
flutter pub get

# Build release APK (choose one):

# Option A — Single APK for all architectures (~40MB)
flutter build apk --release

# Option B — Split APKs per architecture (recommended — smaller files)
flutter build apk --release --split-per-abi

# APK output location:
# build/app/outputs/flutter-apk/app-release.apk
# or (split):
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  ← best for modern phones
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← older phones
```

### Install directly to your phone

```bash
# Enable "Developer Options" + "USB Debugging" on your phone
# Plug in via USB

# Install
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Or transfer the APK to your phone and tap it to sideload
```

### Run in development (hot reload)

```bash
# Plug in phone (USB debug enabled) or start an emulator
flutter run
```

---

## First launch on the phone

1. App opens → **auto-downloads yt-dlp + FFmpeg** (~30–50 MB total, once)
2. You'll be prompted to grant **storage permission** (needed to save to Downloads)
3. On Android 11+, tap "Allow all files" in Settings if prompted — this lets the
   app write to `/storage/emulated/0/Download/MediaSnatch`

---

## Permissions explained

| Permission | Why |
|-----------|-----|
| INTERNET | Download media + yt-dlp binary |
| WRITE_EXTERNAL_STORAGE | Save files (Android ≤ 9) |
| MANAGE_EXTERNAL_STORAGE | Save to Downloads folder (Android 10+) |
| READ_MEDIA_VIDEO / AUDIO | Read downloaded files (Android 13+) |
| FOREGROUND_SERVICE | Keep downloading when app is backgrounded |
| POST_NOTIFICATIONS | Show download progress notification |

---

## Customising the app ID

Change `com.mediasnatch.app` in `android/app/build.gradle` to your own package name
if you plan to distribute it.

---

## Known Android limitations vs Windows

| Feature | Windows | Android |
|---------|---------|---------|
| Browser cookie extraction | ✓ (--cookies-from-browser) | ✗ (no access to other app data) |
| Open folder in explorer | ✓ | Opens system Files app |
| Auto-install via winget/choco | ✓ | N/A — uses HTTP download |
| Console colours | Full 256-colour | Simulated in terminal widget |

Cookie extraction is disabled on Android because Android sandboxes prevent
reading other apps' data. For sites that require login (e.g. private YouTube
videos), use yt-dlp's `--cookies` flag with a manually exported cookies.txt
(add this via Settings → Advanced → Custom yt-dlp args).

---

## Troubleshooting

**"yt-dlp not found"** → Go to Tools screen → Install yt-dlp

**Download fails immediately** → Check internet. Some sites need yt-dlp update — Tools → Update yt-dlp

**Video+audio not merging** → FFmpeg not installed — Tools → Install FFmpeg

**Can't save to Downloads** → Grant "All files access" in Android Settings → Apps → MediaSnatch → Permissions

**App crashes on launch** → Android 5/6 device? Change `minSdkVersion 21` to match your API level
