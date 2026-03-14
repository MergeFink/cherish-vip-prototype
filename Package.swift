// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "CherishVIP",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "CherishVIP",
            path: "Sources/CherishVIP"
        )
    ]
)
