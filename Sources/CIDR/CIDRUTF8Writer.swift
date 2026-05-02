/// Low-level UTF-8 formatting hooks for companion packages.
///
/// This SPI keeps NIO-specific formatting out of the core package while still letting trusted
/// adapters write CIDR text directly into byte-oriented sinks.
@_spi(NIO)
public enum CIDRUTF8Writer {
    /// The longest possible output from ``writeCompressedIPv6AddressLiteral(_:into:)``.
    ///
    /// This is the pure hexadecimal IPv6 form without a C NUL terminator:
    /// `ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff`.utf8.count
    public static let maximumCompressedIPv6AddressLiteralUTF8Count =
        (ipv6HextetCount * maximumHexDigitsPerIPv6Hextet) + maximumColonSeparatorsInIPv6Literal

    /// Writes an RFC 5952-style compressed IPv6 address literal into a caller-provided buffer.
    ///
    /// The buffer must contain at least ``maximumCompressedIPv6AddressLiteralUTF8Count`` writable bytes.
    /// The return value is the exact number of bytes initialized.
    public static func writeCompressedIPv6AddressLiteral(
        _ address: UInt128,
        into rawBuffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        precondition(
            rawBuffer.count >= maximumCompressedIPv6AddressLiteralUTF8Count,
            "IPv6 formatter buffer must have enough writable bytes for the maximum compressed IPv6 literal."
        )
        let buffer = rawBuffer.bindMemory(to: UInt8.self)
        return writeCompressedIPv6AddressLiteral(address, into: buffer)
    }
}

extension CIDRUTF8Writer {
    private static let ipv6HextetCount = 8
    private static let maximumHexDigitsPerIPv6Hextet = 4
    private static let maximumColonSeparatorsInIPv6Literal = ipv6HextetCount - 1

    internal static func fullIPv6AddressLiteral(_ address: UInt128) -> String {
        String(unsafeUninitializedCapacity: maximumCompressedIPv6AddressLiteralUTF8Count) { buffer in
            let written = writeFullIPv6AddressLiteral(address, into: buffer)
            return written
        }
    }

    internal static func compressedIPv6AddressLiteral(_ address: UInt128) -> String {
        if address == 0 { return "::" }

        return withIPv6Bytes(address) { addressBytes in
            let bytes = addressBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            let zeroRun = IPv6ZeroSequenceFinder.longestZeroSequenceRange(inIPv6Bytes: bytes)
            return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: maximumCompressedIPv6AddressLiteralUTF8Count) { buffer in
                // Bind network-order storage once and keep the hot formatter path off raw-buffer subscripts.
                let written = writeCompressedIPv6AddressLiteral(bytes, zeroRun: zeroRun, into: buffer)
                return String(decoding: UnsafeBufferPointer(start: buffer.baseAddress!, count: written), as: UTF8.self)
            }
        }
    }

    @inline(__always)
    private static func withIPv6Bytes<Result>(
        _ address: UInt128,
        _ body: (UnsafeRawBufferPointer) -> Result
    ) -> Result {
        var networkOrder = address.bigEndian
        return withUnsafeBytes(of: &networkOrder, body)
    }

    internal static func writeCompressedIPv6AddressLiteral(
        _ address: UInt128,
        into buffer: UnsafeMutableBufferPointer<UInt8>
    ) -> Int {
        withIPv6Bytes(address) { addressBytes in
            let bytes = addressBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return writeCompressedIPv6AddressLiteral(
                bytes,
                zeroRun: IPv6ZeroSequenceFinder.longestZeroSequenceRange(inIPv6Bytes: bytes),
                into: buffer
            )
        }
    }

    internal static func writeFullIPv6AddressLiteral(
        _ address: UInt128,
        into buffer: UnsafeMutableBufferPointer<UInt8>
    ) -> Int {
        withIPv6Bytes(address) { addressBytes in
            let bytes = addressBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return writeFullIPv6AddressLiteral(bytes, into: buffer)
        }
    }

    internal static func writeFullIPv6AddressLiteral(
        _ addressBytes: UnsafePointer<UInt8>,
        into buffer: UnsafeMutableBufferPointer<UInt8>
    ) -> Int {
        var writeIndex = 0

        for position in 0..<ipv6HextetCount {
            if position > 0 {
                buffer[writeIndex] = asciiColon
                writeIndex += 1
            }

            let offset = position * 2
            // Share the proven hextet writer with full IPv6 formatting and avoid segment Strings.
            writeHextet(left: addressBytes[offset], right: addressBytes[offset + 1], into: buffer, at: &writeIndex)
        }

        return writeIndex
    }

    internal static func writeCompressedIPv6AddressLiteral(
        _ addressBytes: UnsafePointer<UInt8>,
        zeroRun: Range<Int>?,
        into buffer: UnsafeMutableBufferPointer<UInt8>
    ) -> Int {
        let zeroStart = zeroRun?.lowerBound ?? -1
        let zeroEnd = zeroRun?.upperBound ?? -1
        var writeIndex = 0
        var needsSeparator = false
        var position = 0

        while position < 8 {
            if position == zeroStart {
                buffer[writeIndex] = asciiColon
                writeIndex += 1
                buffer[writeIndex] = asciiColon
                writeIndex += 1
                position = zeroEnd
                needsSeparator = false
                continue
            }

            if needsSeparator {
                buffer[writeIndex] = asciiColon
                writeIndex += 1
            }

            let offset = position * 2
            writeHextet(left: addressBytes[offset], right: addressBytes[offset + 1], into: buffer, at: &writeIndex)
            needsSeparator = true
            position += 1
        }

        return writeIndex
    }
    
    private static let asciiColon = UInt8(ascii: ":")
    private static let lowercaseHexDigits: StaticString = "0123456789abcdef"

    @inline(__always)
    private static func writeHextet(
        left: UInt8,
        right: UInt8,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        // Combine into a single 16-bit word
        let hextet = (UInt16(left) &<< 8) | UInt16(right)
        // Derive the exact digit count from the UInt16 leading-zero count, avoiding the nibble-by-nibble branch ladder.
        // Branchless math to find exact digit count (1, 2, 3, or 4)
        // - .leadingZeroBitCount returns 0 to 16.
        // - Shift right by 2 (divide by 4) to get leading zero hex digits (0 to 4).
        // - Subtract from 4 to get digits to write.
        // - Use max(1, ...) to ensure "0x0000" writes at least one "0".
        // Swift's max() compiles to a branchless CSEL (Conditional Select) instruction on ARM64!
        let digitsToWrite = max(1, 4 &- (hextet.leadingZeroBitCount &>> 2))
        let table = lowercaseHexDigits.utf8Start

        switch digitsToWrite {
        case 4:
            buffer[writeIndex] = table[Int(hextet &>> 12)]
            buffer[writeIndex &+ 1] = table[Int((hextet &>> 8) & 0x0F)]
            buffer[writeIndex &+ 2] = table[Int((hextet &>> 4) & 0x0F)]
            buffer[writeIndex &+ 3] = table[Int(hextet & 0x0F)]
        case 3:
            buffer[writeIndex] = table[Int((hextet &>> 8) & 0x0F)]
            buffer[writeIndex &+ 1] = table[Int((hextet &>> 4) & 0x0F)]
            buffer[writeIndex &+ 2] = table[Int(hextet & 0x0F)]
        case 2:
            buffer[writeIndex] = table[Int((hextet &>> 4) & 0x0F)]
            buffer[writeIndex &+ 1] = table[Int(hextet & 0x0F)]
        default:
            buffer[writeIndex] = table[Int(hextet & 0x0F)]
        }

        writeIndex &+= digitsToWrite
    }
}
