// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RangeDetailTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RangeDetailTracker",
            path: "Sources/RangeDetailTracker"
        ),
    ]
)
