# Core Flow Persona And Copy Audit

Last updated: 2026-05-10

Scope: signup -> identity/compass -> tribe join -> commitment and nudge setting -> daily nudges -> daily check-in -> reflection -> tribe hangout -> invite/support.

## Flow Read

| Step | Current Intent | Review Status | Notes |
| --- | --- | --- | --- |
| First impression | Calmly explain identity, belonging, commitment, reflection, growth. | Strong | Opening screens now communicate the core loop without duplicate light animations. |
| Signup/account | Capture account after compass and summarize starting point. | Fixed copy | Removed lingering "first path" language; summary shows identity, commitment direction, private age band, spiritual age. |
| Identity/compass | Use exact age privately, derive age band, calculate archetype and spiritual age. | Strong | Payload now carries compass result, action plan, archetype profile, spiritual story metadata. |
| Visibility | Let users choose anonymous, initials, nickname, or visible profile before reflection/community. | Improved | Copy says reflections are commitment-scoped and no longer uses "Public profile" language in the core flow. |
| Tribe join | Confirm recommended tribe and show compass context. | Good | Tribe join copy emphasizes belonging before performance. |
| Commitment selection | One active commitment, nudge count, daily action. | Good | Copy consistently says commitment, check-in, and nudge rhythm. |
| Daily nudges | Local notifications prompt the active commitment. | Improved | Nudges now repeat daily, restart tomorrow after today's check-in, include the user's remembered plan where available, and surface an in-app recovery panel when notifications appear disabled. |
| Daily check-in | One tap from Today/Commit/notification. | Good | Check-in is framed as the center; reflection is optional. |
| Reflection | Commitment-scoped, one honest post after check-in. | Good | No hangout wording in Reflect. Feed copy is constructive and bounded. |
| Tribe hangout | Tribe-owned live audio rooms. | Improved | Hangout room now has an "Invite someone" action. Tribe screen owns creation/joining. |
| Invite | Invite existing/new people. | Improved | Invite screen no longer imports contacts automatically; user chooses contact import. Copy is less generic "friends," and invite entry points now carry tribe/hangout/commitment context where available. |

## Persona Scenarios

| Persona | Scenario | What Works | Gaps / Watchpoints |
| --- | --- | --- | --- |
| Busy professional | Wants a fast path into one commitment with minimal social exposure. | Anonymous visibility, one commitment, low nudge count, optional reflection. | The first check-in plan is now persisted locally and sent to backend on commitment join, then resurfaced in Today, Commit, and nudge copy. |
| New believer / spiritually young | Needs low-shame language and a clear maturity story. | Spiritual age labels and soil/seed/fruit language are gentle; check-in is not performance. | Spiritual age could be misread as judgment if not repeatedly framed as a season, not worth. Current copy mostly does this. |
| Addiction / relapse-prone user | Needs private struggle sharing and stronger nudges without shame. | Reflection is gated behind check-in and scoped to commitment; nudges can be increased. | Reflection cards and hangout rooms now expose safety/report actions. Dedicated crisis-response policy copy can still be expanded later. |
| Teen / young adult | Exact age is sensitive. | Exact age is in-memory only; age band is persisted/sent. | No explicit minor-specific privacy or guardian policy copy in onboarding. |
| Privacy-sensitive user | Does not want contact import or public exposure. | Anonymous mode exists; invite contact import is user-initiated; "Visible profile" replaces "Public profile." | Keep monitoring whether users understand visible scope as tribe/commitment limited. |
| Isolated user | Has no trusted community yet. | Tribe recommendations, fallback tribes, invite flow, and hangouts provide entry points. | Fallback tribes now include a compass-tied local match reason when archetypes are available. |
| Socially anxious user | Afraid reflection/hangout means public vulnerability. | Reflect copy says commitment-scoped and "one honest sentence if it helps." | Hangout rooms now show small-room agreements and invite context. Creation copy can still be polished after real usage. |
| Highly motivated user | Wants more than one commitment. | Library explains one commitment at a time. | No preview of "next season" scheduling beyond browsing the library. |
| Returning user after missed days | Needs non-shaming re-entry. | Nudge copy says missed nudges are information, not condemnation. | A missed-day recovery state could be more explicit in Today/Commit if backend exposes missed streak data. |
| User invited by another user | Needs context before signup. | Invite route exists and entry points carry source context. | Public invite acceptance screens can later show inviter identity and exact destination before signup. |

## Findings Fixed In This Pass

- Replaced remaining visible "path" copy in account and Today core surfaces with "commitment" or "rhythm."
- Replaced commitment nudge notification channel copy from "return" to "check in."
- Made commitment nudges repeat daily with `DateTimeComponents.time`.
- After a successful check-in, local nudges are rescheduled to begin tomorrow so remaining same-day nudges do not keep pressing the user.
- Added "Invite someone" from the live hangout room.
- Made contact importing explicit on the Invite screen instead of automatic.
- Fixed invite button count so manual email and phone count separately.
- Persisted first check-in plan context locally and in the commitment join backend contract.
- Resurfaced the remembered plan in Today, Commit, and commitment nudge notification copy.
- Added notification permission recovery UI for active commitments.
- Renamed visible "Public profile" core copy to "Visible profile."
- Added reflection and hangout report actions backed by a server-side safety report table.
- Added contextual invite payloads and contextual invite screen copy for tribe, hangout, and commitment entry points.
- Added compass-tied fallback tribe explanations when remote recommendations are unavailable.

## Remaining Product Questions

These are not quick copy fixes; they need product or backend decisions.

| Priority | Question | Why It Matters |
| --- | --- | --- |
| High | What exact moderation operations should happen after a report: hide immediately, queue for review, notify admins, or rate-limit repeat offenders? | The reporting path exists; operational policy still determines how safe the community becomes. |
| Medium | Should public invite acceptance screens show inviter name, tribe name, hangout title, and commitment title before signup? | Outbound invites now carry context, but inbound pre-signup context still depends on future public invite handling. |
| Medium | Should notification recovery deep-link directly to OS settings after denial/permanent denial? | The app requests permissions again; a platform-specific settings fallback could make recovery stronger. |
| Low | Should missed-day recovery copy be backed by explicit streak/missed-day backend fields? | Current copy is non-shaming, but more precise recovery states need backend missed-day semantics. |
