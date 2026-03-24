// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Chronoforge",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Chronoforge",
            targets: ["Chronoforge"]
        ),
    ],
    targets: [
        .target(
            name: "Chronoforge",
            path: "Chronoforge",
            exclude: ["Resources/Sounds", "Resources/Music", "Resources/Particles"],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ChronoforgeTests",
            dependencies: ["Chronoforge"],
            path: "Tests"
        ),
    ]
)
