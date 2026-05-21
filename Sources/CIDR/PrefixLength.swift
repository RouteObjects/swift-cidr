/// PrefixLength<Family> is the safe, typed version of the number after the slash in CIDR notation.
///   - stores that slash number as a real domain type instead of a loose Int
///   - validates the number for the address family
///   - keeps IPv4 and IPv6 prefix lengths from being mixed accidentally

/// Canonical alias for an IPv4 prefix length in the family-bound CIDR engine.
public typealias IPv4PrefixLength = PrefixLength<V4>

/// Canonical alias for an IPv6 prefix length in the family-bound CIDR engine.
public typealias IPv6PrefixLength = PrefixLength<V6>

/// A validated CIDR prefix length bound to a specific address family.
public struct PrefixLength<Family: AddressFamily>: RawRepresentable, Sendable, Hashable, Comparable, CustomStringConvertible, LosslessStringConvertible, Codable {
    public let rawValue: UInt8

    public init?(rawValue: UInt8) {
        guard Int(rawValue) <= Family.bitWidth else { return nil }
        self.rawValue = rawValue
    }

    public init?(_ value: Int) {
        guard value >= 0,
              value <= Family.bitWidth,
              let rawValue = UInt8(exactly: value)
        else {
            return nil
        }

        self.rawValue = rawValue
    }

    public init?(_ description: String) {
        guard let value = Int(description) else { return nil }
        self.init(value)
    }

    @inline(__always)
    public var intValue: Int {
        Int(rawValue)
    }

    public var description: String {
        "\(rawValue)"
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension PrefixLength {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        guard let prefixLength = Self(value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) prefix length \(value).")
        }
        self = prefixLength
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(intValue)
    }
}
