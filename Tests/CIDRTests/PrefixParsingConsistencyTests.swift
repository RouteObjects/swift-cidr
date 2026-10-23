//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
// Copyright (c) 2026 Craig A. Munro
// Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CIDR
import struct CIDR.Port
import Foundation
import Testing

@Suite("Prefix Parsing Consistency Tests")
struct PrefixParsingConsistencyTests {
    @Test("Every valid standalone prefix has one accepted decimal spelling")
    func canonicalStandaloneLengths() throws {
        for value in 0...32 {
            let length = try #require(IPv4PrefixLength(String(value)))
            #expect(length.intValue == value)
            #expect(lossless(IPv4PrefixLength.self, String(value)) == length)
        }
        for value in 0...128 {
            let length = try #require(IPv6PrefixLength(String(value)))
            #expect(length.intValue == value)
            #expect(lossless(IPv6PrefixLength.self, String(value)) == length)
        }
    }

    @Test("Standalone prefix text rejects padding, signs, and non-ASCII digits")
    func noncanonicalStandaloneLengths() {
        for text in ["00", "000", "01", "024", "+0", "-0", "+24", "-1", " 24", "24 ", "２４", "", "999999999999999999999999999"] {
            #expect(IPv4PrefixLength(text) == nil, "IPv4: \(text)")
            #expect(IPv6PrefixLength(text) == nil, "IPv6: \(text)")
            #expect(lossless(IPv4PrefixLength.self, text) == nil, "IPv4 witness: \(text)")
            #expect(lossless(IPv6PrefixLength.self, text) == nil, "IPv6 witness: \(text)")
        }
        #expect(IPv4PrefixLength("33") == nil)
        #expect(IPv6PrefixLength("129") == nil)
    }

    @Test("Concrete and generic IPv4 composite parsers reject the same prefix spellings")
    func ipv4CompositeRejection() throws {
        for suffix in ["+0", "-0", "00", "000", "+24", "024", "33", "24/1", "", " 24", "２４"] {
            let text = "192.0.2.1/\(suffix)"
            #expect(IPv4Address(text) == nil, "\(text)")
            #expect(IPv4Network(text) == nil, "\(text)")
            try expectCompositeRejection(V4.self, text: text, endpointText: text + ":53")
        }
    }

    @Test("Concrete and generic IPv6 composite parsers reject the same prefix spellings")
    func ipv6CompositeRejection() throws {
        for suffix in ["+0", "-0", "00", "000", "+64", "064", "129", "64/1", "", " 64", "６４"] {
            let text = "2001:db8::1/\(suffix)"
            #expect(IPv6Address(text) == nil, "\(text)")
            #expect(IPv6Network(text) == nil, "\(text)")
            try expectCompositeRejection(V6.self, text: text, endpointText: "[\(text)]:53")
        }
    }

    @Test("Canonical composite text keeps address context and network normalization")
    func canonicalCompositeSemantics() throws {
        try expectCanonicalComposite(V4.self, text: "192.0.2.1/24", literal: "192.0.2.1", prefix: 24)
        try expectCanonicalComposite(V6.self, text: "2001:db8::1/64", literal: "2001:db8::1", prefix: 64)
        #expect(IPv4Address("192.0.2.1")?.prefixLength == .maximum)
        #expect(IPv6Address("2001:db8::1")?.prefixLength == .maximum)
        #expect(IPv4Network("192.0.2.1") == nil)
        #expect(IPv6Network("2001:db8::1") == nil)
        #expect(CIDRBlock<V4>("192.0.2.1")?.prefixLength == .maximum)
        #expect(CIDRBlock<V6>("2001:db8::1")?.prefixLength == .maximum)
        let parent = try #require(CIDRBlock<V4>("192.0.2.0/24"))
        #expect(IPv4Network("192.0.2.0/25", within: parent) != nil)
        #expect(IPv4Network("0.0.0.0/0", within: parent) == nil)
    }

    @Test("Multicast groups and ranges reject noncanonical prefix text through wrappers and Codable")
    func multicastPrefixRejection() throws {
        for text in ["239.1.2.3/+32", "239.1.2.3/032"] {
            #expect(IPv4MulticastGroup(text) == nil, "\(text)")
            #expect(AnyIPMulticastGroup(text) == nil, "\(text)")
            try expectDecodingRejection(IPv4MulticastGroup.self, text)
            try expectDecodingRejection(AnyIPMulticastGroup.self, text)
        }
        for text in ["ff02::1/+128", "ff02::1/0128"] {
            #expect(IPv6MulticastGroup(text) == nil, "\(text)")
            #expect(AnyIPMulticastGroup(text) == nil, "\(text)")
            try expectDecodingRejection(IPv6MulticastGroup.self, text)
            try expectDecodingRejection(AnyIPMulticastGroup.self, text)
        }
        for text in ["239.1.2.0/+24", "239.1.2.0/024"] {
            #expect(IPv4MulticastGroupRange(text) == nil, "\(text)")
            #expect(AnyIPMulticastGroupRange(text) == nil, "\(text)")
            try expectDecodingRejection(IPv4MulticastGroupRange.self, text)
            try expectDecodingRejection(AnyIPMulticastGroupRange.self, text)
        }
        for text in ["ff02::/+64", "ff02::/064"] {
            #expect(IPv6MulticastGroupRange(text) == nil, "\(text)")
            #expect(AnyIPMulticastGroupRange(text) == nil, "\(text)")
            try expectDecodingRejection(IPv6MulticastGroupRange.self, text)
            try expectDecodingRejection(AnyIPMulticastGroupRange.self, text)
        }
        #expect(IPv4MulticastGroup("239.1.2.3/32") != nil)
        #expect(IPv6MulticastGroup("ff02::1/128") != nil)
        #expect(IPv4MulticastGroupRange("239.1.2.0/24") != nil)
        #expect(IPv6MulticastGroupRange("ff02::/64") != nil)
    }

    @Test("Standalone prefix Codable keeps its numeric wire contract")
    func numericPrefixCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        #expect(try encoder.encode(IPv4PrefixLength.zero) == Data("0".utf8))
        #expect(try decoder.decode(IPv4PrefixLength.self, from: Data("24".utf8)).intValue == 24)
        #expect(try decoder.decode(IPv6PrefixLength.self, from: Data("128".utf8)) == .maximum)
        // CHANGE: Numeric decoders discard token spelling; string grammar does not alter this wire format.
        #expect(try decoder.decode(IPv4PrefixLength.self, from: Data("-0".utf8)) == .zero)
        try expectDecodingRejection(IPv4PrefixLength.self, "24")
    }

    private func lossless<T: LosslessStringConvertible>(_: T.Type, _ text: String) -> T? {
        T(text)
    }

    private func expectCompositeRejection<F: IPAddressFamily>(
        _: F.Type, text: String, endpointText: String
    ) throws {
        // CHANGE: A generic helper exercises the witness path that concrete-only tests missed.
        #expect(IPAddress<F>(text) == nil, "Generic address: \(text)")
        #expect(IPNetwork<F>(text) == nil, "Generic network: \(text)")
        #expect(lossless(IPAddress<F>.self, text) == nil, "Address witness: \(text)")
        #expect(lossless(IPNetwork<F>.self, text) == nil, "Network witness: \(text)")
        #expect(CIDRBlock<F>(text) == nil, "Block: \(text)")
        let parent = CIDRBlock<F>(prefix: 0, prefixLength: .zero)
        #expect(IPNetwork<F>(text, within: parent) == nil, "Within parent: \(text)")
        #expect(IPEndpoint<F>(endpointText) == nil, "Endpoint: \(endpointText)")
        for order in [AddressFamilyParseOrder.ipv4ThenIPv6, .ipv6ThenIPv4] {
            #expect(AnyIPAddress(text, parseOrder: order) == nil, "Any address: \(text)")
            #expect(AnyIPNetwork(text, parseOrder: order) == nil, "Any network: \(text)")
        }
        #expect(lossless(AnyIPAddress.self, text) == nil)
        #expect(lossless(AnyIPNetwork.self, text) == nil)
        try expectDecodingRejection(IPAddress<F>.self, text)
        try expectDecodingRejection(IPNetwork<F>.self, text)
        try expectDecodingRejection(CIDRBlock<F>.self, text)
        try expectDecodingRejection(AnyIPAddress.self, text)
        try expectDecodingRejection(AnyIPNetwork.self, text)
        let endpointJSON = try JSONEncoder().encode(EndpointWire(address: text, port: Port(53)))
        #expect(throws: DecodingError.self, "Endpoint Codable: \(text)") {
            try JSONDecoder().decode(IPEndpoint<F>.self, from: endpointJSON)
        }
    }

    private func expectCanonicalComposite<F: IPAddressFamily>(
        _: F.Type, text: String, literal: String, prefix: Int
    ) throws {
        let address = try #require(IPAddress<F>(text))
        #expect(address.addressLiteral == literal)
        #expect(address.prefixLength.intValue == prefix)
        #expect(lossless(IPAddress<F>.self, text) == address)
        #expect(IPNetwork<F>(text) == address.network)
        #expect(lossless(IPNetwork<F>.self, text) == address.network)
        let data = try JSONEncoder().encode(text)
        #expect(try JSONDecoder().decode(IPAddress<F>.self, from: data) == address)
        #expect(try JSONDecoder().decode(IPNetwork<F>.self, from: data) == address.network)
        #expect(CIDRBlock<F>(text)?.prefix == address.network.prefix)
    }

    private func expectDecodingRejection<T: Decodable>(_: T.Type, _ text: String) throws {
        let data = try JSONEncoder().encode(text)
        #expect(throws: DecodingError.self, "\(T.self): \(text)") {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    private struct EndpointWire: Encodable {
        let address: String
        let port: Port
    }
}
