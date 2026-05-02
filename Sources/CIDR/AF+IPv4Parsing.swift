extension AF {
    internal static func parseIPv4Text(_ string: String) -> UInt32? {
        // Copying into a var and forcing withUTF8 keeps the hot path on contiguous bytes.
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4TextCore(bytes)
        }
    }

    @inline(__always)
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
}

extension AF.V4 {
    internal static func prefixLength(fromNetmask netmaskString: String) -> Int? {
        guard let maskValue = AF.parseIPv4Text(netmaskString) else { return nil }
        let leadingOnes = (~maskValue).leadingZeroBitCount
        guard maskValue == (UInt32.max << (32 - leadingOnes)) else { return nil }
        return leadingOnes
    }
}
