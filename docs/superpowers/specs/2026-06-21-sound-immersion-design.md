# Sound Immersion & Daily Welcome Design

Date: 2026-06-21
Status: Draft — awaiting implementation plan

## Summary

Make the app feel alive with sound. Every major screen and meaningful action should carry a subtle, fitting audio cue. The home screen greets the user once per day with a ray-of-light animation and a shiny welcome sound. Users can disable sounds from settings.

## Goals

- Sound is consistently present but never annoying or intrusive.
- Audio respects platform audio focus and does not leak between screens.
- Users can toggle sound on/off; default is on.
- The daily welcome moment is delightful and only fires once per day.
- All assets are royalty-free/CC0 and documented.

## Non-Goals

- No background music that persists across the entire app.
- No voiceover beyond existing TTS/prompt assets.
- No haptic changes in this scope.
- No custom notification sounds in this scope; keep existing Android/iOS notification assets.

## Context

- The app already has a `SoundService` using `audioplayers`.
- Existing assets live in `assets/audio/` and include ambient loops, SFX, countdown numbers, and voice prompts.
- `AppSettings` persists user state and already tracks dates like `lastCheckIn`.
- Most screens currently do not play any sound.

## Architecture

### Sound Service

- Convert `SoundService` from a singleton to a Riverpod-backed provider so it can react to settings changes.
- Keep two `AudioPlayer` instances:
  - `_ambientPlayer` for looping ambient tracks.
  - `_sfxPlayer` for one-shot sound effects.
- Add semantic play methods:
  - `playTap()`, `playSuccess()`, `playComplete()`, `playError()`, `playTransition()`
  - `playWelcomeShiny()`
  - `playAmbientFor(ScreenCategory)` / `stopAmbient()`
- Add per-category volume presets:
  - tap: 0.18
  - success/complete: 0.5
  - error: 0.35
  - transition: 0.25
  - ambient: 0.10
  - welcome: 0.7
- All play methods silently catch errors and fall back to `SystemSound.click` or no-op.
- Add `preloadCritical()` to warm the SFX players on app startup.

### Settings Integration

- Add `soundEnabled` to `AppSettings`, default `true`.
- Add a toggle switch in the Profile/Settings screen.
- `SoundService` reads `soundEnabled` from the provider; when disabled, all play calls are no-ops.

### Screen Lifecycle

- Screens that start ambient loops stop them in `dispose()` or when the route changes.
- Use a small helper widget or mixin to attach ambient start/stop to `initState`/`dispose` for immersive screens.

### Platform & Lifecycle Considerations

- **App backgrounding**: ambient loops must pause when the app is backgrounded and resume when foregrounded. Use `WidgetsBindingObserver` or a central lifecycle listener in `SoundService`.
- **Silent mode / hardware mute**: SFX should respect the device mute switch on iOS. Use `AVAudioSessionCategory.ambient` for UI sounds and `playback` only for immersive loops. If the package makes this hard, add a runtime check and skip SFX when the ringer is silent.
- **Do Not Disturb**: the app already has a `do_not_disturb` package. `SoundService` should not play ambient or SFX when DND is active unless the sound is explicitly user-initiated (e.g., a tap).
- **Audio focus / ducking**: when TTS, meditation voice prompts, or phone calls are active, ambient loops should duck or pause. `audioplayers` audio-context setup should use `AndroidAudioFocus.gain` for loops and `gainTransientMayDuck` for SFX.
- **Route transitions**: ambient must stop when the user navigates away, not only when the widget disposes. Hook into `GoRouter` route changes or use a `RouteObserver` to stop ambience on navigation.
- **App size**: keep SFX under 1 second and ambient loops 15–30 seconds at low bitrate (128 kbps MP3). Reuse loops across related screens.

## Daily Welcome Moment

- Persist `lastWelcomeDate` in `AppSettings` as a date-only value.
- In `HomeScreen.initState`, after the first frame, check:
  - onboarding completed
  - `today != lastWelcomeDate`
- If true, trigger:
  1. Full-screen `DailyWelcomeOverlay` with rotating radial rays and sparkle particles (1.5–2 seconds).
  2. `playWelcomeShiny()`.
  3. Update `lastWelcomeDate` to today.
- The overlay auto-dismisses and does not block interaction.
- Animation details:
  - A full-screen `Stack` with an `AnimatedBuilder` rotating a radial gradient from the top-center.
  - Two or three overlapping ray gradients with low opacity (0.08–0.18) rotating slowly.
  - Sparkle particles use small `AnimatedOpacity` + `ScaleTransition` widgets scattered across the top half.
  - Total duration: ~1.8s, then fade out over 0.4s.
  - Colors derived from the current theme accent / page gradient so it fits light/dark modes.
- The welcome sound starts at the same time as the animation; if sound is disabled, the animation still plays silently.
- The overlay must not appear while a dialog, bottom sheet, or loading spinner is active. Use a small guard in `HomeScreen` that checks `ModalRoute.of(context)?.isCurrent` and no active dialogs.

## Screen + Action Sound Map

### Devotional / immersive screens (ambient + SFX)

| Screen | Ambient | Actions |
|---|---|---|
| Home | `ambient-home` | welcome once/day; refresh chime; tap on cards |
| Today | `ambient-today` | check-in success; card tap; completion flourish |
| Bible / BibleReader / BibleLibrary | `ambient-bible` | page/scroll rustle; verse selection chime; reading start |
| Meditation / MeditationHome / SoulCareReset | `bell-meditation` / soft ambient | session start; step transition; keep existing voice prompts |
| CommitmentActive / CommitmentJourney / CommitmentCompletion | reflective ambient | success bell on check-in; completion flourish; creation chime |
| Vision: Grow / Reflect | calm ambient | selection chime; save/complete flourish |

### Community / social screens (ambient + SFX)

| Screen | Ambient | Actions |
|---|---|---|
| Vision: Tribe | `ambient/community` | interaction tap; send/react chime |
| Connect | `ambient/community` | tap; refresh chime |
| HangoutRoom | `ambient/community` | join/leave chime; message tap |
| CompanionChat | `ambient/community` | send tap; response chime |
| MissionHub / ServiceOpportunities / ImpactHistory | `ambient/community` | tap; action-complete chime |

### Utility / task screens (SFX only, no ambient)

| Screen | Actions |
|---|---|
| Journal / NoteEditor / NoteReader | paper rustle on new note; save success; delete error |
| Profile / About / ReminderSettings | tap on rows; toggle success |
| Assessment / FearFirstAssessment / WeeklyAssessment / AssessmentResults | progress tick; completion chime; result flourish |
| TimeDiagnose (Start / Configure / Analysis) | tap; completion chime |
| AppLock (Dashboard / Setup / LimitReached) | tap; warning/error on limit reached |
| FaithQuestions (Hub / FAQ / Quiz / Results) | quiz answer tap; correct/wrong; results success |
| Onboarding | keep existing success bell; add subtle tap on buttons |
| CommitmentWizard | step transition whoosh; final creation chime |
| OverlayNotification | existing notification sound on trigger; open tap |
| Speak / CompanionCall | call start/stop chime; tap |
| GamesHub / JourneyMap / JourneyQuiz / JourneyComplete / JourneyEvent / PostGameReading / VerseGame | keep existing game sounds; add ambient under maps; win/loss variety |

### Global actions

- Navigation tap: `playTap()`
- Positive completion: `playSuccess()` or `playComplete()`
- Error/invalid action: `playError()`
- Major transition (modal open, sheet reveal): `playTransition()`
- Pull-to-refresh: subtle `playTap()` or `playTransition()`

## New Assets Needed

Downloaded as royalty-free/CC0 from Pixabay/Freesound. Documented in `assets/audio/LICENSE-SOUNDS.md`.

- `assets/audio/welcome-shiny.mp3` — bright magical chime
- `assets/audio/ui-tap.mp3` — short click
- `assets/audio/ui-success.mp3` — positive ding
- `assets/audio/ui-complete.mp3` — completion flourish
- `assets/audio/ui-error.mp3` — soft error bump
- `assets/audio/transition-whoosh.mp3` — quick whoosh
- `assets/audio/page-turn.mp3` — paper page turn
- `assets/audio/paper-rustle.mp3` — paper movement
- `assets/audio/ambient/ambient-home.mp3` — soft home background
- `assets/audio/ambient/ambient-today.mp3` — calm today background
- `assets/audio/ambient/ambient-bible.mp3` — contemplative reading background

Reuse existing assets where they already fit:
- `bell-meditation.mp3`, `chime-gentle.mp3`, `success_bell.mp3`, `level-up.mp3`, `correct.mp3`, `wrong.mp3`, `ambient.mp3`, `ambient/community.mp3`.

Update `pubspec.yaml` to include any new asset directories.

### Asset Strategy & Fallbacks

- Download only MP3 files (best Flutter asset support, smallest size).
- Target lengths: SFX 0.3–1.0s, ambient loops 15–30s.
- If a specific asset cannot be sourced cleanly, fall back to an existing asset:
  - `ui-tap` → reuse `ding.wav` if needed.
  - `ui-success` → reuse `chime-gentle.mp3` or `success_bell.mp3`.
  - `ui-complete` → reuse `level-up.mp3`.
  - `ui-error` → reuse `wrong.mp3`.
  - `ambient-*` → reuse `ambient.mp3` or existing ambient subfolder.
- Every screen mapping must specify a fallback asset so the feature ships even if a download fails.
- Keep a `assets/audio/LICENSE-SOUNDS.md` with source URL, author, and license for each downloaded file.

## Accessibility & Reduced Motion

- Sound toggle is independent from motion settings.
- The welcome animation should respect the system `MediaQuery.disableAnimations` or a `AnimationScale` check; when reduced motion is enabled, skip the ray rotation and show a shorter fade with the sound still playing (or honor the sound toggle).
- All sound feedback should be paired with visible UI change so users who disable sound still get confirmation.

## Migration & Storage

- Adding `soundEnabled` to `AppSettings` requires a defaults migration; set it to `true` for existing users so the feature is opt-out, not opt-in.
- `lastWelcomeDate` is stored as a UTC date-only string (`yyyy-MM-dd`) to avoid timezone edge cases.
- Existing `SoundService` singleton callers must be migrated to the new provider-based API. Keep the singleton deprecated during the refactor, then remove after Phase 1.

## Error Handling

- Every play method is wrapped in try/catch.
- Missing or corrupted asset → silent failure, no crash.
- Audio context setup failure → continue without audio.
- Player disposal errors are ignored.
- All ambient loops are stopped on screen dispose to prevent leakage.

## Testing & Verification

- Unit tests for `SoundService` state: enabled/disabled, ambient start/stop, fallback behavior, DND/silent skip.
- Widget test for `DailyWelcomeOverlay` animation lifecycle and date gate.
- `flutter analyze` and `flutter test` must pass after each phase.
- Manual verification checklist (on device or emulator with audio):
  - Toggle off/on in settings silences/enables sounds.
  - Home welcome fires once per day and not on subsequent visits.
  - Welcome does not block bottom nav, dialogs, or loading states.
  - Ambient stops when navigating away from Bible/Meditation.
  - Ambient pauses when app is backgrounded and resumes when foregrounded.
  - No audio overlaps or volume leaks between screens.
  - Mute switch on iOS silences SFX.
  - SFX do not play when DND is active.

## Phased Implementation

1. **Foundation**
   - Refactor `SoundService` to a Riverpod provider with ambient + SFX players.
   - Add `soundEnabled` to `AppSettings` (default `true`) and a settings toggle.
   - Implement lifecycle handling (background/foreground, DND, audio focus).
   - Add `preloadCritical()` and `stopAmbient()`.
   - Migrate existing `SoundService.instance` callers to the provider; deprecate singleton.
   - Add unit tests.

2. **Daily Welcome**
   - Add `lastWelcomeDate` to `AppSettings` and migration defaults.
   - Build `DailyWelcomeOverlay` widget with ray + sparkle animation.
   - Add `welcome-shiny.mp3` asset and `playWelcomeShiny()`.
   - Wire into `HomeScreen` with date gate and reduced-motion support.
   - Add widget test.

3. **Top Screens (Home, Today, Bible, Meditation)**
   - Download and add `ambient-home`, `ambient-today`, `ambient-bible`, and core SFX assets.
   - Wire ambient loops and SFX into the four screens using a helper widget/mixin.
   - Ensure ambient stops on navigation.
   - Verify on emulator/device.

4. **Remaining Screens**
   - Apply the screen sound map to Journal, Commitment, Tribe, Games, Assessments, FaithQuestions, TimeDiagnose, AppLock, Social, Mission, Onboarding, Profile, Speak, Vision screens.
   - Use existing assets as fallbacks where possible.
   - Add route-aware cleanup everywhere.

5. **Polish & Verify**
   - Create `assets/audio/LICENSE-SOUNDS.md`.
   - Balance volumes across devices.
   - Run `flutter analyze`, `flutter test`, and manual device checks.
   - Remove deprecated singleton `SoundService` after all callers are migrated.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Audio leaks or overlaps between screens | Central route observer + helper widget ensures `stopAmbient()` on every navigation. |
| App size grows too large | Short MP3s, reuse loops, compress at 128 kbps. |
| iOS mute switch ignored | Use `ambient` category for SFX or add runtime silent-mode detection. |
| Sounds become annoying | Default volumes are low; user can toggle off; ambient only on immersive screens. |
| Downloads fail or licenses are unclear | Every asset has a documented fallback and a `LICENSE-SOUNDS.md` entry. |
| Welcome animation blocks UI | Overlay is non-blocking; guard against dialogs/loading. |
| TTS/voice prompts conflict with ambient | Ambient ducks during TTS; separate players prevent SFX cutting prompts. |
| Existing singleton callers break | Migrate all callers in Phase 1; deprecate but keep until verified. |

## Open Questions

None at this time. All decisions made in the brainstorming session:
- Source: CC0/Pixabay/Freesound.
- Settings: sound toggle + sensible preset volumes.
- Approach: phased by screen priority.
