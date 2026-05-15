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

/// Canonical alias for an IPv4 prefix length.
public typealias IPv4PrefixLength = PrefixLength<V4>

/// Canonical alias for an IPv6 prefix length.
public typealias IPv6PrefixLength = PrefixLength<V6>

/// The validated prefix length after the CIDR notation slash.
///
/// `PrefixLength` turns the slash number into a family-bound domain type instead of leaving it as
/// a loose integer. IPv4 prefix lengths are valid in `0...32`, and IPv6 prefix lengths are valid in
/// `0...128`. The type parameter prevents accidentally using an IPv4 prefix length where an IPv6
/// prefix length is required, or the reverse.
///
/// A prefix length describes how much of an address belongs to the CIDR prefix. `/0` covers the
/// entire address-family space. `/32` for IPv4 and `/128` for IPv6 describe a range containing
/// exactly one address.
///
/// In swift-cidr terminology, `PrefixLength` is a core currency type: a compact, value-semantic
/// representation used by addresses, networks, multicast ranges, and neutral CIDR blocks.
public struct PrefixLength<Family: AddressFamily>: RawRepresentable, Sendable, Hashable, Comparable, CustomStringConvertible, LosslessStringConvertible, Codable {
    /// The validated slash number stored as compact unsigned integer storage.
    ///
    /// This value is guaranteed to be in `0...Family.bitWidth`.
    public let rawValue: UInt8

    /// Creates a prefix length from raw storage.
    ///
    /// Returns `nil` when `rawValue` is greater than the address-family bit width.
    public init?(rawValue: UInt8) {
        guard Int(rawValue) <= Family.bitWidth else { return nil }
        self.rawValue = rawValue
    }

    /// Creates a prefix length from an integer slash number.
    ///
    /// Returns `nil` for negative values and for values greater than the address-family bit width.
    public init?(_ value: Int) {
        guard value >= 0,
              value <= Family.bitWidth,
              let rawValue = UInt8(exactly: value)
        else {
            return nil
        }

        self.rawValue = rawValue
    }

    /// Creates a prefix length from base-10 integer text.
    ///
    /// The text is the number after the slash, without the slash itself. For example,
    /// `PrefixLength<V4>("24")` represents `/24`.
    public init?(_ description: String) {
        guard let value = Int(description) else { return nil }
        self.init(value)
    }

    /// The prefix length as an `Int`.
    ///
    /// Use this projection for mask generation, shifts, loops, and other algorithms that require
    /// Swift's default integer type.
    @inline(__always)
    public var intValue: Int {
        Int(rawValue)
    }

    /// Base-10 integer text for the prefix length without the slash.
    ///
    /// Full CIDR values such as `192.0.2.0/24` add the slash when formatting the containing value.
    public var description: String {
        "\(rawValue)"
    }

    /// Orders shorter prefixes before longer prefixes.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension PrefixLength {
    /// Creates a prefix length from a value the implementation has already proven valid.
    ///
    /// Use the failable public initializers for external input. This initializer is for internal CIDR
    /// math where failure would indicate a programmer error or a violated address-family invariant.
    internal init(preconditioned value: Int) {
        precondition(value >= 0, "Prefix length must not be negative.")
        precondition(value <= Family.bitWidth, "Prefix length must not exceed the address-family width.")
        precondition(value <= Int(UInt8.max), "Prefix length must fit in UInt8 storage.")
        self.rawValue = UInt8(truncatingIfNeeded: value)
    }

    /// The `/0` prefix length for this address family.
    public static var zero: Self {
        Self(preconditioned: 0)
    }

    /// The maximum prefix length for this address family.
    ///
    /// This is `/32` for IPv4 and `/128` for IPv6.
    public static var maximum: Self {
        Self(preconditioned: Family.bitWidth)
    }
}

extension PrefixLength {
    /// Decodes a prefix length from a numeric scalar.
    ///
    /// Decoding fails when the value is outside the valid range for the address family.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        guard let prefixLength = Self(value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) prefix length \(value).")
        }
        self = prefixLength
    }

    /// Encodes the prefix length as a numeric scalar.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(intValue)
    }
}
