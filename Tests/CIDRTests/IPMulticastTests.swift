import Foundation
import Testing
@testable import CIDR

@Suite("IP Multicast Tests")
struct IPMulticastTests {
    @Test("IPv4 multicast groups accept only host-length addresses in 224.0.0.0/4")
    func ipv4MulticastGroupValidation() throws {
        let localControl = try #require(IPv4MulticastGroup("224.0.0.1"))
        let sameLocalControl = try #require(IPv4MulticastGroup("224.0.0.1/32"))
        let administrativelyScoped = try #require(IPv4MulticastGroup("239.1.2.3"))

        #expect(localControl == sameLocalControl)
        #expect(localControl.description == "224.0.0.1")
        #expect(administrativelyScoped.description == "239.1.2.3")
        #expect(IPv4MulticastGroup("192.0.2.1") == nil)
        #expect(IPv4MulticastGroup("223.255.255.255") == nil)
        #expect(IPv4MulticastGroup("240.0.0.0") == nil)
        #expect(IPv4MulticastGroup("239.1.2.1/24") == nil)
        #expect(IPv4MulticastGroup("224.0.0.0/4") == nil)
    }

    @Test("IPv4 multicast ranges are canonical ranges fully inside 224.0.0.0/4")
    func ipv4MulticastRangeValidation() throws {
        let allMulticast = try #require(IPv4MulticastGroupRange("224.0.0.0/4"))
        let localNetworkControl = try #require(IPv4MulticastGroupRange("224.0.0.0/24"))
        let sourceSpecific = try #require(IPv4MulticastGroupRange("232.0.0.0/8"))
        let administrativelyScoped = try #require(IPv4MulticastGroupRange("239.0.0.0/8"))
        let group = try #require(IPv4MulticastGroup("239.1.2.3"))
        let outsideGroup = try #require(IPv4MulticastGroup("232.10.1.1"))

        #expect(allMulticast.contains(localNetworkControl))
        #expect(allMulticast.contains(sourceSpecific))
        #expect(allMulticast.contains(administrativelyScoped))
        #expect(allMulticast.overlaps(sourceSpecific))
        #expect(sourceSpecific.isWithin(allMulticast))
        #expect(administrativelyScoped.contains(group))
        #expect(!administrativelyScoped.contains(outsideGroup))
        #expect(localNetworkControl.firstGroup.description == "224.0.0.0")
        #expect(localNetworkControl.lastGroup.description == "224.0.0.255")
        #expect(localNetworkControl.rangeSizeIfRepresentable == 256)
        #expect(IPv4MulticastGroupRange("239.1.2.1/24") == nil)
        #expect(IPv4MulticastGroupRange("223.0.0.0/7") == nil)
        #expect(IPv4MulticastGroupRange("240.0.0.0/4") == nil)
    }

    @Test("IPv6 multicast groups accept only host-length addresses in ff00::/8")
    func ipv6MulticastGroupValidation() throws {
        let allNodes = try #require(IPv6MulticastGroup("ff02::1"))
        let sameAllNodes = try #require(IPv6MulticastGroup("ff02::1/128"))

        #expect(allNodes == sameAllNodes)
        #expect(allNodes.description == "ff02:0:0:0:0:0:0:1")
        #expect(IPv6MulticastGroup("fe80::1") == nil)
        #expect(IPv6MulticastGroup("2001:db8::1") == nil)
        #expect(IPv6MulticastGroup("ff02::1/64") == nil)
    }

    @Test("IPv6 multicast ranges are canonical ranges fully inside ff00::/8")
    func ipv6MulticastRangeValidation() throws {
        let allMulticast = try #require(IPv6MulticastGroupRange("ff00::/8"))
        let linkLocal = try #require(IPv6MulticastGroupRange("ff02::/16"))
        let group = try #require(IPv6MulticastGroup("ff02::1"))

        #expect(allMulticast.contains(linkLocal))
        #expect(linkLocal.isWithin(allMulticast))
        #expect(linkLocal.contains(group))
        #expect(linkLocal.firstGroup.description == "ff02:0:0:0:0:0:0:0")
        #expect(linkLocal.lastGroup.description == "ff02:ffff:ffff:ffff:ffff:ffff:ffff:ffff")
        #expect(linkLocal.rangeSizeIfRepresentable == UInt128(1) << 112)
        #expect(IPv6MulticastGroupRange("ff02::1/16") == nil)
        #expect(IPv6MulticastGroupRange("fe00::/7") == nil)
        #expect(IPv6MulticastGroupRange("2001:db8::/32") == nil)
    }

    @Test("Multicast types encode and decode their canonical text forms")
    func multicastCodableRoundTrip() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        let group = try #require(IPv4MulticastGroup("239.1.2.3/32"))
        let range = try #require(IPv4MulticastGroupRange("239.1.2.0/24"))

        #expect(group.description == "239.1.2.3")
        #expect(range.storage == range.prefix)
        #expect(range.description == "239.1.2.0/24")
        #expect(range.formatted(.cidrNotation) == "239.1.2.0/24")
        #expect(range.formatted(.addressOnly) == "239.1.2.0")

        let encodedGroup = try encoder.encode(group)
        let encodedRange = try encoder.encode(range)

        #expect(String(decoding: encodedGroup, as: UTF8.self) == #""239.1.2.3""#)
        #expect(try decoder.decode(String.self, from: encodedRange) == "239.1.2.0/24")
        #expect(try decoder.decode(IPv4MulticastGroup.self, from: encodedGroup) == group)
        #expect(try decoder.decode(IPv4MulticastGroupRange.self, from: encodedRange) == range)
    }
}
