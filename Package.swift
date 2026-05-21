// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-cidr",
    platforms: [
        .iOS(.v18), // built-in UInt128 is only available from iOS 18 / macOS 15 in this toolchain.
        .macOS(.v15),
    ],
    products: [
        .library(name: "CIDR", targets: ["CIDR"]),
        .library(name: "CIDRConfig", targets: ["CIDRConfig"]),
        .library(name: "CIDRPOSIX", targets: ["CIDRPOSIX"]),
    ],
    targets: [
        .target(name: "CIDR"),
        .target(
            name: "CIDRConfig",
            dependencies: ["CIDR"]
        ),
        .target(
            name: "CIDRPOSIX",
            dependencies: ["CIDR"]
        ),
        .testTarget(
            name: "CIDRTests",
            dependencies: ["CIDR"]
        ),
        .testTarget(
            name: "CIDRConfigTests",
            dependencies: ["CIDR", "CIDRConfig"]
        ),
        .testTarget(
            name: "CIDRPOSIXTests",
            dependencies: ["CIDR", "CIDRPOSIX"]
        ),
    ]
)
