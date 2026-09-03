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
                    if let cadetID = firing.cadetID, let practiceID = firing.practiceID {
                        let cadetName = store.session.cadets.first { $0.id == cadetID }?.name ?? "?"
                        let practiceName = store.session.practices.first { $0.id == practiceID }?.name ?? "?"
                        Text("Lane \(firing.laneNumber): \(cadetName) — \(practiceName)")
                    }
                }
            }
            Button("Confirm Fired") {
                store.confirmDraft()
            }
            .disabled(store.displayedDraft.firings.allSatisfy { $0.cadetID == nil })
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
