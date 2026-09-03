import SwiftUI

struct DraftDetailPanelView: View {
    @Bindable var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Up Next").font(.title2)
            let draft = store.displayedDraft
            if draft.firings.allSatisfy({ $0.cadetID == nil }) {
                Text("No cadets eligible for the active lanes.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(draft.firings.sorted { $0.laneNumber < $1.laneNumber }) { firing in
                    HStack {
                        Text("Lane \(firing.laneNumber)").frame(width: 60, alignment: .leading)

                        Picker("Cadet", selection: Binding(
                            get: { firing.cadetID },
                            set: { newCadetID in
                                store.editDraftLane(firing.laneNumber, cadetID: newCadetID, practiceID: firing.practiceID ?? store.session.practices.first?.id)
                            }
                        )) {
                            Text("— Idle —").tag(UUID?.none)
                            ForEach(store.session.cadets.sorted { $0.name < $1.name }) { cadet in
                                Text(cadet.name).tag(Optional(cadet.id))
                            }
                        }
                        .labelsHidden()

                        Picker("Practice", selection: Binding(
                            get: { firing.practiceID },
                            set: { newPracticeID in
                                store.editDraftLane(firing.laneNumber, cadetID: firing.cadetID, practiceID: newPracticeID)
                            }
                        )) {
                            Text("—").tag(UUID?.none)
                            ForEach(store.session.practices.sorted { $0.order < $1.order }) { practice in
                                Text(practice.name).tag(Optional(practice.id))
                            }
                        }
                        .labelsHidden()
                        .disabled(firing.cadetID == nil)
                    }
                }
            }
            Button("Confirm Fired") {
                store.confirmDraft()
            }
            .disabled(store.displayedDraft.firings.allSatisfy { $0.cadetID == nil } || store.hasPendingResults)
            if store.hasPendingResults {
                Text("Score all firings from the previous detail before confirming a new one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
