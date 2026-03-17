// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SoftwareifyAuth",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SoftwareifyAuth",
            targets: ["SoftwareifyAuth"]
        ),
    ],
    targets: [
        .target(
            name: "SoftwareifyAuth",
            path: "Sources/SoftwareifyAuth"
        ),
    ]
)
