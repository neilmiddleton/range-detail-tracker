import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore
    @State private var showingButtRegister = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LanePanelView(store: store)
                    }
                    .padding()
                }
                .frame(height: geometry.size.height / 2)

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    RosterPanelView(store: store)
                    ScrollView {
                        DetailHistoryView(store: store)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .frame(height: geometry.size.height / 2)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .tint(Theme.accentFill)
        .dynamicTypeSize(.large)
        .toolbar {
            Button {
                showingButtRegister = true
            } label: {
                Label("Butt Register", systemImage: "list.bullet.clipboard")
            }
        }
        .sheet(isPresented: $showingButtRegister) {
            ButtRegisterView(store: store)
                .tint(Theme.accentFill)
        }
    }
}
