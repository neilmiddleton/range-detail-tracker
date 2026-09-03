import SwiftUI

struct DetailHistoryView: View {
    let store: SessionStore

    var body: some View {
        let details = store.session.details.sorted { $0.sequenceNumber > $1.sequenceNumber }
        VStack(alignment: .leading, spacing: 8) {
            Text("History").font(.title2)
            if details.isEmpty {
                Text("No details fired yet.").foregroundStyle(.secondary)
            }
            ForEach(details) { detail in
                DisclosureGroup("Detail \(detail.sequenceNumber)") {
                    ForEach(detail.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
                        let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
                        let practiceName = store.session.practices.first { $0.id == firing.practiceID }?.name ?? "?"
                        Text("Lane \(firing.laneNumber): \(cadetName) — \(practiceName) — \(outcomeText(firing))")
                    }
                }
            }
        }
        .padding()
    }

    private func outcomeText(_ firing: Firing) -> String {
        switch firing.outcome {
        case .pass: return "PASS"
        case .fail: return "FAIL"
        case nil: return "pending"
        }
    }
}
