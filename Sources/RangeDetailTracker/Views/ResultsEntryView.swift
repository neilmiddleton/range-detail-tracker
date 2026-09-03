import SwiftUI

struct ResultsEntryView: View {
    @Bindable var store: SessionStore

    private var pendingFirings: [Firing] {
        guard let latest = store.session.details.max(by: { $0.sequenceNumber < $1.sequenceNumber }) else { return [] }
        return latest.firings.filter { $0.outcome == nil }.sorted { $0.laneNumber < $1.laneNumber }
    }

    var body: some View {
        if !pendingFirings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Results").font(.title2)
                ForEach(pendingFirings) { firing in
                    resultRow(firing)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func resultRow(_ firing: Firing) -> some View {
        let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
        let practice = store.session.practices.first { $0.id == firing.practiceID }

        HStack {
            Text("Lane \(firing.laneNumber): \(cadetName)").frame(width: 220, alignment: .leading)
            if practice?.scoringType == .zeroing {
                scoreField("ES", value: Binding(
                    get: { firing.esScore ?? 0 },
                    set: { store.recordScore(firing: firing, score: nil, esScore: $0, pvScore: firing.pvScore) }
                ))
                scoreField("PV", value: Binding(
                    get: { firing.pvScore ?? 0 },
                    set: { store.recordScore(firing: firing, score: nil, esScore: firing.esScore, pvScore: $0) }
                ))
            } else {
                scoreField("Score", value: Binding(
                    get: { firing.score ?? 0 },
                    set: { store.recordScore(firing: firing, score: $0, esScore: nil, pvScore: nil) }
                ))
            }
        }
    }

    private func scoreField(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
            TextField(label, value: value, format: .number)
                .frame(width: 60)
        }
    }
}
