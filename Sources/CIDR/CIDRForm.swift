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
/// `CIDRForm` is a **protocol**, not a single hybrid value type. It is the broad structural interface
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
///
/// The name follows "CIDR form" terminology in the CIPS Internet-Draft (draft-munro-cips).
// Renamed from `CIDR`. A protocol sharing the module's name shadows it, so clients could
// not write `CIDR.IPv4Address` to disambiguate from Network.framework. Do not add a `CIDR` typealias:
// it would reintroduce the shadowing.
public protocol CIDRForm: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    associatedtype Family: IPAddressFamily

    /// The raw address-family storage for this CIDR value.
    var storage: Family.Storage { get }

    /// The prefix length that gives the stored bits their CIDR context.
    var prefixLength: PrefixLength<Family> { get }

    /// Formats the value using a requested presentation style.
    func formatted(_ style: CIDRTextStyle) -> String
}

public extension CIDRForm {
    @inline(__always)
    var prefixBits: Int {
        prefixLength.intValue
    }

    // CHANGE: Allow concrete downstream containment calls to specialize mask generation.
    @inlinable
    var mask: Family.Storage { Family.Storage.networkMask(for: prefixBits) }
    var inverseMask: Family.Storage { ~mask }
    
    /// The first address, retaining this value's prefix context.
    var first: IPAddress<Family> {
        // CHANGE: Endpoint projection preserves the same context as address enumeration.
        IPAddress(address: storage & mask, prefixLength: prefixLength)
    }

    /// The last address, retaining this value's prefix context.
    var last: IPAddress<Family> { IPAddress(address: storage | inverseMask, prefixLength: prefixLength) }

    /// Ordered contextual endpoints, subject to `ClosedRange` and `Strideable` limits.
    ///
    /// Range containment uses ordering. Use network containment for hierarchy checks or
    /// `IPNetwork.addresses` for exact sequence membership and raw-storage traversal.
    var range: ClosedRange<IPAddress<Family>> { first...last }

    /// The stored bits formatted as an address literal, without the prefix length.
    @inlinable
    @inline(__always)
    var addressLiteral: String {
        Family.formatAddress(storage)
    }

    /// Canonical CIDR text, such as `192.0.2.0/24` or `2001:db8::/32`.
    // The one CustomStringConvertible witness for every conformer. Routing through
    // Family.formatCIDR keeps the per-family fast path on interpolation and generic calls.
    @inlinable
    @inline(__always)
    var description: String {
        Family.formatCIDR(storage, prefixLength: prefixLength)
    }

    var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }

    // Shared by every conformer; replaces identical per-type and per-family overloads.
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
}

public extension CIDRForm where Family == AF.V4 {
    func formatted(_ style: IPv4TextStyle) -> String {
        switch style {
        case .addressAndNetmask:
            let v4Mask = UInt32.networkMask(for: prefixBits)
            return "\(addressLiteral) \(AF.formatV4(v4Mask))"
        }
    }
}

public extension CIDRForm where Family == AF.V6 {
    // _compressedCIDRNotationDescription() moved to AF.formatV6CompressedCIDR.
    // Expose this wrapper so concrete callers can eliminate storage witness dispatch.
    @inlinable
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
