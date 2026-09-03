# Range Detail Tracker — Design Spec

Date: 2026-09-03

## Purpose

A native Mac app used on an air cadets shooting range to track which
practice (shoot) is being fired next and which cadets are on that
detail. Replaces manual/paper tracking of progression and lane
assignment during a live range session.

## Domain concepts

- **Practice** — a single named shoot in a progressive sequence
  configured for the session (e.g. `AR1`, `AR2`, `AR3` or `GP1`,
  `GP3`, `GP5`). Practices have an explicit order; a cadet may not
  attempt a later practice until they have passed every practice
  before it in that order.
- **Session** — one range day: a lane count, an ordered list of
  practices, a cadet roster, and the history of details fired.
- **Lane** — a numbered firing point, 1 up to a configurable maximum
  of 10. A lane can be toggled out of commission at any point during
  a session and back into commission later.
- **Detail** — one firing round: an assignment of cadets to active
  lanes, each paired with the practice they are firing. Once a detail
  is confirmed as fired, it is an immutable historical record; pass/
  fail results are recorded against it.
- **Cadet** — a roster member with a pass/fail/not-attempted result
  per practice for the session, used to compute their current
  progression.

## Progression rule

A cadet's **current practice** is the first practice (in configured
order) they have not yet passed. A fail leaves this unchanged — they
are due to repeat the same practice next time they're placed in a
detail. There is no automatic retry limit; a human always decides
when to move a struggling cadet on (see manual override below).

A cadet who has passed every configured practice does not stop being
scheduled: their current practice resolves to the **final** practice
in the sequence, indefinitely, and they continue to compete for lanes
under the normal fairness rule alongside cadets still progressing.
Each further firing of the final practice is recorded as its own
attempt (see data model), so there is a full history of every time
they fired it, not just the qualifying pass.

## Data model (SwiftData)

```
Session
  id: UUID
  date: Date
  laneCount: Int            // 1...10
  practices: [Practice]     // ordered
  cadets: [Cadet]
  lanes: [Lane]
  details: [Detail]         // fired-detail history, append-only

Practice
  id: UUID
  name: String              // e.g. "GP1"
  order: Int                // progression sequence, 0-based

Lane
  number: Int                // 1...10
  active: Bool               // toggle for in/out of commission

Cadet
  id: UUID
  name: String
  attempts: [PracticeAttempt]      // full attempt history, one row per firing
  nextOverridePracticeID: UUID?    // one-shot manual override, cleared after use

PracticeAttempt
  practiceID: UUID
  detailID: UUID              // which detail this attempt was fired in
  outcome: Outcome            // .pass | .fail
  firedAt: Date

Detail
  id: UUID
  sequenceNumber: Int
  firedAt: Date
  assignments: [LaneAssignment]   // immutable once the detail is confirmed fired

LaneAssignment
  laneNumber: Int
  cadetID: UUID
  practiceID: UUID
  outcome: Outcome?          // nil until result entered; then .pass | .fail
```

## Detail generation algorithm

A pure function, independent of SwiftData and UI, so it can be unit
tested directly:

```
nextDetail(cadets, practices, lanes, history) -> DraftDetail
```

1. Consider only lanes where `active == true`.
2. For each cadet, resolve their practice for this detail: their
   one-shot override if set, otherwise their current practice per the
   progression rule (which resolves to the final practice for cadets
   who have completed progression).
3. Group eligible cadets by resolved practice.
4. Within each practice group, rank cadets by fairness: longest time
   since their last fired detail first, then fewest details fired
   this session.
5. Fill active lanes in **contiguous blocks per practice** — each
   practice occupies a contiguous run of lane numbers within the
   detail — taking the top-ranked cadets from each group until lanes
   are exhausted. Cadets not placed remain eligible and wait for the
   next detail.
6. This produces a `DraftDetail`, recomputed live whenever lane
   state, roster, or results change — it is not a one-time
   suggestion, it is always "what would fire right now."

There is no separate "complete and excluded" state — a cadet who has
passed every practice keeps cycling through step 5 on the final
practice, same as any other cadet, and is only left idle if lanes run
out (same as anyone else waiting).

## Detail lifecycle: draft, edit, confirm

The `DraftDetail` shown to the range control officer (RCO) is fully
editable before it is fired:

- The RCO can change any lane's assigned cadet and/or practice,
  clear a lane, or pull a cadet out — directly on the draft.
- Edits apply to this draft only; they do not persist as a rule.
  Once this detail is confirmed and recorded, the *next* draft is
  computed fresh from the algorithm (step 1 above), not from the
  edited state.
- If the RCO wants to nudge the algorithm's future behaviour for a
  specific cadet (e.g. hold them back, or let them skip ahead despite
  a fail), they set that cadet's one-shot override, which is
  consumed the next time that cadet is scheduled.
- Confirming a draft turns it into a `Detail` record (immutable
  history) with `outcome == nil` per lane, ready for results entry.

## Results entry

After a detail is confirmed as fired, the RCO records pass/fail per
lane. Entering a result:
- Sets the `outcome` on that `LaneAssignment`.
- Appends a new `PracticeAttempt` to the cadet's history for that
  practice (so repeat firings — including repeats of an
  already-passed final practice — are all individually recorded).
- Immediately triggers recomputation of the live draft "up next"
  detail (fairness/progression state has changed).

## Screens

1. **Session Setup**
   - Set lane count (1–10).
   - Define the ordered list of practices for this session (name +
     order), free-form so any naming scheme (`AR1..AR5`, `GP1,GP3,
     GP5`, etc.) works.
   - Add the cadet roster (names).
   - Starting the session creates the `Session`, `Lane` rows, and
     `Cadet` rows and moves to Range View.

2. **Range View** (main working screen, single screen for the whole
   session)
   - **Lane grid**: one tile per lane (1..laneCount), each with an
     active/out-of-commission toggle, and — when active — the current
     draft detail's cadet + practice for that lane.
   - **Draft detail panel**: editable view of the live "up next"
     detail (per the lifecycle above), with a "Confirm Fired" action
     that locks it in and switches lanes into results-entry mode
     (pass/fail buttons per lane) until all fired lanes have a
     result, at which point a new draft is computed.
   - **Roster/progression panel**: always visible alongside the lane
     grid and draft — a table of cadets × practices showing each
     cadet's outcome per practice and their current practice, so the
     RCO has full context while editing a draft or deciding a manual
     override.
   - **History**: a scrollable log of past fired details below/behind
     the main panel, for reference.

## Persistence

- SwiftData, autosaved on every change — no explicit save action.
- All app data is local-only (no network, no sync).

## Edge cases

- No eligible cadets for an active lane → lane tile shows an empty/
  idle state rather than blocking the rest of the draft.
- Reducing lane count, or toggling lanes out of commission, never
  alters already-fired `Detail` history — only affects future
  scheduling.
- All cadets complete (passed every practice) → the draft detail is
  not empty; every cadet resolves to the final practice and details
  keep being generated as normal, one contiguous block on that
  practice.

## Testing approach

Per TDD: the `nextDetail` algorithm is the core logic and gets
thorough red-green unit tests first, covering:
- Progression blocking (can't skip ahead without passing prior
  practice).
- Fairness ordering (least-recent, then fewest-fired-today).
- Contiguous per-practice lane grouping.
- Out-of-commission lane exclusion, including lanes toggled mid-
  session.
- One-shot manual override consumption.
- Completed cadets (passed every practice) resolve to the final
  practice and keep being scheduled, competing fairly with
  still-progressing cadets, with each firing recorded as a separate
  attempt.

UI is smoke-tested manually in the running app (SwiftUI previews +
manual exercise of Session Setup → Range View → confirm/results
flow).

## Out of scope (YAGNI)

- Reusable practice templates across sessions (fresh config per
  session per current requirement).
- Cloud sync / multi-device.
- Configurable fail-retry limits (may revisit if it becomes a real
  need).
- Authentication/multi-user — single RCO operating the app locally.
