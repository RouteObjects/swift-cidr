import Testing
@testable import ParserBenchSupport

@Suite("Historical IPv6 Parser Tests")
struct HistoricalIPv6ParserTests {
    @Test("Historical IPv6 parsers cover canonical, shorthand, middle-compressed, and mapped forms")
    func historicalParsersMatchExpectedResults() {
        let canonical = "2001:0db8:0000:0000:0000:0000:0000:0001"
        let shorthand = "2001:db8::1"
        let middleCompressed = "2001:db8:85a3::8a2e:370:7334"
        let mapped = "::ffff:192.0.2.1"

        let expectedLoopbackish = (UInt128(0x20010DB8) << 96) | UInt128(1)
        let expectedMiddleCompressed = (UInt128(0x20010DB885A30000) << 64) | UInt128(0x00008A2E03707334)
        let expectedMapped = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)

        #expect(HistoricalParsers.parseIPv6TextV1(canonical) == expectedLoopbackish)
        #expect(HistoricalParsers.parseIPv6TextV2(canonical) == expectedLoopbackish)
        #expect(HistoricalParsers.parseIPv6TextV3(canonical) == expectedLoopbackish)

        #expect(HistoricalParsers.parseIPv6TextV1("::1") == UInt128(1))
        #expect(HistoricalParsers.parseIPv6TextV2("::1") == UInt128(1))
        #expect(HistoricalParsers.parseIPv6TextV3("::1") == UInt128(1))

        #expect(HistoricalParsers.parseIPv6TextV1(shorthand) == expectedLoopbackish)
        #expect(HistoricalParsers.parseIPv6TextV2(shorthand) == expectedLoopbackish)
        #expect(HistoricalParsers.parseIPv6TextV3(shorthand) == expectedLoopbackish)

        #expect(HistoricalParsers.parseIPv6TextV1(middleCompressed) == expectedMiddleCompressed)
        #expect(HistoricalParsers.parseIPv6TextV2(middleCompressed) == expectedMiddleCompressed)
        #expect(HistoricalParsers.parseIPv6TextV3(middleCompressed) == expectedMiddleCompressed)

        #expect(HistoricalParsers.parseIPv6TextV1(mapped) == expectedMapped)
        #expect(HistoricalParsers.parseIPv6TextV2(mapped) == expectedMapped)
        #expect(HistoricalParsers.parseIPv6TextV3(mapped) == expectedMapped)

        let invalidCases = [
            "2001:db8::g1",
            "2001:db8::10000:1",
        ]

        for literal in invalidCases {
            #expect(HistoricalParsers.parseIPv6TextV1(literal) == nil)
            #expect(HistoricalParsers.parseIPv6TextV2(literal) == nil)
            #expect(HistoricalParsers.parseIPv6TextV3(literal) == nil)
        }

        #expect(HistoricalParsers.parseIPv6TextV3("2001:db8:::1") == nil)
    }
}
