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

@Suite("IP Address Family Width Tests")
struct IPAddressFamilyWidthTests {
    @Test("IP families derive bitWidth from Storage")
    func derivedWidths() {
        #expect(AF.V4.bitWidth == UInt32.bitWidth)
        #expect(AF.V6.bitWidth == UInt128.bitWidth)
        #expect(DerivedWidthFamily.bitWidth == UInt16.bitWidth)
    }

    @Test("Raw prefix lengths accept storage boundaries and reject larger values")
    func rawPrefixLengthBoundaries() {
        // CHANGE: Pin validation at the raw initializer now exposed to downstream specialization.
        #expect(IPv4PrefixLength(rawValue: 0)?.rawValue == 0)
        #expect(IPv4PrefixLength(rawValue: 32)?.rawValue == 32)
        #expect(IPv4PrefixLength(rawValue: 33) == nil)
        #expect(IPv6PrefixLength(rawValue: 0)?.rawValue == 0)
        #expect(IPv6PrefixLength(rawValue: 128)?.rawValue == 128)
        #expect(IPv6PrefixLength(rawValue: 129) == nil)
    }

    @Test("Non-IP families keep their declared width")
    func nonIPWidths() {
        #expect(AF.MAC48.bitWidth == 48)
        #expect(AF.MAC48.Storage.bitWidth == 64)
    }

    @Test("IANA address family numbers are 16-bit registry values")
    func ianaValuesAreUInt16() {
        let values: [UInt16] = [AF.V4.ianaValue, AF.V6.ianaValue, AF.ASN.ianaValue, AF.MAC48.ianaValue, AF.MAC64.ianaValue]
        #expect(values == [1, 2, 18, 16389, 16390])
    }

    @Test("A misdeclared bitWidth cannot widen prefix lengths beyond Storage")
    func misdeclaredWidthIsMetadataOnly() throws {
        // The declared 200 is ignored by CIDR math; Storage (UInt32) is authoritative.
        #expect(MisdeclaredWidthFamily.bitWidth == 200)
        #expect(PrefixLength<MisdeclaredWidthFamily>(200) == nil)
        #expect(PrefixLength<MisdeclaredWidthFamily>(33) == nil)
        #expect(PrefixLength<MisdeclaredWidthFamily>(rawValue: 32)?.rawValue == 32)
        #expect(PrefixLength<MisdeclaredWidthFamily>(rawValue: 33) == nil)
        #expect(PrefixLength<MisdeclaredWidthFamily>.maximum.rawValue == 32)
        #expect(IPAddress<MisdeclaredWidthFamily>(address: 7).prefixLength.rawValue == 32)

        let length = try #require(PrefixLength<MisdeclaredWidthFamily>(24))
        let network = IPNetwork<MisdeclaredWidthFamily>(prefix: 0xFFFF_FF7F, prefixLength: length)
        #expect(network.prefix == 0xFFFF_FF00)
        #expect(network.last.address == 0xFFFF_FFFF)
        #expect(network.nextNetwork == nil)
        #expect(Array(network.subnets(prefixLength: 26)).count == 4)
        #expect(IPNetwork<MisdeclaredWidthFamily>("7/40") == nil)
        #expect(IPNetwork<MisdeclaredWidthFamily>("7/32")?.prefixLength.rawValue == 32)
    }

    @Test("Summarization uses storage width even when family metadata disagrees")
    func summarizationIgnoresMisdeclaredWidth() throws {
        // CHANGE: The append kernel must retain Storage.bitWidth as its arithmetic authority.
        let start = IPAddress<MisdeclaredWidthFamily>(address: 0xFFFF_FFFE)
        let end = IPAddress<MisdeclaredWidthFamily>(address: .max)
        let expected = IPNetwork<MisdeclaredWidthFamily>(
            prefix: start.address, prefixLength: try #require(PrefixLength(31))
        )
        var result: [IPNetwork<MisdeclaredWidthFamily>] = []
        IPNetwork<MisdeclaredWidthFamily>.summarize(from: start, to: end, into: &result)
        #expect(result == [expected])
        #expect(IPNetwork<MisdeclaredWidthFamily>.summarize(from: start, to: end) == [expected])

        let range = try #require(IPAddressRange(lowerBound: start, upperBound: end))
        range.summarizedNetworks(into: &result)
        IPAddressCoverage([range]).summarizedNetworks(into: &result)
        #expect(result == [expected, expected, expected])
    }
}

private enum DerivedWidthFamily: IPAddressFamily {
    typealias Storage = UInt16
    static let ianaValue: UInt16 = 65_535
    static let familyName = "Derived Width Test"
    static func parseAddress(_ string: String) -> UInt16? { UInt16(string) }
    static func formatAddress(_ address: UInt16) -> String { String(address) }
}

private enum MisdeclaredWidthFamily: IPAddressFamily {
    typealias Storage = UInt32
    static let ianaValue: UInt16 = 65_535
    static let bitWidth = 200
    static let familyName = "Misdeclared Width Test"
    static func parseAddress(_ string: String) -> UInt32? { UInt32(string) }
    static func formatAddress(_ address: UInt32) -> String { String(address) }
}
