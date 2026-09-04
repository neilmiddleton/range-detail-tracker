import SwiftUI

struct LaneGridView: View {
    @Bindable var store: SessionStore

    private let laneWidth: CGFloat = 160

    var body: some View {
        // Lanes are laid out left-to-right in a single row, matching how
        // firing points are physically arranged on the range.
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(store.session.lanes.sorted { $0.number < $1.number }) { lane in
                    laneTile(lane)
                        .frame(width: laneWidth)
                }
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
                .tint(Theme.accentFill)
            }
            if lane.active {
                Text(cadetName ?? "Idle")
                Text(practiceName ?? "—").font(.caption).foregroundStyle(.secondary)
            } else {
                Label("Out of commission", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.fail)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(lane.active && cadetName != nil ? Theme.accentFill.opacity(0.6) : .clear, lineWidth: 2)
        )
    }
}
