import Foundation

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

    func testMustPassEveryAR4PositionBeforeReachingAR5() {
        // ACP 18's AR4 has 4 position-specific stages (Prone/Sitting/Kneeling/Standing);
        // a cadet must pass all four before progressing to AR5 — passing the first
        // three is not enough.
        let ar4Prone = PracticeSnapshot(id: UUID(), name: "AR4.1 Deliberate (Prone)", order: 0, scoringType: .points, passMark: 30, esPassMark: nil, pvPassMark: nil)
        let ar4Sitting = PracticeSnapshot(id: UUID(), name: "AR4.2 Deliberate (Sitting)", order: 1, scoringType: .points, passMark: 25, esPassMark: nil, pvPassMark: nil)
        let ar4Kneeling = PracticeSnapshot(id: UUID(), name: "AR4.3 Deliberate (Kneeling)", order: 2, scoringType: .points, passMark: 20, esPassMark: nil, pvPassMark: nil)
        let ar4Standing = PracticeSnapshot(id: UUID(), name: "AR4.4 Deliberate (Standing)", order: 3, scoringType: .points, passMark: 15, esPassMark: nil, pvPassMark: nil)
        let ar5Standing = PracticeSnapshot(id: UUID(), name: "AR5.1 Sighting (Standing)", order: 4, scoringType: .points, passMark: 5, esPassMark: nil, pvPassMark: nil)
        let practices = [ar4Prone, ar4Sitting, ar4Kneeling, ar4Standing, ar5Standing]

        let cadetID = UUID()
        let firings = [
            firing(cadetID: cadetID, practiceID: ar4Prone.id, outcome: .pass),
            firing(cadetID: cadetID, practiceID: ar4Sitting.id, outcome: .pass),
            firing(cadetID: cadetID, practiceID: ar4Kneeling.id, outcome: .pass),
            // AR4.4 (Standing) not yet passed.
        ]
        let current = ProgressionRule.currentPractice(for: cadetID, practices: practices, firings: firings)
        XCTAssertEqual(current?.id, ar4Standing.id)

        let allPassed = firings + [firing(cadetID: cadetID, practiceID: ar4Standing.id, outcome: .pass)]
        let afterFinalPass = ProgressionRule.currentPractice(for: cadetID, practices: practices, firings: allPassed)
        XCTAssertEqual(afterFinalPass?.id, ar5Standing.id)
    }

    static let allTests: [(String, (ProgressionRuleTests) -> () throws -> Void)] = [
        ("testCurrentPracticeIsFirstUnpassedPractice", testCurrentPracticeIsFirstUnpassedPractice),
        ("testCurrentPracticeStaysSameAfterFail", testCurrentPracticeStaysSameAfterFail),
        ("testCannotSkipAheadEvenIfLaterPracticeSomehowPassed", testCannotSkipAheadEvenIfLaterPracticeSomehowPassed),
        ("testCompletedCadetResolvesToFinalPractice", testCompletedCadetResolvesToFinalPractice),
        ("testNoPracticesReturnsNil", testNoPracticesReturnsNil),
        ("testMustPassEveryAR4PositionBeforeReachingAR5", testMustPassEveryAR4PositionBeforeReachingAR5),
    ]
}
