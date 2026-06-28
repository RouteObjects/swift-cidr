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

/// Capacity constants and helpers for allocation-free CIDR text output.
///
/// The ordinary `formatted(_:)` and `description` APIs are the right surface for one-off
/// presentation. These constants support high-volume export paths that reuse caller-owned storage
/// and want to avoid creating one `String` per CIDR value.
public enum CIDRUTF8Formatting {
    /// Maximum bytes for an IPv4 address literal such as `255.255.255.255`.
    public static let maximumIPv4AddressLiteralUTF8Count = 15

    /// Maximum bytes for IPv4 CIDR notation such as `255.255.255.255/32`.
    public static let maximumIPv4CIDRNotationUTF8Count = maximumIPv4AddressLiteralUTF8Count + 3

    /// Maximum bytes for a compressed IPv6 address literal such as
    /// `ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff`.
    public static let maximumCompressedIPv6AddressLiteralUTF8Count = 39

    /// Maximum bytes for compressed IPv6 CIDR notation such as
    /// `ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128`.
    public static let maximumCompressedIPv6CIDRNotationUTF8Count =
        maximumCompressedIPv6AddressLiteralUTF8Count + 4

    private static let asciiSlash = UInt8(ascii: "/")
    private static let asciiZero = UInt8(ascii: "0")

    @inline(__always)
    // Leave the constant `/` and `%` operations readable; optimized Swift/LLVM lowers
    // `/10`, `%10`, and `/100` to multiply/shift/remainder sequences, and the table variant
    // benchmarked slightly slower in the bulk CIDR writer path.
    static func writeSlashPrefixLength(
        _ prefixLength: Int,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        buffer[writeIndex] = asciiSlash
        writeIndex &+= 1

        if prefixLength >= 100 {
            buffer[writeIndex] = asciiZero &+ UInt8(prefixLength / 100)
            buffer[writeIndex &+ 1] = asciiZero &+ UInt8((prefixLength / 10) % 10)
            buffer[writeIndex &+ 2] = asciiZero &+ UInt8(prefixLength % 10)
            writeIndex &+= 3
        } else if prefixLength >= 10 {
            buffer[writeIndex] = asciiZero &+ UInt8(prefixLength / 10)
            buffer[writeIndex &+ 1] = asciiZero &+ UInt8(prefixLength % 10)
            writeIndex &+= 2
        } else {
            buffer[writeIndex] = asciiZero &+ UInt8(prefixLength)
            writeIndex &+= 1
        }
    }
}

public extension CIDR where Family == AF.V4 {
    /// Writes this IPv4 CIDR value's address literal into caller-owned UTF-8 storage.
    ///
    /// The buffer must contain at least
    /// ``CIDRUTF8Formatting/maximumIPv4AddressLiteralUTF8Count`` writable bytes. The return value
    /// is the exact number of bytes initialized.
    @discardableResult
    func writeAddressLiteralUTF8(into rawBuffer: UnsafeMutableRawBufferPointer) -> Int {
        precondition(
            rawBuffer.count >= CIDRUTF8Formatting.maximumIPv4AddressLiteralUTF8Count,
            "IPv4 address literal buffer must have enough writable bytes."
        )

        let buffer = rawBuffer.bindMemory(to: UInt8.self)
        var writeIndex = 0
        AF.writeIPv4AddressLiteral(storage, into: buffer.baseAddress!, at: &writeIndex)
        return writeIndex
    }

    /// Writes this IPv4 CIDR value as `address/prefix` into caller-owned UTF-8 storage.
    ///
    /// The buffer must contain at least
    /// ``CIDRUTF8Formatting/maximumIPv4CIDRNotationUTF8Count`` writable bytes. The return value is
    /// the exact number of bytes initialized.
    @discardableResult
    func writeCIDRNotationUTF8(into rawBuffer: UnsafeMutableRawBufferPointer) -> Int {
        precondition(
            rawBuffer.count >= CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count,
            "IPv4 CIDR notation buffer must have enough writable bytes."
        )

        let buffer = rawBuffer.bindMemory(to: UInt8.self)
        var writeIndex = 0
        AF.writeIPv4AddressLiteral(storage, into: buffer.baseAddress!, at: &writeIndex)
        CIDRUTF8Formatting.writeSlashPrefixLength(prefixBits, into: buffer, at: &writeIndex)
        return writeIndex
    }
}

public extension CIDR where Family == AF.V6 {
    /// Writes this IPv6 CIDR value's compressed address literal into caller-owned UTF-8 storage.
    ///
    /// The buffer must contain at least
    /// ``CIDRUTF8Formatting/maximumCompressedIPv6AddressLiteralUTF8Count`` writable bytes. The
    /// return value is the exact number of bytes initialized.
    @discardableResult
    func writeCompressedAddressLiteralUTF8(into rawBuffer: UnsafeMutableRawBufferPointer) -> Int {
        precondition(
            rawBuffer.count >= CIDRUTF8Formatting.maximumCompressedIPv6AddressLiteralUTF8Count,
            "IPv6 compressed address literal buffer must have enough writable bytes."
        )

        return CIDRUTF8Writer.writeCompressedIPv6AddressLiteral(storage, into: rawBuffer)
    }

    /// Writes this IPv6 CIDR value as `compressed-address/prefix` into caller-owned UTF-8 storage.
    ///
    /// The buffer must contain at least
    /// ``CIDRUTF8Formatting/maximumCompressedIPv6CIDRNotationUTF8Count`` writable bytes. The return
    /// value is the exact number of bytes initialized.
    @discardableResult
    func writeCompressedCIDRNotationUTF8(into rawBuffer: UnsafeMutableRawBufferPointer) -> Int {
        precondition(
            rawBuffer.count >= CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count,
            "IPv6 compressed CIDR notation buffer must have enough writable bytes."
        )

        var writeIndex = CIDRUTF8Writer.writeCompressedIPv6AddressLiteral(storage, into: rawBuffer)
        let buffer = rawBuffer.bindMemory(to: UInt8.self)
        CIDRUTF8Formatting.writeSlashPrefixLength(prefixBits, into: buffer, at: &writeIndex)
        return writeIndex
    }
}
