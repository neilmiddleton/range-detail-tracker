# Range Detail Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Mac app that tracks progressive shooting practices on an air cadets range — proposing the next detail (which practice, which cadets, which lanes), recording scores, and producing a butt register at the end of the session.

**Architecture:** SwiftUI + SwiftData, built as a Swift Package Manager executable app (no `.xcodeproj`, no external dependencies). A pure, SwiftData-independent domain layer (`Domain/`) implements progression, scoring, fairness, and detail-generation as plain functions over value types — this is what gets thorough unit tests. SwiftData `@Model` classes (`Models/`) handle persistence only. A `SessionStore` bridges the two: it reads SwiftData models into domain snapshots, calls the pure functions, and writes results back. SwiftUI views are thin and manually smoke-tested, per the spec's testing approach.

**Tech Stack:** Swift 5.10+, SwiftUI, SwiftData, XCTest, macOS 14+ (`.v14` platform minimum, required for SwiftData).

**Spec:** `docs/superpowers/specs/2026-09-03-range-detail-tracker-design.md`

## Global Constraints

- macOS native app: SwiftUI + SwiftData only. No third-party dependencies — SPM executable target, no external packages added.
- Lane count is configurable per session, 1–10.
- Practices are configured fresh each session (no cross-session templates), each with an explicit order, free-form name, and a scoring type.
- Progression: a cadet's current practice is the first practice in order they have not passed; a fail repeats the same practice; a cadet cannot skip ahead.
- A cadet who has passed every practice resolves to the **final** practice indefinitely and keeps competing for lanes under the fairness rule — never excluded from scheduling.
- Fairness ranking within a practice group: longest since last fired detail first, then fewest details fired this session.
- A detail fills active lanes in **contiguous blocks per practice** (each practice occupies a contiguous run of lane numbers).
- The draft "up next" detail is always live-recomputed and fully editable (swap cadet/practice per lane) before confirming; edits apply only to that one draft, never persisted as a rule.
- Each cadet has one one-shot manual override for their next scheduled practice, consumed only when they are actually placed in a confirmed detail.
- Scoring: **standard** practices take one score compared to a configured pass mark; **zeroing** practices take ES and PV scores, each compared to its own pass mark — both must pass for the practice to pass.
- Pass/fail is always derived from recorded score(s), never entered directly.
- Every firing (including repeats of an already-passed final practice) is recorded individually — no overwriting — to feed the butt register.
- Persistence is local-only; SwiftData autosaves on every change, no explicit save action.
- Butt register: on-screen table ordered by detail, plus CSV export.

---

## File Structure

```
Package.swift
Sources/RangeDetailTracker/
  RangeDetailTrackerApp.swift          // @main, SwiftData ModelContainer, root view
  Models/
    ScoringType.swift                  // enum, shared by Models and Domain
    Outcome.swift                      // enum, shared by Models and Domain
    Session.swift                      // @Model
    Practice.swift                     // @Model
    Lane.swift                         // @Model
    Cadet.swift                        // @Model
    Detail.swift                       // @Model
    Firing.swift                       // @Model
  Domain/
    PracticeSnapshot.swift
    CadetSnapshot.swift
    LaneSnapshot.swift
    FiringRecord.swift
    ScoringRule.swift                  // pure: derive Outcome from score(s)
    ProgressionRule.swift              // pure: current practice / hasPassed
    FairnessRanking.swift              // pure: rank cadet IDs
    DraftDetail.swift                  // DraftFiring, DraftDetail structs
    DraftDetailGenerator.swift         // pure: nextDetail(...)
    ButtRegisterRow.swift
    ButtRegisterBuilder.swift          // pure: Session -> [ButtRegisterRow]
    ButtRegisterCSVExporter.swift      // pure: [ButtRegisterRow] -> CSV String
  Store/
    SessionStore.swift                 // SwiftData <-> Domain bridge, @Observable
  Views/
    SessionSetupView.swift
    RangeView.swift
    LaneGridView.swift
    RosterPanelView.swift
    DraftDetailPanelView.swift
    ResultsEntryView.swift
    DetailHistoryView.swift
    ButtRegisterView.swift
Tests/RangeDetailTrackerTests/
  ModelPersistenceTests.swift
  ScoringRuleTests.swift
  ProgressionRuleTests.swift
  FairnessRankingTests.swift
  DraftDetailGeneratorTests.swift
  SessionStoreTests.swift
  ButtRegisterTests.swift
```

---

### Task 1: Project scaffold and SwiftData models

**Files:**
- Create: `Package.swift`
- Create: `Sources/RangeDetailTracker/RangeDetailTrackerApp.swift`
- Create: `Sources/RangeDetailTracker/Models/ScoringType.swift`
- Create: `Sources/RangeDetailTracker/Models/Outcome.swift`
- Create: `Sources/RangeDetailTracker/Models/Session.swift`
- Create: `Sources/RangeDetailTracker/Models/Practice.swift`
- Create: `Sources/RangeDetailTracker/Models/Lane.swift`
- Create: `Sources/RangeDetailTracker/Models/Cadet.swift`
- Create: `Sources/RangeDetailTracker/Models/Detail.swift`
- Create: `Sources/RangeDetailTracker/Models/Firing.swift`
- Test: `Tests/RangeDetailTrackerTests/ModelPersistenceTests.swift`

**Interfaces:**
- Produces: `ScoringType` (`.standard`, `.zeroing`), `Outcome` (`.pass`, `.fail`) — used by every later task.
- Produces: `Session`, `Practice`, `Lane`, `Cadet`, `Detail`, `Firing` SwiftData model classes, each with `id: UUID` (except `Lane`, keyed by `number`), used by `SessionStore` (Task 6) and all views.

- [ ] **Step 1: Create the package manifest**

`Package.swift`:
```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RangeDetailTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RangeDetailTracker",
            path: "Sources/RangeDetailTracker"
        ),
        .testTarget(
            name: "RangeDetailTrackerTests",
            dependencies: ["RangeDetailTracker"],
            path: "Tests/RangeDetailTrackerTests"
        ),
    ]
)
```

- [ ] **Step 2: Write the shared enums**

`Sources/RangeDetailTracker/Models/ScoringType.swift`:
```swift
enum ScoringType: String, Codable, CaseIterable {
    case standard
    case zeroing
}
```

`Sources/RangeDetailTracker/Models/Outcome.swift`:
```swift
enum Outcome: String, Codable {
    case pass
    case fail
}
```

- [ ] **Step 3: Write the SwiftData models**

`Sources/RangeDetailTracker/Models/Practice.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Practice {
    var id: UUID
    var name: String
    var order: Int
    var scoringType: ScoringType
    var passMark: Int?
    var esPassMark: Int?
    var pvPassMark: Int?
    var session: Session?

    init(
        id: UUID = UUID(),
        name: String,
        order: Int,
        scoringType: ScoringType,
        passMark: Int? = nil,
        esPassMark: Int? = nil,
        pvPassMark: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.scoringType = scoringType
        self.passMark = passMark
        self.esPassMark = esPassMark
        self.pvPassMark = pvPassMark
    }
}
```

`Sources/RangeDetailTracker/Models/Lane.swift`:
```swift
import SwiftData

@Model
final class Lane {
    var number: Int
    var active: Bool
    var session: Session?

    init(number: Int, active: Bool = true) {
        self.number = number
        self.active = active
    }
}
```

`Sources/RangeDetailTracker/Models/Cadet.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Cadet {
    var id: UUID
    var name: String
    var nextOverridePracticeID: UUID?
    var session: Session?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
```

`Sources/RangeDetailTracker/Models/Firing.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Firing {
    var id: UUID
    var laneNumber: Int
    var cadetID: UUID
    var practiceID: UUID
    var score: Int?
    var esScore: Int?
    var pvScore: Int?
    var outcome: Outcome?
    var detail: Detail?

    init(id: UUID = UUID(), laneNumber: Int, cadetID: UUID, practiceID: UUID) {
        self.id = id
        self.laneNumber = laneNumber
        self.cadetID = cadetID
        self.practiceID = practiceID
    }
}
```

`Sources/RangeDetailTracker/Models/Detail.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Detail {
    var id: UUID
    var sequenceNumber: Int
    var firedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Firing.detail)
    var firings: [Firing]
    var session: Session?

    init(id: UUID = UUID(), sequenceNumber: Int, firedAt: Date = .now) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.firedAt = firedAt
        self.firings = []
    }
}
```

`Sources/RangeDetailTracker/Models/Session.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var date: Date
    var laneCount: Int
    @Relationship(deleteRule: .cascade, inverse: \Practice.session)
    var practices: [Practice]
    @Relationship(deleteRule: .cascade, inverse: \Cadet.session)
    var cadets: [Cadet]
    @Relationship(deleteRule: .cascade, inverse: \Lane.session)
    var lanes: [Lane]
    @Relationship(deleteRule: .cascade, inverse: \Detail.session)
    var details: [Detail]

    init(id: UUID = UUID(), date: Date = .now, laneCount: Int) {
        self.id = id
        self.date = date
        self.laneCount = laneCount
        self.practices = []
        self.cadets = []
        self.lanes = []
        self.details = []
    }
}
```

- [ ] **Step 4: Write a placeholder app entry point**

`Sources/RangeDetailTracker/RangeDetailTrackerApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct RangeDetailTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Range Detail Tracker")
                .padding()
        }
        .modelContainer(for: [
            Session.self, Practice.self, Lane.self, Cadet.self, Detail.self, Firing.self,
        ])
    }
}
```

- [ ] **Step 5: Write the failing smoke test**

`Tests/RangeDetailTrackerTests/ModelPersistenceTests.swift`:
```swift
import XCTest
import SwiftData
@testable import RangeDetailTracker

final class ModelPersistenceTests: XCTestCase {
    func testModelsPersistAndFetchInMemory() throws {
        let schema = Schema([Session.self, Practice.self, Lane.self, Cadet.self, Detail.self, Firing.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let session = Session(laneCount: 5)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let lane = Lane(number: 1)
        let cadet = Cadet(name: "Test Cadet")
        session.practices.append(practice)
        session.lanes.append(lane)
        session.cadets.append(cadet)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.practices.count, 1)
        XCTAssertEqual(fetched.first?.lanes.first?.number, 1)
    }
}
```

- [ ] **Step 6: Run the test to verify the project builds and the test passes**

Run: `swift test --filter ModelPersistenceTests`
Expected: PASS (this is scaffolding, not red/green — first run should already pass since the models are written; the point of running it is confirming the package builds and SwiftData schema is valid).

- [ ] **Step 7: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "Scaffold SPM app and SwiftData models"
```

---

### Task 2: Domain snapshots and scoring rule

**Files:**
- Create: `Sources/RangeDetailTracker/Domain/PracticeSnapshot.swift`
- Create: `Sources/RangeDetailTracker/Domain/CadetSnapshot.swift`
- Create: `Sources/RangeDetailTracker/Domain/LaneSnapshot.swift`
- Create: `Sources/RangeDetailTracker/Domain/FiringRecord.swift`
- Create: `Sources/RangeDetailTracker/Domain/ScoringRule.swift`
- Test: `Tests/RangeDetailTrackerTests/ScoringRuleTests.swift`

**Interfaces:**
- Consumes: `ScoringType`, `Outcome` (Task 1).
- Produces: `PracticeSnapshot`, `CadetSnapshot`, `LaneSnapshot`, `FiringRecord` value types and `ScoringRule.outcome(for:score:esScore:pvScore:) -> Outcome?`, used by Task 3, 4, 5, 6.

- [ ] **Step 1: Write the snapshot value types**

`Sources/RangeDetailTracker/Domain/PracticeSnapshot.swift`:
```swift
import Foundation

struct PracticeSnapshot: Identifiable, Equatable {
    let id: UUID
    let name: String
    let order: Int
    let scoringType: ScoringType
    let passMark: Int?
    let esPassMark: Int?
    let pvPassMark: Int?
}
```

`Sources/RangeDetailTracker/Domain/CadetSnapshot.swift`:
```swift
import Foundation

struct CadetSnapshot: Identifiable, Equatable {
    let id: UUID
    let name: String
    let nextOverridePracticeID: UUID?
}
```

`Sources/RangeDetailTracker/Domain/LaneSnapshot.swift`:
```swift
struct LaneSnapshot: Identifiable, Equatable {
    var id: Int { number }
    let number: Int
    let active: Bool
}
```

`Sources/RangeDetailTracker/Domain/FiringRecord.swift`:
```swift
import Foundation

struct FiringRecord: Identifiable, Equatable {
    let id: UUID
    let detailID: UUID
    let sequenceNumber: Int
    let firedAt: Date
    let laneNumber: Int
    let cadetID: UUID
    let practiceID: UUID
    let score: Int?
    let esScore: Int?
    let pvScore: Int?
    let outcome: Outcome?
}
```

- [ ] **Step 2: Write the failing test**

`Tests/RangeDetailTrackerTests/ScoringRuleTests.swift`:
```swift
import XCTest
@testable import RangeDetailTracker

final class ScoringRuleTests: XCTestCase {
    func standardPractice(passMark: Int) -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "AR1", order: 0, scoringType: .standard, passMark: passMark, esPassMark: nil, pvPassMark: nil)
    }

    func zeroingPractice(esPassMark: Int, pvPassMark: Int) -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "Zeroing", order: 0, scoringType: .zeroing, passMark: nil, esPassMark: esPassMark, pvPassMark: pvPassMark)
    }

    func testStandardPassesAtExactPassMark() {
        let practice = standardPractice(passMark: 20)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 20, esScore: nil, pvScore: nil), .pass)
    }

    func testStandardFailsOneBelowPassMark() {
        let practice = standardPractice(passMark: 20)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 19, esScore: nil, pvScore: nil), .fail)
    }

    func testZeroingFailsIfEitherScoreBelowMark() {
        let practice = zeroingPractice(esPassMark: 10, pvPassMark: 10)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 15, pvScore: 5), .fail)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 5, pvScore: 15), .fail)
    }

    func testZeroingPassesOnlyWhenBothMeetMarks() {
        let practice = zeroingPractice(esPassMark: 10, pvPassMark: 10)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 10, pvScore: 10), .pass)
    }

    func testReturnsNilWhenScoresNotYetEntered() {
        let practice = standardPractice(passMark: 20)
        XCTAssertNil(ScoringRule.outcome(for: practice, score: nil, esScore: nil, pvScore: nil))
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --filter ScoringRuleTests`
Expected: FAIL to compile — `ScoringRule` not defined.

- [ ] **Step 4: Write the minimal implementation**

`Sources/RangeDetailTracker/Domain/ScoringRule.swift`:
```swift
enum ScoringRule {
    static func outcome(for practice: PracticeSnapshot, score: Int?, esScore: Int?, pvScore: Int?) -> Outcome? {
        switch practice.scoringType {
        case .standard:
            guard let score, let passMark = practice.passMark else { return nil }
            return score >= passMark ? .pass : .fail
        case .zeroing:
            guard let esScore, let pvScore,
                  let esPassMark = practice.esPassMark,
                  let pvPassMark = practice.pvPassMark
            else { return nil }
            return (esScore >= esPassMark && pvScore >= pvPassMark) ? .pass : .fail
        }
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `swift test --filter ScoringRuleTests`
Expected: PASS (5 tests)

- [ ] **Step 6: Commit**

```bash
git add Sources/RangeDetailTracker/Domain Tests/RangeDetailTrackerTests/ScoringRuleTests.swift
git commit -m "Add domain snapshots and score-based pass/fail derivation"
```

---

### Task 3: Progression rule

**Files:**
- Create: `Sources/RangeDetailTracker/Domain/ProgressionRule.swift`
- Test: `Tests/RangeDetailTrackerTests/ProgressionRuleTests.swift`

**Interfaces:**
- Consumes: `PracticeSnapshot`, `FiringRecord`, `Outcome` (Task 2).
- Produces: `ProgressionRule.hasPassed(practiceID:cadetID:firings:) -> Bool` and `ProgressionRule.currentPractice(for:practices:firings:) -> PracticeSnapshot?`, used by Task 5.

- [ ] **Step 1: Write the failing test**

`Tests/RangeDetailTrackerTests/ProgressionRuleTests.swift`:
```swift
import XCTest
@testable import RangeDetailTracker

final class ProgressionRuleTests: XCTestCase {
    let ar1 = PracticeSnapshot(id: UUID(), name: "AR1", order: 0, scoringType: .standard, passMark: 20, esPassMark: nil, pvPassMark: nil)
    let ar2 = PracticeSnapshot(id: UUID(), name: "AR2", order: 1, scoringType: .standard, passMark: 20, esPassMark: nil, pvPassMark: nil)
    let ar3 = PracticeSnapshot(id: UUID(), name: "AR3", order: 2, scoringType: .standard, passMark: 20, esPassMark: nil, pvPassMark: nil)

    func firing(cadetID: UUID, practiceID: UUID, outcome: Outcome) -> FiringRecord {
        FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 1, cadetID: cadetID, practiceID: practiceID, score: 20, esScore: nil, pvScore: nil, outcome: outcome)
    }

    func testCurrentPracticeIsFirstUnpassedPractice() {
        let cadetID = UUID()
        let firings = [firing(cadetID: cadetID, practiceID: ar1.id, outcome: .pass)]
        let current = ProgressionRule.currentPractice(for: cadetID, practices: [ar1, ar2, ar3], firings: firings)
        XCTAssertEqual(current?.id, ar2.id)
    }

    func testCurrentPracticeStaysSameAfterFail() {
        let cadetID = UUID()
        let firings = [firing(cadetID: cadetID, practiceID: ar1.id, outcome: .fail)]
        let current = ProgressionRule.currentPractice(for: cadetID, practices: [ar1, ar2, ar3], firings: firings)
        XCTAssertEqual(current?.id, ar1.id)
    }

    func testCannotSkipAheadEvenIfLaterPracticeSomehowPassed() {
        let cadetID = UUID()
        let firings = [firing(cadetID: cadetID, practiceID: ar3.id, outcome: .pass)]
        let current = ProgressionRule.currentPractice(for: cadetID, practices: [ar1, ar2, ar3], firings: firings)
        XCTAssertEqual(current?.id, ar1.id)
    }

    func testCompletedCadetResolvesToFinalPractice() {
        let cadetID = UUID()
        let firings = [
            firing(cadetID: cadetID, practiceID: ar1.id, outcome: .pass),
            firing(cadetID: cadetID, practiceID: ar2.id, outcome: .pass),
            firing(cadetID: cadetID, practiceID: ar3.id, outcome: .pass),
        ]
        let current = ProgressionRule.currentPractice(for: cadetID, practices: [ar1, ar2, ar3], firings: firings)
        XCTAssertEqual(current?.id, ar3.id)
    }

    func testNoPracticesReturnsNil() {
        XCTAssertNil(ProgressionRule.currentPractice(for: UUID(), practices: [], firings: []))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ProgressionRuleTests`
Expected: FAIL to compile — `ProgressionRule` not defined.

- [ ] **Step 3: Write the minimal implementation**

`Sources/RangeDetailTracker/Domain/ProgressionRule.swift`:
```swift
import Foundation

enum ProgressionRule {
    static func hasPassed(practiceID: UUID, cadetID: UUID, firings: [FiringRecord]) -> Bool {
        firings.contains { $0.cadetID == cadetID && $0.practiceID == practiceID && $0.outcome == .pass }
    }

    static func currentPractice(for cadetID: UUID, practices: [PracticeSnapshot], firings: [FiringRecord]) -> PracticeSnapshot? {
        let ordered = practices.sorted { $0.order < $1.order }
        guard let final = ordered.last else { return nil }
        for practice in ordered where !hasPassed(practiceID: practice.id, cadetID: cadetID, firings: firings) {
            return practice
        }
        return final
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ProgressionRuleTests`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add Sources/RangeDetailTracker/Domain/ProgressionRule.swift Tests/RangeDetailTrackerTests/ProgressionRuleTests.swift
git commit -m "Add progression rule: block skip-ahead, resolve completed cadets to final practice"
```

---

### Task 4: Fairness ranking

**Files:**
- Create: `Sources/RangeDetailTracker/Domain/FairnessRanking.swift`
- Test: `Tests/RangeDetailTrackerTests/FairnessRankingTests.swift`

**Interfaces:**
- Consumes: `FiringRecord` (Task 2).
- Produces: `FairnessRanking.rank(cadetIDs:firings:) -> [UUID]`, used by Task 5.

- [ ] **Step 1: Write the failing test**

`Tests/RangeDetailTrackerTests/FairnessRankingTests.swift`:
```swift
import XCTest
@testable import RangeDetailTracker

final class FairnessRankingTests: XCTestCase {
    func firing(cadetID: UUID, sequenceNumber: Int) -> FiringRecord {
        FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: sequenceNumber, firedAt: .now, laneNumber: 1, cadetID: cadetID, practiceID: UUID(), score: 20, esScore: nil, pvScore: nil, outcome: .pass)
    }

    func testNeverFiredCadetRanksBeforeFiredCadet() {
        let neverFired = UUID()
        let fired = UUID()
        let firings = [firing(cadetID: fired, sequenceNumber: 1)]
        let ranked = FairnessRanking.rank(cadetIDs: [fired, neverFired], firings: firings)
        XCTAssertEqual(ranked.first, neverFired)
    }

    func testLeastRecentlyFiredRanksFirst() {
        let firedLongAgo = UUID()
        let firedRecently = UUID()
        let firings = [
            firing(cadetID: firedLongAgo, sequenceNumber: 1),
            firing(cadetID: firedRecently, sequenceNumber: 3),
        ]
        let ranked = FairnessRanking.rank(cadetIDs: [firedRecently, firedLongAgo], firings: firings)
        XCTAssertEqual(ranked, [firedLongAgo, firedRecently])
    }

    func testFewestFiredCountBreaksRecencyTie() {
        let firedOnce = UUID()
        let firedTwice = UUID()
        let firings = [
            firing(cadetID: firedOnce, sequenceNumber: 2),
            firing(cadetID: firedTwice, sequenceNumber: 1),
            firing(cadetID: firedTwice, sequenceNumber: 2),
        ]
        // Both cadets last fired in detail 2 (a tie on recency); firedOnce has fired
        // fewer times overall, so should rank first.
        let ranked = FairnessRanking.rank(cadetIDs: [firedTwice, firedOnce], firings: firings)
        XCTAssertEqual(ranked, [firedOnce, firedTwice])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FairnessRankingTests`
Expected: FAIL to compile — `FairnessRanking` not defined.

- [ ] **Step 3: Write the minimal implementation**

`Sources/RangeDetailTracker/Domain/FairnessRanking.swift`:
```swift
import Foundation

enum FairnessRanking {
    /// Ranks cadet IDs: longest since last fired detail first (never fired ranks
    /// first of all), then fewest details fired this session, then a stable
    /// deterministic tiebreak.
    static func rank(cadetIDs: [UUID], firings: [FiringRecord]) -> [UUID] {
        func lastFiredSequence(_ cadetID: UUID) -> Int {
            firings.filter { $0.cadetID == cadetID }.map(\.sequenceNumber).max() ?? -1
        }
        func firedCount(_ cadetID: UUID) -> Int {
            firings.filter { $0.cadetID == cadetID }.count
        }
        return cadetIDs.sorted { a, b in
            let lastA = lastFiredSequence(a)
            let lastB = lastFiredSequence(b)
            if lastA != lastB { return lastA < lastB }
            let countA = firedCount(a)
            let countB = firedCount(b)
            if countA != countB { return countA < countB }
            return a.uuidString < b.uuidString
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FairnessRankingTests`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add Sources/RangeDetailTracker/Domain/FairnessRanking.swift Tests/RangeDetailTrackerTests/FairnessRankingTests.swift
git commit -m "Add fairness ranking: least-recent then fewest-fired"
```

---

### Task 5: Draft detail generator

**Files:**
- Create: `Sources/RangeDetailTracker/Domain/DraftDetail.swift`
- Create: `Sources/RangeDetailTracker/Domain/DraftDetailGenerator.swift`
- Test: `Tests/RangeDetailTrackerTests/DraftDetailGeneratorTests.swift`

**Interfaces:**
- Consumes: `CadetSnapshot`, `PracticeSnapshot`, `LaneSnapshot`, `FiringRecord` (Task 2), `ProgressionRule.currentPractice` (Task 3), `FairnessRanking.rank` (Task 4).
- Produces: `DraftFiring` (`laneNumber: Int`, `cadetID: UUID?`, `practiceID: UUID?`), `DraftDetail` (`firings: [DraftFiring]`), and `DraftDetailGenerator.nextDetail(cadets:practices:lanes:firings:) -> DraftDetail`, used by Task 6.

- [ ] **Step 1: Write the draft value types**

`Sources/RangeDetailTracker/Domain/DraftDetail.swift`:
```swift
import Foundation

struct DraftFiring: Identifiable, Equatable {
    var id: Int { laneNumber }
    let laneNumber: Int
    let cadetID: UUID?
    let practiceID: UUID?
}

struct DraftDetail: Equatable {
    let firings: [DraftFiring]
}
```

- [ ] **Step 2: Write the failing test**

`Tests/RangeDetailTrackerTests/DraftDetailGeneratorTests.swift`:
```swift
import XCTest
@testable import RangeDetailTracker

final class DraftDetailGeneratorTests: XCTestCase {
    let ar1 = PracticeSnapshot(id: UUID(), name: "AR1", order: 0, scoringType: .standard, passMark: 20, esPassMark: nil, pvPassMark: nil)
    let ar2 = PracticeSnapshot(id: UUID(), name: "AR2", order: 1, scoringType: .standard, passMark: 20, esPassMark: nil, pvPassMark: nil)

    func lanes(_ numbers: [Int], inactive: Set<Int> = []) -> [LaneSnapshot] {
        numbers.map { LaneSnapshot(number: $0, active: !inactive.contains($0)) }
    }

    func passedFiring(cadetID: UUID, practiceID: UUID) -> FiringRecord {
        FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 1, cadetID: cadetID, practiceID: practiceID, score: 25, esScore: nil, pvScore: nil, outcome: .pass)
    }

    func testFillsLanesFromSingleGroupUpToLaneCount() {
        let cadets = (1...5).map { _ in CadetSnapshot(id: UUID(), name: "Cadet", nextOverridePracticeID: nil) }
        let draft = DraftDetailGenerator.nextDetail(cadets: cadets, practices: [ar1], lanes: lanes([1, 2, 3]), firings: [])
        XCTAssertEqual(draft.firings.count, 3)
        XCTAssertTrue(draft.firings.allSatisfy { $0.practiceID == ar1.id })
    }

    func testGroupsPracticesInContiguousBlocks() {
        let behindCadet = CadetSnapshot(id: UUID(), name: "Behind", nextOverridePracticeID: nil)
        let onTrackCadets = (1...2).map { _ in CadetSnapshot(id: UUID(), name: "OnTrack", nextOverridePracticeID: nil) }
        let firings = onTrackCadets.map { passedFiring(cadetID: $0.id, practiceID: ar1.id) }
        let draft = DraftDetailGenerator.nextDetail(cadets: [behindCadet] + onTrackCadets, practices: [ar1, ar2], lanes: lanes([1, 2, 3]), firings: firings)
        XCTAssertEqual(draft.firings.sorted { $0.laneNumber < $1.laneNumber }.map(\.practiceID), [ar1.id, ar2.id, ar2.id])
    }

    func testExcludesOutOfCommissionLanes() {
        let cadets = (1...3).map { _ in CadetSnapshot(id: UUID(), name: "Cadet", nextOverridePracticeID: nil) }
        let draft = DraftDetailGenerator.nextDetail(cadets: cadets, practices: [ar1], lanes: lanes([1, 2, 3], inactive: [2]), firings: [])
        XCTAssertEqual(draft.firings.map(\.laneNumber).sorted(), [1, 3])
    }

    func testLeavesExcessLanesIdleWhenNotEnoughCadets() {
        let cadets = [CadetSnapshot(id: UUID(), name: "Only", nextOverridePracticeID: nil)]
        let draft = DraftDetailGenerator.nextDetail(cadets: cadets, practices: [ar1], lanes: lanes([1, 2, 3]), firings: [])
        XCTAssertEqual(draft.firings.filter { $0.cadetID != nil }.count, 1)
        XCTAssertEqual(draft.firings.filter { $0.cadetID == nil }.count, 2)
    }

    func testManualOverrideIsUsedInsteadOfProgression() {
        let cadet = CadetSnapshot(id: UUID(), name: "Held Back", nextOverridePracticeID: ar2.id)
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadet], practices: [ar1, ar2], lanes: lanes([1]), firings: [])
        XCTAssertEqual(draft.firings.first?.practiceID, ar2.id)
    }

    func testCompletedCadetPlacedOnFinalPractice() {
        let cadet = CadetSnapshot(id: UUID(), name: "Done", nextOverridePracticeID: nil)
        let firings = [
            passedFiring(cadetID: cadet.id, practiceID: ar1.id),
            passedFiring(cadetID: cadet.id, practiceID: ar2.id),
        ]
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadet], practices: [ar1, ar2], lanes: lanes([1]), firings: firings)
        XCTAssertEqual(draft.firings.first?.practiceID, ar2.id)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --filter DraftDetailGeneratorTests`
Expected: FAIL to compile — `DraftDetailGenerator` not defined.

- [ ] **Step 4: Write the minimal implementation**

`Sources/RangeDetailTracker/Domain/DraftDetailGenerator.swift`:
```swift
import Foundation

enum DraftDetailGenerator {
    static func nextDetail(
        cadets: [CadetSnapshot],
        practices: [PracticeSnapshot],
        lanes: [LaneSnapshot],
        firings: [FiringRecord]
    ) -> DraftDetail {
        let activeLanes = lanes.filter(\.active).sorted { $0.number < $1.number }
        guard !activeLanes.isEmpty, !practices.isEmpty else {
            return DraftDetail(firings: activeLanes.map { DraftFiring(laneNumber: $0.number, cadetID: nil, practiceID: nil) })
        }

        var practiceForCadet: [UUID: PracticeSnapshot] = [:]
        for cadet in cadets {
            if let overrideID = cadet.nextOverridePracticeID,
               let overridePractice = practices.first(where: { $0.id == overrideID }) {
                practiceForCadet[cadet.id] = overridePractice
            } else if let resolved = ProgressionRule.currentPractice(for: cadet.id, practices: practices, firings: firings) {
                practiceForCadet[cadet.id] = resolved
            }
        }

        var cadetIDsByPractice: [UUID: [UUID]] = [:]
        for cadet in cadets {
            guard let practice = practiceForCadet[cadet.id] else { continue }
            cadetIDsByPractice[practice.id, default: []].append(cadet.id)
        }
        for practiceID in cadetIDsByPractice.keys {
            cadetIDsByPractice[practiceID] = FairnessRanking.rank(cadetIDs: cadetIDsByPractice[practiceID] ?? [], firings: firings)
        }

        let orderedPractices = practices
            .sorted { $0.order < $1.order }
            .filter { !(cadetIDsByPractice[$0.id] ?? []).isEmpty }

        var draftFirings: [DraftFiring] = []
        var laneIndex = 0
        for practice in orderedPractices {
            var queue = cadetIDsByPractice[practice.id] ?? []
            while laneIndex < activeLanes.count, !queue.isEmpty {
                let cadetID = queue.removeFirst()
                draftFirings.append(DraftFiring(laneNumber: activeLanes[laneIndex].number, cadetID: cadetID, practiceID: practice.id))
                laneIndex += 1
            }
            if laneIndex >= activeLanes.count { break }
        }
        while laneIndex < activeLanes.count {
            draftFirings.append(DraftFiring(laneNumber: activeLanes[laneIndex].number, cadetID: nil, practiceID: nil))
            laneIndex += 1
        }

        return DraftDetail(firings: draftFirings.sorted { $0.laneNumber < $1.laneNumber })
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `swift test --filter DraftDetailGeneratorTests`
Expected: PASS (6 tests)

- [ ] **Step 6: Commit**

```bash
git add Sources/RangeDetailTracker/Domain/DraftDetail.swift Sources/RangeDetailTracker/Domain/DraftDetailGenerator.swift Tests/RangeDetailTrackerTests/DraftDetailGeneratorTests.swift
git commit -m "Add draft detail generator: contiguous per-practice lane filling"
```

---

### Task 6: Session store (SwiftData bridge)

**Files:**
- Create: `Sources/RangeDetailTracker/Store/SessionStore.swift`
- Test: `Tests/RangeDetailTrackerTests/SessionStoreTests.swift`

**Interfaces:**
- Consumes: `Session`, `Practice`, `Lane`, `Cadet`, `Detail`, `Firing` (Task 1), all `Domain` types and `DraftDetailGenerator.nextDetail`, `ScoringRule.outcome` (Tasks 2–5).
- Produces: `SessionStore` with `draftDetail: DraftDetail`, `displayedDraft: DraftDetail`, `confirmDraft()`, `editDraftLane(_:cadetID:practiceID:)`, `recordScore(firing:score:esScore:pvScore:)`, `toggleLane(_:)`, `setOverride(cadetID:practiceID:)` — used by all Views (Tasks 7–13).

- [ ] **Step 1: Write the failing tests**

`Tests/RangeDetailTrackerTests/SessionStoreTests.swift`:
```swift
import XCTest
import SwiftData
@testable import RangeDetailTracker

final class SessionStoreTests: XCTestCase {
    func makeStore(laneCount: Int = 2) throws -> (store: SessionStore, practice: Practice) {
        let schema = Schema([Session.self, Practice.self, Lane.self, Cadet.self, Detail.self, Firing.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let session = Session(laneCount: laneCount)
        let practice = Practice(name: "AR1", order: 0, scoringType: .standard, passMark: 20)
        session.practices.append(practice)
        for number in 1...laneCount {
            session.lanes.append(Lane(number: number))
        }
        session.cadets.append(Cadet(name: "Cadet A"))
        context.insert(session)
        try context.save()

        return (SessionStore(context: context, session: session), practice)
    }

    func testConfirmDraftCreatesDetailWithFirings() throws {
        let (store, _) = try makeStore(laneCount: 1)
        XCTAssertEqual(store.session.details.count, 0)
        store.confirmDraft()
        XCTAssertEqual(store.session.details.count, 1)
        XCTAssertEqual(store.session.details.first?.firings.count, 1)
    }

    func testRecordScoreSetsDerivedOutcome() throws {
        let (store, _) = try makeStore(laneCount: 1)
        store.confirmDraft()
        let firing = try XCTUnwrap(store.session.details.first?.firings.first)
        store.recordScore(firing: firing, score: 25, esScore: nil, pvScore: nil)
        XCTAssertEqual(firing.outcome, .pass)
    }

    func testToggleLaneRemovesLaneFromDraft() throws {
        let (store, _) = try makeStore(laneCount: 2)
        store.toggleLane(2)
        XCTAssertEqual(store.draftDetail.firings.map(\.laneNumber), [1])
    }

    func testConfirmDraftClearsConsumedOverride() throws {
        let (store, practice) = try makeStore(laneCount: 1)
        let cadet = try XCTUnwrap(store.session.cadets.first)
        store.setOverride(cadetID: cadet.id, practiceID: practice.id)
        XCTAssertEqual(cadet.nextOverridePracticeID, practice.id)
        store.confirmDraft()
        XCTAssertNil(cadet.nextOverridePracticeID)
    }

    func testEditDraftLaneOverridesForNextConfirmOnly() throws {
        let (store, _) = try makeStore(laneCount: 1)
        store.editDraftLane(1, cadetID: nil, practiceID: nil)
        XCTAssertNil(store.displayedDraft.firings.first?.cadetID)
        store.confirmDraft()
        XCTAssertEqual(store.session.details.first?.firings.count, 0)
        // Edits are one-shot: the next draft is computed fresh, not from the edited state.
        XCTAssertNotNil(store.draftDetail.firings.first?.cadetID)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SessionStoreTests`
Expected: FAIL to compile — `SessionStore` not defined.

- [ ] **Step 3: Write the minimal implementation**

`Sources/RangeDetailTracker/Store/SessionStore.swift`:
```swift
import Foundation
import Observation
import SwiftData

@Observable
final class SessionStore {
    private let context: ModelContext
    let session: Session
    private var manualEdits: [Int: DraftFiring] = [:]

    init(context: ModelContext, session: Session) {
        self.context = context
        self.session = session
    }

    private var practiceSnapshots: [PracticeSnapshot] {
        session.practices.map {
            PracticeSnapshot(id: $0.id, name: $0.name, order: $0.order, scoringType: $0.scoringType, passMark: $0.passMark, esPassMark: $0.esPassMark, pvPassMark: $0.pvPassMark)
        }
    }

    private var cadetSnapshots: [CadetSnapshot] {
        session.cadets.map { CadetSnapshot(id: $0.id, name: $0.name, nextOverridePracticeID: $0.nextOverridePracticeID) }
    }

    private var laneSnapshots: [LaneSnapshot] {
        session.lanes.map { LaneSnapshot(number: $0.number, active: $0.active) }
    }

    private var firingRecords: [FiringRecord] {
        session.details.flatMap { detail in
            detail.firings.map { firing in
                FiringRecord(id: firing.id, detailID: detail.id, sequenceNumber: detail.sequenceNumber, firedAt: detail.firedAt, laneNumber: firing.laneNumber, cadetID: firing.cadetID, practiceID: firing.practiceID, score: firing.score, esScore: firing.esScore, pvScore: firing.pvScore, outcome: firing.outcome)
            }
        }
    }

    /// The live, freshly computed "up next" detail — recomputes on every access.
    var draftDetail: DraftDetail {
        DraftDetailGenerator.nextDetail(cadets: cadetSnapshots, practices: practiceSnapshots, lanes: laneSnapshots, firings: firingRecords)
    }

    /// `draftDetail` with any in-progress manual edits applied, for display and confirm.
    var displayedDraft: DraftDetail {
        let base = draftDetail
        let firings = base.firings.map { manualEdits[$0.laneNumber] ?? $0 }
        return DraftDetail(firings: firings)
    }

    func editDraftLane(_ laneNumber: Int, cadetID: UUID?, practiceID: UUID?) {
        manualEdits[laneNumber] = DraftFiring(laneNumber: laneNumber, cadetID: cadetID, practiceID: practiceID)
    }

    func confirmDraft() {
        let detail = Detail(sequenceNumber: session.details.count + 1)
        for draftFiring in displayedDraft.firings where draftFiring.cadetID != nil && draftFiring.practiceID != nil {
            let firing = Firing(laneNumber: draftFiring.laneNumber, cadetID: draftFiring.cadetID!, practiceID: draftFiring.practiceID!)
            detail.firings.append(firing)
        }
        session.details.append(detail)
        clearConsumedOverrides(for: detail)
        manualEdits.removeAll()
        try? context.save()
    }

    private func clearConsumedOverrides(for detail: Detail) {
        let firedCadetIDs = Set(detail.firings.map(\.cadetID))
        for cadet in session.cadets where firedCadetIDs.contains(cadet.id) {
            cadet.nextOverridePracticeID = nil
        }
    }

    func recordScore(firing: Firing, score: Int?, esScore: Int?, pvScore: Int?) {
        guard let practice = session.practices.first(where: { $0.id == firing.practiceID }) else { return }
        firing.score = score
        firing.esScore = esScore
        firing.pvScore = pvScore
        let snapshot = PracticeSnapshot(id: practice.id, name: practice.name, order: practice.order, scoringType: practice.scoringType, passMark: practice.passMark, esPassMark: practice.esPassMark, pvPassMark: practice.pvPassMark)
        firing.outcome = ScoringRule.outcome(for: snapshot, score: score, esScore: esScore, pvScore: pvScore)
        try? context.save()
    }

    func toggleLane(_ number: Int) {
        guard let lane = session.lanes.first(where: { $0.number == number }) else { return }
        lane.active.toggle()
        try? context.save()
    }

    func setOverride(cadetID: UUID, practiceID: UUID?) {
        guard let cadet = session.cadets.first(where: { $0.id == cadetID }) else { return }
        cadet.nextOverridePracticeID = practiceID
        try? context.save()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SessionStoreTests`
Expected: PASS (5 tests)

- [ ] **Step 5: Run the full test suite**

Run: `swift test`
Expected: PASS — all tests from Tasks 1–6.

- [ ] **Step 6: Commit**

```bash
git add Sources/RangeDetailTracker/Store Tests/RangeDetailTrackerTests/SessionStoreTests.swift
git commit -m "Add SessionStore bridging SwiftData and the domain layer"
```

---

### Task 7: Session Setup screen

**Files:**
- Create: `Sources/RangeDetailTracker/Views/SessionSetupView.swift`
- Modify: `Sources/RangeDetailTracker/RangeDetailTrackerApp.swift`

**Interfaces:**
- Consumes: `Session`, `Practice`, `Lane`, `Cadet`, `ScoringType` (Task 1).
- Produces: a working root screen that creates a `Session` (with its `Lane`s, `Practice`s, `Cadet`s) in the SwiftData context and hands off to `RangeView` (Task 8+, so for this task, hand off to a temporary placeholder `Text`).

This task is UI: per the spec's testing approach, it is verified by running the app, not by automated tests.

- [ ] **Step 1: Write the Session Setup view**

`Sources/RangeDetailTracker/Views/SessionSetupView.swift`:
```swift
import SwiftUI
import SwiftData

struct PracticeDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var scoringType: ScoringType = .standard
    var passMark: Int = 0
    var esPassMark: Int = 0
    var pvPassMark: Int = 0
}

struct SessionSetupView: View {
    @Environment(\.modelContext) private var context
    @State private var laneCount: Int = 5
    @State private var practiceDrafts: [PracticeDraft] = [PracticeDraft()]
    @State private var cadetNamesText: String = ""
    @State private var startedSession: Session?

    var body: some View {
        if let startedSession {
            RangeView(store: SessionStore(context: context, session: startedSession))
        } else {
            Form {
                Section("Lanes") {
                    Stepper("Lane count: \(laneCount)", value: $laneCount, in: 1...10)
                }
                Section("Practices") {
                    ForEach($practiceDrafts) { $draft in
                        practiceRow($draft)
                    }
                    Button("Add practice") {
                        practiceDrafts.append(PracticeDraft())
                    }
                }
                Section("Cadets (one name per line)") {
                    TextEditor(text: $cadetNamesText)
                        .frame(minHeight: 120)
                }
                Button("Start Session") {
                    startedSession = makeSession()
                }
                .disabled(!isValid)
            }
            .padding()
            .frame(minWidth: 480, minHeight: 480)
        }
    }

    @ViewBuilder
    private func practiceRow(_ draft: Binding<PracticeDraft>) -> some View {
        HStack {
            TextField("Name (e.g. GP1)", text: draft.name)
            Picker("Scoring", selection: draft.scoringType) {
                Text("Standard").tag(ScoringType.standard)
                Text("Zeroing").tag(ScoringType.zeroing)
            }
            .labelsHidden()
            if draft.wrappedValue.scoringType == .standard {
                TextField("Pass mark", value: draft.passMark, format: .number)
                    .frame(width: 80)
            } else {
                TextField("ES pass mark", value: draft.esPassMark, format: .number)
                    .frame(width: 90)
                TextField("PV pass mark", value: draft.pvPassMark, format: .number)
                    .frame(width: 90)
            }
        }
    }

    private var isValid: Bool {
        !practiceDrafts.isEmpty && practiceDrafts.allSatisfy { !$0.name.isEmpty } && !cadetNames.isEmpty
    }

    private var cadetNames: [String] {
        cadetNamesText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func makeSession() -> Session {
        let session = Session(laneCount: laneCount)
        for number in 1...laneCount {
            session.lanes.append(Lane(number: number))
        }
        for (index, draft) in practiceDrafts.enumerated() {
            let practice = Practice(
                name: draft.name,
                order: index,
                scoringType: draft.scoringType,
                passMark: draft.scoringType == .standard ? draft.passMark : nil,
                esPassMark: draft.scoringType == .zeroing ? draft.esPassMark : nil,
                pvPassMark: draft.scoringType == .zeroing ? draft.pvPassMark : nil
            )
            session.practices.append(practice)
        }
        for name in cadetNames {
            session.cadets.append(Cadet(name: name))
        }
        context.insert(session)
        try? context.save()
        return session
    }
}
```

- [ ] **Step 2: Wire it up as the app's root view**

Modify `Sources/RangeDetailTracker/RangeDetailTrackerApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct RangeDetailTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            SessionSetupView()
        }
        .modelContainer(for: [
            Session.self, Practice.self, Lane.self, Cadet.self, Detail.self, Firing.self,
        ])
    }
}
```

- [ ] **Step 3: Add a temporary placeholder `RangeView` so the project builds**

This is superseded by Task 8 — create a minimal stand-in now so Task 7 compiles and is independently runnable.

`Sources/RangeDetailTracker/Views/RangeView.swift`:
```swift
import SwiftUI

struct RangeView: View {
    let store: SessionStore

    var body: some View {
        Text("Session started with \(store.session.cadets.count) cadets")
            .padding()
    }
}
```

- [ ] **Step 4: Build and manually verify**

Run: `swift run`
Expected: App launches showing the Session Setup form. Set lane count, add at least one practice with a name and pass mark, add a couple of cadet names (one per line), click "Start Session" — it should switch to the placeholder Range View showing the cadet count. Quit the app.

- [ ] **Step 5: Commit**

```bash
git add Sources/RangeDetailTracker/Views/SessionSetupView.swift Sources/RangeDetailTracker/Views/RangeView.swift Sources/RangeDetailTracker/RangeDetailTrackerApp.swift
git commit -m "Add Session Setup screen"
```

---

### Task 8: Range View shell — lane grid and roster panel

**Files:**
- Modify: `Sources/RangeDetailTracker/Views/RangeView.swift`
- Create: `Sources/RangeDetailTracker/Views/LaneGridView.swift`
- Create: `Sources/RangeDetailTracker/Views/RosterPanelView.swift`

**Interfaces:**
- Consumes: `SessionStore` (Task 6), `Session`/`Cadet`/`Practice`/`Lane` (Task 1), `ProgressionRule.currentPractice`/`hasPassed` (Task 3).
- Produces: `LaneGridView(store:)`, `RosterPanelView(store:)`, and an updated `RangeView` that lays them out side by side. Later tasks (9–12) add panels into this same `RangeView` body.

This task is UI: verified by running the app.

- [ ] **Step 1: Write the lane grid**

`Sources/RangeDetailTracker/Views/LaneGridView.swift`:
```swift
import SwiftUI

struct LaneGridView: View {
    @Bindable var store: SessionStore

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.session.lanes.sorted { $0.number < $1.number }) { lane in
                laneTile(lane)
            }
        }
    }

    @ViewBuilder
    private func laneTile(_ lane: Lane) -> some View {
        let draftFiring = store.displayedDraft.firings.first { $0.laneNumber == lane.number }
        let cadetName = draftFiring?.cadetID.flatMap { id in store.session.cadets.first { $0.id == id }?.name }
        let practiceName = draftFiring?.practiceID.flatMap { id in store.session.practices.first { $0.id == id }?.name }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Lane \(lane.number)").font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { lane.active },
                    set: { _ in store.toggleLane(lane.number) }
                ))
                .labelsHidden()
            }
            if lane.active {
                Text(cadetName ?? "Idle")
                Text(practiceName ?? "—").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Out of commission").font(.caption).foregroundStyle(.red)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 2: Write the roster panel**

`Sources/RangeDetailTracker/Views/RosterPanelView.swift`:
```swift
import SwiftUI

struct RosterPanelView: View {
    let store: SessionStore

    var body: some View {
        let practices = store.session.practices.sorted { $0.order < $1.order }
        Table(store.session.cadets.sorted { $0.name < $1.name }) {
            TableColumn("Cadet") { cadet in Text(cadet.name) }
            TableColumn("Current") { cadet in
                let current = ProgressionRule.currentPractice(
                    for: cadet.id,
                    practices: practices.map {
                        PracticeSnapshot(id: $0.id, name: $0.name, order: $0.order, scoringType: $0.scoringType, passMark: $0.passMark, esPassMark: $0.esPassMark, pvPassMark: $0.pvPassMark)
                    },
                    firings: firingRecords(for: cadet)
                )
                Text(current?.name ?? "—")
            }
            TableColumnForEach(practices) { practice in
                TableColumn(practice.name) { cadet in
                    let passed = ProgressionRule.hasPassed(practiceID: practice.id, cadetID: cadet.id, firings: firingRecords(for: cadet))
                    Text(passed ? "✓" : "")
                }
            }
        }
    }

    private func firingRecords(for cadet: Cadet) -> [FiringRecord] {
        store.session.details.flatMap { detail in
            detail.firings
                .filter { $0.cadetID == cadet.id }
                .map { firing in
                    FiringRecord(id: firing.id, detailID: detail.id, sequenceNumber: detail.sequenceNumber, firedAt: detail.firedAt, laneNumber: firing.laneNumber, cadetID: firing.cadetID, practiceID: firing.practiceID, score: firing.score, esScore: firing.esScore, pvScore: firing.pvScore, outcome: firing.outcome)
                }
        }
    }
}
```

- [ ] **Step 3: Lay out Range View with both panels side by side**

Replace `Sources/RangeDetailTracker/Views/RangeView.swift`:
```swift
import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore

    var body: some View {
        HSplitView {
            ScrollView {
                LaneGridView(store: store)
                    .padding()
            }
            .frame(minWidth: 320)

            RosterPanelView(store: store)
                .frame(minWidth: 320)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
```

- [ ] **Step 4: Build and manually verify**

Run: `swift run`
Expected: after starting a session, Range View shows a lane grid (one tile per lane, each with an active/out-of-commission toggle showing "Idle" since no draft cadet exists yet — this is expected until Task 9 wires the draft panel's confirm flow, but the grid should already show each active lane occupying an entry once the store computes a draft, since `displayedDraft` is already live) side by side with a roster table listing cadet names, their current practice, and a column per practice. Toggle a lane off and confirm it becomes "Out of commission" and drops out of the grid's active count.

- [ ] **Step 5: Commit**

```bash
git add Sources/RangeDetailTracker/Views/RangeView.swift Sources/RangeDetailTracker/Views/LaneGridView.swift Sources/RangeDetailTracker/Views/RosterPanelView.swift
git commit -m "Add Range View shell: lane grid and roster panel"
```

---

### Task 9: Draft detail panel and confirm-fired action

**Files:**
- Create: `Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift`
- Modify: `Sources/RangeDetailTracker/Views/RangeView.swift`

**Interfaces:**
- Consumes: `SessionStore.displayedDraft`, `SessionStore.confirmDraft()` (Task 6).
- Produces: `DraftDetailPanelView(store:)`, embedded above the lane grid in `RangeView`.

This task is UI: verified by running the app.

- [ ] **Step 1: Write the draft detail panel**

`Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift`:
```swift
import SwiftUI

struct DraftDetailPanelView: View {
    @Bindable var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Up Next").font(.title2)
            let draft = store.displayedDraft
            if draft.firings.allSatisfy({ $0.cadetID == nil }) {
                Text("No cadets eligible for the active lanes.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
                    if let cadetID = firing.cadetID, let practiceID = firing.practiceID {
                        let cadetName = store.session.cadets.first { $0.id == cadetID }?.name ?? "?"
                        let practiceName = store.session.practices.first { $0.id == practiceID }?.name ?? "?"
                        Text("Lane \(firing.laneNumber): \(cadetName) — \(practiceName)")
                    }
                }
            }
            Button("Confirm Fired") {
                store.confirmDraft()
            }
            .disabled(store.displayedDraft.firings.allSatisfy { $0.cadetID == nil })
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 2: Embed it in Range View above the lane grid**

Modify `Sources/RangeDetailTracker/Views/RangeView.swift` — replace the left-hand `ScrollView` content:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 16) {
        DraftDetailPanelView(store: store)
        LaneGridView(store: store)
    }
    .padding()
}
.frame(minWidth: 320)
```

- [ ] **Step 3: Build and manually verify**

Run: `swift run`
Expected: start a session with 2 lanes, 1 practice, 3 cadets. "Up Next" lists 2 of the 3 cadets against the practice, one per lane. Click "Confirm Fired" — the detail is recorded (roster panel unaffected until scores are entered, Task 11), and "Up Next" recomputes to show the third cadet plus one of the two already-fired cadets (since lanes must still fill, and the just-fired cadets are now least-favoured by fairness).

- [ ] **Step 4: Commit**

```bash
git add Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift Sources/RangeDetailTracker/Views/RangeView.swift
git commit -m "Add draft detail panel with confirm-fired action"
```

---

### Task 10: Draft editing

**Files:**
- Modify: `Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift`

**Interfaces:**
- Consumes: `SessionStore.editDraftLane(_:cadetID:practiceID:)` (Task 6).
- Produces: per-lane edit controls (cadet picker, practice picker, "Clear lane") in the draft panel.

This task is UI: verified by running the app.

- [ ] **Step 1: Add per-lane edit controls to the draft panel**

Replace the `ForEach` body in `Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift`:
```swift
ForEach(draft.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
    HStack {
        Text("Lane \(firing.laneNumber)").frame(width: 60, alignment: .leading)

        Picker("Cadet", selection: Binding(
            get: { firing.cadetID },
            set: { newCadetID in
                store.editDraftLane(firing.laneNumber, cadetID: newCadetID, practiceID: firing.practiceID ?? store.session.practices.first?.id)
            }
        )) {
            Text("— Idle —").tag(UUID?.none)
            ForEach(store.session.cadets.sorted { $0.name < $1.name }) { cadet in
                Text(cadet.name).tag(Optional(cadet.id))
            }
        }
        .labelsHidden()

        Picker("Practice", selection: Binding(
            get: { firing.practiceID },
            set: { newPracticeID in
                store.editDraftLane(firing.laneNumber, cadetID: firing.cadetID, practiceID: newPracticeID)
            }
        )) {
            Text("—").tag(UUID?.none)
            ForEach(store.session.practices.sorted { $0.order < $1.order }) { practice in
                Text(practice.name).tag(Optional(practice.id))
            }
        }
        .labelsHidden()
        .disabled(firing.cadetID == nil)
    }
}
```

- [ ] **Step 2: Build and manually verify**

Run: `swift run`
Expected: start a session with 2 lanes and cadets. In "Up Next", change lane 1's cadet picker to a different cadet, and its practice picker to a different configured practice. Click "Confirm Fired" — the recorded detail should reflect the edited cadet/practice for lane 1, not the algorithm's original suggestion. The next "Up Next" draft (after confirming) should be freshly computed by the algorithm again, not carry the edit forward.

- [ ] **Step 3: Commit**

```bash
git add Sources/RangeDetailTracker/Views/DraftDetailPanelView.swift
git commit -m "Allow editing the draft detail before confirming"
```

---

### Task 11: Results entry

**Files:**
- Create: `Sources/RangeDetailTracker/Views/ResultsEntryView.swift`
- Modify: `Sources/RangeDetailTracker/Views/RangeView.swift`

**Interfaces:**
- Consumes: `SessionStore.recordScore(firing:score:esScore:pvScore:)` (Task 6), `Firing`/`Practice`/`ScoringType` (Task 1).
- Produces: `ResultsEntryView(store:)` listing every confirmed `Firing` in the most recent `Detail` that still lacks an `outcome`, with score entry fields appropriate to its practice's scoring type.

This task is UI: verified by running the app.

- [ ] **Step 1: Write the results entry view**

`Sources/RangeDetailTracker/Views/ResultsEntryView.swift`:
```swift
import SwiftUI

struct ResultsEntryView: View {
    @Bindable var store: SessionStore

    private var pendingFirings: [Firing] {
        guard let latest = store.session.details.max(by: { $0.sequenceNumber < $1.sequenceNumber }) else { return [] }
        return latest.firings.filter { $0.outcome == nil }.sorted { $0.laneNumber < $1.laneNumber }
    }

    var body: some View {
        if !pendingFirings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Results").font(.title2)
                ForEach(pendingFirings) { firing in
                    resultRow(firing)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func resultRow(_ firing: Firing) -> some View {
        let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
        let practice = store.session.practices.first { $0.id == firing.practiceID }

        HStack {
            Text("Lane \(firing.laneNumber): \(cadetName)").frame(width: 220, alignment: .leading)
            if practice?.scoringType == .zeroing {
                scoreField("ES", value: Binding(
                    get: { firing.esScore ?? 0 },
                    set: { store.recordScore(firing: firing, score: nil, esScore: $0, pvScore: firing.pvScore) }
                ))
                scoreField("PV", value: Binding(
                    get: { firing.pvScore ?? 0 },
                    set: { store.recordScore(firing: firing, score: nil, esScore: firing.esScore, pvScore: $0) }
                ))
            } else {
                scoreField("Score", value: Binding(
                    get: { firing.score ?? 0 },
                    set: { store.recordScore(firing: firing, score: $0, esScore: nil, pvScore: nil) }
                ))
            }
        }
    }

    private func scoreField(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
            TextField(label, value: value, format: .number)
                .frame(width: 60)
        }
    }
}
```

- [ ] **Step 2: Embed it above the draft panel in Range View**

Modify `Sources/RangeDetailTracker/Views/RangeView.swift`:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 16) {
        ResultsEntryView(store: store)
        DraftDetailPanelView(store: store)
        LaneGridView(store: store)
    }
    .padding()
}
.frame(minWidth: 320)
```

- [ ] **Step 3: Build and manually verify**

Run: `swift run`
Expected: confirm a detail (Task 9), then "Enter Results" appears listing that detail's lanes. Enter a score above the pass mark for one cadet, below for another — the roster panel's "Current" column should update immediately once a score is entered (each entry triggers recomputation). Once all lanes in a detail have scores, "Enter Results" disappears until the next detail is confirmed.

- [ ] **Step 4: Commit**

```bash
git add Sources/RangeDetailTracker/Views/ResultsEntryView.swift Sources/RangeDetailTracker/Views/RangeView.swift
git commit -m "Add results entry with score-driven outcome derivation"
```

---

### Task 12: Detail history panel

**Files:**
- Create: `Sources/RangeDetailTracker/Views/DetailHistoryView.swift`
- Modify: `Sources/RangeDetailTracker/Views/RangeView.swift`

**Interfaces:**
- Consumes: `Session.details`, `Detail`, `Firing` (Task 1).
- Produces: `DetailHistoryView(store:)`, a scrollable log of past fired details.

This task is UI: verified by running the app.

- [ ] **Step 1: Write the history view**

`Sources/RangeDetailTracker/Views/DetailHistoryView.swift`:
```swift
import SwiftUI

struct DetailHistoryView: View {
    let store: SessionStore

    var body: some View {
        let details = store.session.details.sorted { $0.sequenceNumber > $1.sequenceNumber }
        VStack(alignment: .leading, spacing: 8) {
            Text("History").font(.title2)
            if details.isEmpty {
                Text("No details fired yet.").foregroundStyle(.secondary)
            }
            ForEach(details) { detail in
                DisclosureGroup("Detail \(detail.sequenceNumber)") {
                    ForEach(detail.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
                        let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
                        let practiceName = store.session.practices.first { $0.id == firing.practiceID }?.name ?? "?"
                        Text("Lane \(firing.laneNumber): \(cadetName) — \(practiceName) — \(outcomeText(firing))")
                    }
                }
            }
        }
        .padding()
    }

    private func outcomeText(_ firing: Firing) -> String {
        switch firing.outcome {
        case .pass: return "PASS"
        case .fail: return "FAIL"
        case nil: return "pending"
        }
    }
}
```

- [ ] **Step 2: Embed it in the roster-panel column of Range View**

Modify `Sources/RangeDetailTracker/Views/RangeView.swift` — replace the right-hand pane:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 16) {
        RosterPanelView(store: store)
        DetailHistoryView(store: store)
    }
    .padding()
}
.frame(minWidth: 320)
```

- [ ] **Step 3: Build and manually verify**

Run: `swift run`
Expected: after confirming and scoring a couple of details, the History section on the right lists them newest-first, each expandable to show lane/cadet/practice/outcome.

- [ ] **Step 4: Commit**

```bash
git add Sources/RangeDetailTracker/Views/DetailHistoryView.swift Sources/RangeDetailTracker/Views/RangeView.swift
git commit -m "Add detail history panel"
```

---

### Task 13: Butt register and CSV export

**Files:**
- Create: `Sources/RangeDetailTracker/Domain/ButtRegisterRow.swift`
- Create: `Sources/RangeDetailTracker/Domain/ButtRegisterBuilder.swift`
- Create: `Sources/RangeDetailTracker/Domain/ButtRegisterCSVExporter.swift`
- Create: `Sources/RangeDetailTracker/Views/ButtRegisterView.swift`
- Modify: `Sources/RangeDetailTracker/Views/RangeView.swift`
- Test: `Tests/RangeDetailTrackerTests/ButtRegisterTests.swift`

**Interfaces:**
- Consumes: `Session`, `Detail`, `Firing`, `Cadet`, `Practice`, `Outcome` (Task 1).
- Produces: `ButtRegisterRow`, `ButtRegisterBuilder.rows(for:) -> [ButtRegisterRow]`, `ButtRegisterCSVExporter.csv(for:) -> String`, and `ButtRegisterView(store:)` reachable from a Range View toolbar button.

- [ ] **Step 1: Write the row type**

`Sources/RangeDetailTracker/Domain/ButtRegisterRow.swift`:
```swift
struct ButtRegisterRow: Identifiable {
    var id: String { "\(detailSequenceNumber)-\(laneNumber)" }
    let detailSequenceNumber: Int
    let laneNumber: Int
    let cadetName: String
    let practiceName: String
    let score: Int?
    let esScore: Int?
    let pvScore: Int?
    let outcome: Outcome?
}
```

- [ ] **Step 2: Write the failing test**

`Tests/RangeDetailTrackerTests/ButtRegisterTests.swift`:
```swift
import XCTest
import SwiftData
@testable import RangeDetailTracker

final class ButtRegisterTests: XCTestCase {
    func makeSessionWithOneFiring() throws -> Session {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "AR1", order: 0, scoringType: .standard, passMark: 20)
        let cadet = Cadet(name: "Smith, J")
        session.practices.append(practice)
        session.cadets.append(cadet)

        let detail = Detail(sequenceNumber: 1)
        let firing = Firing(laneNumber: 1, cadetID: cadet.id, practiceID: practice.id)
        firing.score = 25
        firing.outcome = .pass
        detail.firings.append(firing)
        session.details.append(detail)

        return session
    }

    func testRowsAreOrderedByDetailThenLane() throws {
        let session = try makeSessionWithOneFiring()
        let rows = ButtRegisterBuilder.rows(for: session)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.detailSequenceNumber, 1)
        XCTAssertEqual(rows.first?.laneNumber, 1)
        XCTAssertEqual(rows.first?.cadetName, "Smith, J")
        XCTAssertEqual(rows.first?.practiceName, "AR1")
        XCTAssertEqual(rows.first?.score, 25)
        XCTAssertEqual(rows.first?.outcome, .pass)
    }

    func testCSVEscapesCadetNamesContainingCommas() throws {
        let session = try makeSessionWithOneFiring()
        let rows = ButtRegisterBuilder.rows(for: session)
        let csv = ButtRegisterCSVExporter.csv(for: rows)
        XCTAssertTrue(csv.contains("\"Smith, J\""))
        XCTAssertTrue(csv.hasPrefix("Detail,Lane,Cadet,Practice,Score,ES,PV,Outcome"))
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --filter ButtRegisterTests`
Expected: FAIL to compile — `ButtRegisterBuilder`/`ButtRegisterCSVExporter` not defined.

- [ ] **Step 4: Write the minimal implementation**

`Sources/RangeDetailTracker/Domain/ButtRegisterBuilder.swift`:
```swift
enum ButtRegisterBuilder {
    static func rows(for session: Session) -> [ButtRegisterRow] {
        session.details
            .sorted { $0.sequenceNumber < $1.sequenceNumber }
            .flatMap { detail in
                detail.firings
                    .sorted { $0.laneNumber < $1.laneNumber }
                    .compactMap { firing -> ButtRegisterRow? in
                        guard let cadet = session.cadets.first(where: { $0.id == firing.cadetID }),
                              let practice = session.practices.first(where: { $0.id == firing.practiceID })
                        else { return nil }
                        return ButtRegisterRow(
                            detailSequenceNumber: detail.sequenceNumber,
                            laneNumber: firing.laneNumber,
                            cadetName: cadet.name,
                            practiceName: practice.name,
                            score: firing.score,
                            esScore: firing.esScore,
                            pvScore: firing.pvScore,
                            outcome: firing.outcome
                        )
                    }
            }
    }
}
```

`Sources/RangeDetailTracker/Domain/ButtRegisterCSVExporter.swift`:
```swift
enum ButtRegisterCSVExporter {
    static func csv(for rows: [ButtRegisterRow]) -> String {
        var lines = ["Detail,Lane,Cadet,Practice,Score,ES,PV,Outcome"]
        for row in rows {
            let fields = [
                String(row.detailSequenceNumber),
                String(row.laneNumber),
                csvField(row.cadetName),
                csvField(row.practiceName),
                row.score.map(String.init) ?? "",
                row.esScore.map(String.init) ?? "",
                row.pvScore.map(String.init) ?? "",
                row.outcome?.rawValue ?? "",
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\"))\""
        }
        return value
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `swift test --filter ButtRegisterTests`
Expected: PASS (2 tests)

- [ ] **Step 6: Write the Butt Register view with CSV export**

`Sources/RangeDetailTracker/Views/ButtRegisterView.swift`:
```swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ButtRegisterView: View {
    let store: SessionStore

    private var rows: [ButtRegisterRow] {
        ButtRegisterBuilder.rows(for: store.session)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Butt Register").font(.title2)
                Spacer()
                Button("Export CSV") { exportCSV() }
            }
            Table(rows) {
                TableColumn("Detail") { Text("\($0.detailSequenceNumber)") }
                TableColumn("Lane") { Text("\($0.laneNumber)") }
                TableColumn("Cadet") { Text($0.cadetName) }
                TableColumn("Practice") { Text($0.practiceName) }
                TableColumn("Score") { Text($0.score.map(String.init) ?? "") }
                TableColumn("ES") { Text($0.esScore.map(String.init) ?? "") }
                TableColumn("PV") { Text($0.pvScore.map(String.init) ?? "") }
                TableColumn("Outcome") { Text($0.outcome?.rawValue ?? "") }
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 400)
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "butt-register.csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let csv = ButtRegisterCSVExporter.csv(for: rows)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }
}
```

- [ ] **Step 7: Add a toolbar button in Range View to open it**

Modify `Sources/RangeDetailTracker/Views/RangeView.swift` to add state and a sheet:
```swift
import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore
    @State private var showingButtRegister = false

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ResultsEntryView(store: store)
                    DraftDetailPanelView(store: store)
                    LaneGridView(store: store)
                }
                .padding()
            }
            .frame(minWidth: 320)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RosterPanelView(store: store)
                    DetailHistoryView(store: store)
                }
                .padding()
            }
            .frame(minWidth: 320)
        }
        .frame(minWidth: 800, minHeight: 500)
        .toolbar {
            Button("Butt Register") { showingButtRegister = true }
        }
        .sheet(isPresented: $showingButtRegister) {
            ButtRegisterView(store: store)
        }
    }
}
```

- [ ] **Step 8: Build and manually verify**

Run: `swift run`
Expected: run a full session (start, confirm a couple of details, enter scores), then click "Butt Register" in the toolbar — a sheet opens showing every firing across all details, ordered by detail then lane, with correct scores and outcomes. Click "Export CSV", save to a file, and open it to confirm the header row and data match what's on screen.

- [ ] **Step 9: Run the full test suite one final time**

Run: `swift test`
Expected: PASS — all tests across every task.

- [ ] **Step 10: Commit**

```bash
git add Sources/RangeDetailTracker/Domain/ButtRegisterRow.swift Sources/RangeDetailTracker/Domain/ButtRegisterBuilder.swift Sources/RangeDetailTracker/Domain/ButtRegisterCSVExporter.swift Sources/RangeDetailTracker/Views/ButtRegisterView.swift Sources/RangeDetailTracker/Views/RangeView.swift Tests/RangeDetailTrackerTests/ButtRegisterTests.swift
git commit -m "Add butt register view with CSV export"
```
