import SwiftUI

/// One combined per-lane control: who is on the lane now and their score,
/// who is prepped for the next detail, and the out-of-commission toggle —
/// all keyed by lane, since that's how the RCO actually scans the range.
struct LanePanelView: View {
    @Bindable var store: SessionStore

    private let laneWidth: CGFloat = 220
    private let laneCardMinHeight: CGFloat = 210

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Lanes")
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(store.session.lanes.sorted { $0.number < $1.number }) { lane in
                        laneCard(lane)
                            .frame(width: laneWidth)
                    }
                }
            }
            confirmBar
        }
    }

    @ViewBuilder
    private func laneCard(_ lane: Lane) -> some View {
        let currentFiring = store.latestDetailFirings.first { $0.laneNumber == lane.number }
        let draftFiring = store.displayedDraft.firings.first { $0.laneNumber == lane.number }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lane \(lane.number)").font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { lane.active },
                    set: { _ in store.toggleLane(lane.number) }
                ))
                .labelsHidden()
                .tint(Theme.accentFill)
            }

            Divider()
            currentSection(currentFiring)
            Divider()
            nextSection(lane: lane, draftFiring: draftFiring)
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: laneCardMinHeight, alignment: .topLeading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(lane.active ? Theme.accentFill.opacity(0.6) : Theme.fail.opacity(0.6), lineWidth: 2)
        )
    }

    @ViewBuilder
    private func currentSection(_ firing: Firing?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.currentDetailSequenceNumber.map { "Current — Detail \($0)" } ?? "Current")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let firing {
                let cadetName = store.session.cadets.first { $0.id == firing.cadetID }?.name ?? "?"
                let practice = store.session.practices.first { $0.id == firing.practiceID }
                Text("\(cadetName) — \(practice?.name ?? "?")")
                scoreFields(firing: firing, practice: practice)
                if let outcome = firing.outcome {
                    Label(
                        outcome == .pass ? "Pass" : "Fail",
                        systemImage: outcome == .pass ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(outcome == .pass ? Theme.pass : Theme.fail)
                } else {
                    Text("Not yet entered").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Idle").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func scoreFields(firing: Firing, practice: Practice?) -> some View {
        if practice?.scoringType == .zeroing {
            HStack {
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
            }
        } else {
            scoreField("Score", text: Binding(
                get: { firing.score.map(String.init) ?? "" },
                set: { newValue in
                    guard let intValue = Int(newValue.trimmingCharacters(in: .whitespaces)) else { return }
                    store.recordScore(firing: firing, score: intValue, esScore: nil, pvScore: nil)
                }
            ))
        }
    }

    private func scoreField(_ label: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption)
            TextField(label, text: text)
                .frame(width: 50)
        }
    }

    @ViewBuilder
    private func nextSection(lane: Lane, draftFiring: DraftFiring?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next — Detail \(store.nextDetailSequenceNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if !lane.active {
                Label("Out of commission", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.fail)
            } else if let draftFiring {
                Picker("Cadet", selection: Binding(
                    get: { draftFiring.cadetID },
                    set: { newCadetID in
                        store.editDraftLane(lane.number, cadetID: newCadetID, practiceID: draftFiring.practiceID ?? store.session.practices.first?.id)
                    }
                )) {
                    Text("— Idle —").tag(UUID?.none)
                    ForEach(store.session.cadets.sorted { $0.name < $1.name }) { cadet in
                        Text(cadet.name).tag(Optional(cadet.id))
                    }
                }
                .labelsHidden()

                Picker("Practice", selection: Binding(
                    get: { draftFiring.practiceID },
                    set: { newPracticeID in
                        store.editDraftLane(lane.number, cadetID: draftFiring.cadetID, practiceID: newPracticeID)
                    }
                )) {
                    Text("—").tag(UUID?.none)
                    ForEach(store.session.practices.sorted { $0.order < $1.order }) { practice in
                        Text(practice.name).tag(Optional(practice.id))
                    }
                }
                .labelsHidden()
                .disabled(draftFiring.cadetID == nil)
            } else {
                Text("Idle").foregroundStyle(.secondary)
            }
        }
    }

    private var confirmBar: some View {
        HStack(spacing: 12) {
            Button("Confirm Fired — Detail \(store.nextDetailSequenceNumber)") {
                store.confirmDraft()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentFill)
            .disabled(store.displayedDraft.firings.allSatisfy { $0.cadetID == nil } || store.hasPendingResults)

            if store.hasPendingResults {
                Text("Score all firings from the previous detail before confirming a new one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }
}
