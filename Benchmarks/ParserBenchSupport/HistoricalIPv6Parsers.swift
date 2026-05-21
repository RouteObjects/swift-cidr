public extension HistoricalParsers {
    static func parseIPv6TextV1(_ string: String) -> UInt128? {
        guard let expanded = expandIPv6Text(string) else { return nil }
        let segments = expanded.split(separator: ":")
        guard segments.count == 8 else { return nil }

        let words = segments.compactMap { UInt16($0, radix: 16) }
        guard words.count == 8 else { return nil }

        let high = words.prefix(4).reduce(UInt64.zero) { partialResult, word in
            (partialResult << 16) | UInt64(word)
        }
        let low = words.suffix(4).reduce(UInt64.zero) { partialResult, word in
            (partialResult << 16) | UInt64(word)
        }
        return (UInt128(high) << 64) | UInt128(low)
    }

    static func parseIPv6TextV2(_ string: String) -> UInt128? {
        guard let expanded = expandIPv6Text(string) else { return nil }
        let segments = expanded.split(separator: ":")
        guard segments.count == 8 else { return nil }

        let words = segments.compactMap { UInt16($0, radix: 16) }
        guard words.count == 8 else { return nil }

        let highSegments = SIMD4(
            UInt64(words[0]),
            UInt64(words[1]),
            UInt64(words[2]),
            UInt64(words[3])
        )
        let lowSegments = SIMD4(
            UInt64(words[4]),
            UInt64(words[5]),
            UInt64(words[6]),
            UInt64(words[7])
        )
        let shiftPositions = SIMD4<UInt64>(48, 32, 16, 0)
        let highBits = (highSegments &<< shiftPositions).wrappedSum()
        let lowBits = (lowSegments &<< shiftPositions).wrappedSum()
        return (UInt128(highBits) << 64) | UInt128(lowBits)
    }

    static func parseIPv6TextV3(_ string: String) -> UInt128? {
        if let result = string.utf8.withContiguousStorageIfAvailable({ bytes -> UInt128? in
            _parseIPv6TextV3Core(bytes)
        }) {
            return result
        }

        return _parseIPv6TextV3Core(Array(string.utf8))
    }

    private static func _parseIPv6TextV3Core<T: BidirectionalCollection>(_ bytes: T) -> UInt128? where T.Element == UInt8 {
        guard !bytes.isEmpty else { return nil }

        var rawWords = (UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0))
        var wordCount = 0
        var doubleColonIndex: Int? = nil

        var index = bytes.startIndex
        var currentWord: UInt64 = 0
        var hasDigits = false
        var seenDot = false

        func writeWord(_ word: UInt64, at index: Int) {
            switch index {
            case 0: rawWords.0 = word
            case 1: rawWords.1 = word
            case 2: rawWords.2 = word
            case 3: rawWords.3 = word
            case 4: rawWords.4 = word
            case 5: rawWords.5 = word
            case 6: rawWords.6 = word
            case 7: rawWords.7 = word
            default: break
            }
        }

        while index < bytes.endIndex {
            let byte = bytes[index]
            if byte == 58 {
                let nextIndex = bytes.index(after: index)
                if nextIndex < bytes.endIndex && bytes[nextIndex] == 58 {
                    guard doubleColonIndex == nil else { return nil }
                    if hasDigits {
                        writeWord(currentWord, at: wordCount)
                        wordCount += 1
                    }
                    doubleColonIndex = wordCount
                    currentWord = 0
                    hasDigits = false
                    index = bytes.index(after: nextIndex)
                    continue
                }

                guard hasDigits else { return nil }
                guard wordCount < 8 else { return nil }
                writeWord(currentWord, at: wordCount)
                wordCount += 1
                currentWord = 0
                hasDigits = false
            } else if byte == 46 {
                seenDot = true
                break
            } else {
                let value: UInt64
                if byte >= 48 && byte <= 57 {
                    value = UInt64(byte - 48)
                } else if byte >= 97 && byte <= 102 {
                    value = UInt64(byte - 97 + 10)
                } else if byte >= 65 && byte <= 70 {
                    value = UInt64(byte - 65 + 10)
                } else {
                    return nil
                }

                currentWord = (currentWord << 4) | value
                guard currentWord <= 0xFFFF else { return nil }
                hasDigits = true
            }
            index = bytes.index(after: index)
        }

        if seenDot {
            var dotStart = index
            while dotStart > bytes.startIndex && bytes[bytes.index(before: dotStart)] != 58 {
                dotStart = bytes.index(before: dotStart)
            }

            var v4Value: UInt32 = 0
            var octet: UInt32 = 0
            var dotCount = 0
            var hasOctetDigits = false

            for byte in bytes[dotStart...] {
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
            }

            guard dotCount == 3 && hasOctetDigits else { return nil }
            v4Value = (v4Value << 8) | octet
            guard wordCount < 7 else { return nil }
            writeWord(UInt64((v4Value >> 16) & 0xFFFF), at: wordCount)
            writeWord(UInt64(v4Value & 0xFFFF), at: wordCount + 1)
            wordCount += 2
        } else if hasDigits {
            guard wordCount < 8 else { return nil }
            writeWord(currentWord, at: wordCount)
            wordCount += 1
        }

        var w0: UInt64 = 0
        var w1: UInt64 = 0
        var w2: UInt64 = 0
        var w3: UInt64 = 0
        var w4: UInt64 = 0
        var w5: UInt64 = 0
        var w6: UInt64 = 0
        var w7: UInt64 = 0

        func getRaw(_ index: Int) -> UInt64 {
            switch index {
            case 0: return rawWords.0
            case 1: return rawWords.1
            case 2: return rawWords.2
            case 3: return rawWords.3
            case 4: return rawWords.4
            case 5: return rawWords.5
            case 6: return rawWords.6
            case 7: return rawWords.7
            default: return 0
            }
        }

        if let doubleColonIndex {
            let rightCount = wordCount - doubleColonIndex
            if doubleColonIndex >= 1 { w0 = rawWords.0 }
            if doubleColonIndex >= 2 { w1 = rawWords.1 }
            if doubleColonIndex >= 3 { w2 = rawWords.2 }
            if doubleColonIndex >= 4 { w3 = rawWords.3 }
            if doubleColonIndex >= 5 { w4 = rawWords.4 }
            if doubleColonIndex >= 6 { w5 = rawWords.5 }
            if doubleColonIndex >= 7 { w6 = rawWords.6 }

            for offset in 0..<rightCount {
                let source = getRaw(wordCount - 1 - offset)
                switch 7 - offset {
                case 0: w0 = source
                case 1: w1 = source
                case 2: w2 = source
                case 3: w3 = source
                case 4: w4 = source
                case 5: w5 = source
                case 6: w6 = source
                case 7: w7 = source
                default: break
                }
            }
        } else {
            guard wordCount == 8 else { return nil }
            (w0, w1, w2, w3, w4, w5, w6, w7) = rawWords
        }

        let highBits = (SIMD4(w0, w1, w2, w3) &<< SIMD4<UInt64>(48, 32, 16, 0)).wrappedSum()
        let lowBits = (SIMD4(w4, w5, w6, w7) &<< SIMD4<UInt64>(48, 32, 16, 0)).wrappedSum()
        return (UInt128(highBits) << 64) | UInt128(lowBits)
    }

    private static func expandIPv6Text(_ string: String) -> String? {
        var address = string
        if address.contains(".") {
            guard let lastColon = address.lastIndex(of: ":") else { return nil }
            let dottedQuad = String(address[address.index(after: lastColon)...])
            guard let embeddedIPv4 = parseIPv4TextV1(dottedQuad) else { return nil }
            let highWord = String((embeddedIPv4 >> 16) & 0xFFFF, radix: 16)
            let lowWord = String(embeddedIPv4 & 0xFFFF, radix: 16)
            address = "\(address[..<lastColon]):\(highWord):\(lowWord)"
        }

        var doubleColonLowerBound: String.Index? = nil
        var scanIndex = address.startIndex
        while scanIndex < address.endIndex {
            if address[scanIndex] == ":" {
                let nextIndex = address.index(after: scanIndex)
                if nextIndex < address.endIndex, address[nextIndex] == ":" {
                    doubleColonLowerBound = scanIndex
                    break
                }
            }
            scanIndex = address.index(after: scanIndex)
        }

        if let doubleColonLowerBound {
            let doubleColonUpperBound = address.index(doubleColonLowerBound, offsetBy: 2)
            let left = address[..<doubleColonLowerBound].split(separator: ":")
            let right = address[doubleColonUpperBound...].split(separator: ":")
            let missing = 8 - (left.count + right.count)
            let expansion = Array(repeating: "0", count: max(0, missing)).joined(separator: ":")
            let leftPart = left.isEmpty ? "" : left.joined(separator: ":") + ":"
            let rightPart = right.isEmpty ? "" : ":" + right.joined(separator: ":")
            address = leftPart + expansion + rightPart
        }

        return address
    }
}
