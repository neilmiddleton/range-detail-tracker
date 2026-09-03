import Foundation

final class ModelPersistenceTests: XCTestCase {
    func testSessionRoundTripsThroughJSON() throws {
        let session = Session(laneCount: 5)
        let practice = Practice(name: "GP1", order: 0, scoringType: .standard, passMark: 20)
        let lane = Lane(number: 1)
        let cadet = Cadet(name: "Test Cadet")
        session.practices.append(practice)
        session.lanes.append(lane)
        session.cadets.append(cadet)

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(Session.self, from: data)

        XCTAssertEqual(decoded.laneCount, 5)
        XCTAssertEqual(decoded.practices.count, 1)
        XCTAssertEqual(decoded.practices.first?.name, "GP1")
        XCTAssertEqual(decoded.lanes.first?.number, 1)
        XCTAssertEqual(decoded.cadets.first?.name, "Test Cadet")
    }

    static let allTests: [(String, (ModelPersistenceTests) -> () throws -> Void)] = [
        ("testSessionRoundTripsThroughJSON", testSessionRoundTripsThroughJSON),
    ]
}
