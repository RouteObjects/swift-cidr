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

/// A numeric Autonomous System number.
///
/// `AutonomousSystemNumber` is the value-semantic counterpart to the ``AF/ASN`` address-family
/// marker. It stores the complete four-octet AS number space defined by
/// [RFC 6793](https://www.rfc-editor.org/rfc/rfc6793.html) and uses the decimal `asplain`
/// representation specified by [RFC 5396](https://www.rfc-editor.org/rfc/rfc5396.html).
///
/// Parsing accepts bare ASCII decimal text such as `64496`. RPSL forms such as `AS64496`, legacy
/// `asdot` text such as `1.10`, and lossless source spelling belong to an RPSL layer above this
/// numeric value.
///
/// Every value representable by ``AF/ASN/Storage`` can be stored, including reserved and
/// special-purpose numbers. Whether an AS number is allocated, reserved, or suitable for a routing
/// operation is registry or policy information outside this type.
// CHANGE: Keep the numeric value distinct from AF.ASN, which remains an AddressFamily marker.
public struct AutonomousSystemNumber: RawRepresentable, Sendable, Hashable, Comparable, CustomStringConvertible, LosslessStringConvertible, Codable {
    /// The complete unsigned 32-bit AS number value.
    public let rawValue: AF.ASN.Storage

    /// Creates an AS number from its raw numeric value.
    ///
    /// Every `AF.ASN.Storage` value is representable. This initializer does not perform registry
    /// allocation or routing-policy validation.
    public init(rawValue: AF.ASN.Storage) {
        self.rawValue = rawValue
    }

    /// Creates an AS number from its raw numeric value.
    ///
    /// This convenience initializer is equivalent to ``init(rawValue:)``.
    public init(_ rawValue: AF.ASN.Storage) {
        self.init(rawValue: rawValue)
    }

    /// Creates an AS number from bare `asplain` decimal text.
    ///
    /// The parser accepts only ASCII decimal digits whose value fits in ``AF/ASN/Storage``. It does
    /// not accept whitespace, signs, separators, `asdot`, or an RPSL `AS` prefix.
    public init?(_ description: String) {
        guard let rawValue = AF.ASN.parseAddress(description) else { return nil }
        self.init(rawValue: rawValue)
    }

    /// The canonical bare `asplain` decimal representation.
    public var description: String {
        AF.ASN.formatAddress(rawValue)
    }

    /// Orders AS numbers by their unsigned numeric value.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension AutonomousSystemNumber {
    /// Decodes an AS number from an unsigned numeric scalar.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(AF.ASN.Storage.self)
        self.init(rawValue: rawValue)
    }

    /// Encodes the AS number as an unsigned numeric scalar.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Shorthand for ``AutonomousSystemNumber``.
public typealias ASN = AutonomousSystemNumber
