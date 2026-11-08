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

/// An IANA Address Family value that represents an Internet Protocol address space.
///
/// `IPAddressFamily` is the refinement used by IP-specific types such as ``IPAddress``,
/// ``IPNetwork``, ``CIDRBlock``, and ``IPEndpoint``. Today only ``AF/V4`` and ``AF/V6`` conform.
/// This keeps non-IP registry families, such as AS numbers and MAC address formats, out of
/// IP-specific CIDR types while still letting them share the broader ``AddressFamily`` metadata,
/// parsing, and formatting surface.
///
/// **Standards:** [RFC 791](https://datatracker.ietf.org/doc/html/rfc791) (IPv4),
/// [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291) (IPv6).
public protocol IPAddressFamily: AddressFamily {
    /// Parses address-only or CIDR text using one grammar for generic and concrete callers.
    ///
    /// Require a slash when `requiresPrefix` is true; otherwise omitted context is `Storage.bitWidth`.
    /// Explicit prefix text must be `0` or unpadded unsigned ASCII decimal within the family range.
    /// The default implementation supports only `.compatible`. A custom family must implement
    /// this requirement to support `.strict`, including that policy's IPv4 dotted-octet rules.
    static func parseCIDR(
        _ text: String,
        requiresPrefix: Bool,
        policy: IPAddressParsingPolicy
    ) -> (address: Storage, prefixLength: UInt8)?

    /// Formats storage and a prefix length as CIDR notation, such as `192.0.2.0/24`.
    ///
    /// Every ``CIDRForm`` conformer's `description` routes through this requirement. Because it is
    /// dispatched through the family's witness table, concrete fast paths are used by unspecialized
    /// callers too: string interpolation, `String(describing:)`, `print`, `Codable`, and generic code.
    /// The default implementation joins ``AddressFamily/formatAddress(_:)`` and the prefix length.
    // Constrained-extension `description` overloads are never chosen as protocol witnesses,
    // so per-type IPv4/IPv6 fast paths were bypassed everywhere except direct concrete calls.
    static func formatCIDR(_ storage: Storage, prefixLength: PrefixLength<Self>) -> String
}

public extension IPAddressFamily {
    /// The address width, which for an IP family is always the full width of `Storage`.
    ///
    /// CIDR math (masks, last address, overflow detection, summarization, and iteration) requires
    /// an IP address to fill its storage. IP-specific code reads `Storage.bitWidth` directly, so a
    /// conformer that declares a different `bitWidth` changes only this metadata, never the math.
    // Derive from Storage. A mismatched custom family previously accepted prefix lengths
    // its masks could not represent and trapped in FixedWidthInteger.networkMask(for:).
    @inlinable
    @inline(__always)
    static var bitWidth: Int { Storage.bitWidth }

    /// Joins the family address literal and prefix length with a slash.
    static func formatCIDR(_ storage: Storage, prefixLength: PrefixLength<Self>) -> String {
        "\(formatAddress(storage))/\(prefixLength.rawValue)"
    }

    static func parseCIDR(
        _ text: String,
        requiresPrefix: Bool,
        policy: IPAddressParsingPolicy
    ) -> (address: Storage, prefixLength: UInt8)? {
        // CHANGE: Existing custom families retain compatible parsing but cannot silently ignore strictness.
        guard policy == .compatible else { return nil }
        guard let slash = text.firstIndex(of: "/") else {
            guard !requiresPrefix,
                  let length = UInt8(exactly: Storage.bitWidth),
                  let address = parseAddress(text) else { return nil }
            return (address, length)
        }
        let addressText = text[..<slash]
        let suffix = text[text.index(after: slash)...]
        guard !addressText.isEmpty,
              let length = PrefixLengthTextParser.parse(suffix.utf8, maximum: Storage.bitWidth),
              let address = parseAddress(String(addressText)) else { return nil }
        return (address, length)
    }
}
