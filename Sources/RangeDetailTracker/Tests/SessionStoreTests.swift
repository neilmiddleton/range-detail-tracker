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
        store.recordScore(firing: firing, score: 15, esScore: nil, pvScore: nil)
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

    func testRecordScoreWithZeroClearsPendingAndFails() throws {
        let (store, _) = makeStore(laneCount: 1)
        store.confirmDraft()
        XCTAssertTrue(store.hasPendingResults)
        let firing = try XCTUnwrap(store.session.details.first?.firings.first)
        // A genuine, explicitly-entered 0 (e.g. a range malfunction) must
        // still clear the pending-results block, not leave it stuck forever.
        store.recordScore(firing: firing, score: 0, esScore: nil, pvScore: nil)
        XCTAssertEqual(firing.outcome, .fail)
        XCTAssertFalse(store.hasPendingResults)
    }

    func testDetailSequenceNumbersBeforeAndAfterConfirm() throws {
        let (store, _) = makeStore(laneCount: 1)
        XCTAssertNil(store.currentDetailSequenceNumber)
        XCTAssertEqual(store.nextDetailSequenceNumber, 1)
        store.confirmDraft()
        XCTAssertEqual(store.currentDetailSequenceNumber, 1)
        XCTAssertEqual(store.nextDetailSequenceNumber, 2)
    }

    func testDraftStaysStaticUntilAllPendingResultsEntered() throws {
        let session = Session(laneCount: 2)
        let ar1 = Practice(name: "AR1", order: 0, scoringType: .standard, passMark: 20)
        let ar2 = Practice(name: "AR2", order: 1, scoringType: .standard, passMark: 20)
        session.practices.append(contentsOf: [ar1, ar2])
        session.lanes.append(Lane(number: 1))
        session.lanes.append(Lane(number: 2))
        let cadetA = Cadet(name: "Cadet A")
        let cadetB = Cadet(name: "Cadet B")
        session.cadets.append(contentsOf: [cadetA, cadetB])
        let store = SessionStore(session: session, persist: { _ in })

        store.confirmDraft()
        let firingA = try XCTUnwrap(store.session.details.first?.firings.first { $0.cadetID == cadetA.id })
        let firingB = try XCTUnwrap(store.session.details.first?.firings.first { $0.cadetID == cadetB.id })

        store.recordScore(firing: firingA, score: 10, esScore: nil, pvScore: nil)
        // Cadet B is still pending, so the next-detail draft must not reshuffle yet —
        // it should still show Cadet A queued for AR1, not the AR2 they just earned.
        XCTAssertTrue(store.hasPendingResults)
        XCTAssertEqual(store.draftDetail.firings.first { $0.cadetID == cadetA.id }?.practiceID, ar1.id)

        store.recordScore(firing: firingB, score: 25, esScore: nil, pvScore: nil)
        // Now every firing on the current detail has a result: the draft refreshes.
        XCTAssertFalse(store.hasPendingResults)
        XCTAssertEqual(store.draftDetail.firings.first { $0.cadetID == cadetA.id }?.practiceID, ar2.id)
        XCTAssertEqual(store.draftDetail.firings.first { $0.cadetID == cadetB.id }?.practiceID, ar1.id)
    }

    static let allTests: [(String, (SessionStoreTests) -> () throws -> Void)] = [
        ("testConfirmDraftCreatesDetailWithFirings", testConfirmDraftCreatesDetailWithFirings),
        ("testRecordScoreSetsDerivedOutcome", testRecordScoreSetsDerivedOutcome),
        ("testToggleLaneRemovesLaneFromDraft", testToggleLaneRemovesLaneFromDraft),
        ("testConfirmDraftClearsConsumedOverride", testConfirmDraftClearsConsumedOverride),
        ("testEditDraftLaneOverridesForNextConfirmOnly", testEditDraftLaneOverridesForNextConfirmOnly),
        ("testPersistIsCalledOnEveryMutation", testPersistIsCalledOnEveryMutation),
        ("testRecordScoreWithZeroClearsPendingAndFails", testRecordScoreWithZeroClearsPendingAndFails),
        ("testDetailSequenceNumbersBeforeAndAfterConfirm", testDetailSequenceNumbersBeforeAndAfterConfirm),
        ("testDraftStaysStaticUntilAllPendingResultsEntered", testDraftStaysStaticUntilAllPendingResultsEntered),
    ]
}
