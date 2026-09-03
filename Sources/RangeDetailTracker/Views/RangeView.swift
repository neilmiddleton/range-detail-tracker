import SwiftUI

@available(macOS 14.4, *)
struct RangeView: View {
    @Bindable var store: SessionStore

    var body: some View {
        HSplitView {
            ScrollView {
                LaneGridView(store: store)
                    .padding()
            }
            .frame(minWidth: 320)

            RosterPanelView(store: store)
                .frame(minWidth: 320)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
