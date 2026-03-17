// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SmarAuth",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SmarAuth",
            targets: ["SmarAuth"]
        ),
    ],
    targets: [
        .target(
            name: "SmarAuth"
        ),
    ]
)
