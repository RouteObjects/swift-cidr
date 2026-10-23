//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
// Copyright (c) 2026 Craig A. Munro
// Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CIDR
import Foundation
import Testing

@Suite("IP Parsing Policy Tests")
struct IPParsingPolicyTests {
    @Test("Compatible parsing preserves decimal padded IPv4 ingestion")
    func compatibleIPv4Octets() throws {
        let examples: [(text: String, bits: UInt32)] = [
            ("012.0.0.1", 0x0C000001),
            ("010.0.0.1", 0x0A000001),
            ("001.002.003.004", 0x01020304),
            ("000.000.000.000", 0),
        ]
        for example in examples {
            let address = try #require(IPv4Address(example.text, policy: .compatible))
            #expect(address.address == example.bits)
            #expect(address.prefixLength == .maximum)
            #expect(IPv4Address(example.text) == address)
            #expect(genericAddress(V4.self, example.text, policy: .compatible) == address)
            let qualified = example.text + "/24"
            let network = try #require(IPv4Network(qualified, policy: .compatible))
            #expect(network.prefix == example.bits & 0xFFFFFF00)
            #expect(network.prefixLength.intValue == 24)
            #expect(IPv4Network(qualified) == network)
            #expect(genericNetwork(V4.self, qualified, policy: .compatible) == network)
            let data = try JSONEncoder().encode(example.text)
            #expect(try JSONDecoder().decode(IPv4Address.self, from: data) == address)
        }
    }

    @Test("Strict IPv4 rejects padded octets without changing canonical address semantics")
    func strictIPv4Octets() throws {
        for text in ["012.0.0.1", "192.000.2.1", "192.0.002.1", "192.0.2.001", "000.0.0.0"] {
            #expect(IPv4Address(text, policy: .strict) == nil, "\(text)")
            #expect(genericAddress(V4.self, text, policy: .strict) == nil, "\(text)")
            #expect(IPv4Network(text + "/24", policy: .strict) == nil, "\(text)")
            #expect(genericNetwork(V4.self, text + "/24", policy: .strict) == nil, "\(text)")
        }
        for text in ["0.0.0.0", "1.2.3.4", "192.0.2.1", "255.255.255.255"] {
            let strict = try #require(IPv4Address(text, policy: .strict))
            #expect(strict == IPv4Address(text))
            #expect(strict.prefixLength == .maximum)
        }
        let host = try #require(IPv4Address("192.0.2.129/24", policy: .strict))
        #expect(host.address == 0xC0000281)
        #expect(host.prefixLength.intValue == 24)
        #expect(IPv4Network("192.0.2.129/24", policy: .strict) == host.network)
        #expect(IPv4Network("192.0.2.1", policy: .strict) == nil)
    }

    @Test("IPv6 dotted tails use the same IPv4 policy for mapped and nonmapped addresses")
    func ipv6DottedTailPolicy() throws {
        let examples = [
            ("::ffff:012.0.0.1", "::ffff:c00:1"),
            ("2001:db8::012.0.0.1", "2001:db8::c00:1"),
            ("::ffff:192.000.2.1", "::ffff:c000:201"),
            ("::192.0.002.1", "::c000:201"),
            ("2001:db8::192.0.2.001", "2001:db8::c000:201"),
        ]
        for (text, literal) in examples {
            let compatible = try #require(IPv6Address(text, policy: .compatible))
            #expect(compatible.addressLiteral == literal)
            #expect(IPv6Address(text) == compatible)
            #expect(genericAddress(V6.self, text, policy: .compatible) == compatible)
            #expect(IPv6Address(text, policy: .strict) == nil, "\(text)")
            #expect(genericAddress(V6.self, text, policy: .strict) == nil, "\(text)")
            #expect(IPv6Network(text + "/96", policy: .strict) == nil, "\(text)")
            #expect(genericNetwork(V6.self, text + "/96", policy: .strict) == nil, "\(text)")
            #expect(IPv6Network(text + "/96", policy: .compatible) != nil)
        }
    }

    @Test("Strict IPv6 permits ordinary hextet spelling and unpadded dotted tails")
    func strictIPv6AcceptedForms() throws {
        for text in [
            "::", "::1", "2001:0DB8:0000:0000:0000:0000:0000:0001",
            "::ffff:192.0.2.1", "2001:db8::192.0.2.1", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        ] {
            let address = try #require(IPv6Address(text, policy: .strict))
            #expect(address == IPv6Address(text))
            #expect(address.prefixLength == .maximum)
            #expect(genericAddress(V6.self, text, policy: .strict) == address)
        }
        let address = try #require(IPv6Address("2001:0DB8::1/64", policy: .strict))
        #expect(address.addressLiteral == "2001:db8::1")
        #expect(address.prefixLength.intValue == 64)
        #expect(IPv6Network("2001:0DB8::1/64", policy: .strict) == address.network)
        #expect(IPv6Network("2001:db8::1", policy: .strict) == nil)
    }

    @Test("Address-only family parsers do not acquire CIDR grammar")
    func rawAddressParserContract() {
        #expect(V4.parseAddress("192.0.2.1/24") == nil)
        #expect(V6.parseAddress("2001:db8::1/64") == nil)
        #expect(V4.parseAddress("012.0.0.1") == 0x0C000001)
        #expect(V4.parseCIDR("192.0.2.1", requiresPrefix: true, policy: .strict) == nil)
        #expect(V6.parseCIDR("2001:db8::1", requiresPrefix: true, policy: .strict) == nil)
        #expect(V4.parseCIDR("192.0.2.1", requiresPrefix: false, policy: .strict)?.prefixLength == 32)
        #expect(V6.parseCIDR("2001:db8::1", requiresPrefix: false, policy: .strict)?.prefixLength == 128)
    }

    @Test("Both policies require canonical prefix text")
    func policyCannotRelaxPrefixGrammar() {
        for policy in [IPAddressParsingPolicy.compatible, .strict] {
            for suffix in ["+0", "-0", "00", "000", "+24", "024", "２４"] {
                #expect(IPv4Address("192.0.2.1/" + suffix, policy: policy) == nil)
                #expect(IPv4Network("192.0.2.1/" + suffix, policy: policy) == nil)
                #expect(IPv6Address("2001:db8::1/" + suffix, policy: policy) == nil)
                #expect(IPv6Network("2001:db8::1/" + suffix, policy: policy) == nil)
                #expect(genericAddress(V4.self, "192.0.2.1/" + suffix, policy: policy) == nil)
                #expect(genericNetwork(V6.self, "2001:db8::1/" + suffix, policy: policy) == nil)
            }
        }
    }

    @Test("AnyIP propagates policy through both family parse orders")
    func erasedPolicyAndParseOrder() throws {
        for order in [AddressFamilyParseOrder.ipv4ThenIPv6, .ipv6ThenIPv4] {
            for text in ["012.0.0.1", "::ffff:012.0.0.1", "2001:db8::012.0.0.1"] {
                #expect(AnyIPAddress(text, policy: .strict, parseOrder: order) == nil, "\(text)")
                #expect(AnyIPNetwork(text + "/24", policy: .strict, parseOrder: order) == nil, "\(text)")
                #expect(AnyIPAddress(text, policy: .compatible, parseOrder: order) == AnyIPAddress(text))
                #expect(AnyIPNetwork(text + "/24", policy: .compatible, parseOrder: order) == AnyIPNetwork(text + "/24"))
            }
            for text in ["192.0.2.1/24", "2001:db8::1/64"] {
                let address = try #require(AnyIPAddress(text, policy: .strict, parseOrder: order))
                let network = try #require(AnyIPNetwork(text, policy: .strict, parseOrder: order))
                #expect(address == AnyIPAddress(text))
                #expect(network == AnyIPNetwork(text))
            }
            for suffix in ["+0", "-0", "00", "024"] {
                for policy in [IPAddressParsingPolicy.compatible, .strict] {
                    #expect(AnyIPAddress("192.0.2.1/" + suffix, policy: policy, parseOrder: order) == nil)
                    #expect(AnyIPNetwork("2001:db8::/" + suffix, policy: policy, parseOrder: order) == nil)
                }
            }
        }
        #expect(AnyIPAddress("012.0.0.1", policy: .strict) == nil)
        #expect(AnyIPNetwork("012.0.0.1/24", policy: .strict) == nil)
    }

    @Test("Custom families retain compatible parsing and explicitly opt into strict parsing")
    func customFamilyDefaultAndWitness() throws {
        let oldStyle = try #require(IPAddress<CompatibleOnlyFamily>("router/24"))
        #expect(oldStyle.address == 0xC0000201)
        #expect(oldStyle.prefixLength.intValue == 24)
        #expect(genericAddress(CompatibleOnlyFamily.self, "router/24", policy: .compatible) == oldStyle)
        #expect(genericAddress(CompatibleOnlyFamily.self, "router/24", policy: .strict) == nil)
        #expect(genericNetwork(CompatibleOnlyFamily.self, "router/24", policy: .strict) == nil)
        #expect(IPAddress<CompatibleOnlyFamily>("router/+24") == nil)
        #expect(IPNetwork<CompatibleOnlyFamily>("router/024") == nil)
        #expect(IPNetwork<CompatibleOnlyFamily>("router") == nil)
        let data = try JSONEncoder().encode("router/24")
        #expect(try JSONDecoder().decode(IPAddress<CompatibleOnlyFamily>.self, from: data) == oldStyle)

        // CHANGE: Only the new protocol witness knows this custom family's strict parser.
        let optedIn = try #require(genericAddress(StrictCustomFamily.self, "router/24", policy: .strict))
        #expect(optedIn.address == oldStyle.address)
        #expect(optedIn.prefixLength.intValue == 24)
        #expect(genericNetwork(StrictCustomFamily.self, "router/24", policy: .strict) == optedIn.network)
        #expect(genericAddress(StrictCustomFamily.self, "012.0.0.1", policy: .strict) == nil)
        #expect(genericAddress(StrictCustomFamily.self, "012.0.0.1", policy: .compatible)?.address == 0x0C000001)
        #expect(genericAddress(StrictCustomFamily.self, "router/+24", policy: .strict) == nil)
    }

    @Test("Strict parsed values compose into blocks and endpoints without reparsing text")
    func typedComposition() throws {
        let address = try #require(IPv4Address("192.0.2.129/24", policy: .strict))
        let block = CIDRBlock(prefix: address.address, prefixLength: address.prefixLength)
        let endpoint = IPEndpoint(address: address, port: Port(53))
        #expect(block.prefix == 0xC0000200)
        #expect(block.prefixLength.intValue == 24)
        #expect(endpoint.address == address)
        #expect(endpoint.port.rawValue == 53)
        let ipv6 = try #require(IPv6Address("2001:db8::1/64", policy: .strict))
        let endpoint6 = IPEndpoint(address: ipv6, port: Port(443))
        #expect(endpoint6.address == ipv6)
        #expect(endpoint6.address.prefixLength.intValue == 64)
    }

    private func genericAddress<F: IPAddressFamily>(
        _: F.Type, _ text: String, policy: IPAddressParsingPolicy
    ) -> IPAddress<F>? {
        IPAddress<F>(text, policy: policy)
    }

    private func genericNetwork<F: IPAddressFamily>(
        _: F.Type, _ text: String, policy: IPAddressParsingPolicy
    ) -> IPNetwork<F>? {
        IPNetwork<F>(text, policy: policy)
    }
}

private enum CompatibleOnlyFamily: IPAddressFamily {
    typealias Storage = UInt32
    static let ianaValue: Int32 = 1
    static let bitWidth = 32
    static let familyName = "CompatibleOnlyFamily"

    static func parseAddress(_ text: String) -> UInt32? {
        text == "router" ? 0xC0000201 : V4.parseAddress(text)
    }

    static func formatAddress(_ address: UInt32) -> String {
        V4.formatAddress(address)
    }
}

private enum StrictCustomFamily: IPAddressFamily {
    typealias Storage = UInt32
    static let ianaValue: Int32 = 1
    static let bitWidth = 32
    static let familyName = "StrictCustomFamily"

    static func parseAddress(_ text: String) -> UInt32? {
        CompatibleOnlyFamily.parseAddress(text)
    }

    static func formatAddress(_ address: UInt32) -> String {
        V4.formatAddress(address)
    }

    static func parseCIDR(
        _ text: String, requiresPrefix: Bool, policy: IPAddressParsingPolicy
    ) -> (address: UInt32, prefixLength: UInt8)? {
        let expanded = text == "router" || text.hasPrefix("router/")
            ? "192.0.2.1" + text.dropFirst("router".count)
            : text
        return V4.parseCIDR(expanded, requiresPrefix: requiresPrefix, policy: policy)
    }
}
