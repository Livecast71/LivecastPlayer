// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LivecastPlayer",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "LivecastPlayer",
            targets: ["LivecastPlayer"]
        )
    ],
    targets: [
        .target(
            name: "LivecastPlayer",
            path: "Sources/LivecastPlayer"
        )
    ]
)
