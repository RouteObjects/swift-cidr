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

/// An IPv4 closed address range.
public typealias IPv4AddressRange = IPAddressRange<V4>

/// An IPv6 closed address range.
public typealias IPv6AddressRange = IPAddressRange<V6>

/// An inclusive, ordered interval of addresses from one IP address family.
///
/// A range represents address coverage, not CIDR prefix structure. Its endpoints retain only their
/// literal address bits. Reading ``lowerBound`` or ``upperBound`` therefore returns an `IPAddress`
/// with the family's host prefix (`/32` for IPv4 or `/128` for IPv6), even when a programmatic input
/// endpoint originally carried a shorter prefix length.
///
/// Text uses the strict `lower...upper` form. Both endpoints must be address literals from the same
/// family, and the lower endpoint must not be greater than the upper endpoint.
public struct IPAddressRange<Family: IPAddressFamily>: Sendable, Hashable,
    LosslessStringConvertible, Codable
{
    private let lowerAddress: Family.Storage
    private let upperAddress: Family.Storage

    /// The first address in the range, with host-prefix context.
    public var lowerBound: IPAddress<Family> {
        IPAddress(address: lowerAddress)
    }

    /// The last address in the range, with host-prefix context.
    public var upperBound: IPAddress<Family> {
        IPAddress(address: upperAddress)
    }

    /// Creates an ordered range from two inclusive endpoints.
    ///
    /// The initializer returns `nil` when `lowerBound` follows `upperBound`. Prefix-length context
    /// on either endpoint is intentionally discarded because ranges compare address coverage.
    public init?(lowerBound: IPAddress<Family>, upperBound: IPAddress<Family>) {
        guard lowerBound.address <= upperBound.address else { return nil }

        // A range endpoint is one address; retaining CIDR prefix context would make equal
        // address intervals hash differently even though they cover the same addresses.
        self.lowerAddress = lowerBound.address
        self.upperAddress = upperBound.address
    }

    /// Creates a singleton range containing one address.
    ///
    /// Prefix-length context on `address` is intentionally discarded.
    public init(_ address: IPAddress<Family>) {
        self.lowerAddress = address.address
        self.upperAddress = address.address
    }

    /// Creates a range covering every address in a canonical prefix.
    public init<Prefix: IPPrefix>(covering prefix: Prefix) where Prefix.Family == Family {
        self.lowerAddress = prefix.first.address
        self.upperAddress = prefix.last.address
    }

    /// Parses a range from strict `lower...upper` address-literal text.
    ///
    /// CIDR suffixes, whitespace, repeated delimiters, reversed endpoints, and mixed address
    /// families are rejected.
    public init?(_ description: String) {
        guard let delimiter = description.firstRange(of: "..."),
            description[delimiter.upperBound...].firstRange(of: "...") == nil
        else {
            return nil
        }

        let lowerText = String(description[..<delimiter.lowerBound])
        let upperText = String(description[delimiter.upperBound...])
        guard !lowerText.isEmpty,
            !upperText.isEmpty,
            let lowerAddress = Family.parseAddress(lowerText),
            let upperAddress = Family.parseAddress(upperText)
        else {
            return nil
        }

        self.init(
            lowerBound: IPAddress(address: lowerAddress),
            upperBound: IPAddress(address: upperAddress)
        )
    }

    /// The canonical `lower...upper` address-literal representation.
    public var description: String {
        "\(Family.formatAddress(lowerAddress))...\(Family.formatAddress(upperAddress))"
    }

    /// The number of covered addresses when that cardinality fits in `UInt128`.
    ///
    /// A range covering the entire IPv6 address space returns `nil` because its cardinality is
    /// `2^128`, one greater than `UInt128.max`.
    public var rangeSizeIfRepresentable: UInt128? {
        // Widen IPv4 before adding one so its complete address space remains representable.
        guard let lower = UInt128(exactly: lowerAddress),
            let upper = UInt128(exactly: upperAddress)
        else {
            return nil
        }
        let (size, overflow) = (upper - lower).addingReportingOverflow(1)
        return overflow ? nil : size
    }

    /// Returns whether `address` is inside this inclusive range.
    public func contains(_ address: IPAddress<Family>) -> Bool {
        lowerAddress <= address.address && address.address <= upperAddress
    }

    /// Returns whether every address in `other` is inside this range.
    public func contains(_ other: Self) -> Bool {
        lowerAddress <= other.lowerAddress && other.upperAddress <= upperAddress
    }

    /// Returns whether this range and `other` share at least one address.
    public func overlaps(_ other: Self) -> Bool {
        lowerAddress <= other.upperAddress && other.lowerAddress <= upperAddress
    }

    /// Returns whether the two ranges touch without overlapping.
    public func isAdjacent(to other: Self) -> Bool {
        areSuccessive(upperAddress, other.lowerAddress)
            || areSuccessive(other.upperAddress, lowerAddress)
    }

    /// Returns the exact union of two connected ranges, or `nil` when a gap separates them.
    public func merged(with other: Self) -> Self? {
        guard overlaps(other) || isAdjacent(to: other) else { return nil }

        return Self(
            uncheckedLowerAddress: min(lowerAddress, other.lowerAddress),
            upperAddress: max(upperAddress, other.upperAddress)
        )
    }

    /// Coalesces ranges into the smallest ascending list with the same exact address coverage.
    ///
    /// Duplicate, contained, overlapping, and adjacent ranges collapse. Gaps are never widened or
    /// covered. Applying this operation to an already-coalesced result is idempotent.
    public static func coalescing<Ranges: Sequence>(_ ranges: Ranges) -> [Self]
    where Ranges.Element == Self {
        let sorted = ranges.sorted { lhs, rhs in
            if lhs.lowerAddress == rhs.lowerAddress {
                return lhs.upperAddress > rhs.upperAddress
            }
            return lhs.lowerAddress < rhs.lowerAddress
        }
        guard sorted.count > 1 else { return sorted }

        var result: [Self] = []
        result.reserveCapacity(sorted.count)
        var current = sorted[0]

        for range in sorted.dropFirst() {
            // Sorted input only needs a forward boundary comparison. Keeping one active
            // interval avoids repeated result-array mutation for heavily subsumed data.
            if current.connectsToFollowing(range) {
                current = Self(
                    uncheckedLowerAddress: current.lowerAddress,
                    upperAddress: max(current.upperAddress, range.upperAddress)
                )
            } else {
                result.append(current)
                current = range
            }
        }
        result.append(current)

        return result
    }

    /// Summarizes this exact range as the smallest ordered list of canonical networks.
    ///
    /// This delegates range-to-CIDR math to swift-cidr. The returned networks preserve exact
    /// coverage, but their prefix lengths need not match prefixes used to construct this range.
    public func summarizedNetworks() -> [IPNetwork<Family>] {
        IPNetwork<Family>.summarize(from: lowerBound, to: upperBound)
    }

    /// Decodes a range from its canonical single-string representation.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid \(Family.familyName) address range '\(description)'."
            )
        }
        self = range
    }

    /// Encodes the range as one canonical `lower...upper` string.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    private init(
        uncheckedLowerAddress lowerAddress: Family.Storage,
        upperAddress: Family.Storage
    ) {
        self.lowerAddress = lowerAddress
        self.upperAddress = upperAddress
    }

    private func areSuccessive(_ lower: Family.Storage, _ upper: Family.Storage) -> Bool {
        let (successor, overflow) = lower.addingReportingOverflow(1)
        return !overflow && successor == upper
    }

    private func connectsToFollowing(_ other: Self) -> Bool {
        other.lowerAddress <= upperAddress || areSuccessive(upperAddress, other.lowerAddress)
    }
}

/// A family-erased inclusive IP address range.
///
/// Use this boundary type when IPv4 and IPv6 values must share one collection or parsing API. Keep
/// family-specific algorithms on ``IPAddressRange`` whenever the family is known statically.
public enum AnyIPAddressRange: Sendable, Hashable, CustomStringConvertible,
    CustomDebugStringConvertible, LosslessStringConvertible, Codable
{
    /// An IPv4 address range.
    case v4(IPv4AddressRange)

    /// An IPv6 address range.
    case v6(IPv6AddressRange)

    /// Wraps an IPv4 range.
    public init(_ range: IPv4AddressRange) {
        self = .v4(range)
    }

    /// Wraps an IPv6 range.
    public init(_ range: IPv6AddressRange) {
        self = .v6(range)
    }

    /// Creates a singleton range from a family-erased address.
    public init(_ address: AnyIPAddress) {
        switch address {
        case .v4(let address):
            self = .v4(IPv4AddressRange(address))
        case .v6(let address):
            self = .v6(IPv6AddressRange(address))
        }
    }

    /// Creates a range covering a family-erased canonical network.
    public init(covering network: AnyIPNetwork) {
        switch network {
        case .v4(let network):
            self = .v4(IPv4AddressRange(covering: network))
        case .v6(let network):
            self = .v6(IPv6AddressRange(covering: network))
        }
    }

    /// Parses an IPv4 or IPv6 range, trying IPv4 first.
    public init?(_ description: String) {
        self.init(description, parseOrder: .ipv4ThenIPv6)
    }

    /// Parses a mixed-family range using the requested family parse order.
    ///
    /// Parse order is a performance hint. Both families are attempted before parsing fails.
    public init?(
        _ description: String,
        parseOrder: AddressFamilyParseOrder = .ipv4ThenIPv6
    ) {
        switch parseOrder {
        case .ipv4ThenIPv6:
            if let range = IPv4AddressRange(description) {
                self = .v4(range)
                return
            }
            if let range = IPv6AddressRange(description) {
                self = .v6(range)
                return
            }
        case .ipv6ThenIPv4:
            if let range = IPv6AddressRange(description) {
                self = .v6(range)
                return
            }
            if let range = IPv4AddressRange(description) {
                self = .v4(range)
                return
            }
        }
        return nil
    }

    /// The IANA address-family number of the wrapped range.
    public var ianaValue: Int32 {
        switch self {
        case .v4: V4.ianaValue
        case .v6: V6.ianaValue
        }
    }

    /// The human-readable address-family name of the wrapped range.
    public var familyName: String {
        switch self {
        case .v4: V4.familyName
        case .v6: V6.familyName
        }
    }

    /// A Boolean value indicating whether this value wraps IPv4.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether this value wraps IPv6.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The first address in the range, with family-erased host-prefix context.
    public var lowerBound: AnyIPAddress {
        switch self {
        case .v4(let range): AnyIPAddress(range.lowerBound)
        case .v6(let range): AnyIPAddress(range.lowerBound)
        }
    }

    /// The last address in the range, with family-erased host-prefix context.
    public var upperBound: AnyIPAddress {
        switch self {
        case .v4(let range): AnyIPAddress(range.upperBound)
        case .v6(let range): AnyIPAddress(range.upperBound)
        }
    }

    /// The number of covered addresses when that cardinality fits in `UInt128`.
    public var rangeSizeIfRepresentable: UInt128? {
        switch self {
        case .v4(let range): range.rangeSizeIfRepresentable
        case .v6(let range): range.rangeSizeIfRepresentable
        }
    }

    /// The wrapped IPv4 range, or `nil` when this value stores IPv6.
    public var v4: IPv4AddressRange? {
        guard case .v4(let range) = self else { return nil }
        return range
    }

    /// The wrapped IPv6 range, or `nil` when this value stores IPv4.
    public var v6: IPv6AddressRange? {
        guard case .v6(let range) = self else { return nil }
        return range
    }

    /// Returns whether the family-matching address is inside this range.
    ///
    /// An address from the other family is never contained.
    public func contains(_ address: AnyIPAddress) -> Bool {
        switch (self, address) {
        case (.v4(let range), .v4(let address)):
            range.contains(address)
        case (.v6(let range), .v6(let address)):
            range.contains(address)
        default:
            false
        }
    }

    /// Returns whether the family-matching range is completely inside this range.
    public func contains(_ other: Self) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            lhs.contains(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            lhs.contains(rhs)
        default:
            false
        }
    }

    /// Returns whether two same-family ranges share at least one address.
    public func overlaps(_ other: Self) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            lhs.overlaps(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            lhs.overlaps(rhs)
        default:
            false
        }
    }

    /// Returns whether two same-family ranges touch without overlapping.
    public func isAdjacent(to other: Self) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            lhs.isAdjacent(to: rhs)
        case (.v6(let lhs), .v6(let rhs)):
            lhs.isAdjacent(to: rhs)
        default:
            false
        }
    }

    /// Returns the exact union of two connected same-family ranges.
    ///
    /// The result is `nil` for different families or when a gap separates the ranges.
    public func merged(with other: Self) -> Self? {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            lhs.merged(with: rhs).map(Self.v4)
        case (.v6(let lhs), .v6(let rhs)):
            lhs.merged(with: rhs).map(Self.v6)
        default:
            nil
        }
    }

    /// Coalesces mixed-family ranges, returning sorted IPv4 ranges before sorted IPv6 ranges.
    ///
    /// Coverage is coalesced independently within each family. Different address families never
    /// overlap or become adjacent.
    public static func coalescing<Ranges: Sequence>(_ ranges: Ranges) -> [Self]
    where Ranges.Element == Self {
        var ipv4: [IPv4AddressRange] = []
        var ipv6: [IPv6AddressRange] = []

        for range in ranges {
            switch range {
            case .v4(let range): ipv4.append(range)
            case .v6(let range): ipv6.append(range)
            }
        }

        // Family partitioning makes the erased result deterministic without introducing
        // mixed-family ordering or arithmetic into the family-bound range engine.
        return IPv4AddressRange.coalescing(ipv4).map(Self.v4)
            + IPv6AddressRange.coalescing(ipv6).map(Self.v6)
    }

    /// Summarizes this exact range as canonical family-erased networks.
    public func summarizedNetworks() -> [AnyIPNetwork] {
        switch self {
        case .v4(let range):
            range.summarizedNetworks().map(AnyIPNetwork.v4)
        case .v6(let range):
            range.summarizedNetworks().map(AnyIPNetwork.v6)
        }
    }

    /// The canonical family-specific `lower...upper` representation.
    public var description: String {
        switch self {
        case .v4(let range): range.description
        case .v6(let range): range.description
        }
    }

    /// A diagnostic representation that includes the stored enum case.
    public var debugDescription: String {
        switch self {
        case .v4(let range): "AnyIPAddressRange.v4(\(range.description))"
        case .v6(let range): "AnyIPAddressRange.v6(\(range.description))"
        }
    }

    /// Decodes an IPv4 or IPv6 range from one canonical string.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid mixed-family IP address range '\(description)'."
            )
        }
        self = range
    }

    /// Encodes the wrapped range as one canonical family-specific string.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
