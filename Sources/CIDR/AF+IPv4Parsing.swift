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

@usableFromInline
struct IPv4CIDRParseResult: Sendable, Equatable {
    @usableFromInline
    let address: UInt32
    @usableFromInline
    let prefixLength: UInt8
    @usableFromInline
    let hasExplicitPrefix: Bool

    @usableFromInline
    init(address: UInt32, prefixLength: UInt8, hasExplicitPrefix: Bool) {
        self.address = address
        self.prefixLength = prefixLength
        self.hasExplicitPrefix = hasExplicitPrefix
    }
}

extension AF {
    private static let asciiSlash = UInt8(ascii: "/")

    internal static func parseIPv4Text(_ string: String) -> UInt32? {
        // Copying into a var and forcing withUTF8 keeps the hot path on contiguous bytes.
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4TextCore(bytes)
        }
    }

    @usableFromInline
    internal static func parseIPv4CIDRTextSuffix(
        _ string: String,
        requiresPrefix: Bool
    ) -> IPv4CIDRParseResult? {
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4CIDRTextCore(
                bytes,
                slashIndex: _firstSlashIndexSuffix(in: bytes),
                requiresPrefix: requiresPrefix
            )
        }
    }

    @inline(__always)
    // SAFETY: `bytes` is a borrowed UTF-8 view that is never escaped; all indexing is bounded by iteration.
    internal static func _parseIPv4TextCore(_ bytes: UnsafeBufferPointer<UInt8>) -> UInt32? {
        // Share exact IPv4 dotted-quad rules between standalone IPv4 and IPv6 mixed-notation parsing.
        guard bytes.count >= 7 && bytes.count <= 15 else { return nil }

        var result: UInt32 = 0
        var currentOctet: UInt32 = 0
        var dotCount = 0
        var digitsInOctet = 0

        for byte in bytes {
            let digit = byte &- 48
            if digit <= 9 {
                digitsInOctet += 1
                guard digitsInOctet <= 3 else { return nil }
                currentOctet = (currentOctet * 10) + UInt32(digit)
                guard currentOctet <= 255 else { return nil }
            } else if byte == 46 {
                guard digitsInOctet > 0, dotCount < 3 else { return nil }
                result = (result << 8) | currentOctet
                currentOctet = 0
                digitsInOctet = 0
                dotCount += 1
            } else {
                return nil
            }
        }

        guard digitsInOctet > 0, dotCount == 3 else { return nil }
        return (result << 8) | currentOctet
    }

    @inline(__always)
    // SAFETY: `bytes` is borrowed for the call; derived slices are validated to remain within it.
    private static func _parseIPv4CIDRTextCore(
        _ bytes: UnsafeBufferPointer<UInt8>,
        slashIndex: Int?,
        requiresPrefix: Bool
    ) -> IPv4CIDRParseResult? {
        guard let slashIndex else {
            guard !requiresPrefix,
                  let address = _parseIPv4TextCore(bytes)
            else {
                return nil
            }

            return IPv4CIDRParseResult(address: address, prefixLength: 32, hasExplicitPrefix: false)
        }

        let prefixStart = slashIndex + 1
        guard slashIndex > 0,
              prefixStart < bytes.count,
              let baseAddress = bytes.baseAddress
        else {
            return nil
        }

        // SAFETY: `slashIndex` was validated inside `bytes`, and the rebased buffer does not escape.
        let addressBytes = UnsafeBufferPointer(start: baseAddress, count: slashIndex)
        guard let address = _parseIPv4TextCore(addressBytes),
              let prefixLength = _parseStrictIPv4PrefixLength(bytes, start: prefixStart, end: bytes.count)
        else {
            return nil
        }

        return IPv4CIDRParseResult(address: address, prefixLength: prefixLength, hasExplicitPrefix: true)
    }

    @inline(__always)
    // SAFETY: `start` and `end` are produced from validated slash positions within `bytes`.
    private static func _parseStrictIPv4PrefixLength(
        _ bytes: UnsafeBufferPointer<UInt8>,
        start: Int,
        end: Int
    ) -> UInt8? {
        let count = end - start
        guard count == 1 || count == 2 else { return nil }
        guard count == 1 || bytes[start] != asciiZero else { return nil }

        var value = UInt8.zero
        var index = start
        while index < end {
            let digit = bytes[index] &- asciiZero
            guard digit <= 9 else { return nil }
            value = (value &* 10) &+ digit
            index &+= 1
        }

        guard value <= 32 else { return nil }
        return value
    }

    @inline(__always)
    // SAFETY: Candidate suffix indices are checked against `bytes.count` before each subscript.
    private static func _firstSlashIndexSuffix(in bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        let count = bytes.count

        // A valid IPv4 CIDR prefix is 0...32, so the slash can only appear
        // immediately before a one- or two-digit suffix.
        let oneDigitPrefixSlashIndex = count &- 2
        if count >= 2, oneDigitPrefixSlashIndex > 0, bytes[oneDigitPrefixSlashIndex] == asciiSlash {
            return oneDigitPrefixSlashIndex
        }

        let twoDigitPrefixSlashIndex = count &- 3
        if count >= 3, twoDigitPrefixSlashIndex > 0, bytes[twoDigitPrefixSlashIndex] == asciiSlash {
            return twoDigitPrefixSlashIndex
        }

        return nil
    }
}

extension AF.V4 {
    internal static func prefixLength(fromNetmask netmaskString: String) -> Int? {
        guard let maskValue = AF.parseIPv4Text(netmaskString) else { return nil }
        let leadingOnes = (~maskValue).leadingZeroBitCount
        guard maskValue == (UInt32.max << (32 - leadingOnes)) else { return nil }
        return leadingOnes
    }
}
