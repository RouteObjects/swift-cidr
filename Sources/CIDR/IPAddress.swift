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
    associatedtype Family: AddressFamily

    /// The raw address bits for this value's address family.
    var address: Family.Storage { get }
}

/// Canonical alias for an IPv4 address in the family-bound CIDR engine.
public typealias IPv4Address = IPAddress<V4>

/// Canonical alias for an IPv6 address in the family-bound CIDR engine.
public typealias IPv6Address = IPAddress<V6>

/// Family-bound IP address value with a stable canonical CIDR text representation.
public struct IPAddress<Family: AddressFamily>: Addressable, CIDR, Hashable, Comparable, LosslessStringConvertible, Codable {
    public let address: Family.Storage
    public let prefixLength: PrefixLength<Family>

    public var block: Family.Storage { address }

    public init(address: Family.Storage, prefixLength: PrefixLength<Family>) {
        self.address = address
        self.prefixLength = prefixLength
    }

    public init(address: Family.Storage) {
        self.init(address: address, prefixLength: PrefixLength<Family>(Family.bitWidth)!)
    }

    public var network: IPNetwork<Family> {
        IPNetwork(host: self)
    }

    public static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        lhs.address == rhs.address
        ? lhs.prefixLength < rhs.prefixLength
        : lhs.address < rhs.address
    }
}

extension IPAddress {
    public init?(_ string: String) {
        let parts = string.split(separator: "/", omittingEmptySubsequences: false)
        switch parts.count {
        case 1:
            guard let val = Family.parseAddress(string) else { return nil }
            self.init(address: val)
        case 2:
            guard !parts[0].isEmpty, !parts[1].isEmpty else { return nil }
            guard let rawPrefix = Int(parts[1]),
                  let prefixLength = PrefixLength<Family>(rawPrefix),
                  let val = Family.parseAddress(String(parts[0]))
            else { return nil }
            self.init(address: val, prefixLength: prefixLength)
        default:
            return nil
        }
    }
}

extension IPAddress {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) address '\(description)'.")
        }
        self = address
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension IPAddress: Strideable {
    public typealias Stride = Int128

    public func distanceIfRepresentable(to other: IPAddress) -> Int128? {
        let lhs = UInt128(exactly: self.address)!, rhs = UInt128(exactly: other.address)!
        if rhs >= lhs {
            return Int128(exactly: rhs - lhs)
        }
        let magnitude = lhs - rhs
        if let positive = Int128(exactly: magnitude) { return -positive }
        let minMagnitude = UInt128(exactly: Int128.max)! + 1
        guard magnitude == minMagnitude else { return nil }
        return Int128.min
    }

    public func advancedIfRepresentable(by n: Int128) -> IPAddress? {
        if n >= 0 {
            let magnitude = UInt128(exactly: n)!
            guard let step = Family.Storage(exactly: magnitude) else { return nil }
            let (next, overflow) = address.addingReportingOverflow(step)
            guard !overflow else { return nil }
            return IPAddress(address: next, prefixLength: prefixLength)
        }
        let magnitude = n == Int128.min ? (UInt128(exactly: Int128.max)! + 1) : UInt128(exactly: -n)!
        guard let step = Family.Storage(exactly: magnitude) else { return nil }
        let (next, overflow) = address.subtractingReportingOverflow(step)
        guard !overflow else { return nil }
        return IPAddress(address: next, prefixLength: prefixLength)
    }

    public func distance(to other: IPAddress) -> Int128 {
        guard let distance = distanceIfRepresentable(to: other) else { preconditionFailure("Exceeds Int128 range.") }
        return distance
    }

    public func advanced(by n: Int128) -> IPAddress {
        guard let advanced = advancedIfRepresentable(by: n) else { preconditionFailure("Overflow/Underflow range.") }
        return advanced
    }
}

extension IPAddress {
    public static func v4(_ string: String) -> IPAddress<AF.V4>? { IPAddress<AF.V4>(string) }
    public static func v6(_ string: String) -> IPAddress<AF.V6>? { IPAddress<AF.V6>(string) }
}
