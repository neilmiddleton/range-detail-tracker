import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ResultsEntryView(store: store)
                    DraftDetailPanelView(store: store)
                    LaneGridView(store: store)
                }
                .padding()
            }
            .frame(minWidth: 320)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RosterPanelView(store: store)
                    DetailHistoryView(store: store)
                }
                .padding()
            }
            .frame(minWidth: 320)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
