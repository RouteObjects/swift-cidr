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

@Suite("IP Address Identity Tests")
struct IPAddressIdentityTests {
    @Test("IPv4 equality includes both address bits and prefix context")
    func ipv4Identity() throws {
        let address = try #require(IPv4Address("192.0.2.1/24"))
        let same = try #require(IPv4Address("192.0.2.1/24"))
        let differentPrefix = try #require(IPv4Address("192.0.2.1/32"))
        let differentBits = try #require(IPv4Address("192.0.2.2/24"))

        #expect(address == same)
        #expect(address != differentPrefix)
        #expect(differentPrefix != address)
        #expect(address != differentBits)
        #expect(address < differentPrefix)
        #expect(!(differentPrefix < address))
        #expect(areEqual(address, same))
        #expect(!areEqual(address, differentPrefix))
        #expect(!areEqual(address, differentBits))
    }

    @Test("IPv6 equality includes both address bits and prefix context")
    func ipv6Identity() throws {
        let address = try #require(IPv6Address("2001:db8::1/64"))
        let same = try #require(IPv6Address("2001:db8::1/64"))
        let differentPrefix = try #require(IPv6Address("2001:db8::1/128"))
        let differentBits = try #require(IPv6Address("2001:db8::2/64"))

        #expect(address == same)
        #expect(address != differentPrefix)
        #expect(differentPrefix != address)
        #expect(address != differentBits)
        #expect(address < differentPrefix)
        #expect(!(differentPrefix < address))
        #expect(areEqual(address, same))
        #expect(!areEqual(address, differentPrefix))
        #expect(!areEqual(address, differentBits))
    }

    @Test("IPv4 collections and wrappers preserve prefix identity")
    func ipv4CollectionsAndWrappers() throws {
        let address = try #require(IPv4Address("192.0.2.1/24"))
        let same = try #require(IPv4Address("192.0.2.1/24"))
        let differentPrefix = try #require(IPv4Address("192.0.2.1/32"))

        verifyCollectionIdentity(address, same, differentPrefix)
        verifyCollectionIdentity(AnyIPAddress(address), AnyIPAddress(same), AnyIPAddress(differentPrefix))
        verifyCollectionIdentity(
            IPEndpoint(address: address, port: Port(53)),
            IPEndpoint(address: same, port: Port(53)),
            IPEndpoint(address: differentPrefix, port: Port(53))
        )
    }

    @Test("IPv6 collections and wrappers preserve prefix identity")
    func ipv6CollectionsAndWrappers() throws {
        let address = try #require(IPv6Address("2001:db8::1/64"))
        let same = try #require(IPv6Address("2001:db8::1/64"))
        let differentPrefix = try #require(IPv6Address("2001:db8::1/128"))

        verifyCollectionIdentity(address, same, differentPrefix)
        verifyCollectionIdentity(AnyIPAddress(address), AnyIPAddress(same), AnyIPAddress(differentPrefix))
        verifyCollectionIdentity(
            IPEndpoint(address: address, port: Port(443)),
            IPEndpoint(address: same, port: Port(443)),
            IPEndpoint(address: differentPrefix, port: Port(443))
        )
    }

    @Test("IPv6 equality works across the full address space without a signed distance")
    func ipv6FullSpanEquality() {
        let lower = IPv6Address(address: 0)
        let upper = IPv6Address(address: .max)

        #expect(lower != upper)
        #expect(upper != lower)
        #expect(!areEqual(lower, upper))
        #expect(!areEqual(upper, lower))
        #expect(AnyIPAddress(lower) != AnyIPAddress(upper))
        #expect(IPEndpoint(address: lower, port: Port(53)) != IPEndpoint(address: upper, port: Port(53)))
    }

    private func areEqual<Value: Equatable>(_ lhs: Value, _ rhs: Value) -> Bool {
        lhs == rhs
    }

    private func verifyCollectionIdentity<Value: Hashable>(_ value: Value, _ same: Value, _ different: Value) {
        #expect(value == same)
        #expect(value != different)
        #expect(value.hashValue == same.hashValue)

        var values: Set<Value> = [value, same, different]
        #expect(values.count == 2)
        #expect(values.contains(same))
        #expect(values.contains(different))
        #expect(values.remove(same) == value)
        #expect(values.count == 1)
        #expect(!values.contains(value))
        #expect(values.contains(different))

        var labels = [value: "original", different: "different prefix"]
        labels[same] = "same identity"
        #expect(labels.count == 2)
        #expect(labels[value] == "same identity")
        #expect(labels[different] == "different prefix")
        #expect(labels.removeValue(forKey: same) == "same identity")
        #expect(labels.count == 1)
        #expect(labels[value] == nil)
        #expect(labels[different] == "different prefix")
    }
}
