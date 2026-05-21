extension AF {
    /// The selected production IPv6 text parser.
    internal static func parseIPv6Text(_ string: String) -> UInt128? {
        if let result = string.utf8.withContiguousStorageIfAvailable({ bytes -> UInt128? in
            _parseIPv6TextCore(bytes)
        }) {
            return result
        }

        let fallback = Array(string.utf8)
        return fallback.withUnsafeBufferPointer { bytes in
            _parseIPv6TextCore(bytes)
        }
    }

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

        while index < count {
            let byte = bytes[index]
            if byte == 58 {
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
            } else if byte == 46 {
                seenDot = true
                break
            } else {
                guard consumeHexDigit(byte) else { return nil }
            }
            index += 1
        }

        if seenDot {
            var dotStart = index
            while dotStart > 0 && bytes[dotStart - 1] != 58 {
                dotStart -= 1
            }

            var v4Value: UInt32 = 0
            var octet: UInt32 = 0
            var dotCount = 0
            var hasOctetDigits = false
            var v4Index = dotStart

            while v4Index < count {
                let byte = bytes[v4Index]
                if byte == 46 {
                    guard hasOctetDigits && dotCount < 3 else { return nil }
                    v4Value = (v4Value << 8) | octet
                    octet = 0
                    dotCount += 1
                    hasOctetDigits = false
                } else if byte >= 48 && byte <= 57 {
                    octet = (octet * 10) + UInt32(byte - 48)
                    guard octet <= 255 else { return nil }
                    hasOctetDigits = true
                } else {
                    return nil
                }
                v4Index += 1
            }

            guard dotCount == 3 && hasOctetDigits else { return nil }
            v4Value = (v4Value << 8) | octet
            guard wordCount < 7 else { return nil }
            words[wordCount] = UInt16((v4Value >> 16) & 0xFFFF)
            words[wordCount + 1] = UInt16(v4Value & 0xFFFF)
            wordCount += 2
        } else if hasDigits {
            guard wordCount < 8 else { return nil }
            words[wordCount] = UInt16(currentWord)
            wordCount += 1
        }

        // TODO: Optimize
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
