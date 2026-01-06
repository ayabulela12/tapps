# Tapps

A cross-platform Flutter app (Android, iOS, web, macOS, Linux, Windows) with Firebase integrations and common utilities for maps, geolocation, and media assets.

---

## Table of Contents

- [Overview](#overview) ✅
- [Features](#features) ✨
- [Repository Structure](#repository-structure) 🗂️
- [Prerequisites](#prerequisites) 🔧
- [Quick Start](#quick-start) 🚀
- [Running & Building](#running--building) 🏗️
- [Testing & Quality](#testing--quality) ✅
- [Contributing](#contributing) 🤝
- [Maintenance](#maintenance) 🔧
- [Troubleshooting](#troubleshooting) ⚠️
- [License & Contact](#license--contact) 📄

---

## Overview

This repository contains a Flutter application scaffolded for multi-platform targets and using Firebase services (Auth, Firestore, Realtime DB, Analytics). It includes sample assets, multiple app entry points, and common integrations such as maps and geolocation.

The project aims to be a starting point for production apps while staying flexible for experimentation and rapid prototyping.

---

## Features

- Firebase integrations: Authentication, Firestore, Realtime Database, Analytics
- Maps & Location: `google_maps_flutter`, `geolocator`, `geocoding`
- Asset management: fonts, images, audio, videos, Lottie/Rive animations
- Multiple main entrypoints (`lib/main.dart`, `lib/main_simple.dart`, `lib/main_minimal.dart`) for different build variants or demos
- Multi-platform support: Android, iOS, web, macOS, Linux, Windows

---

## Repository Structure

Key folders and files:

- `lib/` — Dart source code (screens, providers, services, widgets)
- `assets/` — images, fonts, audio, videos, animations
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` — platform projects and configs
- `pubspec.yaml` — dependencies and assets configuration
- `test/` — unit & widget tests

---

## Prerequisites

- Flutter SDK (stable channel). Check with:

```bash
flutter --version
```

- Android SDK and Android Studio (for Android builds)
- Xcode & CocoaPods (for iOS/macOS builds)
- If using Firebase features: a Firebase project with app config files

---

## Quick Start

1. Clone the repo:

```bash
git clone <repo-url>
cd tapps
```

2. Install dependencies:

```bash
flutter pub get
```

3. Platform-specific setup:

- Android: place `google-services.json` in `android/app/` (if not already present).
- iOS/macOS: add `GoogleService-Info.plist` to the Xcode project (`ios/Runner/` / `macos/Runner/`), then run `pod install` inside `ios/`.

4. Run the app (device or emulator):

```bash
flutter run -d <device_id>
# or target a specific entrypoint
flutter run -t lib/main_simple.dart
```

---

## Running & Building

- Run on Android emulator/device:

```bash
flutter run
```

- Run on web (Chrome):

```bash
flutter run -d chrome
```

- Build APK / App Bundle:

```bash
flutter build apk --release
flutter build appbundle --release
```

- Build iOS (on macOS):

```bash
flutter build ios --release
```

- Build macOS/Linux/Windows:

```bash
flutter build macos
flutter build linux
flutter build windows
```

---

## Testing & Quality

- Run unit & widget tests:

```bash
flutter test
```

- Static analysis:

```bash
flutter analyze
```

- Format code:

```bash
dart format .
```

---

## Contributing

Thanks for considering contributing! Please follow these simple steps:

1. Fork the repository and create a feature branch:

```bash
git checkout -b feat/your-feature
```

2. Keep changes small and focused; add or update tests where appropriate.
3. Run tests and linters locally before opening a PR.
4. Open a pull request with a clear description of your changes.

---

## Maintenance

For comprehensive maintenance procedures, update schedules, and critical information for maintaining the Tapps Android app on Google Play Store, see **[MAINTENANCE.md](MAINTENANCE.md)**.

The maintenance guide includes:
- Critical keys and credentials management
- Version management procedures
- Monthly, quarterly, and annual update schedules
- Pre-release checklists
- Emergency procedures
- Monitoring and alert setup

**Quick Maintenance Reminders:**
- **Monthly:** Check Flutter updates, review Play Console, check analytics (1st of month)
- **Quarterly:** Update dependencies, review policies, audit security (Jan 1, Apr 1, Jul 1, Oct 1)
- **Annual:** Full dependency audit, security review, documentation update (January)

---

## Troubleshooting

- Missing Firebase files: If the app fails to start due to missing Firebase config, download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project and place them in the appropriate platform folders.

- CocoaPods issues (iOS/macOS):

```bash
cd ios && pod install --repo-update
```

- Gradle build errors: try a clean build:

```bash
flutter clean
flutter pub get
```

---

## License & Copyright

© 2025 Appmaniazar PTY Ltd. All rights reserved.

This software and all associated assets are proprietary and confidential property of Appmaniazar PTY Ltd. No part of this project may be reproduced, distributed, or transmitted without prior written permission.

For licensing or partnership inquiries, please contact Appmaniazar PTY Ltd.

See [COPYRIGHT](COPYRIGHT) for full copyright notice.

---

**Maintainer:** Thembela  
**Company:** Appmaniazar PTY Ltd

---

If you'd like, I can also:
- Add a project badge (build, coverage)
- Add sample screenshots to the `docs/` folder and include them here
- Add a `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`

💡 **Next step:** review this draft and tell me any specific items you want added or reworded — I can update it immediately.
