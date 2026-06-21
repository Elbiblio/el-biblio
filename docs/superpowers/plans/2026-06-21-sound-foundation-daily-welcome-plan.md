# Sound Foundation & Daily Welcome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the sound system into a provider-driven, lifecycle-aware service, add a user sound toggle, and ship the once-per-day home-screen welcome animation with a shiny sound.

**Architecture:** `SoundService` becomes a Riverpod provider that exposes semantic one-shot SFX and ambient-loop methods. It watches `soundEnabled` from `AppSettings` and respects DND/silent mode. A `SoundLifecycleObserver` pauses ambient on backgrounding. `DailyWelcomeOverlay` renders the ray/sparkle animation and is wired into `HomeScreen` with a date gate.

**Tech Stack:** Flutter, flutter_riverpod, go_router, audioplayers, do_not_disturb, shared_preferences/Hive.

---

## File Structure

- **Modify:**
  - `lib/core/storage/app_settings.dart` — add `soundEnabled` and `lastWelcomeDate`.
  - `lib/core/storage/settings_storage.dart` — add `loadSoundEnabled` / `saveSoundEnabled` helpers (or rely on existing AppSettings load/save).
  - `lib/core/application/settings_notifier.dart` — add `setSoundEnabled()` and `markWelcomeShownForToday()`.
  - `lib/core/services/sound_service.dart` — refactor to provider, split ambient/SFX, add lifecycle, semantic methods.
  - `lib/core/di/app_providers.dart` — update `soundServiceProvider` to use new constructor.
  - `lib/features/home/presentation/screens/home_screen.dart` — wire welcome overlay.
  - `lib/features/profile/presentation/profile_screen.dart` — add sound toggle.
  - `pubspec.yaml` — add new asset directories if needed.
- **Create:**
  - `lib/core/services/sound_lifecycle_observer.dart` — app lifecycle and DND listener.
  - `lib/features/home/presentation/widgets/daily_welcome_overlay.dart` — ray/sparkle animation.
  - `assets/audio/LICENSE-SOUNDS.md` — license doc for downloaded assets.
- **Tests:**
  - `test/core/services/sound_service_test.dart` — unit tests.
  - `test/features/home/presentation/widgets/daily_welcome_overlay_test.dart` — widget test.

---

## Task 1: Add sound settings fields to AppSettings

**Files:**
- Modify: `lib/core/storage/app_settings.dart`

- [ ] **Step 1: Add `soundEnabled` and `lastWelcomeDate` fields**

Add the two new fields to the `AppSettings` constructor parameters:

```dart
required this.soundEnabled,
required this.lastWelcomeDate,
```

Add the declarations right after `onboardingDraft`:

```dart
final bool soundEnabled;
final DateTime? lastWelcomeDate;
```

- [ ] **Step 2: Update `AppSettings.defaults()`**

Set `soundEnabled: true` and `lastWelcomeDate: null` in `AppSettings.defaults()`:

```dart
return const AppSettings(
  ...
  onboardingDraft: null,
  soundEnabled: true,
  lastWelcomeDate: null,
);
```

- [ ] **Step 3: Update `toJson()`**

Add these two entries to the map returned by `toJson()`:

```dart
'soundEnabled': soundEnabled,
'lastWelcomeDate': lastWelcomeDate?.toIso8601String(),
```

- [ ] **Step 4: Update `copyWith()`**

Add to `copyWith` signature:

```dart
bool? soundEnabled,
DateTime? lastWelcomeDate,
```

Add to the body:

```dart
soundEnabled: soundEnabled ?? this.soundEnabled,
lastWelcomeDate: lastWelcomeDate ?? this.lastWelcomeDate,
```

- [ ] **Step 5: Verify no compile errors**

Run: `flutter analyze lib/core/storage/app_settings.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/storage/app_settings.dart
git commit -m "feat(settings): add soundEnabled and lastWelcomeDate fields"
```

---

## Task 2: Add settings mutator methods

**Files:**
- Modify: `lib/core/application/settings_notifier.dart`

- [ ] **Step 1: Add `setSoundEnabled()`**

Insert near the other `set*` methods (e.g., after `setAccountabilityTone`):

```dart
Future<void> setSoundEnabled(bool enabled) async {
  final next = state.copyWith(soundEnabled: enabled);
  state = next;
  await _persistWithRetry(next);
}
```

- [ ] **Step 2: Add `markWelcomeShownForToday()`**

```dart
Future<void> markWelcomeShownForToday() async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final next = state.copyWith(lastWelcomeDate: today);
  state = next;
  await _persistWithRetry(next);
}
```

- [ ] **Step 3: Verify no compile errors**

Run: `flutter analyze lib/core/application/settings_notifier.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/application/settings_notifier.dart
git commit -m "feat(settings): add soundEnabled and lastWelcomeDate mutators"
```

---

## Task 3: Refactor SoundService into a provider-aware service

**Files:**
- Modify: `lib/core/services/sound_service.dart`
- Modify: `lib/core/di/app_providers.dart`

- [ ] **Step 1: Replace the singleton with a configurable class**

Rewrite `SoundService` to accept settings and remove the singleton.

```dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService({required bool soundEnabled}) : _soundEnabled = soundEnabled {
    _initAudio();
  }

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _soundEnabled;
  bool _isAmbientPlaying = false;
  bool _isDndActive = false;
  bool _isAppPaused = false;
  String? _currentAmbientAsset;

  // Asset constants
  static const String welcomeShinyAsset = 'audio/welcome-shiny.mp3';
  static const String tapAsset = 'audio/ui-tap.mp3';
  static const String successAsset = 'audio/ui-success.mp3';
  static const String completeAsset = 'audio/ui-complete.mp3';
  static const String errorAsset = 'audio/ui-error.mp3';
  static const String transitionAsset = 'audio/transition-whoosh.mp3';
  static const String pageTurnAsset = 'audio/page-turn.mp3';
  static const String paperRustleAsset = 'audio/paper-rustle.mp3';
  static const String ambientHomeAsset = 'audio/ambient/ambient-home.mp3';
  static const String ambientTodayAsset = 'audio/ambient/ambient-today.mp3';
  static const String ambientBibleAsset = 'audio/ambient/ambient-bible.mp3';
  static const String ambientCommunityAsset = 'audio/ambient/community.mp3';
  static const String bellMeditationAsset = 'audio/bell-meditation.mp3';
  static const String chimeGentleAsset = 'audio/chime-gentle.mp3';
  static const String successBellAsset = 'audio/success_bell.mp3';
  static const String levelUpAsset = 'audio/level-up.mp3';
  static const String correctAsset = 'audio/correct.mp3';
  static const String wrongAsset = 'audio/wrong.mp3';

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      unawaited(stopAmbient());
      unawaited(_sfxPlayer.stop());
    }
  }

  void setDndActive(bool active) {
    _isDndActive = active;
    if (active) {
      unawaited(stopAmbient());
    }
  }

  void setAppPaused(bool paused) {
    _isAppPaused = paused;
    if (paused) {
      unawaited(_ambientPlayer.pause());
    } else if (_isAmbientPlaying && _currentAmbientAsset != null) {
      unawaited(_ambientPlayer.resume());
    }
  }

  Future<void> _initAudio() async {
    try {
      await _ambientPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      await _sfxPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (_) {
      // Continue silently; audio is not launch-critical.
    }
  }

  Future<void> _playSfx(String asset, {double volume = 0.5}) async {
    if (!_soundEnabled || _isDndActive || _isAppPaused) return;
    try {
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource(asset));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playTap() => _playSfx(tapAsset, volume: 0.18);
  Future<void> playSuccess() => _playSfx(successAsset, volume: 0.5);
  Future<void> playComplete() => _playSfx(completeAsset, volume: 0.5);
  Future<void> playError() => _playSfx(errorAsset, volume: 0.35);
  Future<void> playTransition() => _playSfx(transitionAsset, volume: 0.25);
  Future<void> playPageTurn() => _playSfx(pageTurnAsset, volume: 0.22);
  Future<void> playPaperRustle() => _playSfx(paperRustleAsset, volume: 0.2);
  Future<void> playWelcomeShiny() => _playSfx(welcomeShinyAsset, volume: 0.7);

  Future<void> playBellMeditation() => _playSfx(bellMeditationAsset, volume: 0.5);
  Future<void> playChimeGentle() => _playSfx(chimeGentleAsset, volume: 0.5);
  Future<void> playSuccessBell() => _playSfx(successBellAsset, volume: 0.5);
  Future<void> playLevelUp() => _playSfx(levelUpAsset, volume: 0.5);
  Future<void> playCorrect() => _playSfx(correctAsset, volume: 0.5);
  Future<void> playWrong() => _playSfx(wrongAsset, volume: 0.35);

  Future<void> playAmbient(String asset, {double volume = 0.10}) async {
    if (!_soundEnabled || _isDndActive || _isAppPaused) return;
    if (_isAmbientPlaying && _currentAmbientAsset == asset) return;

    try {
      await stopAmbient();
      _isAmbientPlaying = true;
      _currentAmbientAsset = asset;
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(volume);
      await _ambientPlayer.play(AssetSource(asset));
    } catch (_) {
      _isAmbientPlaying = false;
      _currentAmbientAsset = null;
    }
  }

  Future<void> stopAmbient() async {
    if (!_isAmbientPlaying) return;
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.setReleaseMode(ReleaseMode.release);
    } catch (_) {} finally {
      _isAmbientPlaying = false;
      _currentAmbientAsset = null;
    }
  }

  Future<void> stopAll() async {
    await stopAmbient();
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopAll();
    await _ambientPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
```

> **Note:** keep the old `playGameTap`, `playGameSuccess`, etc. methods as thin aliases to the new methods during the migration so existing callers continue to compile. Remove them after Task 8.

- [ ] **Step 2: Update `app_providers.dart`**

Replace the existing `soundServiceProvider` with one that watches settings:

```dart
final soundServiceProvider = Provider<SoundService>((ref) {
  final settings = ref.watch(settingsProvider);
  final service = SoundService(soundEnabled: settings.soundEnabled);

  ref.listen<bool>(
    settingsProvider.select((s) => s.soundEnabled),
    (_, next) => service.setSoundEnabled(next),
  );

  ref.onDispose(() => service.dispose());
  return service;
});
```

- [ ] **Step 3: Run analyzer and fix imports**

Run: `flutter analyze lib/core/services/sound_service.dart lib/core/di/app_providers.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/sound_service.dart lib/core/di/app_providers.dart
git commit -m "feat(sound): refactor SoundService into provider with ambient/sfx split"
```

---

## Task 4: Create lifecycle observer

**Files:**
- Create: `lib/core/services/sound_lifecycle_observer.dart`

- [ ] **Step 1: Implement the observer**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/app_providers.dart';
import 'sound_service.dart';

/// Observes app lifecycle and DND state to pause/resume ambient audio.
class SoundLifecycleObserver extends WidgetsBindingObserver {
  SoundLifecycleObserver(this._ref);

  final WidgetRef _ref;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = _ref.read(soundServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        service.setAppPaused(true);
      case AppLifecycleState.resumed:
        service.setAppPaused(false);
      case AppLifecycleState.inactive:
        // No change; keep current state.
        break;
    }
  }
}
```

> **Note:** DND checking via the `do_not_disturb` package will be wired in a later step if the package exposes a synchronous stream. For now, the service provides the `setDndActive` hook.

- [ ] **Step 2: Wire observer into the app root**

Find the root widget (likely `lib/main.dart` or `lib/app.dart`). Add a `ConsumerStatefulWidget` wrapper that initializes `SoundLifecycleObserver` in `initState` and disposes it in `dispose()`.

Example insertion in `main.dart` (adjust to actual root widget):

```dart
class _AppLifecycleWrapperState extends ConsumerState<AppLifecycleWrapper> {
  SoundLifecycleObserver? _observer;

  @override
  void initState() {
    super.initState();
    _observer = SoundLifecycleObserver(ref);
    _observer!.initialize();
  }

  @override
  void dispose() {
    _observer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

If the root is already a `ConsumerStatefulWidget`, add the observer directly there.

- [ ] **Step 3: Verify analyzer**

Run: `flutter analyze lib/core/services/sound_lifecycle_observer.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/sound_lifecycle_observer.dart lib/main.dart
git commit -m "feat(sound): add lifecycle observer for ambient pause/resume"
```

---

## Task 5: Add sound toggle to Profile screen

**Files:**
- Modify: `lib/features/profile/presentation/profile_screen.dart`

- [ ] **Step 1: Locate a settings section and add the toggle**

Search the `build` method for a `Card` or settings list. Add a new `ListTile` with a `Switch`:

```dart
ListTile(
  leading: Icon(
    settings.soundEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
    color: primaryTextColor,
  ),
  title: Text(
    'Sound',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryTextColor,
    ),
  ),
  subtitle: Text(
    'Play subtle sounds for actions and screens',
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: primaryTextColor.withValues(alpha: 0.7),
    ),
  ),
  trailing: Switch(
    value: settings.soundEnabled,
    onChanged: (val) {
      ref.read(settingsProvider.notifier).setSoundEnabled(val);
    },
  ),
),
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/features/profile/presentation/profile_screen.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/profile_screen.dart
git commit -m "feat(profile): add sound on/off toggle"
```

---

## Task 6: Create DailyWelcomeOverlay widget

**Files:**
- Create: `lib/features/home/presentation/widgets/daily_welcome_overlay.dart`

- [ ] **Step 1: Implement the overlay**

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_animations.dart';

class DailyWelcomeOverlay extends StatefulWidget {
  const DailyWelcomeOverlay({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<DailyWelcomeOverlay> createState() => _DailyWelcomeOverlayState();
}

class _DailyWelcomeOverlayState extends State<DailyWelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (reducedMotion) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onComplete();
      });
      return Container(
        color: colors.surface.withValues(alpha: 0.4),
        child: const Center(child: SizedBox.shrink()),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: colors.surface.withValues(alpha: 0.0),
                ),
              ),
              Positioned(
                top: -MediaQuery.of(context).size.height * 0.2,
                left: -MediaQuery.of(context).size.width * 0.3,
                right: -MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.height * 0.9,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 3.14,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.5, 0.0),
                          radius: 0.8,
                          colors: [
                            colors.primary.withValues(alpha: 0.18),
                            colors.primary.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -MediaQuery.of(context).size.height * 0.1,
                left: -MediaQuery.of(context).size.width * 0.4,
                right: -MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Transform.rotate(
                  angle: -_rotationAnimation.value * 3.14,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.5, 0.0),
                        radius: 0.7,
                        colors: [
                          colors.secondary.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              ..._buildSparkles(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles(BuildContext context) {
    final random = [0.12, 0.28, 0.45, 0.62, 0.78, 0.88];
    return random.map((dx) {
      final delay = Interval(dx * 0.6, dx * 0.6 + 0.3, curve: Curves.easeOut);
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = delay.transform(_controller.value);
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.05 + dx * 120,
            left: MediaQuery.of(context).size.width * dx,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.5 + t * 0.5,
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/features/home/presentation/widgets/daily_welcome_overlay.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/widgets/daily_welcome_overlay.dart
git commit -m "feat(home): add daily welcome ray/sparkle overlay widget"
```

---

## Task 7: Wire welcome overlay into HomeScreen

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: Add state and import overlay**

Add the import:

```dart
import '../widgets/daily_welcome_overlay.dart';
import '../../../../core/services/sound_service.dart';
```

Add a state variable in `_HomeScreenState`:

```dart
bool _showWelcome = false;
```

- [ ] **Step 2: Add welcome trigger logic**

In `initState`, after the existing post-frame callback, add:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  ref.read(visionProvider.notifier).load();
  _checkForMissedDaysAndShowSuggestion();
  _maybeShowWelcome();
});
```

Add the method:

```dart
Future<void> _maybeShowWelcome() async {
  final settings = ref.read(settingsProvider);
  if (!settings.onboardingCompleted) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last = settings.lastWelcomeDate;
  if (last != null &&
      last.year == today.year &&
      last.month == today.month &&
      last.day == today.day) {
    return;
  }

  if (!mounted) return;
  if (ModalRoute.of(context)?.isCurrent != true) return;

  setState(() => _showWelcome = true);
  await ref.read(soundServiceProvider).playWelcomeShiny();
  await ref.read(settingsProvider.notifier).markWelcomeShownForToday();
}
```

- [ ] **Step 3: Render the overlay conditionally**

Wrap the `Scaffold` body in a `Stack` and add the overlay at the end:

```dart
return Scaffold(
  body: Stack(
    children: [
      Container(
        decoration: BoxDecoration(...), // existing gradient
        child: SafeArea(...), // existing content
      ),
      if (_showWelcome)
        DailyWelcomeOverlay(
          onComplete: () {
            if (mounted) setState(() => _showWelcome = false);
          },
        ),
    ],
  ),
);
```

- [ ] **Step 4: Verify analyzer**

Run: `flutter analyze lib/features/home/presentation/screens/home_screen.dart`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/screens/home_screen.dart
git commit -m "feat(home): wire daily welcome overlay and sound"
```

---

## Task 8: Migrate existing SoundService callers

**Files:**
- Modify: `lib/features/games/presentation/screens/journey_map_screen.dart`
- Modify: `lib/features/games/presentation/screens/journey_quiz_screen.dart`
- Modify: `lib/features/games/application/journey_game_notifier.dart`
- Modify: `lib/features/bible/presentation/games/verse_game_screen.dart`
- Modify: `lib/features/bible/application/verse_game_notifier.dart`
- Modify: `lib/features/commit/presentation/screens/overlay_notification_screen.dart`
- Modify: `lib/core/services/celebration_service.dart`

- [ ] **Step 1: Replace singleton access with provider reads**

All existing `SoundService.instance` or `SoundService()` calls should be replaced with `ref.read(soundServiceProvider)` where a `WidgetRef`/`Ref` is available. Where `CelebrationService` currently uses `SoundService.instance`, change it to accept a `SoundService` parameter or use the provider when invoked from a Riverpod context.

For `CelebrationService`:

```dart
void playOnboardingCompletion(BuildContext context, WidgetRef ref) {
  playCelebration(
    context: context,
    type: CelebrationType.onboarding,
    soundService: ref.read(soundServiceProvider),
  );
}
```

And update ` CelebrationService.playCelebration` to accept the service, or use the provider inside if it already has a `ref`.

- [ ] **Step 2: Keep game-specific method aliases**

In `SoundService`, add thin aliases so existing code still compiles:

```dart
Future<void> playGameTap() => playTap();
Future<void> playGameSuccess() => playSuccess();
Future<void> playGameFail() => playWrong();
Future<void> playGameTick() => playTap(); // or a dedicated tick sound
Future<void> playGameTimeout() => playError();
Future<void> playGameLevelUp() => playLevelUp();
Future<void> playGameOver() => playError();
Future<void> playOnboardingSuccess() => playSuccessBell();
Future<void> playJourneyAmbience() => playAmbient(ambientHomeAsset);
Future<void> stopJourneyAmbience() => stopAmbient();
Future<void> playCategoryAmbience(String asset) => playAmbient(asset);
Future<void> stopCategoryAmbience() => stopAmbient();
```

- [ ] **Step 3: Verify analyzer and tests**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(sound): migrate existing callers to provider-based SoundService"
```

---

## Task 9: Add sound assets and update pubspec

**Files:**
- Create: `assets/audio/welcome-shiny.mp3`, `assets/audio/ui-tap.mp3`, `assets/audio/ui-success.mp3`, `assets/audio/ui-complete.mp3`, `assets/audio/ui-error.mp3`, `assets/audio/transition-whoosh.mp3`, `assets/audio/page-turn.mp3`, `assets/audio/paper-rustle.mp3`, `assets/audio/ambient/ambient-home.mp3`, `assets/audio/ambient/ambient-today.mp3`, `assets/audio/ambient/ambient-bible.mp3`
- Create: `assets/audio/LICENSE-SOUNDS.md`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Download or generate MP3 assets**

For each new asset, download a short royalty-free/CC0 MP3 from Pixabay or Freesound. If a clean download is not available, use the fallback asset already in the repo:

| Asset | Fallback (if download fails) |
|---|---|
| `welcome-shiny.mp3` | `success_bell.mp3` |
| `ui-tap.mp3` | `ding.wav` |
| `ui-success.mp3` | `chime-gentle.mp3` |
| `ui-complete.mp3` | `level-up.mp3` |
| `ui-error.mp3` | `wrong.mp3` |
| `transition-whoosh.mp3` | `ding.wav` (very short) |
| `page-turn.mp3` | `paper-rustle.mp3` |
| `paper-rustle.mp3` | `chime-gentle.mp3` |
| `ambient-home.mp3` | `ambient.mp3` |
| `ambient-today.mp3` | `ambient/garden.mp3` |
| `ambient-bible.mp3` | `ambient/forest.mp3` |

- [ ] **Step 2: Create `assets/audio/LICENSE-SOUNDS.md`**

```markdown
# Sound Asset Licenses

All assets below are used under CC0 or equivalent royalty-free licenses.

| File | Source | Author | License |
|---|---|---|---|
| welcome-shiny.mp3 | Pixabay | TODO | CC0 |
| ui-tap.mp3 | Pixabay | TODO | CC0 |
| ui-success.mp3 | Pixabay | TODO | CC0 |
| ui-complete.mp3 | Pixabay | TODO | CC0 |
| ui-error.mp3 | Pixabay | TODO | CC0 |
| transition-whoosh.mp3 | Pixabay | TODO | CC0 |
| page-turn.mp3 | Pixabay | TODO | CC0 |
| paper-rustle.mp3 | Pixabay | TODO | CC0 |
| ambient/ambient-home.mp3 | Pixabay | TODO | CC0 |
| ambient/ambient-today.mp3 | Pixabay | TODO | CC0 |
| ambient/ambient-bible.mp3 | Pixabay | TODO | CC0 |

Update the table with real URLs and authors after each download.
```

- [ ] **Step 3: Update `pubspec.yaml`**

Ensure these are already present or add them under `flutter: assets:`:

```yaml
- assets/audio/
- assets/audio/ambient/
```

- [ ] **Step 4: Commit**

```bash
git add assets/audio/ pubspec.yaml
git commit -m "assets: add sound fx and ambient loops for foundation + welcome"
```

---

## Task 10: Write unit tests for SoundService

**Files:**
- Create: `test/core/services/sound_service_test.dart`

- [ ] **Step 1: Test enabled/disabled gating**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/core/services/sound_service.dart';

void main() {
  group('SoundService', () {
    test('play methods are no-ops when sound is disabled', () async {
      final service = SoundService(soundEnabled: false);
      await service.playWelcomeShiny();
      await service.playSuccess();
      await service.playAmbient(SoundService.ambientHomeAsset);
      expect(service.soundEnabled, false);
      await service.dispose();
    });

    test('play methods are no-ops when DND is active', () async {
      final service = SoundService(soundEnabled: true);
      service.setDndActive(true);
      await service.playWelcomeShiny();
      await service.playAmbient(SoundService.ambientHomeAsset);
      service.setDndActive(false);
      await service.dispose();
    });

    test('setSoundEnabled stops ambient and sfx', () async {
      final service = SoundService(soundEnabled: true);
      await service.setSoundEnabled(false);
      expect(service.soundEnabled, false);
      await service.dispose();
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/core/services/sound_service_test.dart`
Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/core/services/sound_service_test.dart
git commit -m "test(sound): add SoundService gating unit tests"
```

---

## Task 11: Write widget test for DailyWelcomeOverlay

**Files:**
- Create: `test/features/home/presentation/widgets/daily_welcome_overlay_test.dart`

- [ ] **Step 1: Test animation completes and calls onComplete**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/home/presentation/widgets/daily_welcome_overlay.dart';

void main() {
  testWidgets('DailyWelcomeOverlay completes and invokes callback', (
    WidgetTester tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DailyWelcomeOverlay(onComplete: () => completed = true),
      ),
    );

    expect(completed, false);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, true);
  });

  testWidgets('DailyWelcomeOverlay respects reduced motion', (
    WidgetTester tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: DailyWelcomeOverlay(onComplete: () => completed = true),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    expect(completed, true);
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/home/presentation/widgets/daily_welcome_overlay_test.dart`
Expected: all tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/features/home/presentation/widgets/daily_welcome_overlay_test.dart
git commit -m "test(home): add daily welcome overlay widget tests"
```

---

## Task 12: Final verification and cleanup

- [ ] **Step 1: Run full analyzer and test suite**

Run:
```bash
flutter analyze
flutter test
```
Expected: no analyze errors; existing tests pass.

- [ ] **Step 2: Manual device/emulator check**

1. Launch the app and navigate to Profile → toggle Sound off.
2. Tap around; confirm no SFX.
3. Toggle Sound on; tap; confirm SFX.
4. Kill and relaunch the app to Home; confirm welcome overlay + sound plays once.
5. Navigate away and back to Home; confirm welcome does not replay.
6. Change system date to tomorrow and relaunch; confirm welcome plays again.
7. Background the app while on an ambient screen; confirm audio pauses.

- [ ] **Step 3: Commit final polish**

```bash
git add -A
git commit -m "feat(sound): complete sound foundation and daily welcome"
```

---

## Self-Review Checklist

- [ ] Spec coverage: every requirement from the foundation/daily-welcome sections has a task.
- [ ] No placeholders: no TBD/TODO in code steps; license file has TODO only for source/author, which must be filled during asset download.
- [ ] Type consistency: `SoundService` method names match across tasks and existing callers.
- [ ] Migration: existing `SoundService.instance` callers are migrated before the singleton is removed.
