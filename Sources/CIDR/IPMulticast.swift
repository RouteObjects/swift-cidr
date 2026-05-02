/// An address family that contains a multicast address space.
///
/// IANA defines IPv4 and IPv6 as address families. Multicast is not a separate address family; it
/// is a constrained address space inside those families, with allocation registries maintained by
/// IANA for IPv4 and IPv6 multicast addresses.
///
/// See the IANA [Address Family Numbers](https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml),
/// [IPv4 Multicast Address Space](https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml),
/// and [IPv6 Multicast Address Space](https://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml)
/// registries for the terminology split. See
/// [RFC 6308](https://datatracker.ietf.org/doc/html/rfc6308) for an overview of multicast address
/// allocation and assignment architecture.
public protocol MulticastAddressSpace: AddressFamily {
    /// The top-level multicast address space for this family.
    static var multicastAddressSpace: CIDRBlock<Self> { get }
}

extension AF.V4: MulticastAddressSpace {
    public static let multicastAddressSpace = CIDRBlock(
        prefix: UInt32(0xE0000000),
        prefixLength: PrefixLength<AF.V4>(4)!
    )
}

extension AF.V6: MulticastAddressSpace {
    public static let multicastAddressSpace = CIDRBlock(
        prefix: UInt128(0xFF) << 120,
        prefixLength: PrefixLength<AF.V6>(8)!
    )
}

/// Canonical alias for an IPv4 multicast group destination identifier.
public typealias IPv4MulticastGroup = IPMulticastGroup<V4>

/// Canonical alias for an IPv6 multicast group destination identifier.
public typealias IPv6MulticastGroup = IPMulticastGroup<V6>

/// Canonical alias for an IPv4 multicast group-address range.
public typealias IPv4MulticastGroupRange = IPMulticastGroupRange<V4>

/// Canonical alias for an IPv6 multicast group-address range.
public typealias IPv6MulticastGroupRange = IPMulticastGroupRange<V6>

/// A single multicast group destination identifier.
///
/// `IPMulticastGroup` validates that the stored address is inside the family's multicast address
/// space. It is not a subnet and does not expose broadcast, usable-host, or gateway concepts.
public struct IPMulticastGroup<Family: MulticastAddressSpace>: Addressable, Hashable, Comparable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    public let address: Family.Storage
    public let prefixLength: PrefixLength<Family>

    public init?(_ address: IPAddress<Family>) {
        guard address.prefixLength.intValue == Family.bitWidth,
              Family.multicastAddressSpace.contains(address)
        else {
            return nil
        }

        self.address = address.address
        self.prefixLength = address.prefixLength
    }

    public init?(address: Family.Storage) {
        self.init(IPAddress(address: address))
    }

    public init?(_ description: String) {
        guard let address = IPAddress<Family>(description) else { return nil }
        self.init(address)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.address < rhs.address
    }

    public var addressLiteral: String {
        Family.formatAddress(address)
    }

    public var description: String {
        addressLiteral
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }
}

extension IPMulticastGroup {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let group = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) multicast group '\(description)'.")
        }
        self = group
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// A canonical CIDR range containing multicast group destination identifiers.
///
/// `IPMulticastGroupRange` interprets CIDR notation as group-address range math. A range such as
/// `239.1.2.0/24` contains 256 multicast group identifiers; it is not a LAN subnet with usable
/// hosts or a broadcast address.
public struct IPMulticastGroupRange<Family: MulticastAddressSpace>: CIDR, Hashable, LosslessStringConvertible, Codable {
    public let prefix: Family.Storage
    public let prefixLength: PrefixLength<Family>

    public var storage: Family.Storage {
        prefix
    }

    private var cidrBlock: CIDRBlock<Family> {
        CIDRBlock(prefix: prefix, prefixLength: prefixLength)
    }

    public init?(block: CIDRBlock<Family>) {
        self.init(prefix: block.prefix, prefixLength: block.prefixLength)
    }

    public init?(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
        let mask = Family.Storage.networkMask(for: prefixLength.intValue)
        guard prefix & mask == prefix else { return nil }

        let candidate = CIDRBlock(prefix: prefix, prefixLength: prefixLength)
        guard Family.multicastAddressSpace.contains(candidate) else { return nil }

        self.prefix = prefix
        self.prefixLength = prefixLength
    }

    public init?(_ description: String) {
        let parts = description.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              let prefix = Family.parseAddress(String(parts[0])),
              let prefixLength = PrefixLength<Family>(String(parts[1]))
        else {
            return nil
        }

        self.init(prefix: prefix, prefixLength: prefixLength)
    }

    public var firstGroup: IPMulticastGroup<Family> {
        IPMulticastGroup(cidrBlock.firstAddress)!
    }

    public var lastGroup: IPMulticastGroup<Family> {
        IPMulticastGroup(cidrBlock.lastAddress)!
    }

    public var rangeSizeIfRepresentable: UInt128? {
        cidrBlock.rangeSizeIfRepresentable
    }

    public func contains(_ group: IPMulticastGroup<Family>) -> Bool {
        cidrBlock.contains(IPAddress(address: group.address))
    }

    public func contains(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.contains(range.cidrBlock)
    }

    public func overlaps(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.overlaps(range.cidrBlock)
    }

    public func isWithin(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.isWithin(range.cidrBlock)
    }

    public var description: String {
        cidrBlock.description
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }
}

extension IPMulticastGroupRange {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) multicast group range '\(description)'.")
        }
        self = range
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
