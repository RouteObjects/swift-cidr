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
import Foundation
import Testing

@Suite("IP Address Range Tests")
struct IPAddressRangeTests {
    @Test("Generic construction and concrete aliases expose host-context endpoints")
    func publicGenericAndAliasSurface() throws {
        let lower = try #require(IPv4Address("192.0.2.2/24"))
        let upper = try #require(IPv4Address("192.0.2.7/30"))
        let generic = try #require(IPAddressRange<V4>(lowerBound: lower, upperBound: upper))
        let alias: IPv4AddressRange = generic

        #expect(alias.description == "192.0.2.2...192.0.2.7")
        #expect(alias.lowerBound.prefixLength.intValue == 32)
        #expect(alias.upperBound.prefixLength.intValue == 32)
        // Range membership compares literal address bits and ignores an input address's
        // prefix context; ClosedRange<IPAddress> would not provide that semantic guarantee.
        #expect(alias.contains(try #require(IPv4Address("192.0.2.2/24"))))
        #expect(alias.contains(try #require(IPv4Address("192.0.2.7/30"))))

        let ipv6: IPv6AddressRange = try #require(
            IPAddressRange<V6>("2001:db8::1...2001:db8::f")
        )
        #expect(ipv6.lowerBound.prefixLength.intValue == 128)
        #expect(ipv6.upperBound.prefixLength.intValue == 128)
    }

    @Test("Range text uses one strict address-only grammar")
    func strictTextGrammar() throws {
        #expect(
            IPv4AddressRange("192.0.2.2...192.0.2.7")?.description
                == "192.0.2.2...192.0.2.7"
        )
        #expect(
            IPv6AddressRange("2001:0DB8::1...2001:0DB8::F")?.description
                == "2001:db8::1...2001:db8::f"
        )
        #expect(IPv4AddressRange("192.0.2.7...192.0.2.2") == nil)
        #expect(IPv4AddressRange("192.0.2.2/32...192.0.2.7/32") == nil)
        #expect(IPv4AddressRange("192.0.2.2 ...192.0.2.7") == nil)
        #expect(IPv4AddressRange("192.0.2.2...192.0.2.7...192.0.2.8") == nil)
        #expect(AnyIPAddressRange("192.0.2.2...2001:db8::1") == nil)
    }

    @Test("Generic and family-erased ranges use canonical single-string Codable")
    func canonicalCodable() throws {
        let typed = try #require(IPv6AddressRange("2001:db8::1...2001:db8::f"))
        let typedData = try JSONEncoder().encode(typed)
        #expect(String(decoding: typedData, as: UTF8.self) == #""2001:db8::1...2001:db8::f""#)
        #expect(try JSONDecoder().decode(IPv6AddressRange.self, from: typedData) == typed)

        let erased = try #require(AnyIPAddressRange("192.0.2.2...192.0.2.7"))
        let erasedData = try JSONEncoder().encode(erased)
        #expect(String(decoding: erasedData, as: UTF8.self) == #""192.0.2.2...192.0.2.7""#)
        #expect(try JSONDecoder().decode(AnyIPAddressRange.self, from: erasedData) == erased)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                IPv6AddressRange.self,
                from: Data(#""2001:db8::f...2001:db8::1""#.utf8)
            )
        }
    }

    @Test("Containment, overlap, adjacency, and merging are exact")
    func exactRangeMath() throws {
        let first = try #require(IPv4AddressRange("192.0.2.2...192.0.2.7"))
        let contained = try #require(IPv4AddressRange("192.0.2.3...192.0.2.6"))
        let overlap = try #require(IPv4AddressRange("192.0.2.7...192.0.2.9"))
        let adjacent = try #require(IPv4AddressRange("192.0.2.8...192.0.2.10"))
        let gap = try #require(IPv4AddressRange("192.0.2.9...192.0.2.10"))

        #expect(first.contains(contained))
        #expect(first.contains(try #require(IPv4Address("192.0.2.4"))))
        #expect(first.overlaps(overlap))
        #expect(first.isAdjacent(to: adjacent))
        #expect(first.merged(with: adjacent)?.description == "192.0.2.2...192.0.2.10")
        #expect(first.merged(with: gap) == nil)
    }

    @Test("Range cardinality and adjacency handle address-family boundaries")
    func addressSpaceBoundaries() throws {
        let singleton = try #require(IPv4AddressRange("255.255.255.255...255.255.255.255"))
        let penultimate = try #require(IPv4AddressRange("255.255.255.254...255.255.255.254"))
        let allIPv4 = try #require(IPv4AddressRange("0.0.0.0...255.255.255.255"))
        let allIPv6 = try #require(
            IPv6AddressRange("::...ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")
        )

        #expect(singleton.rangeSizeIfRepresentable == 1)
        #expect(allIPv4.rangeSizeIfRepresentable == UInt128(UInt32.max) + 1)
        #expect(allIPv6.rangeSizeIfRepresentable == nil)
        #expect(penultimate.isAdjacent(to: singleton))
        #expect(singleton.isAdjacent(to: penultimate))
        #expect(!singleton.isAdjacent(to: singleton))
        #expect(
            singleton.merged(with: penultimate)?.description
                == "255.255.255.254...255.255.255.255"
        )
    }

    @Test("Coalescing is minimal, sorted, idempotent, and does not widen gaps")
    func coalescingInvariants() throws {
        let input = try [
            "192.0.2.8...192.0.2.9",
            "192.0.2.2...192.0.2.7",
            "192.0.2.3...192.0.2.5",
            "192.0.2.8...192.0.2.9",
            "192.0.2.11...192.0.2.12",
        ].map { try #require(IPv4AddressRange($0)) }

        let coalesced = IPv4AddressRange.coalescing(input)
        #expect(
            coalesced.map(\.description)
                == ["192.0.2.2...192.0.2.9", "192.0.2.11...192.0.2.12"]
        )
        #expect(IPv4AddressRange.coalescing(coalesced) == coalesced)
        #expect(!coalesced[0].contains(try #require(IPv4Address("192.0.2.10"))))
    }

    @Test("Network construction and summarization preserve coverage, not prefix structure")
    func networkBridge() throws {
        let network = try #require(IPv4Network("192.0.2.128/25"))
        let range = IPv4AddressRange(covering: network)

        #expect(range.description == "192.0.2.128...192.0.2.255")
        #expect(range.lowerBound.description == "192.0.2.128/32")
        #expect(range.upperBound.description == "192.0.2.255/32")

        let arbitrary = try #require(IPv4AddressRange("192.168.2.2...192.168.2.7"))
        let summarized = arbitrary.summarizedNetworks()
        #expect(
            summarized.map(\.description)
                == ["192.168.2.2/31", "192.168.2.4/30"]
        )
        // Prefix lengths are representation details; the supported round trip preserves
        // exact coverage even when the original range is not one canonical CIDR block.
        #expect(IPAddressCoverage<V4>(covering: summarized).ranges == [arbitrary])
    }

    @Test("Family erasure is deterministic and never combines address families")
    func mixedFamilyBoundary() throws {
        let ipv4 = try #require(AnyIPAddressRange("192.0.2.1...192.0.2.2"))
        let ipv6 = try #require(
            AnyIPAddressRange("2001:db8::1...2001:db8::2", parseOrder: .ipv6ThenIPv4)
        )

        #expect(ipv4.isIPv4)
        #expect(ipv4.v4?.description == "192.0.2.1...192.0.2.2")
        #expect(ipv6.isIPv6)
        #expect(ipv6.v6?.description == "2001:db8::1...2001:db8::2")
        #expect(ipv4.ianaValue == V4.ianaValue)
        #expect(ipv6.familyName == V6.familyName)
        #expect(!ipv4.contains(ipv6))
        #expect(!ipv4.overlaps(ipv6))
        #expect(!ipv4.isAdjacent(to: ipv6))
        #expect(ipv4.merged(with: ipv6) == nil)
        #expect(
            AnyIPAddressRange.coalescing([ipv6, ipv4]).map(\.description)
                == [ipv4.description, ipv6.description]
        )
        #expect(ipv4.summarizedNetworks().map(\.description) == ["192.0.2.1/32", "192.0.2.2/32"])
    }
}
