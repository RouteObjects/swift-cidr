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

/// Canonical alias for an IPv4 network in the family-bound CIDR engine.
public typealias IPv4Network = IPNetwork<V4>

/// Canonical alias for an IPv6 network in the family-bound CIDR engine.
public typealias IPv6Network = IPNetwork<V6>

/// A family-bound, prefix-aligned IP network boundary.
///
/// `IPNetwork` is the concrete `IPPrefix` type for ordinary unicast-style network prefixes. It
/// stores a canonical prefix boundary: any host bits below `prefixLength` are cleared during
/// initialization.
///
/// A network value describes CIDR prefix math, not operational routing state. A prefix may later be
/// installed in a routing table, advertised by BGP, assigned to an interface context, or referenced
/// by policy, but those are higher-layer interpretations built on top of this boundary value.
///
/// By conforming to `IPPrefix`, `IPNetwork` gets the shared aligned-prefix operations such as
/// containment, subnet traversal, next-prefix calculation, and summarization.
public struct IPNetwork<Family: IPAddressFamily>: IPPrefix, Hashable, LosslessStringConvertible, Codable {
    /// The canonical prefix boundary for this network.
    ///
    /// The stored value is always masked by `prefixLength`, so host bits below the prefix boundary
    /// are zero.
    public let prefix: Family.Storage

    /// The number of leading bits that identify the network prefix.
    public let prefixLength: PrefixLength<Family>

    /// Creates a canonical network from raw prefix bits and a prefix length.
    ///
    /// Any host bits present in `prefix` are cleared before storage. This makes
    /// `IPNetwork(prefix: 192.0.2.77, prefixLength: 24)` equivalent to `192.0.2.0/24`.
    public init(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
        self.prefix = prefix & Family.Storage.networkMask(for: prefixLength.intValue)
        self.prefixLength = prefixLength
    }

    /// Creates a canonical network from an address and raw prefix-length value.
    ///
    /// Returns `nil` when `rawValue` is outside the valid prefix range for `Family`.
    public init?(address: IPAddress<Family>, prefixLength rawValue: UInt8) {
        guard let prefix = PrefixLength<Family>(rawValue: rawValue) else { return nil }
        self.init(address: address, prefixLength: prefix)
    }

    /// Creates the network that contains a CIDR-qualified address.
    ///
    /// The address value supplies both the address bits and the prefix context. The resulting
    /// network is the canonical boundary containing that address.
    public init(host address: IPAddress<Family>) {
        self.init(address: address, prefixLength: address.prefixLength)
    }
}

extension IPNetwork {
    @inlinable
    @inline(__always)
    public var storage: Family.Storage {
        prefix
    }

    @inlinable
    @inline(__always)
    public var addressLiteral: String {
        Family.formatAddress(prefix)
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

public extension IPNetwork where Family == AF.V4 {
    /// Creates an IPv4 network from address text and dotted-decimal netmask text.
    ///
    /// This initializer accepts vendor-friendly IPv4 configuration notation such as
    /// `address: "192.0.2.77", netmask: "255.255.255.0"` and canonicalizes the result to
    /// `192.0.2.0/24`.
    init?(address: String, netmask: String) {
        guard let address = IPAddress<Family>(address),
              let rawLength = AF.V4.prefixLength(fromNetmask: netmask),
              let prefixLength = PrefixLength<Family>(rawLength)
        else {
            return nil
        }

        self.init(address: address, prefixLength: prefixLength)
    }

    @inlinable
    @inline(__always)
    var description: String {
        AF.formatV4CIDR(address: prefix, prefixLength: prefixLength.rawValue)
    }

    @inlinable
    @inline(__always)
    func formatted(_ style: CIDRTextStyle) -> String {
        switch style {
        case .cidrNotation:
            return AF.formatV4CIDR(address: prefix, prefixLength: prefixLength.rawValue)
        case .addressOnly:
            return addressLiteral
        }
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

public extension IPNetwork where Family == AF.V6 {
    @inlinable
    @inline(__always)
    var description: String {
        _compressedCIDRNotationDescription()
    }

    @inlinable
    @inline(__always)
    func formatted(_ style: CIDRTextStyle) -> String {
        switch style {
        case .cidrNotation:
            return _compressedCIDRNotationDescription()
        case .addressOnly:
            return addressLiteral
        }
    }

    @inline(__always)
    func formatted(_ style: IPv6TextStyle) -> String {
        switch style {
        case .preferred:
            return AF.formatV6(prefix)
        case .ipv4Mapped:
            return AF.formatV6Mapped(prefix) ?? addressLiteral
        case .compressed:
            return AF.formatV6Compressed(prefix)
        }
    }
}

extension IPNetwork {
    /// Creates a canonical network from CIDR notation.
    ///
    /// The address portion may include host bits; the resulting `IPNetwork` stores the canonical
    /// prefix boundary.
    public init?(_ string: String) {
        guard let slashIndex = string.firstIndex(of: "/") else {
            return nil
        }

        let prefixStart = string.index(after: slashIndex)
        let addressText = string[..<slashIndex]
        let prefixText = string[prefixStart...]

        guard !addressText.isEmpty,
              !prefixText.isEmpty,
              prefixText.firstIndex(of: "/") == nil,
              let rawPrefix = Int(prefixText),
              let prefixLength = PrefixLength<Family>(rawPrefix),
              let prefix = Family.parseAddress(String(addressText))
        else {
            return nil
        }

        self.init(prefix: prefix, prefixLength: prefixLength)
    }

    /// Creates a canonical IPv4 network from CIDR notation using the IPv4 CIDR suffix scanner.
    public init?(_ string: String) where Family == AF.V4 {
        guard let result = AF.parseIPv4CIDRTextSuffix(string, requiresPrefix: true),
              let prefixLength = PrefixLength<Family>(rawValue: result.prefixLength)
        else {
            return nil
        }

        self.init(prefix: result.address, prefixLength: prefixLength)
    }

    /// Creates a canonical IPv6 network from CIDR notation using the IPv6 CIDR suffix scanner.
    public init?(_ string: String) where Family == AF.V6 {
        guard let result = AF.parseIPv6CIDRTextSuffix(string, requiresPrefix: true),
              let prefixLength = PrefixLength<Family>(rawValue: result.prefixLength)
        else {
            return nil
        }

        self.init(prefix: result.address, prefixLength: prefixLength)
    }

    /// Creates a canonical network from CIDR notation only when it is contained by a parent block.
    ///
    /// Use this initializer when the caller already has a neutral `CIDRBlock` representing a
    /// delegation, allocation, or other parent range and wants construction to fail unless the
    /// requested network fits inside that range.
    ///
    /// The containment check is intentionally limited to CIDR math. It does not prove that the
    /// parent exists in a database, that the child has been allocated, that the child does not
    /// overlap another assignment, or that assigning the exact parent block is allowed by local
    /// policy.
    public init?(_ description: String, within parent: CIDRBlock<Family>) {
        guard let network = Self(description),
              parent.contains(network)
        else {
            return nil
        }

        self = network
    }

    /// Creates a canonical network from raw prefix bits only when contained by a parent block.
    ///
    /// Any host bits present in `prefix` are cleared by the normal `IPNetwork` initializer before
    /// containment is checked. This makes the initializer useful for UI and database workflows that
    /// already hold parsed prefix components but still need to verify that the resulting network is
    /// inside a known delegated block.
    public init?(prefix: Family.Storage, prefixLength: PrefixLength<Family>, within parent: CIDRBlock<Family>) {
        let network = Self(prefix: prefix, prefixLength: prefixLength)
        guard parent.contains(network) else { return nil }
        self = network
    }
}

extension IPNetwork {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let network = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) network '\(description)'.")
        }
        self = network
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension IPNetwork: Sequence {
    /// The address type yielded when iterating every address in the represented range.
    public typealias Element = IPAddress<Family>

    /// Returns an iterator over every address in the network range.
    ///
    /// Iteration walks from `first` through `last`. Large networks may contain many addresses, so
    /// prefer containment or subnet operations when enumeration is not explicitly required.
    public func makeIterator() -> AnyIterator<Element> {
        var current = first.address
        let end = last.address
        var finished = false
        return AnyIterator {
            guard !finished else { return nil }
            let element = Element(address: current)
            if current == end { finished = true; return element }
            let (next, overflow) = current.addingReportingOverflow(1)
            precondition(!overflow)
            current = next
            return element
        }
    }
}
