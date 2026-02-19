# El-Biblio Flutter CI/CD Pipeline

This document describes the CI/CD pipeline setup for the El-Biblio Flutter application.

## Overview

The CI/CD pipeline is configured to automatically build and deploy both Android and iOS versions of the El-Biblio Flutter app when changes are pushed to the main/release branches or when manually triggered.

## Pipeline Configuration

### Workflow File
- **Location**: `.github/workflows/flutter-mobile-build.yml`
- **Triggers**: 
  - Push to `main` or `release` branches with changes to `pubspec.yaml`, `android/**`, `ios/**`, or `lib/**`
  - Manual workflow dispatch

### Build Process

#### 1. Prepare Build
- Extracts version information from `pubspec.yaml`
- Generates unique build ID
- Compares with previous version to determine if rebuild is needed
- Prunes old artifacts and checks disk space

#### 2. Android Build
- Sets up JDK 21, Ruby, and Flutter environment
- Downloads and configures signing keystore from R2 storage
- Creates/updates keystore.properties
- Downloads Google Play service account JSON
- Builds APK and AAB using Fastlane
- Uploads artifacts to GitHub Actions
- Uploads AAB to Google Play Console (internal track)

#### 3. iOS Build
- Runs on macOS-15 with Xcode 16
- Sets up Ruby, Flutter, and CocoaPods
- Downloads signing assets from R2 storage:
  - Distribution certificate
  - P12 private key
  - Mobile provisioning profile
  - App Store Connect API key (optional)
- Sets up code signing in temporary keychain
- Builds IPA using Fastlane
- Uploads IPA to GitHub Actions
- Uploads to TestFlight (if API key available)

## Required Secrets

### Common Secrets
- `R2_ACCESS_KEY_ID`: Cloudflare R2 access key
- `R2_SECRET_ACCESS_KEY`: Cloudflare R2 secret key
- `R2_ACCOUNT_ID`: Cloudflare R2 account ID
- `R2_KEYSTORE_BUCKET`: S3 bucket name for signing assets

### Android Secrets
- `ANDROID_KEYSTORE_PASSWORD`: Password for the Android keystore
- `ANDROID_KEY_PASSWORD`: Password for the private key

### iOS Secrets
- `IOS_KEYCHAIN_PASSWORD`: Password for the temporary keychain
- `IOS_P12_PASSWORD`: Password for the P12 certificate (may be empty)
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key ID (optional)
- `APPSTORE_ISSUER_ID`: App Store issuer ID (optional)

## Fastlane Configuration

### Android Fastlane
- **Location**: `android/fastlane/Fastfile`
- **Lanes**:
  - `build_release`: Clean and build release APK/AAB
  - `upload_to_play_console`: Upload AAB to Google Play Console
  - `build_and_upload`: Combined build and upload

### iOS Fastlane
- **Location**: `ios/fastlane/Fastfile`
- **Lanes**:
  - `setup_signing`: Configure code signing with downloaded assets
  - `build_release`: Build release IPA
  - `upload_testflight`: Upload IPA to TestFlight
  - `build_and_upload`: Combined build and upload

## Version Management

The pipeline automatically extracts version information from `pubspec.yaml`:
- Format: `version: 1.0.31+10032`
- Version name: `1.0.31`
- Build number: `10032`

The build is only triggered if the version has changed since the last commit.

## Artifact Storage

### GitHub Actions Artifacts
- **Android APK**: `android-apa-{build_id}` (30 days retention)
- **Android AAB**: `android-aab-{build_id}` (30 days retention)
- **iOS IPA**: `ios-ipa-{build_id}` (30 days retention)
- **iOS Fastlane Logs**: `ios-fastlane-logs-{build_id}` (14 days retention)

### Cloudflare R2 Storage
- **Android Keystore**: `keystore/elbiblio.jks`
- **Google Play Service Account**: `pc-api-8544579711642974481-790-f1fa1d5f9f3c.json`
- **iOS Distribution Certificate**: `iosbuild/distribution.cer`
- **iOS P12 Certificate**: `iosbuild/Venmail_Distribution.new.p12`
- **iOS Provisioning Profile**: `iosbuild/Elbiblio.mobileprovision`
- **iOS App Store Connect Key**: `iosbuild/AuthKey_4WKTZ9VTBH_ConnectKey.p8`

## Deployment Targets

### Android
- **Google Play Console**: Internal track (draft status)
- **Package Name**: `com.elbiblio.app`

### iOS
- **TestFlight**: External testing (if API key configured)
- **Bundle ID**: `com.elbiblio.app`

## Local Development

### Prerequisites
- Flutter SDK 3.19.0+
- Xcode 16+ (for iOS)
- Android SDK (for Android)
- Ruby 3.2+ (for Fastlane)
- Fastlane gems

### Setup Commands
```bash
# Install Flutter dependencies
flutter pub get

# Install iOS dependencies (macOS only)
cd ios && pod install && cd ..

# Install Fastlane (both platforms)
cd android && gem install fastlane && cd ..
cd ios && gem install fastlane && cd ..
```

### Local Build Commands
```bash
# Android
cd android
fastlane build_release

# iOS
cd ios
fastlane build_release
```

## Troubleshooting

### Common Issues
1. **Signing certificate expired**: Update certificates in R2 storage
2. **Provisioning profile expired**: Update mobileprovision file
3. **Keystore password mismatch**: Verify ANDROID_KEYSTORE_PASSWORD secret
4. **P12 password incorrect**: Verify IOS_P12_PASSWORD secret
5. **Bundle ID mismatch**: Ensure provisioning profile matches app bundle ID

### Debug Information
- iOS build logs are uploaded as artifacts for debugging
- Keychain and profile information is printed on failure
- Fastlane generates HTML reports for inspection

## Security Notes

- All signing assets are stored in encrypted R2 storage
- Secrets are never logged or exposed in artifacts
- Temporary keychains are created and destroyed during builds
- Signing assets are cleaned up after each build

## Maintenance

- Regularly update Flutter SDK version in workflow
- Monitor certificate expiration dates
- Keep Fastlane gems updated
- Review and rotate secrets periodically
- Monitor artifact storage usage
