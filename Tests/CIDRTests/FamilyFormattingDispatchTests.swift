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
import CIDR

/// Formatting must be identical whether reached directly, through a protocol witness, or generically.
@Suite("Family Formatting Dispatch Tests")
struct FamilyFormattingDispatchTests {
    private func genericDescription<C: CIDRForm>(_ value: C) -> String { value.description }
    private func existentialDescription(_ value: any CustomStringConvertible) -> String { value.description }
    private func existentialFormatted(_ value: any CIDRForm) -> String { value.formatted(.cidrNotation) }

    private func genericParse<Value: LosslessStringConvertible>(_ type: Value.Type, _ text: String) -> Value? {
        Value(text)
    }

    private func assertEveryPath<C: CIDRForm>(_ value: C, _ expected: String) {
        #expect(value.description == expected)
        #expect("\(value)" == expected)
        #expect(String(describing: value) == expected)
        #expect(genericDescription(value) == expected)
        #expect(existentialDescription(value) == expected)
        #expect(value.formatted(.cidrNotation) == expected)
        #expect(existentialFormatted(value) == expected)
        #expect(C.Family.formatCIDR(value.storage, prefixLength: value.prefixLength) == expected)
    }

    private func assertCodablePaths<Value: CIDRForm & Codable & Equatable>(
        _ value: Value,
        expected: String,
        json: String
    ) throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let encoded = try encoder.encode(value)
        // CHANGE: Literal expectations and independent JSON fixtures catch matching encode/decode errors.
        #expect(try decoder.decode(String.self, from: encoded) == expected)
        #expect(try decoder.decode(Value.self, from: Data(json.utf8)) == value)
        #expect(try decoder.decode(Value.self, from: encoded) == value)
    }

    private func assertInvalidJSON<Value: Decodable>(_ type: Value.Type, fixtures: [String]) {
        for fixture in fixtures {
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(Value.self, from: Data(fixture.utf8))
            }
        }
    }

    @Test("IPv4 conformers agree on every formatting path")
    func ipv4Paths() throws {
        assertEveryPath(try #require(IPv4Address("192.0.2.77/24")), "192.0.2.77/24")
        assertEveryPath(try #require(IPv4Network("192.0.2.77/24")), "192.0.2.0/24")
        assertEveryPath(try #require(CIDRBlock<V4>("192.0.2.77/24")), "192.0.2.0/24")
        assertEveryPath(try #require(IPv4MulticastGroupRange("239.1.2.0/24")), "239.1.2.0/24")
        assertEveryPath(try #require(IPv4Network("0.0.0.0/0")), "0.0.0.0/0")
        assertEveryPath(try #require(IPv4Address("255.255.255.255")), "255.255.255.255/32")
    }

    @Test("IPv6 conformers agree on every formatting path")
    func ipv6Paths() throws {
        assertEveryPath(try #require(IPv6Address("2001:db8::1/64")), "2001:db8::1/64")
        assertEveryPath(try #require(IPv6Network("2001:db8:abcd::1234/48")), "2001:db8:abcd::/48")
        assertEveryPath(try #require(CIDRBlock<V6>("2001:db8:abcd::1234/48")), "2001:db8:abcd::/48")
        assertEveryPath(try #require(IPv6MulticastGroupRange("ff02::/16")), "ff02::/16")
        assertEveryPath(try #require(IPv6Network("::/0")), "::/0")
        assertEveryPath(
            IPv6Address(address: .max),
            "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"
        )
    }

    @Test("Every IPv4 CIDR form encodes and decodes canonical JSON strings")
    func ipv4CodablePaths() throws {
        try assertCodablePaths(
            #require(IPv4Address("192.0.2.77/24")),
            expected: "192.0.2.77/24", json: #""192.0.2.77/24""#
        )
        try assertCodablePaths(
            #require(IPv4Network("192.0.2.77/24")),
            expected: "192.0.2.0/24", json: #""192.0.2.0/24""#
        )
        try assertCodablePaths(
            #require(CIDRBlock<V4>("192.0.2.77/24")),
            expected: "192.0.2.0/24", json: #""192.0.2.0/24""#
        )
        try assertCodablePaths(
            #require(IPv4MulticastGroupRange("239.1.2.0/24")),
            expected: "239.1.2.0/24", json: #""239.1.2.0/24""#
        )
    }

    @Test("Every IPv6 CIDR form encodes and decodes canonical JSON strings")
    func ipv6CodablePaths() throws {
        try assertCodablePaths(
            #require(IPv6Address("2001:db8::1/64")),
            expected: "2001:db8::1/64", json: #""2001:db8::1/64""#
        )
        try assertCodablePaths(
            #require(IPv6Network("2001:db8:abcd::1234/48")),
            expected: "2001:db8:abcd::/48", json: #""2001:db8:abcd::/48""#
        )
        try assertCodablePaths(
            #require(CIDRBlock<V6>("2001:db8:abcd::1234/48")),
            expected: "2001:db8:abcd::/48", json: #""2001:db8:abcd::/48""#
        )
        try assertCodablePaths(
            #require(IPv6MulticastGroupRange("ff02::/16")),
            expected: "ff02::/16", json: #""ff02::/16""#
        )
    }

    @Test("CIDR block and multicast JSON decoding preserve validation")
    func codableRejectsInvalidBlocksAndMulticastRanges() {
        assertInvalidJSON(CIDRBlock<V4>.self, fixtures: [
            #""not-an-address""#, #""192.0.2.0/33""#, "123",
        ])
        assertInvalidJSON(CIDRBlock<V6>.self, fixtures: [
            #""not-an-address""#, #""2001:db8::/129""#, "123",
        ])
        assertInvalidJSON(IPv4MulticastGroupRange.self, fixtures: [
            #""not-an-address""#, #""239.1.2.0/33""#,
            #""192.0.2.0/24""#, #""239.1.2.1/24""#,
        ])
        assertInvalidJSON(IPv6MulticastGroupRange.self, fixtures: [
            #""not-an-address""#, #""ff02::/129""#,
            #""2001:db8::/32""#, #""ff02::1/16""#,
        ])
    }

    @Test("Custom family formatter and parser witnesses reach formatting and Codable")
    func customFamilyWitnesses() throws {
        let length = try #require(PrefixLength<DispatchMarkerFamily>(24))
        let address = IPAddress<DispatchMarkerFamily>(address: 0xC000_0201, prefixLength: length)
        let network = IPNetwork<DispatchMarkerFamily>(prefix: 0xC000_0201, prefixLength: length)
        let block = CIDRBlock<DispatchMarkerFamily>(prefix: 0xC000_0201, prefixLength: length)

        // CHANGE: A marker absent from formatAddress distinguishes family dispatch from generic fallback.
        assertEveryPath(address, "marker-3221225985/24")
        assertEveryPath(network, "marker-3221225984/24")
        assertEveryPath(block, "marker-3221225984/24")
        #expect(address.addressLiteral == "3221225985")
        #expect(DispatchMarkerFamily.parseAddress("marker-3221225985") == nil)
        #expect(genericParse(IPAddress<DispatchMarkerFamily>.self, "marker-3221225985/24") == address)
        #expect(genericParse(IPNetwork<DispatchMarkerFamily>.self, "marker-3221225985/24") == network)
        #expect(genericParse(CIDRBlock<DispatchMarkerFamily>.self, "marker-3221225985/24") == block)
        let parser: any LosslessStringConvertible.Type = IPAddress<DispatchMarkerFamily>.self
        #expect(parser.init("marker-3221225985/24")?.description == "marker-3221225985/24")

        try assertCodablePaths(address, expected: "marker-3221225985/24", json: #""marker-3221225985/24""#)
        try assertCodablePaths(network, expected: "marker-3221225984/24", json: #""marker-3221225984/24""#)
        try assertCodablePaths(block, expected: "marker-3221225984/24", json: #""marker-3221225984/24""#)
    }
}

private enum DispatchMarkerFamily: IPAddressFamily {
    typealias Storage = UInt32
    static let ianaValue: UInt16 = 65_535
    static let familyName = "Dispatch Marker Test"

    static func formatAddress(_ address: UInt32) -> String { String(address) }
    static func parseAddress(_ text: String) -> UInt32? { UInt32(text) }

    static func formatCIDR(_ storage: UInt32, prefixLength: PrefixLength<Self>) -> String {
        "marker-\(storage)/\(prefixLength.rawValue)"
    }

    static func parseCIDR(
        _ text: String,
        requiresPrefix: Bool,
        policy: IPAddressParsingPolicy
    ) -> (address: UInt32, prefixLength: UInt8)? {
        guard policy == .compatible, text.hasPrefix("marker-") else { return nil }
        let fields = text.dropFirst(7).split(separator: "/", omittingEmptySubsequences: false)
        guard let addressText = fields.first, let address = UInt32(addressText) else { return nil }
        if fields.count == 1 {
            return requiresPrefix ? nil : (address, 32)
        }
        guard fields.count == 2,
              fields[1] == "0" || fields[1].first.map({ $0 >= "1" && $0 <= "9" }) == true,
              fields[1].utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
              let length = UInt8(fields[1]), length <= 32 else { return nil }
        return (address, length)
    }
}

@Suite("IPPrefix Subnet Sequence Tests")
struct IPPrefixSubnetsTests {
    @Test("subnets is a concrete lazy sequence")
    func concreteType() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let subnets: IPPrefixSubnets<IPv4Network> = network.subnets(prefixLength: 26)
        #expect(subnets.map(\.description) == [
            "192.0.2.0/26", "192.0.2.64/26", "192.0.2.128/26", "192.0.2.192/26",
        ])
    }

    @Test("Iteration is restartable and independent")
    func restartable() throws {
        let network = try #require(IPv6Network("2001:db8::/32"))
        let subnets = network.subnets(prefixLength: 34)
        var first = subnets.makeIterator()
        _ = first.next()
        #expect(Array(subnets).count == 4)
        #expect(first.next()?.description == "2001:db8:4000::/34")
    }

    @Test("Copies of a partially advanced subnet iterator advance independently")
    func copiedIteratorIsIndependent() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        var first = network.subnets(prefixLength: 26).makeIterator()
        #expect(first.next()?.description == "192.0.2.0/26")
        // CHANGE: Copy the cursor itself, rather than creating another iterator from the sequence.
        var copy = first
        #expect(first.next()?.description == "192.0.2.64/26")
        #expect(first.next()?.description == "192.0.2.128/26")
        #expect(copy.next()?.description == "192.0.2.64/26")
        #expect(first.next()?.description == "192.0.2.192/26")
        #expect(first.next() == nil)
        #expect(copy.next()?.description == "192.0.2.128/26")
    }

    @Test("Shorter, invalid, and negative lengths yield empty sequences")
    func emptyCases() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        #expect(Array(network.subnets(prefixLength: 23)).isEmpty)
        #expect(Array(network.subnets(prefixLength: 33)).isEmpty)
        #expect(Array(network.subnets(prefixLength: -1)).isEmpty)
        #expect(Array(network.subnets(prefixLength: PrefixLength<V4>(16)!)).isEmpty)
    }

    @Test("An invalid integer length on a /0 parent is empty, not the parent")
    func invalidLengthOnDefaultRoute() throws {
        let v4 = try #require(IPv4Network("0.0.0.0/0"))
        let v6 = try #require(IPv6Network("::/0"))
        #expect(Array(v4.subnets(prefixLength: 99)).isEmpty)
        #expect(Array(v6.subnets(prefixLength: 129)).isEmpty)
        #expect(v6.subnets(prefixLength: 0).map(\.description) == ["::/0"])
        #expect(v6.subnets(prefixLength: 1).map(\.description) == ["::/1", "8000::/1"])
    }

    @Test("Same-length subnets yield the parent once")
    func sameLength() throws {
        let network = try #require(IPv4Network("198.51.100.0/24"))
        #expect(Array(network.subnets(prefixLength: 24)) == [network])
    }

    @Test("IPNetwork iterates with its concrete address iterator")
    func networkIteratorIsConcrete() throws {
        let network = try #require(IPv4Network("192.0.2.0/30"))
        var iterator: IPv4Network.Addresses.Iterator = network.makeIterator()
        #expect(iterator.next()?.description == "192.0.2.0/30")
        #expect(network.map(\.description) == [
            "192.0.2.0/30", "192.0.2.1/30", "192.0.2.2/30", "192.0.2.3/30",
        ])
    }
}
