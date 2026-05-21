/// A mixed-family IP address wrapper for public APIs that may carry either IPv4 or IPv6.
///
/// `AnyIPAddress` is intentionally a concrete tagged union rather than an
/// existential. It keeps the family-bound CIDR engine intact while giving
/// boundary APIs one value type for "IPv4 or IPv6".
/// mixed-family addresses can serialize losslessly as their canonical CIDR strings.
public enum AnyIPAddress: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    case v4(IPv4Address)
    case v6(IPv6Address)

    public init(_ address: IPv4Address) {
        self = .v4(address)
    }

    public init(_ address: IPv6Address) {
        self = .v6(address)
    }

    public init?(_ description: String) {
        if let address = IPv4Address(description) {
            self = .v4(address)
            return
        }

        if let address = IPv6Address(description) {
            self = .v6(address)
            return
        }

        return nil
    }

    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    public var addressLiteral: String {
        switch self {
        case .v4(let address):
            return address.addressLiteral
        case .v6(let address):
            return address.addressLiteral
        }
    }

    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let address):
            return .v4(address.prefixLength)
        case .v6(let address):
            return .v6(address.prefixLength)
        }
    }

    public var network: AnyIPNetwork {
        switch self {
        case .v4(let address):
            return .v4(address.network)
        case .v6(let address):
            return .v6(address.network)
        }
    }

    public var v4: IPv4Address? {
        guard case .v4(let address) = self else { return nil }
        return address
    }

    public var v6: IPv6Address? {
        guard case .v6(let address) = self else { return nil }
        return address
    }

    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let address):
            return address.formatted(style)
        case .v6(let address):
            return address.formatted(style)
        }
    }

    public var description: String {
        switch self {
        case .v4(let address):
            return address.description
        case .v6(let address):
            return address.description
        }
    }

    public var debugDescription: String {
        switch self {
        case .v4(let address):
            return "AnyIPAddress.v4(\(address.debugDescription))"
        case .v6(let address):
            return "AnyIPAddress.v6(\(address.debugDescription))"
        }
    }
}

/// A mixed-family network wrapper for public APIs that may carry either IPv4 or IPv6.
/// mixed-family networks can serialize losslessly as their canonical CIDR strings.
public enum AnyIPNetwork: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    case v4(IPv4Network)
    case v6(IPv6Network)

    public init(_ network: IPv4Network) {
        self = .v4(network)
    }

    public init(_ network: IPv6Network) {
        self = .v6(network)
    }

    public init?(_ description: String) {
        if let network = IPv4Network(description) {
            self = .v4(network)
            return
        }

        if let network = IPv6Network(description) {
            self = .v6(network)
            return
        }

        return nil
    }

    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    public var addressLiteral: String {
        switch self {
        case .v4(let network):
            return network.addressLiteral
        case .v6(let network):
            return network.addressLiteral
        }
    }

    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let network):
            return .v4(network.prefixLength)
        case .v6(let network):
            return .v6(network.prefixLength)
        }
    }

    public var first: AnyIPAddress {
        switch self {
        case .v4(let network):
            return .v4(network.first)
        case .v6(let network):
            return .v6(network.first)
        }
    }

    public var last: AnyIPAddress {
        switch self {
        case .v4(let network):
            return .v4(network.last)
        case .v6(let network):
            return .v6(network.last)
        }
    }

    public var nextNetwork: AnyIPNetwork? {
        switch self {
        case .v4(let network):
            return network.nextNetwork.map(AnyIPNetwork.v4)
        case .v6(let network):
            return network.nextNetwork.map(AnyIPNetwork.v6)
        }
    }

    public var v4: IPv4Network? {
        guard case .v4(let network) = self else { return nil }
        return network
    }

    public var v6: IPv6Network? {
        guard case .v6(let network) = self else { return nil }
        return network
    }

    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let network):
            return network.formatted(style)
        case .v6(let network):
            return network.formatted(style)
        }
    }

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

    public var description: String {
        switch self {
        case .v4(let network):
            return network.description
        case .v6(let network):
            return network.description
        }
    }

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
    case v4(IPv4MulticastGroup)
    case v6(IPv6MulticastGroup)

    public init(_ group: IPv4MulticastGroup) {
        self = .v4(group)
    }

    public init(_ group: IPv6MulticastGroup) {
        self = .v6(group)
    }

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

    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    public var addressLiteral: String {
        switch self {
        case .v4(let group):
            return group.addressLiteral
        case .v6(let group):
            return group.addressLiteral
        }
    }

    public var v4: IPv4MulticastGroup? {
        guard case .v4(let group) = self else { return nil }
        return group
    }

    public var v6: IPv6MulticastGroup? {
        guard case .v6(let group) = self else { return nil }
        return group
    }

    public var description: String {
        switch self {
        case .v4(let group):
            return group.description
        case .v6(let group):
            return group.description
        }
    }

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
    case v4(IPv4MulticastGroupRange)
    case v6(IPv6MulticastGroupRange)

    public init(_ range: IPv4MulticastGroupRange) {
        self = .v4(range)
    }

    public init(_ range: IPv6MulticastGroupRange) {
        self = .v6(range)
    }

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

    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    public var addressLiteral: String {
        switch self {
        case .v4(let range):
            return range.addressLiteral
        case .v6(let range):
            return range.addressLiteral
        }
    }

    public var prefixLength: AnyPrefixLength {
        switch self {
        case .v4(let range):
            return .v4(range.prefixLength)
        case .v6(let range):
            return .v6(range.prefixLength)
        }
    }

    public var firstGroup: AnyIPMulticastGroup {
        switch self {
        case .v4(let range):
            return .v4(range.firstGroup)
        case .v6(let range):
            return .v6(range.firstGroup)
        }
    }

    public var lastGroup: AnyIPMulticastGroup {
        switch self {
        case .v4(let range):
            return .v4(range.lastGroup)
        case .v6(let range):
            return .v6(range.lastGroup)
        }
    }

    public var rangeSizeIfRepresentable: UInt128? {
        switch self {
        case .v4(let range):
            return range.rangeSizeIfRepresentable
        case .v6(let range):
            return range.rangeSizeIfRepresentable
        }
    }

    public var v4: IPv4MulticastGroupRange? {
        guard case .v4(let range) = self else { return nil }
        return range
    }

    public var v6: IPv6MulticastGroupRange? {
        guard case .v6(let range) = self else { return nil }
        return range
    }

    public func formatted(_ style: CIDRTextStyle) -> String {
        switch self {
        case .v4(let range):
            return range.formatted(style)
        case .v6(let range):
            return range.formatted(style)
        }
    }

    public func contains(_ group: AnyIPMulticastGroup) -> Bool {
        switch (self, group) {
        case (.v4(let range), .v4(let group)):
            return range.contains(group)
        case (.v6(let range), .v6(let group)):
            return range.contains(group)
        default:
            // CHANGE: Mixed-family multicast containment stays false instead of coercing families.
            return false
        }
    }

    public func contains(_ other: AnyIPMulticastGroupRange) -> Bool {
        switch (self, other) {
        case (.v4(let lhs), .v4(let rhs)):
            return lhs.contains(rhs)
        case (.v6(let lhs), .v6(let rhs)):
            return lhs.contains(rhs)
        default:
            // CHANGE: Multicast range containment is meaningful only within the same address family.
            return false
        }
    }

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

    public var description: String {
        switch self {
        case .v4(let range):
            return range.description
        case .v6(let range):
            return range.description
        }
    }

    public var debugDescription: String {
        switch self {
        case .v4(let range):
            return "AnyIPMulticastGroupRange.v4(\(range.debugDescription))"
        case .v6(let range):
            return "AnyIPMulticastGroupRange.v6(\(range.debugDescription))"
        }
    }
}

/// A mixed-family prefix-length wrapper for public APIs that may carry either IPv4 or IPv6.
public enum AnyPrefixLength: Sendable, Hashable, CustomStringConvertible, Codable { // erased prefixes need an explicit family-preserving Codable shape even though their display text stays family-erasing.
    case v4(IPv4PrefixLength)
    case v6(IPv6PrefixLength)

    public init(_ prefixLength: IPv4PrefixLength) {
        self = .v4(prefixLength)
    }

    public init(_ prefixLength: IPv6PrefixLength) {
        self = .v6(prefixLength)
    }

    public var ianaValue: Int32 {
        switch self {
        case .v4:
            return AF.V4.ianaValue
        case .v6:
            return AF.V6.ianaValue
        }
    }

    public var familyName: String {
        switch self {
        case .v4:
            return AF.V4.familyName
        case .v6:
            return AF.V6.familyName
        }
    }

    public var isIPv4: Bool {
        if case .v4 = self { return true }
        return false
    }

    public var isIPv6: Bool {
        if case .v6 = self { return true }
        return false
    }

    public var rawValue: UInt8 {
        switch self {
        case .v4(let prefixLength):
            return prefixLength.rawValue
        case .v6(let prefixLength):
            return prefixLength.rawValue
        }
    }

    public var intValue: Int {
        switch self {
        case .v4(let prefixLength):
            return prefixLength.intValue
        case .v6(let prefixLength):
            return prefixLength.intValue
        }
    }

    public var v4: IPv4PrefixLength? {
        guard case .v4(let prefixLength) = self else { return nil }
        return prefixLength
    }

    public var v6: IPv6PrefixLength? {
        guard case .v6(let prefixLength) = self else { return nil }
        return prefixLength
    }

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
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = Self(description) else {
            // erased address decoding still delegates to the existing mixed-family parser rather than inventing a second wire grammar.
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family IP address '\(description)'.")
        }
        self = address
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPNetwork {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let network = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family network '\(description)'.")
        }
        self = network
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPMulticastGroup {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let group = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family multicast group '\(description)'.")
        }
        self = group
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension AnyIPMulticastGroupRange {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mixed-family multicast group range '\(description)'.")
        }
        self = range
    }

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
