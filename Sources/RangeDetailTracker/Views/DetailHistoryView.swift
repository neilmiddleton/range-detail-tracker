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
                    ForEach(detail.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
                        let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
                        let practiceName = store.session.practices.first { $0.id == firing.practiceID }?.name ?? "?"
                        HStack {
                            Text("Lane \(firing.laneNumber): \(cadetName) — \(practiceName)")
                            Spacer()
                            outcomeLabel(firing)
                        }
                    }
                }
            }
        }
        .padding()
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
