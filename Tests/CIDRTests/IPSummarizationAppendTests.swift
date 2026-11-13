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

import CIDR
import Testing

@Suite("IP Summarization Append Tests")
struct IPSummarizationAppendTests {
    @Test("IPv4 append APIs preserve boundaries and existing output")
    func ipv4Boundaries() throws {
        try checkBoundaries(V4.self)
    }

    @Test("IPv6 append APIs preserve boundaries and existing output")
    func ipv6Boundaries() throws {
        try checkBoundaries(V6.self)
        let boundary = UInt128(1) << 64
        try checkAppendAPIs(V6.self, from: boundary - 3, to: boundary + 5)
        try checkAppendAPIs(V6.self, from: boundary - 1, to: boundary)
    }

    @Test("Coverage appends ordered summaries without filling gaps or merging existing output")
    func coveragePreservesGapsAndOutput() throws {
        try checkCoverage(V4.self)
        try checkCoverage(V6.self)
    }

    @Test("Summarization preserves the caller's concrete IPPrefix type")
    func preservesCustomPrefixType() throws {
        try checkCustomPrefix(V4.self)
        try checkCustomPrefix(V6.self)
    }

    @Test("Every eight-bit endpoint pair agrees with an independent prefix-tree oracle")
    func exhaustiveSmallFamily() {
        // CHANGE: Exhaust all ordered and reversed ranges without reproducing the greedy loop.
        for lower in UInt16(0)...UInt16(UInt8.max) {
            for upper in UInt16(0)...UInt16(UInt8.max) {
                checkAgainstOracle(SmallSummarizationFamily.self, from: UInt8(lower), to: UInt8(upper))
            }
        }
    }

    @Test("Seeded IPv4 ranges agree with an independent prefix-tree oracle")
    func randomizedIPv4() {
        var generator = SummarizationGenerator(state: 0xC1D2_0032)
        for _ in 0..<2_000 {
            let first = UInt32(truncatingIfNeeded: generator.next())
            let second = UInt32(truncatingIfNeeded: generator.next())
            checkAgainstOracle(V4.self, from: min(first, second), to: max(first, second))
            checkAgainstOracle(V4.self, from: max(first, second), to: min(first, second))
        }
    }

    @Test("Seeded IPv6 ranges agree with an independent prefix-tree oracle")
    func randomizedIPv6() {
        var generator = SummarizationGenerator(state: 0xC1D2_0128)
        for _ in 0..<2_000 {
            let first = (UInt128(generator.next()) << 64) | UInt128(generator.next())
            let second = (UInt128(generator.next()) << 64) | UInt128(generator.next())
            checkAgainstOracle(V6.self, from: min(first, second), to: max(first, second))
            checkAgainstOracle(V6.self, from: max(first, second), to: min(first, second))
        }
    }

    private func checkBoundaries<Family: IPAddressFamily>(_ family: Family.Type) throws {
        let maximum = Family.Storage.max
        let midpoint = Family.Storage(1) << (Family.Storage.bitWidth - 1)
        let cases: [(Family.Storage, Family.Storage)] = [
            (0, 0), (maximum, maximum), (0, maximum),
            (0, maximum - 1), (1, maximum), (1, maximum - 1),
            (0, 1), (maximum - 1, maximum),
            (midpoint - 1, midpoint), (midpoint, midpoint + 15),
            (17, 190), (190, 17),
        ]
        for (lower, upper) in cases {
            try checkAppendAPIs(family, from: lower, to: upper)
        }
    }

    private func checkAppendAPIs<Family: IPAddressFamily>(
        _ family: Family.Type, from lower: Family.Storage, to upper: Family.Storage
    ) throws {
        // Endpoint prefix context does not change the address interval being summarized.
        let start = IPAddress<Family>(address: lower, prefixLength: .zero)
        let end = IPAddress<Family>(address: upper, prefixLength: .zero)
        let expected = prefixTreeSummary(from: lower, to: upper)
        let sentinel = IPNetwork<Family>(prefix: 0, prefixLength: .zero)

        let returned = IPNetwork<Family>.summarize(from: start, to: end)
        #expect(blocks(returned) == expected)

        var empty: [IPNetwork<Family>] = []
        IPNetwork<Family>.summarize(from: start, to: end, into: &empty)
        #expect(empty == returned)

        var appended = [sentinel]
        IPNetwork<Family>.summarize(from: start, to: end, into: &appended)
        #expect(appended == [sentinel] + returned)
        IPNetwork<Family>.summarize(from: start, to: end, into: &appended)
        #expect(appended == [sentinel] + returned + returned)

        guard lower <= upper else { return }
        let range = try #require(IPAddressRange(lowerBound: start, upperBound: end))
        #expect(range.summarizedNetworks() == returned)
        var rangeResult: [IPNetwork<Family>] = []
        range.summarizedNetworks(into: &rangeResult)
        #expect(rangeResult == returned)
        rangeResult = [sentinel]
        range.summarizedNetworks(into: &rangeResult)
        range.summarizedNetworks(into: &rangeResult)
        #expect(rangeResult == [sentinel] + returned + returned)

        let coverage = IPAddressCoverage([range])
        #expect(coverage.summarizedNetworks() == returned)
        var coverageResult: [IPNetwork<Family>] = []
        coverage.summarizedNetworks(into: &coverageResult)
        #expect(coverageResult == returned)
        coverageResult = [sentinel]
        coverage.summarizedNetworks(into: &coverageResult)
        coverage.summarizedNetworks(into: &coverageResult)
        #expect(coverageResult == [sentinel] + returned + returned)
    }

    private func checkCoverage<Family: IPAddressFamily>(_ family: Family.Type) throws {
        let endpoints: [(Family.Storage, Family.Storage)] = [(17, 30), (33, 62), (80, 96)]
        let ranges = try endpoints.map { lower, upper in
            try #require(
                IPAddressRange<Family>(
                    lowerBound: IPAddress(address: lower), upperBound: IPAddress(address: upper)
                ))
        }
        let coverage = IPAddressCoverage(ranges.reversed())
        let expected = endpoints.flatMap { prefixTreeSummary(from: $0.0, to: $0.1) }
        let returned = coverage.summarizedNetworks()
        #expect(blocks(returned) == expected)

        let sentinel = IPNetwork<Family>(prefix: 0, prefixLength: .zero)
        var result = [sentinel]
        coverage.summarizedNetworks(into: &result)
        #expect(result == [sentinel] + returned)
        coverage.summarizedNetworks(into: &result)
        #expect(result == [sentinel] + returned + returned)

        let empty = IPAddressCoverage<Family>([IPAddressRange<Family>]())
        let previous = result
        empty.summarizedNetworks(into: &result)
        #expect(result == previous)
        var emptyResult: [IPNetwork<Family>] = []
        empty.summarizedNetworks(into: &emptyResult)
        #expect(emptyResult.isEmpty)
        #expect(empty.summarizedNetworks().isEmpty)
    }

    private func checkCustomPrefix<Family: IPAddressFamily>(_ family: Family.Type) throws {
        let start = IPAddress<Family>(address: 17)
        let end = IPAddress<Family>(address: 190)
        let expected = prefixTreeSummary(from: start.address, to: end.address)
        let sentinel = SummarizationRoute<Family>(prefix: 0, prefixLength: .zero)
        var result = [sentinel]
        SummarizationRoute<Family>.summarize(from: start, to: end, into: &result)
        #expect(blocks(Array(result.dropFirst())) == expected)
        #expect(result.first == sentinel)
        #expect(blocks(SummarizationRoute<Family>.summarize(from: start, to: end)) == expected)

        // CHANGE: The /0 fast path must construct Self just like the ordinary loop.
        SummarizationRoute<Family>.summarize(
            from: IPAddress(address: 0), to: IPAddress(address: Family.Storage.max), into: &result
        )
        #expect(result.last == sentinel)
        #expect(result.count == expected.count + 2)
    }

    private func checkAgainstOracle<Family: IPAddressFamily>(
        _ family: Family.Type, from lower: Family.Storage, to upper: Family.Storage
    ) {
        let start = IPAddress<Family>(address: lower)
        let end = IPAddress<Family>(address: upper)
        let expected = prefixTreeSummary(from: lower, to: upper)
        let returned = IPNetwork<Family>.summarize(from: start, to: end)
        #expect(blocks(returned) == expected)
        var appended: [IPNetwork<Family>] = []
        IPNetwork<Family>.summarize(from: start, to: end, into: &appended)
        #expect(blocks(appended) == expected)
    }
}

private struct SummaryBlock<Storage: FixedWidthInteger & UnsignedInteger>: Equatable {
    let prefix: Storage
    let length: Int
}

private func blocks<Prefix: IPPrefix>(_ prefixes: [Prefix]) -> [SummaryBlock<Prefix.Family.Storage>] {
    prefixes.map { SummaryBlock(prefix: $0.prefix, length: Int($0.prefixLength.rawValue)) }
}

// CHANGE: This oracle partitions an inclusive binary tree; it uses neither the greedy
// summarizer's trailing-zero/log2 arithmetic nor any CIDR mask or endpoint helpers.
private func prefixTreeSummary<Storage: FixedWidthInteger & UnsignedInteger>(
    from start: Storage, to end: Storage
) -> [SummaryBlock<Storage>] {
    guard start <= end else { return [] }
    var result: [SummaryBlock<Storage>] = []
    func visit(lower: Storage, upper: Storage, length: Int) {
        guard lower <= end, start <= upper else { return }
        if start <= lower, upper <= end {
            result.append(SummaryBlock(prefix: lower, length: length))
            return
        }
        let middle = lower + ((upper - lower) >> 1)
        visit(lower: lower, upper: middle, length: length + 1)
        visit(lower: middle + 1, upper: upper, length: length + 1)
    }
    visit(lower: 0, upper: .max, length: 0)
    return result
}

private enum SmallSummarizationFamily: IPAddressFamily {
    typealias Storage = UInt8
    static let ianaValue: UInt16 = 65_535
    static let familyName = "Small Summarization Test"
    static func parseAddress(_ string: String) -> UInt8? { UInt8(string) }
    static func formatAddress(_ address: UInt8) -> String { String(address) }
}

private struct SummarizationRoute<Family: IPAddressFamily>: IPPrefix, Equatable {
    let prefix: Family.Storage
    let prefixLength: PrefixLength<Family>

    init(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
        let length = Int(prefixLength.rawValue)
        let mask: Family.Storage = length == 0 ? 0 : .max << (Family.Storage.bitWidth - length)
        self.prefix = prefix & mask
        self.prefixLength = prefixLength
    }
}

private struct SummarizationGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
