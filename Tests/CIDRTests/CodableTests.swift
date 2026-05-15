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

@Suite("Codable Tests")
struct CodableTests {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    @Test("PrefixLength encodes as a numeric scalar and round-trips")
    func prefixLengthCodableRoundTrip() throws {
        let ipv4 = try #require(IPv4PrefixLength(24))
        let ipv6 = try #require(IPv6PrefixLength(64))

        #expect(try encodedJSON(ipv4) == "24")
        #expect(try encodedJSON(ipv6) == "64")
        #expect(try decoder.decode(IPv4PrefixLength.self, from: Data("24".utf8)) == ipv4)
        #expect(try decoder.decode(IPv6PrefixLength.self, from: Data("64".utf8)) == ipv6)
    }

    @Test("Family-bound addresses and networks encode as canonical CIDR strings")
    func familyBoundCIDRWireShape() throws {
        let ipv4Address = try #require(IPv4Address("192.0.2.1/24"))
        let ipv6Address = try #require(IPv6Address("2001:db8::1/64"))
        let ipv4Network = try #require(IPv4Network("192.0.2.0/24"))
        let ipv6Network = try #require(IPv6Network("2001:db8::/64"))

        #expect(try encodedJSONStringValue(ipv4Address) == "192.0.2.1/24")
        #expect(try encodedJSONStringValue(ipv6Address) == "2001:db8:0:0:0:0:0:1/64")
        #expect(try encodedJSONStringValue(ipv4Network) == "192.0.2.0/24")
        #expect(try encodedJSONStringValue(ipv6Network) == "2001:db8:0:0:0:0:0:0/64")

        #expect(try decoder.decode(IPv4Address.self, from: Data(#""192.0.2.1/24""#.utf8)) == ipv4Address)
        #expect(try decoder.decode(IPv6Network.self, from: Data(#""2001:db8:0:0:0:0:0:0/64""#.utf8)) == ipv6Network)
    }

    @Test("AnyIPAddress and AnyIPNetwork encode as canonical CIDR strings")
    func anyAddressAndNetworkWireShape() throws {
        let anyAddress = try #require(AnyIPAddress("2001:db8::1/64"))
        let anyNetwork = try #require(AnyIPNetwork("192.0.2.0/24"))

        #expect(try encodedJSONStringValue(anyAddress) == "2001:db8:0:0:0:0:0:1/64")
        #expect(try encodedJSONStringValue(anyNetwork) == "192.0.2.0/24")
        #expect(try decoder.decode(AnyIPAddress.self, from: Data(#""2001:db8:0:0:0:0:0:1/64""#.utf8)) == anyAddress)
        #expect(try decoder.decode(AnyIPNetwork.self, from: Data(#""192.0.2.0/24""#.utf8)) == anyNetwork)
    }

    @Test("AnyPrefixLength encodes as a tagged object")
    func anyPrefixLengthWireShape() throws {
        let ipv4 = AnyPrefixLength(try #require(IPv4PrefixLength(24)))
        let ipv6 = AnyPrefixLength(try #require(IPv6PrefixLength(64)))

        #expect(try encodedJSON(ipv4) == #"{"family":"ipv4","prefixLength":24}"#)
        #expect(try encodedJSON(ipv6) == #"{"family":"ipv6","prefixLength":64}"#)
        #expect(try decoder.decode(AnyPrefixLength.self, from: Data(#"{"family":"ipv4","prefixLength":24}"#.utf8)) == ipv4)
        #expect(try decoder.decode(AnyPrefixLength.self, from: Data(#"{"family":"ipv6","prefixLength":64}"#.utf8)) == ipv6)
    }

    @Test("Codable decoding rejects malformed or mismatched data")
    func codableRejectsMalformedData() {
        #expect(throws: DecodingError.self) {
            try decoder.decode(IPv4PrefixLength.self, from: Data("33".utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(IPv4Address.self, from: Data(#""bad-address""#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(IPv6Network.self, from: Data(#""2001:db8::/129""#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(AnyIPAddress.self, from: Data(#"{"family":"ipv4","address":"192.0.2.1/24"}"#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(AnyPrefixLength.self, from: Data(#""24""#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(AnyPrefixLength.self, from: Data(#"{"family":"ipv5","prefixLength":24}"#.utf8))
        }
        #expect(throws: DecodingError.self) {
            try decoder.decode(AnyPrefixLength.self, from: Data(#"{"family":"ipv4","prefixLength":129}"#.utf8))
        }
    }

    private func encodedJSON<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    private func encodedJSONStringValue<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        let json = try #require(JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? String)
        return json
    }
}
