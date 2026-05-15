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

struct IPv6CIDRParseResult: Sendable, Equatable {
    let address: UInt128
    let prefixLength: UInt8
    let hasExplicitPrefix: Bool

    init(address: UInt128, prefixLength: UInt8, hasExplicitPrefix: Bool) {
        self.address = address
        self.prefixLength = prefixLength
        self.hasExplicitPrefix = hasExplicitPrefix
    }
}

extension AF {
    private static let ipv6CIDRSlashASCII = UInt8(ascii: "/")
    private static let ipv6CIDRZeroASCII = UInt8(ascii: "0")

    /// The selected production IPv6 text parser.
    internal static func parseIPv6Text(_ string: String) -> UInt128? {
        if let result = string.utf8.withContiguousStorageIfAvailable({ bytes -> UInt128? in
            _parseIPv6TextCore(bytes)
        }) {
            return result
        }

        let fallback = Array(string.utf8)
        // SAFETY: The fallback array owns contiguous storage for the duration of this closure.
        return fallback.withUnsafeBufferPointer { bytes in
            _parseIPv6TextCore(bytes)
        }
    }

    internal static func parseIPv6CIDRTextSuffix(
        _ string: String,
        requiresPrefix: Bool
    ) -> IPv6CIDRParseResult? {
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv6CIDRTextCore(
                bytes,
                slashIndex: _firstIPv6CIDRSlashIndexSuffix(in: bytes),
                requiresPrefix: requiresPrefix
            )
        }
    }

    @inline(__always)
    // SAFETY: `bytes` is borrowed for the call; derived slices are validated to remain within it.
    private static func _parseIPv6CIDRTextCore(
        _ bytes: UnsafeBufferPointer<UInt8>,
        slashIndex: Int?,
        requiresPrefix: Bool
    ) -> IPv6CIDRParseResult? {
        guard let slashIndex else {
            guard !requiresPrefix,
                  let address = _parseIPv6TextCore(bytes)
            else {
                return nil
            }

            return IPv6CIDRParseResult(address: address, prefixLength: 128, hasExplicitPrefix: false)
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
        guard let address = _parseIPv6TextCore(addressBytes),
              let prefixLength = _parseStrictIPv6PrefixLength(bytes, start: prefixStart, end: bytes.count)
        else {
            return nil
        }

        return IPv6CIDRParseResult(address: address, prefixLength: prefixLength, hasExplicitPrefix: true)
    }

    @inline(__always)
    // SAFETY: `start` and `end` are produced from validated slash positions within `bytes`.
    private static func _parseStrictIPv6PrefixLength(
        _ bytes: UnsafeBufferPointer<UInt8>,
        start: Int,
        end: Int
    ) -> UInt8? {
        let count = end - start
        guard (1...3).contains(count) else { return nil }
        guard count == 1 || bytes[start] != ipv6CIDRZeroASCII else { return nil }

        var value = UInt16.zero
        var index = start
        while index < end {
            let digit = bytes[index] &- ipv6CIDRZeroASCII
            guard digit <= 9 else { return nil }
            value = (value &* 10) &+ UInt16(digit)
            index &+= 1
        }

        guard value <= 128 else { return nil }
        return UInt8(value)
    }

    @inline(__always)
    // SAFETY: Candidate suffix indices are checked against `bytes.count` before each subscript.
    private static func _firstIPv6CIDRSlashIndexSuffix(in bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        let count = bytes.count

        // A valid IPv6 CIDR prefix is 0...128, so the slash can only appear
        // immediately before a one-, two-, or three-digit suffix.
        let oneDigitPrefixSlashIndex = count &- 2
        if count >= 2, oneDigitPrefixSlashIndex > 0, bytes[oneDigitPrefixSlashIndex] == ipv6CIDRSlashASCII {
            return oneDigitPrefixSlashIndex
        }

        let twoDigitPrefixSlashIndex = count &- 3
        if count >= 3, twoDigitPrefixSlashIndex > 0, bytes[twoDigitPrefixSlashIndex] == ipv6CIDRSlashASCII {
            return twoDigitPrefixSlashIndex
        }

        let threeDigitPrefixSlashIndex = count &- 4
        if count >= 4, threeDigitPrefixSlashIndex > 0, bytes[threeDigitPrefixSlashIndex] == ipv6CIDRSlashASCII {
            return threeDigitPrefixSlashIndex
        }

        return nil
    }

    // SAFETY: `bytes` is a borrowed UTF-8 view that is never escaped; subscripts are guarded by `count`.
    private static func _parseIPv6TextCore(_ bytes: UnsafeBufferPointer<UInt8>) -> UInt128? {
        let count = bytes.count
        guard count > 0 else { return nil }

        if let fullForm = _parseCanonicalIPv6Text(bytes) {
            return fullForm
        }

        var words = SIMD8<UInt16>(repeating: 0)
        var wordCount = 0
        var doubleColonIndex = -1
        var index = 0
        var currentWord: UInt32 = 0
        var hasDigits = false
        var seenDot = false

        @inline(__always)
        func hexValue(_ byte: UInt8) -> UInt32? {
            switch byte {
            case 48...57:
                return UInt32(byte - 48)
            case 65...70:
                return UInt32(byte - 65 + 10)
            case 97...102:
                return UInt32(byte - 97 + 10)
            default:
                return nil
            }
        }

        @inline(__always)
        func consumeHexDigit(_ byte: UInt8) -> Bool {
            guard let value = hexValue(byte) else { return false }
            currentWord = (currentWord << 4) | value
            guard currentWord <= 0xFFFF else { return false }
            hasDigits = true
            return true
        }

        parseLoop: while index < count {
            let byte = bytes[index]
            switch byte {
            case 58:
                let nextIndex = index + 1
                if nextIndex < count && bytes[nextIndex] == 58 {
                    guard doubleColonIndex == -1 else { return nil }
                    if hasDigits {
                        guard wordCount < 8 else { return nil }
                        words[wordCount] = UInt16(currentWord)
                        wordCount += 1
                    }
                    doubleColonIndex = wordCount
                    currentWord = 0
                    hasDigits = false
                    index = nextIndex + 1
                    continue
                }

                guard hasDigits else { return nil }
                guard wordCount < 8 else { return nil }
                words[wordCount] = UInt16(currentWord)
                wordCount += 1
                currentWord = 0
                hasDigits = false
            case 46:
                seenDot = true
                break parseLoop
            default:
                guard consumeHexDigit(byte) else { return nil }
            }
            index += 1
        }

        if seenDot {
            guard wordCount < 7 else { return nil }

            var dotStart = index
            while dotStart > 0 && bytes[dotStart - 1] != 58 {
                dotStart -= 1
            }

            // SAFETY: `count > 0` was validated before this path, so `bytes.baseAddress` is non-nil.
            let baseAddress = bytes.baseAddress!
            // SAFETY: `dotStart` is found within `bytes`, and the derived IPv4 tail buffer does not escape.
            let v4Bytes = UnsafeBufferPointer(start: baseAddress + dotStart, count: count - dotStart)
            guard let v4Value = _parseIPv4TextCore(v4Bytes) else { return nil }

            words[wordCount] = UInt16((v4Value >> 16) & 0xFFFF)
            words[wordCount + 1] = UInt16(v4Value & 0xFFFF)
            wordCount += 2
        } else if hasDigits {
            guard wordCount < 8 else { return nil }
            words[wordCount] = UInt16(currentWord)
            wordCount += 1
        }

        if doubleColonIndex >= 0 {
            let rightCount = wordCount - doubleColonIndex
            if rightCount > 0 {
                var readIndex = wordCount - 1
                var writeIndex = 7
                while readIndex >= doubleColonIndex {
                    words[writeIndex] = words[readIndex]
                    if readIndex < 8 - rightCount {
                        words[readIndex] = 0
                    }
                    readIndex -= 1
                    writeIndex -= 1
                }
            }
        } else {
            guard wordCount == 8 else { return nil }
        }

        return _packIPv6Words(words)
    }

    @inline(__always)
    // SAFETY: The canonical parser first checks the exact 39-byte length before fixed subscripts.
    private static func _parseCanonicalIPv6Text(_ bytes: UnsafeBufferPointer<UInt8>) -> UInt128? {
        let hextetCount = 8
        let hexDigitsPerHextet = 4
        let colonSeparatorCount = hextetCount - 1
        // Fast path for the full eight-hextet form:
        // ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        // This count excludes any C NUL terminator and does not cover mixed IPv4 text.
        let canonicalFullIPv6TextCount = (hextetCount * hexDigitsPerHextet) + colonSeparatorCount
        let colon = UInt8(ascii: ":")

        guard bytes.count == canonicalFullIPv6TextCount else { return nil }
        guard bytes[4] == colon, bytes[9] == colon, bytes[14] == colon, bytes[19] == colon,
              bytes[24] == colon, bytes[29] == colon, bytes[34] == colon else {
            return nil
        }

        @inline(__always)
        func hexNibble(_ byte: UInt8) -> UInt16? {
            switch byte {
            case 48...57:
                return UInt16(byte - 48)
            case 65...70:
                return UInt16(byte - 65 + 10)
            case 97...102:
                return UInt16(byte - 97 + 10)
            default:
                return nil
            }
        }

        @inline(__always)
        func parseWord(at start: Int) -> UInt16? {
            guard let a = hexNibble(bytes[start]),
                  let b = hexNibble(bytes[start + 1]),
                  let c = hexNibble(bytes[start + 2]),
                  let d = hexNibble(bytes[start + 3]) else {
                return nil
            }
            return (a << 12) | (b << 8) | (c << 4) | d
        }

        guard let w0 = parseWord(at: 0),
              let w1 = parseWord(at: 5),
              let w2 = parseWord(at: 10),
              let w3 = parseWord(at: 15),
              let w4 = parseWord(at: 20),
              let w5 = parseWord(at: 25),
              let w6 = parseWord(at: 30),
              let w7 = parseWord(at: 35) else {
            return nil
        }

        return _packIPv6Words(SIMD8(w0, w1, w2, w3, w4, w5, w6, w7))
    }

    @inline(__always)
    private static func _packIPv6Words(_ words: SIMD8<UInt16>) -> UInt128 {
        let shifts = SIMD4<UInt64>(48, 32, 16, 0)
        let lowHalf = words.lowHalf
        let highHalf = words.highHalf
        let highBits = (SIMD4<UInt64>(UInt64(lowHalf[0]), UInt64(lowHalf[1]), UInt64(lowHalf[2]), UInt64(lowHalf[3])) &<< shifts).wrappedSum()
        let lowBits = (SIMD4<UInt64>(UInt64(highHalf[0]), UInt64(highHalf[1]), UInt64(highHalf[2]), UInt64(highHalf[3])) &<< shifts).wrappedSum()
        return (UInt128(highBits) << 64) | UInt128(lowBits)
    }
}
