import Foundation

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

    static let allTests: [(String, (ScoringRuleTests) -> () throws -> Void)] = [
        ("testStandardPassesAtExactPassMark", testStandardPassesAtExactPassMark),
        ("testStandardFailsOneBelowPassMark", testStandardFailsOneBelowPassMark),
        ("testZeroingFailsIfEitherScoreBelowMark", testZeroingFailsIfEitherScoreBelowMark),
        ("testZeroingPassesOnlyWhenBothMeetMarks", testZeroingPassesOnlyWhenBothMeetMarks),
        ("testReturnsNilWhenScoresNotYetEntered", testReturnsNilWhenScoresNotYetEntered),
    ]
}
