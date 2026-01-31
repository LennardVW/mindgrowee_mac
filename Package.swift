// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mindgrowee_mac",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "mindgrowee_mac", targets: ["mindgrowee_mac"])
    ],
    targets: [
        .executableTarget(
            name: "mindgrowee_mac"
        )
    ]
)
