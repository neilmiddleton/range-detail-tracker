import SwiftUI

struct RangeView: View {
    let store: SessionStore

    var body: some View {
        Text("Session started with \(store.session.cadets.count) cadets")
            .padding()
    }
}
