import Testing
@testable import CIDR

@Suite("IP Network Traversal Tests")
struct IPNetworkTraversalTests {
    @Test("nextNetwork advances normally for IPv4")
    func nextNetworkIPv4() throws {
        let network = try #require(IPNetwork<V4>("192.168.1.0/24"))
        let next = try #require(network.nextNetwork)

        #expect(next.description == "192.168.2.0/24")
    }

    @Test("nextNetwork returns nil for the final IPv4 network")
    func finalIPv4NetworkHasNoNextNetwork() throws {
        let network = try #require(IPNetwork<V4>("255.255.255.0/24"))

        #expect(network.nextNetwork == nil)
    }

    @Test("nextNetwork returns nil for the final IPv6 network")
    func finalIPv6NetworkHasNoNextNetwork() throws {
        let finalAddress = UInt128.max & ~UInt128(0xFF)
        let prefix = try #require(PrefixLength<V6>(120))
        let network = IPNetwork<V6>(
            address: IPAddress<V6>(address: finalAddress),
            prefixLength: prefix
        )

        #expect(network.nextNetwork == nil)
    }

    @Test("IPv4 subnets ending at max are yielded exactly once")
    func ipv4SubnetsTerminateAtMaxAddress() throws {
        let network = try #require(IPNetwork<V4>("255.255.255.252/30"))
        let hostPrefix = try #require(PrefixLength<V4>(32))
        let subnets = Array(network.subnets(prefixLength: hostPrefix))

        #expect(subnets.map(\.description) == [
            "255.255.255.252/32",
            "255.255.255.253/32",
            "255.255.255.254/32",
            "255.255.255.255/32",
        ])
    }

    @Test("IPv6 top-of-space subnet iteration terminates cleanly")
    func ipv6SubnetsTerminateAtMaxAddress() throws {
        let networkPrefix = try #require(PrefixLength<V6>(127))
        let hostPrefix = try #require(PrefixLength<V6>(128))
        let network = IPNetwork<V6>(
            address: IPAddress<V6>(address: UInt128.max, prefixLength: networkPrefix),
            prefixLength: networkPrefix
        )
        let subnets = Array(network.subnets(prefixLength: hostPrefix))

        #expect(subnets.count == 2)
        #expect(subnets[0].prefix == UInt128.max - 1)
        #expect(subnets[1].prefix == UInt128.max)
    }

    @Test("IPPrefix canonicalizes host bits when initialized from an address")
    func ipPrefixAddressInitializerCanonicalizesHostBits() throws {
        let host = try #require(IPAddress<V4>("192.0.2.129/24"))
        let network = IPNetwork<V4>(address: host, prefixLength: try #require(PrefixLength<V4>(24)))

        #expect(network.prefix == 0xC0000200)
        #expect(network.description == "192.0.2.0/24")
    }
}
