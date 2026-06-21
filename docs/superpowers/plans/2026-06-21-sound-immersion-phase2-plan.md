# Sound Immersion Phase 2 — Ambient Wiring, New Downloads & Screen Identity

> **Priority order:** P0 = ship-blocking | P1 = high-impact | P2 = polish
> Each task is independently executable. Run `flutter analyze` after each batch.

---

## Sound → Screen Identity Map

The design principle: **every major screen has a unique sound signature** that users
learn to associate. Repeat exposure builds Pavlovian comfort with the app.

| Screen cluster | Ambient loop | Entry SFX | Key action SFX |
|---|---|---|---|
| Home | `ambient-home` (garden) | `welcome-shiny` (daily) | — |
| Today / Check-in | `ambient-today` (dawn) | — | `correct` on check-in |
| Bible reader | `ambient-bible` (forest) | `page-turn` on open | `paper-rustle` on swipe |
| Meditation | `bell-meditation` | `bell-meditation` on session start | `chime-gentle` on complete |
| **Commitment Active** | **`mountain`** (focus, resolve) | — | `chime-gentle` on check-in |
| **Commitment Completion** | *(none — transient)* | **`success-bell` burst** | `level-up` |
| **Commitment Journey** | `ambient-home` | — | `level-up` on milestone |
| **Assessment / Archetype** | **`field`** (open, reflective) | — | `transition` on each step |
| **Assessment Results** | *(none — transient)* | **`success-bell`** on mount | — |
| **Prayer screens** | **`stars`** (night, reverent) | `chime-gentle` on open | `chime-gentle` on Amen |
| **Confession / Recalibration** | **`dawn`** (repentance, morning) | — | `chime-gentle` on submit |
| **Companion chat** | **`community`** | — | `tap` on send |
| **Companion selection** | `community` | — | `tap` |
| **Faith Questions Hub** | **`forest`** (still, seeking) | — | `tap` on card |
| **Faith FAQ** | `forest` | — | — |
| Games Hub | `ambient-home` | — | `tap` |
| Journey Map | `ambient-home` | — | `level-up` on event |
| Journey Completion | *(none)* | `level-up` burst | — |
| Connect / Tribe | `community` | — | `tap` |
| Journal | `field` | `paper-rustle` on open | `success` on save |
| Reading Plan | `ambient-bible` | `page-turn` | `page-turn` on advance |
| Soul Care Reset | `bell-meditation` | `bell-meditation` | `chime-gentle` on complete |

---

## New Assets to Download (P0 — stubs need replacing)

All current SFX are stubs. These are the **minimum** real downloads needed for
the critical screens to feel distinct. Source from **Pixabay** or **Freesound** (CC0).

### Tier 1 — Critical (commitment + prayer + home feel)

| Needed for | Suggested search term | Maps to asset |
|---|---|---|
| Home daily welcome | "magic sparkle chime" | `welcome-shiny.mp3` |
| Commitment active ambient | "mountain wind peaceful" | `ambient/mountain.mp3` |
| Prayer / confession ambient | "night sky stars ambience" | `ambient/stars.mp3` |
| Recalibration / confession | "gentle morning birds dawn" | `ambient/dawn.mp3` |
| Soft UI tap | "soft click button UI" | `ui-tap.mp3` |
| Success / completion bell | "tibetan bowl bell" | `success_bell.mp3` |
| Transition whoosh | "page swipe whoosh light" | `transition-whoosh.mp3` |
| Chime gentle | "wind chime single note" | `chime-gentle.mp3` |

### Tier 2 — High-impact polish

| Needed for | Suggested search term | Maps to asset |
|---|---|---|
| Assessment ambient | "open field wind birdsong" | `ambient/field.mp3` |
| Bible / reflection ambient | "forest stream birdsong loop" | `ambient/forest.mp3` |
| Paper rustle | "paper book page rustle" | `paper-rustle.mp3` |
| Page turn | "single page book turn" | `page-turn.mp3` |
| Level up | "achievement fanfare short" | `level-up.mp3` |
| Correct | "soft ding correct answer" | `correct.mp3` |
| Wrong / error | "soft buzz wrong answer" | `wrong.mp3` |

> After downloading: update `assets/audio/LICENSE-SOUNDS.md` with source URL,
> author, and license. Replace the stub comment for each file.

---

## Task 1 — [P0] Commitment Active Screen ambient (mountain loop)

**File:** `lib/features/commitments/presentation/screens/commitment_active_screen.dart`

The user is in a focused, resolve-driven state. Mountain wind is serene but
purposeful — reinforcing discipline.

### Step 1: Add new `ambientCommitmentAsset` constant to SoundService

```dart
static const String ambientCommitmentAsset = 'audio/ambient/mountain.mp3';
```

### Step 2: Add imports + wrap build return with AmbientScope

```dart
import '../../../../core/services/sound_service.dart';
import '../../../../shared/widgets/ambient_scope.dart';
```

In `build()`, wrap the outermost `Scaffold` with:
```dart
return AmbientScope(
  asset: SoundService.ambientCommitmentAsset,
  volume: 0.07,
  child: Scaffold(...)
);
```

### Step 3: Play `chime-gentle` when user completes a check-in action

Find the check-in `onPressed` callback and add:
```dart
ref.read(soundServiceProvider).playChimeGentle();
```

### Step 4: `flutter analyze && flutter test`

---

## Task 2 — [P0] Commitment Completion Screen (celebration burst)

**File:** `lib/features/commitments/presentation/screens/commitment_completion_screen.dart`

Already has `ConsumerStatefulWidget` + animation controllers. Add sound in `initState`.

### Step 1: Add postFrameCallback in `initState` (after animation forward calls)

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ref.read(soundServiceProvider).playSuccessBell();
  Future.delayed(const Duration(milliseconds: 800), () {
    if (!mounted) return;
    ref.read(soundServiceProvider).playLevelUp();
  });
});
```

The double burst (bell → level-up 800 ms later) mirrors the two-phase animation
(`_celebrateController` + `_contentController`).

### Step 2: `flutter analyze`

---

## Task 3 — [P0] Prayer screens ambient (stars loop)

**Files:**
- `lib/features/spiritual_aid/presentation/screens/quick_prayer_screen.dart` (already has chime on Amen)
- `lib/features/spiritual_aid/presentation/screens/speak_to_me_screen.dart`
- `lib/features/spiritual_aid/presentation/screens/faith_discuss_screen.dart`

### Step 1: Add `ambientPrayerAsset` constant

```dart
static const String ambientPrayerAsset = 'audio/ambient/stars.mp3';
```

### Step 2: Add AmbientScope to each prayer screen

`quick_prayer_screen.dart` — wrap Scaffold with:
```dart
AmbientScope(
  asset: SoundService.ambientPrayerAsset,
  volume: 0.07,
  child: Scaffold(...)
)
```

Repeat for `speak_to_me_screen.dart` and `faith_discuss_screen.dart`.

### Step 3: `flutter analyze`

---

## Task 4 — [P0] Daily Welcome Overlay — sound + animation tightly coupled

**File:** `lib/features/home/presentation/screens/home_screen.dart`

`playWelcomeShiny()` is already called in `_maybeShowWelcome()` but fires
**before** `setState(() => _showWelcome = true)`. The sound should fire
**in sync with the animation start**, not before it.

### Step 1: Fix ordering in `_maybeShowWelcome`

Current (wrong order):
```dart
setState(() => _showWelcome = true);
await ref.read(soundServiceProvider).playWelcomeShiny();
await ref.read(settingsProvider.notifier).markWelcomeShownForToday();
```

Correct — sound fires exactly when overlay becomes visible:
```dart
setState(() => _showWelcome = true);
// Sound fires on the same frame the overlay animates in
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ref.read(soundServiceProvider).playWelcomeShiny();
});
await ref.read(settingsProvider.notifier).markWelcomeShownForToday();
```

### Step 2: Enhance `DailyWelcomeOverlay` — add sparkle particle burst at peak

**File:** `lib/features/home/presentation/widgets/daily_welcome_overlay.dart`

The overlay currently uses gradient radial sweeps + star icons. Enhance the
visual to match the shiny sound by adding a second sparkle burst at the 50%
animation mark (when sound would be at its peak).

Add a second animation interval for larger sparkles:
```dart
_burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
  ),
);
```

And in `_buildSparkles`, add 4 larger burst sparkles with `Icons.auto_awesome`
at screen centre that scale up and fade between 0.3–0.7:
```dart
Positioned(
  top: size.height * 0.3,
  left: size.width * 0.5 - 24,
  child: AnimatedBuilder(
    animation: _burstAnimation,
    builder: (_, __) => Opacity(
      opacity: _burstAnimation.value * (1 - _burstAnimation.value) * 4,
      child: Transform.scale(
        scale: 0.5 + _burstAnimation.value,
        child: Icon(Icons.auto_awesome, size: 48,
          color: colors.primary.withValues(alpha: 0.9)),
      ),
    ),
  ),
),
```

### Step 3: `flutter analyze`

---

## Task 5 — [P1] Assessment screens (field ambient + step sounds)

**Files:**
- `lib/features/assessment/presentation/assessment_screen.dart`
- `lib/features/assessment/presentation/assessment_results_screen.dart`
- `lib/features/assessment/presentation/assessment_rating_screen.dart`
- `lib/features/assessment/presentation/fear_first_assessment_screen.dart`

### Step 1: Add `ambientAssessmentAsset` constant

```dart
static const String ambientAssessmentAsset = 'audio/ambient/field.mp3';
```

### Step 2: Wrap each screen's Scaffold with AmbientScope

```dart
AmbientScope(
  asset: SoundService.ambientAssessmentAsset,
  volume: 0.06,
  child: Scaffold(...)
)
```

### Step 3: `assessment_screen.dart` — play `playTransition()` on each step advance

Find the "Next" / "Continue" button `onPressed` and add:
```dart
ref.read(soundServiceProvider).playTransition();
```

### Step 4: `assessment_results_screen.dart` — play `playSuccessBell()` on mount

In `initState`, add postFrameCallback:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  ref.read(soundServiceProvider).playSuccessBell();
});
```

### Step 5: `flutter analyze`

---

## Task 6 — [P1] Faith Questions Hub + FAQ (forest ambient)

**Files:**
- `lib/features/faith_questions/presentation/screens/faith_questions_hub_screen.dart`
- `lib/features/faith_questions/presentation/screens/faith_faq_screen.dart`

### Step 1: Add `ambientReflectionAsset` constant (reuse `ambientBibleAsset` or add new)

`forest.mp3` already exists. Add:
```dart
static const String ambientReflectionAsset = 'audio/ambient/forest.mp3';
```

### Step 2: Wrap Scaffold in both screens

```dart
AmbientScope(
  asset: SoundService.ambientReflectionAsset,
  volume: 0.06,
  child: Scaffold(...)
)
```

### Step 3: Hub screen — add `playTap()` to question card taps

### Step 4: `flutter analyze`

---

## Task 7 — [P1] Companion Selection Screen

**File:** `lib/features/companion/presentation/screens/companion_selection_screen.dart`

### Step 1: Wrap Scaffold with community ambient

```dart
AmbientScope(
  asset: SoundService.ambientCommunityAsset,
  volume: 0.06,
  child: Scaffold(...)
)
```

### Step 2: Add `playTap()` on character selection card tap

### Step 3: `flutter analyze`

---

## Task 8 — [P1] Bible Library + Reading Plan screens

**Files:**
- `lib/features/bible/presentation/bible_library_screen.dart`
- `lib/features/bible/presentation/reading_plan_detail_screen.dart`

### Step 1: Wrap both with `ambientBibleAsset`

### Step 2: `bible_library_screen.dart` — `playPageTurn()` on book/plan tap

### Step 3: `reading_plan_detail_screen.dart` — `playPageTurn()` on chapter advance

### Step 4: `flutter analyze`

---

## Task 9 — [P1] Journey Completion Screen (games)

**File:** `lib/features/games/presentation/screens/journey_complete_screen.dart`

### Step 1: Play `playLevelUp()` on mount via postFrameCallback in initState

---

## Task 10 — [P2] Alignment Hub + Habit Tracker

**Files:**
- `lib/features/alignment/presentation/screens/alignment_hub_screen.dart`
- `lib/features/alignment/presentation/screens/habit_tracker_screen.dart`

Both benefit from `field.mp3` (open, purposeful growth).

### Step 1: Wrap both with `ambientAssessmentAsset` (field.mp3)

### Step 2: `habit_tracker_screen.dart` — play `playChimeGentle()` on habit check-in

---

## Task 11 — [P2] Soul Care Reset Screen

**File:** `lib/features/meditation/presentation/screens/soul_care_reset_screen.dart`

### Step 1: Wrap with `bellMeditationAsset` ambient

### Step 2: Play `playChimeGentle()` on session complete action

---

## Task 12 — [P0] Update LICENSE-SOUNDS.md after downloads

After downloading Tier 1 assets, replace all `TODO` entries with:
- Full Pixabay/Freesound URL
- Author username
- License: CC0 1.0

---

## Execution Order

```
Download Tier 1 assets → Tasks 1, 2, 3, 4 (P0, critical feel)
→ flutter analyze + flutter test
→ git commit "feat(sound): P0 commitment/prayer/home immersion"

Tasks 5, 6, 7, 8, 9 (P1, all screens wired)
→ flutter analyze + flutter test
→ git commit "feat(sound): P1 assessment/bible/games/companion immersion"

Download Tier 2 assets
→ Tasks 10, 11 (P2 polish)
→ Task 12 (update LICENSE)
→ flutter analyze + flutter test
→ git commit "feat(sound): P2 alignment/soul-care polish + license update"
```

---

## Self-review Checklist

- [ ] Every P0 screen has a unique ambient that plays on mount and stops on pop
- [ ] Home welcome sound fires on the same frame the overlay animates
- [ ] Commitment completion has a two-phase sound burst matching animations
- [ ] Prayer/confession screens share `stars` ambient (night, sacred)
- [ ] No screen plays two overlapping ambients simultaneously
- [ ] All new real assets are recorded in LICENSE-SOUNDS.md
- [ ] `flutter analyze` passes with 0 issues after every task
- [ ] `flutter test` passes all 466+ tests after final task
