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

    func testCSVEscapesCadetNamesContainingDoubleQuotes() throws {
        let session = try makeSessionWithOneFiring()
        session.cadets[0].name = "Smith \"Ace\" J"
        let rows = ButtRegisterBuilder.rows(for: session)
        let csv = ButtRegisterCSVExporter.csv(for: rows)
        XCTAssertTrue(csv.contains("\"Smith \"\"Ace\"\" J\""))
    }

    static let allTests: [(String, (ButtRegisterTests) -> () throws -> Void)] = [
        ("testRowsAreOrderedByDetailThenLane", testRowsAreOrderedByDetailThenLane),
        ("testCSVEscapesCadetNamesContainingCommas", testCSVEscapesCadetNamesContainingCommas),
        ("testCSVEscapesCadetNamesContainingDoubleQuotes", testCSVEscapesCadetNamesContainingDoubleQuotes),
    ]
}
