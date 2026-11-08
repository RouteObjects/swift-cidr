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

/// Describes a supported IANA Address Family value as a compile-time trait instead of a runtime tag.
///
/// IANA address-family numbers identify more than IP versions. `CIDR` lifts selected registry
/// values into the type system so a family defines its storage width, canonical parser, formatter,
/// and IANA identifier.
///
/// **Why:** generic algorithms need width and parse/format hooks without a runtime switch on every
/// call. **Standards:** [IANA Address Family Numbers](https://www.iana.org/assignments/address-family-numbers/).
///
/// IPv4 and IPv6 are Internet Protocol address families and therefore conform to
/// ``IPAddressFamily``. Other supported families, such as AS numbers and MAC address formats, are
/// parseable and formattable registry families but do not automatically participate in IP-specific
/// CIDR math.
public protocol AddressFamily: Sendable {
    /// The fixed-width unsigned integer used to store address bits for this family.
    associatedtype Storage: FixedWidthInteger & UnsignedInteger & Sendable

    /// The [IANA Address Family Number](https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml)
    /// for this family.
    ///
    /// IANA assigns these as 16-bit values (the AFI field carried by MP-BGP and BGP-LS), so the
    /// type encodes the registry's range.
    // UInt16 to match the 16-bit IANA Address Family Numbers registry.
    static var ianaValue: UInt16 { get }

    /// The width of the address space in bits.
    ///
    /// For non-IP families this may be narrower than `Storage` (``AF/MAC48`` stores 48 bits in a
    /// `UInt64`). ``IPAddressFamily`` derives it from `Storage`, because CIDR math requires an IP
    /// address to fill its storage.
    static var bitWidth: Int { get }

    /// A human-readable family name such as `IPv4` or `IPv6`.
    static var familyName: String { get }

    /// Parses canonical or accepted presentation text into the family storage representation.
    static func parseAddress(_ string: String) -> Storage?

    /// Formats storage into the family's canonical presentation text.
    static func formatAddress(_ address: Storage) -> String
}

/// Namespace for the concrete IANA address family marker types supported by CIDR.
///
/// `AF` is intentionally familiar to developers coming from POSIX and IANA registry terminology,
/// but the members are Swift types rather than integer constants. `AF.V4` and `AF.V6` are
/// IP address families. `AF.ASN`, `AF.MAC48`, and `AF.MAC64` are supported registry families for
/// values that are important to routing and layer-2 modeling but are not IP address spaces.
public enum AF {
    /// The IPv4 address family, stored as a `UInt32`.
    public enum V4: IPAddressFamily {
        public typealias Storage = UInt32

        public static let ianaValue: UInt16 = 1
        // bitWidth now comes from IPAddressFamily's Storage-derived default.
        public static let familyName: String = "IPv4"

        @inlinable
        @inline(__always)
        public static func formatAddress(_ address: UInt32) -> String {
            AF.formatV4(address)
        }

        // The single IPv4 CIDR fast path, reached by concrete and generic callers alike.
        @inlinable
        @inline(__always)
        public static func formatCIDR(_ storage: UInt32, prefixLength: PrefixLength<AF.V4>) -> String {
            AF.formatV4CIDR(address: storage, prefixLength: prefixLength.rawValue)
        }
    }

    /// The IPv6 address family, stored as a `UInt128`.
    public enum V6: IPAddressFamily {
        public typealias Storage = UInt128

        public static let ianaValue: UInt16 = 2
        // bitWidth now comes from IPAddressFamily's Storage-derived default.
        public static let familyName: String = "IPv6"

        public static func formatAddress(_ address: UInt128) -> String {
            AF.formatV6Compressed(address)
        }

        // The single IPv6 compressed CIDR fast path, reached by concrete and generic callers alike.
        public static func formatCIDR(_ storage: UInt128, prefixLength: PrefixLength<AF.V6>) -> String {
            AF.formatV6CompressedCIDR(address: storage, prefixLength: prefixLength.rawValue)
        }
    }

    /// The AS Number address family, stored as a 32-bit unsigned integer.
    ///
    /// RFC 1930 defines an Autonomous System as a connected group of IP prefixes under a single
    /// clearly defined routing policy. RFC 6793 extends AS numbers to four octets, so this family
    /// uses `UInt32` storage.
    public enum ASN: AddressFamily {
        public typealias Storage = UInt32

        public static let ianaValue: UInt16 = 18
        public static let bitWidth: Int = UInt32.bitWidth
        public static let familyName: String = "AS Number"

        public static func parseAddress(_ string: String) -> UInt32? {
            AF.parseASNText(string)
        }

        public static func formatAddress(_ address: UInt32) -> String {
            String(address)
        }
    }

    /// The 48-bit MAC address family, stored in the low 48 bits of a `UInt64`.
    public enum MAC48: AddressFamily {
        public typealias Storage = UInt64

        public static let ianaValue: UInt16 = 16389
        public static let bitWidth: Int = 48
        public static let familyName: String = "48-bit MAC"

        public static func parseAddress(_ string: String) -> UInt64? {
            AF.parseMACText(string, octetCount: 6)
        }

        public static func formatAddress(_ address: UInt64) -> String {
            AF.formatMAC(address, octetCount: 6)
        }
    }

    /// The 64-bit MAC address family, stored as a `UInt64`.
    public enum MAC64: AddressFamily {
        public typealias Storage = UInt64

        public static let ianaValue: UInt16 = 16390
        public static let bitWidth: Int = UInt64.bitWidth
        public static let familyName: String = "64-bit MAC"

        public static func parseAddress(_ string: String) -> UInt64? {
            AF.parseMACText(string, octetCount: 8)
        }

        public static func formatAddress(_ address: UInt64) -> String {
            AF.formatMAC(address, octetCount: 8)
        }
    }
}

/// Shorthand alias for the IPv4 address family marker type.
public typealias V4 = AF.V4
/// Shorthand alias for the IPv6 address family marker type.
public typealias V6 = AF.V6
/// Shorthand alias for the 48-bit MAC address family marker type.
public typealias MAC48 = AF.MAC48
/// Shorthand alias for the 64-bit MAC address family marker type.
public typealias MAC64 = AF.MAC64
