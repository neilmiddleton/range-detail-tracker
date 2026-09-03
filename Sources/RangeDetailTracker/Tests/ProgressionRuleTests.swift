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

    static let allTests: [(String, (ProgressionRuleTests) -> () throws -> Void)] = [
        ("testCurrentPracticeIsFirstUnpassedPractice", testCurrentPracticeIsFirstUnpassedPractice),
        ("testCurrentPracticeStaysSameAfterFail", testCurrentPracticeStaysSameAfterFail),
        ("testCannotSkipAheadEvenIfLaterPracticeSomehowPassed", testCannotSkipAheadEvenIfLaterPracticeSomehowPassed),
        ("testCompletedCadetResolvesToFinalPractice", testCompletedCadetResolvesToFinalPractice),
        ("testNoPracticesReturnsNil", testNoPracticesReturnsNil),
    ]
}
