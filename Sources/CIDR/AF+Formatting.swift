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
    private static let ipv4SingleDecimalDigitOctetMask: UInt32 = 0xF0F0_F0F0
    private static let ipv4DecimalDigitCarryBias: UInt32 = 0x0606_0606
    private static let ipv4DecimalDigitCarryMask: UInt32 = 0x1010_1010
    private static let decimalOctetTriplets: StaticString = "000001002003004005006007008009010011012013014015016017018019020021022023024025026027028029030031032033034035036037038039040041042043044045046047048049050051052053054055056057058059060061062063064065066067068069070071072073074075076077078079080081082083084085086087088089090091092093094095096097098099100101102103104105106107108109110111112113114115116117118119120121122123124125126127128129130131132133134135136137138139140141142143144145146147148149150151152153154155156157158159160161162163164165166167168169170171172173174175176177178179180181182183184185186187188189190191192193194195196197198199200201202203204205206207208209210211212213214215216217218219220221222223224225226227228229230231232233234235236237238239240241242243244245246247248249250251252253254255"

    @inline(__always)
    // SAFETY: The caller provides a buffer large enough for the fixed IPv4-mapped IPv6 prefix.
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
    // SAFETY: The caller provides a buffer large enough for the maximum IPv4 literal length.
    private static func writeIPv4AddressLiteral(
        _ address: UInt32,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        // Fast-path 0...9 octets; the first mask proves each byte is < 16, then adding
        // 6 exposes decimal values 10...15 as a 0x10 carry bit in each byte.
        if (address & ipv4SingleDecimalDigitOctetMask) == 0,
           ((address &+ ipv4DecimalDigitCarryBias) & ipv4DecimalDigitCarryMask) == 0 {
            writeSingleDigitIPv4AddressLiteral(address, into: buffer, at: &writeIndex)
            return
        }

        writeDecimalOctet((address &>> 24) & 0xFF, into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet((address &>> 16) & 0xFF, into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet((address &>> 8) & 0xFF, into: buffer, at: &writeIndex)
        writeDot(into: buffer, at: &writeIndex)
        writeDecimalOctet(address & 0xFF, into: buffer, at: &writeIndex)
    }

    @inline(__always)
    // SAFETY: The caller has proven all four IPv4 octets are decimal single digits.
    private static func writeSingleDigitIPv4AddressLiteral(
        _ address: UInt32,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        // Keep all-single-digit IPv4 literals on a compact no-table path for zero/simple cases.
        buffer[writeIndex] = asciiZero &+ UInt8((address &>> 24) & 0xFF)
        buffer[writeIndex &+ 1] = asciiDot
        buffer[writeIndex &+ 2] = asciiZero &+ UInt8((address &>> 16) & 0xFF)
        buffer[writeIndex &+ 3] = asciiDot
        buffer[writeIndex &+ 4] = asciiZero &+ UInt8((address &>> 8) & 0xFF)
        buffer[writeIndex &+ 5] = asciiDot
        buffer[writeIndex &+ 6] = asciiZero &+ UInt8(address & 0xFF)
        writeIndex &+= 7
    }

    @inline(__always)
    // SAFETY: The caller provides writable capacity for one ASCII dot at `writeIndex`.
    private static func writeDot(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        buffer[writeIndex] = asciiDot
        writeIndex &+= 1
    }

    @inline(__always)
    // SAFETY: The caller provides writable capacity for the maximum three decimal octet digits.
    private static func writeDecimalOctet(
        _ value: UInt32,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at writeIndex: inout Int
    ) {
        if value < 10 {
            buffer[writeIndex] = asciiZero &+ UInt8(value)
            writeIndex &+= 1
            return
        }

        let offset = Int(value &* 3)
        let table = decimalOctetTriplets.utf8Start

        // Use fixed-width decimal triplet lookup for multi-digit octets to avoid divide/modulo.
        if value >= 100 {
            buffer[writeIndex] = table[offset]
            buffer[writeIndex &+ 1] = table[offset &+ 1]
            buffer[writeIndex &+ 2] = table[offset &+ 2]
            writeIndex &+= 3
        } else {
            buffer[writeIndex] = table[offset &+ 1]
            buffer[writeIndex &+ 1] = table[offset &+ 2]
            writeIndex &+= 2
        }
    }
}
