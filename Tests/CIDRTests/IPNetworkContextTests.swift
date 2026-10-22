import Testing
@testable import CIDR

@Suite("Network prefix context")
struct IPNetworkContextTests {
    @Test("IPv4 iteration preserves its parent prefix")
    func ipv4Iteration() throws {
        let network = try #require(IPv4Network("192.0.2.0/30"))
        #expect(Array(network).map(\.description) == [
            "192.0.2.0/30", "192.0.2.1/30", "192.0.2.2/30", "192.0.2.3/30",
        ])
        checkMembership(network, address: 0xC0000201)
    }

    @Test("IPv6 iteration preserves its parent prefix")
    func ipv6Iteration() throws {
        let network = try #require(IPv6Network("::/126"))
        let values = Array(network)
        #expect(values.map(\.address) == [0, 1, 2, 3])
        #expect(values.map(\.prefixLength.intValue) == [126, 126, 126, 126])
        checkMembership(network, address: 1)
    }

    @Test("Shared CIDR endpoints preserve context through generic access")
    func endpoints() throws {
        let v4 = try #require(IPv4Address("192.0.2.1/30"))
        let v6 = try #require(IPv6Address("::1/126"))
        checkEndpoints(v4, lower: 0xC0000200, upper: 0xC0000203)
        checkEndpoints(v4.network, lower: 0xC0000200, upper: 0xC0000203)
        checkEndpoints(try #require(CIDRBlock<V4>("192.0.2.0/30")), lower: 0xC0000200, upper: 0xC0000203)
        checkEndpoints(v6, lower: 0, upper: 3)
        checkEndpoints(v6.network, lower: 0, upper: 3)
        checkEndpoints(try #require(CIDRBlock<V6>("::/126")), lower: 0, upper: 3)
        checkEndpoints(try #require(IPv4MulticastGroupRange("239.0.0.0/30")), lower: 0xEF000000, upper: 0xEF000003)
        checkEndpoints(try #require(IPv6MulticastGroupRange("ff02::/126")), lower: UInt128(0xFF02) << 112, upper: (UInt128(0xFF02) << 112) | 3)
    }

    private func checkMembership<F: IPAddressFamily>(_ network: IPNetwork<F>, address: F.Storage) {
        let contextual = IPAddress<F>(address: address, prefixLength: network.prefixLength)
        let individual = IPAddress<F>(address: address)
        func contains<S: Sequence>(_ sequence: S, _ value: S.Element) -> Bool where S.Element: Equatable {
            sequence.contains(value)
        }
        #expect(contains(network, contextual))
        #expect(!contains(network, individual))
        #expect(network._customContainsEquatableElement(contextual) == true)
        #expect(network._customContainsEquatableElement(individual) == false)
    }

    private func checkEndpoints<C: CIDR>(_ value: C, lower: C.Family.Storage, upper: C.Family.Storage) {
        #expect(value.first.address == lower)
        #expect(value.last.address == upper)
        #expect(value.first.prefixLength == value.prefixLength)
        #expect(value.last.prefixLength == value.prefixLength)
        #expect(value.range.lowerBound.prefixLength == value.prefixLength)
        #expect(value.range.upperBound.prefixLength == value.prefixLength)
    }
}
