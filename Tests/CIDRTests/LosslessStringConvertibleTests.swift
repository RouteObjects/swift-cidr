import Testing
@testable import CIDR

@Suite("Lossless String Convertible Tests")
struct LosslessStringConvertibleTests {
    @Test("PrefixLength parses and round-trips canonical decimal text")
    func prefixLengthRoundTrips() throws {
        let ipv4 = try #require(PrefixLength<V4>("24"))
        let ipv6 = try #require(PrefixLength<V6>("64"))

        #expect(ipv4.intValue == 24)
        #expect(ipv4.description == "24")
        #expect(PrefixLength<V4>(ipv4.description) == ipv4)

        #expect(ipv6.intValue == 64)
        #expect(ipv6.description == "64")
        #expect(PrefixLength<V6>(ipv6.description) == ipv6)
    }

    @Test("PrefixLength rejects invalid widths for each family")
    func prefixLengthRejectsInvalidWidths() {
        #expect(PrefixLength<V4>("-1") == nil)
        #expect(PrefixLength<V4>("33") == nil)
        #expect(PrefixLength<V6>("129") == nil)
        #expect(PrefixLength<V6>("abc") == nil)
    }

    @Test("IPAddress and IPNetwork round-trip canonical CIDR text")
    func familyBoundCIDRTypesRoundTrip() throws {
        let ipv4Address = try #require(IPAddress<V4>("192.0.2.1/24"))
        let ipv6Address = try #require(IPAddress<V6>("2001:db8::1/64"))
        let ipv4Network = try #require(IPNetwork<V4>("192.0.2.0/24"))
        let ipv4DefaultNetwork = try #require(IPNetwork<V4>("0.0.0.0/0"))
        let ipv6Network = try #require(IPNetwork<V6>("2001:db8::/64"))
        let ipv6MaxLengthNetwork = try #require(IPNetwork<V6>("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"))

        #expect(IPAddress<V4>(ipv4Address.description) == ipv4Address)
        #expect(IPAddress<V6>(ipv6Address.description) == ipv6Address)
        #expect(IPNetwork<V4>(ipv4Network.description) == ipv4Network)
        #expect(IPNetwork<V4>(ipv4DefaultNetwork.description) == ipv4DefaultNetwork)
        #expect(IPNetwork<V6>(ipv6Network.description) == ipv6Network)
        #expect(IPNetwork<V6>(ipv6MaxLengthNetwork.description) == ipv6MaxLengthNetwork)
    }

    @Test("IPNetwork rejects malformed CIDR notation")
    func ipNetworkRejectsMalformedCIDRNotation() {
        #expect(IPv4Network("192.0.2.0") == nil)
        #expect(IPv4Network("192.0.2.0/") == nil)
        #expect(IPv4Network("/24") == nil)
        #expect(IPv4Network("192.0.2.0/+24") == nil)
        #expect(IPv4Network("192.0.2.0/-1") == nil)
        #expect(IPv4Network("192.0.2.0/032") == nil)
        #expect(IPv4Network("192.0.2.0/24/extra") == nil)
        #expect(IPv4Network("192.0.2.0/24/1") == nil)
        #expect(IPv6Network("2001:db8::/129") == nil)
        #expect(IPv6Network("2001:db8::/+64") == nil)
        #expect(IPv6Network("2001:db8::/-1") == nil)
        #expect(IPv6Network("2001:db8::/064") == nil)
        #expect(IPv6Network("2001:db8::/64/extra") == nil)
        #expect(IPv6Network("2001:db8::/64/1") == nil)
    }

    @Test("AnyPrefixLength stays a projection rather than a lossless string form")
    func anyPrefixLengthRemainsProjectionShaped() throws {
        let any = AnyPrefixLength(try #require(IPv4PrefixLength(24)))

        #expect(any.description == "24")
        #expect((AnyPrefixLength.self is any LosslessStringConvertible.Type) == false)
    }
}
