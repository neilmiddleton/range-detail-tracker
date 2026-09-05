import AppKit
import SwiftUI

struct RangeView: View {
    @Bindable var store: SessionStore
    var onEndSession: () -> Void
    @State private var showingButtRegister = false
    @State private var topPaneFraction: CGFloat = 0.5
    @State private var dragStartTopHeight: CGFloat?

    private let dividerHitHeight: CGFloat = 8
    private let minPaneFraction: CGFloat = 0.2
    private let maxPaneFraction: CGFloat = 0.8

    var body: some View {
        GeometryReader { geometry in
            let topHeight = geometry.size.height * topPaneFraction
            let bottomHeight = geometry.size.height - topHeight - dividerHitHeight

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LanePanelView(store: store)
                    }
                    .padding()
                }
                .frame(height: topHeight)

                dragHandle(totalHeight: geometry.size.height, currentTopHeight: topHeight)

                VStack(alignment: .leading, spacing: 16) {
                    RosterPanelView(store: store)
                    ScrollView {
                        DetailHistoryView(store: store)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .frame(height: bottomHeight)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .tint(Theme.accentFill)
        .dynamicTypeSize(.large)
        .toolbar {
            Button {
                onEndSession()
            } label: {
                Label("Setup", systemImage: "gearshape")
            }
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

    @ViewBuilder
    private func dragHandle(totalHeight: CGFloat, currentTopHeight: CGFloat) -> some View {
        ZStack {
            Divider()
        }
        .frame(height: dividerHitHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let startHeight = dragStartTopHeight ?? currentTopHeight
                    dragStartTopHeight = startHeight
                    let proposedHeight = startHeight + value.translation.height
                    topPaneFraction = min(max(proposedHeight / totalHeight, minPaneFraction), maxPaneFraction)
                }
                .onEnded { _ in
                    dragStartTopHeight = nil
                }
        )
    }
}
