# Range Detail Tracker

A native macOS app for a Range Control Officer (RCO) to run a progressive
shooting practice session on an air cadets (RAFAC) range: it works out which
detail fires next, who's on it, records scores, and produces an end-of-session
butt register.

## What it does

- **Progressive practices** — configure a sequence of practices for the
  session (e.g. `AR1`–`AR5`, or `GP1`, `GP3`, `GP5`). A cadet can't fire a
  later practice without having passed an earlier one.
- **Fair, automatic detailing** — each "detail" (a batch of simultaneous
  firings, one per lane) is generated automatically from the roster's current
  progression, rotating cadets fairly across who's waited longest.
- **Live lane view** — one card per lane shows who's on it right now with an
  inline score field, who's prepped for the next detail so they can get
  ready, and a toggle to take the lane out of commission.
- **Manual overrides** — an RCO can hand-edit a lane's cadet/practice for the
  next detail, or override which practice a specific cadet fires next.
- **Scoring** — supports both standard pass-mark scoring and two-stage
  zeroing (ES/PV) scoring per practice. A score of `0` always means the
  practice wasn't actually fired (e.g. a stoppage) and is recorded as a fail.
- **History** — a pivot table of every cadet against every detail fired so
  far, colour-coded pass/fail, showing which practice they fired.
- **Butt register** — an exportable (CSV) end-of-session register of every
  cadet, every detail they fired, and their score.
- **Session persistence** — the session autosaves to disk and resumes where
  you left off if the app is restarted.

## Requirements

- macOS 14.4+
- Swift 5.10+ / Xcode Command Line Tools (no full Xcode install required)

## Running the app

```sh
swift run RangeDetailTracker
```

## Running the tests

There's no XCTest/Swift Testing dependency — the project uses a small
hand-rolled test harness so it can run from the command line tools alone:

```sh
swift run RangeDetailTracker --run-tests
```

Pass a substring to run a subset of tests:

```sh
swift run RangeDetailTracker --run-tests ScoringRule
```

## Project layout

```
Sources/RangeDetailTracker/
  Domain/       Pure logic: progression, scoring, fairness, draft generation, butt register
  Models/       Persisted, @Observable session data (Codable, no SwiftData)
  Store/        SessionStore — bridges persisted models to the domain layer
  Views/        SwiftUI views
  Tests/        Hand-rolled unit tests (see TestSupport/)
```

The domain layer (`Domain/`) has no dependency on SwiftUI or persistence, so
progression, scoring, and detailing logic can be tested in isolation.
