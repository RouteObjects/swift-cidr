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

/// Describes an IP address family as a compile-time trait instead of a runtime tag.
///
/// POSIX APIs typically carry the family beside the address bits using runtime constants such as
/// `AF_INET` and `AF_INET6`. `CIDR` keeps the same conceptual distinction, but lifts it into the
/// type system so the family also defines the storage width, canonical parser, formatter, and IANA
/// family identifier used by the rest of the library.
///
/// That model matches the protocol definitions: IPv4 addresses are 32-bit Internet addresses in
/// [RFC 791](https://datatracker.ietf.org/doc/html/rfc791), and IPv6 addresses are 128-bit
/// identifiers in [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291).
public protocol AddressFamily: Sendable {
    /// The fixed-width unsigned integer used to store address bits for this family.
    associatedtype Storage: FixedWidthInteger & UnsignedInteger & Sendable

    /// The [IANA Address Family Number](https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml)
    /// for this family.
    static var ianaValue: Int32 { get }

    /// The width of the address space in bits.
    static var bitWidth: Int { get }

    /// A human-readable family name such as `IPv4` or `IPv6`.
    static var familyName: String { get }

    /// Parses canonical or accepted presentation text into the family storage representation.
    static func parseAddress(_ string: String) -> Storage?

    /// Formats storage into the family's canonical presentation text.
    static func formatAddress(_ address: Storage) -> String
}

/// Namespace for the concrete IP address family marker types supported by CIDR.
///
/// `AF` is intentionally familiar to developers coming from POSIX, but the members are Swift types
/// rather than integer constants. `AF.V4` and `AF.V6` can therefore carry storage width and parsing
/// behavior directly in the type system.
public enum AF {
    /// The IPv4 address family, stored as a `UInt32`.
    public enum V4: AddressFamily {
        public typealias Storage = UInt32

        public static let ianaValue: Int32 = 1
        public static let bitWidth: Int = UInt32.bitWidth
        public static let familyName: String = "IPv4"

        public static func parseAddress(_ string: String) -> UInt32? {
            AF.parseIPv4Text(string)
        }

        public static func formatAddress(_ address: UInt32) -> String {
            AF.formatV4(address)
        }
    }

    /// The IPv6 address family, stored as a `UInt128`.
    public enum V6: AddressFamily {
        public typealias Storage = UInt128

        public static let ianaValue: Int32 = 2
        public static let bitWidth: Int = UInt128.bitWidth
        public static let familyName: String = "IPv6"

        public static func parseAddress(_ string: String) -> UInt128? {
            AF.parseIPv6Text(string)
        }

        public static func formatAddress(_ address: UInt128) -> String {
            AF.formatV6(address)
        }
    }
}

/// Shorthand alias for the IPv4 address family marker type.
public typealias V4 = AF.V4
/// Shorthand alias for the IPv6 address family marker type.
public typealias V6 = AF.V6
