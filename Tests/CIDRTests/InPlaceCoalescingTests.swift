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

@Suite("In-Place Coalescing Tests")
struct InPlaceCoalescingTests {
    @Test("Compaction preserves empty, singleton, collapsed, and disjoint shapes")
    func compactionShapes() throws {
        try checkCompactionShapes(V4.self)
        try checkCompactionShapes(V6.self)
        try checkCompactionShapes(InPlaceCoalescingTestFamily.self)
    }

    @Test("Coalescing and coverage accept sequences with a shared single-pass cursor")
    func singlePassSequences() throws {
        try checkSinglePassSequences(V4.self)
        try checkSinglePassSequences(V6.self)
        try checkSinglePassSequences(InPlaceCoalescingTestFamily.self)
    }

    @Test("Compaction preserves caller arrays, slices, aliases, and independent mutations")
    func valueOwnership() throws {
        try checkValueOwnership(V4.self)
        try checkValueOwnership(V6.self)
        try checkValueOwnership(InPlaceCoalescingTestFamily.self)
    }

    @Test("Compaction preserves full storage coverage and gaps beside maximum endpoints")
    func storageBoundaries() throws {
        try checkStorageBoundaries(V4.self)
        try checkStorageBoundaries(V6.self)
        try checkStorageBoundaries(InPlaceCoalescingTestFamily.self)
    }

    @Test("Sparse merges preserve long disjoint prefixes and suffixes")
    func sparseMerges() throws {
        try checkSparseMerges(V4.self)
        try checkSparseMerges(V6.self)
        try checkSparseMerges(InPlaceCoalescingTestFamily.self)
    }

    private func checkSparseMerges<Family: IPAddressFamily>(_ family: Family.Type) throws {
        let expected = try (0..<4096).map { index in
            let address = Family.Storage(index * 4)
            return try makeRange(address, address, family: family)
        }
        for duplicateIndex in [0, expected.count / 2, expected.count - 1] {
            var input = Array(expected.reversed())
            input.append(expected[duplicateIndex])
            let alias = input
            let result = IPAddressRange<Family>.coalescing(input)

            #expect(result == expected)
            #expect(input == alias)
            #expect(result.count == input.count - 1)
            #expect(IPAddressCoverage(input).ranges == expected)
        }
    }

    private func checkCompactionShapes<Family: IPAddressFamily>(_ family: Family.Type) throws {
        typealias Bounds = [(UInt16, UInt16)]
        let examples: [(input: Bounds, expected: Bounds)] = [
            ([], []),
            ([(3, 7)], [(3, 7)]),
            ([(20, 21), (1, 2), (10, 11)], [(1, 2), (10, 11), (20, 21)]),
            ([(1, 2), (10, 11), (20, 21)], [(1, 2), (10, 11), (20, 21)]),
            ([(3, 7), (3, 7), (3, 7)], [(3, 7)]),
            ([(3, 4), (1, 9), (1, 5), (8, 9), (2, 8)], [(1, 9)]),
            ([(5, 6), (1, 2), (3, 4)], [(1, 6)]),
            (
                [(20, 20), (4, 4), (1, 2), (10, 12), (2, 3), (11, 11), (10, 10), (6, 6)],
                [(1, 4), (6, 6), (10, 12), (20, 20)]
            ),
        ]

        for example in examples {
            let input = try makeRanges(example.input, family: family)
            let expected = try makeRanges(example.expected, family: family)
            let actual = IPAddressRange<Family>.coalescing(input)

            #expect(actual == expected)
            #expect(IPAddressRange<Family>.coalescing(actual) == expected)
            #expect(IPAddressCoverage(input).ranges == expected)
        }
    }

    private func checkSinglePassSequences<Family: IPAddressFamily>(_ family: Family.Type) throws {
        typealias Bounds = [(UInt16, UInt16)]
        let examples: [(input: Bounds, expected: Bounds)] = [
            ([], []),
            ([(3, 7)], [(3, 7)]),
            ([(20, 21), (3, 4), (1, 2), (10, 10)], [(1, 4), (10, 10), (20, 21)]),
        ]

        for example in examples {
            let input = try makeRanges(example.input, family: family)
            let expected = try makeRanges(example.expected, family: family)
            let directSequence = SharedCursorSequence(input)
            let coverageSequence = SharedCursorSequence(input)

            #expect(IPAddressRange<Family>.coalescing(directSequence) == expected)
            #expect(IPAddressCoverage(coverageSequence).ranges == expected)
            #expect(directSequence.yieldedCount == input.count)
            #expect(coverageSequence.yieldedCount == input.count)
            #expect(directSequence.next() == nil)
            #expect(coverageSequence.next() == nil)
        }
    }

    private func checkValueOwnership<Family: IPAddressFamily>(_ family: Family.Type) throws {
        typealias Bounds = [(UInt16, UInt16)]
        let examples: [(input: Bounds, expected: Bounds, sliceExpected: Bounds)] = [
            (
                [(20, 21), (3, 4), (1, 2), (10, 10)],
                [(1, 4), (10, 10), (20, 21)],
                [(1, 4), (10, 10)]
            ),
            (
                [(1, 2), (10, 10), (20, 21)],
                [(1, 2), (10, 10), (20, 21)],
                [(10, 10), (20, 21)]
            ),
        ]

        for example in examples {
            var source = try makeRanges(example.input, family: family)
            let originalEndpoints = source.map { [$0.lowerBound.address, $0.upperBound.address] }
            let alias = source
            let slice = source[1...]
            let originalSliceEndpoints = slice.map { [$0.lowerBound.address, $0.upperBound.address] }
            let expected = try makeRanges(example.expected, family: family)
            let sliceExpected = try makeRanges(example.sliceExpected, family: family)

            var output = IPAddressRange<Family>.coalescing(source)
            var sliceOutput = IPAddressRange<Family>.coalescing(slice)
            let coverage = IPAddressCoverage(source)

            #expect(output == expected)
            #expect(sliceOutput == sliceExpected)
            #expect(coverage.ranges == expected)
            #expect(source.map { [$0.lowerBound.address, $0.upperBound.address] } == originalEndpoints)
            #expect(alias.map { [$0.lowerBound.address, $0.upperBound.address] } == originalEndpoints)
            #expect(slice.map { [$0.lowerBound.address, $0.upperBound.address] } == originalSliceEndpoints)

            output[0] = try makeRange(100, 100, family: family)
            sliceOutput[0] = try makeRange(110, 110, family: family)
            #expect(source.map { [$0.lowerBound.address, $0.upperBound.address] } == originalEndpoints)
            #expect(alias.map { [$0.lowerBound.address, $0.upperBound.address] } == originalEndpoints)
            #expect(slice.map { [$0.lowerBound.address, $0.upperBound.address] } == originalSliceEndpoints)
            #expect(coverage.ranges == expected)

            let modifiedOutput = output
            let modifiedSliceOutput = sliceOutput
            source[0] = try makeRange(200, 200, family: family)
            #expect(output == modifiedOutput)
            #expect(sliceOutput == modifiedSliceOutput)
            #expect(coverage.ranges == expected)
            #expect(alias.map { [$0.lowerBound.address, $0.upperBound.address] } == originalEndpoints)
            #expect(slice.map { [$0.lowerBound.address, $0.upperBound.address] } == originalSliceEndpoints)
        }
    }

    private func checkStorageBoundaries<Family: IPAddressFamily>(_ family: Family.Type) throws {
        let maximum = Family.Storage.max
        let midpoint = maximum / 2
        let fullInput = try [
            makeRange(maximum, maximum, family: family),
            makeRange(midpoint + 1, maximum - 1, family: family),
            makeRange(0, midpoint, family: family),
            makeRange(0, 0, family: family),
        ]
        let fullExpected = [try makeRange(0, maximum, family: family)]
        #expect(IPAddressRange<Family>.coalescing(fullInput) == fullExpected)
        #expect(IPAddressCoverage(fullInput).ranges == fullExpected)

        let gapInput = try [
            makeRange(maximum, maximum, family: family),
            makeRange(0, maximum - 2, family: family),
        ]
        let gapExpected = [gapInput[1], gapInput[0]]
        #expect(IPAddressRange<Family>.coalescing(gapInput) == gapExpected)
        #expect(IPAddressCoverage(gapInput).ranges == gapExpected)

        let endpoints = try [
            makeRange(maximum, maximum, family: family),
            makeRange(0, 0, family: family),
        ]
        #expect(IPAddressRange<Family>.coalescing(endpoints) == [endpoints[1], endpoints[0]])
    }

    private func makeRanges<Family: IPAddressFamily>(
        _ bounds: [(UInt16, UInt16)],
        family: Family.Type
    ) throws -> [IPAddressRange<Family>] {
        try bounds.map { lower, upper in
            try makeRange(Family.Storage(lower), Family.Storage(upper), family: family)
        }
    }

    private func makeRange<Family: IPAddressFamily>(
        _ lower: Family.Storage,
        _ upper: Family.Storage,
        family: Family.Type
    ) throws -> IPAddressRange<Family> {
        try #require(
            IPAddressRange(
                lowerBound: IPAddress<Family>(address: lower),
                upperBound: IPAddress<Family>(address: upper)
            )
        )
    }
}

// Every iterator shares the same advancing cursor, unlike AnySequence wrapping an Array.
private final class SharedCursorSequence<Element>: Sequence, IteratorProtocol {
    private let elements: [Element]
    private var index = 0
    private(set) var yieldedCount = 0

    init(_ elements: [Element]) {
        self.elements = elements
    }

    func makeIterator() -> SharedCursorSequence<Element> { self }

    func next() -> Element? {
        guard index < elements.count else { return nil }
        let element = elements[index]
        index += 1
        yieldedCount += 1
        return element
    }
}

private enum InPlaceCoalescingTestFamily: IPAddressFamily {
    typealias Storage = UInt16
    static let ianaValue: UInt16 = 65_534
    static let familyName = "In-Place Coalescing Test"
    static func parseAddress(_ string: String) -> UInt16? { UInt16(string) }
    static func formatAddress(_ address: UInt16) -> String { String(address) }
}
