import SwiftUI

struct RosterPanelView: View {
    @Bindable var store: SessionStore

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
            TableColumn("Next") { cadet in
                Picker("Next", selection: Binding(
                    get: { cadet.nextOverridePracticeID },
                    set: { store.setOverride(cadetID: cadet.id, practiceID: $0) }
                )) {
                    Text("—").tag(UUID?.none)
                    ForEach(practices) { practice in
                        Text(practice.name).tag(Optional(practice.id))
                    }
                }
                .labelsHidden()
            }
            TableColumnForEach(practices) { practice in
                TableColumn(practice.name) { cadet in
                    Text(latestOutcomeSymbol(practiceID: practice.id, for: cadet))
                }
            }
        }
    }

    private func latestOutcomeSymbol(practiceID: UUID, for cadet: Cadet) -> String {
        let records = firingRecords(for: cadet).filter { $0.practiceID == practiceID }
        if records.contains(where: { $0.outcome == .pass }) {
            return "✓"
        } else if records.contains(where: { $0.outcome == .fail }) {
            return "✗"
        } else {
            return ""
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
