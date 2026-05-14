// swift-tools-version: 6.1

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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.89.0"),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.32.0"),
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
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRBenchmarkTarget",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRParserExperimentBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRParserExperimentBenchmarkTarget",
            plugins: [
                // Keep SPI parser-engine experiments out of the public/API-facing default target.
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRCPUBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRCPUBenchmarkTarget",
            plugins: [
                // Keep fixed-loop CPU batch measurements isolated from the default threshold-gated target.
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
        .executableTarget(
            name: "CIDRNIOBenchmarkTarget",
            dependencies: [
                .product(name: "CIDR", package: "swift-cidr"),
                .product(name: "CIDRNIO", package: "swift-cidr"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "CIDRNIOBenchmarkTarget",
            plugins: [
                // CHANGE: Keep NIO adapter measurements isolated from the default threshold-gated target.
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
