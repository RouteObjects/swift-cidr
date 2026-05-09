import Foundation
import Testing
@testable import CIDR

@Suite("IP Summarization Tests")
struct IPSummarizationTests {
    @Test("Summarize complex IPv6 range")
    func complexIPv6Summarization() throws {
        let start = try #require(IPv6Address("2001:db8:0:0:0:0:0:1"))
        let end = try #require(IPv6Address("2001:db8:0:0:0:0:0:f"))

        let result = IPNetwork<V6>.summarize(from: start, to: end)

        #expect(result.count == 4)

        #expect(result[0].prefixLength.intValue == 128)
        #expect(result[1].prefixLength.intValue == 127)
        #expect(result[2].prefixLength.intValue == 126)
        #expect(result[3].prefixLength.intValue == 125)

        #expect(result.first?.first.address == start.address)
        #expect(result.last?.last.address == end.address)
    }

    @Test("Summarize adjacent IPv4 hosts")
    func simpleIPv4Summarization() throws {
        let start = try #require(IPv4Address("192.168.1.1"))
        let end = try #require(IPv4Address("192.168.1.2"))

        let result = IPNetwork<V4>.summarize(from: start, to: end)

        #expect(result.count == 2)
        #expect(result[0].description == "192.168.1.1/32")
        #expect(result[1].description == "192.168.1.2/32")
        #expect(result[0].formatted(.addressOnly) == "192.168.1.1")
        #expect(result[1].formatted(.addressOnly) == "192.168.1.2")
    }

    @Test("Single address range results in one /32")
    func singleAddressSummarization() throws {
        let addr = try #require(IPv4Address("10.0.0.1"))
        let result = IPNetwork<V4>.summarize(from: addr, to: addr)

        #expect(result.count == 1)
        #expect(result.first?.prefixLength.intValue == 32)
        #expect(result.first?.first.address == addr.address)
    }

    @Test("Full IPv4 space summarizes to a single /0")
    func fullIPv4SpaceSummarization() {
        let start = IPAddress<V4>(address: 0)
        let end = IPAddress<V4>(address: UInt32.max)
        let result = IPNetwork<V4>.summarize(from: start, to: end)

        #expect(result.count == 1)
        #expect(result[0].prefixLength.intValue == 0)
        #expect(result[0].prefix == 0)
        #expect(result[0].storage == result[0].prefix)
    }

    @Test("Full IPv6 space summarizes to a single /0")
    func fullIPv6SpaceSummarization() {
        let start = IPAddress<V6>(address: 0)
        let end = IPAddress<V6>(address: UInt128.max)
        let result = IPNetwork<V6>.summarize(from: start, to: end)

        #expect(result.count == 1)
        #expect(result[0].prefixLength.intValue == 0)
        #expect(result[0].prefix == 0)
        #expect(result[0].storage == result[0].prefix)
    }

    @Test("IPv4 address and mask style stays vendor-friendly")
    func ipv4AddressAndMaskFormatting() throws {
        let host = try #require(IPv4Address("192.168.1.1"))
        let network = IPNetwork<V4>(host: host)

        #expect(network.formatted(.addressAndNetmask) == "192.168.1.1 255.255.255.255")
    }

    @Test("IPv6 preferred style uses the current full-text formatter")
    func ipv6PreferredFormatting() throws {
        let host = try #require(IPv6Address("2001:db8:0:0:0:0:0:1"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.preferred) == "2001:db8:0:0:0:0:0:1")
    }

    @Test("IPv6 preferred style preserves current all-zero and maximum full-text output")
    func ipv6PreferredFormattingEdgeCases() {
        let allZero = IPNetwork<V6>(host: IPAddress<V6>(address: 0))
        let maximum = IPNetwork<V6>(host: IPAddress<V6>(address: UInt128.max))

        #expect(allZero.formatted(.preferred) == "0:0:0:0:0:0:0:0")
        #expect(maximum.formatted(.preferred) == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")
    }

    @Test("IPv4-mapped IPv6 style uses mixed notation")
    func ipv4MappedIPv6Formatting() throws {
        let mappedAddress = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)
        let host = IPAddress<V6>(
            address: mappedAddress,
            prefixLength: try #require(PrefixLength<V6>(128))
        )
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.ipv4Mapped) == "::ffff:192.0.2.1")
    }

    @Test("Non-mapped IPv6 style falls back to normal address text")
    func nonMappedIPv6FormattingFallsBack() throws {
        let host = try #require(IPv6Address("2001:db8:0:0:0:0:0:1"))
        let network = IPNetwork<V6>(host: host)

        #expect(network.formatted(.ipv4Mapped) == "2001:db8:0:0:0:0:0:1")
    }
}
