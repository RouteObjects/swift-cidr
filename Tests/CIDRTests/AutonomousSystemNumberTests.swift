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

@Suite("Autonomous System Number Tests")
struct AutonomousSystemNumberTests {
    @Test("Raw construction covers the complete four-octet number space")
    func rawConstructionCoversBoundaries() {
        let values: [AF.ASN.Storage] = [0, 23_456, 65_535, 65_536, .max]

        for value in values {
            #expect(AutonomousSystemNumber(value).rawValue == value)
            #expect(AutonomousSystemNumber(rawValue: value).rawValue == value)
        }
    }

    @Test("Asplain parsing round-trips through canonical decimal text")
    func asplainParsingRoundTrips() throws {
        let examples: [(source: String, value: AF.ASN.Storage, canonical: String)] = [
            ("0", 0, "0"),
            ("64496", 64_496, "64496"),
            ("65535", 65_535, "65535"),
            ("65536", 65_536, "65536"),
            ("4294967295", .max, "4294967295"),
            ("00064496", 64_496, "64496"),
        ]

        for example in examples {
            let number = try #require(AutonomousSystemNumber(example.source))
            #expect(number.rawValue == example.value)
            #expect(number.description == example.canonical)
            #expect(AutonomousSystemNumber(number.description) == number)
        }
    }

    @Test("Parsing rejects non-asplain and overflowing text")
    func parsingRejectsInvalidText() {
        let invalid = [
            "",
            " ",
            " 64496",
            "64496 ",
            "+64496",
            "-1",
            "64_496",
            "1.10",
            "AS64496",
            "as64496",
            "4294967296",
            "６４４９６",
        ]

        for source in invalid {
            #expect(AutonomousSystemNumber(source) == nil)
        }
    }

    @Test("Numeric ordering crosses the two-octet boundary")
    func numericOrdering() {
        let lower = AutonomousSystemNumber(65_535)
        let upper = AutonomousSystemNumber(65_536)

        #expect(lower < upper)
        #expect(upper > lower)
    }

    @Test("Hashing uses numeric identity rather than source spelling")
    func hashingUsesNumericIdentity() throws {
        let canonical = try #require(AutonomousSystemNumber("64496"))
        let padded = try #require(AutonomousSystemNumber("00064496"))

        #expect(canonical == padded)
        #expect(Set([canonical, padded]).count == 1)
    }

    @Test("Codable uses an unsigned numeric scalar")
    func codableUsesNumericScalar() throws {
        let number = AutonomousSystemNumber(64_496)
        let data = try JSONEncoder().encode(number)

        #expect(String(decoding: data, as: UTF8.self) == "64496")
        #expect(try JSONDecoder().decode(AutonomousSystemNumber.self, from: data) == number)
    }

    @Test("Codable rejects invalid scalar representations", arguments: [
        "-1",
        "4294967296",
        #""64496""#,
        "1.5",
        "null",
        #"{"rawValue":64496}"#,
    ])
    func codableRejectsInvalidScalars(source: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AutonomousSystemNumber.self, from: Data(source.utf8))
        }
    }

    @Test("The value is Sendable")
    func valueIsSendable() {
        requireSendable(AutonomousSystemNumber(64_496))
    }

    private func requireSendable<T: Sendable>(_: T) {}
}
