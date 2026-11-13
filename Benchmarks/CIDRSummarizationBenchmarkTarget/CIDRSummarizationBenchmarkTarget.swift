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

import Benchmark
import CIDR

private func summarizationConfiguration(rangeCount: Int = 1) -> Benchmark.Configuration {
    .init(
        metrics: [
            .wallClock,
            .cpuUser,
            .peakMemoryResident,
            .mallocCountSmall,
            .mallocCountLarge,
            .mallocCountTotal,
            .mallocBytesCount,
            .objectAllocCount,
            .retainCount,
            .releaseCount,
            .retainReleaseDelta,
        ],
        // CHANGE: Preserve base counts/bytes in histogram exports instead of rounding to K/M units.
        units: [
            .peakMemoryResident: .count,
            .mallocCountSmall: .count,
            .mallocCountLarge: .count,
            .mallocCountTotal: .count,
            .mallocBytesCount: .count,
            .objectAllocCount: .count,
            .retainCount: .count,
            .releaseCount: .count,
            .retainReleaseDelta: .count,
        ],
        warmupIterations: 3,
        // CHANGE: Amortize the timer for small calls without multiplying large coverage work.
        scalingFactor: rangeCount == 1 ? .kilo : .one,
        maxDuration: .milliseconds(300),
        maxIterations: 1_000,
        thresholds: nil
    )
}

private func registerRangeBenchmarks<Family: IPAddressFamily>(
    _ fixture: SummarizationRangeFixture<Family>, familyName: String
) {
    let prefixName = "summarization.prefix.\(familyName).\(fixture.name)"
    let rangeName = "summarization.range.\(familyName).\(fixture.name)"

    // CHANGE: The runner executes measurements off MainActor; capture only Sendable fixture values.
    Benchmark("\(prefixName).returning", configuration: summarizationConfiguration()) { @Sendable benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPNetwork<Family>.summarize(from: fixture.lower, to: fixture.upper))
        }
    }
    Benchmark("\(rangeName).returning", configuration: summarizationConfiguration()) { @Sendable benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(fixture.range.summarizedNetworks())
        }
    }

    // CHANGE: The identical harness compiles against the pre-append baseline without this flag.
    #if SUMMARIZATION_APPEND_APIS
        Benchmark("\(prefixName).appendFresh", configuration: summarizationConfiguration()) { @Sendable benchmark in
            for _ in benchmark.scaledIterations {
                var result: [IPNetwork<Family>] = []
                IPNetwork<Family>.summarize(from: fixture.lower, to: fixture.upper, into: &result)
                blackHole(result)
            }
        }
        Benchmark("\(rangeName).appendFresh", configuration: summarizationConfiguration()) { @Sendable benchmark in
            for _ in benchmark.scaledIterations {
                var result: [IPNetwork<Family>] = []
                fixture.range.summarizedNetworks(into: &result)
                blackHole(result)
            }
        }
        Benchmark("\(prefixName).appendReused", configuration: summarizationConfiguration()) { @Sendable benchmark in
            var result: [IPNetwork<Family>] = []
            result.reserveCapacity(fixture.networkCount)
            // CHANGE: Own the buffer locally; allocation and disposal are outside this reuse sample.
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                result.removeAll(keepingCapacity: true)
                IPNetwork<Family>.summarize(from: fixture.lower, to: fixture.upper, into: &result)
                blackHole(result)
            }
            benchmark.stopMeasurement()
        }
        Benchmark("\(rangeName).appendReused", configuration: summarizationConfiguration()) { @Sendable benchmark in
            var result: [IPNetwork<Family>] = []
            result.reserveCapacity(fixture.networkCount)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                result.removeAll(keepingCapacity: true)
                fixture.range.summarizedNetworks(into: &result)
                blackHole(result)
            }
            benchmark.stopMeasurement()
        }
    #endif
}

private func registerCoverageBenchmarks<Family: IPAddressFamily>(
    _ fixture: SummarizationCoverageFixture<Family>, familyName: String
) {
    let name = "summarization.coverage.\(familyName).\(fixture.name)"
    let configuration = summarizationConfiguration(rangeCount: fixture.rangeCount)

    Benchmark("\(name).returning", configuration: configuration) { @Sendable benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(fixture.coverage.summarizedNetworks())
        }
    }

    #if SUMMARIZATION_APPEND_APIS
        Benchmark("\(name).appendFresh", configuration: configuration) { @Sendable benchmark in
            for _ in benchmark.scaledIterations {
                var result: [IPNetwork<Family>] = []
                fixture.coverage.summarizedNetworks(into: &result)
                blackHole(result)
            }
        }
        Benchmark("\(name).appendReused", configuration: configuration) { @Sendable benchmark in
            var result: [IPNetwork<Family>] = []
            result.reserveCapacity(fixture.networkCount)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                result.removeAll(keepingCapacity: true)
                fixture.coverage.summarizedNetworks(into: &result)
                blackHole(result)
            }
            benchmark.stopMeasurement()
        }
    #endif
}

private func registerSummarizationBenchmarks<Family: IPAddressFamily>(
    _ family: Family.Type, name: String
) {
    // CHANGE: Hide prebuilt fixtures from constant folding without timing parsing or coalescing.
    for fixture in summarizationRangeFixtures(family) {
        #if SUMMARIZATION_VALIDATE_FIXTURES
            precondition(
                IPNetwork<Family>.summarize(from: fixture.lower, to: fixture.upper).count == fixture.networkCount)
            precondition(fixture.range.summarizedNetworks().count == fixture.networkCount)
        #endif
        registerRangeBenchmarks(identity(fixture), familyName: name)
    }
    for fixture in summarizationCoverageFixtures(family) {
        #if SUMMARIZATION_VALIDATE_FIXTURES
            precondition(fixture.coverage.summarizedNetworks().count == fixture.networkCount)
        #endif
        registerCoverageBenchmarks(identity(fixture), familyName: name)
    }
}

// CHANGE: Match the runner's nonisolated registration hook with an immutable Sendable closure.
let benchmarks: @Sendable () -> Void = {
    registerSummarizationBenchmarks(V4.self, name: "v4")
    registerSummarizationBenchmarks(V6.self, name: "v6")
}
