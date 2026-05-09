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
    /// The top-level multicast address space for this address family.
    ///
    /// The returned block is the family-wide container for all valid multicast group destination
    /// identifiers in this address family.
    static var multicastAddressSpace: CIDRBlock<Self> { get }
}

extension AF.V4: MulticastAddressSpace {
    /// The IPv4 multicast address space, `224.0.0.0/4`.
    public static let multicastAddressSpace = CIDRBlock(
        prefix: UInt32(0xE0000000),
        prefixLength: PrefixLength<AF.V4>(4)!
    )
}

extension AF.V6: MulticastAddressSpace {
    /// The IPv6 multicast address space, `ff00::/8`.
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
/// space. The value represents a single group destination, so it requires host-length CIDR context:
/// `/32` for IPv4 and `/128` for IPv6.
///
/// This type is not a subnet and does not expose broadcast, usable-host, default-gateway, or LAN
/// allocation concepts. Use ``IPMulticastGroupRange`` when you need a CIDR range of multicast group
/// destination identifiers.
public struct IPMulticastGroup<Family: MulticastAddressSpace>: Addressable, Hashable, Comparable, CustomStringConvertible, CustomDebugStringConvertible, LosslessStringConvertible, Codable {
    /// The multicast group address.
    ///
    /// This address is guaranteed to be inside the address family's `multicastAddressSpace`.
    public let address: Family.Storage

    /// The host-length prefix context for this multicast group.
    ///
    /// IPv4 multicast groups store `/32`; IPv6 multicast groups store `/128`. A shorter prefix
    /// describes a range and is represented by ``IPMulticastGroupRange`` instead.
    public let prefixLength: PrefixLength<Family>

    /// Creates a multicast group from an address-shaped CIDR value.
    ///
    /// The initializer accepts only host-length addresses inside the family multicast address
    /// space. It rejects ordinary unicast addresses and prefixed ranges such as `239.1.2.1/24`.
    public init?(_ address: IPAddress<Family>) {
        guard address.prefixLength.intValue == Family.bitWidth,
              Family.multicastAddressSpace.contains(address)
        else {
            return nil
        }

        self.address = address.address
        self.prefixLength = address.prefixLength
    }

    /// Creates a multicast group from raw address-family storage.
    ///
    /// The raw address is interpreted with the family host-length prefix context.
    public init?(address: Family.Storage) {
        self.init(IPAddress(address: address))
    }

    /// Parses a multicast group destination identifier from text.
    ///
    /// Address-only text receives host-length context from `IPAddress`. CIDR-qualified text must use
    /// the host length for the family.
    public init?(_ description: String) {
        guard let address = IPAddress<Family>(description) else { return nil }
        self.init(address)
    }

    /// Orders multicast groups by their address bits.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.address < rhs.address
    }

    /// The formatted multicast group address literal.
    public var addressLiteral: String {
        Family.formatAddress(address)
    }

    /// The canonical text for the multicast group.
    ///
    /// Single multicast group descriptions omit `/32` or `/128`; the host-length prefix is implied
    /// by the type.
    public var description: String {
        addressLiteral
    }

    /// A debug representation that includes the concrete multicast group type.
    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }
}

extension IPMulticastGroup {
    /// Decodes a multicast group from canonical string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let group = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) multicast group '\(description)'.")
        }
        self = group
    }

    /// Encodes the multicast group as canonical string text.
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
///
/// The prefix must be aligned to its prefix length, and the entire range must fit inside the
/// family's multicast address space. Registry-specific allocation names and policies are outside
/// this type; this type models the typed CIDR range math.
public struct IPMulticastGroupRange<Family: MulticastAddressSpace>: CIDR, Hashable, LosslessStringConvertible, Codable {
    /// The canonical multicast range prefix.
    ///
    /// Host bits below ``prefixLength`` are required to be clear.
    public let prefix: Family.Storage

    /// The prefix length for the multicast group-address range.
    public let prefixLength: PrefixLength<Family>

    /// The raw storage value used to satisfy `CIDR`.
    ///
    /// For multicast group ranges, `storage` is the canonical range prefix.
    public var storage: Family.Storage {
        prefix
    }

    private var cidrBlock: CIDRBlock<Family> {
        CIDRBlock(prefix: prefix, prefixLength: prefixLength)
    }

    /// Creates a multicast group range from a neutral CIDR block.
    ///
    /// The block must be prefix-aligned and fully contained by the family multicast address space.
    public init?(block: CIDRBlock<Family>) {
        self.init(prefix: block.prefix, prefixLength: block.prefixLength)
    }

    /// Creates a canonical multicast group range from raw prefix bits and prefix length.
    ///
    /// The prefix must already be aligned to `prefixLength`, and the resulting range must be fully
    /// contained by the family multicast address space.
    public init?(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
        let mask = Family.Storage.networkMask(for: prefixLength.intValue)
        guard prefix & mask == prefix else { return nil }

        let candidate = CIDRBlock(prefix: prefix, prefixLength: prefixLength)
        guard Family.multicastAddressSpace.contains(candidate) else { return nil }

        self.prefix = prefix
        self.prefixLength = prefixLength
    }

    /// Parses a multicast group range from CIDR text.
    ///
    /// The text is interpreted as a range of multicast group destination identifiers, not as a
    /// unicast subnet.
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

    /// The first multicast group destination identifier in the range.
    public var firstGroup: IPMulticastGroup<Family> {
        IPMulticastGroup(cidrBlock.firstAddress)!
    }

    /// The last multicast group destination identifier in the range.
    public var lastGroup: IPMulticastGroup<Family> {
        IPMulticastGroup(cidrBlock.lastAddress)!
    }

    /// The number of multicast group destination identifiers in the range, if representable.
    public var rangeSizeIfRepresentable: UInt128? {
        cidrBlock.rangeSizeIfRepresentable
    }

    /// Returns whether this range contains a multicast group.
    public func contains(_ group: IPMulticastGroup<Family>) -> Bool {
        cidrBlock.contains(IPAddress(address: group.address))
    }

    /// Returns whether this range fully contains another multicast group range.
    public func contains(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.contains(range.cidrBlock)
    }

    /// Returns whether this range overlaps another multicast group range.
    public func overlaps(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.overlaps(range.cidrBlock)
    }

    /// Returns whether this range is fully contained by another multicast group range.
    public func isWithin(_ range: IPMulticastGroupRange<Family>) -> Bool {
        cidrBlock.isWithin(range.cidrBlock)
    }

    /// The canonical CIDR text for the multicast group range.
    public var description: String {
        cidrBlock.description
    }

    /// A debug representation that includes the concrete multicast group range type.
    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }
}

extension IPMulticastGroupRange {
    /// Decodes a multicast group range from canonical CIDR string text.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let range = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) multicast group range '\(description)'.")
        }
        self = range
    }

    /// Encodes the multicast group range as canonical CIDR string text.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
