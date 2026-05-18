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
/// IPv4 and IPv6 are Internet Protocol address families and therefore conform to
/// ``IPAddressFamily``. Other supported families, such as AS numbers and MAC address formats, are
/// parseable and formattable registry families but do not automatically participate in IP-specific
/// CIDR math.
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

/// An IANA Address Family value that represents an Internet Protocol address space.
///
/// `IPAddressFamily` is the refinement used by IP-specific types such as ``IPAddress``,
/// ``IPNetwork``, ``CIDRBlock``, and ``IPEndpoint``. Today only ``AF/V4`` and ``AF/V6`` conform.
/// This keeps non-IP registry families, such as AS numbers and MAC address formats, out of
/// IP-specific CIDR types while still letting them share the broader ``AddressFamily`` metadata,
/// parsing, and formatting surface.
public protocol IPAddressFamily: AddressFamily {}

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
    public enum V6: IPAddressFamily {
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

    /// The AS Number address family, stored as a 32-bit unsigned integer.
    ///
    /// RFC 1930 defines an Autonomous System as a connected group of IP prefixes under a single
    /// clearly defined routing policy. RFC 6793 extends AS numbers to four octets, so this family
    /// uses `UInt32` storage.
    public enum ASN: AddressFamily {
        public typealias Storage = UInt32

        public static let ianaValue: Int32 = 18
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

        public static let ianaValue: Int32 = 16389
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

        public static let ianaValue: Int32 = 16390
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

extension AF {
    internal static func parseASNText(_ string: String) -> UInt32? {
        guard !string.isEmpty else { return nil }

        var value: UInt32 = 0
        for byte in string.utf8 {
            guard byte >= 48, byte <= 57 else { return nil }

            let digit = UInt32(byte &- 48)
            let multiplied = value.multipliedReportingOverflow(by: 10)
            guard !multiplied.overflow else { return nil }

            let added = multiplied.partialValue.addingReportingOverflow(digit)
            guard !added.overflow else { return nil }

            value = added.partialValue
        }

        return value
    }

    internal static func parseMACText(_ string: String, octetCount: Int) -> UInt64? {
        precondition(octetCount == 6 || octetCount == 8)

        let expectedLength = (octetCount * 3) - 1
        guard string.utf8.count == expectedLength else { return nil }

        var value: UInt64 = 0
        for (index, byte) in string.utf8.enumerated() {
            if index % 3 == 2 {
                guard byte == 58 else { return nil }
                continue
            }

            guard let nibble = hexNibble(byte) else { return nil }
            value = (value << 4) | UInt64(nibble)
        }

        return value
    }

    internal static func formatMAC(_ address: UInt64, octetCount: Int) -> String {
        precondition(octetCount == 6 || octetCount == 8)
        if octetCount == 6 {
            precondition(address >> 48 == 0, "MAC48 storage must fit in 48 bits.")
        }

        let hexDigitsLiteral: StaticString = "0123456789abcdef"
        let hexDigits = hexDigitsLiteral.utf8Start
        var bytes: [UInt8] = []
        bytes.reserveCapacity((octetCount * 3) - 1)

        for octetIndex in 0..<octetCount {
            let shift = (octetCount - octetIndex - 1) * 8
            let octet = UInt8(truncatingIfNeeded: address >> shift)
            bytes.append(hexDigits[Int(octet >> 4)])
            bytes.append(hexDigits[Int(octet & 0x0F)])

            if octetIndex != octetCount - 1 {
                bytes.append(58)
            }
        }

        return String(decoding: bytes, as: UTF8.self)
    }

    private static func hexNibble(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 48...57:
            return byte &- 48
        case 65...70:
            return byte &- 55
        case 97...102:
            return byte &- 87
        default:
            return nil
        }
    }
}

/// Shorthand alias for the IPv4 address family marker type.
public typealias V4 = AF.V4
/// Shorthand alias for the IPv6 address family marker type.
public typealias V6 = AF.V6
