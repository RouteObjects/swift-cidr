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

/// The address-family order used by mixed-family text parsers.
///
/// `AddressFamilyParseOrder` is a performance hint, not a validation rule. Mixed-family wrappers
/// still try both address families before failing; the order only controls which family-specific
/// parser receives the first attempt.
public enum AddressFamilyParseOrder: Sendable, Hashable, Codable {
    /// Try IPv4 first, then IPv6.
    case ipv4ThenIPv6

    /// Try IPv6 first, then IPv4.
    case ipv6ThenIPv4
}

/// A family-erased IP address wrapper that stores either an IPv4 or IPv6 address.
///
/// `AnyIPAddress` is a concrete tagged union rather than an existential. It keeps the
/// family-bound CIDR currency types intact while giving boundary APIs one value type for
/// "IPv4 or IPv6."
///
/// Use this type when the address family is not known until runtime, such as parsing imported text,
/// displaying mixed-family UI rows, serializing user data, or storing mixed-family collections.
/// `AnyIPAddress` does not infer multicast semantics; `AnyIPAddress("239.1.2.3")` is an ordinary
/// IPv4 address wrapper.
public enum AnyIPAddress: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    /// An IPv4 address.
    case v4(IPv4Address)

    /// An IPv6 address.
    case v6(IPv6Address)

    /// Wraps an IPv4 address.
    public init(_ address: IPv4Address) {
        self = .v4(address)
    }

    /// Wraps an IPv6 address.
    public init(_ address: IPv6Address) {
        self = .v6(address)
    }

    /// Parses a mixed-family address from canonical or accepted address text.
    ///
    /// This initializer satisfies `LosslessStringConvertible` and uses the default IPv4-then-IPv6
    /// parse order.
    public init?(_ description: String) {
        self.init(description, parseOrder: .ipv4ThenIPv6)
    }

    /// Parses a mixed-family address using the requested family parse order.
    ///
    /// The parse order is only a performance hint for workloads that know which family is likely to
    /// appear first. Both families are still attempted before this initializer returns `nil`.
    public init?(_ description: String, parseOrder: AddressFamilyParseOrder = .ipv4ThenIPv6) {
        switch parseOrder {
        case .ipv4ThenIPv6:
            if let address = IPv4Address(description) {
                self = .v4(address)
                return
            }

            if let address = IPv6Address(description) {
                self = .v6(address)
                return
            }
        case .ipv6ThenIPv4:
            if let address = IPv6Address(description) {
                self = .v6(address)
                return
            }

            if let address = IPv4Address(description) {
                self = .v4(address)
                return
            }
        }

        return nil
    }

    /// The IANA address-family number for the wrapped address.
    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    /// The human-readable address-family name for the wrapped address.
    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    /// A Boolean value indicating whether the wrapper stores an IPv4 address.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether the wrapper stores an IPv6 address.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The formatted address literal without CIDR prefix notation.
    public var addressLiteral: String {
        switch self {
        case .v4(let address):
            return address.addressLiteral
        case .v6(let address):
            return address.addressLiteral
        }
    }

    /// The wrapped address's family-erased prefix length.
    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let address):
            return .v4(address.prefixLength)
        case .v6(let address):
            return .v6(address.prefixLength)
        }
    }

    /// The family-erased network containing the wrapped address.
    public var network: AnyIPNetwork {
        switch self {
        case .v4(let address):
            return .v4(address.network)
        case .v6(let address):
            return .v6(address.network)
        }
    }

    /// The wrapped IPv4 address, or `nil` when this value stores IPv6.
    public var v4: IPv4Address? {
        guard case .v4(let address) = self else { return nil }
        return address
    }

    /// The wrapped IPv6 address, or `nil` when this value stores IPv4.
    public var v6: IPv6Address? {
        guard case .v6(let address) = self else { return nil }
        return address
    }

    /// Formats the wrapped address using the requested text style.
    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let address):
            return address.formatted(style)
        case .v6(let address):
            return address.formatted(style)
        }
    }

    /// The canonical CIDR text for the wrapped address.
    public var description: String {
        switch self {
        case .v4(let address):
            return address.description
        case .v6(let address):
            return address.description
        }
    }

    /// A debug representation that includes the erased family case.
    public var debugDescription: String {
        switch self {
        case .v4(let address):
            return "AnyIPAddress.v4(\(address.debugDescription))"
        case .v6(let address):
            return "AnyIPAddress.v6(\(address.debugDescription))"
        }
    }
}

/// A family-erased IP network wrapper that stores either an IPv4 or IPv6 network.
///
/// `AnyIPNetwork` is a concrete tagged union for APIs that accept "IPv4 network or IPv6 network"
/// while preserving the family-bound `IPNetwork` value inside. Mixed-family networks serialize
/// losslessly as canonical CIDR strings.
public enum AnyIPNetwork: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    /// An IPv4 network.
    case v4(IPv4Network)

    /// An IPv6 network.
    case v6(IPv6Network)

    /// Wraps an IPv4 network.
    public init(_ network: IPv4Network) {
        self = .v4(network)
    }

    /// Wraps an IPv6 network.
    public init(_ network: IPv6Network) {
        self = .v6(network)
    }

    /// Parses a mixed-family network from CIDR text.
    ///
    /// This initializer satisfies `LosslessStringConvertible` and uses the default IPv4-then-IPv6
    /// parse order.
    public init?(_ description: String) {
        self.init(description, parseOrder: .ipv4ThenIPv6)
    }

    /// Parses a mixed-family network using the requested family parse order.
    ///
    /// The parse order is only a performance hint. Both families are still attempted before this
    /// initializer returns `nil`.
    public init?(_ description: String, parseOrder: AddressFamilyParseOrder = .ipv4ThenIPv6) {
        switch parseOrder {
        case .ipv4ThenIPv6:
            if let network = IPv4Network(description) {
                self = .v4(network)
                return
            }

            if let network = IPv6Network(description) {
                self = .v6(network)
                return
            }
        case .ipv6ThenIPv4:
            if let network = IPv6Network(description) {
                self = .v6(network)
                return
            }

            if let network = IPv4Network(description) {
                self = .v4(network)
                return
            }
        }

        return nil
    }

    /// The IANA address-family number for the wrapped network.
    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    /// The human-readable address-family name for the wrapped network.
    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    /// A Boolean value indicating whether the wrapper stores an IPv4 network.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether the wrapper stores an IPv6 network.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The formatted network prefix literal without CIDR prefix notation.
    public var addressLiteral: String {
        switch self {
        case .v4(let network):
            return network.addressLiteral
        case .v6(let network):
            return network.addressLiteral
        }
    }

    /// The wrapped network's family-erased prefix length.
    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let network):
            return .v4(network.prefixLength)
        case .v6(let network):
            return .v6(network.prefixLength)
        }
    }

    /// The first address in the wrapped network.
    public var first: AnyIPAddress {
        switch self {
        case .v4(let network):
            return .v4(network.first)
        case .v6(let network):
            return .v6(network.first)
        }
    }

    /// The last address in the wrapped network.
    public var last: AnyIPAddress {
        switch self {
        case .v4(let network):
            return .v4(network.last)
        case .v6(let network):
            return .v6(network.last)
        }
    }

    /// The next adjacent network with the same prefix length, if representable.
    public var nextNetwork: AnyIPNetwork? {
        switch self {
        case .v4(let network):
            return network.nextNetwork.map(AnyIPNetwork.v4)
        case .v6(let network):
            return network.nextNetwork.map(AnyIPNetwork.v6)
        }
    }

    /// The wrapped IPv4 network, or `nil` when this value stores IPv6.
    public var v4: IPv4Network? {
        guard case .v4(let network) = self else { return nil }
        return network
    }

    /// The wrapped IPv6 network, or `nil` when this value stores IPv4.
    public var v6: IPv6Network? {
        guard case .v6(let network) = self else { return nil }
        return network
    }

    /// Formats the wrapped network using the requested text style.
    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let network):
            return network.formatted(style)
        case .v6(let network):
            return network.formatted(style)
        }
    }

    /// Returns whether this network contains the supplied address.
    ///
    /// Containment is meaningful only within the same address family. Mixed-family comparisons
    /// return `false`.
    public func contains(_ address: AnyIPAddress) -> Bool {
        switch (self, address) {
        case (.v4(let network), .v4(let address)):
            return network.contains(address)
        case (.v6(let network), .v6(let address)):
            return network.contains(address)
        default:
            // mixed-family containment is always false instead of trying to coerce between unrelated address families.
            return false
        }
    }

    /// Returns whether this network fully contains another network.
    ///
    /// Containment is meaningful only within the same address family. Mixed-family comparisons
    /// return `false`.
    public func contains(_ other: AnyIPNetwork) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            return lhs.contains(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            return lhs.contains(rhs)
        default:
            // family-erased wrapper APIs keep family mismatch explicit rather than silently widening semantics.
            return false
        }
    }

    /// The canonical CIDR text for the wrapped network.
    public var description: String {
        switch self {
        case .v4(let network):
            return network.description
        case .v6(let network):
            return network.description
        }
    }

    /// A debug representation that includes the erased family case.
    public var debugDescription: String {
        switch self {
        case .v4(let network):
            return "AnyIPNetwork.v4(\(network.debugDescription))"
        case .v6(let network):
            return "AnyIPNetwork.v6(\(network.debugDescription))"
        }
    }
}

/// A mixed-family multicast group wrapper for public APIs that may carry either IPv4 or IPv6.
///
/// `AnyIPMulticastGroup` preserves multicast group semantics while erasing only the address family.
/// Use this type when an input must be validated as a multicast group destination identifier rather
/// than accepted as an ordinary IP address.
public enum AnyIPMulticastGroup: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    /// An IPv4 multicast group destination identifier.
    case v4(IPv4MulticastGroup)

    /// An IPv6 multicast group destination identifier.
    case v6(IPv6MulticastGroup)

    /// Wraps an IPv4 multicast group.
    public init(_ group: IPv4MulticastGroup) {
        self = .v4(group)
    }

    /// Wraps an IPv6 multicast group.
    public init(_ group: IPv6MulticastGroup) {
        self = .v6(group)
    }

    /// Parses a mixed-family multicast group destination identifier.
    ///
    /// The input must be a multicast group address, not ordinary unicast address text and not CIDR
    /// range text.
    public init?(_ description: String) {
        if let group = IPv4MulticastGroup(description) {
            self = .v4(group)
            return
        }

        if let group = IPv6MulticastGroup(description) {
            self = .v6(group)
            return
        }

        return nil
    }

    /// The IANA address-family number for the wrapped multicast group.
    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    /// The human-readable address-family name for the wrapped multicast group.
    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    /// A Boolean value indicating whether the wrapper stores an IPv4 multicast group.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether the wrapper stores an IPv6 multicast group.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The formatted multicast group address literal.
    public var addressLiteral: String {
        switch self {
        case .v4(let group):
            return group.addressLiteral
        case .v6(let group):
            return group.addressLiteral
        }
    }

    /// The wrapped IPv4 multicast group, or `nil` when this value stores IPv6.
    public var v4: IPv4MulticastGroup? {
        guard case .v4(let group) = self else { return nil }
        return group
    }

    /// The wrapped IPv6 multicast group, or `nil` when this value stores IPv4.
    public var v6: IPv6MulticastGroup? {
        guard case .v6(let group) = self else { return nil }
        return group
    }

    /// The canonical text for the wrapped multicast group.
    public var description: String {
        switch self {
        case .v4(let group):
            return group.description
        case .v6(let group):
            return group.description
        }
    }

    /// A debug representation that includes the erased family case.
    public var debugDescription: String {
        switch self {
        case .v4(let group):
            return "AnyIPMulticastGroup.v4(\(group.debugDescription))"
        case .v6(let group):
            return "AnyIPMulticastGroup.v6(\(group.debugDescription))"
        }
    }
}

/// A mixed-family multicast group-range wrapper for public APIs that may carry either IPv4 or IPv6.
///
/// `AnyIPMulticastGroupRange` preserves multicast group-range semantics while erasing only the
/// address family. Use this type when CIDR-looking input must be interpreted as multicast
/// group-address range math rather than ordinary `IPNetwork` subnet semantics.
public enum AnyIPMulticastGroupRange: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    /// An IPv4 multicast group-address range.
    case v4(IPv4MulticastGroupRange)

    /// An IPv6 multicast group-address range.
    case v6(IPv6MulticastGroupRange)

    /// Wraps an IPv4 multicast group-address range.
    public init(_ range: IPv4MulticastGroupRange) {
        self = .v4(range)
    }

    /// Wraps an IPv6 multicast group-address range.
    public init(_ range: IPv6MulticastGroupRange) {
        self = .v6(range)
    }

    /// Parses a mixed-family multicast group-address range from CIDR text.
    ///
    /// The input is interpreted as multicast group-range math, not unicast subnet semantics.
    public init?(_ description: String) {
        if let range = IPv4MulticastGroupRange(description) {
            self = .v4(range)
            return
        }

        if let range = IPv6MulticastGroupRange(description) {
            self = .v6(range)
            return
        }

        return nil
    }

    /// The IANA address-family number for the wrapped multicast range.
    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    /// The human-readable address-family name for the wrapped multicast range.
    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    /// A Boolean value indicating whether the wrapper stores an IPv4 multicast range.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether the wrapper stores an IPv6 multicast range.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The formatted multicast range prefix literal without CIDR prefix notation.
    public var addressLiteral: String {
        switch self {
        case .v4(let range):
            return range.addressLiteral
        case .v6(let range):
            return range.addressLiteral
        }
    }

    /// The wrapped multicast range's family-erased prefix length.
    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let range):
            return .v4(range.prefixLength)
        case .v6(let range):
            return .v6(range.prefixLength)
        }
    }

    /// The first multicast group address in the wrapped range.
    public var firstGroup: AnyIPMulticastGroup {
        switch self {
        case .v4(let range):
            return .v4(range.firstGroup)
        case .v6(let range):
            return .v6(range.firstGroup)
        }
    }

    /// The last multicast group address in the wrapped range.
    public var lastGroup: AnyIPMulticastGroup {
        switch self {
        case .v4(let range):
            return .v4(range.lastGroup)
        case .v6(let range):
            return .v6(range.lastGroup)
        }
    }

    /// The number of multicast group addresses in the wrapped range, if representable.
    public var rangeSizeIfRepresentable: UInt128? {
        switch self {
        case .v4(let range):
            return range.rangeSizeIfRepresentable
        case .v6(let range):
            return range.rangeSizeIfRepresentable
        }
    }

    /// The wrapped IPv4 multicast range, or `nil` when this value stores IPv6.
    public var v4: IPv4MulticastGroupRange? {
        guard case .v4(let range) = self else { return nil }
        return range
    }

    /// The wrapped IPv6 multicast range, or `nil` when this value stores IPv4.
    public var v6: IPv6MulticastGroupRange? {
        guard case .v6(let range) = self else { return nil }
        return range
    }

    /// Formats the wrapped multicast range using the requested text style.
    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let range):
            return range.formatted(style)
        case .v6(let range):
            return range.formatted(style)
        }
    }

    /// Returns whether this multicast range contains the supplied multicast group.
    ///
    /// Containment is meaningful only within the same address family. Mixed-family comparisons
    /// return `false`.
    public func contains(_ group: AnyIPMulticastGroup) -> Bool {
        switch (self, group) {
        case (.v4(let range), .v4(let group)):
            return range.contains(group)
        case (.v6(let range), .v6(let group)):
            return range.contains(group)
        default:
            // Mixed-family multicast containment stays false instead of coercing families.
            return false
        }
    }

    /// Returns whether this multicast range fully contains another multicast range.
    ///
    /// Containment is meaningful only within the same address family. Mixed-family comparisons
    /// return `false`.
    public func contains(_ other: AnyIPMulticastGroupRange) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            return lhs.contains(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            return lhs.contains(rhs)
        default:
            // Multicast range containment is meaningful only within the same address family.
            return false
        }
    }

    /// Returns whether this multicast range overlaps another multicast range.
    ///
    /// Overlap is meaningful only within the same address family. Mixed-family comparisons return
    /// `false`.
    public func overlaps(_ other: AnyIPMulticastGroupRange) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            return lhs.overlaps(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            return lhs.overlaps(rhs)
        default:
            return false
        }
    }

    /// Returns whether this multicast range is fully contained by another multicast range.
    ///
    /// The relationship is meaningful only within the same address family. Mixed-family comparisons
    /// return `false`.
    public func isWithin(_ other: AnyIPMulticastGroupRange) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            return lhs.isWithin(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            return lhs.isWithin(rhs)
        default:
            return false
        }
    }

    /// The canonical CIDR text for the wrapped multicast range.
    public var description: String {
        switch self {
        case .v4(let range):
            return range.description
        case .v6(let range):
            return range.description
        }
    }

    /// A debug representation that includes the erased family case.
    public var debugDescription: String {
        switch self {
        case .v4(let range):
            return "AnyIPMulticastGroupRange.v4(\(range.debugDescription))"
        case .v6(let range):
            return "AnyIPMulticastGroupRange.v6(\(range.debugDescription))"
        }
    }
}

/// A family-erased prefix-length wrapper that stores either an IPv4 or IPv6 prefix length.
///
/// `AnyPrefixLength` preserves the address family because the text `"24"` alone cannot say whether
/// it means IPv4 `/24` or IPv6 `/24`. The display text stays family-erasing, but Codable uses an
/// explicit tagged object to preserve the family.
public enum AnyPrefixLength: Sendable, Hashable, CustomStringConvertible, Codable {
    /// An IPv4 prefix length.
    case v4(IPv4PrefixLength)

    /// An IPv6 prefix length.
    case v6(IPv6PrefixLength)

    /// Wraps an IPv4 prefix length.
    public init(_ prefixLength: IPv4PrefixLength) {
        self = .v4(prefixLength)
    }

    /// Wraps an IPv6 prefix length.
    public init(_ prefixLength: IPv6PrefixLength) {
        self = .v6(prefixLength)
    }

    /// The IANA address-family number for the wrapped prefix length.
    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    /// The human-readable address-family name for the wrapped prefix length.
    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    /// A Boolean value indicating whether the wrapper stores an IPv4 prefix length.
    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    /// A Boolean value indicating whether the wrapper stores an IPv6 prefix length.
    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    /// The validated slash number stored by the wrapped prefix length.
    public var rawValue: UInt8 {
        switch self {
        case .v4(let prefixLength):
            return prefixLength.rawValue
        case .v6(let prefixLength):
            return prefixLength.rawValue
        }
    }

    /// The wrapped prefix length as an `Int`.
    public var intValue: Int {
        switch self {
        case .v4(let prefixLength):
            return prefixLength.intValue
        case .v6(let prefixLength):
            return prefixLength.intValue
        }
    }

    /// The wrapped IPv4 prefix length, or `nil` when this value stores IPv6.
    public var v4: IPv4PrefixLength? {
        guard case .v4(let prefixLength) = self else { return nil }
        return prefixLength
    }

    /// The wrapped IPv6 prefix length, or `nil` when this value stores IPv4.
    public var v6: IPv6PrefixLength? {
        guard case .v6(let prefixLength) = self else { return nil }
        return prefixLength
    }

    /// Decimal text for the wrapped prefix length without the slash or family.
    public var description: String {
        switch self {
        case .v4(let prefixLength):
            return prefixLength.description
        case .v6(let prefixLength):
            return prefixLength.description
        }
    }
}

private enum AnyIPCodableFamily: String, Codable {
    case ipv4
    case ipv6
}

extension AnyIPAddress {
    /// Decodes a mixed-family address from canonical CIDR string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = Self(description) else {
            // erased address decoding still delegates to the existing mixed-family parser rather than inventing a second wire grammar.
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family IP address '\(description)'.")
        }
        self = address
    }

    /// Encodes the wrapped address as canonical CIDR string text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPNetwork {
    /// Decodes a mixed-family network from canonical CIDR string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let network = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family network '\(description)'.")
        }
        self = network
    }

    /// Encodes the wrapped network as canonical CIDR string text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPMulticastGroup {
    /// Decodes a mixed-family multicast group from canonical string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let group = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family multicast group '\(description)'.")
        }
        self = group
    }

    /// Encodes the wrapped multicast group as canonical string text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPMulticastGroupRange {
    /// Decodes a mixed-family multicast group-address range from canonical CIDR string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family multicast group range '\(description)'.")
        }
        self = range
    }

    /// Encodes the wrapped multicast group-address range as canonical CIDR string text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyPrefixLength {
    private enum CodingKeys: String, CodingKey {
        case family
        case prefixLength
    }

    /// Decodes a family-erased prefix length from a tagged object.
    ///
    /// The expected shape is `{ "family": "ipv4" | "ipv6", "prefixLength": number }`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let family = try container.decode(AnyIPCodableFamily.self, forKey: .family)
        let rawValue = try container.decode(Int.self, forKey: .prefixLength)

        switch family {
        case .ipv4:
            guard let prefixLength = IPv4PrefixLength(rawValue) else {
                // erased-prefix decoding validates the prefix against the declared family before constructing the wrapper.
                throw DecodingError.dataCorruptedError(forKey: .prefixLength, in: container, debugDescription: "Invalid IPv4 prefix length \(rawValue).")
            }
            self = .v4(prefixLength)
        case .ipv6:
            guard let prefixLength = IPv6PrefixLength(rawValue) else {
                throw DecodingError.dataCorruptedError(forKey: .prefixLength, in: container, debugDescription: "Invalid IPv6 prefix length \(rawValue).")
            }
            self = .v6(prefixLength)
        }
    }

    /// Encodes the prefix length as a tagged object that preserves the address family.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .v4(let prefixLength):
            try container.encode(AnyIPCodableFamily.ipv4, forKey: .family)
            try container.encode(prefixLength.intValue, forKey: .prefixLength)
        case .v6(let prefixLength):
            try container.encode(AnyIPCodableFamily.ipv6, forKey: .family)
            try container.encode(prefixLength.intValue, forKey: .prefixLength)
        }
    }
}
