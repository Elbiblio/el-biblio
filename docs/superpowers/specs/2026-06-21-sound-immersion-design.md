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

## Screen + Action Sound Map

### Immersive screens (ambient loop + action SFX)

| Screen | Ambient | Actions |
|---|---|---|
| Home | `ambient-home` (or reuse `ambient.mp3`) | welcome sound once/day; refresh chime |
| Today | `ambient-today` | check-in success; tap on cards |
| Bible | `ambient-bible` | page/scroll rustle; verse selection chime |
| Meditation | reuse existing bell/chime/ambient | start/transition sounds; keep voice prompts |
| Tribe | `ambient/community.mp3` | interaction tap |
| Games | keep existing game sounds | add variety for win/loss/level |

### Utility screens (SFX only, no ambient)

| Screen | Actions |
|---|---|
| Journal | paper rustle on new note; save success chime |
| Commitment | success bell on check-in; creation chime |
| Assessments | completion chime; progress ticks |
| Profile/Settings | tap sounds |
| Onboarding | keep existing success bell; add subtle tap sounds |

### Global actions

- Navigation tap: `playTap()`
- Positive completion: `playSuccess()` or `playComplete()`
- Error/invalid action: `playError()`
- Major transition (modal open, sheet reveal): `playTransition()`

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

## Error Handling

- Every play method is wrapped in try/catch.
- Missing or corrupted asset → silent failure, no crash.
- Audio context setup failure → continue without audio.
- Player disposal errors are ignored.
- All ambient loops are stopped on screen dispose to prevent leakage.

## Testing & Verification

- Unit tests for `SoundService` state: enabled/disabled, ambient start/stop, fallback behavior.
- Widget test for `DailyWelcomeOverlay` animation lifecycle.
- Manual verification checklist:
  - Toggle off/on in settings silences/enables sounds.
  - Home welcome fires once per day and not on subsequent visits.
  - Ambient stops when navigating away from Bible/Meditation.
  - No audio overlaps or volume leaks.

## Phased Implementation

1. **Foundation** — refactor `SoundService`, add settings toggle, preload.
2. **Daily Welcome** — animation + sound + `lastWelcomeDate` tracking.
3. **Top Screens** — Home, Today, Bible, Meditation.
4. **Remaining Screens** — Journal, Commitment, Tribe, Games, Assessments, etc.
5. **Polish & Verify** — asset license doc, regression checks, volume balance.

## Open Questions

None at this time. All decisions made in the brainstorming session:
- Source: CC0/Pixabay/Freesound.
- Settings: sound toggle + sensible preset volumes.
- Approach: phased by screen priority.
