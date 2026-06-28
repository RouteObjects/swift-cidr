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

@Suite("CIDR UTF-8 Formatting Tests")
struct CIDRUTF8FormattingTests {
    @Test("Public capacity constants match maximum literal sizes")
    func capacityConstantsMatchMaximumLiteralSizes() {
        #expect(CIDRUTF8Formatting.maximumIPv4AddressLiteralUTF8Count == "255.255.255.255".utf8.count)
        #expect(CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count == "255.255.255.255/32".utf8.count)
        #expect(
            CIDRUTF8Formatting.maximumCompressedIPv6AddressLiteralUTF8Count
                == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff".utf8.count
        )
        #expect(
            CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
                == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128".utf8.count
        )
    }

    @Test("IPv4 address writer emits expected literals")
    func ipv4AddressWriterEmitsExpectedLiterals() {
        let cases: [(IPv4Address, String)] = [
            (IPv4Address(address: 0), "0.0.0.0"),
            (IPv4Address(address: 0x7F00_0001), "127.0.0.1"),
            (IPv4Address(address: UInt32.max), "255.255.255.255"),
            (IPv4Address(address: 0x7B2D_0600), "123.45.6.0"),
        ]

        for (address, expected) in cases {
            #expect(renderIPv4Address(address) == expected)
        }
    }

    @Test("IPv4 CIDR writer emits address and canonical network notation")
    func ipv4CIDRWriterEmitsExpectedNotation() throws {
        let address = try #require(IPv4Address("192.0.2.77/24"))
        let network = try #require(IPv4Network("192.0.2.77/24"))
        let maximum = IPv4Address(address: UInt32.max)

        #expect(renderIPv4CIDR(address) == "192.0.2.77/24")
        #expect(renderIPv4CIDR(network) == "192.0.2.0/24")
        #expect(renderIPv4CIDR(maximum) == "255.255.255.255/32")
    }

    @Test("IPv6 compressed address writer emits expected literals")
    func ipv6CompressedAddressWriterEmitsExpectedLiterals() {
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)
        let cases: [(IPv6Address, String)] = [
            (IPv6Address(address: 0), "::"),
            (IPv6Address(address: 1), "::1"),
            (IPv6Address(address: UInt128.max), "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"),
            (IPv6Address(address: 0x85a0_850a_8500_0000_0000_00af_805a_085a), "85a0:850a:8500::af:805a:85a"),
            (IPv6Address(address: mappedAddress), "::ffff:c000:201"),
        ]

        for (address, expected) in cases {
            #expect(renderIPv6CompressedAddress(address) == expected)
        }
    }

    @Test("IPv6 compressed CIDR writer emits address and canonical network notation")
    func ipv6CompressedCIDRWriterEmitsExpectedNotation() throws {
        let address = try #require(IPv6Address("2001:db8::1/64"))
        let network = try #require(IPv6Network("2001:db8:abcd::1234/48"))
        let maximum = IPv6Address(address: UInt128.max)

        #expect(renderIPv6CompressedCIDR(address) == "2001:db8::1/64")
        #expect(renderIPv6CompressedCIDR(network) == "2001:db8:abcd::/48")
        #expect(renderIPv6CompressedCIDR(maximum) == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128")
    }

    private func renderIPv4Address<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V4 {
        render(capacity: CIDRUTF8Formatting.maximumIPv4AddressLiteralUTF8Count) { rawBuffer in
            value.writeAddressLiteralUTF8(into: rawBuffer)
        }
    }

    private func renderIPv4CIDR<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V4 {
        render(capacity: CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count) { rawBuffer in
            value.writeCIDRNotationUTF8(into: rawBuffer)
        }
    }

    private func renderIPv6CompressedAddress<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V6 {
        render(capacity: CIDRUTF8Formatting.maximumCompressedIPv6AddressLiteralUTF8Count) { rawBuffer in
            value.writeCompressedAddressLiteralUTF8(into: rawBuffer)
        }
    }

    private func renderIPv6CompressedCIDR<Value: CIDR>(_ value: Value) -> String where Value.Family == AF.V6 {
        render(capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count) { rawBuffer in
            value.writeCompressedCIDRNotationUTF8(into: rawBuffer)
        }
    }

    /// A test adapter helper that converts low-level byte-writing operations into `String` values
    /// for easy assertion testing.
    ///
    /// - Note: This helper uses **Destination-Passing Style (DPS)** by allocating a temporary
    ///   buffer and passing it to the formatting closure. While `String(decoding:as:)` is called here
    ///   to allow string assertions, production integrations (like NIO) write directly to their
    ///   own storage and bypass String creation entirely.
    private func render(
        capacity: Int,
        _ body: (UnsafeMutableRawBufferPointer) -> Int
    ) -> String {
        // Allocate temporary storage of the required capacity on the stack/heap.
        var storage = [UInt8](repeating: 0, count: capacity)

        // Pin the array memory and pass the raw buffer to the formatter.
        let written = storage.withUnsafeMutableBytes { rawBuffer in
            body(rawBuffer)
        }

        // Transcode and copy the initialized bytes into a String.
        // Small strings (<= 15 bytes) are optimized inline, avoiding heap allocations.
        return String(decoding: storage.prefix(written), as: UTF8.self)
    }
}
