// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-cidr-benchmarks",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .executable(name: "CIDRProfileTarget", targets: ["CIDRProfileTarget"]),
    ],
    dependencies: [
        .package(name: "swift-cidr", path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.31.0"),
    ],
    targets: [
        .target(
            name: "ParserBenchSupport",
            path: "ParserBenchSupport"
        ),
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
                "ParserBenchSupport",
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRBenchmarkTarget",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRCPUComparisonBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRCPUComparisonBenchmarkTarget",
            plugins: [
                // Keep fixed-loop CPU batch comparisons isolated from the default threshold-gated target.
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
        .testTarget(
            name: "ParserBenchSupportTests",
            dependencies: ["ParserBenchSupport"],
            path: "Tests/ParserBenchSupportTests"
        ),
    ]
)
