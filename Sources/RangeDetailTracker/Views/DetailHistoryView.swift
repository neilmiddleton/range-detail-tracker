import SwiftUI

struct DetailHistoryView: View {
    let store: SessionStore

    var body: some View {
        let details = store.session.details.sorted { $0.sequenceNumber > $1.sequenceNumber }
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "History")
            if details.isEmpty {
                Text("No details fired yet.").foregroundStyle(.secondary)
            }
            ForEach(details) { detail in
                DisclosureGroup("Detail \(detail.sequenceNumber)") {
                    let firings = detail.firings.sorted { $0.laneNumber < $1.laneNumber }
                    Table(firings) {
                        TableColumn("Lane") { firing in Text("\(firing.laneNumber)") }
                        TableColumn("Cadet") { firing in Text(cadetName(for: firing)) }
                        TableColumn("Practice") { firing in Text(practiceName(for: firing)) }
                        TableColumn("Score") { firing in Text(firing.score.map(String.init) ?? "") }
                        TableColumn("ES") { firing in Text(firing.esScore.map(String.init) ?? "") }
                        TableColumn("PV") { firing in Text(firing.pvScore.map(String.init) ?? "") }
                        TableColumn("Outcome") { firing in outcomeLabel(firing) }
                    }
                    .frame(minHeight: CGFloat(firings.count) * 28 + 30)
                }
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
