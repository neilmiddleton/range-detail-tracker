final class SessionStoreTests: XCTestCase {
    func makeStore(laneCount: Int = 2) -> (store: SessionStore, practice: Practice) {
        let session = Session(laneCount: laneCount)
        let practice = Practice(name: "AR1", order: 0, scoringType: .standard, passMark: 20)
        session.practices.append(practice)
        for number in 1...laneCount {
            session.lanes.append(Lane(number: number))
        }
        session.cadets.append(Cadet(name: "Cadet A"))
        return (SessionStore(session: session, persist: { _ in }), practice)
    }

    func testConfirmDraftCreatesDetailWithFirings() throws {
        let (store, _) = makeStore(laneCount: 1)
        XCTAssertEqual(store.session.details.count, 0)
        store.confirmDraft()
        XCTAssertEqual(store.session.details.count, 1)
        XCTAssertEqual(store.session.details.first?.firings.count, 1)
    }

    func testRecordScoreSetsDerivedOutcome() throws {
        let (store, _) = makeStore(laneCount: 1)
        store.confirmDraft()
        let firing = try XCTUnwrap(store.session.details.first?.firings.first)
        store.recordScore(firing: firing, score: 25, esScore: nil, pvScore: nil)
        XCTAssertEqual(firing.outcome, .pass)
    }

    func testToggleLaneRemovesLaneFromDraft() throws {
        let (store, _) = makeStore(laneCount: 2)
        store.toggleLane(2)
        XCTAssertEqual(store.draftDetail.firings.map(\.laneNumber), [1])
    }

    func testConfirmDraftClearsConsumedOverride() throws {
        let (store, practice) = makeStore(laneCount: 1)
        let cadet = try XCTUnwrap(store.session.cadets.first)
        store.setOverride(cadetID: cadet.id, practiceID: practice.id)
        XCTAssertEqual(cadet.nextOverridePracticeID, practice.id)
        store.confirmDraft()
        XCTAssertNil(cadet.nextOverridePracticeID)
    }

    func testEditDraftLaneOverridesForNextConfirmOnly() throws {
        let (store, _) = makeStore(laneCount: 1)
        store.editDraftLane(1, cadetID: nil, practiceID: nil)
        XCTAssertNil(store.displayedDraft.firings.first?.cadetID)
        store.confirmDraft()
        XCTAssertEqual(store.session.details.first?.firings.count, 0)
        // Edits are one-shot: the next draft is computed fresh, not from the edited state.
        XCTAssertNotNil(store.draftDetail.firings.first?.cadetID)
    }

    func testPersistIsCalledOnEveryMutation() throws {
        let session = Session(laneCount: 1)
        session.lanes.append(Lane(number: 1))
        var savedCount = 0
        let store = SessionStore(session: session, persist: { _ in savedCount += 1 })
        store.toggleLane(1)
        XCTAssertEqual(savedCount, 1)
    }

    static let allTests: [(String, (SessionStoreTests) -> () throws -> Void)] = [
        ("testConfirmDraftCreatesDetailWithFirings", testConfirmDraftCreatesDetailWithFirings),
        ("testRecordScoreSetsDerivedOutcome", testRecordScoreSetsDerivedOutcome),
        ("testToggleLaneRemovesLaneFromDraft", testToggleLaneRemovesLaneFromDraft),
        ("testConfirmDraftClearsConsumedOverride", testConfirmDraftClearsConsumedOverride),
        ("testEditDraftLaneOverridesForNextConfirmOnly", testEditDraftLaneOverridesForNextConfirmOnly),
        ("testPersistIsCalledOnEveryMutation", testPersistIsCalledOnEveryMutation),
    ]
}
