// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Config",
    products: [
        .library(name: "Config", targets: ["Config"]),
        .executable(name: "generateconfig", targets: ["generateconfig"])
    ],
    dependencies: [],
    targets: [
        .target(name: "generateconfig", dependencies: ["Config"]),
        .target(name: "Config", dependencies: []),
        .testTarget(name: "ConfigTests", dependencies: ["Config"])
    ],
    swiftLanguageVersions: [.v5]
)
