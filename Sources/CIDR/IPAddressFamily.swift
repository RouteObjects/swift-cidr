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
    /// Require a slash when `requiresPrefix` is true; otherwise omitted context is `bitWidth`.
    /// Explicit prefix text must be `0` or unpadded unsigned ASCII decimal within the family range.
    /// The default implementation supports only `.compatible`. A custom family must implement
    /// this requirement to support `.strict`, including that policy's IPv4 dotted-octet rules.
    static func parseCIDR(
        _ text: String,
        requiresPrefix: Bool,
        policy: IPAddressParsingPolicy
    ) -> (address: Storage, prefixLength: UInt8)?
}

public extension IPAddressFamily {
    static func parseCIDR(
        _ text: String,
        requiresPrefix: Bool,
        policy: IPAddressParsingPolicy
    ) -> (address: Storage, prefixLength: UInt8)? {
        // CHANGE: Existing custom families retain compatible parsing but cannot silently ignore strictness.
        guard policy == .compatible else { return nil }
        guard let slash = text.firstIndex(of: "/") else {
            guard !requiresPrefix,
                  let length = UInt8(exactly: bitWidth),
                  let address = parseAddress(text) else { return nil }
            return (address, length)
        }
        let addressText = text[..<slash]
        let suffix = text[text.index(after: slash)...]
        guard !addressText.isEmpty,
              let length = PrefixLengthTextParser.parse(suffix.utf8, maximum: bitWidth),
              let address = parseAddress(String(addressText)) else { return nil }
        return (address, length)
    }
}
