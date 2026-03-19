# Safe Bottom Padding Usage Guide

This document explains how to use the safe bottom padding widgets to prevent bottom navigation bar overlap across the application.

## Problem
The app uses a floating bottom navigation bar with `extendBody: true` in the AppShell, which causes content to extend behind the navigation bar, making it inaccessible to users.

## Solution
Use the safe bottom padding widgets provided in `shared/widgets/safe_bottom_padding.dart`.

## Available Widgets

### 1. SafeCustomScrollView
Use this for any screen that uses `CustomScrollView`.

**Before:**
```dart
CustomScrollView(
  slivers: [
    // your slivers here
    SliverToBoxAdapter(
      child: SizedBox(height: 120), // Manual padding
    ),
  ],
)
```

**After:**
```dart
SafeCustomScrollView(
  bottomPadding: 120, // Automatic padding
  slivers: [
    // your slivers here (no manual padding needed)
  ],
)
```

### 2. SafeListView
Use this for any screen that uses `ListView`.

**Before:**
```dart
ListView(
  padding: EdgeInsets.only(bottom: 120), // Manual padding
  children: [
    // your children here
  ],
)
```

**After:**
```dart
SafeListView(
  bottomPadding: 120, // Automatic padding
  children: [
    // your children here
  ],
)
```

### 3. BottomPadding
Use this for simple cases where you just need to add padding at the bottom.

```dart
Column(
  children: [
    // your content here
    BottomPadding(height: 120),
  ],
)
```

### 4. SafeScrollableContent
Use this when you have a scrollable widget that needs to be wrapped.

```dart
SafeScrollableContent(
  bottomPadding: 120,
  child: YourScrollableWidget(),
)
```

## Recommended Padding Values

- **120px** - Standard floating bottom navigation (recommended)
- **100px** - Minimal padding for smaller content
- **140px** - Extra padding for larger devices or more space

## Implementation Checklist

When updating a screen:

1. ✅ Import the safe bottom padding widget
   ```dart
   import '../../../../shared/widgets/safe_bottom_padding.dart';
   ```

2. ✅ Replace scrollable widgets with safe versions
3. ✅ Remove manual bottom padding (SizedBox(height: 120))
4. ✅ Test on different screen sizes
5. ✅ Ensure content is fully accessible

## Updated Screens

- ✅ Bible Library Screen (bible_library_screen.dart)
- ✅ Meditation Screen (meditation_screen.dart)
- ✅ Journal Screen (journal_screen.dart)

## Screens to Update

- [ ] Today Screen
- [ ] Bible Screen  
- [ ] Profile Screen
- [ ] Settings Screen

## Migration Pattern

1. Find screens using `CustomScrollView`, `ListView`, or `SingleChildScrollView`
2. Check if they have manual bottom padding
3. Replace with appropriate safe widget
4. Remove manual padding
5. Test scrolling behavior

## Benefits

- ✅ Consistent bottom padding across the app
- ✅ No more content hidden behind navigation
- ✅ Better user experience
- ✅ Maintainable codebase
- ✅ Responsive to different screen sizes
