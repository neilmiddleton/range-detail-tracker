import SwiftUI
import AppKit

/// Shared colour palette, styled after RAFAC's navy/RAF-blue identity.
/// Each colour adapts between light and dark appearance so it always reads
/// correctly, regardless of the system's current appearance setting.
enum Theme {
    /// Primary accent: deep RAF navy in light mode, a lighter RAF blue in dark
    /// mode (plain navy text would be nearly invisible on a dark background).
    static let accent = Color.adaptive(
        light: NSColor(red: 0.02, green: 0.16, blue: 0.35, alpha: 1),
        dark: NSColor(red: 0.55, green: 0.75, blue: 0.92, alpha: 1)
    )

    /// A solid navy fill for prominent buttons and accent bars — always paired
    /// with light/white foreground content, so it doesn't need to adapt.
    static let accentFill = Color(red: 0.02, green: 0.16, blue: 0.35)

    static let pass = Color.green
    static let fail = Color.red
}

extension Color {
    /// A colour that switches between two `NSColor`s based on the system's
    /// current light/dark appearance.
    static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

/// A section title styled consistently across the app: bold, accented, with a
/// leading navy bar.
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.accentFill)
                .frame(width: 4, height: 18)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
    }
}
