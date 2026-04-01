// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacDitto",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacDitto", targets: ["MacDitto"])
    ],
    targets: [
        .executableTarget(
            name: "MacDitto",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
