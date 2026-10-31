// swift-tools-version: 6.2
//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
// Copyright (c) 2026 Craig A. Munro
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "ContainmentClient",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../..")],
    targets: [
        .executableTarget(
            name: "ContainmentClient",
            dependencies: [.product(name: "CIDR", package: "swift-cidr")]
        )
    ]
)
