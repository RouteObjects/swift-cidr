import Testing
@testable import CIDR

@Suite("IP Address Stride Tests")
struct IPAddressStrideTests {
    @Test("IPv4 stride helpers preserve the current prefix context")
    func ipv4StrideHelpers() throws {
        let prefix = try #require(PrefixLength<V4>(24))
        let start = IPAddress<V4>(address: 0xC0000201, prefixLength: prefix)
        let end = IPAddress<V4>(address: 0xC000020A, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(9))
        #expect(start.distance(to: end) == Int128(9))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(9)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
        #expect(start.advanced(by: Int128(9)) == end)
    }

    @Test("IPv6 stride helpers work for low-space deltas")
    func ipv6LowSpaceStrideHelpers() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: UInt128(1), prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128(5), prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(4))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(4)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
    }

    @Test("IPv6 stride helpers work near UInt128.max for small deltas")
    func ipv6HighSpaceStrideHelpers() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: UInt128.max - 3, prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == Int128(3))

        let advanced = try #require(start.advancedIfRepresentable(by: Int128(3)))
        #expect(advanced == end)
        #expect(advanced.prefixLength == prefix)
    }

    @Test("Stride helpers return nil when the move exceeds Int128 or the family range")
    func boundedStrideFailures() throws {
        let prefix = try #require(PrefixLength<V6>(64))
        let start = IPAddress<V6>(address: 0, prefixLength: prefix)
        let end = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)

        #expect(start.distanceIfRepresentable(to: end) == nil)
        #expect(end.distanceIfRepresentable(to: start) == nil)
        #expect(start.advancedIfRepresentable(by: Int128(-1)) == nil)
        #expect(end.advancedIfRepresentable(by: Int128(1)) == nil)
    }

    @Test("IPv6 network iteration uses raw storage rather than generic stride")
    func ipv6NetworkSequenceNearTopOfSpace() throws {
        let prefix = try #require(PrefixLength<V6>(127))
        let host = IPAddress<V6>(address: UInt128.max, prefixLength: prefix)
        let network = IPNetwork<V6>(host: host)

        let addresses = Array(network)

        #expect(addresses.map(\.address) == [UInt128.max - 1, UInt128.max])
        #expect(addresses[0].prefixLength.intValue == 128)
        #expect(addresses[1].prefixLength.intValue == 128)
    }
}
