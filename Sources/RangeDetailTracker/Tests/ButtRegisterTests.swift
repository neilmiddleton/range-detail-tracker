import Foundation

final class ButtRegisterTests: XCTestCase {
    func addFiring(to session: Session, sequenceNumber: Int, cadetID: UUID, practiceID: UUID, score: Int? = nil, esScore: Int? = nil, pvScore: Int? = nil, outcome: Outcome?) {
        let detail = session.details.first { $0.sequenceNumber == sequenceNumber } ?? {
            let new = Detail(sequenceNumber: sequenceNumber)
            session.details.append(new)
            return new
        }()
        let firing = Firing(laneNumber: 1, cadetID: cadetID, practiceID: practiceID)
        firing.score = score
        firing.esScore = esScore
        firing.pvScore = pvScore
        firing.outcome = outcome
        detail.firings.append(firing)
    }

    func testReportsCadetNameAndBestStandardScore() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let cadet = Cadet(name: "Smith, J")
        session.practices.append(practice)
        session.cadets.append(cadet)
        addFiring(to: session, sequenceNumber: 1, cadetID: cadet.id, practiceID: practice.id, score: 25, outcome: .fail)
        addFiring(to: session, sequenceNumber: 2, cadetID: cadet.id, practiceID: practice.id, score: 15, outcome: .pass)

        let rows = ButtRegisterBuilder.rows(for: session)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.cadetName, "Smith, J")
        let best = rows.first?.bestResult(for: practice.id)
        XCTAssertEqual(best?.score, 15)
        XCTAssertEqual(best?.outcome, .pass)
    }

    func testVoidZeroScoresAreExcludedFromBestScore() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let cadet = Cadet(name: "Jones")
        session.practices.append(practice)
        session.cadets.append(cadet)
        // A malfunctioned (score 0) attempt should never count as their "best".
        addFiring(to: session, sequenceNumber: 1, cadetID: cadet.id, practiceID: practice.id, score: 0, outcome: .fail)
        addFiring(to: session, sequenceNumber: 2, cadetID: cadet.id, practiceID: practice.id, score: 18, outcome: .pass)

        let rows = ButtRegisterBuilder.rows(for: session)
        XCTAssertEqual(rows.first?.bestResult(for: practice.id)?.score, 18)
    }

    func testReportsBestZeroingPairByLowestCombinedScore() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "Zero", order: 0, scoringType: .zeroing, esPassMark: 10, pvPassMark: 10)
        let cadet = Cadet(name: "Patel")
        session.practices.append(practice)
        session.cadets.append(cadet)
        addFiring(to: session, sequenceNumber: 1, cadetID: cadet.id, practiceID: practice.id, esScore: 15, pvScore: 15, outcome: .fail)
        addFiring(to: session, sequenceNumber: 2, cadetID: cadet.id, practiceID: practice.id, esScore: 8, pvScore: 9, outcome: .pass)

        let rows = ButtRegisterBuilder.rows(for: session)
        let best = rows.first?.bestResult(for: practice.id)
        XCTAssertEqual(best?.esScore, 8)
        XCTAssertEqual(best?.pvScore, 9)
        XCTAssertEqual(best?.outcome, .pass)
    }

    func testReportsBestPointsScoreAsHighestNotLowest() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "AR4.1", order: 0, scoringType: .points, passMark: 30)
        let cadet = Cadet(name: "Ahmed")
        session.practices.append(practice)
        session.cadets.append(cadet)
        // Higher is better for points-scored practices, so 40 (not 20) is the best.
        addFiring(to: session, sequenceNumber: 1, cadetID: cadet.id, practiceID: practice.id, score: 20, outcome: .fail)
        addFiring(to: session, sequenceNumber: 2, cadetID: cadet.id, practiceID: practice.id, score: 40, outcome: .pass)

        let rows = ButtRegisterBuilder.rows(for: session)
        let best = rows.first?.bestResult(for: practice.id)
        XCTAssertEqual(best?.score, 40)
        XCTAssertEqual(best?.outcome, .pass)
    }

    func testCadetWithNoFiringsHasNoResult() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let cadet = Cadet(name: "Never Fired")
        session.practices.append(practice)
        session.cadets.append(cadet)

        let rows = ButtRegisterBuilder.rows(for: session)
        XCTAssertFalse(rows.first?.bestResult(for: practice.id)?.hasResult ?? true)
    }

    func testCSVHasOneColumnPerPracticeAndEscapesCommas() throws {
        let session = Session(laneCount: 1)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let cadet = Cadet(name: "Smith, J")
        session.practices.append(practice)
        session.cadets.append(cadet)
        addFiring(to: session, sequenceNumber: 1, cadetID: cadet.id, practiceID: practice.id, score: 15, outcome: .pass)

        let rows = ButtRegisterBuilder.rows(for: session)
        let csv = ButtRegisterCSVExporter.csv(for: rows, practices: session.practices)
        XCTAssertTrue(csv.hasPrefix("Cadet,GP1"))
        XCTAssertTrue(csv.contains("\"Smith, J\",15"))
    }

    static let allTests: [(String, (ButtRegisterTests) -> () throws -> Void)] = [
        ("testReportsCadetNameAndBestStandardScore", testReportsCadetNameAndBestStandardScore),
        ("testVoidZeroScoresAreExcludedFromBestScore", testVoidZeroScoresAreExcludedFromBestScore),
        ("testReportsBestZeroingPairByLowestCombinedScore", testReportsBestZeroingPairByLowestCombinedScore),
        ("testReportsBestPointsScoreAsHighestNotLowest", testReportsBestPointsScoreAsHighestNotLowest),
        ("testCadetWithNoFiringsHasNoResult", testCadetWithNoFiringsHasNoResult),
        ("testCSVHasOneColumnPerPracticeAndEscapesCommas", testCSVHasOneColumnPerPracticeAndEscapesCommas),
    ]
}
