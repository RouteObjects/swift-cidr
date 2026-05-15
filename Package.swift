// swift-tools-version: 6.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
//
// Copyright (c) 2026 Craig A. Munro
//
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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
        .library(name: "CIDRNIO", targets: ["CIDRNIO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.81.0"),
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
        .target(
            name: "CIDRNIO",
            dependencies: [
                "CIDR",
                // Keep SwiftNIO isolated behind the explicit CIDRNIO module boundary.
                .product(name: "NIOCore", package: "swift-nio"),
            ]
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
        .testTarget(
            name: "CIDRNIOTests",
            dependencies: [
                "CIDR",
                "CIDRNIO",
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
    ]
)
