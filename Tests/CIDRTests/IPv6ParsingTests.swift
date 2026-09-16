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

@Suite("IPv6 Parsing Tests")
struct IPv6ParsingTests {
    @Test(
        "Malformed IPv6 components are rejected by direct, CIDR, generic, and range parsing",
        arguments: [
            "00000::1", "1:00000::2", "::00000", "00001::", "::00000000000000000000000000000000",
            "1:2:3:4:5:6:7:8:", "::1:", "2001:db8::1:",
            "::1:2:3:4:5:6:7:8", "1:2:3:4::5:6:7:8", "1:2:3:4:5:6:7:8::",
            "1:2:3:4:5:6::192.0.2.1", "::1:2:3:4:5:6:192.0.2.1",
            "1:2:3::4:5:6:192.0.2.1", "1::2::3", "2001:db8:::1",
            "1:2:3:4:5:6:7:8:9", "1:2:3:4:5:6:7", ":1:2:3:4:5:6:7",
            "::ffff:0001.2.3.4", "::ffff:192.0.2.256", "::ffff:192..2.1",
        ]
    )
    func rejectsMalformedIPv6Components(_ literal: String) {
        #expect(AF.V6.parseAddress(literal) == nil)
        #expect(IPv6Address(literal) == nil)
        #expect(parseGenericAddress(literal, family: AF.V6.self) == nil)
        #expect(parseLossless(literal, as: IPv6Address.self) == nil)

        for suffix in ["/64", "/128"] {
            let cidr = literal + suffix
            #expect(IPv6Address(cidr) == nil)
            #expect(IPv6Network(cidr) == nil)
            #expect(parseGenericAddress(cidr, family: AF.V6.self) == nil)
            #expect(parseGenericNetwork(cidr, family: AF.V6.self) == nil)
            #expect(parseLossless(cidr, as: IPv6Address.self) == nil)
            #expect(parseLossless(cidr, as: IPv6Network.self) == nil)
        }

        #expect(IPv6AddressRange("\(literal)...ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff") == nil)
        #expect(IPv6AddressRange("::...\(literal)") == nil)
    }

    @Test(
        "Valid hextet and compression boundaries preserve bits and prefix context",
        arguments: [
            ("::", "0000:0000:0000:0000:0000:0000:0000:0000"),
            ("::1", "0000:0000:0000:0000:0000:0000:0000:0001"),
            ("0000::0001", "0000:0000:0000:0000:0000:0000:0000:0001"),
            ("FFFF:ffff:FFFF:ffff:FFFF:ffff:FFFF:ffff", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"),
            ("1:2:3:4:5:6:7:8", "0001:0002:0003:0004:0005:0006:0007:0008"),
            ("::1:2:3:4:5:6:7", "0000:0001:0002:0003:0004:0005:0006:0007"),
            ("1:2:3:4::5:6:7", "0001:0002:0003:0004:0000:0005:0006:0007"),
            ("1:2:3:4:5:6:7::", "0001:0002:0003:0004:0005:0006:0007:0000"),
            ("1:2:3:4:5:6:192.0.2.1", "0001:0002:0003:0004:0005:0006:c000:0201"),
            ("1:2:3:4:5::192.0.2.1", "0001:0002:0003:0004:0005:0000:c000:0201"),
            ("::ffff:192.0.2.1", "0000:0000:0000:0000:0000:ffff:c000:0201"),
            ("::ffff:192.000.002.001", "0000:0000:0000:0000:0000:ffff:c000:0201"),
        ]
    )
    func acceptsValidIPv6ComponentBoundaries(_ literal: String, expanded: String) throws {
        let expected = try #require(AF.V6.parseAddress(expanded))
        let address = try #require(IPv6Address(literal))
        #expect(AF.V6.parseAddress(literal) == expected)
        #expect(address.address == expected)
        #expect(address.prefixLength == .maximum)
        #expect(parseGenericAddress(literal, family: AF.V6.self) == address)
        #expect(parseLossless(literal, as: IPv6Address.self) == address)

        let prefixed = try #require(IPv6Address(literal + "/64"))
        let network = try #require(IPv6Network(literal + "/64"))
        #expect(prefixed.address == expected)
        #expect(prefixed.prefixLength.intValue == 64)
        #expect(network == prefixed.network)
        #expect(parseGenericAddress(literal + "/64", family: AF.V6.self) == prefixed)
        #expect(parseGenericNetwork(literal + "/64", family: AF.V6.self) == network)
        #expect(parseLossless(literal + "/64", as: IPv6Address.self) == prefixed)
        #expect(parseLossless(literal + "/64", as: IPv6Network.self) == network)
        #expect(IPv6Address(address.description) == address)
    }

    private func parseGenericAddress<Family: IPAddressFamily>(
        _ text: String, family: Family.Type
    ) -> IPAddress<Family>? {
        IPAddress<Family>(text)
    }

    private func parseGenericNetwork<Family: IPAddressFamily>(
        _ text: String, family: Family.Type
    ) -> IPNetwork<Family>? {
        IPNetwork<Family>(text)
    }

    private func parseLossless<Value: LosslessStringConvertible>(_ text: String, as type: Value.Type) -> Value? {
        Value(text)
    }

    @Test("Leading double-colon IPv6 shorthand parses correctly")
    func parsesLeadingDoubleColonShorthand() throws {
        let host = try #require(IPv6Address("::1"))

        #expect(host.address == UInt128(1))
    }

    @Test("IPv4-mapped mixed notation parses through the IPv6 family parser")
    func parsesMappedMixedNotation() throws {
        let host = try #require(IPv6Address("::ffff:192.0.2.1"))
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)

        #expect(host.address == mappedAddress)

        let network = IPNetwork<V6>(host: host)
        #expect(network.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
    }

    @Test("Mixed IPv4 notation is accepted in the low 32 IPv6 bits")
    func parsesMixedIPv4NotationInLowBits() {
        let expectedDocumentationAddress = (UInt128(0x20010DB8) << 96) | UInt128(0xC0000201)
        let expectedPrivateAddress = (UInt128(0xFFFF) << 32) | UInt128(0x0A000001)

        #expect(AF.V6.parseAddress("2001:db8::192.0.2.1") == expectedDocumentationAddress)
        #expect(AF.V6.parseAddress("::ffff:10.0.0.1") == expectedPrivateAddress)
    }

    @Test("Embedded IPv4 notation follows IPv4 octet parsing rules")
    func embeddedIPv4NotationRejectsMalformedOctets() {
        #expect(AF.V6.parseAddress("::ffff:0001.2.3.4") == nil)
        #expect(AF.V6.parseAddress("::ffff:1.0002.3.4") == nil)
        #expect(AF.V6.parseAddress("::ffff:1a2.0.0.1") == nil)
        #expect(AF.V6.parseAddress("::ffff:256.0.0.1") == nil)
    }

    @Test("IPv6 parser rejects hextets above ffff")
    func rejectsOversizedHextets() {
        #expect(IPv6Address("2001:db8::10000:1") == nil)
    }

    @Test("Selected IPv6 parser handles canonical, shorthand, middle-compressed, and mapped input")
    func selectedIPv6ParserHandlesSupportedInput() throws {
        let expectedLoopbackish = (UInt128(0x20010DB8) << 96) | UInt128(1)
        let expectedMiddleCompressed = (UInt128(0x20010DB885A30000) << 64) | UInt128(0x00008A2E03707334)
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)

        #expect(AF.V6.parseAddress("2001:0db8:0000:0000:0000:0000:0000:0001") == expectedLoopbackish)
        #expect(AF.V6.parseAddress("::1") == UInt128(1))
        #expect(AF.V6.parseAddress("2001:db8::1") == expectedLoopbackish)
        #expect(AF.V6.parseAddress("2001:db8:85a3::8a2e:370:7334") == expectedMiddleCompressed)
        #expect(AF.V6.parseAddress("::ffff:192.0.2.1") == mappedAddress)

        #expect(AF.V6.parseAddress("2001:db8:::1") == nil)
        #expect(AF.V6.parseAddress("2001:db8::g1") == nil)
    }
}
