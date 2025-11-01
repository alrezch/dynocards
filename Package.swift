// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dynocards",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Dynocards",
            targets: ["Dynocards"]),
    ],
    dependencies: [
        // Add external dependencies here
        // Example: .package(url: "https://github.com/realm/realm-swift.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Dynocards",
            dependencies: []
        ),
        .testTarget(
            name: "DynocardsTests",
            dependencies: ["Dynocards"]
        ),
    ]
) 