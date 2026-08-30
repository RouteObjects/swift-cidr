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

@Suite("IP Address Coverage Tests")
struct IPAddressCoverageTests {
    @Test("Empty and singleton input produce normalized coverage values")
    func emptyAndSingletonCoverage() throws {
        let empty = IPAddressCoverage<V4>([IPv4AddressRange]())
        let singletonRange = IPv4AddressRange(try #require(IPv4Address("192.0.2.7/24")))
        let singleton = IPAddressCoverage([singletonRange])

        #expect(empty.isEmpty)
        #expect(empty.ranges.isEmpty)
        #expect(empty.summarizedNetworks().isEmpty)
        #expect(!singleton.isEmpty)
        #expect(singleton.ranges.map(\.description) == ["192.0.2.7...192.0.2.7"])
        #expect(singleton.contains(try #require(IPv4Address("192.0.2.7"))))
        #expect(!singleton.contains(try #require(IPv4Address("192.0.2.8"))))
    }

    @Test("Coverage equality ignores ordering, duplicates, containment, and adjacency")
    func normalizedValueEquality() throws {
        let first = try [
            "192.0.2.8...192.0.2.9",
            "192.0.2.2...192.0.2.7",
            "192.0.2.3...192.0.2.4",
            "192.0.2.8...192.0.2.9",
        ].map { try #require(IPv4AddressRange($0)) }
        let second = [try #require(IPv4AddressRange("192.0.2.2...192.0.2.9"))]

        let lhs = IPAddressCoverage(first)
        let rhs = IPAddressCoverage(second)

        #expect(lhs == rhs)
        #expect(lhs.hashValue == rhs.hashValue)
        #expect(IPAddressCoverage(lhs.ranges) == lhs)
    }

    @Test("Coverage snapshots input and finds exact boundaries across a disjoint range index")
    func immutableIndexedContainment() throws {
        var source = try [
            "192.0.2.10...192.0.2.19",
            "192.0.2.30...192.0.2.39",
            "192.0.2.50...192.0.2.59",
        ].map { try #require(IPv4AddressRange($0)) }
        let coverage = IPAddressCoverage(source)

        // Coverage owns an immutable normalized value; later mutations to the source
        // collection cannot change either its index or the represented address set.
        source.append(try #require(IPv4AddressRange("192.0.2.20...192.0.2.29")))

        #expect(coverage.ranges.count == 3)
        for address in ["192.0.2.10", "192.0.2.19", "192.0.2.30", "192.0.2.39", "192.0.2.59"] {
            #expect(coverage.contains(try #require(IPv4Address(address))))
        }
        for address in ["192.0.2.9", "192.0.2.20", "192.0.2.29", "192.0.2.40", "192.0.2.60"] {
            #expect(!coverage.contains(try #require(IPv4Address(address))))
        }
    }

    @Test("Prefix construction erases representation and preserves exact union")
    func constructsFromPrefixes() throws {
        let prefixes = try [
            #require(IPv4Network("192.0.2.0/32")),
            #require(IPv4Network("192.0.2.1/32")),
            #require(IPv4Network("192.0.2.2/31")),
        ]

        let coverage = IPAddressCoverage<V4>(covering: prefixes)

        #expect(coverage.ranges.map(\.description) == ["192.0.2.0...192.0.2.3"])
        #expect(coverage.summarizedNetworks().map(\.description) == ["192.0.2.0/30"])
    }

    @Test("Unequal adjacent prefixes form one range and retain their canonical summary")
    func summarizesUnequalAdjacency() throws {
        let prefixes = try [
            #require(IPv4Network("192.0.2.0/25")),
            #require(IPv4Network("192.0.2.128/26")),
        ]

        let coverage = IPAddressCoverage<V4>(covering: prefixes)

        #expect(coverage.ranges.map(\.description) == ["192.0.2.0...192.0.2.191"])
        #expect(
            coverage.summarizedNetworks().map(\.description)
                == ["192.0.2.0/25", "192.0.2.128/26"]
        )
    }

    @Test("Disjoint inputs retain uncovered gaps in ranges and network summaries")
    func doesNotWidenGaps() throws {
        let prefixes = try [
            #require(IPv4Network("192.0.2.0/26")),
            #require(IPv4Network("192.0.2.128/26")),
        ]
        let coverage = IPAddressCoverage<V4>(covering: prefixes)

        #expect(
            coverage.ranges.map(\.description)
                == ["192.0.2.0...192.0.2.63", "192.0.2.128...192.0.2.191"]
        )
        #expect(
            coverage.summarizedNetworks().map(\.description)
                == ["192.0.2.0/26", "192.0.2.128/26"]
        )
        #expect(!coverage.contains(try #require(IPv4Address("192.0.2.64"))))
        #expect(!coverage.contains(try #require(IPv4Address("192.0.2.127"))))
    }

    @Test("Complete IPv4 and IPv6 spaces summarize without overflow")
    func completeAddressSpaces() throws {
        let ipv4 = IPAddressCoverage([
            try #require(IPv4AddressRange("0.0.0.0...255.255.255.255"))
        ])
        let ipv6 = IPAddressCoverage([
            try #require(
                IPv6AddressRange("::...ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")
            )
        ])

        #expect(ipv4.summarizedNetworks().map(\.description) == ["0.0.0.0/0"])
        #expect(ipv6.summarizedNetworks().map(\.description) == ["::/0"])
        #expect(ipv4.contains(try #require(IPv4Address("255.255.255.255"))))
        #expect(ipv6.contains(try #require(IPv6Address("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"))))
    }

    @Test("IPv6 normalization follows the same exact-coverage rules")
    func ipv6Coverage() throws {
        let prefixes = try [
            #require(IPv6Network("2001:db8::/65")),
            #require(IPv6Network("2001:db8:0:0:8000::/65")),
        ]
        let coverage = IPAddressCoverage<V6>(covering: prefixes)

        #expect(
            coverage.ranges.map(\.description)
                == ["2001:db8::...2001:db8::ffff:ffff:ffff:ffff"]
        )
        #expect(coverage.summarizedNetworks().map(\.description) == ["2001:db8::/64"])
    }

    @Test("Randomized normalization and summarization retain exact address membership")
    func randomizedExactUnion() throws {
        let base = try #require(IPv4Address("198.51.100.0")).address
        var generator = DeterministicGenerator(state: 0xC1D2_4E)

        for _ in 0..<1_000 {
            let count = Int(generator.next() % 41)
            var input: [IPv4Network] = []
            input.reserveCapacity(count)

            for _ in 0..<count {
                let rawPrefixLength = 24 + Int(generator.next() % 9)
                let prefixLength = try #require(IPv4PrefixLength(rawPrefixLength))
                let address = base | UInt32(generator.next() & 0xFF)
                input.append(IPv4Network(prefix: address, prefixLength: prefixLength))
            }

            let coverage = IPAddressCoverage<V4>(covering: input)
            let summarized = coverage.summarizedNetworks()

            #expect(coverage.ranges.count <= input.count)
            #expect(summarized.count <= input.count)
            #expect(IPAddressCoverage(coverage.ranges) == coverage)
            #expect(IPAddressCoverage<V4>(covering: summarized) == coverage)

            for offset in UInt32(0)...UInt32(255) {
                let address = IPv4Address(address: base | offset)
                let expected = input.contains { $0.contains(address) }
                #expect(coverage.contains(address) == expected)
                #expect(summarized.contains { $0.contains(address) } == expected)
            }

            for index in coverage.ranges.indices.dropLast() {
                #expect(!coverage.ranges[index].overlaps(coverage.ranges[index + 1]))
                #expect(!coverage.ranges[index].isAdjacent(to: coverage.ranges[index + 1]))
            }
        }
    }

    @Test("Randomized IPv6 normalization preserves exact coverage inside a /120 window")
    func randomizedIPv6ExactUnion() throws {
        let base = try #require(IPv6Address("2001:db8::")).address
        var generator = DeterministicGenerator(state: 0x1_6C1D_2E)

        // A bounded /120 window permits exhaustive membership checks while still varying
        // network alignment and every prefix length from /120 through /128.
        for _ in 0..<250 {
            let count = Int(generator.next() % 33)
            var input: [IPv6Network] = []
            input.reserveCapacity(count)

            for _ in 0..<count {
                let rawPrefixLength = 120 + Int(generator.next() % 9)
                let prefixLength = try #require(IPv6PrefixLength(rawPrefixLength))
                let address = base | UInt128(generator.next() & 0xFF)
                input.append(IPv6Network(prefix: address, prefixLength: prefixLength))
            }

            let coverage = IPAddressCoverage<V6>(covering: input)
            let summarized = coverage.summarizedNetworks()

            #expect(coverage.ranges.count <= input.count)
            #expect(summarized.count <= input.count)
            #expect(IPAddressCoverage(coverage.ranges) == coverage)
            #expect(IPAddressCoverage<V6>(covering: summarized) == coverage)

            for offset in UInt64(0)...UInt64(255) {
                let address = IPv6Address(address: base | UInt128(offset))
                let expected = input.contains { $0.contains(address) }
                #expect(coverage.contains(address) == expected)
                #expect(summarized.contains { $0.contains(address) } == expected)
            }

            for index in coverage.ranges.indices.dropLast() {
                #expect(!coverage.ranges[index].overlaps(coverage.ranges[index + 1]))
                #expect(!coverage.ranges[index].isAdjacent(to: coverage.ranges[index + 1]))
            }
        }
    }
}

private struct DeterministicGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
