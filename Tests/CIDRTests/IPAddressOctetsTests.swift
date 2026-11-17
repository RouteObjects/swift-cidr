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
@testable import CIDR

@Suite("IPAddress Octet Adapter Tests")
struct IPAddressOctetsTests {
    @Test("IPv4 network-order octets construct and project a known address")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4KnownAddress() {
        let wireOctets: InlineArray<4, UInt8> = [192, 0, 2, 129]
        let address = IPv4Address(octets: wireOctets)

        #expect(address.address == 0xC000_0281)
        #expect(address.prefixLength == .maximum)
        #expect(address.description == "192.0.2.129/32")
        #expect(address == IPv4Address(address: 0xC000_0281))
        expectEqual(address.octets, wireOctets)
    }

    @Test("IPv6 network-order octets construct and project a known address")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6KnownAddress() {
        let expected: InlineArray<16, UInt8> = [
            0x20, 0x01, 0x0D, 0xB8,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 1,
        ]
        let address = IPv6Address(octets: expected)

        #expect(address.address == (UInt128(0x2001_0DB8) << 96) | 1)
        #expect(address.prefixLength == .maximum)
        #expect(address == IPv6Address(address: (UInt128(0x2001_0DB8) << 96) | 1))
        expectEqual(address.octets, expected)
    }

    @Test("IPv6 network byte order preserves every distinct octet position")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6DistinctOctetPositions() {
        let octets: InlineArray<16, UInt8> = [
            0x00, 0x01, 0x02, 0x03,
            0x04, 0x05, 0x06, 0x07,
            0x08, 0x09, 0x0A, 0x0B,
            0x0C, 0x0D, 0x0E, 0x0F,
        ]
        let expectedAddress: UInt128 = 0x0001_0203_0405_0607_0809_0A0B_0C0D_0E0F
        let address = IPv6Address(octets: octets)

        #expect(address.address == expectedAddress)
        expectEqual(address.octets, octets)
    }

    @Test("IPv4 zero and maximum values preserve every octet")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4ZeroAndMaximum() {
        let zeroOctets: InlineArray<4, UInt8> = [0, 0, 0, 0]
        let maximumOctets: InlineArray<4, UInt8> = [255, 255, 255, 255]
        let zero = IPv4Address(octets: zeroOctets)
        let maximum = IPv4Address(octets: maximumOctets)

        #expect(zero.address == UInt32.zero)
        #expect(maximum.address == UInt32.max)
        expectEqual(zero.octets, zeroOctets)
        expectEqual(maximum.octets, maximumOctets)
    }

    @Test("IPv6 zero and maximum values preserve every octet")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6ZeroAndMaximum() {
        let zeroOctets: InlineArray<16, UInt8> = [
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
        ]
        let maximumOctets: InlineArray<16, UInt8> = [
            255, 255, 255, 255, 255, 255, 255, 255,
            255, 255, 255, 255, 255, 255, 255, 255,
        ]
        let zero = IPv6Address(octets: zeroOctets)
        let maximum = IPv6Address(octets: maximumOctets)

        #expect(zero.address == UInt128.zero)
        #expect(maximum.address == UInt128.max)
        expectEqual(zero.octets, zeroOctets)
        expectEqual(maximum.octets, maximumOctets)
    }

    @Test("IPv4 octets are independent of explicit prefix context")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4ExplicitPrefix() throws {
        let octets: InlineArray<4, UInt8> = [192, 0, 2, 1]
        let prefix = try #require(IPv4PrefixLength(24))
        let address = IPv4Address(octets: octets, prefixLength: prefix)

        #expect(address.prefixLength == prefix)
        expectEqual(address.octets, IPv4Address(octets: octets).octets)
    }

    @Test("IPv6 octets are independent of explicit prefix context")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6ExplicitPrefix() throws {
        let octets: InlineArray<16, UInt8> = [
            0x20, 0x01, 0x0D, 0xB8,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 1,
        ]
        let prefix = try #require(IPv6PrefixLength(64))
        let address = IPv6Address(octets: octets, prefixLength: prefix)

        #expect(address.prefixLength == prefix)
        expectEqual(address.octets, IPv6Address(octets: octets).octets)
    }

    @Test("IPv4 octets preserve host bits instead of canonicalizing a network")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4HostBitsRemainAddressIdentity() throws {
        let octets: InlineArray<4, UInt8> = [192, 0, 2, 129]
        let prefix = try #require(IPv4PrefixLength(24))
        let address = IPv4Address(octets: octets, prefixLength: prefix)

        #expect(address.address == 0xC000_0281)
        #expect(address.network.prefix == 0xC000_0200)
        expectEqual(address.octets, octets)
    }

    @Test("Octet round trips retain the caller-supplied prefix context")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func roundTripsWithPrefixContext() throws {
        let ipv4Prefix = try #require(IPv4PrefixLength(24))
        let ipv6Prefix = try #require(IPv6PrefixLength(64))
        let ipv4 = IPv4Address(address: 0xC000_0281, prefixLength: ipv4Prefix)
        let ipv6 = IPv6Address(
            address: (UInt128(0x2001_0DB8) << 96) | 0x0123_4567_89AB_CDEF,
            prefixLength: ipv6Prefix
        )

        #expect(IPv4Address(octets: ipv4.octets, prefixLength: ipv4.prefixLength) == ipv4)
        #expect(IPv6Address(octets: ipv6.octets, prefixLength: ipv6.prefixLength) == ipv6)
    }

    @Test("IPv4 spans decode independent network-order fixtures with host-length context")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4SpanFixtures() throws {
        let fixtures: [([UInt8], UInt32)] = [
            ([0, 0, 0, 0], 0),
            ([255, 255, 255, 255], .max),
            ([192, 0, 2, 129], 0xC000_0281),
            ([1, 35, 69, 103], 0x0123_4567),
        ]

        for (octets, expected) in fixtures {
            let result = IPv4Address(octets: octets.span)
            let address = try #require(result)
            let owned: InlineArray<4, UInt8> = [octets[0], octets[1], octets[2], octets[3]]

            #expect(address.address == expected)
            #expect(address.prefixLength == .maximum)
            #expect(address == IPv4Address(octets: owned))
            expectEqual(address.octets, owned)
        }
    }

    @Test("IPv6 spans decode independent network-order fixtures with host-length context")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6SpanFixtures() throws {
        let fixtures: [([UInt8], UInt128)] = [
            (Array(repeating: 0, count: 16), 0),
            (Array(repeating: 255, count: 16), .max),
            (
                [0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
                0x2001_0DB8_0000_0000_0000_0000_0000_0001
            ),
            (
                [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
                0x0001_0203_0405_0607_0809_0A0B_0C0D_0E0F
            ),
            (
                [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 192, 0, 2, 129],
                0x0000_0000_0000_0000_0000_FFFF_C000_0281
            ),
        ]

        for (octets, expected) in fixtures {
            let result = IPv6Address(octets: octets.span)
            let address = try #require(result)
            let owned: InlineArray<16, UInt8> = [
                octets[0], octets[1], octets[2], octets[3],
                octets[4], octets[5], octets[6], octets[7],
                octets[8], octets[9], octets[10], octets[11],
                octets[12], octets[13], octets[14], octets[15],
            ]

            #expect(address.address == expected)
            #expect(address.prefixLength == .maximum)
            #expect(address == IPv6Address(octets: owned))
            expectEqual(address.octets, owned)
        }
    }

    @Test("Span constructors require exactly the address-family byte count", arguments: Array(0...32) + [64, 4096])
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func spanExactLengths(count: Int) {
        let octets = Array(repeating: UInt8(0xA5), count: count)
        let ipv4 = IPv4Address(octets: octets.span)
        let ipv6 = IPv6Address(octets: octets.span)

        #expect((ipv4 != nil) == (count == 4))
        #expect((ipv6 != nil) == (count == 16))
    }

    @Test("IPv4 span slices accept arbitrary byte offsets", arguments: 0..<32)
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4SpanOffsets(offset: Int) throws {
        // CHANGE: Exercise every alignment without assuming the backing array's base alignment.
        let buffer = Array(repeating: UInt8(0xA5), count: offset) + [192, 0, 2, 129] + [0x5A]
        let prefix = try #require(IPv4PrefixLength(24))
        let result = IPv4Address(
            octets: buffer.span.extracting(offset..<(offset + 4)),
            prefixLength: prefix
        )
        let address = try #require(result)
        let expected: InlineArray<4, UInt8> = [192, 0, 2, 129]

        #expect(address.address == 0xC000_0281)
        #expect(address.prefixLength == prefix)
        #expect(address == IPv4Address(octets: expected, prefixLength: prefix))
        expectEqual(address.octets, expected)
    }

    @Test("IPv6 span slices accept arbitrary byte offsets", arguments: 0..<32)
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6SpanOffsets(offset: Int) throws {
        let wireOctets: [UInt8] = [
            0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0,
            0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
        ]
        let buffer = Array(repeating: UInt8(0xA5), count: offset) + wireOctets + [0x5A]
        let prefix = try #require(IPv6PrefixLength(64))
        let result = IPv6Address(
            octets: buffer.span.extracting(offset..<(offset + 16)),
            prefixLength: prefix
        )
        let address = try #require(result)
        let expected: InlineArray<16, UInt8> = [
            0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0,
            0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
        ]

        #expect(address.address == 0x2001_0DB8_0000_0000_0123_4567_89AB_CDEF)
        #expect(address.prefixLength == prefix)
        #expect(address == IPv6Address(octets: expected, prefixLength: prefix))
        expectEqual(address.octets, expected)
    }

    @Test("IPv4 spans preserve every legal prefix and all host bits", arguments: 0...32)
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv4SpanPrefixContexts(length: Int) throws {
        let octets: InlineArray<4, UInt8> = [192, 0, 2, 129]
        let prefix = try #require(IPv4PrefixLength(length))
        let result = IPv4Address(octets: octets.span, prefixLength: prefix)
        let address = try #require(result)

        #expect(address.address == 0xC000_0281)
        #expect(address.prefixLength == prefix)
        #expect(address == IPv4Address(octets: octets, prefixLength: prefix))
        expectEqual(address.octets, octets)
    }

    @Test("IPv6 spans preserve every legal prefix and all host bits", arguments: 0...128)
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func ipv6SpanPrefixContexts(length: Int) throws {
        let octets: InlineArray<16, UInt8> = [
            0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0,
            0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
        ]
        let prefix = try #require(IPv6PrefixLength(length))
        let result = IPv6Address(octets: octets.span, prefixLength: prefix)
        let address = try #require(result)

        #expect(address.address == 0x2001_0DB8_0000_0000_0123_4567_89AB_CDEF)
        #expect(address.prefixLength == prefix)
        #expect(address == IPv6Address(octets: octets, prefixLength: prefix))
        expectEqual(address.octets, octets)
    }

    @Test("Span construction produces owned addresses that outlive the borrowed storage")
    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func spanResultsOwnTheirAddressBits() throws {
        let ipv4: IPv4Address
        let ipv6: IPv6Address
        do {
            let octets: [UInt8] = [192, 0, 2, 129]
            let result = IPv4Address(octets: octets.span)
            ipv4 = try #require(result)
        }
        do {
            let octets: [UInt8] = [
                0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 1,
            ]
            let result = IPv6Address(octets: octets.span)
            ipv6 = try #require(result)
        }

        #expect(ipv4.address == 0xC000_0281)
        #expect(ipv4.prefixLength == .maximum)
        #expect(ipv6.address == 0x2001_0DB8_0000_0000_0000_0000_0000_0001)
        #expect(ipv6.prefixLength == .maximum)
    }

    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    private func expectEqual(
        _ actual: InlineArray<4, UInt8>,
        _ expected: InlineArray<4, UInt8>
    ) {
        for index in 0..<4 {
            #expect(actual[index] == expected[index])
        }
    }

    @available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    private func expectEqual(
        _ actual: InlineArray<16, UInt8>,
        _ expected: InlineArray<16, UInt8>
    ) {
        for index in 0..<16 {
            #expect(actual[index] == expected[index])
        }
    }
}
