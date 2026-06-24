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
    name: "swift-cidr-benchmarks",
    platforms: [
        // Benchmark executables are a macOS/Linux command-line workflow. iOS is declared so
        // SwiftPM/Xcode resolve this nested package with the same Apple platform floor as CIDR.
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .executable(name: "CIDRProfileTarget", targets: ["CIDRProfileTarget"]),
    ],
    dependencies: [
        .package(name: "swift-cidr", path: ".."),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.100.0"),
        .package(url: "https://github.com/ordo-one/benchmark.git", from: "1.35.0"),
    ],
    targets: [
        .executableTarget(
            name: "CIDRProfileTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
            ],
            path: "Tools/CIDRProfileTarget"
        ),
        .executableTarget(
            name: "CIDRBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "Benchmark", package: "benchmark"),
            ],
            path: "CIDRBenchmarkTarget",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRCPUBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "Benchmark", package: "benchmark"),
            ],
            path: "CIDRCPUBenchmarkTarget",
            plugins: [
                // Keep fixed-loop CPU batch measurements isolated from the default threshold-gated target.
                .plugin(name: "BenchmarkPlugin", package: "benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRNIOBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "CIDRNIO", package: "swift-cidr"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Benchmark", package: "benchmark"),
            ],
            path: "CIDRNIOBenchmarkTarget",
            plugins: [
                // CHANGE: Keep NIO adapter measurements isolated from the default threshold-gated target.
                .plugin(name: "BenchmarkPlugin", package: "benchmark"),
            ]
        ),
    ]
)
