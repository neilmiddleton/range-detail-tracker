import Foundation

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

    func testCadetStaysOnStickyLaneAfterZeroing() {
        let zeroing = PracticeSnapshot(id: UUID(), name: "Zero", order: 0, scoringType: .zeroing, passMark: nil, esPassMark: 10, pvPassMark: 10)
        let cadetA = CadetSnapshot(id: UUID(), name: "A", nextOverridePracticeID: nil)
        let cadetB = CadetSnapshot(id: UUID(), name: "B", nextOverridePracticeID: nil)
        let cadetC = CadetSnapshot(id: UUID(), name: "C", nextOverridePracticeID: nil)
        // Cadet A previously zeroed on lane 1 but failed, so they're still on the zeroing practice.
        let priorFiring = FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 1, cadetID: cadetA.id, practiceID: zeroing.id, score: nil, esScore: 20, pvScore: 20, outcome: .fail)
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadetA, cadetB, cadetC], practices: [zeroing], lanes: lanes([1, 2, 3]), firings: [priorFiring])
        XCTAssertEqual(draft.firings.first { $0.laneNumber == 1 }?.cadetID, cadetA.id)
    }

    func testStickyLaneIgnoredWhenLaneUnavailable() {
        let zeroing = PracticeSnapshot(id: UUID(), name: "Zero", order: 0, scoringType: .zeroing, passMark: nil, esPassMark: 10, pvPassMark: 10)
        let cadetA = CadetSnapshot(id: UUID(), name: "A", nextOverridePracticeID: nil)
        let priorFiring = FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 2, cadetID: cadetA.id, practiceID: zeroing.id, score: nil, esScore: 20, pvScore: 20, outcome: .fail)
        // Cadet A's sticky lane (2) is now out of commission, so they fall back to whichever active lane is available.
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadetA], practices: [zeroing], lanes: lanes([1, 2, 3], inactive: [2]), firings: [priorFiring])
        XCTAssertEqual(draft.firings.first { $0.cadetID == cadetA.id }?.laneNumber, 1)
    }

    func testStickyPreferenceNeverBumpsAHigherPriorityCadet() {
        let zeroing = PracticeSnapshot(id: UUID(), name: "Zero", order: 0, scoringType: .zeroing, passMark: nil, esPassMark: 10, pvPassMark: 10)
        let cadetX = CadetSnapshot(id: UUID(), name: "Never Fired", nextOverridePracticeID: nil)
        let cadetY = CadetSnapshot(id: UUID(), name: "Sticky But Behind", nextOverridePracticeID: nil)
        // Cadet Y previously zeroed (and failed) on lane 1, making it their sticky lane —
        // but that also means they've already had a turn. Cadet X has never fired, so
        // they have higher fairness priority for the one remaining lane. Stickiness is
        // only a lane preference; it must never let Y take X's turn to fire at all.
        let priorFiring = FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 1, cadetID: cadetY.id, practiceID: zeroing.id, score: nil, esScore: 20, pvScore: 20, outcome: .fail)
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadetX, cadetY], practices: [zeroing], lanes: lanes([1]), firings: [priorFiring])
        XCTAssertEqual(draft.firings.first?.cadetID, cadetX.id)
    }

    func testVoidAttemptDoesNotCountAgainstFairness() {
        let cadetA = CadetSnapshot(id: UUID(), name: "Malfunctioned", nextOverridePracticeID: nil)
        let cadetB = CadetSnapshot(id: UUID(), name: "Never Fired", nextOverridePracticeID: nil)
        let cadetC = CadetSnapshot(id: UUID(), name: "Actually Fired", nextOverridePracticeID: nil)
        let voidFiring = FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 1, cadetID: cadetA.id, practiceID: ar1.id, score: 0, esScore: nil, pvScore: nil, outcome: .fail)
        let validFiring = FiringRecord(id: UUID(), detailID: UUID(), sequenceNumber: 1, firedAt: .now, laneNumber: 2, cadetID: cadetC.id, practiceID: ar1.id, score: 25, esScore: nil, pvScore: nil, outcome: .fail)
        // Only one lane: whoever the fairness ranking puts first gets it. Cadet A's
        // malfunctioned (zero score) attempt shouldn't count against them, so it must
        // go to A or B — never to C, who genuinely fired already.
        let draft = DraftDetailGenerator.nextDetail(cadets: [cadetA, cadetB, cadetC], practices: [ar1], lanes: lanes([1]), firings: [voidFiring, validFiring])
        XCTAssertNotEqual(draft.firings.first?.cadetID, cadetC.id)
    }

    static let allTests: [(String, (DraftDetailGeneratorTests) -> () throws -> Void)] = [
        ("testFillsLanesFromSingleGroupUpToLaneCount", testFillsLanesFromSingleGroupUpToLaneCount),
        ("testGroupsPracticesInContiguousBlocks", testGroupsPracticesInContiguousBlocks),
        ("testExcludesOutOfCommissionLanes", testExcludesOutOfCommissionLanes),
        ("testLeavesExcessLanesIdleWhenNotEnoughCadets", testLeavesExcessLanesIdleWhenNotEnoughCadets),
        ("testManualOverrideIsUsedInsteadOfProgression", testManualOverrideIsUsedInsteadOfProgression),
        ("testCompletedCadetPlacedOnFinalPractice", testCompletedCadetPlacedOnFinalPractice),
        ("testCadetStaysOnStickyLaneAfterZeroing", testCadetStaysOnStickyLaneAfterZeroing),
        ("testStickyLaneIgnoredWhenLaneUnavailable", testStickyLaneIgnoredWhenLaneUnavailable),
        ("testStickyPreferenceNeverBumpsAHigherPriorityCadet", testStickyPreferenceNeverBumpsAHigherPriorityCadet),
        ("testVoidAttemptDoesNotCountAgainstFairness", testVoidAttemptDoesNotCountAgainstFairness),
    ]
}
