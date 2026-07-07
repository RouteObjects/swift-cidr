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

import Foundation
import Testing
@testable import CIDR

@Suite("CIDR Block Tests")
struct CIDRBlockTests {
    @Test("CIDRBlock canonicalizes stored prefix bits and exposes neutral range math")
    func cidrBlockCanonicalizesAndContains() throws {
        let block = try #require(CIDRBlock<V4>("192.0.2.1/24"))
        let child = try #require(CIDRBlock<V4>("192.0.2.128/25"))
        let overlap = try #require(CIDRBlock<V4>("192.0.2.192/26"))
        let outside = try #require(CIDRBlock<V4>("192.0.3.0/24"))
        let network = try #require(IPv4Network("192.0.2.64/26"))
        let address = try #require(IPv4Address("192.0.2.42"))

        #expect(block.prefix == 0xC0000200)
        #expect(block.description == "192.0.2.0/24")
        #expect(block.firstAddress.description == "192.0.2.0/32")
        #expect(block.lastAddress.description == "192.0.2.255/32")
        #expect(block.rangeSizeIfRepresentable == 256)
        #expect(block.contains(address))
        #expect(block.contains(child))
        #expect(block.contains(network))
        #expect(block.overlaps(overlap))
        #expect(child.isWithin(block))
        #expect(!block.contains(outside))
        #expect(!block.overlaps(outside))
    }

    @Test("IPNetwork construction can be bounded by a parent CIDRBlock")
    func ipNetworkConstructionWithinCIDRBlock() throws {
        let parent = try #require(CIDRBlock<V4>("198.51.100.0/24"))
        let child = try #require(IPv4Network("198.51.100.4/30", within: parent))
        let equal = try #require(IPv4Network("198.51.100.0/24", within: parent))
        let rawPrefix = try #require(IPv4Address("198.51.100.77"))
        let rawPrefixLength = try #require(IPv4PrefixLength(30))
        let rawChild = try #require(IPv4Network(prefix: rawPrefix.address, prefixLength: rawPrefixLength, within: parent))

        #expect(child.description == "198.51.100.4/30")
        #expect(equal.description == "198.51.100.0/24")
        #expect(rawChild.description == "198.51.100.76/30")
        #expect(parent.contains(child))
        #expect(parent.contains(equal))
        #expect(IPv4Network("198.51.101.0/24", within: parent) == nil)
        #expect(IPv4Network("198.51.100.0/23", within: parent) == nil)
    }

    @Test("IPv6 networks can be bounded by a parent CIDRBlock")
    func ipv6NetworkConstructionWithinCIDRBlock() throws {
        let parent = try #require(CIDRBlock<V6>("2001:db8::/32"))
        let child = try #require(IPv6Network("2001:db8:1::/48", within: parent))
        let equal = try #require(IPv6Network("2001:db8::/32", within: parent))
        let rawPrefix = try #require(IPv6Address("2001:db8:abcd::1"))
        let rawPrefixLength = try #require(IPv6PrefixLength(48))
        let rawChild = try #require(IPv6Network(prefix: rawPrefix.address, prefixLength: rawPrefixLength, within: parent))

        #expect(child.description == "2001:db8:1::/48")
        #expect(equal.description == "2001:db8::/32")
        #expect(rawChild.description == "2001:db8:abcd::/48")
        #expect(parent.contains(child))
        #expect(parent.contains(equal))
        #expect(IPv6Network("2001:db9::/32", within: parent) == nil)
        #expect(IPv6Network("2001:db8::/31", within: parent) == nil)
    }

    @Test("CIDRBlock reports range sizes when UInt128 can represent the count")
    func cidrBlockRangeSizeRepresentation() throws {
        let ipv4Default = try #require(CIDRBlock<V4>("0.0.0.0/0"))
        let ipv6Half = try #require(CIDRBlock<V6>("8000::/1"))
        let ipv6Default = try #require(CIDRBlock<V6>("::/0"))

        #expect(ipv4Default.rangeSizeIfRepresentable == UInt128(UInt32.max) + 1)
        #expect(ipv6Half.rangeSizeIfRepresentable == UInt128(1) << 127)
        #expect(ipv6Default.rangeSizeIfRepresentable == nil)
    }

    @Test("CIDRBlock encodes and decodes as canonical CIDR text")
    func cidrBlockCodableRoundTrip() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        let block = try #require(CIDRBlock<V4>("192.0.2.1/24"))
        let encoded = try encoder.encode(block)
        let decoded = try decoder.decode(CIDRBlock<V4>.self, from: encoded)

        #expect(try decoder.decode(String.self, from: encoded) == "192.0.2.0/24")
        #expect(decoded == block)
        #expect(try decoder.decode(CIDRBlock<V4>.self, from: Data(#""192.0.2.1/24""#.utf8)).description == "192.0.2.0/24")
    }
}
