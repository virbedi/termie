// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TermieCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TermieCore", targets: ["TermieCore"]),
    ],
    targets: [
        .target(name: "TermieCore"),
        .testTarget(name: "TermieCoreTests", dependencies: ["TermieCore"]),
    ]
)
