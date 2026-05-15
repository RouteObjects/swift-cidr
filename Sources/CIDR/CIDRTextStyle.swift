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

/// Family-neutral textual representations for CIDR values.
public enum CIDRTextStyle: Sendable, Hashable {
    /// `192.168.1.1/32` or `2001:db8:0:0:0:0:0:1/128`
    case cidrNotation
    /// `192.168.1.1` or `2001:db8:0:0:0:0:0:1`
    case addressOnly

    @available(*, deprecated, message: "Use .cidrNotation")
    public static var canonicalCIDR: Self { .cidrNotation }
}

/// IPv4-only textual representations that extend the generic CIDR formatter.
public enum IPv4TextStyle: Sendable, Hashable {
    /// `192.168.1.1 255.255.255.255`
    case addressAndNetmask
}

/// IPv6-only textual representations that extend the generic CIDR formatter.
///
/// RFC 4291 defines conventional IPv6 text forms in
/// [Section 2.2](https://datatracker.ietf.org/doc/html/rfc4291#section-2.2), including the
/// preferred eight-field hexadecimal form and the compressed `::` form for runs of zero bits.
public enum IPv6TextStyle: Sendable, Hashable {
    /// `2001:db8:0:0:0:0:0:1`
    /// Uses the RFC 4291 preferred eight-field hexadecimal form.
    case preferred
    /// `2001:db8::1`
    /// Uses the RFC 4291 `::` compressed form without mixed IPv4 notation.
    case compressed
    /// `::ffff:192.0.2.1`
    /// Uses mixed IPv4 notation for IPv4-mapped IPv6 addresses when possible.
    case ipv4Mapped
}
