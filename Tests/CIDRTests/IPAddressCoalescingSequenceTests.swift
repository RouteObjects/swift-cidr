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

import CIDR
import Testing

@Suite("IP Address Coalescing Sequence Tests")
struct IPAddressCoalescingSequenceTests {
    @Test("IPv4 coalesces arbitrary sequences through maximum endpoints")
    func ipv4Sequence() throws {
        try checkSequenceNormalization(V4.self)
    }

    @Test("IPv6 coalesces arbitrary sequences through maximum endpoints")
    func ipv6Sequence() throws {
        try checkSequenceNormalization(V6.self)
    }

    @Test("Custom storage families retain generic sequence normalization")
    func customFamilySequence() throws {
        try checkSequenceNormalization(CoalescingTestFamily.self)
    }

    private func checkSequenceNormalization<Family: IPAddressFamily>(_: Family.Type) throws {
        typealias Range = IPAddressRange<Family>

        func range(_ lower: Family.Storage, _ upper: Family.Storage) throws -> Range {
            try #require(
                Range(
                    lowerBound: IPAddress<Family>(address: lower),
                    upperBound: IPAddress<Family>(address: upper)
                )
            )
        }

        let maximum = Family.Storage.max
        // CHANGE: Specialization must preserve non-Array sequences and custom-family boundary math.
        let input = try [
            range(maximum, maximum),
            range(8, 9),
            range(0, 0),
            range(maximum - 1, maximum - 1),
            range(8, 10),
            range(8, 9),
        ]
        let expected = try [range(0, 0), range(8, 10), range(maximum - 1, maximum)]

        #expect(Range.coalescing(AnySequence(input)) == expected)
        #expect(IPAddressCoverage(AnySequence(input)).ranges == expected)

        let empty = AnySequence([Range]())
        #expect(Range.coalescing(empty).isEmpty)
        #expect(IPAddressCoverage(empty).isEmpty)
    }
}

private enum CoalescingTestFamily: IPAddressFamily {
    typealias Storage = UInt16
    static let ianaValue: UInt16 = 65_535
    static let familyName = "Coalescing Test"
    static func parseAddress(_ string: String) -> UInt16? { UInt16(string) }
    static func formatAddress(_ address: UInt16) -> String { String(address) }
}
