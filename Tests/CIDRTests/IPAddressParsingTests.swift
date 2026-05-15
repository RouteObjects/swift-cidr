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

@Suite("IPAddress Parsing Tests")
struct IPAddressParsingTests {
    @Test("IPv4 address-only parsing keeps the full-width fallback prefix")
    func parsesIPv4AddressOnly() throws {
        let host = try #require(IPAddress<V4>("192.0.2.1"))

        #expect(host.address == 0xC0000201)
        #expect(host.storage == host.address)
        #expect(host.prefixLength.intValue == 32)
        #expect(host.description == "192.0.2.1/32")
    }

    @Test("IPv4 CIDR-qualified parsing preserves the explicit prefix")
    func parsesIPv4CIDRQualifiedAddress() throws {
        let host = try #require(IPAddress<V4>("192.0.2.1/24"))
        let maxLengthHost = try #require(IPAddress<V4>("255.255.255.255/32"))

        #expect(host.address == 0xC0000201)
        #expect(host.prefixLength.intValue == 24)
        #expect(host.network.description == "192.0.2.0/24")
        #expect(maxLengthHost.address == UInt32.max)
        #expect(maxLengthHost.prefixLength.intValue == 32)
    }

    @Test("IPv4 malformed CIDR-qualified address input is rejected")
    func rejectsMalformedIPv4CIDRAddressInput() {
        #expect(IPAddress<V4>("192.0.2.1/") == nil)
        #expect(IPAddress<V4>("/24") == nil)
        #expect(IPAddress<V4>("192.0.2.1/33") == nil)
        #expect(IPAddress<V4>("192.0.2.1/+24") == nil)
        #expect(IPAddress<V4>("192.0.2.1/-1") == nil)
        #expect(IPAddress<V4>("192.0.2.1/032") == nil)
        #expect(IPAddress<V4>("192.0.2.1/24/extra") == nil)
        #expect(IPAddress<V4>("192.0.2.1/24/1") == nil)
    }

    @Test("Selected IPv4 parser matches valid literals and rejects malformed input")
    func selectedIPv4ParserParsesAndRejectsCorrectly() {
        #expect(AF.V4.parseAddress("192.168.1.1") == 0xC0A80101)
        #expect(AF.V4.parseAddress("255.255.255.255") == UInt32.max)
        #expect(AF.V4.parseAddress("001.002.003.004") == 0x01020304)

        #expect(AF.V4.parseAddress("256.0.0.1") == nil)
        #expect(AF.V4.parseAddress("1..2.3") == nil)
        #expect(AF.V4.parseAddress("1.2.3") == nil)
        #expect(AF.V4.parseAddress("1.2.3.4.5") == nil)
        #expect(AF.V4.parseAddress("abc") == nil)
    }

    @Test("Selected IPv4 formatter covers one-, two-, and three-digit octets")
    func selectedIPv4FormatterCoversDecimalOctetWidths() {
        #expect(AF.V4.formatAddress(0x00000000) == "0.0.0.0")
        #expect(AF.V4.formatAddress(0x01020304) == "1.2.3.4")
        #expect(AF.V4.formatAddress(0x0A000001) == "10.0.0.1")
        #expect(AF.V4.formatAddress(0xC0A80101) == "192.168.1.1")
        #expect(AF.V4.formatAddress(UInt32.max) == "255.255.255.255")
    }

    @Test("IPv4 formatter covers every decimal octet value in every position")
    func selectedIPv4FormatterCoversAllOctetValuesByPosition() {
        for octet in UInt32(0)...UInt32(255) {
            let text = String(octet)

            #expect(AF.V4.formatAddress((octet << 24) | 0x0001_0203) == "\(text).1.2.3")
            #expect(AF.V4.formatAddress(0x0100_0203 | (octet << 16)) == "1.\(text).2.3")
            #expect(AF.V4.formatAddress(0x0102_0003 | (octet << 8)) == "1.2.\(text).3")
            #expect(AF.V4.formatAddress(0x0102_0300 | octet) == "1.2.3.\(text)")
        }
    }

    @Test("IPv6 address-only parsing keeps the full-width fallback prefix")
    func parsesIPv6AddressOnly() throws {
        let host = try #require(IPAddress<V6>("2001:db8::1"))

        #expect(host.prefixLength.intValue == 128)
        #expect(host.address == (UInt128(0x20010DB8) << 96) | 1)
        #expect(host.storage == host.address)
    }

    @Test("IPv6 CIDR-qualified parsing preserves the explicit prefix")
    func parsesIPv6CIDRQualifiedAddress() throws {
        let host = try #require(IPAddress<V6>("2001:db8::1/64"))
        let maxLengthHost = try #require(IPAddress<V6>("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"))

        #expect(host.prefixLength.intValue == 64)
        #expect(host.address == (UInt128(0x20010DB8) << 96) | 1)
        #expect(maxLengthHost.address == UInt128.max)
        #expect(maxLengthHost.prefixLength.intValue == 128)
    }

    @Test("IPv4-mapped IPv6 CIDR-qualified parsing preserves the explicit prefix")
    func parsesMappedIPv6CIDRQualifiedAddress() throws {
        let host = try #require(IPAddress<V6>("::ffff:192.0.2.1/96"))

        #expect(host.prefixLength.intValue == 96)
        #expect(host.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
    }

    @Test("IPv6 malformed CIDR-qualified address input is rejected")
    func rejectsMalformedIPv6CIDRAddressInput() {
        #expect(IPAddress<V6>("2001:db8::1/129") == nil)
        #expect(IPAddress<V6>("2001:db8::1/") == nil)
        #expect(IPAddress<V6>("/64") == nil)
        #expect(IPAddress<V6>("2001:db8::1/+64") == nil)
        #expect(IPAddress<V6>("2001:db8::1/-1") == nil)
        #expect(IPAddress<V6>("2001:db8::1/064") == nil)
        #expect(IPAddress<V6>("2001:db8::1/64/extra") == nil)
        #expect(IPAddress<V6>("2001:db8::1/64/1") == nil)
    }

    @Test("IPAddress description round-trips through the string parser")
    func roundTripsCanonicalDescription() throws {
        let ipv4 = try #require(IPAddress<V4>("192.0.2.1/24"))
        let ipv6 = try #require(IPAddress<V6>("2001:db8::1/64"))

        #expect(IPAddress<V4>(ipv4.description) == ipv4)
        #expect(IPAddress<V6>(ipv6.description) == ipv6)
    }
}
