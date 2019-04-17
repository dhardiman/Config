// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Config",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "Config", targets: ["Config"]),
        .executable(name: "generateconfig", targets: ["generateconfig"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.1")
    ],
    targets: [
        .target(name: "generateconfig", dependencies: ["Config"]),
        .target(name: "Config", dependencies: []),
        .testTarget(name: "ConfigTests", dependencies: ["Config", "Nimble"])
    ],
    swiftLanguageVersions: [.v5]
)
