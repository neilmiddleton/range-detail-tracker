import SwiftUI

struct ResultsEntryView: View {
    @Bindable var store: SessionStore

    var body: some View {
        let firings = store.latestDetailFirings
        if !firings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Enter Results — Detail \(store.currentDetailSequenceNumber ?? 0)")
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
                scoreField("ES", text: Binding(
                    get: { firing.esScore.map(String.init) ?? "" },
                    set: { newValue in
                        guard let intValue = Int(newValue.trimmingCharacters(in: .whitespaces)) else { return }
                        store.recordScore(firing: firing, score: nil, esScore: intValue, pvScore: firing.pvScore)
                    }
                ))
                scoreField("PV", text: Binding(
                    get: { firing.pvScore.map(String.init) ?? "" },
                    set: { newValue in
                        guard let intValue = Int(newValue.trimmingCharacters(in: .whitespaces)) else { return }
                        store.recordScore(firing: firing, score: nil, esScore: firing.esScore, pvScore: intValue)
                    }
                ))
            } else {
                scoreField("Score", text: Binding(
                    get: { firing.score.map(String.init) ?? "" },
                    set: { newValue in
                        guard let intValue = Int(newValue.trimmingCharacters(in: .whitespaces)) else { return }
                        store.recordScore(firing: firing, score: intValue, esScore: nil, pvScore: nil)
                    }
                ))
            }
            if let outcome = firing.outcome {
                Label(
                    outcome == .pass ? "Pass" : "Fail",
                    systemImage: outcome == .pass ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(outcome == .pass ? Theme.pass : Theme.fail)
            } else {
                Text("Not yet entered").foregroundStyle(.secondary)
            }
        }
    }

    private func scoreField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            TextField(label, text: text)
                .frame(width: 60)
        }
    }
}
