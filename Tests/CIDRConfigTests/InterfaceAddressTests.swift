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
@testable import CIDRConfig

@Suite("Interface Address Tests")
struct InterfaceAddressTests {
    @Test("Explicit IPv4 interface-address initialization keeps address and prefix")
    func explicitIPv4Initialization() throws {
        let prefix = try #require(IPv4PrefixLength(24))
        let interfaceAddress = InterfaceAddress<V4>(address: 0xC0000201, prefixLength: prefix)

        #expect(interfaceAddress.address == 0xC0000201)
        #expect(interfaceAddress.storage == interfaceAddress.address)
        #expect(interfaceAddress.prefixLength == prefix)
        #expect(interfaceAddress.host.description == "192.0.2.1/24")
        #expect(interfaceAddress.network.description == "192.0.2.0/24")
        #expect(interfaceAddress.network.prefix == 0xC0000200)
        #expect(interfaceAddress.network.storage == interfaceAddress.network.prefix)
    }

    @Test("Host-based initialization preserves CIDR context")
    func hostBasedInitializationPreservesCIDRContext() throws {
        let host = try #require(IPAddress<V6>("2001:db8::1/64"))
        let interfaceAddress = InterfaceAddress<V6>(host: host)

        #expect(interfaceAddress.address == host.address)
        #expect(interfaceAddress.storage == interfaceAddress.address)
        #expect(interfaceAddress.prefixLength == host.prefixLength)
        #expect(interfaceAddress.host == host)
        #expect(interfaceAddress.network.description == "2001:db8:0:0:0:0:0:0/64")
    }

    @Test("InterfaceAddress equality and hashing follow address plus prefix")
    func equalityAndHashing() throws {
        let lhs = InterfaceAddress<V4>(
            address: 0xC0000201,
            prefixLength: try #require(IPv4PrefixLength(24))
        )
        let rhs = InterfaceAddress<V4>(
            address: 0xC0000201,
            prefixLength: try #require(IPv4PrefixLength(24))
        )
        let different = InterfaceAddress<V4>(
            address: 0xC0000201,
            prefixLength: try #require(IPv4PrefixLength(25))
        )

        #expect(lhs == rhs)
        #expect(lhs != different)
        #expect(Set([lhs, rhs, different]).count == 2)
    }

    @Test("CIDR covers prefixed host values while IPPrefix remains aligned-only")
    func cidrAndIPPrefixSeparateStructuralLevels() throws {
        func cidrText<T: CIDR>(_ value: T) -> String { value.description }
        func prefixText<T: IPPrefix>(_ value: T) -> String { value.description }

        let host = try #require(IPv4Address("192.0.2.1/24"))
        let interfaceAddress = InterfaceAddress<V4>(host: host)
        let network = host.network

        #expect(cidrText(host) == "192.0.2.1/24")
        #expect(cidrText(interfaceAddress) == "192.0.2.1/24")
        #expect(prefixText(network) == "192.0.2.0/24")
    }
}
