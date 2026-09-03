import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore
    @State private var showingButtRegister = false

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

            VStack(alignment: .leading, spacing: 16) {
                RosterPanelView(store: store)
                ScrollView {
                    DetailHistoryView(store: store)
                        .padding(.horizontal)
                }
            }
            .padding()
            .frame(minWidth: 320)
        }
        .frame(minWidth: 800, minHeight: 500)
        .toolbar {
            Button("Butt Register") { showingButtRegister = true }
        }
        .sheet(isPresented: $showingButtRegister) {
            ButtRegisterView(store: store)
        }
    }
}
