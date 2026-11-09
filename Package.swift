// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoriKey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MoriKeyEngine",
            targets: ["MoriKeyEngine"]
        ),
        .executable(
            name: "MoriKey",
            targets: ["MoriKeyApp"]
        )
    ],
    targets: [
        .target(
            name: "MoriKeyEngine",
            dependencies: [],
            path: "Sources/MoriKeyEngine"
        ),
        .executableTarget(
            name: "MoriKeyApp",
            dependencies: ["MoriKeyEngine"],
            path: "Sources/MoriKeyApp"
        ),
        .testTarget(
            name: "MoriKeyEngineTests",
            dependencies: ["MoriKeyEngine"],
            path: "Tests/MoriKeyEngineTests"
        )
    ]
)
