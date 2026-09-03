import SwiftUI

struct ResultsEntryView: View {
    @Bindable var store: SessionStore

    var body: some View {
        let firings = store.latestDetailFirings
        if !firings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Enter Results")
                ForEach(firings) { firing in
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
            if let outcome = firing.outcome {
                Label(
                    outcome == .pass ? "Pass" : "Fail",
                    systemImage: outcome == .pass ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(outcome == .pass ? Theme.pass : Theme.fail)
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
