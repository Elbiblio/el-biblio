# Core Spiritual Growth Loop Completion Status

Last updated: 2026-05-10

Legend: `Done` = implemented and verified, `Partial` = works but has known gaps, `Gap` = not complete.

## Product Loop

| Area | Status | Evidence | Gaps / Next Action |
| --- | --- | --- | --- |
| Exquisite onboarding first impression | Done | Opening onboarding screens were redesigned; `TheNoiseView` and `TheSolutionView` now use calmer composition and a single intentional sacred reveal. Static tests cover the duplicate light-ray regression, and rendered widget tests cover phone/tablet/desktop viewports with no layout exceptions. | Production-device screenshot QA is still useful before store submission, but no code gap remains in this pass. |
| Reduced-motion-safe animations | Done | `LightRaysReveal` respects `MediaQuery.disableAnimations`; `onboarding_visual_static_test.dart` covers this. | None known. |
| Full spiritual compass replaces mini quiz | Done | Onboarding now asks exact age in-memory, derives `age_band`, captures archetype selections, maturity calibration, primary/top archetypes, spiritual age score/stage, selected path, selected tasks, action-plan metadata, archetype profile metadata, and the growth-story result. Legacy mini-assessment state/notifier code was removed. | None known. |
| Exact age privacy | Done | Exact age is not serialized to onboarding draft/settings and is not sent to backend; `age_band` is derived for payloads. Round-trip test verifies exact age drops after persistence. | None known. |
| Compass sync after signup | Done | Signup stores a pending compass payload before clearing onboarding, clears it after successful API sync, and app startup/auth/settings changes now retry any queued payload automatically. | None known. |
| Spiritual age standardization | Done | `spiritualAgeScore` and stage labels (`Infant`, `Child`, `Young`, `Maturing`, `Mature`) are used in onboarding, account/settings context, Grow, and Tribe reassessment context. | None known. |
| Bottom nav and `/reflect` route | Done | Bottom nav is `Today`, `Commit`, `Reflect`, `Tribe`, `Grow`; `/reflect` opens `ReflectScreen`; notification deep links no longer redirect reflect to commit. | None known. |
| "Return" language replaced | Done | Core user-facing language now uses check-in language; copy test blocks high-risk legacy phrases. Backend/internal fields may still use `returned_count` for compatibility, with `checked_in_count` added. | Broader non-core legacy screens can still be audited later. |
| Commit vs Reflect vs Tribe separation | Done | Commit manages commitments/check-in; Reflect is commitment-only composer/feed/support; Tribe owns tribe hangouts and rituals. Widget tests cover the launch states. | None known. |
| Tribe hangouts launch scope | Done | UI creates tribe hangouts only; Today filters live hangouts to the primary tribe; backend visible/create endpoints are tribe-only for launch. | Compatibility code still supports old commitment-scoped hangout reads/tests where needed. |
| Grow identity/maturity surface | Done | Grow shows soil/seed/fruit maturity story and backend journey/milestones now include compass, tribe joined, commitment started, check-ins, reflections, supports, weekly ritual, and tribe hangouts. | Real UX polish pass still useful once connected to production data, but no known implementation gap remains. |
| Context persistence and recovery | Done | First check-in plan fields are stored in app settings, sent to `/commitments/{id}/join`, returned on commitment membership payloads, shown in Today/Commit, and included in nudge copy. Active commitments show a notification recovery panel when local notifications appear disabled. | OS-settings deep-link behavior can be refined per platform later. |
| Safety and contextual invites | Done | Reflection cards and hangout rooms expose report actions persisted to `vision_content_reports`; hangout rooms show room agreements. Invite routes carry tribe/hangout/commitment context and backend invitations store context fields. | Admin review workflow and public invite landing-page context remain future product work. |

## Backend

| Area | Status | Evidence | Gaps / Next Action |
| --- | --- | --- | --- |
| Full compass contract | Done | `/compass-assessments` accepts primary/top/selected archetypes, `age_band`, spiritual age score/stage, selected path/tasks, metadata, action-plan metadata, and exposes top-level accessor fields. Version column expanded for `full_spiritual_compass_v1`. | Consider first-class DB columns later; launch contract currently stores detail in metadata with accessors. |
| Tribe recommendations prefer compass | Done | Recommendation lookup reads latest completed compass archetypes before falling back to profile metadata and normalizes archetype slugs/names. | None known. |
| Legacy compass scoring uses answer index | Done | Legacy scoring weights the selected answer's virtue, so answer index affects results. | None known. |
| One active commitment | Done | Join is wrapped with locking/transaction behavior and returns 409 for a second active commitment; tests cover enforcement. | None known. |
| Commitment reflection constraints | Done | Tests cover member-scoped feed, check-in gate, one reflection per day, and support reaction counts/notifications. | None known. |
| Tribe pulse milestones | Done | Pulse payload includes `checked_in_count`, compatibility `returned_count`, weekly ritual count, and commitment milestone aggregates; tests assert milestone payload. | None known. |
| Hangout hardening | Done | Backend covers tribe-scope access, scheduled-room rejection, full-room handling, existing participant refresh, LiveKit absence, and leave cleanup/end. | LiveKit token payload shape is covered indirectly through successful room payloads; production LiveKit integration still deserves environment QA. |
| Route stability | Done | Compass static routes are before the resource route; latest assessment and full compass tests pass. | None known. |
| Context memory and reports | Done | New migration adds commitment plan context fields, invitation context fields, and generic vision safety reports. `VisionMvpTest` covers persisted first check-in context and member-scoped reflection reports. | Add admin moderation tooling once report-review workflow is defined. |

## Tests

| Test Area | Status | Evidence | Gaps / Next Action |
| --- | --- | --- | --- |
| Flutter onboarding state/compass | Done | Round-trip and notifier tests cover exact age privacy, derived age band, full compass payload, and spiritual age. | None known. |
| Flutter router/copy/animation | Done | Static tests cover `/reflect`, reduced motion, single light reveal, and blocked copy. Rendered onboarding viewport tests cover first-screen and solution-screen layout on phone/tablet/desktop sizes. | Golden screenshot baselines can be added later if the design system starts requiring pixel-level approval. |
| Flutter Commit/Reflect/Tribe widgets | Done | `vision_screens_test.dart` covers no active commitment, active unchecked, checked-in/no reflection, reflection posted, tribe hangout empty/live/LiveKit missing/join error states. | None known. |
| Flutter repository/model parsing | Done | Vision model tests cover tribe pulse parsing, journey icons, hangout/LiveKit absence, and malformed daily growth question payloads. | None known. |
| Backend compass/commitment/feed | Done | `VisionMvpTest` covers full compass submission, latest/recommendation behavior, one active commitment, feed constraints, reflection constraints, and reactions. | None known. |
| Backend tribe pulse/hangouts | Done | `VisionMvpTest` covers pulse aggregates/milestones, tribe-only visible hangouts, LiveKit absence, full room, scheduled room, permission rejection, and leave cleanup. | None known. |

## Verification Log

- `php -l` passed on edited backend controller/model/migration/test files.
- `php artisan test tests\Feature\API\v1\VisionMvpTest.php --stop-on-failure` passed: 20 tests, 154 assertions.
- `flutter analyze` passed.
- Focused Flutter suite passed: onboarding state/journey/copy/static visual tests, router static test, settings round-trip, vision model tests, vision screen widget tests, assessment notifier/repository tests.
- Follow-up focused Flutter copy/model/widget tests passed after the final copy cleanup.
- Added verification for pending compass sync retry, rendered onboarding viewports, full compass action-plan payload, and malformed daily growth question parsing; focused Flutter tests passed.
- Backend Vision MVP suite passed after selected path/task metadata assertions were added: 20 tests, 157 assertions.
- Follow-up context/safety pass passed: `flutter analyze`; focused Flutter storage/copy/model/widget suite; `php -l` on edited backend files; `php artisan test tests\Feature\API\v1\VisionMvpTest.php --stop-on-failure` passed with 21 tests and 163 assertions.
