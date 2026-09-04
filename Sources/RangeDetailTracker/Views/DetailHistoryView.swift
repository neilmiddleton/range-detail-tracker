import SwiftUI

struct DetailHistoryView: View {
    let store: SessionStore

    private struct Row: Identifiable {
        var id: UUID { firing.id }
        let detailSequenceNumber: Int
        let firing: Firing
    }

    private var rows: [Row] {
        store.session.details
            .sorted { $0.sequenceNumber > $1.sequenceNumber }
            .flatMap { detail in
                detail.firings
                    .sorted { $0.laneNumber < $1.laneNumber }
                    .map { Row(detailSequenceNumber: detail.sequenceNumber, firing: $0) }
            }
    }

    var body: some View {
        let rows = rows
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "History")
            if rows.isEmpty {
                Text("No details fired yet.").foregroundStyle(.secondary)
            } else {
                // Every fire from every detail so far, newest detail first —
                // a single glanceable table rather than one you have to
                // expand detail by detail.
                Table(rows) {
                    TableColumn("Detail") { row in Text("\(row.detailSequenceNumber)") }
                    TableColumn("Lane") { row in Text("\(row.firing.laneNumber)") }
                    TableColumn("Cadet") { row in Text(cadetName(for: row.firing)) }
                    TableColumn("Practice") { row in Text(practiceName(for: row.firing)) }
                    TableColumn("Score") { row in Text(row.firing.score.map(String.init) ?? "") }
                    TableColumn("ES") { row in Text(row.firing.esScore.map(String.init) ?? "") }
                    TableColumn("PV") { row in Text(row.firing.pvScore.map(String.init) ?? "") }
                    TableColumn("Outcome") { row in outcomeLabel(row.firing) }
                }
                .frame(minHeight: CGFloat(rows.count) * 28 + 30)
            }
        }
        .padding()
    }

    private func cadetName(for firing: Firing) -> String {
        store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
    }

    private func practiceName(for firing: Firing) -> String {
        store.session.practices.first { $0.id == firing.practiceID }?.name ?? "?"
    }

    @ViewBuilder
    private func outcomeLabel(_ firing: Firing) -> some View {
        switch firing.outcome {
        case .pass:
            Label("Pass", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.pass)
        case .fail:
            Label("Fail", systemImage: "xmark.circle.fill").foregroundStyle(Theme.fail)
        case nil:
            Text("Pending").foregroundStyle(.secondary)
        }
    }
}
