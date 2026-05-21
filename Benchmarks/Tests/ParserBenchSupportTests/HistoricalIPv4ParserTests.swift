import Testing
@testable import ParserBenchSupport

@Suite("Historical IPv4 Parser Tests")
struct HistoricalIPv4ParserTests {
    @Test("Historical IPv4 parsers agree on valid and invalid input")
    func historicalParsersMatchExpectedResults() {
        let validCases: [(String, UInt32)] = [
            ("192.168.1.1", 0xC0A80101),
            ("255.255.255.255", UInt32.max),
            ("001.002.003.004", 0x01020304),
        ]

        for (literal, expected) in validCases {
            #expect(HistoricalParsers.parseIPv4TextV1(literal) == expected)
            #expect(HistoricalParsers.parseIPv4TextV2(literal) == expected)
            #expect(HistoricalParsers.parseIPv4TextV3(literal) == expected)
        }

        let invalidCases = [
            "256.0.0.1",
            "1..2.3",
            "1.2.3",
            "1.2.3.4.5",
            "abc",
        ]

        for literal in invalidCases {
            #expect(HistoricalParsers.parseIPv4TextV1(literal) == nil)
            #expect(HistoricalParsers.parseIPv4TextV2(literal) == nil)
            #expect(HistoricalParsers.parseIPv4TextV3(literal) == nil)
        }
    }
}
