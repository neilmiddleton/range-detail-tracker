import Foundation
import Observation

@Observable
final class SessionStore {
    let session: Session
    private let persist: (Session) -> Void
    private var manualEdits: [Int: DraftFiring] = [:]

    init(session: Session, persist: @escaping (Session) -> Void = SessionPersistence.save) {
        self.session = session
        self.persist = persist
    }

    private var practiceSnapshots: [PracticeSnapshot] {
        session.practices.map {
            PracticeSnapshot(id: $0.id, name: $0.name, order: $0.order, scoringType: $0.scoringType, passMark: $0.passMark, esPassMark: $0.esPassMark, pvPassMark: $0.pvPassMark)
        }
    }

    private var cadetSnapshots: [CadetSnapshot] {
        session.cadets.map { CadetSnapshot(id: $0.id, name: $0.name, nextOverridePracticeID: $0.nextOverridePracticeID) }
    }

    private var laneSnapshots: [LaneSnapshot] {
        session.lanes.map { LaneSnapshot(number: $0.number, active: $0.active) }
    }

    private var firingRecords: [FiringRecord] {
        session.details.flatMap { detail in
            detail.firings.map { firing in
                FiringRecord(id: firing.id, detailID: detail.id, sequenceNumber: detail.sequenceNumber, firedAt: detail.firedAt, laneNumber: firing.laneNumber, cadetID: firing.cadetID, practiceID: firing.practiceID, score: firing.score, esScore: firing.esScore, pvScore: firing.pvScore, outcome: firing.outcome)
            }
        }
    }

    /// The live, freshly computed "up next" detail — recomputes on every access.
    var draftDetail: DraftDetail {
        DraftDetailGenerator.nextDetail(cadets: cadetSnapshots, practices: practiceSnapshots, lanes: laneSnapshots, firings: firingRecords)
    }

    /// `draftDetail` with any in-progress manual edits applied, for display and confirm.
    var displayedDraft: DraftDetail {
        let base = draftDetail
        let firings = base.firings.map { manualEdits[$0.laneNumber] ?? $0 }
        return DraftDetail(firings: firings)
    }

    func editDraftLane(_ laneNumber: Int, cadetID: UUID?, practiceID: UUID?) {
        manualEdits[laneNumber] = DraftFiring(laneNumber: laneNumber, cadetID: cadetID, practiceID: practiceID)
    }

    func confirmDraft() {
        let detail = Detail(sequenceNumber: session.details.count + 1)
        for draftFiring in displayedDraft.firings where draftFiring.cadetID != nil && draftFiring.practiceID != nil {
            let firing = Firing(laneNumber: draftFiring.laneNumber, cadetID: draftFiring.cadetID!, practiceID: draftFiring.practiceID!)
            detail.firings.append(firing)
        }
        session.details.append(detail)
        clearConsumedOverrides(for: detail)
        manualEdits.removeAll()
        persist(session)
    }

    private func clearConsumedOverrides(for detail: Detail) {
        let firedCadetIDs = Set(detail.firings.map(\.cadetID))
        for cadet in session.cadets where firedCadetIDs.contains(cadet.id) {
            cadet.nextOverridePracticeID = nil
        }
    }

    func recordScore(firing: Firing, score: Int?, esScore: Int?, pvScore: Int?) {
        guard let practice = session.practices.first(where: { $0.id == firing.practiceID }) else { return }
        firing.score = score
        firing.esScore = esScore
        firing.pvScore = pvScore
        let snapshot = PracticeSnapshot(id: practice.id, name: practice.name, order: practice.order, scoringType: practice.scoringType, passMark: practice.passMark, esPassMark: practice.esPassMark, pvPassMark: practice.pvPassMark)
        firing.outcome = ScoringRule.outcome(for: snapshot, score: score, esScore: esScore, pvScore: pvScore)
        persist(session)
    }

    func toggleLane(_ number: Int) {
        guard let lane = session.lanes.first(where: { $0.number == number }) else { return }
        lane.active.toggle()
        persist(session)
    }

    /// True if the most recently fired detail has any firing still awaiting a score.
    var hasPendingResults: Bool {
        guard let latest = session.details.max(by: { $0.sequenceNumber < $1.sequenceNumber }) else { return false }
        return latest.firings.contains { $0.outcome == nil }
    }

    /// Firings on the most recent detail still awaiting a score, in lane order.
    var pendingFirings: [Firing] {
        guard let latest = session.details.max(by: { $0.sequenceNumber < $1.sequenceNumber }) else { return [] }
        return latest.firings.filter { $0.outcome == nil }.sorted { $0.laneNumber < $1.laneNumber }
    }

    /// All firings on the most recent detail, in lane order (for reviewing/correcting scores).
    var latestDetailFirings: [Firing] {
        guard let latest = session.details.max(by: { $0.sequenceNumber < $1.sequenceNumber }) else { return [] }
        return latest.firings.sorted { $0.laneNumber < $1.laneNumber }
    }

    /// Sequence number of the most recently confirmed detail (the one currently being scored), if any.
    var currentDetailSequenceNumber: Int? {
        session.details.map(\.sequenceNumber).max()
    }

    /// Sequence number the next confirmed detail will get.
    var nextDetailSequenceNumber: Int {
        session.details.count + 1
    }

    func setOverride(cadetID: UUID, practiceID: UUID?) {
        guard let cadet = session.cadets.first(where: { $0.id == cadetID }) else { return }
        cadet.nextOverridePracticeID = practiceID
        persist(session)
    }
}
