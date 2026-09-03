import AppKit
import Foundation

if let flagIndex = CommandLine.arguments.firstIndex(of: "--run-tests") {
    let filter = CommandLine.arguments.count > flagIndex + 1 ? CommandLine.arguments[flagIndex + 1] : nil
    runAllTests(filter: filter)
} else {
    // `swift run` launches this as a bare process with no app bundle, so
    // AppKit defaults to an "accessory" activation policy that can never
    // become key/frontmost. Force a normal foreground app so the window
    // can actually receive keyboard focus.
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
    RangeDetailTrackerApp.main()
}
