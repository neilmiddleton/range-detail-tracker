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

    static let allTests: [(String, (DraftDetailGeneratorTests) -> () throws -> Void)] = [
        ("testFillsLanesFromSingleGroupUpToLaneCount", testFillsLanesFromSingleGroupUpToLaneCount),
        ("testGroupsPracticesInContiguousBlocks", testGroupsPracticesInContiguousBlocks),
        ("testExcludesOutOfCommissionLanes", testExcludesOutOfCommissionLanes),
        ("testLeavesExcessLanesIdleWhenNotEnoughCadets", testLeavesExcessLanesIdleWhenNotEnoughCadets),
        ("testManualOverrideIsUsedInsteadOfProgression", testManualOverrideIsUsedInsteadOfProgression),
        ("testCompletedCadetPlacedOnFinalPractice", testCompletedCadetPlacedOnFinalPractice),
    ]
}
