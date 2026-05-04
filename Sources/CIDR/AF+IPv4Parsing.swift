@_spi(Benchmark)
public struct IPv4CIDRParseResult: Sendable, Equatable {
    public let address: UInt32
    public let prefixLength: UInt8
    public let hasExplicitPrefix: Bool

    internal init(address: UInt32, prefixLength: UInt8, hasExplicitPrefix: Bool) {
        self.address = address
        self.prefixLength = prefixLength
        self.hasExplicitPrefix = hasExplicitPrefix
    }
}

extension AF {
    private static let asciiSlash = UInt8(ascii: "/")
    private static let asciiZero = UInt8(ascii: "0")
    private static let ipv4CIDRSlashVector = SIMD16<UInt8>(repeating: UInt8(ascii: "/"))
    private static let ipv4CIDRSlashBitWeights = SIMD16<Int16>(
        -1, -2, -4, -8,
        -16, -32, -64, -128,
        -256, -512, -1024, -2048,
        -4096, -8192, -16384, Int16.min
    )

    internal static func parseIPv4Text(_ string: String) -> UInt32? {
        // Copying into a var and forcing withUTF8 keeps the hot path on contiguous bytes.
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4TextCore(bytes)
        }
    }

    @_spi(Benchmark)
    public static func parseIPv4CIDRTextScalar(
        _ string: String,
        requiresPrefix: Bool
    ) -> IPv4CIDRParseResult? {
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4CIDRTextCore(
                bytes,
                slashIndex: _firstSlashIndexScalar(in: bytes),
                requiresPrefix: requiresPrefix
            )
        }
    }

    @_spi(Benchmark)
    public static func parseIPv4CIDRTextSIMDSlash(
        _ string: String,
        requiresPrefix: Bool
    ) -> IPv4CIDRParseResult? {
        var string = string

        return string.withUTF8 { bytes in
            _parseIPv4CIDRTextCore(
                bytes,
                slashIndex: _firstSlashIndexSIMD(in: bytes),
                requiresPrefix: requiresPrefix
            )
        }
    }

    @_spi(Benchmark)
    public static func parseIPv4CIDRTextSuffix(
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

        let addressBytes = UnsafeBufferPointer(start: baseAddress, count: slashIndex)
        guard let address = _parseIPv4TextCore(addressBytes),
              let prefixLength = _parseStrictIPv4PrefixLength(bytes, start: prefixStart, end: bytes.count)
        else {
            return nil
        }

        return IPv4CIDRParseResult(address: address, prefixLength: prefixLength, hasExplicitPrefix: true)
    }

    @inline(__always)
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
    private static func _firstSlashIndexScalar(in bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        var index = 0
        while index < bytes.count {
            if bytes[index] == asciiSlash {
                return index
            }

            index &+= 1
        }

        return nil
    }

    @inline(__always)
    private static func _firstSlashIndexSIMD(in bytes: UnsafeBufferPointer<UInt8>) -> Int? {
        let laneCount = min(bytes.count, 16)
        guard laneCount > 0 else { return nil }

        var input = SIMD16<UInt8>(repeating: 0)
        var lane = 0
        while lane < laneCount {
            input[lane] = bytes[lane]
            lane &+= 1
        }

        //    Example for "192.168.1.1/24":
        //
        //    1 9 2 . 1 6 8 . 1 . 1 / 2 4
        //    0 1 2 3 4 5 6 7 8 9 10 11 12 13
        //
        //    The slash is at byte index 11.
        //
        //    The SIMD compare produces a lane match at lane 11, the weights turn that into bit 11, and then:
        //
        //    matchBits.trailingZeroBitCount == 11
        //
        //    If no slash exists, matchBits == 0, so the code checks that first before calling trailingZeroBitCount.
        //    For slash at string index 11, the bitmask is:
        //
        //    bit index:  15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
        //    value:       0  0  0  0  1  0 0 0 0 0 0 0 0 0 0 0
        //
        //    Numerically that is:
        //
        //    1 << 11
        //
        //    trailingZeroBitCount counts from bit 0 upward until it finds the first 1:
        //
        //    bits 0...10 are zero = 11 trailing zeros
        //    bit 11 is one
        //
        //    So:
        //
        //    (1 << 11).trailingZeroBitCount == 11


        // `_storage` exposes compare lanes as 0 for false and -1 for true.
        // Multiplying by negative powers of two turns true lanes into a UInt16 bitmask:
        //
        //     string/lane index 0 -> bit 0
        //     string/lane index 1 -> bit 1
        //     ...
        //     string/lane index 15 -> bit 15
        //
        // Therefore a slash at byte index 11 sets bit 11, and trailingZeroBitCount
        // returns 11 because it counts upward from the least-significant bit.
        let matches = (input .== ipv4CIDRSlashVector)._storage
        let matchBits = UInt16(bitPattern: (SIMD16<Int16>(truncatingIfNeeded: matches) &* ipv4CIDRSlashBitWeights).wrappedSum())
        guard matchBits != 0 else { return nil }

        return matchBits.trailingZeroBitCount
    }

    @inline(__always)
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
