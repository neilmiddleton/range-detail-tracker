import Foundation

final class ScoringRuleTests: XCTestCase {
    func standardPractice(passMark: Int) -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "AR1", order: 0, scoringType: .standard, passMark: passMark, esPassMark: nil, pvPassMark: nil)
    }

    func zeroingPractice(esPassMark: Int, pvPassMark: Int) -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "Zeroing", order: 0, scoringType: .zeroing, passMark: nil, esPassMark: esPassMark, pvPassMark: pvPassMark)
    }

    func pointsPractice(passMark: Int) -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "AR4.1", order: 0, scoringType: .points, passMark: passMark, esPassMark: nil, pvPassMark: nil)
    }

    func completionPractice() -> PracticeSnapshot {
        PracticeSnapshot(id: UUID(), name: "GP1", order: 0, scoringType: .completion, passMark: nil, esPassMark: nil, pvPassMark: nil)
    }

    func testStandardPassesAtExactPassMark() {
        let practice = standardPractice(passMark: 20)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 20, esScore: nil, pvScore: nil), .pass)
    }

    func testStandardFailsOneAbovePassMark() {
        let practice = standardPractice(passMark: 20)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 21, esScore: nil, pvScore: nil), .fail)
    }

    func testZeroingFailsIfEitherScoreAboveMark() {
        let practice = zeroingPractice(esPassMark: 10, pvPassMark: 10)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 5, pvScore: 15), .fail)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 15, pvScore: 5), .fail)
    }

    func testZeroingPassesOnlyWhenBothMeetMarks() {
        let practice = zeroingPractice(esPassMark: 10, pvPassMark: 10)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 10, pvScore: 10), .pass)
    }

    func testReturnsNilWhenScoresNotYetEntered() {
        let practice = standardPractice(passMark: 20)
        XCTAssertNil(ScoringRule.outcome(for: practice, score: nil, esScore: nil, pvScore: nil))
    }

    func testStandardScoreOfZeroIsAlwaysFail() {
        let practice = standardPractice(passMark: 20)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 0, esScore: nil, pvScore: nil), .fail)
    }

    func testZeroingEitherScoreOfZeroIsAlwaysFail() {
        let practice = zeroingPractice(esPassMark: 10, pvPassMark: 10)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 0, pvScore: 5), .fail)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: nil, esScore: 5, pvScore: 0), .fail)
    }

    func testStandardZeroScoreIsAVoidAttempt() {
        XCTAssertTrue(ScoringRule.isVoidAttempt(scoringType: .standard, score: 0, esScore: nil, pvScore: nil))
        XCTAssertFalse(ScoringRule.isVoidAttempt(scoringType: .standard, score: 25, esScore: nil, pvScore: nil))
    }

    func testZeroingEitherZeroScoreIsAVoidAttempt() {
        XCTAssertTrue(ScoringRule.isVoidAttempt(scoringType: .zeroing, score: nil, esScore: 0, pvScore: 5))
        XCTAssertTrue(ScoringRule.isVoidAttempt(scoringType: .zeroing, score: nil, esScore: 5, pvScore: 0))
        XCTAssertFalse(ScoringRule.isVoidAttempt(scoringType: .zeroing, score: nil, esScore: 5, pvScore: 5))
    }

    func testPointsPassesAtOrAbovePassMark() {
        let practice = pointsPractice(passMark: 30)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 30, esScore: nil, pvScore: nil), .pass)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 35, esScore: nil, pvScore: nil), .pass)
    }

    func testPointsFailsBelowPassMark() {
        let practice = pointsPractice(passMark: 30)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 29, esScore: nil, pvScore: nil), .fail)
    }

    func testPointsScoreOfZeroIsAlwaysFail() {
        let practice = pointsPractice(passMark: 30)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 0, esScore: nil, pvScore: nil), .fail)
        XCTAssertTrue(ScoringRule.isVoidAttempt(scoringType: .points, score: 0, esScore: nil, pvScore: nil))
    }

    func testCompletionPassesOnAnyNonZeroScore() {
        let practice = completionPractice()
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 1, esScore: nil, pvScore: nil), .pass)
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 100, esScore: nil, pvScore: nil), .pass)
    }

    func testCompletionScoreOfZeroIsAlwaysFail() {
        let practice = completionPractice()
        XCTAssertEqual(ScoringRule.outcome(for: practice, score: 0, esScore: nil, pvScore: nil), .fail)
        XCTAssertTrue(ScoringRule.isVoidAttempt(scoringType: .completion, score: 0, esScore: nil, pvScore: nil))
    }

    static let allTests: [(String, (ScoringRuleTests) -> () throws -> Void)] = [
        ("testStandardPassesAtExactPassMark", testStandardPassesAtExactPassMark),
        ("testStandardFailsOneAbovePassMark", testStandardFailsOneAbovePassMark),
        ("testZeroingFailsIfEitherScoreAboveMark", testZeroingFailsIfEitherScoreAboveMark),
        ("testZeroingPassesOnlyWhenBothMeetMarks", testZeroingPassesOnlyWhenBothMeetMarks),
        ("testReturnsNilWhenScoresNotYetEntered", testReturnsNilWhenScoresNotYetEntered),
        ("testStandardScoreOfZeroIsAlwaysFail", testStandardScoreOfZeroIsAlwaysFail),
        ("testZeroingEitherScoreOfZeroIsAlwaysFail", testZeroingEitherScoreOfZeroIsAlwaysFail),
        ("testStandardZeroScoreIsAVoidAttempt", testStandardZeroScoreIsAVoidAttempt),
        ("testZeroingEitherZeroScoreIsAVoidAttempt", testZeroingEitherZeroScoreIsAVoidAttempt),
        ("testPointsPassesAtOrAbovePassMark", testPointsPassesAtOrAbovePassMark),
        ("testPointsFailsBelowPassMark", testPointsFailsBelowPassMark),
        ("testPointsScoreOfZeroIsAlwaysFail", testPointsScoreOfZeroIsAlwaysFail),
        ("testCompletionPassesOnAnyNonZeroScore", testCompletionPassesOnAnyNonZeroScore),
        ("testCompletionScoreOfZeroIsAlwaysFail", testCompletionScoreOfZeroIsAlwaysFail),
    ]
}
