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
                .tint(Theme.accentFill)
            }
            TableColumnForEach(practices) { practice in
                TableColumn(practice.name) { cadet in
                    outcomeIcon(for: latestOutcome(practiceID: practice.id, for: cadet))
                }
            }
        }
    }

    @ViewBuilder
    private func outcomeIcon(for outcome: Outcome?) -> some View {
        switch outcome {
        case .pass:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.pass)
        case .fail:
            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.fail)
        case nil:
            Text("—").foregroundStyle(.tertiary)
        }
    }

    private func latestOutcome(practiceID: UUID, for cadet: Cadet) -> Outcome? {
        let records = firingRecords(for: cadet).filter { $0.practiceID == practiceID }
        if records.contains(where: { $0.outcome == .pass }) {
            return .pass
        } else if records.contains(where: { $0.outcome == .fail }) {
            return .fail
        } else {
            return nil
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
