# El-Biblio App Icons and Splash Screen Setup

This guide explains how to set up the proper El-Biblio branding for app icons and splash screens.

## Current Status: ⚠️ PLACEHOLDER SETUP

The app is currently configured with placeholder images. You need to replace them with actual El-Biblio logo files.

## Required Images

### 1. App Icons
- **`app_icon.png`** (1024x1024px)
  - Main app icon for all platforms
  - Should include the El-Biblio logo
  - High contrast, recognizable at small sizes
  - Include the slogan "a personal spiritual operating system" if space permits

- **`app_icon_adaptive.png`** (1024x1024px)
  - Adaptive icon foreground (Android)
  - Transparent background
  - Logo should be centered and fit within safe zone
  - Leave margins for adaptive icon background

### 2. Splash Screens
- **`splash_logo.png`** (300x300px)
  - Main splash screen logo
  - Clean, simple version of the logo
  - Works well on white background
  - Should include the full El-Biblio branding

- **`splash_logo_android12.png`** (300x300px)
  - Android 12+ splash screen icon
  - Must follow Android 12 splash screen guidelines
  - Should be a simplified version of the logo

## Setup Instructions

### Step 1: Add Actual Logo Files
1. Obtain high-quality El-Biblio logo files
2. Resize them according to the specifications above
3. Replace the placeholder files in `assets/images/`:
   - Replace `app_icon.png` placeholder
   - Replace `app_icon_adaptive.png` placeholder
   - Replace `splash_logo.png` placeholder
   - Replace `splash_logo_android12.png` placeholder

### Step 2: Generate App Icons
```bash
dart run flutter_launcher_icons
```

This will generate all the required icon sizes for:
- Android (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (multiple sizes)
- Adaptive icons for Android

### Step 3: Generate Splash Screens
```bash
dart run flutter_native_splash:create
```

This will generate splash screen configurations for:
- Android (including Android 12+)
- iOS
- Updates necessary native files

### Step 4: Test the Implementation
```bash
flutter clean
flutter pub get
flutter run
```

## Design Guidelines

### Logo Requirements
- **Primary Color:** Use El-Biblio brand colors
- **Slogan:** "a personal spiritual operating system"
- **Style:** Clean, modern, spiritual aesthetic
- **Contrast:** High contrast for accessibility
- **Scalability:** Must work well from 32px to 1024px

### Splash Screen Design
- **Background:** White (#FFFFFF)
- **Logo:** Centered El-Biblio logo
- **Optional:** Subtle spiritual elements
- **Text:** Can include slogan if readable

### Adaptive Icon Guidelines (Android)
- **Safe Zone:** Keep important elements within center 66% of the icon
- **Background:** White (#FFFFFF) configured
- **Foreground:** Logo with transparent background
- **Margins:** Leave space for system masks

## Configuration Files

### pubspec.yaml Configuration
```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/app_icon_adaptive.png"

flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/images/splash_logo.png"
  android_12:
    image: "assets/images/splash_logo_android12.png"
    color: "#FFFFFF"
  ios_content_image: "assets/images/splash_logo.png"
  web: false
```

## Platform-Specific Notes

### Android
- Icons are generated in `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Adaptive icons in `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`
- Splash screen in `android/app/src/main/res/drawable/launch_background.xml`

### iOS
- Icons are generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Splash screen in `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

### Desktop
- Window icons will use the main app icon
- Splash screens are handled by the window_manager configuration

## Troubleshooting

### Icons Not Updating
1. Run `flutter clean`
2. Delete `build/` directory
3. Regenerate icons with `dart run flutter_launcher_icons`
4. Rebuild the app

### Splash Screen Issues
1. Check image file names match configuration
2. Ensure images are in correct `assets/images/` directory
3. Run `dart run flutter_native_splash:create` again
4. Clean and rebuild

### Android Adaptive Icon Issues
1. Verify `app_icon_adaptive.png` has transparent background
2. Check logo fits within safe zone
3. Test on different Android versions

## Next Steps

1. **Design Phase:** Create actual El-Biblio logo files
2. **Implementation:** Replace placeholder files
3. **Generation:** Run icon and splash generation commands
4. **Testing:** Verify on all target platforms
5. **Refinement:** Adjust based on testing results

## Files Created/Modified

- `pubspec.yaml` - Added icon and splash configuration
- `assets/images/README.md` - Documentation for image requirements
- `assets/images/*.png` - Placeholder image files (to be replaced)
- `setup_icons_splash.md` - This setup guide

---

**Note:** The current setup uses placeholder files. Replace them with actual El-Biblio branding before generating the final icons and splash screens.
