// swift-tools-version: 6.0
//
// Copyright (c) 2026 Craig A. Munro
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

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
