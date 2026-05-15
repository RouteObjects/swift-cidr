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

import Testing
@testable import CIDR

@Suite("IPv6 Compression Tests")
struct IPv6CompressionTests {
    @Test("Compressed formatter shortens a middle zero run")
    func compressesMiddleRun() throws {
        let host = try #require(IPv6Address("2001:db8:0:0:0:0:0:1"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "2001:db8::1")
    }

    @Test("Compressed formatter preserves a single zero hextet")
    func preservesSingleZeroHextet() throws {
        let host = try #require(IPv6Address("2001:db8:0:1:2:3:4:5"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "2001:db8:0:1:2:3:4:5")
    }

    @Test("Compressed formatter prefers the leftmost longest zero run")
    func prefersLeftmostLongestRun() throws {
        let host = try #require(IPv6Address("2001:0:0:1:0:0:1:1"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "2001::1:0:0:1:1")
    }

    @Test("Compressed formatter handles all-zero IPv6")
    func compressesAllZeroIPv6() throws {
        let host = try #require(IPv6Address("0:0:0:0:0:0:0:0"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "::")
    }

    @Test("Compressed formatter handles a trailing zero run")
    func compressesTrailingRun() throws {
        let host = try #require(IPv6Address("2001:db8:1:0:0:0:0:0"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "2001:db8:1::")
    }

    @Test("Compressed formatter keeps mapped IPv6 in hexadecimal form")
    func keepsMappedIPv6Hexadecimal() throws {
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)
        let host = IPAddress<V6>(
            address: mappedAddress,
            prefixLength: try #require(PrefixLength<V6>(128))
        )
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "::ffff:c000:201")
        #expect(network.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
    }

    @Test("Compressed formatter handles maximum IPv6 without zero compression")
    func handlesMaximumIPv6() {
        let host = IPAddress<V6>(address: UInt128.max)
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")
    }

    @Test("Compressed formatter handles mixed hextets around a middle zero run")
    func handlesMixedHextetsAroundMiddleRun() {
        let host = IPAddress<V6>(address: 0x85a0_850a_8500_0000_0000_00af_805a_085a)
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.compressed) == "85a0:850a:8500::af:805a:85a")
    }

    @Test("Zero finder reports the longest middle run from words")
    func zeroFinderWordsPath() {
        let words: [UInt16] = [0xBEEF, 0xB00B, 0, 0, 0, 0xABCD, 0, 0xDEAD]

        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: words) == 2..<5)
    }

    @Test("Zero finder handles leading, trailing, all-zero, and tie runs from words")
    func zeroFinderEdgeCasesFromWords() {
        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: [0, 0, 0, 1, 2, 3, 4, 5]) == 0..<3)
        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: [1, 2, 3, 4, 5, 0, 0, 0]) == 5..<8)
        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: [0, 0, 0, 0, 0, 0, 0, 0]) == 0..<8)
        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: [0, 0, 1, 0, 0, 1, 0, 0]) == 0..<2)
    }

    @Test("Zero finder reports the longest middle run from network-order bytes")
    func zeroFinderIPv6BytesPath() {
        let address: UInt128 = 0x2001_0db8_0000_0000_0000_0000_0000_0001
        var networkOrder = address.bigEndian
        // SAFETY: `networkOrder` is a local UInt128, so the byte view is 16 bytes and non-empty.
        let range = withUnsafeBytes(of: &networkOrder) { rawBuffer in
            let bytes = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return IPv6ZeroSequenceFinder.longestZeroSequenceRange(inIPv6Bytes: bytes)
        }

        #expect(range == 2..<7)
    }

    @Test("Zero finder rejects single-zero runs")
    func zeroFinderRejectsSingleZeroRun() {
        let words: [UInt16] = [0x2001, 0x0DB8, 0, 1, 2, 3, 4, 5]

        #expect(IPv6ZeroSequenceFinder.longestZeroSequenceRange(in: words) == nil)
    }
}
