/// A family-bound Classless Inter-Domain Routing (CIDR) value with stored bits and prefix length.
///
/// `CIDR` is the broad structural protocol for IP values that participate in the CIDR model
/// described in [RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632). It covers both
/// host-oriented values that carry prefix context and canonical aligned prefixes.
///
/// `block` is the generic CIDR term shared across address, network, and interface contexts. For
/// host-oriented types, it may contain host bits and is not required to be network-aligned.
public protocol CIDR: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Family: AddressFamily

    /// The stored address bits for this CIDR value.
    var block: Family.Storage { get }

    /// The prefix length that gives the stored bits their CIDR context.
    var prefixLength: PrefixLength<Family> { get }

    /// Formats the value using a requested presentation style.
    func formatted(_ style: CIDRTextStyle) -> String
}

public extension CIDR {
    @inline(__always)
    var prefixBits: Int {
        prefixLength.intValue
    }

    var mask: Family.Storage { Family.Storage.networkMask(for: prefixBits) }
    var inverseMask: Family.Storage { ~mask }
    
    var first: IPAddress<Family> { IPAddress(address: block & mask) }
    var last: IPAddress<Family> { IPAddress(address: block | inverseMask) }
    var range: ClosedRange<IPAddress<Family>> { first...last }

    var addressLiteral: String {
        Family.formatAddress(block)
    }

    var description: String {
        "\(addressLiteral)/\(prefixLength)"
    }

    var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }

    func formatted(_ style: CIDRTextStyle) -> String {
        switch style {
        case .cidrNotation:
            return description
        case .addressOnly:
            return addressLiteral
        }
    }
}

public extension CIDR where Family == AF.V4 {
    func formatted(_ style: IPv4TextStyle) -> String {
        switch style {
        case .addressAndNetmask:
            let v4Mask = UInt32.networkMask(for: prefixBits)
            return "\(addressLiteral) \(AF.formatV4(v4Mask))"
        }
    }
}

public extension CIDR where Family == AF.V6 {
    func formatted(_ style: IPv6TextStyle) -> String {
        switch style {
        case .preferred:
            return addressLiteral
        case .ipv4Mapped:
            return AF.formatV6Mapped(block) ?? addressLiteral
        case .compressed:
            return AF.formatV6Compressed(block)
        }
    }
}
