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

/// A singular address-like value bound to an IP address family.
///
/// `Addressable` marks values whose primary identity is one address-sized identifier, rather than
/// a prefix range or network boundary. The protocol exists mostly as vocabulary: conforming types
/// can be reasoned about as singular address values even when their higher-level meaning differs.
///
/// For example:
///
/// - `IPAddress` is a unicast-capable address value with optional prefix context.
/// - `IPMulticastGroup` is a multicast group destination identifier.
///
/// Both expose one family-bound `address`, but neither statement implies that every `Addressable`
/// value has subnet, route, allocation, or host semantics.
public protocol Addressable: Sendable {
    associatedtype Family: IPAddressFamily

    /// The raw address bits for this value's address family.
    var address: Family.Storage { get }
}

/// Canonical alias for an IPv4 address in the family-bound CIDR engine.
public typealias IPv4Address = IPAddress<V4>

/// Canonical alias for an IPv6 address in the family-bound CIDR engine.
public typealias IPv6Address = IPAddress<V6>

/// A family-bound IP address whose address bits and prefix length form a CIDR value.
///
/// `IPAddress` stores a concrete IP address together with a ``PrefixLength``. The pair is the
/// canonical form for address-shaped CIDR input: `192.0.2.77/24` means address `192.0.2.77`
/// interpreted within the `/24` CIDR range.
///
/// In swift-cidr terminology, `IPAddress` is a core currency type: a small, value-semantic type
/// intended to move between parsing, formatting, containment, and endpoint APIs.
///
/// Use ``network`` when you need the containing ``IPNetwork`` prefix boundary.
public struct IPAddress<Family: IPAddressFamily>: Addressable, CIDR, Hashable, Comparable, LosslessStringConvertible, Codable {
    /// The address component of this CIDR value.
    ///
    /// `address` identifies the concrete IP address being described. Together with
    /// ``prefixLength``, it defines the address's position within the CIDR range.
    public let address: Family.Storage

    /// The prefix-length component of this CIDR value.
    ///
    /// The prefix length provides the range context in which ``address`` is interpreted. Together,
    /// ``address`` and ``prefixLength`` are the canonical form for an address-shaped CIDR value.
    public let prefixLength: PrefixLength<Family>

    /// The raw storage value used to satisfy `CIDR`.
    ///
    /// For `IPAddress`, `storage` is the same value as ``address`` because the address is the stored
    /// CIDR value. Prefix-aligned types such as `IPNetwork` project their canonical prefix instead.
    public var storage: Family.Storage { address }

    /// Creates an address-shaped CIDR value from address bits and an explicit prefix length.
    ///
    /// The address identifies the concrete IP address being described, and the prefix length
    /// provides the CIDR range context for that address.
    public init(address: Family.Storage, prefixLength: PrefixLength<Family>) {
        self.address = address
        self.prefixLength = prefixLength
    }

    /// Creates an individual-address CIDR value.
    ///
    /// Because no prefix length is supplied, the safest CIDR context is a range containing exactly
    /// one address. IPv4 addresses therefore receive `/32` context and IPv6 addresses receive `/128`
    /// context.
    public init(address: Family.Storage) {
        self.init(address: address, prefixLength: .maximum)
    }

    /// The canonical network boundary that contains this address.
    ///
    /// This projection clears host bits according to ``prefixLength`` and returns an `IPNetwork`
    /// using the same address family.
    public var network: IPNetwork<Family> {
        IPNetwork(host: self)
    }

    /// Orders addresses first by address bits, then by prefix length.
    ///
    /// This makes sorting stable when two values contain the same address but carry different
    /// prefix lengths.
    @inlinable
    @inline(__always)
    public static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        lhs.address == rhs.address
        ? lhs.prefixLength < rhs.prefixLength
        : lhs.address < rhs.address
    }
}

extension IPAddress {
    /// Creates an address from presentation text.
    ///
    /// The initializer accepts address-only text such as `192.0.2.1` and CIDR-qualified text such
    /// as `192.0.2.1/24`. Address-only text receives maximum prefix-length context for the family.
    /// CIDR-qualified text preserves the parsed address bits and stores the parsed prefix length as
    /// context.
    public init?(_ string: String) {
        guard let slashIndex = string.firstIndex(of: "/") else {
            guard let address = Family.parseAddress(string) else { return nil }
            self.init(address: address)
            return
        }

        let prefixStart = string.index(after: slashIndex)
        let addressText = string[..<slashIndex]
        let prefixText = string[prefixStart...]

        guard !addressText.isEmpty,
              !prefixText.isEmpty,
              prefixText.firstIndex(of: "/") == nil,
              let rawPrefix = Int(prefixText),
              let prefixLength = PrefixLength<Family>(rawPrefix),
              let address = Family.parseAddress(String(addressText))
        else {
            return nil
        }

        self.init(address: address, prefixLength: prefixLength)
    }
}

public extension IPAddress where Family == AF.V4 {
    /// Creates an IPv4 address from address-only or CIDR-qualified presentation text.
    ///
    /// This overload uses the optimized IPv4 CIDR parser while preserving the public semantics of
    /// the generic string initializer.
    init?(_ string: String) {
        guard let result = AF.parseIPv4CIDRTextSuffix(string, requiresPrefix: false),
              let prefixLength = PrefixLength<Family>(rawValue: result.prefixLength)
        else {
            return nil
        }

        self.init(address: result.address, prefixLength: prefixLength)
    }

    @inline(__always)
    func formatted(_ style: IPv4TextStyle) -> String {
        switch style {
        case .addressAndNetmask:
            let v4Mask = UInt32.networkMask(for: prefixLength.intValue)
            return "\(addressLiteral) \(AF.formatV4(v4Mask))"
        }
    }
}

public extension IPAddress where Family == AF.V6 {
    /// Creates an IPv6 address from address-only or CIDR-qualified presentation text.
    ///
    /// This overload uses the optimized IPv6 CIDR parser while preserving the public semantics of
    /// the generic string initializer.
    init?(_ string: String) {
        guard let result = AF.parseIPv6CIDRTextSuffix(string, requiresPrefix: false),
              let prefixLength = PrefixLength<Family>(rawValue: result.prefixLength)
        else {
            return nil
        }

        self.init(address: result.address, prefixLength: prefixLength)
    }

    @inline(__always)
    func formatted(_ style: IPv6TextStyle) -> String {
        switch style {
        case .preferred:
            return addressLiteral
        case .ipv4Mapped:
            return AF.formatV6Mapped(address) ?? addressLiteral
        case .compressed:
            return AF.formatV6Compressed(address)
        }
    }
}

extension IPAddress {
    /// Decodes an address from its canonical CIDR text representation.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) address '\(description)'.")
        }
        self = address
    }

    /// Encodes the address as canonical CIDR text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension IPAddress: Strideable {
    /// The signed distance type used to move through address space.
    public typealias Stride = Int128

    /// Returns the signed distance to another address when it fits in `Int128`.
    ///
    /// The calculation compares only address bits. Prefix context is ignored for distance
    /// measurement.
    public func distanceIfRepresentable(to other: IPAddress) -> Int128? {
        // Force unwrap is safe: supported CIDR address-family storage is unsigned and fits in UInt128.
        let lhs = UInt128(exactly: self.address)!
        // Force unwrap is safe: supported CIDR address-family storage is unsigned and fits in UInt128.
        let rhs = UInt128(exactly: other.address)!
        if rhs >= lhs {
            return Int128(exactly: rhs - lhs)
        }
        let magnitude = lhs - rhs
        if let positive = Int128(exactly: magnitude) { return -positive }
        // Force unwrap is safe: Int128.max is positive and always representable as UInt128.
        let minMagnitude = UInt128(exactly: Int128.max)! + 1
        guard magnitude == minMagnitude else { return nil }
        return Int128.min
    }

    /// Returns an address advanced by `n` positions when the result remains in the family range.
    ///
    /// The returned value preserves the receiver's ``prefixLength``. Returns `nil` instead of
    /// trapping when the move would underflow, overflow, or exceed the family storage width.
    public func advancedIfRepresentable(by n: Int128) -> IPAddress? {
        if n >= 0 {
            // Force unwrap is safe: this branch only converts non-negative Int128 values to UInt128.
            let magnitude = UInt128(exactly: n)!
            guard let step = Family.Storage(exactly: magnitude) else { return nil }
            let (next, overflow) = address.addingReportingOverflow(step)
            guard !overflow else { return nil }
            return IPAddress(address: next, prefixLength: prefixLength)
        }
        let magnitude: UInt128
        if n == Int128.min {
            // Force unwrap is safe: Int128.max is positive; adding 1 gives Int128.min's magnitude.
            magnitude = UInt128(exactly: Int128.max)! + 1
        } else {
            // Force unwrap is safe: negative values other than Int128.min are negated before conversion.
            magnitude = UInt128(exactly: -n)!
        }
        guard let step = Family.Storage(exactly: magnitude) else { return nil }
        let (next, overflow) = address.subtractingReportingOverflow(step)
        guard !overflow else { return nil }
        return IPAddress(address: next, prefixLength: prefixLength)
    }

    /// Returns the signed distance to another address.
    ///
    /// This `Strideable` requirement traps if the distance cannot be represented by `Int128`. Use
    /// ``distanceIfRepresentable(to:)`` when failure should be handled explicitly.
    public func distance(to other: IPAddress) -> Int128 {
        guard let distance = distanceIfRepresentable(to: other) else { preconditionFailure("Exceeds Int128 range.") }
        return distance
    }

    /// Returns an address advanced by `n` positions.
    ///
    /// This `Strideable` requirement traps if the resulting address would leave the family range.
    /// Use ``advancedIfRepresentable(by:)`` when failure should be handled explicitly.
    public func advanced(by n: Int128) -> IPAddress {
        guard let advanced = advancedIfRepresentable(by: n) else { preconditionFailure("Overflow/Underflow range.") }
        return advanced
    }
}

extension IPAddress {
    @inlinable
    @inline(__always)
    public var addressLiteral: String {
        Family.formatAddress(address)
    }

    @inlinable
    @inline(__always)
    public var description: String {
        "\(addressLiteral)/\(prefixLength)"
    }

    @inlinable
    @inline(__always)
    public func formatted(_ style: CIDRTextStyle) -> String {
        switch style {
        case .cidrNotation:
            return description
        case .addressOnly:
            return addressLiteral
        }
    }
}
