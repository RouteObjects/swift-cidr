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

@Suite("Any IP Wrapper Tests")
struct AnyIPTests {
    @Test("AnyIPAddress parses IPv4 and IPv6 strings and round-trips canonical text")
    func anyIPAddressParsesAndRoundTrips() throws {
        let ipv4 = try #require(AnyIPAddress("192.0.2.1/24"))
        let ipv6 = try #require(AnyIPAddress("2001:db8::1/64"))

        #expect(ipv4.isIPv4)
        #expect(ipv4.ianaValue == 1)
        #expect(ipv4.familyName == "IPv4")
        #expect(ipv4.description == "192.0.2.1/24")
        #expect(AnyIPAddress(ipv4.description) == ipv4)

        #expect(ipv6.isIPv6)
        #expect(ipv6.ianaValue == 2)
        #expect(ipv6.familyName == "IPv6")
        #expect(ipv6.description == "2001:db8::1/64")
        #expect(AnyIPAddress(ipv6.description) == ipv6)
    }

    @Test("AnyIPAddress parse order changes first attempt only")
    func anyIPAddressParseOrderIsAHint() throws {
        let ipv6First = try #require(AnyIPAddress("2001:db8::1/64", parseOrder: .ipv6ThenIPv4))
        let ipv4Fallback = try #require(AnyIPAddress("192.0.2.1/24", parseOrder: .ipv6ThenIPv4))

        #expect(ipv6First.isIPv6)
        #expect(ipv6First.description == "2001:db8::1/64")
        #expect(ipv4Fallback.isIPv4)
        #expect(ipv4Fallback.description == "192.0.2.1/24")
    }

    @Test(
        "AnyIP wrappers reject malformed IPv6 literals in either parse order",
        arguments: [
            "00000::1",
            "1:2:3:4:5:6:7:8:",
            "1:2:3:4:5:6:7:8::",
            "1:2:3:4:5:6::192.0.2.1",
        ])
    func anyIPWrappersRejectMalformedIPv6(source: String) {
        // CHANGE: Family selection must not bypass the shared IPv6 grammar correction.
        for order in [AddressFamilyParseOrder.ipv4ThenIPv6, .ipv6ThenIPv4] {
            #expect(AnyIPAddress(source, parseOrder: order) == nil)
            #expect(AnyIPAddress("\(source)/128", parseOrder: order) == nil)
            #expect(AnyIPNetwork("\(source)/128", parseOrder: order) == nil)
        }
    }

    @Test(
        "AnyIP wrappers retain valid IPv6 boundary forms in either parse order",
        arguments: [
            "0000::1",
            "::1:2:3:4:5:6:7",
            "1:2:3:4:5:6:7::",
            "1:2:3:4:5::192.0.2.1",
            "::ffff:192.000.002.001",
        ])
    func anyIPWrappersRetainValidIPv6BoundaryForms(source: String) throws {
        for order in [AddressFamilyParseOrder.ipv4ThenIPv6, .ipv6ThenIPv4] {
            let address = try #require(AnyIPAddress(source, parseOrder: order))
            let network = try #require(AnyIPNetwork("\(source)/128", parseOrder: order))

            #expect(address.isIPv6)
            #expect(address.prefixLength.intValue == 128)
            #expect(network.isIPv6)
            #expect(network.first == address)
            #expect(AnyIPAddress(address.description, parseOrder: order) == address)
        }
    }

    @Test("AnyIPAddress exposes wrapped network and formatting behavior")
    func anyIPAddressDelegatesNetworkAndFormatting() throws {
        let mapped = try #require(AnyIPAddress("::ffff:192.0.2.1/96"))
        let ipv4 = try #require(AnyIPAddress("192.0.2.129/24"))
        let mappedV6 = try #require(mapped.v6)

        #expect(mapped.formatted(.addressOnly) == mapped.addressLiteral)
        #expect(mappedV6.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
        #expect(mapped.prefixLength.intValue == 96)
        #expect(mapped.network.description == "::ffff:0:0/96")

        #expect(ipv4.network.description == "192.0.2.0/24")
        #expect(ipv4.prefixLength.intValue == 24)
    }

    @Test("AnyIPNetwork round-trips canonical CIDR text and preserves family in traversal")
    func anyIPNetworkRoundTripsAndTraverses() throws {
        let ipv4 = try #require(AnyIPNetwork("192.0.2.0/24"))
        let ipv6 = try #require(AnyIPNetwork("2001:db8::/126"))

        #expect(ipv4.description == "192.0.2.0/24")
        #expect(AnyIPNetwork(ipv4.description) == ipv4)
        #expect(ipv4.first.description == "192.0.2.0/32")
        #expect(ipv4.last.description == "192.0.2.255/32")
        #expect(ipv4.nextNetwork?.description == "192.0.3.0/24")

        #expect(ipv6.isIPv6)
        #expect(ipv6.first.description == "2001:db8::/128")
        #expect(ipv6.last.description == "2001:db8::3/128")
    }

    @Test(
        "AnyIPNetwork hashing preserves equality and prefix identity",
        arguments: [
            ("192.0.2.0/24", "192.0.2.0/25"),
            ("2001:db8::/64", "2001:db8::/65"),
        ])
    func anyIPNetworkHashingPreservesIdentity(source: String, otherPrefix: String) throws {
        let value = try #require(AnyIPNetwork(source))
        let same = try #require(AnyIPNetwork(source))
        let different = try #require(AnyIPNetwork(otherPrefix))

        func genericHash<T: Hashable>(_ value: T) -> Int { value.hashValue }

        // CHANGE: Direct and generic hashValue access exposed a native x86-64 compiler crash.
        #expect(value == same)
        #expect(value.hashValue == same.hashValue)
        // Keep enum arguments outside #expect's generated closure, which has the same alignment defect.
        let valueHash = genericHash(value)
        let sameHash = genericHash(same)
        #expect(valueHash == sameHash)
        #expect(value != different)
        #expect(Set([value, same, different]).count == 2)

        let dictionary = [value: "original", different: "other prefix"]
        #expect(dictionary[same] == "original")
        #expect(dictionary[different] == "other prefix")
    }

    @Test("AnyIPNetwork parse order changes first attempt only")
    func anyIPNetworkParseOrderIsAHint() throws {
        let ipv6First = try #require(AnyIPNetwork("2001:db8::/64", parseOrder: .ipv6ThenIPv4))
        let ipv4Fallback = try #require(AnyIPNetwork("192.0.2.0/24", parseOrder: .ipv6ThenIPv4))

        #expect(ipv6First.isIPv6)
        #expect(ipv6First.description == "2001:db8::/64")
        #expect(ipv4Fallback.isIPv4)
        #expect(ipv4Fallback.description == "192.0.2.0/24")
    }

    @Test("AnyIPNetwork containment is family-aware")
    func anyIPNetworkContainmentIsFamilyAware() throws {
        let ipv4Network = try #require(AnyIPNetwork("192.0.2.0/24"))
        let ipv4Address = try #require(AnyIPAddress("192.0.2.10/32"))
        let ipv4Subnet = try #require(AnyIPNetwork("192.0.2.0/25"))
        let ipv6Address = try #require(AnyIPAddress("2001:db8::1/128"))
        let ipv6Network = try #require(AnyIPNetwork("2001:db8::/64"))

        #expect(ipv4Network.contains(ipv4Address))
        #expect(ipv4Network.contains(ipv4Subnet))
        #expect(ipv4Network.contains(ipv6Address) == false)
        #expect(ipv4Network.contains(ipv6Network) == false)
    }

    @Test("AnyPrefixLength exposes family metadata and typed projections")
    func anyPrefixLengthExposesMetadataAndProjections() throws {
        let ipv4 = AnyPrefixLength(try #require(IPv4PrefixLength(24)))
        let ipv6 = AnyPrefixLength(try #require(IPv6PrefixLength(64)))

        #expect(ipv4.isIPv4)
        #expect(ipv4.ianaValue == 1)
        #expect(ipv4.familyName == "IPv4")
        #expect(ipv4.rawValue == 24)
        #expect(ipv4.intValue == 24)
        #expect(ipv4.description == "24")
        #expect(ipv4.v4?.intValue == 24)
        #expect(ipv4.v6 == nil)

        #expect(ipv6.isIPv6)
        #expect(ipv6.ianaValue == 2)
        #expect(ipv6.familyName == "IPv6")
        #expect(ipv6.rawValue == 64)
        #expect(ipv6.intValue == 64)
        #expect(ipv6.description == "64")
        #expect(ipv6.v6?.intValue == 64)
        #expect(ipv6.v4 == nil)
    }

    @Test("AnyIPMulticastGroup parses IPv4 and IPv6 groups and round-trips canonical text")
    func anyIPMulticastGroupParsesAndRoundTrips() throws {
        let ipv4 = try #require(AnyIPMulticastGroup("239.1.2.3"))
        let ipv6 = try #require(AnyIPMulticastGroup("ff02::1"))

        #expect(ipv4.isIPv4)
        #expect(ipv4.ianaValue == 1)
        #expect(ipv4.familyName == "IPv4")
        #expect(ipv4.addressLiteral == "239.1.2.3")
        #expect(ipv4.description == "239.1.2.3")
        #expect(ipv4.v4?.description == "239.1.2.3")
        #expect(ipv4.v6 == nil)
        #expect(AnyIPMulticastGroup(ipv4.description) == ipv4)

        #expect(ipv6.isIPv6)
        #expect(ipv6.ianaValue == 2)
        #expect(ipv6.familyName == "IPv6")
        #expect(ipv6.description == "ff02::1")
        #expect(ipv6.v6?.description == "ff02::1")
        #expect(ipv6.v4 == nil)
        #expect(AnyIPMulticastGroup(ipv6.description) == ipv6)

        #expect(AnyIPMulticastGroup("192.0.2.1") == nil)
        #expect(AnyIPMulticastGroup("2001:db8::1") == nil)
        #expect(AnyIPMulticastGroup("239.1.2.3/24") == nil)
    }

    @Test("AnyIPMulticastGroupRange preserves multicast range semantics")
    func anyIPMulticastGroupRangePreservesSemantics() throws {
        let allIPv4 = try #require(AnyIPMulticastGroupRange("224.0.0.0/4"))
        let administrativelyScoped = try #require(AnyIPMulticastGroupRange("239.0.0.0/8"))
        let sourceSpecific = try #require(AnyIPMulticastGroupRange("232.0.0.0/8"))
        let group = try #require(AnyIPMulticastGroup("239.1.2.3"))
        let ipv6Range = try #require(AnyIPMulticastGroupRange("ff02::/16"))
        let ipv6Group = try #require(AnyIPMulticastGroup("ff02::1"))

        #expect(allIPv4.isIPv4)
        #expect(allIPv4.description == "224.0.0.0/4")
        #expect(allIPv4.prefixLength.intValue == 4)
        #expect(allIPv4.firstGroup.description == "224.0.0.0")
        #expect(allIPv4.lastGroup.description == "239.255.255.255")
        #expect(allIPv4.rangeSizeIfRepresentable == UInt128(1) << 28)
        #expect(allIPv4.contains(administrativelyScoped))
        #expect(allIPv4.overlaps(sourceSpecific))
        #expect(administrativelyScoped.isWithin(allIPv4))
        #expect(administrativelyScoped.contains(group))
        #expect(!administrativelyScoped.contains(ipv6Group))
        #expect(administrativelyScoped.formatted(.cidrNotation) == "239.0.0.0/8")
        #expect(administrativelyScoped.formatted(.addressOnly) == "239.0.0.0")
        #expect(administrativelyScoped.v4?.description == "239.0.0.0/8")
        #expect(administrativelyScoped.v6 == nil)

        #expect(ipv6Range.isIPv6)
        #expect(ipv6Range.contains(ipv6Group))
        #expect(!ipv6Range.contains(group))
        #expect(ipv6Range.v6?.description == "ff02::/16")
        #expect(ipv6Range.v4 == nil)

        #expect(AnyIPMulticastGroupRange("192.0.2.0/24") == nil)
        #expect(AnyIPMulticastGroupRange("2001:db8::/32") == nil)
        #expect(AnyIPMulticastGroupRange("239.1.2.1/24") == nil)
    }

    @Test("AnyIPMulticast wrappers encode and decode canonical string values")
    func anyIPMulticastCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let group = try #require(AnyIPMulticastGroup("239.1.2.3"))
        let range = try #require(AnyIPMulticastGroupRange("239.1.2.0/24"))

        let encodedGroup = try encoder.encode(group)
        let encodedRange = try encoder.encode(range)

        #expect(String(decoding: encodedGroup, as: UTF8.self) == #""239.1.2.3""#)
        #expect(try decoder.decode(String.self, from: encodedRange) == "239.1.2.0/24")
        #expect(try decoder.decode(AnyIPMulticastGroup.self, from: encodedGroup) == group)
        #expect(try decoder.decode(AnyIPMulticastGroupRange.self, from: encodedRange) == range)
    }

    @Test("Generic AnyIP wrappers do not infer multicast semantics")
    func genericAnyIPWrappersKeepExistingSemantics() throws {
        let address = try #require(AnyIPAddress("239.1.2.3"))
        let network = try #require(AnyIPNetwork("224.0.0.0/4"))
        let multicastRange = try #require(AnyIPMulticastGroupRange("224.0.0.0/4"))

        #expect(address.description == "239.1.2.3/32")
        #expect(address.v4?.description == "239.1.2.3/32")
        #expect(network.description == "224.0.0.0/4")
        #expect(network.v4?.description == "224.0.0.0/4")
        #expect(multicastRange.description == "224.0.0.0/4")
    }
}
