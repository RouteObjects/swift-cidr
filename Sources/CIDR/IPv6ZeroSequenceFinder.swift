internal enum IPv6ZeroSequenceFinder {
    internal typealias Word = UInt16

    internal static func longestZeroSequenceRange<Words>(in words: Words) -> Range<Words.Index>?
    where Words: Collection, Words.Element == Word {
        scanLongestCompressibleZeroRun(in: words)
    }

    // SAFETY: `bytes` must point to 16 network-order IPv6 bytes for the duration of the call.
    internal static func longestZeroSequenceRange(inIPv6Bytes bytes: UnsafePointer<UInt8>) -> Range<Int>? {
        var bestStart = -1
        var bestCount = 0
        var currentStart = -1
        var currentCount = 0
        var position = 0

        while position < 8 {
            let offset = position * 2
            // The byte-OR predicate is endian-independent, alignment-safe, and keeps zero detection portable.
            let isZero = (bytes[offset] | bytes[offset + 1]) == 0
            if isZero {
                if currentStart == -1 {
                    currentStart = position
                }
                currentCount += 1
                position += 1
                continue
            }

            if currentCount > bestCount {
                bestStart = currentStart
                bestCount = currentCount
            }

            currentStart = -1
            currentCount = 0
            position += 1
        }

        if currentCount > bestCount {
            bestStart = currentStart
            bestCount = currentCount
        }

        guard bestCount >= 2 else { return nil }
        return bestStart..<(bestStart + bestCount)
    }

    private static func scanLongestCompressibleZeroRun<Source>(
        in words: Source
    ) -> Range<Source.Index>?
    where Source: Collection, Source.Element == Word {
        var bestRange: Range<Source.Index>?
        var bestCount = 0
        var currentStart: Source.Index?
        var currentCount = 0

        for index in words.indices {
            if words[index] == 0 {
                if currentStart == nil {
                    currentStart = index
                }
                currentCount += 1
                continue
            }

            if let start = currentStart, currentCount > bestCount {
                // Preserve RFC 5952 leftmost tie behavior by only replacing strictly longer runs.
                bestRange = start..<index
                bestCount = currentCount
            }

            currentStart = nil
            currentCount = 0
        }

        if let start = currentStart, currentCount > bestCount {
            bestRange = start..<words.endIndex
            bestCount = currentCount
        }

        guard bestCount >= 2 else { return nil }
        return bestRange
    }

}
