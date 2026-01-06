# Tapps Maintenance Guide

**Last Updated:** January 2025  
**Current Version:** Code `8`, Name `"5 (1.0.1)"`  
**Package Name:** `com.tapps.appmaniazar`

This document provides comprehensive maintenance procedures, update schedules, and critical information for maintaining the Tapps Android app on Google Play Store.

---

## Table of Contents

1. [Critical Keys & Credentials](#critical-keys--credentials)
2. [Version Management](#version-management)
3. [Update Schedule & Checkpoints](#update-schedule--checkpoints)
4. [Build Configuration Checklist](#build-configuration-checklist)
5. [Pre-Release Checklist](#pre-release-checklist)
6. [Emergency Procedures](#emergency-procedures)
7. [Monitoring & Alerts](#monitoring--alerts)
8. [Key File Locations Reference](#key-file-locations-reference)

---

## Critical Keys & Credentials

### Keystore Information

**Location:** `android/app/Tapps-keystore.jks`  
**Keys Configuration:** `android/keys.properties`  
**Key Alias:** `Tapps`  
**Passwords:** Stored in `keys.properties` (currently `Tapps2024@`)

#### Security Notes

⚠️ **CRITICAL:** Never commit the following files to git:
- `android/app/Tapps-keystore.jks`
- `android/keys.properties`
- `android/app/google-services.json`

These files are already in `.gitignore` - verify they remain excluded.

#### Keystore Backup Instructions

1. **Create a secure backup** of `Tapps-keystore.jks`:
   ```bash
   cp android/app/Tapps-keystore.jks ~/secure-backup-location/Tapps-keystore-backup-$(date +%Y%m%d).jks
   ```

2. **Store backup securely:**
   - Use encrypted storage (password-protected USB drive, cloud storage with encryption)
   - Store in multiple secure locations
   - Document backup location in secure password manager

3. **Backup `keys.properties`** (store separately from keystore):
   ```bash
   cp android/keys.properties ~/secure-backup-location/keys.properties.backup
   ```

4. **If keystore is lost:** The app cannot be updated on Google Play. You would need to create a new app listing.

### Firebase Configuration

**Location:** `android/app/google-services.json`  
**Purpose:** Firebase services integration (Auth, Firestore, Realtime Database, Analytics)  
**Update Frequency:** When Firebase project settings change

**Note:** This file contains sensitive API keys and should never be committed to version control.

### Package Information

- **Package Name:** `com.tapps.appmaniazar`
- **Application ID:** `com.tapps.appmaniazar`
- **Namespace:** `com.tapps.appmaniazar`
- **Current Version Code:** `8`
- **Current Version Name:** `"5 (1.0.1)"`

---

## Version Management

### Version Configuration Locations

Version information must be updated in **two places**:

1. **`android/app/build.gradle.kts`** (lines 40-41):
   ```kotlin
   versionCode = 8
   versionName = "5 (1.0.1)"
   ```

2. **`pubspec.yaml`** (line 19):
   ```yaml
   version: 1.0.1+8
   ```
   Format: `versionName+buildNumber` (e.g., `1.0.1+8` means version name `1.0.1` and build number `8`)

### Version Code Rules

- **Never reuse a version code** - each release must increment
- Version codes must be integers (1, 2, 3, ...)
- Google Play rejects uploads with duplicate version codes
- Version codes can only increase, never decrease

### Version Name Format

Current format: `"X (1.0.1)"` where:
- `X` = Release number (increments with major releases)
- `1.0.1` = Semantic version (major.minor.patch)

Example progression:
- `"4 (1.0.1)"` → `"5 (1.0.1)"` → `"6 (1.0.1)"` (major releases)
- Or: `"5 (1.0.1)"` → `"5 (1.0.2)"` → `"5 (1.1.0)"` (semantic versioning)

---

## Update Schedule & Checkpoints

### Monthly Checks (1st of each month)

Perform these checks on the first of every month:

- [ ] **Check Flutter SDK version:**
  ```bash
  flutter --version
  ```
  Note current version and check for updates

- [ ] **Review dependency updates:**
  ```bash
  flutter pub outdated
  ```
  Review available updates but don't auto-update (do this quarterly)

- [ ] **Check Google Play Console:**
  - Log into [Google Play Console](https://play.google.com/console)
  - Review any warnings or notifications
  - Check app status and policy compliance
  - Review user reviews and ratings

- [ ] **Review app analytics and crash reports:**
  - Check Firebase Analytics for user trends
  - Review crash reports in Firebase Crashlytics (if enabled)
  - Monitor app performance metrics

- [ ] **Check Firebase console:**
  - Verify Firebase services are operational
  - Review Firebase project quotas and usage
  - Check for any service alerts or deprecations

**Set a calendar reminder:** "Tapps Monthly Maintenance - 1st of month"

### Quarterly Checks (Jan 1, Apr 1, Jul 1, Oct 1)

Perform comprehensive updates quarterly:

- [ ] **Update Flutter SDK** (if stable release available):
  ```bash
  flutter upgrade
  flutter --version  # Verify update
  ```

- [ ] **Review and update dependencies:**
  ```bash
  flutter pub outdated
  flutter pub upgrade  # Update compatible packages
  ```
  Test thoroughly after dependency updates

- [ ] **Check Android Gradle Plugin compatibility:**
  - Review `android/settings.gradle.kts` for AGP version
  - Check compatibility with current Flutter version
  - Update if necessary (test builds after update)

- [ ] **Review Google Play policy changes:**
  - Check [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
  - Review any new requirements or deprecations
  - Ensure app compliance with latest policies

- [ ] **Audit security dependencies:**
  ```bash
  flutter pub outdated --security
  ```
  Prioritize security updates

- [ ] **Review targetSdk requirements:**
  - Current requirement: **targetSdk 35** (as of Jan 2025)
  - Check Google Play Console for upcoming requirements
  - Plan updates 2-3 months before deadline

**Set calendar reminders:** "Tapps Quarterly Maintenance - Jan 1, Apr 1, Jul 1, Oct 1"

### Google Play Store Requirements (Critical Dates)

#### Target SDK Updates

- **Current Requirement:** targetSdk 35 (as of Jan 2025)
- **Next Expected Requirement:** targetSdk 36 (typically announced 6 months in advance)
- **Check Frequency:** Monthly via Google Play Console announcements
- **Update Timeline:** Update 2-3 months before deadline to allow testing

**How to check:**
1. Log into Google Play Console
2. Navigate to Policy → App content
3. Check "Target API level" section for requirements
4. Monitor email notifications from Google Play

#### 16KB Page Size Alignment

- **Status:** ✅ Already implemented
- **Configuration:** `android/app/build.gradle.kts` (lines 46-49)
  ```kotlin
  packaging {
      jniLibs {
          useLegacyPackaging = false
      }
  }
  ```
- **Monitor:** Check quarterly for new requirements or changes

#### Edge-to-Edge Display

- **Status:** ✅ Already implemented
- **Configuration:** `android/app/src/main/kotlin/com/tapps/appmaniazar/MainActivity.kt`
- **Monitor:** Check for API deprecations quarterly

#### Security Updates

- **Check Frequency:** Quarterly
- **Sources:**
  - Google Play Security Bulletins
  - Android Security Advisories
  - Flutter Security Advisories

### Annual Maintenance (January)

Perform comprehensive annual review:

- [ ] **Full dependency audit and major version updates:**
  ```bash
  flutter pub outdated
  # Review breaking changes for major version updates
  # Plan migration strategy for major updates
  ```

- [ ] **Review and update signing keys if needed:**
  - Check keystore expiration (if applicable)
  - Verify backup integrity
  - Consider key rotation if security concerns arise

- [ ] **Archive old build artifacts:**
  - Clean up old APK/AAB files
  - Archive release notes and changelogs
  - Document version history

- [ ] **Review and update documentation:**
  - Update this maintenance guide
  - Review README.md for accuracy
  - Update any outdated procedures

- [ ] **Security audit of all credentials:**
  - Rotate passwords if needed
  - Verify backup security
  - Review access permissions

**Set calendar reminder:** "Tapps Annual Maintenance - January 1"

---

## Build Configuration Checklist

### Current Configurations

Maintain these configurations in `android/app/build.gradle.kts`:

| Configuration | Current Value | Location | Notes |
|--------------|---------------|----------|-------|
| `compileSdk` | `36` | Line 21 | Keep updated with latest Android SDK |
| `targetSdk` | `35` | Line 39 | **Must match Google Play requirements** |
| `minSdk` | `flutter.minSdkVersion` | Line 38 | Flutter default (typically 21) |
| `namespace` | `com.tapps.appmaniazar` | Line 20 | Package identifier |
| `applicationId` | `com.tapps.appmaniazar` | Line 37 | Must match package name |
| `versionCode` | `8` | Line 40 | Increment for each release |
| `versionName` | `"5 (1.0.1)"` | Line 41 | User-facing version |
| Signing Config | `release` | Lines 52-59 | Uses `keys.properties` |
| 16KB Alignment | Enabled | Lines 46-49 | Required for Google Play |

### Signing Configuration

Release builds are signed using:
- **Keystore:** `android/app/Tapps-keystore.jks`
- **Config File:** `android/keys.properties`
- **Build Type:** `release` (line 62-64)

Verify signing is configured correctly:
```bash
# Check if release build is signed
flutter build appbundle --release
# Verify with: jarsigner -verify -verbose -certs app-release.aab
```

### 16KB Page Size Alignment

**Status:** ✅ Configured  
**Location:** `android/app/build.gradle.kts` lines 46-49

```kotlin
packaging {
    jniLibs {
        useLegacyPackaging = false
    }
}
```

**Verification:** Google Play Console will validate during upload.

---

## Pre-Release Checklist

Before uploading a new version to Google Play, complete all items:

### Version Updates

- [ ] **Increment version code** (never reuse):
  - Update `android/app/build.gradle.kts` line 40
  - Update `pubspec.yaml` line 19
  - Verify both match

- [ ] **Update version name if needed:**
  - Update `android/app/build.gradle.kts` line 41
  - Follow version naming convention

- [ ] **Verify version consistency:**
  ```bash
  # Check build.gradle.kts
  grep "versionCode\|versionName" android/app/build.gradle.kts
  
  # Check pubspec.yaml
  grep "version:" pubspec.yaml
  ```

### Build Verification

- [ ] **Verify signing configuration:**
  - Confirm `keys.properties` exists and is readable
  - Verify keystore file exists: `android/app/Tapps-keystore.jks`
  - Test signing config loads correctly

- [ ] **Test release build:**
  ```bash
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```

- [ ] **Verify bundle:**
  - Use Play Console internal testing track, OR
  - Use `bundletool` to verify:
    ```bash
    bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks
    ```

### Code Quality Checks

- [ ] **Check for lint errors:**
  ```bash
  flutter analyze
  ```
  Fix all errors, review warnings

- [ ] **Run tests:**
  ```bash
  flutter test
  ```
  Ensure all tests pass

- [ ] **Format code:**
  ```bash
  dart format .
  ```

### Feature Verification

- [ ] **Verify edge-to-edge display works:**
  - Test on physical devices (various Android versions)
  - Verify system bars are transparent
  - Check content doesn't overlap system UI

- [ ] **Check 16KB alignment compliance:**
  - Google Play Console validates automatically
  - Review any warnings in Play Console

### Google Play Console

- [ ] **Review pre-submission checklist:**
  - App content rating
  - Privacy policy (if required)
  - Target audience
  - Content guidelines compliance

- [ ] **Prepare release notes:**
  - Write clear, user-friendly release notes
  - Highlight new features and bug fixes
  - Keep notes concise

- [ ] **Select release track:**
  - Internal testing (for initial verification)
  - Closed testing (for beta testing)
  - Open testing (for public beta)
  - Production (for public release)

### Post-Upload Verification

- [ ] **Monitor Google Play Console:**
  - Check for processing errors
  - Review pre-launch report
  - Verify app bundle is accepted

- [ ] **Test on internal testing track:**
  - Install from Play Store (internal testing)
  - Verify app functionality
  - Check version number displays correctly

---

## Emergency Procedures

### Lost Keystore

**If keystore file is lost:**

1. **Check backups immediately:**
   - Review secure backup locations
   - Check password manager for backup notes

2. **If backup exists:**
   - Restore keystore file to `android/app/Tapps-keystore.jks`
   - Verify `keys.properties` matches backup
   - Test build with restored keystore

3. **If no backup exists:**
   - ⚠️ **Critical:** You cannot update the existing app on Google Play
   - Options:
     - Create new app listing with new package name
     - Contact Google Play Support (low success rate for recovery)
   - **Prevention:** Always maintain secure backups

### Build Failures

**Common build issues and solutions:**

1. **Gradle sync errors:**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Kotlin compilation errors:**
   - Check `android/app/build.gradle.kts` for syntax errors
   - Verify Kotlin version compatibility
   - Review `MainActivity.kt` for errors

3. **Signing errors:**
   - Verify `keys.properties` exists and is readable
   - Check keystore file path is correct
   - Verify passwords match keystore

4. **Dependency conflicts:**
   ```bash
   flutter pub get
   flutter pub upgrade
   # If issues persist, check pubspec.lock
   ```

5. **"No space left on device":**
   - Clean build artifacts:
     ```bash
     flutter clean
     rm -rf build/
     ```
   - Free up disk space
   - Check Gradle cache: `~/.gradle/caches/`

### Google Play Rejection

**If app is rejected:**

1. **Review rejection reason:**
   - Check Google Play Console → Policy → App content
   - Read rejection email carefully
   - Note specific policy violation

2. **Common rejection reasons:**
   - Target SDK too low (update `targetSdk`)
   - Policy violation (review content)
   - Security issues (update dependencies)
   - Misleading content (update app description)

3. **Appeal process:**
   - Fix the issue
   - Update app and resubmit
   - Use Play Console appeal form if rejection seems incorrect
   - Provide detailed explanation

4. **Prevention:**
   - Review Google Play policies before submission
   - Use pre-launch report to catch issues early
   - Test on internal testing track first

### Security Incident

**If credentials are compromised:**

1. **Immediate actions:**
   - Rotate Firebase API keys in Firebase Console
   - Update `google-services.json` if compromised
   - Review access logs in Firebase Console

2. **If keystore is compromised:**
   - ⚠️ **Critical decision required:**
     - Option A: Create new app with new package name
     - Option B: If keystore not publicly exposed, monitor for abuse
   - Contact Google Play Support immediately

3. **Prevention:**
   - Never commit credentials to git
   - Use secure password manager
   - Limit access to credentials
   - Regular security audits

---

## Monitoring & Alerts

### Google Play Console Notifications

**Set up email notifications:**

1. Log into [Google Play Console](https://play.google.com/console)
2. Navigate to Settings → Email preferences
3. Enable notifications for:
   - Policy updates
   - App status changes
   - User reviews
   - Revenue reports
   - Security alerts

### Firebase Monitoring

**If Firebase Crashlytics is enabled:**

- Monitor crash reports weekly
- Set up alerts for critical crashes
- Review Firebase Analytics monthly
- Check Firebase Console for service status

### App Performance Metrics

**Track monthly:**

- User acquisition and retention
- App ratings and reviews
- Crash-free user percentage
- ANR (Application Not Responding) rate
- Revenue metrics (if applicable)

### Calendar Reminders

**Set up recurring reminders:**

- **Monthly:** 1st of each month - Monthly maintenance checklist
- **Quarterly:** Jan 1, Apr 1, Jul 1, Oct 1 - Quarterly updates
- **Annual:** January 1 - Annual comprehensive review
- **Google Play:** Check for targetSdk announcements monthly

**Recommended calendar entries:**
```
Monthly: "Tapps Maintenance - Check Flutter updates, Play Console, Analytics"
Quarterly: "Tapps Quarterly Update - Update dependencies, review policies"
Annual: "Tapps Annual Review - Full audit and documentation update"
```

---

## Key File Locations Reference

Quick reference table of all critical files:

| File/Directory | Path | Purpose | Update Frequency |
|----------------|------|---------|------------------|
| **Build Configuration** | `android/app/build.gradle.kts` | Android build settings, version, signing | Every release |
| **Android Manifest** | `android/app/src/main/AndroidManifest.xml` | App permissions, activities, metadata | As needed |
| **MainActivity** | `android/app/src/main/kotlin/com/tapps/appmaniazar/MainActivity.kt` | Main activity, edge-to-edge config | As needed |
| **Keystore** | `android/app/Tapps-keystore.jks` | App signing key | Backup regularly |
| **Keys Config** | `android/keys.properties` | Keystore credentials | Backup regularly |
| **Firebase Config** | `android/app/google-services.json` | Firebase services | When Firebase changes |
| **Dependencies** | `pubspec.yaml` | Flutter dependencies | Quarterly |
| **Version Info** | `pubspec.yaml` (line 19) | Flutter version | Every release |
| **Gradle Properties** | `android/gradle.properties` | Gradle settings | Rarely |
| **Settings** | `android/settings.gradle.kts` | Gradle project settings | Rarely |

### Important Directories

- **Source Code:** `lib/` - Main application code
- **Assets:** `assets/` - Images, fonts, animations
- **Tests:** `test/` - Unit and widget tests
- **Build Output:** `build/` - Generated build files (can be deleted)

---

## Additional Resources

### Official Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Developer Guide](https://developer.android.com/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Useful Commands Reference

```bash
# Check Flutter version
flutter --version

# Check for dependency updates
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Clean build
flutter clean
flutter pub get

# Build release bundle
flutter build appbundle --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

---

## Maintenance Log

Use this section to track maintenance activities:

| Date | Activity | Version | Notes |
|------|----------|--------|-------|
| 2025-01-04 | Initial maintenance guide created | 8 | Documented all procedures |
| | | | |
| | | | |

---

**Remember:** Regular maintenance prevents issues and ensures your app stays compliant with Google Play requirements. Set calendar reminders and stick to the schedule!

