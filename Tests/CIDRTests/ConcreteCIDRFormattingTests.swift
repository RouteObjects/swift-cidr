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

import Testing
import CIDR

@Suite("Concrete CIDR Formatting Tests")
struct ConcreteCIDRFormattingTests {
    @Test("IPv4 concrete CIDR values preserve CIDR and family-specific text styles")
    func ipv4ConcreteCIDRValuesPreserveTextStyles() throws {
        let address = try #require(IPv4Address("192.0.2.77/24"))
        let network = try #require(IPv4Network("192.0.2.77/24"))
        let block = try #require(CIDRBlock<AF.V4>("192.0.2.77/24"))
        let multicastRange = try #require(IPv4MulticastGroupRange("239.1.2.0/24"))

        #expect(address.formatted(.addressAndNetmask) == "192.0.2.77 255.255.255.0")

        #expect(network.description == "192.0.2.0/24")
        #expect(network.formatted(.cidrNotation) == "192.0.2.0/24")
        #expect(network.formatted(.addressOnly) == "192.0.2.0")
        #expect(network.formatted(.addressAndNetmask) == "192.0.2.0 255.255.255.0")

        #expect(block.description == "192.0.2.0/24")
        #expect(block.formatted(.cidrNotation) == "192.0.2.0/24")
        #expect(block.formatted(.addressOnly) == "192.0.2.0")
        #expect(block.formatted(.addressAndNetmask) == "192.0.2.0 255.255.255.0")

        #expect(multicastRange.description == "239.1.2.0/24")
        #expect(multicastRange.formatted(.cidrNotation) == "239.1.2.0/24")
        #expect(multicastRange.formatted(.addressOnly) == "239.1.2.0")
        #expect(multicastRange.formatted(.addressAndNetmask) == "239.1.2.0 255.255.255.0")
    }

    @Test("IPv6 concrete CIDR values preserve CIDR and family-specific text styles")
    func ipv6ConcreteCIDRValuesPreserveTextStyles() throws {
        let address = try #require(IPv6Address("2001:db8::1/64"))
        let network = try #require(IPv6Network("2001:db8:abcd::1234/48"))
        let block = try #require(CIDRBlock<AF.V6>("2001:db8:abcd::1234/48"))
        let multicastRange = try #require(IPv6MulticastGroupRange("ff02::/16"))

        #expect(address.formatted(.compressed) == "2001:db8::1")
        #expect(address.description == "2001:db8::1/64")
        #expect(address.formatted(.cidrNotation) == "2001:db8::1/64")
        #expect(address.formatted(.preferred) == "2001:db8:0:0:0:0:0:1")

        #expect(network.description == "2001:db8:abcd::/48")
        #expect(network.formatted(.cidrNotation) == "2001:db8:abcd::/48")
        #expect(network.formatted(.addressOnly) == "2001:db8:abcd::")
        #expect(network.formatted(.compressed) == "2001:db8:abcd::")
        #expect(network.formatted(.preferred) == "2001:db8:abcd:0:0:0:0:0")

        #expect(block.description == "2001:db8:abcd::/48")
        #expect(block.formatted(.cidrNotation) == "2001:db8:abcd::/48")
        #expect(block.formatted(.addressOnly) == "2001:db8:abcd::")
        #expect(block.formatted(.compressed) == "2001:db8:abcd::")
        #expect(block.formatted(.preferred) == "2001:db8:abcd:0:0:0:0:0")

        #expect(multicastRange.description == "ff02::/16")
        #expect(multicastRange.formatted(.cidrNotation) == "ff02::/16")
        #expect(multicastRange.formatted(.addressOnly) == "ff02::")
        #expect(multicastRange.formatted(.compressed) == "ff02::")
        #expect(multicastRange.formatted(.preferred) == "ff02:0:0:0:0:0:0:0")
    }

    @Test("Concrete CIDR block and multicast raw UTF-8 writers preserve canonical output")
    func concreteRawUTF8WritersPreserveCanonicalOutput() throws {
        let ipv4Block = try #require(CIDRBlock<AF.V4>("192.0.2.77/24"))
        let ipv4MulticastRange = try #require(IPv4MulticastGroupRange("239.1.2.0/24"))
        let ipv6Block = try #require(CIDRBlock<AF.V6>("2001:db8:abcd::1234/48"))
        let ipv6MulticastRange = try #require(IPv6MulticastGroupRange("ff02::/16"))

        #expect(renderIPv4CIDR(ipv4Block) == "192.0.2.0/24")
        #expect(renderIPv4CIDR(ipv4MulticastRange) == "239.1.2.0/24")
        #expect(renderIPv6CompressedCIDR(ipv6Block) == "2001:db8:abcd::/48")
        #expect(renderIPv6CompressedCIDR(ipv6MulticastRange) == "ff02::/16")
    }

    private func renderIPv4CIDR<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V4 {
        render(capacity: CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count) { rawBuffer in
            value.writeCIDRNotationUTF8(into: rawBuffer)
        }
    }

    private func renderIPv6CompressedCIDR<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V6 {
        render(capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count) { rawBuffer in
            value.writeCompressedCIDRNotationUTF8(into: rawBuffer)
        }
    }

    private func render(
        capacity: Int,
        _ body: (UnsafeMutableRawBufferPointer) -> Int
    ) -> String {
        var storage = [UInt8](repeating: 0, count: capacity)
        let written = storage.withUnsafeMutableBytes { rawBuffer in
            body(rawBuffer)
        }
        return String(decoding: storage.prefix(written), as: UTF8.self)
    }
}
