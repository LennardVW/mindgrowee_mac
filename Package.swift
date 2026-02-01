// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "mindgrowee_mac",
    defaultLocalization: "en",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "mindgrowee_mac", targets: ["mindgrowee_mac"])
    ],
    targets: [
        .executableTarget(
            name: "mindgrowee_mac"
        )
    ]
)
