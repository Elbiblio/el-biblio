# Screen Sound Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the refactored `SoundService` into every major screen so each screen and meaningful action has a fitting sound, without audio leaks or overlaps.

**Architecture:** A reusable `AmbientScope` helper wraps immersive screens and starts/stops ambient loops on init/dispose. SFX are triggered from button `onPressed` handlers and state-change listeners. Route transitions are observed via a `RouteObserver` to stop ambient on navigation.

**Tech Stack:** Flutter, flutter_riverpod, go_router, audioplayers.

**Prerequisite:** `2026-06-21-sound-foundation-daily-welcome-plan.md` must be completed and merged.

---

## File Structure

- **Create:**
  - `lib/shared/widgets/ambient_scope.dart` — helper widget for ambient start/stop.
  - `lib/core/router/sound_route_observer.dart` — route observer to stop ambient on navigation.
- **Modify:**
  - `lib/core/router/app_router.dart` — register `SoundRouteObserver`.
  - `lib/shared/widgets/app_shell.dart` — if needed, stop ambient on bottom-nav switches.
  - All `*_screen.dart` files per the screen sound map.
  - `assets/audio/LICENSE-SOUNDS.md` — fill in real source URLs/authors.
- **Tests:**
  - `test/shared/widgets/ambient_scope_test.dart`.

---

## Task 1: Create AmbientScope helper

**Files:**
- Create: `lib/shared/widgets/ambient_scope.dart`

- [ ] **Step 1: Implement the helper widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/app_providers.dart';
import '../../core/services/sound_service.dart';

/// Starts an ambient loop when inserted and stops it on dispose or when the
/// route is no longer current.
class AmbientScope extends ConsumerStatefulWidget {
  const AmbientScope({
    super.key,
    required this.asset,
    required this.child,
    this.volume = 0.10,
  });

  final String asset;
  final Widget child;
  final double volume;

  @override
  ConsumerState<AmbientScope> createState() => _AmbientScopeState();
}

class _AmbientScopeState extends ConsumerState<AmbientScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAmbient();
    });
  }

  @override
  void dispose() {
    _stopAmbient();
    super.dispose();
  }

  void _startAmbient() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;
    ref.read(soundServiceProvider).playAmbient(widget.asset, volume: widget.volume);
  }

  void _stopAmbient() {
    ref.read(soundServiceProvider).stopAmbient();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/shared/widgets/ambient_scope.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/ambient_scope.dart
git commit -m "feat(sound): add AmbientScope helper for screen ambient loops"
```

---

## Task 2: Create SoundRouteObserver

**Files:**
- Create: `lib/core/router/sound_route_observer.dart`

- [ ] **Step 1: Implement the observer**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/app_providers.dart';

/// Stops ambient audio when the current route is popped or replaced.
class SoundRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  SoundRouteObserver(this._ref);

  final ProviderContainer _ref;

  @override
  void didPop(Route route, Route? previousRoute) {
    _ref.read(soundServiceProvider).stopAmbient();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _ref.read(soundServiceProvider).stopAmbient();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
```

- [ ] **Step 2: Register observer in app_router.dart**

Find the `GoRouter` creation and add the observer. Since `GoRouter` accepts `observers`, add:

```dart
import 'sound_route_observer.dart';

final soundRouteObserverProvider = Provider<SoundRouteObserver>((ref) {
  // ProviderContainer access is not available here; instead, pass ref through
  // a ProviderScope-aware observer. For GoRouter, use a custom observer that
  // reads the container from the BuildContext via ProviderScope.containerOf.
  return SoundRouteObserver(ref as ProviderContainer);
});
```

> **Implementation note:** In practice, the `SoundRouteObserver` will be instantiated with a `ProviderContainer` obtained from the app root's `ProviderScope.containerOf(context)`. Update the plan during execution if the exact wiring differs.

- [ ] **Step 3: Verify analyzer**

Run: `flutter analyze lib/core/router/sound_route_observer.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/sound_route_observer.dart lib/core/router/app_router.dart
git commit -m "feat(sound): add route observer to stop ambient on navigation"
```

---

## Task 3: Wire sounds into Home, Today, Bible, and Meditation

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart`
- Modify: `lib/features/today/presentation/today_screen.dart`
- Modify: `lib/features/bible/presentation/bible_screen.dart` and `bible_library_screen.dart` and `bible_reader_screen.dart`
- Modify: `lib/features/meditation/presentation/screens/meditation_home_screen.dart` and `meditation_screen.dart`

- [ ] **Step 1: Home screen**

Wrap the `Scaffold` body in `AmbientScope` with `SoundService.ambientHomeAsset`. Add `playTap()` to the notification button and any primary action buttons. The refresh indicator already triggers a rebuild; add `playTransition()` to its `onRefresh` callback.

```dart
return AmbientScope(
  asset: SoundService.ambientHomeAsset,
  child: Scaffold(...),
);
```

- [ ] **Step 2: Today screen**

Wrap in `AmbientScope` with `SoundService.ambientTodayAsset`. Add `playTap()` to card taps and `playSuccess()` when a check-in completes. Find the check-in completion point (likely in `commitmentNotifier` or a dialog) and call `ref.read(soundServiceProvider).playSuccess()` there.

- [ ] **Step 3: Bible screens**

Wrap Bible reader/library in `AmbientScope` with `SoundService.ambientBibleAsset`. Add `playPageTurn()` on scroll/chapter change. Add `playTap()` on verse selection and `playChimeGentle()` when a verse is bookmarked or highlighted.

- [ ] **Step 4: Meditation screens**

Keep existing bell/ambient usage. Wrap in `AmbientScope` with `SoundService.bellMeditationAsset` (short loop) or continue existing ambient. Add `playTransition()` on meditation start and `playSuccessBell()` on session complete.

- [ ] **Step 5: Verify analyzer**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(sound): wire ambient and sfx into home, today, bible, meditation"
```

---

## Task 4: Wire sounds into Journal, Commitment, and Tribe

**Files:**
- Modify: `lib/features/journal/presentation/journal_screen.dart`, `note_editor_screen.dart`, `note_reader_screen.dart`
- Modify: `lib/features/commitments/presentation/screens/commitment_active_screen.dart`, `commitment_completion_screen.dart`, `journey_selection_screen.dart`
- Modify: `lib/features/vision/presentation/screens/tribe_screen.dart`
- Modify: `lib/features/connect/presentation/screens/connect_screen.dart`

- [ ] **Step 1: Journal**

No ambient. Add `playPaperRustle()` when opening the editor. Add `playSuccess()` when a note is saved. Add `playError()` on save failure or delete confirm.

- [ ] **Step 2: Commitment screens**

Wrap active/commitment screens in `AmbientScope` with a reflective ambient fallback (e.g., `SoundService.ambientHomeAsset`). Add `playSuccessBell()` on check-in completion. Add `playChimeGentle()` on commitment creation.

- [ ] **Step 3: Tribe and Connect**

Wrap in `AmbientScope` with `SoundService.ambientCommunityAsset`. Add `playTap()` to message send, reaction, and friend-tap actions. Add `playTransition()` when opening a room or chat.

- [ ] **Step 4: Verify analyzer**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(sound): wire sounds into journal, commitment, tribe, connect"
```

---

## Task 5: Wire sounds into Assessments, Games, FaithQuestions, and Utilities

**Files:**
- Modify: `lib/features/assessment/presentation/weekly_assessment_screen.dart` and related assessment screens
- Modify: `lib/features/games/presentation/screens/*.dart`
- Modify: `lib/features/faith_questions/presentation/screens/*.dart`
- Modify: `lib/features/time_diagnose/presentation/screens/*.dart`
- Modify: `lib/features/app_lock/presentation/screens/*.dart`
- Modify: `lib/features/profile/presentation/profile_screen.dart`, `about_screen.dart`, `reminder_settings_screen.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart` and onboarding views
- Modify: `lib/features/spiritual_aid/presentation/screens/*.dart`
- Modify: `lib/features/mission/presentation/*.dart` and screens
- Modify: `lib/features/social/presentation/*.dart`
- Modify: `lib/features/speak/presentation/screens/*.dart`
- Modify: `lib/features/companion/presentation/screens/*.dart`
- Modify: `lib/features/churches/presentation/screens/church_finder_screen.dart`

- [ ] **Step 1: Assessment screens**

Add `playTap()` on answer selection. Add `playCorrect()` / `playWrong()` where appropriate. Add `playLevelUp()` or `playComplete()` when an assessment finishes and results are shown.

- [ ] **Step 2: Games**

Keep existing game sounds. Add `playTap()` to menu buttons and `playTransition()` between screens. Wrap `JourneyMapScreen` in `AmbientScope` with `SoundService.ambientHomeAsset`.

- [ ] **Step 3: FaithQuestions**

Add `playTap()` on quiz answer selection, `playCorrect()`/`playWrong()` on reveal, and `playComplete()` on results.

- [ ] **Step 4: TimeDiagnose, AppLock, Profile, Onboarding**

Add `playTap()` to all major buttons/toggles. Add `playError()` on AppLock limit reached. Add `playTransition()` on onboarding step advance. Keep onboarding completion sound via `CelebrationService`.

- [ ] **Step 5: SpiritualAid, Mission, Social, Speak, Companion, Churches**

Add `playTap()` to major actions. Add `playTransition()` for modal/sheet opens. Add `playSuccess()` for positive completions (e.g., prayer sent, opportunity saved, invite accepted).

- [ ] **Step 6: Verify analyzer**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(sound): wire sounds into remaining screens and actions"
```

---

## Task 6: Add global tap SFX to common buttons

**Files:**
- Modify: shared button widgets if they exist (search `lib/shared/widgets/` for buttons)

- [ ] **Step 1: Find primary button widgets**

Search for `PrimaryButton`, `SecondaryButton`, or similar shared button classes. If they exist, add an optional `sound` parameter that defaults to `SoundType.tap`.

```dart
enum SoundType { none, tap, success, error }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.sound = SoundType.tap,
  });

  final VoidCallback? onPressed;
  final String label;
  final SoundType sound;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ElevatedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  _playSound(ref);
                  onPressed!();
                },
          child: Text(label),
        );
      },
    );
  }

  void _playSound(WidgetRef ref) {
    final soundService = ref.read(soundServiceProvider);
    switch (sound) {
      case SoundType.none:
        break;
      case SoundType.tap:
        soundService.playTap();
      case SoundType.success:
        soundService.playSuccess();
      case SoundType.error:
        soundService.playError();
    }
  }
}
```

> **Note:** Only modify shared buttons if the app has a centralized button widget. If buttons are ad-hoc, update the plan to add `playTap()` calls manually where needed.

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/shared/widgets/`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(sound): add default tap sound to shared buttons"
```

---

## Task 7: Update asset license file

**Files:**
- Modify: `assets/audio/LICENSE-SOUNDS.md`

- [ ] **Step 1: Fill in real sources**

For every downloaded asset, replace `TODO` with the actual Pixabay/Freesound URL, author name, and license (CC0).

- [ ] **Step 2: Commit**

```bash
git add assets/audio/LICENSE-SOUNDS.md
git commit -m "docs: fill in sound asset licenses"
```

---

## Task 8: Remove deprecated SoundService aliases

**Files:**
- Modify: `lib/core/services/sound_service.dart`

- [ ] **Step 1: Remove migration aliases after all callers are updated**

Once every screen has been wired to use the new semantic methods (`playTap`, `playSuccess`, etc.), remove the old aliases (`playGameTap`, `playGameSuccess`, `playOnboardingSuccess`, etc.) from `SoundService`.

- [ ] **Step 2: Verify analyzer and tests**

Run: `flutter analyze && flutter test`
Expected: no errors, all tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/sound_service.dart
git commit -m "refactor(sound): remove deprecated SoundService aliases"
```

---

## Task 9: Final verification

- [ ] **Step 1: Run analyzer and tests**

```bash
flutter analyze
flutter test
```
Expected: no errors, all tests pass.

- [ ] **Step 2: Manual device/emulator checklist**

- Navigate through every major screen and confirm ambient starts/stops appropriately.
- Confirm SFX on taps, completions, and errors.
- Confirm no audio leak when switching bottom-nav tabs.
- Confirm sound toggle silences everything.
- Confirm DND/silent mode silences ambient and SFX.
- Confirm welcome animation only plays once per day.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat(sound): complete screen sound integration"
```

---

## Self-Review Checklist

- [ ] Spec coverage: every screen in the screen sound map has a task or sub-step.
- [ ] No placeholders: all TODOs in license file are resolved; no vague instructions.
- [ ] Type consistency: `SoundService` method names are consistent across all screen modifications.
- [ ] Leak prevention: every ambient start has a corresponding stop on dispose, pop, or replace.
