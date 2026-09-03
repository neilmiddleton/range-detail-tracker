import SwiftUI

@available(macOS 14.4, *)
struct RosterPanelView: View {
    let store: SessionStore

    var body: some View {
        let practices = store.session.practices.sorted { $0.order < $1.order }
        Table(store.session.cadets.sorted { $0.name < $1.name }) {
            TableColumn("Cadet") { cadet in Text(cadet.name) }
            TableColumn("Current") { cadet in
                let current = ProgressionRule.currentPractice(
                    for: cadet.id,
                    practices: practices.map {
                        PracticeSnapshot(id: $0.id, name: $0.name, order: $0.order, scoringType: $0.scoringType, passMark: $0.passMark, esPassMark: $0.esPassMark, pvPassMark: $0.pvPassMark)
                    },
                    firings: firingRecords(for: cadet)
                )
                Text(current?.name ?? "—")
            }
            TableColumnForEach(practices) { practice in
                TableColumn(practice.name) { cadet in
                    let passed = ProgressionRule.hasPassed(practiceID: practice.id, cadetID: cadet.id, firings: firingRecords(for: cadet))
                    Text(passed ? "✓" : "")
                }
            }
        }
    }

    private func firingRecords(for cadet: Cadet) -> [FiringRecord] {
        store.session.details.flatMap { detail in
            detail.firings
                .filter { $0.cadetID == cadet.id }
                .map { firing in
                    FiringRecord(id: firing.id, detailID: detail.id, sequenceNumber: detail.sequenceNumber, firedAt: detail.firedAt, laneNumber: firing.laneNumber, cadetID: firing.cadetID, practiceID: firing.practiceID, score: firing.score, esScore: firing.esScore, pvScore: firing.pvScore, outcome: firing.outcome)
                }
        }
    }
}
