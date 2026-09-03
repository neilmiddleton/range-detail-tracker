import Foundation

if let flagIndex = CommandLine.arguments.firstIndex(of: "--run-tests") {
    let filter = CommandLine.arguments.count > flagIndex + 1 ? CommandLine.arguments[flagIndex + 1] : nil
    runAllTests(filter: filter)
} else {
    RangeDetailTrackerApp.main()
}
