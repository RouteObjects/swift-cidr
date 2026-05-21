import Testing
@testable import CIDR

@Suite("IPv6 Parsing Tests")
struct IPv6ParsingTests {
    @Test("Leading double-colon IPv6 shorthand parses correctly")
    func parsesLeadingDoubleColonShorthand() throws {
        let host = try #require(IPAddress<V6>.v6("::1"))

        #expect(host.address == UInt128(1))
    }

    @Test("IPv4-mapped mixed notation parses through the IPv6 family parser")
    func parsesMappedMixedNotation() throws {
        let host = try #require(IPAddress<V6>.v6("::ffff:192.0.2.1"))
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)

        #expect(host.address == mappedAddress)

        let network = IPNetwork<V6>(host: host)
        #expect(network.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
    }

    @Test("IPv6 parser rejects hextets above ffff")
    func rejectsOversizedHextets() {
        #expect(IPAddress<V6>.v6("2001:db8::10000:1") == nil)
    }

    @Test("Selected IPv6 parser handles canonical, shorthand, middle-compressed, and mapped input")
    func selectedIPv6ParserHandlesSupportedInput() throws {
        let expectedLoopbackish = (UInt128(0x20010DB8) << 96) | UInt128(1)
        let expectedMiddleCompressed = (UInt128(0x20010DB885A30000) << 64) | UInt128(0x00008A2E03707334)
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)

        #expect(AF.V6.parseAddress("2001:0db8:0000:0000:0000:0000:0000:0001") == expectedLoopbackish)
        #expect(AF.V6.parseAddress("::1") == UInt128(1))
        #expect(AF.V6.parseAddress("2001:db8::1") == expectedLoopbackish)
        #expect(AF.V6.parseAddress("2001:db8:85a3::8a2e:370:7334") == expectedMiddleCompressed)
        #expect(AF.V6.parseAddress("::ffff:192.0.2.1") == mappedAddress)

        #expect(AF.V6.parseAddress("2001:db8:::1") == nil)
        #expect(AF.V6.parseAddress("2001:db8::g1") == nil)
    }
}
