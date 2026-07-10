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

extension AF {
    @inlinable
    @inline(__always)
    internal static func formatV4(_ address: UInt32) -> String {
        // Keep this literal on the hot path to avoid static-let initialization/access overhead.
        String(unsafeUninitializedCapacity: 15) { buffer in
            var writeIndex = 0
            // Avoid interpolation on the IPv4 hot path by writing decimal octets directly.
            writeIPv4AddressLiteral(address, into: buffer.baseAddress!, at: &writeIndex)
            return writeIndex
        }
    }

    @inlinable
    @inline(__always)
    internal static func formatV4CIDR(address: UInt32, prefixLength: UInt8) -> String {
        // Preserve Swift small-string storage for short CIDR text while still handling /32 max-width output.
        let capacity = ipv4CIDRUTF8Length(address: address, prefixLength: prefixLength) <= maximumIPv4AddressLiteralUTF8Count
            ? maximumIPv4AddressLiteralUTF8Count
            : CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count
        return String(unsafeUninitializedCapacity: capacity) { buffer in
            var writeIndex = 0
            writeIPv4AddressLiteral(address, into: buffer.baseAddress!, at: &writeIndex)
            CIDRUTF8Formatting.writeSlashPrefixLength(Int(prefixLength), into: buffer, at: &writeIndex)
            return writeIndex
        }
    }

    @usableFromInline
    @inline(__always)
    internal static func ipv4CIDRUTF8Length(address: UInt32, prefixLength: UInt8) -> Int {
        var length = 0
        length &+= decimalOctetUTF8Length((address &>> 24) & 0xFF)
        length &+= 1
        length &+= decimalOctetUTF8Length((address &>> 16) & 0xFF)
        length &+= 1
        length &+= decimalOctetUTF8Length((address &>> 8) & 0xFF)
        length &+= 1
        length &+= decimalOctetUTF8Length(address & 0xFF)
        length &+= 1 // slash
        length &+= prefixLength >= 10 ? 2 : 1
        return length
    }

    @usableFromInline
    @inline(__always)
    internal static func decimalOctetUTF8Length(_ value: UInt32) -> Int {
        value >= 100 ? 3 : (value >= 10 ? 2 : 1)
    }

    internal static func formatV6(_ address: UInt128) -> String {
        CIDRUTF8Writer.fullIPv6AddressLiteral(address)
    }

    internal static func formatV6Compressed(_ address: UInt128) -> String {
        // Use the fixed-buffer UTF-8 formatter to avoid intermediate String fragments.
        CIDRUTF8Writer.compressedIPv6AddressLiteral(address)
    }

    internal static func formatV6Mapped(_ address: UInt128) -> String? {
        guard (address >> 32) == UInt128(0xFFFF) else { return nil }
        return String(unsafeUninitializedCapacity: maximumIPv4MappedIPv6AddressLiteralUTF8Count) { buffer in
            var writeIndex = 0
            // Avoid building a separate IPv4 String before appending the mapped IPv6 prefix.
            writeIPv4MappedIPv6Prefix(into: buffer, at: &writeIndex)
            writeIPv4AddressLiteral(UInt32(truncatingIfNeeded: address), into: buffer.baseAddress!, at: &writeIndex)
            return writeIndex
        }
    }

    @usableFromInline internal static let ipv4OctetCount = 4
    @usableFromInline internal static let maximumDecimalDigitsPerIPv4Octet = 3
    @usableFromInline internal static let maximumDotSeparatorsInIPv4Literal = ipv4OctetCount - 1
    @usableFromInline internal static let maximumIPv4AddressLiteralUTF8Count =
        (ipv4OctetCount * maximumDecimalDigitsPerIPv4Octet) + maximumDotSeparatorsInIPv4Literal
    private static let ipv4MappedIPv6Prefix: StaticString = "::ffff:"
    private static let ipv4MappedIPv6PrefixUTF8Count = "::ffff:".utf8.count
    private static let maximumIPv4MappedIPv6AddressLiteralUTF8Count =
        ipv4MappedIPv6PrefixUTF8Count + maximumIPv4AddressLiteralUTF8Count

    @usableFromInline internal static let asciiDot = UInt8(ascii: ".")
    @usableFromInline internal static let asciiZero = UInt8(ascii: "0")
    @usableFromInline internal static let decimalOctetTriplets: StaticString = "000001002003004005006007008009010011012013014015016017018019020021022023024025026027028029030031032033034035036037038039040041042043044045046047048049050051052053054055056057058059060061062063064065066067068069070071072073074075076077078079080081082083084085086087088089090091092093094095096097098099100101102103104105106107108109110111112113114115116117118119120121122123124125126127128129130131132133134135136137138139140141142143144145146147148149150151152153154155156157158159160161162163164165166167168169170171172173174175176177178179180181182183184185186187188189190191192193194195196197198199200201202203204205206207208209210211212213214215216217218219220221222223224225226227228229230231232233234235236237238239240241242243244245246247248249250251252253254255"

    @inline(__always)
    // SAFETY: The caller provides a buffer large enough for the fixed IPv4-mapped IPv6 prefix.
    private static func writeIPv4MappedIPv6Prefix(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        let prefix = ipv4MappedIPv6Prefix.utf8Start
        for offset in 0..<ipv4MappedIPv6PrefixUTF8Count {
            buffer[writeIndex &+ offset] = prefix[offset]
        }
        writeIndex &+= ipv4MappedIPv6PrefixUTF8Count
    }

    @inlinable
    @inline(__always)
    // SAFETY: The caller provides a buffer large enough for the maximum IPv4 literal length.
    internal static func writeIPv4AddressLiteral(
        _ address: UInt32,
        into buffer: UnsafeMutablePointer<UInt8>,
        at writeIndex: inout Int
    ) {
        writeDecimalOctet(UInt8(truncatingIfNeeded: address &>> 24), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address &>> 16), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address &>> 8), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address), into: buffer, at: &writeIndex)
    }

    @inlinable
    @inline(__always)
    // SAFETY: The caller provides writable capacity for one ASCII dot at `writeIndex`.
    internal static func writeDot(
        into buffer: UnsafeMutablePointer<UInt8>,
        at writeIndex: inout Int
    ) {
        buffer[writeIndex] = asciiDot
        writeIndex &+= 1
    }

    @inlinable
    @inline(__always)
    // SAFETY: The caller provides writable capacity for the maximum three decimal octet digits.
    internal static func writeDecimalOctet(
        _ value: UInt8,
        into buffer: UnsafeMutablePointer<UInt8>,
        at writeIndex: inout Int
    ) {
        if value < 10 {
            buffer[writeIndex] = asciiZero &+ value
            writeIndex &+= 1
            return
        }

        let offset = Int(value) &* 3
        let table = decimalOctetTriplets.utf8Start

        // Use fixed-width decimal triplet lookup for multi-digit octets to avoid divide/modulo.
        if value >= 100 {
            buffer[writeIndex] = table[offset]
            buffer[writeIndex &+ 1] = table[offset &+ 1]
            buffer[writeIndex &+ 2] = table[offset &+ 2]
            writeIndex &+= 3
        } else {
            buffer[writeIndex] = table[offset &+ 1]
            buffer[writeIndex &+ 1] = table[offset &+ 2]
            writeIndex &+= 2
        }
    }
}
