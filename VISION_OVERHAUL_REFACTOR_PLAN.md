# Elbiblio Vision Overhaul Refactor Plan

## Purpose

Recenter Elbiblio around the original vision: a spiritually centered social growth app where people grow through tribe-based belonging, time-bound commitments, lightweight shared reflections, daily spiritual insight, and simple recurring rituals.

This plan is not a scaffold plan. It is a production-grade refactor and launch plan. The goal is a clean, cohesive product surface that can ship without feeling like multiple older apps stitched together.

Target bottom navigation:

`Today | Reflect | Commit | Tribe | Grow`

Important naming rule: "MVP" is only a planning descriptor. It must not appear in new component names, new route names, analytics event names, implementation copy, or user-facing copy.

## Launch Definition

The refactor is launch-ready only when the app feels like one product:

- The five bottom tabs are the only primary visible app structure.
- Every primary tab maps directly to the vision.
- Reflection and hangouts are centered around active commitments.
- Tribe is an identity and belonging surface, not a generic group directory.
- Grow tells a visual story of spiritual growth and gives access to daily faith questions and daily spiritual insights.
- Old features are either removed from the primary journey, moved behind contextual links, or retired.
- Backend responses support the UX directly without the Flutter app inventing core truth locally.
- Empty, loading, error, offline, unauthenticated, and first-run states are designed, not accidental.
- Tests cover the core product loop end to end.

## Current-State Findings

### What Already Aligns

- `vision.md` defines a focused product: consistency, belonging, emotional support, commitments, private commitment feeds, weekend tribe rituals, hangouts, and daily faith growth questions.
- Flutter has a first-pass vision implementation under `lib/features/mvp/`, including visibility modes, tribes, commitments, reflection feed, daily questions, and milestone icons.
- Backend foundation at `C:\Users\Son\cowork\elbiblio_api` is stronger than the Flutter surface currently suggests:
  - `VisionMvpController` supports bootstrap, visibility, recommended tribes, joining tribes, recommended commitments, joining commitments, active commitments, check-ins, and nudge count updates.
  - `ChallengeFeedAPIController` enforces commitment-member scoped feeds, 500-character reflections, one reflection per user per commitment per day, and reactions.
  - `WeeklyRitualAPIController` enforces tribe membership and weekend-only posting.
  - `2026_05_08_000001_create_vision_mvp_tables.php` creates the key tables for tribes, commitments, check-ins, reflections, reactions, weekly rituals, hangouts, daily faith questions, and daily faith question answers.
  - `VisionMvpSeeder` seeds starter tribes, commitments, and daily faith questions.
- Existing archetypes in `lib/features/assessment/domain/models/archetype.dart` are a strong base for tribe identity: Artisan, Watchman, Cultivator, Sower, Welcomer, Pillar, Sentinel, Bridgebuilder, Healer, Harvester, Reformer, Architect.
- The app already uses Riverpod, GoRouter, Dio, local notifications, Lucide icons, and centralized theme tokens. No new app architecture framework is needed.

### What Is Blocking A Cohesive Launch

- Visible navigation is currently `Today | Challenge | Tribes | Questions | Profile`, not the intended emotional flow.
- Current Flutter implementation names still use `Mvp...`, which makes the refactor feel temporary and leaks scaffolding into the codebase.
- Current `MvpChallengeScreen` combines commitment management and reflection feed. The vision needs two different mental spaces:
  - `Commit`: choose and keep the commitment.
  - `Reflect`: share, listen, support, and gather around that commitment.
- Current `MvpTribesScreen` is mostly visibility plus tribe selection. It does not yet carry daily tribe pulse, check-in summaries, invitations, reassessment, or identity evolution.
- Current `GrowHubScreen` is too broad and too legacy-heavy. It promotes games, Bible reading plans, journal, accountability partner, career/calling, habits, and other old surfaces. Grow should become a visual spiritual growth journey plus daily faith questions and daily spiritual insights.
- Backend `AudioHangout` has a model and table, but no production API, join/leave model, room credential flow, moderation state, or Flutter contract.
- Tribe pulse data does not yet exist as a first-class API. The requested copy like "4 people from your tribe completed 30 days fast today" requires aggregate backend endpoints.
- Weekly ritual responses need more context for production UX: can-post state, poster alias, bookmark state for current user, weekend window timing, expiration rules, and empty states.
- Daily faith question API returns the first active question by sort order. Production needs rotation, answered state, and insight history.
- Notification payloads still route commitment nudges to old challenge surfaces. They should route to `Commit` for check-in and `Reflect` for post-completion reflection.
- Many older features remain first-class routes. Internal routes can remain, but primary discovery must be pruned.

## Product North Star

Elbiblio should feel like:

- A daily return point, not a productivity dashboard.
- A small spiritual community, not a public social network.
- A commitment companion, not a content library.
- A place where identity leads to belonging, belonging supports commitment, commitment creates reflection, and reflection deepens growth.

Each tab must answer one question:

- `Today`: What is my faithful return today?
- `Reflect`: Who is walking this commitment with me, and what can we honestly share?
- `Commit`: What commitment am I keeping or choosing for this season?
- `Tribe`: Where do I belong, who is returning with me, and does my identity still fit?
- `Grow`: How is my spiritual journey unfolding, and what insight helps me grow today?

## Behavioral Design Principles

- Identity before activity. Users should feel "I am part of this kind of spiritual journey" before they are asked to do tasks.
- Belonging before performance. Tribe and commitment feed should reduce shame, not increase pressure.
- One clear next action. Each screen gets one primary action and one natural secondary action.
- Scarcity creates meaning. One reflection per day is a ritual, not a product limitation.
- Social proof should be aggregate and gentle. Use "4 people returned today," not rankings or comparison.
- Missed days invite return. Avoid failure language unless the user explicitly asks for strict accountability.
- Commitments should be concrete. A commitment has a daily action, duration, nudge rhythm, and reflection context.
- Nudges are implementation intentions. They help users answer "when this moment arrives, what will I do?"
- Privacy must feel calm. Before posting, users should know who can see it and under what alias.
- AI stays supportive and mostly invisible. It can assist nudges, summaries, encouragement, recap generation, and reflection assistance, but it should not become the product center.

## Production UX Architecture

### The Core Loop

1. User completes onboarding and spiritual compass.
2. User joins a spiritually aligned tribe.
3. User chooses a time-bound commitment and nudge rhythm.
4. User completes today's commitment from Today or a nudge.
5. User shares or reads one reflection in Reflect.
6. Tribe pulse reinforces belonging without comparison.
7. Grow visualizes the journey and offers daily insight.
8. Weekend ritual creates a weekly communal rhythm.

Every shipped surface should support this loop directly or remain secondary.

### Primary Navigation Rules

- Bottom nav labels are exactly `Today`, `Reflect`, `Commit`, `Tribe`, `Grow`.
- No bottom-nav destination should be a generic hub of unrelated features.
- No primary tab should require more than one scroll screen to find its primary action.
- Old routes can remain for deep links, but primary screens should not advertise them unless contextually relevant.
- Top app bars should be minimal. Avoid turning screens into settings dashboards.

## Target Screens

### Today

Role: daily landing and commitment check-in.

Primary content:

- Active commitment card:
  - title
  - day count
  - daily action
  - progress through the commitment
  - check-in status
- One primary check-in action.
- Reflection prompt after check-in.
- Tribe pulse preview.
- Daily insight preview from Grow.
- Milestone strip for meaningful journey events.

Primary actions:

- Complete today.
- Open Reflect after completion.
- Choose commitment if none exists.
- Join tribe if no tribe exists.

Production states:

- First run: guide to tribe and commitment, not a blank dashboard.
- No tribe: show belonging-first prompt.
- No commitment: show one curated recommendation and route to Commit.
- Checked in: shift from action to reflection/support.
- Offline: allow local completion queue only if it can sync reliably and visibly.
- Error: show soft recovery copy with retry.

Do not surface:

- Dense analytics.
- Multiple unrelated modules.
- XP-first feedback.
- Large public feed previews.
- Broad quick action menus.

### Reflect

Role: commitment-centered social support.

Reflect is where hangouts belong. Hangouts should primarily be centered around commitments because the shared commitment creates trust, context, and psychological safety. A generic audio room feels like a community feature; a commitment hangout feels like "people walking this with me."

Primary content:

- Active commitment header.
- Member-scoped commitment reflection feed.
- Composer for one daily reflection, max 500 characters.
- Support reactions: Amen, Support, Same.
- Commitment hangouts:
  - live hangouts for current commitment
  - scheduled hangouts for current commitment
  - create hangout scoped to current commitment by default
- Weekend reflection hub entry when available.

Primary actions:

- Share today's reflection.
- Support someone else's reflection.
- Start a commitment hangout.
- Join a commitment hangout.
- Enter weekly reflection hub on Saturday/Sunday.

Rules:

- If no active commitment exists, Reflect is locked with a warm explanation and a route to Commit.
- If user has not checked in today, allow reading feed but gate composing behind check-in or clearly encourage completing today first.
- Default hangout scope is `commitment`.
- Tribe-scoped hangouts may exist as a secondary option for weekend rituals.
- Everyone-scoped hangouts should be hidden from the main Reflect screen for launch unless moderation is complete.
- Feed pagination should be calm and finite-feeling. Avoid public-social infinite scroll energy.
- Reflection cards must show visibility alias, time, content, reactions, and support state.
- Composer must show visibility context: "Visible to members of this commitment as Anonymous/Nickname/etc."

Production states:

- No active commitment.
- Active commitment but not checked in.
- Checked in and can post.
- Already posted today.
- Empty feed.
- Feed loading/error.
- Live hangout available.
- No hangouts available.
- Hangout join denied because max participants reached.

### Commit

Role: choose, configure, and keep time-bound commitments.

Primary content:

- Active commitment status.
- Daily action.
- Nudge rhythm from 3 to 10.
- Recommended commitments based on tribe, compass result, and current progression.
- Commitment detail cards with duration, purpose, daily action, visibility, tribe alignment, and reflection availability.

Primary actions:

- Join commitment.
- Complete today.
- Update nudge count.
- View commitment details.

Rules:

- Product language should prefer "commitment" over "challenge" in navigation and screen framing.
- A commitment can still have a title like "30-Day Social Media Fast."
- The catalog should be curated and small.
- Joining a commitment should schedule nudges only after permissions are handled gracefully.
- Leaving or archiving a commitment must be a secondary, confirmed action.
- Users should not accidentally join multiple commitments unless the product explicitly supports multiple active commitments. For launch, prefer one primary active commitment.

Production states:

- No active commitment.
- Active commitment.
- Completed today.
- Notification permission denied.
- Nudge scheduling failed.
- Commitment catalog unavailable.

### Tribe

Role: belonging, identity, daily tribe pulse, invites, and reassessment.

Primary content:

- Current tribe identity using spiritual archetype language.
- Daily tribe pulse:
  - aggregate returns today
  - commitment milestones completed by tribe members
  - reflections/support activity counts
  - weekly ritual activity
- Invite action.
- Visibility controls.
- Retake spiritual compass.
- Recommended tribes based on current progression.

Primary actions:

- Invite someone.
- Retake compass.
- Change primary tribe.
- Open weekend ritual.

Tribe naming direction:

- Tribe names should be formed from the spiritual archetype system, not generic lifestyle labels alone.
- Examples:
  - Watchman Circle
  - Healer Circle
  - Cultivator Circle
  - Bridgebuilder Circle
  - Sentinel Circle
  - Sower Circle
  - Artisan Circle
  - Pillar Circle
- Existing seed names like Quiet Discipline, Healing & Forgiveness, and Gratitude & Presence can become commitment categories, descriptions, or tribe paths rather than primary tribe identity.

Production states:

- No tribe selected.
- Tribe selected with no activity.
- Tribe selected with daily pulse.
- Weekend ritual available.
- Weekend ritual closed.
- Invite success/failure.
- Retake compass recommended.

Privacy:

- Tribe pulse is aggregate by default.
- Do not reveal individual completion behavior unless the user explicitly posted a reflection under their chosen alias.

### Grow

Role: visual spiritual growth journey, daily faith questions, and daily spiritual insights.

Grow should not be a generic "more features" hub. It should visually tell the story of the user's spiritual journey: who they are becoming, what season they are in, where they have returned, where they struggled, and what God may be inviting them into next.

Primary content:

- Visual journey timeline:
  - compass completed
  - tribe joined
  - commitment joined
  - daily returns
  - reflections shared
  - support given
  - weekly rituals bookmarked
  - commitment completed
  - compass retaken
- Current growth season:
  - archetype identity
  - active tribe
  - active commitment
  - current growth theme
- Daily faith question:
  - question
  - optional answer
  - answered state
- Daily spiritual insight:
  - concise explanation
  - spiritual insight
  - practical perspective
  - difficult real-world context
- Saved/bookmarked insights and weekly reflections.
- Gentle next invitation based on journey state.

Primary actions:

- Answer today's faith question.
- Read today's spiritual insight.
- Save/bookmark insight.
- Revisit journey timeline.
- Retake compass if identity feels outdated.

Visual storytelling requirements:

- The journey should be scannable at a glance and emotionally meaningful.
- Use a vertical path, timeline, rings, or season map rather than analytics cards.
- Show milestones as story beats, not trophies.
- Avoid charts that feel like productivity tracking.
- Use icons consistently from the milestone registry.
- Completion should read as formation, not achievement.

Example Grow structure:

- Header: "Your growth journey"
- Season card: "Walking with the Watchman Circle through 30-Day Social Media Fast"
- Journey path:
  - "Compass completed"
  - "Joined Watchman Circle"
  - "Started Social Media Fast"
  - "Returned today"
  - "Shared 4 reflections this season"
- Today insight:
  - daily faith question
  - four insight blocks
  - answer field
- Saved reflections and insights:
  - bookmarked weekly reflections
  - saved daily insights

Do not surface as primary Grow content:

- Games.
- Large Bible library.
- Career/calling dashboards.
- Broad journaling.
- Heavy habit conquest UI.
- Deep analytics.
- XP or leaderboard framing.

## Information Architecture Decisions

### What Moves Out Of Primary Navigation

- Profile becomes accessible from a small settings/avatar affordance, not bottom nav.
- Faith Questions move into Grow.
- Reflection feed moves into Reflect.
- Commitment selection/check-in moves into Commit.
- Games become secondary or deferred.
- Bible library becomes contextual, not a bottom-nav-level feature.
- Journal becomes contextual to reflections/insights if needed.
- Companion chat is not a primary surface for this launch.
- Mission/career/church/app-lock surfaces are not part of the launch loop unless specifically reintroduced later.

### What Can Remain Internally

Internal routes may remain to avoid risky deletion:

- Bible routes.
- Journal routes.
- Assessment routes.
- Meditation routes.
- Profile/settings routes.
- Legacy commitment journey routes.
- Games routes.

But the five-tab experience should not promote them as equal pillars.

## Flutter Refactor Plan

### Phase 1: Create Production Vision Namespace

Create:

- `lib/features/vision/domain/`
- `lib/features/vision/data/`
- `lib/features/vision/application/`
- `lib/features/vision/presentation/screens/`
- `lib/features/vision/presentation/widgets/`

Move concepts from `lib/features/mvp/` into production names:

- `MvpVisibilityMode` -> `VisibilityMode`
- `MvpTribe` -> `TribeIdentity`
- `MvpTribeMembership` -> `TribeMembership`
- `MvpCommitmentChallenge` -> `CommitmentPlan`
- `MvpCommitmentMembership` -> `CommitmentSeason`
- `MvpReflection` -> `CommitmentReflection`
- `MvpDailyFaithQuestion` -> `DailyGrowthQuestion`
- `MvpRepository` -> `VisionRepository`
- `MvpNotifier` -> `VisionNotifier`
- `MvpState` -> `VisionState`

New models:

- `TribePulse`
- `TribePulseItem`
- `WeeklyRitualReflection`
- `WeeklyRitualStatus`
- `CommitmentHangout`
- `HangoutParticipant`
- `DailySpiritualInsight`
- `GrowthJourneyEvent`
- `GrowthSeason`
- `ReflectionStatus`

Provider:

- `visionRepositoryProvider`
- `visionProvider`

Important:

- The repository can still call existing backend endpoints while hiding old endpoint names behind production method names.
- Remove all user-facing "MVP" copy immediately.
- Remove new `Mvp` class names before launch.

### Phase 2: Define App Routes And Shell

Update route constants:

- `/today`
- `/reflect`
- `/commit`
- `/tribe`
- `/grow`

Add transitional redirects if needed:

- `/challenge` -> `/commit`
- `/tribes` -> `/tribe`
- `/questions` -> `/grow`

Update `AppShell`:

- `Today`: `LucideIcons.calendarCheck` or `LucideIcons.sun`
- `Reflect`: `LucideIcons.messagesSquare` or available heart/message icon
- `Commit`: `LucideIcons.flag`
- `Tribe`: `LucideIcons.users`
- `Grow`: `LucideIcons.sprout`

Production checks:

- Labels fit on small devices.
- Touch targets remain at least 44px high.
- Selected state is visible in light and dark themes.
- Bottom nav does not obscure scroll content.

### Phase 3: Build The Five Production Screens

Create production screens:

- `TodayScreen`
- `ReflectScreen`
- `CommitScreen`
- `TribeScreen`
- `GrowScreen`

Shared widgets:

- `CommitmentStatusCard`
- `DailyReturnButton`
- `ReflectionComposer`
- `CommitmentReflectionCard`
- `HangoutStrip`
- `TribePulseCard`
- `GrowthJourneyTimeline`
- `DailyInsightCard`
- `MilestoneIcon`
- `VisibilityAliasBadge`
- `VisionEmptyState`
- `VisionErrorState`

Avoid one giant screen file. Widgets should be small enough for testing but not over-abstracted.

### Phase 4: Split Commit And Reflect State

Short-term:

- Keep one `VisionState` if it reduces churn.

Production target:

- `VisionOverviewState` for bootstrap-level state.
- `CommitState` for commitments.
- `ReflectState` for feed, composer, hangouts, and weekly ritual.
- `TribeState` for tribe pulse.
- `GrowState` for journey events, questions, insights, and saved items.

Do not over-split before the first production pass if it slows delivery, but the plan should avoid a single forever-notifier that becomes a hidden monolith.

### Phase 5: Grow Visual Journey Implementation

Build `GrowthJourneyTimeline` using real events where available:

- compass completed
- tribe joined
- commitment joined
- check-in completed
- reflection posted
- support given
- weekly reflection bookmarked
- commitment completed

Fallback:

- If backend milestones are thin, derive provisional events from bootstrap data but mark them as local display events only.
- Do not fake long histories.

UX:

- Use a vertical timeline or path with icons.
- Current season gets a stronger visual treatment.
- Past events are soft and readable.
- Empty state explains that the story begins with tribe and commitment.

Daily question and insight:

- Combine current `DailyGrowthQuestion` fields into a polished insight card.
- Allow answering from Grow.
- Store answered state.
- Save/bookmark insight if backend supports it; otherwise add backend support before launch or hide save.

### Phase 6: Onboarding Recenter

Target onboarding:

1. Account/sign up.
2. Visibility mode.
3. Short spiritual compass.
4. Tribe recommendation.
5. Commitment recommendation.
6. Nudge rhythm.
7. Land on Today.

Compass:

- Use a short, production-feeling assessment, not placeholder copy.
- Map results to archetype-led tribes.
- Let user override recommendation.
- Store results through backend compass endpoints.

Onboarding launch criteria:

- No prototype wording.
- No "MVP" wording.
- No dead-end if backend fails.
- User can finish with no notification permission.
- User understands who can see reflections before first post.

### Phase 7: Notifications And Nudges

Commitment nudges:

- Default route: `/commit`.
- If check-in is already complete, route to `/reflect`.
- Notification action "I did this" should attempt check-in.
- If check-in action fails, route to Commit with a retry state.

Production requirements:

- Permission request timing must be contextual, after commitment choice.
- Nudge count must respect backend min/max.
- Scheduled notification IDs must avoid collisions.
- Leaving/archiving commitment must cancel related nudges.
- Copy must be gentle and commitment-specific.

### Phase 8: Remove Primary Old-Feature Gravity

Prune from primary screens:

- Games.
- Broad Bible library cards.
- Feature-heavy journal prompts.
- Companion/personality prompts.
- Mission/career dashboards.
- App lock dashboards.
- Analytics-heavy streaks.

Keep as contextual routes only where useful:

- A daily insight may deep-link to a scripture passage later.
- A reflection may be saved to journal later.
- A profile/settings icon can hold reminders, account, theme, about.

## Backend Refactor Plan

### Backend Phase 1: Production Bootstrap

Add route alias:

- `GET /vision/bootstrap`

Keep old route temporarily:

- `GET /mvp/bootstrap`

Bootstrap should return:

```json
{
  "user": {
    "id": 1,
    "visibility_mode": "anonymous",
    "visibility_alias": "Anonymous"
  },
  "primary_tribe": {},
  "active_commitment": {},
  "today_check_in": {},
  "reflection_status": {
    "can_post": true,
    "posted_today": false,
    "visible_to": "commitment_members"
  },
  "tribe_pulse_preview": {},
  "weekly_ritual_status": {},
  "today_faith_question": {},
  "today_faith_answer": {},
  "daily_spiritual_insight": {},
  "growth_journey": {
    "season": {},
    "events": []
  },
  "hangout_summary": {
    "live_count": 0,
    "scheduled_count": 0
  }
}
```

Why:

- Flutter should not need four network calls to paint the first useful frame.
- The server should own eligibility and visibility rules.

### Backend Phase 2: Tribe Pulse

Add:

- `GET /tribes/{id}/pulse`

Response:

```json
{
  "tribe": {},
  "today": {
    "returned_count": 4,
    "active_members_count": 18,
    "reflection_count": 7,
    "support_count": 14,
    "weekly_ritual_count": 2
  },
  "commitment_milestones": [
    {
      "commitment_id": 1,
      "commitment_title": "30-Day Social Media Fast",
      "day": 30,
      "count": 4
    }
  ],
  "items": [
    {
      "type": "commitment_day_completed",
      "text": "4 people completed Day 30 of Social Media Fast today.",
      "icon_key": "flag",
      "created_at": "2026-05-08T10:00:00Z"
    }
  ]
}
```

Rules:

- Member scoped.
- Aggregate-first.
- No individual check-in exposure without explicit reflection post.
- Cache briefly if needed, but not so long that "today" feels stale.

### Backend Phase 3: Commitment-Centered Hangouts

Add:

- `GET /commitments/{id}/hangouts`
- `POST /commitments/{id}/hangouts`
- `GET /hangouts/{id}`
- `POST /hangouts/{id}/join`
- `POST /hangouts/{id}/leave`
- `POST /hangouts/{id}/end`

Default scope:

- `scope_type = commitment`
- `scope_id = commitment_challenge_id`

Optional later scopes:

- `tribe` for weekend rituals.
- `everyone` only after moderation, reporting, and abuse controls are ready.

Required data:

- title
- scope type/id
- creator alias
- max participants
- participant count
- starts_at
- status
- can_join
- denial reason if not joinable
- room/token payload when joining

Production rules:

- Only active commitment members can view or join commitment hangouts.
- Creator must be active commitment member.
- Max participants bounded.
- Ended rooms cannot be joined.
- LiveKit room creation/token errors are handled cleanly.
- Add basic moderation path: end own room, report room/user, admin-disable room.

### Backend Phase 4: Reflection Feed Hardening

Existing feed is a good base. Improve:

- Return `posted_today` and `can_post`.
- Return current user's reaction state per reflection.
- Return reaction counts by type.
- Return author alias consistently.
- Enforce membership on all read/write/reaction endpoints.
- Add pagination metadata that Flutter can parse reliably.
- Add idempotent reaction toggle or explicit remove endpoint.

### Backend Phase 5: Weekly Ritual Hardening

Enhance:

- `GET /tribes/{id}/weekly-ritual`
- `POST /tribes/{id}/weekly-ritual`
- `POST /weekly-ritual/{id}/bookmark`
- `DELETE /weekly-ritual/{id}/bookmark`

Response additions:

- `can_post`
- `window_label`
- `next_window_starts_at`
- `window_ends_at`
- `is_bookmarked_by_me`
- `poster_alias`
- `expires_at`

Add cleanup command:

- Delete expired, unbookmarked weekly reflections.

### Backend Phase 6: Daily Faith Questions And Spiritual Insights

Current daily question exists. Production needs:

- Rotation strategy by date, tribe, or user.
- Answered state for current user.
- Answer history.
- Optional saved/bookmarked insights.
- Stable daily insight payload.

Add or enhance:

- `GET /faith-questions/today`
- `POST /faith-questions/{id}/answer`
- `GET /faith-questions/history`
- `POST /daily-insights/{id}/bookmark`
- `GET /daily-insights/bookmarked`

The Grow screen should not need to infer whether the user answered today.

### Backend Phase 7: Growth Journey Events

Add a server-owned journey events endpoint:

- `GET /growth-journey`

Events can be derived initially from existing tables:

- compass assessments
- tribe memberships
- commitment memberships
- commitment check-ins
- challenge reflections
- reflection reactions
- weekly ritual reflections/bookmarks

Response:

```json
{
  "season": {
    "archetype": "Watchman",
    "tribe_name": "Watchman Circle",
    "commitment_title": "30-Day Social Media Fast",
    "theme": "Discipline and attention"
  },
  "events": [
    {
      "type": "tribe_joined",
      "title": "Joined Watchman Circle",
      "subtitle": "You found a place to grow with others.",
      "icon_key": "users",
      "occurred_at": "2026-05-08T10:00:00Z"
    }
  ]
}
```

This prevents Flutter from fabricating the user's spiritual story.

### Backend Phase 8: Route Naming And Compatibility

Add production aliases first:

- `/vision/bootstrap`
- `/growth-journey`

Keep old routes until Flutter migration is complete.

Deprecate old "mvp" references after:

- Flutter no longer calls them.
- Backend tests cover aliases.
- Production logs show no clients using old routes.

## Data And Domain Boundaries

Flutter should treat backend as source of truth for:

- membership eligibility
- posting eligibility
- check-in state
- tribe pulse aggregates
- hangout join permissions
- weekly ritual window state
- daily question answered state
- growth journey history

Flutter can own:

- transient form state
- selected nudge count before save
- local optimistic reaction animation
- local loading/empty/error presentation
- cached read-only display snapshots

Avoid:

- Local fake tribes in production flows.
- Local fake commitments after launch.
- Local fake growth history.
- Silent fallback that looks like real membership.

## UI And Micro-Interaction Direction

### Visual System

- Cards use 8px radius unless existing design tokens require otherwise.
- Avoid cards inside cards.
- Use full-width calm sections, thin dividers, and soft surfaces.
- Use Lucide icons consistently for all milestones and core actions.
- Avoid a one-note palette. Grow especially should not become a generic green dashboard.
- Avoid hero-scale text inside compact tool surfaces.
- Bottom nav and fixed controls must not obscure content.

### Motion

- Tab transition: fast fade.
- Check-in: check icon fill, small scale, light haptic, quiet confirmation.
- Reflection post: composer collapses into posted state.
- Reaction: icon fills and count updates in place.
- Join commitment: confirmation sheet with next action.
- Join tribe: confirmation sheet with identity language.
- Grow timeline: subtle reveal as events enter viewport.
- Hangout join: clear transition into room or loading state; never leave user wondering if audio connected.

### Copy

Use:

- "You returned today."
- "Share one honest reflection."
- "Visible to members of this commitment."
- "Start a hangout for this commitment."
- "Your tribe is active today."
- "Your growth story is taking shape."
- "Sit with today's question."

Avoid:

- "MVP"
- "Optimize"
- "Maximize"
- "Crush"
- "Leaderboard"
- "Public feed"
- "AI companion" as a primary promise.
- Shame-heavy failure copy.

## Observability And Analytics

Track product health without turning the UI into analytics:
These actions should have visual consistency e.g. confetti for committment completion and a big visually appealing icon for all other screens

- onboarding completed
- compass completed
- tribe joined
- commitment joined
- notification permission accepted/declined
- daily check-in completed
- reflection posted
- reaction sent
- hangout created
- hangout joined
- weekly ritual posted
- daily question answered
- insight bookmarked
- compass retaken

Do not track sensitive reflection content.

Operational logs:

- API failures by endpoint.
- Hangout room creation/join errors.
- Notification scheduling failures.
- Reflection post conflicts.
- Weekly ritual window denials.

## Testing Plan

### Flutter Unit Tests

- Vision model parsing.
- Visibility alias mapping.
- Commitment progress and checked-in-today logic.
- Reflection status parsing.
- Reaction count/state parsing.
- Tribe pulse parsing.
- Hangout eligibility parsing.
- Growth journey event parsing.
- Daily question answered state.
- Milestone icon registry.

### Flutter Widget Tests

- App shell displays exactly `Today | Reflect | Commit | Tribe | Grow`.
- Today first-run state routes to tribe/commitment.
- Today active commitment check-in state.
- Reflect locked state when no active commitment exists.
- Reflect composer appears only when eligible.
- Reflect hangout strip is commitment-scoped.
- Commit nudge slider respects min/max.
- Tribe pulse renders aggregate activity.
- Tribe invite and retake compass actions are visible.
- Grow renders visual journey timeline.
- Grow renders daily faith question and daily spiritual insight.
- Grow answer field persists answered state.

### Flutter Integration Tests

- New user completes onboarding to Today.
- User joins tribe, joins commitment, checks in, posts reflection.
- User reacts to another reflection.
- User creates or joins a commitment hangout.
- User answers daily faith question from Grow.
- Notification tap routes to Commit or Reflect as appropriate.

### Backend Feature Tests

- `/vision/bootstrap` returns launch payload.
- Tribe pulse is member-scoped and aggregate-only.
- Commitment feed remains member-scoped.
- Reflection one-per-day constraint.
- Reflection reactions include current user state.
- Commitment hangout create/join respects active membership.
- Hangout max participants enforced.
- Weekly ritual can post only on weekends.
- Weekly ritual bookmark/unbookmark works.
- Expired unbookmarked weekly reflections are hidden/deleted.
- Daily question answer upserts once per day.
- Growth journey endpoint derives expected events.

### Manual QA

- Small phone layout.
- Large phone layout.
- Dark mode.
- Slow network.
- Offline after bootstrap.
- Logged-out/expired token.
- Notification permission denied.
- No tribe.
- No commitment.
- Already posted reflection today.
- Hangout full.
- Weekend and weekday weekly ritual states.

## Production Rollout Plan

### Stage 1: Backend Contracts

- Add `/vision/bootstrap`.
- Add tribe pulse.
- Add commitment hangouts.
- Harden reflection feed.
- Harden weekly ritual.
- Add growth journey endpoint.
- Add daily insight/bookmark support if saving is included.

Exit criteria:

- Backend feature tests pass.
- API payloads documented in code or docs.
- Flutter can build all five tabs from real payloads.

### Stage 2: Flutter Vision Namespace

- Create `features/vision`.
- Rename models/providers/screens.
- Add route aliases and shell nav.
- Build five screens with production empty/error/loading states.

Exit criteria:

- No new `Mvp` names in Flutter vision code.
- Five-tab navigation works.
- Old routes redirect where needed.

### Stage 3: Core Loop Integration

- Onboarding -> tribe -> commitment -> Today.
- Today check-in -> Reflect.
- Reflect feed/reaction/composer.
- Commit nudge settings.
- Tribe pulse.
- Grow timeline/question/insight.

Exit criteria:

- Integration test covers full loop.
- Manual QA confirms no dead ends.

### Stage 4: Prune And Polish

- Remove old primary feature cards.
- Move profile/settings behind secondary affordance.
- Remove broad Grow hub content.
- Refine copy and micro-interactions.
- Verify notifications.
- Verify dark mode and small-device layout.

Exit criteria:

- Product feels cohesive.
- No old hub competes with the five-tab vision.
- All launch acceptance criteria pass.

### Stage 5: Launch Hardening

- Run Flutter tests.
- Run backend tests.
- Run static analysis.
- Run manual smoke on release profile build.
- Review analytics and logging.
- Verify migration/seed state in production-like environment.

## Cutover Acceptance Criteria

- Bottom nav exactly reads `Today | Reflect | Commit | Tribe | Grow`.
- No user-facing text says "MVP".
- No new production Flutter classes/providers/routes use `Mvp` naming.
- User can complete onboarding into a tribe and commitment.
- Commitment check-in works from Today, Commit, and notification action.
- Reflect is locked or contextual without an active commitment.
- Reflect feed is visible only to members of the same active commitment.
- Users can post at most one reflection per commitment per day.
- Reflect hangouts are commitment-scoped by default.
- Hangout create/join/end states are production-safe.
- Users can choose 3 to 10 nudges within each commitment's backend bounds.
- Tribe page shows daily aggregate pulse plus invite and retake compass actions.
- Grow shows a visual spiritual growth journey.
- Grow provides daily faith question access.
- Grow provides daily spiritual insight with the four required perspectives.
- Weekly ritual works on weekends and clearly communicates closed state on weekdays.
- Offline/error states are designed across all five tabs.
- Tests cover the primary loop.

## Risks And Mitigations

- Risk: Refactor becomes a rename without product simplification.
  - Mitigation: Remove old feature promotion from primary screens before launch.

- Risk: Grow becomes another generic dashboard.
  - Mitigation: Treat Grow as story/timeline plus daily question/insight. No broad feature grid.

- Risk: Hangouts become generic community rooms.
  - Mitigation: Default and primary scope is active commitment. Hide everyone-scope until moderation is ready.

- Risk: Backend route file complexity causes regressions.
  - Mitigation: Add route aliases carefully with feature tests before Flutter migration.

- Risk: Flutter fallback data creates fake production truth.
  - Mitigation: Use fallback only for development or explicit offline read-only states.

- Risk: Assessment is too heavy for onboarding.
  - Mitigation: Build a short production compass from archetype data and allow reassessment later.

- Risk: Notifications feel aggressive.
  - Mitigation: User chooses 3 to 10 nudges, copy is gentle, and permission timing is contextual.

- Risk: Social features create comparison or shame.
  - Mitigation: Aggregate tribe pulse, no leaderboards, no public feed, no ranking.

## Immediate Next Implementation Slice

The first coding slice should be small but decisive:

1. Add production route constants for `/reflect`, `/commit`, and `/tribe`.
2. Update bottom navigation labels to `Today | Reflect | Commit | Tribe | Grow`.
3. Create `features/vision` with renamed domain models and repository wrapper.
4. Split the current commitment/reflection UI into basic `CommitScreen` and `ReflectScreen`.
5. Replace the current bottom-nav Grow target with a simplified `GrowScreen` showing growth journey placeholder from real available state plus daily question/insight.
6. Add redirects from old challenge/tribes/questions routes.
7. Add widget tests for bottom nav and the three split surfaces.

This creates the new product spine first. Backend hangouts, tribe pulse, and growth journey endpoints can then land behind the correct UX structure without fighting the old navigation.
