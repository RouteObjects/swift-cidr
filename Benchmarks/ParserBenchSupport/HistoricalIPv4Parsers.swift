public enum HistoricalParsers {}

public extension HistoricalParsers {
    static func parseIPv4TextV1(_ string: String) -> UInt32? {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return nil }

        var result: UInt32 = 0
        for part in parts {
            guard let value = UInt32(part), value <= 255 else { return nil }
            result = (result << 8) | value
        }
        return result
    }

    static func parseIPv4TextV2(_ string: String) -> UInt32? {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return nil }

        let bytes = parts.compactMap { UInt8($0, radix: 10) }
        guard bytes.count == 4 else { return nil }

        let octets = SIMD4(
            UInt32(bytes[0]),
            UInt32(bytes[1]),
            UInt32(bytes[2]),
            UInt32(bytes[3])
        )
        let shiftPositions = SIMD4<UInt32>(24, 16, 8, 0)
        return (octets &<< shiftPositions).wrappedSum()
    }

    static func parseIPv4TextV3(_ string: String) -> UInt32? {
        var result: UInt32 = 0
        var currentOctet: UInt32 = 0
        var octetCount = 0
        var hasDigits = false

        for byte in string.utf8 {
            if byte == 46 {
                guard hasDigits, octetCount < 3 else { return nil }
                result = (result << 8) | currentOctet
                currentOctet = 0
                hasDigits = false
                octetCount += 1
            } else if byte >= 48 && byte <= 57 {
                currentOctet = (currentOctet * 10) + UInt32(byte - 48)
                guard currentOctet <= 255 else { return nil }
                hasDigits = true
            } else {
                return nil
            }
        }

        guard hasDigits, octetCount == 3 else { return nil }
        return (result << 8) | currentOctet
    }
}
