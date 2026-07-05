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

/// A canonical, prefix-aligned CIDR range without subnet or host semantics.
///
/// `CIDRBlock` is the neutral range form: it knows the address family, prefix bits, first address,
/// last address, containment, and overlap. It intentionally does not model operational network
/// concepts such as broadcast addresses, usable hosts, gateways, or subnet allocation policy.
///
/// See [RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632) for Classless Inter-Domain
/// Routing notation and aggregation context.
public struct CIDRBlock<Family: IPAddressFamily>: CIDR, Hashable, LosslessStringConvertible, Codable {
    public let prefix: Family.Storage
    public let prefixLength: PrefixLength<Family>

    @inlinable
    @inline(__always)
    public var storage: Family.Storage { prefix }

    public init(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
        self.prefix = prefix & Family.Storage.networkMask(for: prefixLength.intValue)
        self.prefixLength = prefixLength
    }
}

extension CIDRBlock {
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

public extension CIDRBlock where Family == AF.V4 {
    @inlinable
    @inline(__always)
    var description: String {
        _cidrNotationDescription()
    }

    @inlinable
    @inline(__always)
    func formatted(_ style: CIDRTextStyle) -> String {
        switch style {
        case .cidrNotation:
            return description
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

public extension CIDRBlock where Family == AF.V6 {
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
            return description
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

public extension CIDRBlock {
    /// The first address in the represented range.
    var firstAddress: IPAddress<Family> {
        first
    }

    /// The last address in the represented range.
    var lastAddress: IPAddress<Family> {
        last
    }

    /// The number of addresses in the represented range when it fits in `UInt128`.
    var rangeSizeIfRepresentable: UInt128? {
        let hostBits = Family.bitWidth - prefixBits
        guard hostBits < UInt128.bitWidth else { return nil }
        return UInt128(1) << hostBits
    }

    func contains(_ address: IPAddress<Family>) -> Bool {
        (address.address & mask) == prefix
    }

    func contains(_ other: CIDRBlock<Family>) -> Bool {
        other.prefixLength >= prefixLength && contains(other.firstAddress)
    }

    /// Returns whether this block fully contains a network prefix.
    ///
    /// This is useful when a neutral allocation or delegation block is being used as the parent
    /// boundary for ordinary network construction. The check is pure CIDR containment: it verifies
    /// that the network is not less-specific than the block and that the network boundary falls
    /// inside the block.
    ///
    /// This method does not imply that the network has been allocated, assigned, routed, or
    /// approved by an IPAM database. Higher-layer systems remain responsible
    /// for policy rules like requiring a stored parent, denying overlaps, or disallowing direct use
    /// of the delegated parent block.
    func contains(_ network: IPNetwork<Family>) -> Bool {
        network.prefixLength >= prefixLength && contains(network.networkAddress)
    }

    func overlaps(_ other: CIDRBlock<Family>) -> Bool {
        firstAddress.address <= other.lastAddress.address && other.firstAddress.address <= lastAddress.address
    }

    func isWithin(_ other: CIDRBlock<Family>) -> Bool {
        other.contains(self)
    }
}

extension CIDRBlock {
    public init?(_ description: String) {
        guard let address = IPAddress<Family>(description) else { return nil }
        self.init(prefix: address.address, prefixLength: address.prefixLength)
    }
}

extension CIDRBlock {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let block = Self(description) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(Family.familyName) CIDR block '\(description)'.")
        }
        self = block
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
