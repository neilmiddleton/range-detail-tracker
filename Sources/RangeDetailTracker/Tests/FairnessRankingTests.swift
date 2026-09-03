import Foundation

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

    static let allTests: [(String, (FairnessRankingTests) -> () throws -> Void)] = [
        ("testNeverFiredCadetRanksBeforeFiredCadet", testNeverFiredCadetRanksBeforeFiredCadet),
        ("testLeastRecentlyFiredRanksFirst", testLeastRecentlyFiredRanksFirst),
        ("testFewestFiredCountBreaksRecencyTie", testFewestFiredCountBreaksRecencyTie),
    ]
}
