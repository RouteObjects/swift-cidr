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

@Suite("Address Family Tests")
struct AddressFamilyTests {
    @Test("IANA metadata is exposed for IP, ASN, and MAC families")
    func exposesIANAAddressFamilyMetadata() {
        assertAddressFamily(AF.V4.self, ianaValue: 1, bitWidth: 32, familyName: "IPv4")
        assertAddressFamily(AF.V6.self, ianaValue: 2, bitWidth: 128, familyName: "IPv6")
        assertAddressFamily(AF.ASN.self, ianaValue: 18, bitWidth: 32, familyName: "AS Number")
        assertAddressFamily(AF.MAC48.self, ianaValue: 16389, bitWidth: 48, familyName: "48-bit MAC")
        assertAddressFamily(AF.MAC64.self, ianaValue: 16390, bitWidth: 64, familyName: "64-bit MAC")

        assertIPAddressFamily(AF.V4.self)
        assertIPAddressFamily(AF.V6.self)
    }

    @Test("shorthand aliases expose supported address family markers")
    func exposesShorthandAliases() {
        assertAddressFamily(V4.self, ianaValue: 1, bitWidth: 32, familyName: "IPv4")
        assertAddressFamily(V6.self, ianaValue: 2, bitWidth: 128, familyName: "IPv6")
        assertAddressFamily(MAC48.self, ianaValue: 16389, bitWidth: 48, familyName: "48-bit MAC")
        assertAddressFamily(MAC64.self, ianaValue: 16390, bitWidth: 64, familyName: "64-bit MAC")

        assertIPAddressFamily(V4.self)
        assertIPAddressFamily(V6.self)
    }

    @Test("AS number family parses and formats unsigned 32-bit decimal text")
    func parsesAndFormatsASNumbers() {
        #expect(AF.ASN.parseAddress("0") == 0)
        #expect(AF.ASN.parseAddress("64496") == 64_496)
        #expect(AF.ASN.parseAddress("4294967295") == UInt32.max)
        #expect(AF.ASN.formatAddress(64_496) == "64496")
        #expect(AF.ASN.formatAddress(UInt32.max) == "4294967295")

        #expect(AF.ASN.parseAddress("") == nil)
        #expect(AF.ASN.parseAddress(" 64496") == nil)
        #expect(AF.ASN.parseAddress("64496 ") == nil)
        #expect(AF.ASN.parseAddress("+64496") == nil)
        #expect(AF.ASN.parseAddress("-1") == nil)
        #expect(AF.ASN.parseAddress("64_496") == nil)
        #expect(AF.ASN.parseAddress("4294967296") == nil)
    }

    @Test("48-bit MAC family parses and formats canonical colon-separated hex")
    func parsesAndFormatsMAC48() {
        #expect(AF.MAC48.parseAddress("00:11:22:33:44:55") == 0x0011_2233_4455)
        #expect(AF.MAC48.parseAddress("aa:bb:cc:dd:ee:ff") == 0xAABB_CCDD_EEFF)
        #expect(AF.MAC48.parseAddress("AA:BB:CC:DD:EE:FF") == 0xAABB_CCDD_EEFF)
        #expect(AF.MAC48.formatAddress(0x0011_2233_4455) == "00:11:22:33:44:55")
        #expect(AF.MAC48.formatAddress(0xAABB_CCDD_EEFF) == "aa:bb:cc:dd:ee:ff")

        #expect(AF.MAC48.parseAddress("") == nil)
        #expect(AF.MAC48.parseAddress("0:11:22:33:44:55") == nil)
        #expect(AF.MAC48.parseAddress("00:11:22:33:44") == nil)
        #expect(AF.MAC48.parseAddress("00:11:22:33:44:55:66") == nil)
        #expect(AF.MAC48.parseAddress("00-11-22-33-44-55") == nil)
        #expect(AF.MAC48.parseAddress("00:11:22:33:44:gg") == nil)
    }

    @Test("64-bit MAC family parses and formats canonical colon-separated hex")
    func parsesAndFormatsMAC64() {
        #expect(AF.MAC64.parseAddress("00:11:22:33:44:55:66:77") == 0x0011_2233_4455_6677)
        #expect(AF.MAC64.parseAddress("AA:BB:CC:DD:EE:FF:00:11") == 0xAABB_CCDD_EEFF_0011)
        #expect(AF.MAC64.formatAddress(0x0011_2233_4455_6677) == "00:11:22:33:44:55:66:77")
        #expect(AF.MAC64.formatAddress(0xAABB_CCDD_EEFF_0011) == "aa:bb:cc:dd:ee:ff:00:11")

        #expect(AF.MAC64.parseAddress("") == nil)
        #expect(AF.MAC64.parseAddress("00:11:22:33:44:55:66") == nil)
        #expect(AF.MAC64.parseAddress("00:11:22:33:44:55:66:77:88") == nil)
        #expect(AF.MAC64.parseAddress("00:11:22:33:44:55:66:7") == nil)
        #expect(AF.MAC64.parseAddress("00-11-22-33-44-55-66-77") == nil)
        #expect(AF.MAC64.parseAddress("00:11:22:33:44:55:66:xx") == nil)
    }

    private func assertAddressFamily<Family: AddressFamily>(
        _ family: Family.Type,
        ianaValue: Int32,
        bitWidth: Int,
        familyName: String
    ) {
        #expect(family.ianaValue == ianaValue)
        #expect(family.bitWidth == bitWidth)
        #expect(family.familyName == familyName)
    }

    private func assertIPAddressFamily<Family: IPAddressFamily>(_ family: Family.Type) {
        #expect(family.bitWidth == Family.Storage.bitWidth)
    }
}
