// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "cherish-vip-prototype",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "cherish-vip-prototype",
            path: "cherish-vip-prototype"
        )
    ]
)
