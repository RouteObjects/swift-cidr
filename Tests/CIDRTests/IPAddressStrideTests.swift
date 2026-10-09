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

@Suite("IP Address Stride Tests")
struct IPAddressStrideTests {
    @Test("IPv4 stride helpers preserve the current prefix context")
    func ipv4StrideHelpers() throws {
        let prefix = try #require(PrefixLength<V4>(24))
        let start = IPAddress<V4>(address: 0xC0000201, prefixLength: prefix)
        let end = IPAddress<V4>(address: 0xC000020A, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(9))
        #expect(start.distance(to: end) == Int128(9))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(9)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
        #expect(start.advanced(by: Int128(9)) == end)
    }

    @Test("IPv6 stride helpers work for low-space deltas")
    func ipv6LowSpaceStrideHelpers() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: UInt128(1), prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128(5), prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(4))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(4)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
    }

    @Test("IPv6 stride helpers work near UInt128.max for small deltas")
    func ipv6HighSpaceStrideHelpers() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: UInt128.max - 3, prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(3))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(3)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
    }

    @Test("Stride helpers return nil when the move exceeds Int128 or the family range")
    func boundedStrideFailures() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: 0, prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == nil)
        #expect(end.distanceIfRepresentable(to: start) == nil)
        #expect(start.advancedIfRepresentable(by: Int128(-1)) == nil)
        #expect(end.advancedIfRepresentable(by: Int128(1)) == nil)
    }

    @Test("IPv6 network iteration uses raw storage rather than generic stride")
    func ipv6NetworkSequenceNearTopOfSpace() throws {
        let prefix = try #require(PrefixLength<V6>(127))
        let host = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)
        let network = IPNetwork<V6>(host: host)

        let addresses = Array(network)

        #expect(addresses.map(\.address) == [UInt128.max - 1, UInt128.max])
        #expect(addresses[0].prefixLength.intValue == 128)
        #expect(addresses[1].prefixLength.intValue == 128)
    }

    @Test("IPv4 strides satisfy both inverse laws with matching prefix context")
    func ipv4StrideInverseLaws() throws {
        let prefix = try #require(PrefixLength<V4>(24))
        let cases: [(UInt32, UInt32, Int128)] = [
            (0xC0000201, 0xC000020A, 9),
            (0xC000020A, 0xC0000201, -9),
            (0xC0000201, 0xC0000201, 0),
        ]

        for (start, end, distance) in cases {
            try expectStrideInverseLaws(
                from: IPv4Address(address: start, prefixLength: prefix),
                to: IPv4Address(address: end, prefixLength: prefix),
                distance: distance
            )
        }
    }

    @Test("IPv6 strides satisfy both inverse laws in low and high address space")
    func ipv6StrideInverseLaws() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let cases: [(UInt128, UInt128, Int128)] = [
            (1, 5, 4),
            (5, 1, -4),
            (1, 1, 0),
            (UInt128.max - 3, UInt128.max, 3),
            (UInt128.max, UInt128.max - 3, -3),
            (UInt128.max, UInt128.max, 0),
        ]

        for (start, end, distance) in cases {
            try expectStrideInverseLaws(
                from: IPv6Address(address: start, prefixLength: prefix),
                to: IPv6Address(address: end, prefixLength: prefix),
                distance: distance
            )
        }
    }

    @Test("IPv6 strides honor the exact signed distance boundaries")
    func ipv6SignedStrideBoundaries() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let midpoint = UInt128(1) << 127
        let cases: [(UInt128, UInt128, Int128)] = [
            (0, midpoint - 1, Int128.max),
            (midpoint - 1, 0, -Int128.max),
            (midpoint, 0, Int128.min),
            (midpoint, UInt128.max, Int128.max),
            (UInt128.max, midpoint - 1, Int128.min),
        ]

        for (start, end, distance) in cases {
            try expectStrideInverseLaws(
                from: IPv6Address(address: start, prefixLength: prefix),
                to: IPv6Address(address: end, prefixLength: prefix),
                distance: distance
            )
        }

        let zero = IPv6Address(address: 0, prefixLength: prefix)
        let middle = IPv6Address(address: midpoint, prefixLength: prefix)
        let belowMiddle = IPv6Address(address: midpoint - 1, prefixLength: prefix)
        let aboveMiddle = IPv6Address(address: midpoint + 1, prefixLength: prefix)

        #expect(zero.distanceIfRepresentable(to: middle) == nil)
        #expect(aboveMiddle.distanceIfRepresentable(to: zero) == nil)
        #expect(belowMiddle.advancedIfRepresentable(by: Int128.min) == nil)
        #expect(aboveMiddle.advancedIfRepresentable(by: Int128.max) == nil)
    }

    @Test("Address movement crosses network boundaries without changing prefix context")
    func strideAcrossNetworkBoundaries() throws {
        let lastIPv4 = try #require(IPv4Address("192.0.2.255/24"))
        let nextIPv4 = try #require(IPv4Address("192.0.3.0/24"))
        try expectStrideInverseLaws(from: lastIPv4, to: nextIPv4, distance: 1)
        try expectStrideInverseLaws(from: nextIPv4, to: lastIPv4, distance: -1)
        #expect(lastIPv4.network != nextIPv4.network)

        let lastIPv6 = try #require(IPv6Address("2001:db8::ffff:ffff:ffff:ffff/64"))
        let nextIPv6 = try #require(IPv6Address("2001:db8:0:1::/64"))
        try expectStrideInverseLaws(from: lastIPv6, to: nextIPv6, distance: 1)
        try expectStrideInverseLaws(from: nextIPv6, to: lastIPv6, distance: -1)
        #expect(lastIPv6.network != nextIPv6.network)
    }

    @Test("Mixed-prefix distance reaches the address bits while preserving the starting context")
    func mixedPrefixMovementPreservesStartingContext() throws {
        let startIPv4 = try #require(IPv4Address("192.0.2.1/24"))
        try expectMixedPrefixMovement(
            from: startIPv4, to: #require(IPv4Address("192.0.2.10/32")), distance: 9
        )
        try expectMixedPrefixMovement(
            from: startIPv4, to: #require(IPv4Address("192.0.2.1/32")), distance: 0
        )

        let startIPv6 = try #require(IPv6Address("2001:db8::1/64"))
        try expectMixedPrefixMovement(
            from: startIPv6, to: #require(IPv6Address("2001:db8::5/128")), distance: 4
        )
        try expectMixedPrefixMovement(
            from: startIPv6, to: #require(IPv6Address("2001:db8::1/128")), distance: 0
        )
    }

    private func expectStrideInverseLaws<Family: IPAddressFamily>(
        from start: IPAddress<Family>, to end: IPAddress<Family>, distance: Int128
    ) throws {
        #expect(start.prefixLength == end.prefixLength)
        #expect(start.distanceIfRepresentable(to: end) == distance)
        #expect(start.distance(to: end) == distance)
        #expect(start.advanced(by: start.distance(to: end)) == end)
        #expect(start.distance(to: start.advanced(by: distance)) == distance)

        let advanced = try #require(start.advancedIfRepresentable(by: distance))
        #expect(advanced == end)
        #expect(advanced.prefixLength == start.prefixLength)
    }

    private func expectMixedPrefixMovement<Family: IPAddressFamily>(
        from start: IPAddress<Family>, to end: IPAddress<Family>, distance: Int128
    ) throws {
        #expect(start.prefixLength != end.prefixLength)
        #expect(start.distanceIfRepresentable(to: end) == distance)
        #expect(start.distance(to: end) == distance)

        // Raw-bit distance does not imply the whole-value inverse law across prefix contexts.
        let advanced = start.advanced(by: start.distance(to: end))
        #expect(advanced.address == end.address)
        #expect(advanced.prefixLength == start.prefixLength)
        #expect(advanced != end)
        let checkedAdvance = try #require(start.advancedIfRepresentable(by: distance))
        #expect(checkedAdvance == advanced)
    }
}
