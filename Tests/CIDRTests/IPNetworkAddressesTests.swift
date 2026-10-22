import Testing
import CIDR

@Suite("Contextual address views and containment")
struct IPNetworkAddressesTests {
    @Test("Address views agree with iteration and exact membership")
    func views() throws {
        try checkView(#require(IPv4Network("192.0.2.0/30")))
        try checkView(#require(IPv6Network("2001:db8::/126")))
    }

    @Test("Hierarchical containment distinguishes prefix context from exact membership")
    func hierarchy() throws {
        try checkHierarchy(#require(IPv4Network("192.0.2.0/30")))
        try checkHierarchy(#require(IPv6Network("2001:db8::/126")))
    }

    @Test("Family-erased containment rejects mixed families and preserves legacy behavior")
    func erasedContainment() throws {
        for (parent, inside, broader, child, outside) in [
            ("192.0.2.0/30", "192.0.2.1/32", "192.0.2.1/24", "192.0.2.2/31", "192.0.2.4/30"),
            ("2001:db8::/126", "2001:db8::1/128", "2001:db8::1/120", "2001:db8::2/127", "2001:db8::4/126"),
        ] {
            let network = try #require(AnyIPNetwork(parent))
            let address = try #require(AnyIPAddress(inside))
            let broad = try #require(AnyIPAddress(broader))
            let subnet = try #require(AnyIPNetwork(child))
            let other = try #require(AnyIPNetwork(outside))
            #expect(network.contains(address: address))
            #expect(!network.contains(address: broad))
            #expect(network.contains(subnet: subnet))
            #expect(!network.contains(subnet: other))
            // CHANGE: Legacy raw-address containment must not silently acquire the new semantics.
            #expect(network.contains(broad))
            #expect(network.contains(subnet))
        }
        let v4 = try #require(AnyIPNetwork("0.0.0.0/0"))
        let v6 = try #require(AnyIPNetwork("::/0"))
        #expect(!v4.contains(address: v6.first))
        #expect(!v6.contains(address: v4.first))
        #expect(!v4.contains(subnet: v6))
        #expect(!v6.contains(subnet: v4))
    }

    @Test("Independent iterators terminate at the highest address")
    func iteratorBoundaries() throws {
        try checkView(#require(IPv4Network("255.255.255.252/30")))
        try checkView(#require(IPv4Network("255.255.255.255/32")))
        try checkView(#require(IPv6Network("ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffc/126")))
        try checkView(#require(IPv6Network("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128")))
    }

    @Test("Default-route traversal is bounded and membership uses a constant-time witness")
    func fullSpace() throws {
        try checkFullSpace(#require(IPv4Network("0.0.0.0/0")))
        try checkFullSpace(#require(IPv6Network("::/0")))
    }

    @Test("Raw ranges and multicast destinations retain their explicit projections")
    func projections() throws {
        let v4 = try #require(IPv4Network("192.0.2.0/30"))
        let v6 = try #require(IPv6Network("2001:db8::/126"))
        let range4 = IPv4AddressRange(covering: v4)
        let range6 = IPv6AddressRange(covering: v6)
        #expect(range4.lowerBound.prefixLength.intValue == 32)
        #expect(range4.upperBound.prefixLength.intValue == 32)
        #expect(range6.lowerBound.prefixLength.intValue == 128)
        #expect(range6.upperBound.prefixLength.intValue == 128)
        #expect(range4.contains(try #require(IPv4Address("192.0.2.1/24"))))
        let groups4 = try #require(IPv4MulticastGroupRange("239.0.0.0/24"))
        let groups6 = try #require(IPv6MulticastGroupRange("ff02::/126"))
        #expect(groups4.firstGroup.address == groups4.first.address)
        #expect(groups4.lastGroup.address == groups4.last.address)
        #expect(groups6.firstGroup.address == groups6.first.address)
        #expect(groups6.lastGroup.address == groups6.last.address)
        #expect(groups4.firstGroup.prefixLength.intValue == 32)
        #expect(groups6.lastGroup.prefixLength.intValue == 128)
    }

    private func checkView<F: IPAddressFamily>(_ network: IPNetwork<F>) throws {
        let expected = Array(network)
        let view = network.addresses
        #expect(Array(view) == expected)
        #expect(expected.first == network.first)
        #expect(expected.last == network.last)
        var first = view.makeIterator()
        var second = view.makeIterator()
        #expect(first.next() == expected.first)
        #expect(second.next() == expected.first)
        for value in expected.dropFirst() { #expect(first.next() == value) }
        #expect(first.next() == nil)
        #expect(first.next() == nil)
        for value in expected.dropFirst() { #expect(second.next() == value) }
        #expect(second.next() == nil)
        var candidates = expected
        candidates.append(IPAddress(address: network.first.address))
        candidates.append(IPAddress(address: network.last.address, prefixLength: .zero))
        let (outside, overflow) = network.last.address.addingReportingOverflow(1)
        if !overflow { candidates.append(IPAddress(address: outside, prefixLength: network.prefixLength)) }
        for candidate in candidates {
            let answer = expected.contains(candidate)
            #expect(view.contains(candidate) == answer)
            #expect(genericContains(network, candidate) == answer)
            #expect(genericContains(view, candidate) == answer)
            #expect(AnySequence(network).contains(candidate) == answer)
            #expect(AnySequence(view).contains(candidate) == answer)
            #expect(network.lazy.contains(candidate) == answer)
            #expect(view.lazy.contains(candidate) == answer)
            #expect(view.lazy.filter { _ in true }.contains(candidate) == answer)
            #expect(view.lazy.map { $0 }.contains(candidate) == answer)
        }
    }

    private func checkHierarchy<F: IPAddressFamily>(_ network: IPNetwork<F>) throws {
        for length in [network.prefixBits - 1, network.prefixBits, network.prefixBits + 1, F.bitWidth] {
            let address = IPAddress<F>(address: network.prefix | 1, prefixLength: try #require(PrefixLength<F>(length)))
            #expect(network.contains(address: address) == (length >= network.prefixBits))
            #expect(network.contains(subnet: address.network) == (length >= network.prefixBits))
            #expect(network.addresses.contains(address) == (length == network.prefixBits))
            #expect(network.contains(address))
            func legacy<P: IPPrefix>(_ prefix: P, _ value: IPAddress<P.Family>) -> Bool {
                prefix.contains(value)
            }
            #expect(legacy(network, address))
        }
        let outside = IPAddress<F>(address: network.last.address + 1, prefixLength: network.prefixLength)
        #expect(!network.contains(address: outside))
        #expect(!network.contains(subnet: outside.network))
        #expect(!network.addresses.contains(outside))
        func generic<P: IPPrefix>(_ parent: P, _ address: IPAddress<P.Family>) -> Bool {
            parent.contains(address: address) && parent.contains(subnet: address.network)
        }
        #expect(generic(network, network.first))
    }

    private func checkFullSpace<F: IPAddressFamily>(_ network: IPNetwork<F>) throws {
        #expect(Array(network.prefix(3)).map(\.address) == [0, 1, 2])
        #expect(Array(network.addresses.prefix(3)).map(\.prefixLength.intValue) == [0, 0, 0])
        let last = IPAddress<F>(address: .max, prefixLength: .zero)
        let individual = IPAddress<F>(address: .max)
        // CHANGE: Require the fast-path witness before a generic call could otherwise scan /0.
        try checkFastMembership(network, last: last, individual: individual)
        try checkFastMembership(network.addresses, last: last, individual: individual)
        try checkFastMembership(AnySequence(network), last: last, individual: individual)
        try checkFastMembership(network.lazy, last: last, individual: individual)
    }

    private func checkFastMembership<S: Sequence>(_ sequence: S, last: S.Element, individual: S.Element) throws where S.Element: Equatable {
        #expect(try #require(sequence._customContainsEquatableElement(last)))
        #expect(!(try #require(sequence._customContainsEquatableElement(individual))))
        #expect(genericContains(sequence, last))
        #expect(!genericContains(sequence, individual))
    }

    private func genericContains<S: Sequence>(_ sequence: S, _ element: S.Element) -> Bool where S.Element: Equatable {
        sequence.contains(element)
    }
}
