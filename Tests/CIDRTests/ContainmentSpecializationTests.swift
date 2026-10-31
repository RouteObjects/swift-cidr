//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
// Copyright (c) 2026 Craig A. Munro
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CIDR
import Testing

@Suite("Containment specialization semantics")
struct ContainmentSpecializationTests {
    @Test func ipv4() throws {
        try check(V4.self, eraseNetwork: AnyIPNetwork.init, eraseAddress: AnyIPAddress.init)
    }

    @Test func ipv6() throws {
        try check(V6.self, eraseNetwork: AnyIPNetwork.init, eraseAddress: AnyIPAddress.init)
    }

    @Test func mixedFamiliesNeverMatch() {
        let v4 = IPv4Network(prefix: 0, prefixLength: .zero)
        let v6 = IPv6Network(prefix: 0, prefixLength: .zero)
        #expect(!AnyIPNetwork(v4).contains(address: AnyIPAddress(IPv6Address(address: 0))))
        #expect(!AnyIPNetwork(v6).contains(address: AnyIPAddress(IPv4Address(address: 0))))
    }

    private func check<F: IPAddressFamily>(
        _ family: F.Type,
        eraseNetwork: (IPNetwork<F>) -> AnyIPNetwork,
        eraseAddress: (IPAddress<F>) -> AnyIPAddress
    ) throws {
        let width = F.Storage.bitWidth
        let seeds: [F.Storage] = [0, .max, .max / 3]
        for length in 0...width {
            let prefixLength = try #require(PrefixLength<F>(length))
            for seed in seeds {
                let network = IPNetwork<F>(prefix: seed, prefixLength: prefixLength)
                let erased = eraseNetwork(network)
                // CHANGE: Use shifted high bits as an independent oracle, not CIDR.mask/contains.
                let canonical = length == 0 ? 0 : (seed >> (width - length)) << (width - length)
                let hostBits = length == 0 ? F.Storage.max : F.Storage.max >> length
                #expect(network.prefix == canonical)
                let last = canonical | hostBits
                var addresses: [F.Storage] = [0, .max, seed, canonical, last]
                if canonical > 0 { addresses.append(canonical - 1) }
                if last < .max { addresses.append(last + 1) }
                for context in 0...width {
                    let contextLength = try #require(PrefixLength<F>(context))
                    for bits in addresses {
                        let address = IPAddress<F>(address: bits, prefixLength: contextLength)
                        let sameHighBits = length == 0 || bits >> (width - length) == seed >> (width - length)
                        let expected = context >= length && sameHighBits
                        let concreteResult = network.contains(address: address)
                        let erasedResult = erased.contains(address: eraseAddress(address))
                        #expect(concreteResult == expected)
                        #expect(erasedResult == expected)
                    }
                }
            }
        }
    }
}
