extension AF {
    internal static func formatV4(_ address: UInt32) -> String {
        String(unsafeUninitializedCapacity: maximumIPv4AddressLiteralUTF8Count) { buffer in
            var writeIndex = 0
            // Avoid interpolation on the IPv4 hot path by writing decimal octets directly.
            writeIPv4AddressLiteral(address, into: buffer, at: &writeIndex)
            return writeIndex
        }
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
            writeIPv4AddressLiteral(UInt32(truncatingIfNeeded: address), into: buffer, at: &writeIndex)
            return writeIndex
        }
    }

    private static let ipv4OctetCount = 4
    private static let maximumDecimalDigitsPerIPv4Octet = 3
    private static let maximumDotSeparatorsInIPv4Literal = ipv4OctetCount - 1
    private static let maximumIPv4AddressLiteralUTF8Count =
        (ipv4OctetCount * maximumDecimalDigitsPerIPv4Octet) + maximumDotSeparatorsInIPv4Literal
    private static let ipv4MappedIPv6Prefix: StaticString = "::ffff:"
    private static let ipv4MappedIPv6PrefixUTF8Count = "::ffff:".utf8.count
    private static let maximumIPv4MappedIPv6AddressLiteralUTF8Count =
        ipv4MappedIPv6PrefixUTF8Count + maximumIPv4AddressLiteralUTF8Count

    private static let asciiDot = UInt8(ascii: ".")
    private static let asciiZero = UInt8(ascii: "0")

    @inline(__always)
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

    @inline(__always)
    private static func writeIPv4AddressLiteral(
        _ address: UInt32,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        writeDecimalOctet(UInt8(truncatingIfNeeded: address >> 24), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address >> 16), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address >> 8), into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(UInt8(truncatingIfNeeded: address), into: buffer, at: &writeIndex)
    }

    @inline(__always)
    private static func writeDot(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        buffer[writeIndex] = asciiDot
        writeIndex &+= 1
    }

    @inline(__always)
    private static func writeDecimalOctet(
        _ value: UInt8,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        let digitsToWrite = decimalDigitCount(value)

        switch digitsToWrite {
        case 3:
            buffer[writeIndex] = asciiZero &+ (value / 100)
            buffer[writeIndex &+ 1] = asciiZero &+ ((value / 10) % 10)
            buffer[writeIndex &+ 2] = asciiZero &+ (value % 10)
        case 2:
            buffer[writeIndex] = asciiZero &+ (value / 10)
            buffer[writeIndex &+ 1] = asciiZero &+ (value % 10)
        default:
            buffer[writeIndex] = asciiZero &+ value
        }

        writeIndex &+= digitsToWrite
    }

    @inline(__always)
    private static func decimalDigitCount(_ value: UInt8) -> Int {
        if value >= 100 { return 3 }
        if value >= 10 { return 2 }
        return 1
    }
}
