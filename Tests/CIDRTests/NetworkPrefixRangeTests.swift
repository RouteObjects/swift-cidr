import Testing
@testable import CIDR

@Suite("Network Prefix Range Tests")
struct NetworkPrefixRangeTests {
    @Test("^- excludes the base prefix and extends to the family max")
    func excludingSelfUsesNextPrefixThroughMax() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let range = try #require(network^-)

        #expect(range.network == network)
        #expect(range.lowerPrefixLength == PrefixLength<V4>(25))
        #expect(range.upperPrefixLength == PrefixLength<V4>(32))
        #expect(range.description == "192.0.2.0/24^-")
    }

    @Test("^+ includes the base prefix and extends to the family max")
    func includingSelfUsesBaseThroughMax() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let range = network^+

        #expect(range.network == network)
        #expect(range.lowerPrefixLength == PrefixLength<V4>(24))
        #expect(range.upperPrefixLength == PrefixLength<V4>(32))
        #expect(range.description == "192.0.2.0/24^+")
    }

    @Test("^n creates an exact prefix-length selector")
    func exactSelector() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let exact = network ^ 26
        let range = try #require(exact)

        #expect(range.lowerPrefixLength == PrefixLength<V4>(26))
        #expect(range.upperPrefixLength == PrefixLength<V4>(26))
        #expect(range.description == "192.0.2.0/24^26")
    }

    @Test("^n-m creates a bounded prefix-length selector")
    func boundedSelector() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let bounded = network ^ (26...28)
        let range = try #require(bounded)

        #expect(range.lowerPrefixLength == PrefixLength<V4>(26))
        #expect(range.upperPrefixLength == PrefixLength<V4>(28))
        #expect(range.description == "192.0.2.0/24^26-28")
    }

    @Test("invalid prefix-range requests return nil")
    func invalidSelectorsReturnNil() throws {
        let network = try #require(IPv4Network("192.0.2.0/24"))
        let maxIPv4 = try #require(IPv4Network("192.0.2.1/32"))
        let ipv6 = try #require(IPv6Network("2001:db8::/64"))
        let lower = try #require(PrefixLength<V4>(28))
        let upper = try #require(PrefixLength<V4>(26))

        #expect((network ^ 16) == nil)
        #expect((network ^ (20...22)) == nil)
        #expect(NetworkPrefixRange(network: network, lowerPrefixLength: lower, upperPrefixLength: upper) == nil)
        #expect((ipv6 ^ (96...129)) == nil)
        #expect((maxIPv4^-) == nil)
    }

    @Test("contains matches only networks inside the base and inside the allowed prefix bounds")
    func containsUsesNetworkAndPrefixBounds() throws {
        let base = try #require(IPv4Network("192.0.2.0/24"))
        let exactRange = base ^ 26
        let exact = try #require(exactRange)
        let boundedRange = base ^ (26...28)
        let bounded = try #require(boundedRange)

        let inside26 = try #require(IPv4Network("192.0.2.64/26"))
        let inside27 = try #require(IPv4Network("192.0.2.64/27"))
        let outsideNetwork = try #require(IPv4Network("192.0.3.0/26"))
        let wrongLength = try #require(IPv4Network("192.0.2.0/25"))

        #expect(exact.contains(inside26))
        #expect(!exact.contains(inside27))
        #expect(!exact.contains(outsideNetwork))
        #expect(!exact.contains(wrongLength))

        #expect(bounded.contains(inside26))
        #expect(bounded.contains(inside27))
        #expect(!bounded.contains(outsideNetwork))
        #expect(!bounded.contains(base))
    }

    @Test("IPv6 selectors respect family width")
    func ipv6SelectorsRespect128BitWidth() throws {
        let network = try #require(IPv6Network("2001:db8::/64"))
        let range = network^+
        let exactRange = network ^ 96
        let exact = try #require(exactRange)

        #expect(range.upperPrefixLength == PrefixLength<V6>(128))
        #expect(range.description == "2001:db8:0:0:0:0:0:0/64^+")
        #expect(exact.description == "2001:db8:0:0:0:0:0:0/64^96")
    }

    @Test("IPPrefix operators work for generic conformers beyond IPNetwork")
    func genericIPPrefixConformerUsesSameOperatorSurface() throws {
        struct Route<Family: AddressFamily>: IPPrefix {
            let prefix: Family.Storage
            let prefixLength: PrefixLength<Family>

            init(prefix: Family.Storage, prefixLength: PrefixLength<Family>) {
                self.prefix = prefix & Family.Storage.networkMask(for: prefixLength.intValue)
                self.prefixLength = prefixLength
            }
        }

        let route = Route<V4>(
            address: IPAddress(address: UInt32(0xC0000200), prefixLength: try #require(PrefixLength<V4>(24))),
            prefixLength: try #require(PrefixLength<V4>(24))
        )
        let range = route^+
        let canonical = IPv4Network(
            address: IPAddress(address: UInt32(0xC0000200)),
            prefixLength: try #require(PrefixLength<V4>(24))
        )

        #expect(range.network == canonical)
        #expect(range.description == "192.0.2.0/24^+")
    }
}
