// swift-tools-version:5.9
// mindgrowee_mac - Native macOS Habit Tracker & Journal
// Local storage, daily reset, statistics

import PackageDescription

let package = Package(
    name: "mindgrowee_mac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "mindgrowee_mac", targets: ["mindgrowee_mac"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "mindgrowee_mac",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "mindgrowee_macTests",
            dependencies: ["mindgrowee_mac"]
        ),
    ]
)
