import SwiftUI

struct LaneGridView: View {
    @Bindable var store: SessionStore

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.session.lanes.sorted { $0.number < $1.number }) { lane in
                laneTile(lane)
            }
        }
    }

    @ViewBuilder
    private func laneTile(_ lane: Lane) -> some View {
        let draftFiring = store.displayedDraft.firings.first { $0.laneNumber == lane.number }
        let cadetName = draftFiring?.cadetID.flatMap { id in store.session.cadets.first { $0.id == id }?.name }
        let practiceName = draftFiring?.practiceID.flatMap { id in store.session.practices.first { $0.id == id }?.name }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Lane \(lane.number)").font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { lane.active },
                    set: { _ in store.toggleLane(lane.number) }
                ))
                .labelsHidden()
            }
            if lane.active {
                Text(cadetName ?? "Idle")
                Text(practiceName ?? "—").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Out of commission").font(.caption).foregroundStyle(.red)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
