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
