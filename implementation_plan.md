# El-Biblio: Grounded Implementation Plan

## The 3-Pillar Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      EL-BIBLIO                                      │
│               Your Christian Habit Formation App                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │   1. CONNECT     │  │   2. COMMIT      │  │   3. SPEAK       │  │
│  │                  │  │                  │  │                  │  │
│  │ Who you are      │  │ What you do      │  │ Who helps you    │  │
│  │ Who you walk     │  │                  │  │                  │  │
│  │ with             │  │ Start good       │  │ Companion AI     │  │
│  │                  │  │ Stop bad         │  │ Tribe / Circle   │  │
│  │ Identity         │  │ Overlay nudges   │  │ Advisors         │  │
│  │ (archetype,      │  │ Progress gardens │  │ Prayer content   │  │
│  │  tradition)      │  │ Milestones       │  │ Encouragement    │  │
│  │                  │  │                  │  │                  │  │
│  │ Prayer family    │  │ FAIL → confess   │  │                  │  │
│  │ Tribe            │  │  to partner/     │  │                  │  │
│  │ Belonging        │  │  companion/circle│  │                  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                     │
│  Supporting Tools (accessed FROM the 3 pillars, never standalone):  │
│  Bible, Journal, Meditation, Assessment, Games, Profile/Settings    │
└─────────────────────────────────────────────────────────────────────┘
```

**Every screen, every action, every feature belongs to exactly one of these 3 pillars.** The app's navigation, onboarding, notifications, and content all funnel through this trinity.

**When a habit fails → confession mechanic triggers:**
The "stop bad habit" flow in Commit includes a built-in failure protocol. When you slip:
1. Overlay notification appears: "You missed today. That's okay. Talk to someone."
2. Options: Speak to companion | Tell your circle | Message your advisor | Pray about it
3. This is NOT sacramental confession — it's the universal Christian practice of admitting failure to a trusted person, which research proves is the #1 predictor of breaking bad habits.
4. The AI companion, accountability partner, and circle are all recipients for these "admissions."

---

## Zero-Duplication Principles
1. **Extend, don't create** — every new feature checks existing models, services, providers, widgets first
2. **One source of truth** — shared state in `AppSettings`, `VisionState`, or feature notifiers
3. **Reuse existing patterns** — Riverpod + StateNotifier + Repository architecture
4. **No dead code** — reactivate what exists before building new
5. **Denomination-neutral core** — tradition-specific content is optional packs, never baked in

---

## EXISTING CODE MAP (What We Have)

### Pillar 1: CONNECT — Existing Assets
| Asset | File | What It Provides |
|-------|------|-----------------|
| 12 Archetypes | `lib/features/assessment/domain/models/archetype.dart` | Identity system: strengths, distortions, growth areas |
| ArchetypeResonance | `lib/features/assessment/domain/models/archetype_resonance.dart` | Tribe + biblical character mapping per archetype |
| CallingProfile | `lib/features/assessment/domain/models/calling_profile.dart` | Weekly priorities, service tendencies, growth risks |
| ChristianLifeBaseline | `lib/features/companion/domain/models/christian_life_baseline.dart` | Bible cadence, prayer rhythm, church attendance |
| Compass Wheel | `lib/features/assessment/presentation/widgets/interactive_compass_wheel.dart` | Visual identity discovery |
| AssessmentScreen | `lib/features/assessment/presentation/screens/assessment_screen.dart` | 3-step archetype selection |
| FearFirstAssessment | `lib/features/assessment/presentation/fear_first_assessment_screen.dart` | Fear-cloud identity discovery |
| OnboardingState | `lib/features/onboarding/application/onboarding_state.dart` | Identity, lifestyle, baseline collection |
| WeeklyAssessment | `lib/features/assessment/presentation/weekly_assessment_screen.dart` | Ongoing identity recalibration |
| CallingProfileService | `lib/features/assessment/application/calling_profile_service.dart` | Generates profile from archetype |
| ArchetypeIdentityBadge | `lib/features/today/presentation/widgets/archetype_identity_badge.dart` | Shows archetype on Today screen |

### Pillar 2: COMMIT — Existing Assets
| Asset | File | What It Provides |
|-------|------|-----------------|
| CommitmentPlan | `lib/features/vision/domain/vision_models.dart:209` | Plan definition (title, dailyAction, durationDays) |
| CommitmentSeason | `lib/features/vision/domain/vision_models.dart:250` | Active commitment (currentDay, completedDays, progress) |
| CommitmentDailyItem | `lib/features/vision/domain/vision_models.dart:340` | Daily checklist items (1-3 per load level) |
| DailyLoad (Light/Steady/Deep) | `lib/features/vision/domain/vision_models.dart:285` | Escalating commitment intensity |
| VisionNotifier | `lib/features/vision/application/vision_notifier.dart` | joinCommitment(), checkIn(), updateNudges() |
| CommitScreen | `lib/features/vision/presentation/screens/commit_screen.dart` (2015 lines) | Full commitment management UI |
| TodayScreen | `lib/features/vision/presentation/screens/today_screen.dart` (642 lines) | Daily commitment view |
| HabitNotifier | `lib/features/alignment/application/habit_notifier.dart` | Good/bad habit tracking |
| HabitItem | `lib/features/alignment/domain/models/habit_assessment.dart` | Bad habits with counter-habits, severity |
| HabitCatalog | `lib/features/alignment/data/habit_catalog.dart` | 31 pre-built habits (19 bad, 8 good, some legacy overlap with onboarding) |
| FortyDayGoal | `lib/features/alignment/domain/models/forty_day_goal.dart` | 40-day structured goals with daily tasks |
| FortyDayTemplates | `lib/features/alignment/data/forty_day_templates.dart` | 6 pre-built 40-day templates |
| XP System | `lib/core/services/xp_service.dart` | 8 activity types, XP tracking |
| Streak Tracking | `lib/core/application/settings_notifier.dart:486` | streakCount, longestStreakCount |
| CelebrationService | `lib/core/services/celebration_service.dart` | Confetti + sound on milestones |
| NotificationService | `lib/core/services/notifications/notification_service.dart` | 11 channels, daily nudges, check-in actions |
| scheduleCommitmentNudges | `notification_service.dart:1597` | Scheduled nudge series |
| Accountability Partner | `lib/features/mission/domain/models/accountability_partner.dart` | Partner with check-in requests |
| MissionNotifier | `lib/features/mission/application/mission_notifier.dart` | enableAiAccountabilityPartner, requestCheckIn |
| GrowScreen | `lib/features/vision/presentation/screens/grow_screen.dart` | Daily growth questions |

### Pillar 3: SPEAK — Existing Assets
| Asset | File | What It Provides |
|-------|------|-----------------|
| CompanionCharacter | `lib/features/companion/domain/models/companion_character.dart` | 3 AI characters (Raziel, Naomi, James) |
| CompanionChatNotifier | `lib/features/companion/application/companion_chat_notifier.dart` | Streaming chat with mood system |
| CompanionChatScreen | `lib/features/companion/presentation/screens/companion_chat_screen.dart` | Full chat UI with orb animation |
| CompanionNudgeProvider | `lib/features/companion/application/companion_nudge_provider.dart` | Daily nudge from companion |
| CompanionOrb | `lib/features/companion/presentation/widgets/companion_orb.dart` | Animated breathing orb (6 moods) |
| CompanionHaptics | `lib/features/companion/presentation/widgets/companion_haptics.dart` | Per-character haptic signatures |
| AiPartnerInviteCard | `lib/features/companion/presentation/widgets/ai_partner_invite_card.dart` | AI as fallback accountability |
| TribeIdentity | `lib/features/vision/domain/vision_models.dart:443` | Tribe definition |
| TribeMembership | `lib/features/vision/domain/vision_models.dart:460` | Joined tribe with visibility |
| TribePulse | `lib/features/vision/domain/vision_models.dart:476` | Tribe activity feed |
| TribeScreen | `lib/features/vision/presentation/screens/tribe_screen.dart` | Full tribe management (1544 lines) |
| CommitmentReflection | `lib/features/vision/domain/vision_models.dart:386` | User reflections with reactions |
| MissionNotifier | `lib/features/mission/application/mission_notifier.dart` | Accountability partners, service opportunities |
| SpiritualAidHub | `lib/features/spiritual_aid/presentation/screens/spiritual_aid_hub_screen.dart` | Quick prayers, faith discuss, evangelism |
| QuickPrayerScreen | `lib/features/spiritual_aid/presentation/screens/quick_prayer_screen.dart` | 40+ prayers with TTS |
| SpeakToMeScreen | `lib/features/spiritual_aid/presentation/screens/speak_to_me_screen.dart` | Verse reveal with animation |
| FaithDiscussScreen | `lib/features/spiritual_aid/presentation/screens/faith_discuss_screen.dart` | Daily faith prompt |
| MeditationSessions | `lib/features/meditation/` | Guided meditation with audio |
| BibleReader | `lib/features/bible/` (56 files) | Full Bible reading experience |

---

## THE NAVIGATION REDESIGN (Pillar-Based Shell)

### Current Shell (6 destinations, flat):
```
Today | Commit | Reflect | Tribe | Grow | Profile
```

### New Shell (3 pillars + Today as dashboard):
```
Home (today dashboard) | Connect | Commit | Speak
```

**Why 4 tabs instead of 3:** Home/Today serves as the daily landing page showing what matters right now — your streak, today's commitment, recent tribe activity, latest companion message. It's the "morning coffee" screen. The 3 pillars are the depth destinations.

### Tab Definitions

| Tab | Route | Purpose | Key Screens |
|-----|-------|---------|-------------|
| **Home** | `/home` | Daily dashboard | Streak, today's commitment, recent tribe pulse, companion nudge, quick actions |
| **Connect** | `/connect` | Identity + belonging | Identity profile (archetype, tradition, calling), prayer family/tribe, assessment compass, weekly assessment |
| **Commit** | `/commit` | Habits + commitments | Active commitment with progress visual, start new commitment, bad habit wizard, good habit builder, overlay schedule |
| **Speak** | `/speak` | People + prayer | Companion chat, tribe feed, prayer content, advisor directory, encouragement |

**Supporting tools** (Bible, Journal, Meditation, Games, Profile/Settings) are accessed via context buttons WITHIN the pillars, not as separate tabs:
- Bible → accessed from Commit (daily verse) or Speak (prayer content)
- Journal → accessed from Commit (after check-in reflection) or Connect (identity journaling)
- Meditation → accessed from Speak (prayer/meditation content)
- Games → accessed from Home (engagement) or Connect (social)

### Shell Implementation

**Files to modify:**
- `lib/shared/widgets/app_shell.dart` — Change 6 destinations to 4 tabs
- `lib/core/constants/app_routes.dart` — Add `/home`, `/connect`, `/speak` routes
- `lib/core/router/app_router.dart` — Update shell route definitions

**New shell destination structure:**
```dart
// Replace existing 6 _ShellAccent entries with 4:
enum _ShellAccent { primary, connect, commit, speak }

// 4 destinations:
_Destination('Home', '/home', LucideIcons.home, _ShellAccent.primary, includeRoot: true),
_Destination('Connect', '/connect', LucideIcons.users, _ShellAccent.connect),
_Destination('Commit', '/commit', LucideIcons.flag, _ShellAccent.commit),
_Destination('Speak', '/speak', LucideIcons.messageCircle, _ShellAccent.speak),
```

---

## PHASE 1: Navigation Redesign + Core Commitments (Weeks 1-4)

### 1.1 Restructure AppShell to 4 Tabs

**Task 1.1.1: Update AppShell**
- **File:** `lib/shared/widgets/app_shell.dart`
- Reduce from 6 to 4 destinations
- Update `_ShellAccent` enum
- Remove: `Reflect`, `Grow`, `Profile` as dedicated tabs
- Keep all existing screens accessible via deep links or context menus
- Update `shellChromeBottomPadding` if layout changes

**Task 1.1.2: Create HomeScreen (New Hub)**
- **File:** `lib/features/home/presentation/screens/home_screen.dart` (new — new `home/` feature)
- **Reuses:**
  - `StreakBadge` from `lib/features/today/presentation/widgets/streak_badge.dart`
  - `CommitmentSnapshotBanner` from `lib/features/vision/presentation/widgets/commitment_daily_load_widgets.dart`
  - `CompanionBubble` from `lib/features/companion/presentation/widgets/companion_bubble.dart`
  - `TribePulse` feed widgets
  - `JourneyProgressVisual` (new, see Phase 2)
- **Layout (top to bottom):**
  1. Greeting: "Good morning, John. Day 12 of your Prayer Commitment."
  2. Streak + Grace Points summary row
  3. Today's commitment: visual timeline snippet + "Check in" button
  4. Companion nudge: "James wants to check in. [Reply]"
  5. Tribe pulse: "Sarah completed her commitment. [Send kudos]"
  6. Quick actions row: Bible, Journal, Meditation (small icons)

**Task 1.1.3: Move Legacy Route Content**
- Reflect screen → accessible from Commit (post-check-in reflection) or from Journal
- Grow screen → accessible from Connect (growth questions) or Home (daily question)
- Profile/Settings → gear icon in top bar (existing pattern)
- Bible → accessible from Home quick actions AND from Commit (if commitment is Bible reading)
- Journal → accessible from Home quick actions AND from Commit (post-check-in)
- Meditation → accessible from Speak (prayer/meditation content)
- Games → accessible from Home (engagement hook)

---

### 1.2 Commitment Overlay Notification System (Core Differentiator)

**What already exists:**
- `scheduleCommitmentNudges()` in `notification_service.dart:1597`
- `setDailyCheckInActionHandler()` in `notification_service.dart`
- `showCommitmentLockInNotification()` in `notification_service.dart:636`
- Action buttons already supported: "I did this ✓", "Journal", "View"
- Full-screen intent capability via `flutter_local_notifications`

**Task 1.2.1: Create OverlayNotificationService**
- **File:** `lib/features/commit/application/overlay_notification_service.dart` (new — in commit feature)
- **Reuses:** `NotificationService` for scheduling, `flutter_local_notifications` for full-screen intent
- **Model `OverlayNotification`:**
  - `id: int`, `commitmentId: int`
  - `scheduledTime: TimeOfDay` — agreed with user
  - `type: String` — checkIn, encouragement, milestone, struggleSupport
  - `title: String`, `body: String` — personalized
  - `imageUrl: String` — commitment category backdrop
  - `soundPath: String` — gentle chime
  - `actionButtons: List<OverlayAction>` — "I did it" / "Skip" / "Talk to companion"
  - `persistent: bool` — cannot be dismissed without action (true for check-ins)
- **Class `OverlayNotificationService`:**
  - `initialize()` — register full-screen intent activity
  - `schedule(OverlayNotification)` — schedule at agreed time
  - `cancel(int id)` — cancel specific
  - `cancelAllForCommitment(int commitmentId)` — cancel all
  - `showImmediate(OverlayNotification)` — show right now
  - `onAction(String action, Map payload)` — handle user tap

**Task 1.2.2: Create OverlayResponseActivity (Android)**
- **File:** `android/app/src/main/kotlin/.../OverlayResponseActivity.kt`
- **Purpose:** Renders the overlay when app is in background
- **Behavior:**
  - Full-screen intent registered in AndroidManifest with `showWhenLocked`, `turnScreenOn`
  - Receives notification payload
  - Renders native or calls Flutter engine to render `OverlayNotificationScreen`
  - Handles: "I did it" → trigger check-in, dismiss, show brief success
  - Handles: "Skip" → dismiss, log gentle miss
  - Handles: "Talk" → open app to companion chat

**Task 1.2.3: Create OverlayNotificationScreen (Flutter)**
- **File:** `lib/features/commit/presentation/screens/overlay_notification_screen.dart`
- **Layout (half or full screen):**
  - Top: commitment category backdrop (mountain, garden, etc.) with dark gradient
  - Center: large title + body
  - Bottom: 2-3 large action buttons
  - Corner: streak badge, companion character avatar
- **States:**
  - App foregrounded → show as dialog
  - App backgrounded → native full-screen intent renders this via FlutterFragment
  - Phone locked → wakes screen, shows overlay

**Task 1.2.4: Create User Schedule Agreement Flow**
- **Integrate into:** `lib/features/vision/presentation/screens/commit_screen.dart` (during commitment creation)
- **Flow:**
  - After selecting plan → "When should we check in on you?"
  - User sets 1-3 daily times
  - "We'll send rich notification overlays. You'll need to respond."
  - Skip days allowance: 1-3 per week
- **Model `CommitmentSchedule`:**
  - `commitmentId: int`, `checkInTimes: List<TimeOfDay>`
  - `activeDays: List<int>` (0=Sun...6=Sat)
  - `skipDaysAllowed: int`, `overlayEnabled: bool`
- **Storage:** Extend `AppSettings` with commitment schedule preferences map

---

### 1.3 Commitment Visual Backdrop System

**Task 1.3.1: Create CommitmentMediaCatalog**
- **File:** `lib/features/commit/data/commitment_media_catalog.dart` (new)
- **Model `CommitmentMedia`:**
  - `category: String`, `backgroundImage: String`, `ambientSound: String?`
  - `accentColor: Color`, `mood: String`
- **Catalog:** Map commitment categories to visual themes
  - prayer → sunrise + gentle strings
  - bible → open field + soft piano
  - discipline → mountain + steady drone
  - service → community + warm tone
  - growth → garden + light piano
  - health → forest + nature sounds
  - faith → stars + contemplative
  - relationships → sunset + ambient

**Task 1.3.2: Create CommitmentBackdrop Widget**
- **File:** `lib/shared/widgets/commitment_backdrop.dart`
- **Parameters:** `category: String, child: Widget`
- **Behavior:**
  - Full-screen background image with dark gradient overlay
  - Smooth crossfade between categories
  - Optional ambient sound (configurable, off by default)

---

## PHASE 2: Commit Pillar — Bad Habit Stopping + Confession Mechanic (Weeks 3-6)

### 2.1 Unified "Start Good / Stop Bad" Wizard

**What already exists:**
- `HabitCatalog` with 31 habits (19 bad, 8 good) at `lib/features/alignment/data/habit_catalog.dart`
- `HabitItem` with `isBadHabit`, `counterHabit`, `severity`, `relatedVirtue`, `conquestTips`
- `HabitNotifier` with `addHabit()`, `checkInHabit()`, `toggleHabit()`
- `CommitmentPlan` with `dailyAction`, `durationDays`, `nudgeMin/Max`
- `CommitScreen` (2015 lines) — existing commitment walkthrough
- `FortyDayGoal` with `dailyTasks`, `completions`
- `commitmentCtaSheet` in `commit_screen.dart` — for joining with personalization

**Task 2.1.1: Create Unified CommitmentWizard (Good + Bad + 40-Day)**
- **File:** `lib/features/commit/presentation/screens/commitment_wizard_screen.dart` (new)
- **Purpose:** Single wizard for starting ANY commitment — good habit, stop bad habit, 40-day goal
- **Flow:**
  1. **Choose Type:** Start a good habit | Stop a bad habit | Follow a 40-day plan
  2. **If Stop Bad Habit:**
     - Pick from struggle catalog (15 struggles from onboarding + any habit)
     - "What triggers this?" (situation, emotion, time, person)
     - "What's a healthier replacement?" (links to existing `counterHabit` system)
     - "Who should know about this struggle?" (accountability partner, circle, companion — connects to SPEAK pillar)
     - "If you slip, what happens?" → confession mechanic setup
  3. **If Start Good Habit:**
     - Pick from good habits catalog (14 good habits from onboarding + catalog)
     - "When and where will you do this?" (implementation intention)
     - Daily load: Light (5min), Steady (15min), Deep (30min)
  4. **If 40-Day Goal:**
     - Pick from 6 templates (Prayer Life, Scripture Study, Service, Gratitude, Forgiveness, Fasting)
     - Preview first 7 days
  5. **Common steps (all paths):**
     - Schedule overlay notifications (1-3 times/day)
     - Set accountability (who sees your progress)
     - Set companion support level
     - Choose visual theme (commitment backdrop)
     - Confirm + start

**Task 2.1.2: Build Bad Habit → Replacement Flow**
- **Extend:** `HabitAssessmentScreen` concepts into Commit
- **Flow within wizard:**
  1. Select bad habit from catalog
  2. Rate severity (1-5) and frequency (daily, multiple times daily, weekly)
  3. System suggests replacement habit from `counterHabit` field
  4. User can customize: "Instead of X, I will do Y"
  5. "Your replacement: When you feel the urge to [bad habit], pause and do [replacement] instead."
  6. This replacement becomes the `dailyAction` in the `CommitmentPlan`
- **Persistence:** Saved as `CommitmentSeason` with plan derived from bad habit data

**Task 2.1.3: Create Confession-on-Failure Protocol**
- **File:** `lib/features/commit/application/failure_protocol_service.dart` (new)
- **This is the key mechanic** — when a stop-bad-habit commitment is missed:
- **Triggered by:** `CommitmentScheduler` detecting 1+ missed days
- **Flow:**
  1. After 1st miss: Notification overlay → "That's okay. Every saint has a past."
  2. "Who would you like to tell about this struggle?"
     - **My companion (AI)** → Opens companion chat, companion knows context
     - **My accountability partner** → Sends miss notification to partner
     - **My circle** → Posts anonymous admission to circle feed
     - **Pray about it** → Opens prayer screen with confession/repentance prayer
  3. After admission: Companion/partner responds with encouragement, not judgment
  4. User is offered "Begin again" — reset grace points, continue commitment
  5. After 3 admissions on same habit without improvement:
     - Companion suggests adjusting the commitment (lower daily load, change time, etc.)
     - "This habit might need a different approach. Want to talk it through?"
- **Reuses:** `CompanionChatNotifier` for AI conversation, `AccountabilityPartner` for human partner, `Tribe/TribePulse` for circle, `SpiritualAidHub` for prayer
- **Research basis:** Traditional "confession" + accountability partner model is the #1 predictor of breaking addictions (AA model, Celebrate Recovery model, every effective recovery program)

**Task 2.1.4: Failure Admission Models**
- **File:** `lib/features/commit/domain/models/failure_admission.dart` (new)
- **Class `FailureAdmission`:**
  - `id: String`, `commitmentId: int`
  - `habitId: String`, `habitName: String`
  - `missedDay: int`, `missedDate: DateTime`
  - `admittedTo: String` — "companion", "partner", "circle", "prayer"
  - `admittedAt: DateTime`
  - `responseReceived: bool`, `responseContent: String?`
  - `commitmentAdjusted: bool`, `newLoad: int?`
  - `gracePointsRestored: int`
- **Analytics:** Track admission patterns — which habits lead to admission, which confession method most effective, does admission improve completion rate?

---

### 2.2 Commitment Visual Timeline (Progress Gardens)

**Task 2.2.1: Create JourneyProgressVisual**
- **File:** `lib/shared/widgets/journey_progress_visual.dart`
- **Parameters:** `category: String, completedDays: int, totalDays: int, currentDay: int`
- **Themed by category:**
  - prayer → path with candles lighting
  - bible → scroll unfurling
  - discipline → mountain ascent
  - service → garden blooming
  - growth → tree branching
  - health → sunrise brightening
  - faith → stars appearing in night sky
  - relationships → tapestry weaving
- **States:**
  - Normal: smooth progress animation
  - Milestone (25/50/75/100%): burst + confetti (reuse `CelebrationService`)
  - Missed day: dimmed marker (not broken — grace over shame)
  - Return after miss: relighting animation
- **Integration:** Home screen, Commit screen, overlay notifications

**Task 2.2.2: Create MilestoneCelebration**
- **Extend:** `CelebrationService` with commitment milestone types
  - `commitmentMilestone`: 4s, 100 particles, category colors
  - `commitmentComplete`: 6s, 200 particles, grand confetti
  - `streakMilestone`: 3s, 60 particles, fire/streak colors

---

## PHASE 3: Connect Pillar — Identity + Belonging (Weeks 4-7)

### 3.1 Denomination-Agnostic Identity

**Task 3.1.1: Create ChristianTraditionSelector**
- **File:** `lib/features/connect/domain/models/christian_tradition.dart` (new — new `connect/` feature)
- **Enum `ChristianTradition`:** (All equal, none privileged)
  - `catholic`, `orthodox`, `protestant_mainline` (Methodist, Lutheran, Presbyterian, Anglican)
  - `protestant_evangelical` (Baptist, Pentecostal, Nondenominational)
  - `protestant_reformed` (Reformed, Conservative Presbyterian)
  - `other`, `exploring`
- **Each tradition:**
  - `label`, `description`, `iconKey`
  - `emphasizedPractices: List<String>` — types of prayer/commitment this tradition favors
  - `commitmentSuggestions: List<String>` — which commitment plans to rank higher
  - `defaultPrayerContent: String` — Lord's Prayer (universal) + optional extra
- **No impact on:**
  - App functionality (all features work identically)
  - Community matching (user can connect across traditions)
  - Content access (all content available to everyone)
- **Only impacts:** Suggested commitment ranking, default prayer content, companion character recommendation

**Task 3.1.2: Create SpiritualIdentity Model**
- **File:** `lib/features/connect/domain/models/spiritual_identity.dart`
- **Fields:**
  - `tradition: ChristianTradition?` (optional — can be unset)
  - `archetypeIds: List<String>` (from existing 12-archetype system)
  - `spiritualAgeStage: String` (from existing: Infant→Mature)
  - `commitmentCategory: String` (growth/discipline/charity)
  - `primaryVirtue: String`
  - `prayerStyle: String` (contemplative, liturgical, spontaneous, varied)
  - `biblePreference: String` (devotional, study, lectio, varied)
  - `communityPreference: String` (solo, small group, large group, varied)
- **Storage:** New field in `AppSettings`
- **Onboarding:** Add tradition + prayer style as optional step

**Task 3.1.3: Reframe Archetype Language for Broad Christianity**
- **File:** `lib/features/assessment/domain/models/archetype.dart`
- **Change:** Remove Catholic-specific framing from descriptions
  - "cardinal vice" → "core struggle"
  - "virtue" → "strength" (already general enough)
  - "charity" → keep (universally Christian)
  - "sacramental" references → remove or generalize
- **No change to:** Archetype names, strengths, distortions, growth commitments (these are already universal)

### 3.2 Connect Screen (Pillar Hub)

**Task 3.2.1: Create ConnectScreen**
- **File:** `lib/features/connect/presentation/screens/connect_screen.dart` (new)
- **Layout:**
  1. **Identity Card:** Archetype name + description, tradition badge, spiritual age
  2. **Your Tribe/Prayer Family:** Family streak, member count, recent pulse
  3. **Quick Assessment:** "Reassess your calling" link, weekly assessment link
  4. **Growth Journey:** Key milestones, archetype resonance (biblical character)
- **Reuses:** `ArchetypeIdentityBadge`, `CallingProfile`, `TribePulse` widgets

---

## PHASE 4: Speak Pillar — People + Prayer (Weeks 5-8)

### 4.1 Speak Screen (Pillar Hub)

**Task 4.1.1: Create SpeakScreen**
- **File:** `lib/features/speak/presentation/screens/speak_screen.dart` (new — new `speak/` feature)
- **Layout:**
  1. **Companion Card:** Orb + latest nudge + "Talk now" button
  2. **Tribe Feed:** Recent check-ins, reflections, encouragement requests
  3. **Prayer/Content:** Quick prayer, verse of the day, meditation
  4. **Advisors:** Accountability partners, circle updates, "Find an advisor"
- **Reuses:** `CompanionOrb`, `CompanionBubble`, `TribePulse`, `SpiritualAidHub` cards

### 4.2 Companion Commitment Integration

**Task 4.2.1: Commitment-Aware Companion Chat**
- **Extend:** `CompanionChatNotifier` with commitment context
- **When opened from notification:** Companion knows commitment + streak + days missed
- **Modes:**
  - `default` — general conversation
  - `accountability` — commitment check-in
  - `hard_questions` — deep faith questions
  - `failure_admission` — user slipped on a bad-habit commitment
- **Admission mode flow:**
  - Companion: "I see you missed your commitment today. That takes courage to admit."
  - Companion: "What happened?" (open-ended)
  - User responds (text or voice via existing speech-to-text)
  - Companion offers encouragement + practical next step
  - Companion: "Want to try again tomorrow? I'll be here."
  - On affirmative: reset grace points, reschedule tomorrow's overlay
- **Reuses:** Existing streaming chat, mood system, haptic signatures

### 4.3 Prayer Content (Denomination-Neutral Core + Optional Packs)

**Task 4.3.1: Universal Prayer Core**
- **Always available (no tradition required):**
  - Lord's Prayer (with optional tradition-specific version)
  - Serenity Prayer
  - Prayer of St. Francis (universally loved across traditions)
  - Psalms: 23, 51 (repentance), 91 (protection), 121 (help), 139 (known)
  - Morning Offering (general version)
  - Evening Thanksgiving
  - Prayer for Forgiveness
  - Prayer for Strength
  - Prayer for Others
  - Gratitude prompts
- **File:** `lib/features/spiritual_aid/data/universal_prayer_catalog.dart` (new — replace/add to existing prayer data)
- **Existing:** `QuickPrayer` catalog has 30+ prayers — audit and keep universal ones, move tradition-specific to content packs

**Task 4.3.2: Content Pack System (Optional)**
- **File:** `lib/core/services/content_pack_service.dart`
- **Model `ContentPack`:**
  - `id: String`, `name: String`, `tradition: ChristianTradition`
  - `prayers: List`, `commitments: List`, `media: List`, `size: int`
- **Packs:** Catholic, Evangelical, Orthodox (optional downloads, not required)
- **Base app works fully without any pack installed**

---

## PHASE 5: Overlay & Notification Escalation (Weeks 7-10)

### 5.1 Smart Escalation Ladder

**Task 5.1.1: Escalation Logic**
- **File:** `lib/features/commit/data/notification_escalation.dart`
- **Logic by consecutive miss count:**
  - Day 1: Standard overlay at agreed time
  - Day 2: Overlay + pre-reminder 15min before
  - Day 3: Overlay + companion message ("James noticed you missed 3 days")
  - Day 4: Overlay + partner/circle alert (if accountability set)
  - Day 5: Urgent overlay "Your commitment is at risk" + highest priority
  - Day 7+: Offer grace restart + "Talk to someone" prompt

**Task 5.1.2: Companion Call Screen (In-App)**
- **File:** `lib/features/speak/presentation/screens/companion_call_screen.dart`
- **Not a real phone call** — full-screen immersive experience
- **Triggered by:** Escalation at day 5+ miss, or user tapping "Call" on companion
- **Experience:**
  - Full dark screen with large companion orb (196px)
  - Companion speaks via TTS (reuse `TtsService`)
  - User responds via tap buttons ("Done" / "Help" / "Later")
  - 30-second max interaction
  - Closes to companion chat for depth

### 5.2 Rich Push Notifications

**Task 5.2.1: Create PushTemplateEngine**
- **File:** `lib/core/services/notifications/push_template_engine.dart`
- **Templates:**
  - `commitment_check_in`: "[name], time for [commitment]. Day [day] of [total]."
  - `milestone_reached`: "🎉 [name], you've completed [percent] of [commitment]!"
  - `partner_activity`: "[partner] just checked in. Your turn?"
  - `circle_streak`: "Your circle is on a [days]-day streak. Don't break it!"
  - `struggle_support`: "You've missed [days] days. Need to adjust or talk?"
  - `companion_nudge`: "[companion] says: [message]"
  - `failure_admission_response`: "[companion] responded to your admission"
- **Method:** `render(String template, Map<String,String> vars)`

**Task 5.2.2: Rich Media Push Layout**
- **Extend:** `NotificationService.scheduleRichNotification()` (line 532)
- Add: big picture image from commitment media, action buttons in expanded view, grouping on lock screen

---

## PHASE 6: Onboarding Redesign (Weeks 8-10)

### 6.1 3-Pillar Onboarding

**Current onboarding** (4 steps): TheProblem → TheSolution → YourIdentity → YourAccount
**New onboarding** (3 steps, maps to 3 pillars):

**Step 1: CONNECT — Who Are You?**
- Christian tradition (optional, skipable)
- Archetype compass (existing compass wheel)
- Prayer style (contemplative, liturgical, spontaneous, varied)
- "You're a [Archetype] who prays [style]. This is your spiritual identity."

**Step 2: COMMIT — What Will You Do?**
- "What matters most right now?"
  - Start a new spiritual habit
  - Break a habit that's holding you back
  - Follow a 40-day guide
- Quick picker from top 5 suggestions (based on archetype + tradition)
- Set schedule: when and how often
- "We'll check in with you at [times]. Ready?"

**Step 3: SPEAK — Who Walks With You?**
- Choose companion character (existing companion selection)
- Join or create prayer family / tribe (based on archetype match)
- Set accountability level (solo / partner / circle)
- "You're not alone. [Companion] walks with you."

**Existing onboarding files to modify:**
- `lib/features/onboarding/application/onboarding_state.dart` — reduce fields, restructure around 3 pillars
- `lib/features/onboarding/application/onboarding_notifier.dart` — update step logic
- `lib/features/onboarding/presentation/onboarding_screen.dart` — 3 steps instead of 4
- Remove: `the_noise_view.dart`, `the_solution_view.dart` (replace with pillar-based views)
- Keep: `discover_identity_view.dart` (compass), `your_account_view.dart` (signup)
- Keep: `christian_life_baseline_view.dart` (baseline data), `good_habits_view.dart`, `struggles_view.dart`

---

## Summary: Complete File Change Map

### New Files (22)

| # | File | Pillar | Phase |
|---|------|--------|-------|
| 1 | `lib/features/home/presentation/screens/home_screen.dart` | Home | 1 |
| 2 | `lib/features/commit/application/overlay_notification_service.dart` | Commit | 1 |
| 3 | `android/app/src/main/kotlin/.../OverlayResponseActivity.kt` | Commit | 1 |
| 4 | `lib/features/commit/presentation/screens/overlay_notification_screen.dart` | Commit | 1 |
| 5 | `lib/features/commit/data/commitment_media_catalog.dart` | Commit | 1 |
| 6 | `lib/shared/widgets/commitment_backdrop.dart` | Commit | 1 |
| 7 | `lib/features/commit/presentation/screens/commitment_wizard_screen.dart` | Commit | 2 |
| 8 | `lib/features/commit/application/failure_protocol_service.dart` | Commit | 2 |
| 9 | `lib/features/commit/domain/models/failure_admission.dart` | Commit | 2 |
| 10 | `lib/shared/widgets/journey_progress_visual.dart` | Commit | 2 |
| 11 | `lib/features/connect/domain/models/christian_tradition.dart` | Connect | 3 |
| 12 | `lib/features/connect/domain/models/spiritual_identity.dart` | Connect | 3 |
| 13 | `lib/features/connect/presentation/screens/connect_screen.dart` | Connect | 3 |
| 14 | `lib/features/speak/presentation/screens/speak_screen.dart` | Speak | 4 |
| 15 | `lib/features/spiritual_aid/data/universal_prayer_catalog.dart` | Speak | 4 |
| 16 | `lib/core/services/content_pack_service.dart` | Speak | 4 |
| 17 | `lib/features/commit/data/notification_escalation.dart` | Commit | 5 |
| 18 | `lib/features/speak/presentation/screens/companion_call_screen.dart` | Speak | 5 |
| 19 | `lib/core/services/notifications/push_template_engine.dart` | Commit | 5 |

### Existing Files to Modify (22)

| # | File | Changes | Phase |
|---|------|---------|-------|
| 1 | `lib/shared/widgets/app_shell.dart` | 6 tabs → 4 tabs (Home, Connect, Commit, Speak) | 1 |
| 2 | `lib/core/constants/app_routes.dart` | Add /home, /connect, /speak routes | 1 |
| 3 | `lib/core/router/app_router.dart` | Update shell route definitions | 1 |
| 4 | `lib/features/vision/presentation/screens/today_screen.dart` | Repurpose/merge into HomeScreen or remove if replaced | 1 |
| 5 | `lib/features/vision/presentation/screens/commit_screen.dart` (2015 lines) | Add overlay schedule agreement, wizard integration | 1, 2 |
| 6 | `lib/features/vision/application/vision_notifier.dart` | Coordinate with overlay scheduler, failure protocol | 1, 2 |
| 7 | `lib/core/services/notifications/notification_service.dart` | Full-screen intent, overlay actions, rich layouts | 1 |
| 8 | `lib/core/services/notifications/push_notification_service.dart` | Rich media push, template engine integration | 1 |
| 9 | `lib/core/services/celebration_service.dart` | Commitment milestone celebrations | 1 |
| 10 | `lib/core/storage/app_settings.dart` | Add spiritualIdentity, commitmentSchedulePreferences, failureAdmissionCount | 2, 3 |
| 11 | `lib/features/alignment/data/habit_catalog.dart` | Enhance bad habits with better counter-habit suggestions | 2 |
| 12 | `lib/features/assessment/domain/models/archetype.dart` | Reframe Catholic-specific language ("cardinal vice" → "core struggle") | 3 |
| 13 | `lib/features/onboarding/presentation/onboarding_screen.dart` | 3 steps (Connect → Commit → Speak) instead of 4 | 6 |
| 14 | `lib/features/onboarding/application/onboarding_state.dart` | Restructure fields around 3 pillars | 6 |
| 15 | `lib/features/onboarding/application/onboarding_notifier.dart` | Update step logic to 3 pillars | 6 |
| 16 | `lib/features/companion/application/companion_chat_notifier.dart` | Add failure_admission mode | 2 |
| 17 | `lib/features/companion/presentation/screens/companion_chat_screen.dart` | Admission flow UI, commitment context | 2 |
| 18 | `lib/features/vision/presentation/screens/tribe_screen.dart` | Integrate with Connect pillar | 3 |
| 19 | `lib/features/mission/application/mission_notifier.dart` | Accountability partner visibility for commitments | 2 |
| 20 | `lib/features/spiritual_aid/application/spiritual_aid_notifier.dart` | Universal prayer catalog, content pack loading | 4 |
| 21 | `lib/features/spiritual_aid/presentation/screens/spiritual_aid_hub_screen.dart` | Integrate with Speak pillar | 4 |
| 22 | `lib/features/vision/domain/vision_models.dart` | CommunityChallenge model for group challenges | 2 |

### Files NOT to Create (Reuse Instead)

| Need | Reuse |
|------|-------|
| Audio playback | `MeditationAudioService` + `GlobalAudioManager` |
| TTS | `TtsService` (Fish Audio + system + pre-recorded) |
| Sound effects | `SoundService` |
| Wake lock | `WakeLockService` |
| DND | `DisturbanceService` |
| Haptics | `HapticService` |
| Celebrations | `CelebrationService` + `ConfettiOverlay` |
| Auth | `AuthNotifier` + `AuthRepository` |
| Streak tracking | `SettingsNotifier.registerDailyCheckIn()` |
| Commitment models | `CommitmentSeason`, `CommitmentPlan`, `CommitmentDailyItem` |
| Habit models | `HabitItem`, `FortyDayGoal`, `HabitNotifier` |
| Community base | `TribeIdentity`, `TribeMembership`, `TribePulse` |
| Accountability | `AccountabilityPartner`, `MissionNotifier` |
| Companion AI | `CompanionChatNotifier`, `CompanionRepository` |
| Theme | `AppThemeFactory`, `AppColorPalette`, `AppThemeTokens` |
| Navigation | `AppShell` (modified), `GoRouter` |
| Data persistence | `HiveService`, `SettingsStorage` |
| Offline sync | `OfflineSyncQueue` |
| Charts | `fl_chart` (already in pubspec) |
| Rich text | `flutter_quill` (already in pubspec) |
| Speech-to-text | `speech_to_text` (already in pubspec) |
| Analytics | `AnalyticsService` + `AppAnalyticsService` |

---

## The 3-Pillar Navigation Map

```
┌────────────────────────────────────────────────────────────────────┐
│                          APP SHELL                                  │
│  [Home]  [Connect]  [Commit]  [Speak]                              │
└────────────────────────────────────────────────────────────────────┘

HOME ─────────────────────────────────────────────────────────────
├─ Streak + Grace Points
├─ Today's commitment (visual timeline snippet + check-in)
├─ Companion nudge
├─ Tribe pulse (recent activity)
└─ Quick actions: Bible, Journal, Meditation, Games

CONNECT ──────────────────────────────────────────────────────────
├─ Identity Card (archetype, tradition, spiritual age, calling)
│  ├─ "Reassess" → Assessment compass
│  └─ "Weekly Check" → Weekly assessment
├─ Your Tribe / Prayer Family
│  ├─ Family streak, member list
│  ├─ Tribe pulse feed
│  └─ "Invite" → Share invite link
└─ Growth Journey (milestones, resonance)

COMMIT ───────────────────────────────────────────────────────────
├─ Active Commitment (if any)
│  ├─ JourneyProgressVisual (progress garden)
│  ├─ Today's checklist (1-3 items)
│  ├─ Overlay schedule (when to expect check-ins)
│  └─ "Check in now" button
├─ "Start New Commitment" → CommitmentWizard
│  ├─ Start good habit
│  ├─ Stop bad habit (with confession protocol)
│  └─ 40-day plan
└─ Past commitments / history

SPEAK ────────────────────────────────────────────────────────────
├─ Companion Chat
│  ├─ Orb + latest nudge
│  └─ "Talk now" → chat screen
├─ Tribe Feed
│  ├─ Reflections, check-ins, encouragement
│  └─ "Send kudos" quick action
├─ Prayer & Content
│  ├─ Quick prayer
│  ├─ Verse of the day
│  └─ Meditation
└─ Accountability
    ├─ Partner status
    ├─ Circle streak
    └─ "Find advisor" (future)
```

---

## The Confession/Admission Flow (Stop Bad Habit)

```
User selects "Stop bad habit" in Commitment Wizard
  → Picks struggle (anger, lust, pride, gossip, etc.)
  → Sets replacement behavior
  → Sets overlay schedule
  → Sets accountability level (companion/partner/circle)
  → COMMITMENT ACTIVE
       │
       ▼ daily overlay check-in
  ┌────┴────┐
  │ DID IT? │──Yes──→ "Great! Day [N] of [total]." → update garden
  └────┬────┘
       │ No
       ▼
  ┌──────────────┐
  │ MISS DAY 1-2 │──→ Gentle overlay: "That's okay. Keep going."
  └──────┬───────┘
         │
  ┌──────┴───────┐
  │ MISS DAY 3+  │──→ FAILURE PROTOCOL TRIGGERED
  └──────┬───────┘
         │
         ▼
  "Who would you like to tell about this struggle?"
  ┌──────────┬───────────┬───────────┬──────────┐
  │ Companion│  Partner  │  Circle   │  Prayer  │
  │ (AI)     │  (human)  │  (group)  │  (alone) │
  └────┬─────┴─────┬─────┴─────┬─────┴────┬─────┘
       │           │           │          │
       ▼           ▼           ▼          ▼
  Companion   Partner gets  Circle feed  Repentance
  talks it    notification: sees: "[User] prayer shown
  through     "[User] needs is struggling" with confession
  with user   support"     (anonymous)  prayer
       │           │           │          │
       └───────────┴───────────┴──────────┴─────────┐
                                                    │
                                                    ▼
                              "Thank you for being honest.
                               Want to begin again tomorrow?"
                                    │ Yes → Reset grace points,
                                    │        reschedule overlays,
                                    │        continue commitment
                                    │ No → Offer adjustment:
                                    │       "Want to change your
                                    │        approach?"
```

The failure protocol is the app's answer to "you want to stop bad things but you don't confess." It provides a non-judgmental, private-or-social admission mechanism that maps to whatever the user is comfortable with. Research shows that admitting failure to a witness dramatically increases the chance of recovery — this is the universal Christian principle of confession translated into habit science.
