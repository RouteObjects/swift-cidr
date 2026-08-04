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

/// A family-bound Classless Inter-Domain Routing (CIDR) value with stored bits and prefix length.
///
/// `CIDR` is a **protocol**, not a single hybrid value type. It is the broad structural interface
/// for IP values that participate in the classless model described in
/// [RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632). Concrete types give the bits their
/// meaning: ``IPAddress`` (address + prefix context), ``IPNetwork`` (canonical prefix),
/// ``CIDRBlock`` (neutral block), multicast ranges, and so on.
///
/// **Why a protocol:** many libraries use one `struct CIDR` that prints host bits but equates as a
/// network. Factoring shared structure into a protocol keeps **forms distinct** while reusing math.
///
/// `storage` is the raw address-family storage for the value. It is not allocation state, not an
/// RIR delegation block, and not necessarily a network-aligned prefix.
public protocol CIDR: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Family: IPAddressFamily

    /// The raw address-family storage for this CIDR value.
    var storage: Family.Storage { get }

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
    
    var first: IPAddress<Family> { IPAddress(address: storage & mask) }
    var last: IPAddress<Family> { IPAddress(address: storage | inverseMask) }
    var range: ClosedRange<IPAddress<Family>> { first...last }

    var addressLiteral: String {
        Family.formatAddress(storage)
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
    @inlinable
    @inline(__always)
    internal func _compressedCIDRNotationDescription() -> String {
        String(unsafeUninitializedCapacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count) { buffer in
            writeCompressedCIDRNotationUTF8(into: UnsafeMutableRawBufferPointer(buffer))
        }
    }

    func formatted(_ style: IPv6TextStyle) -> String {
        switch style {
        case .preferred:
            return AF.formatV6(storage)
        case .ipv4Mapped:
            return AF.formatV6Mapped(storage) ?? addressLiteral
        case .compressed:
            return AF.formatV6Compressed(storage)
        }
    }
}
