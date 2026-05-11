# CIDR Foundations

CIDR is commonly written as an address plus a slash prefix length:

```text
192.0.2.1/24
2001:db8::1/64
```

The slash is not just formatting. It gives the address bits mathematical prefix
context: enough information to calculate containment, ranges, canonical network
boundaries, summarization, and related CIDR operations.

That is still not the full operational context. A CIDR prefix takes on
additional meaning when it is used somewhere: configured on an interface,
advertised by a routing protocol, installed in a routing table, matched by an
access-list filter, delegated by a registry, or interpreted as a multicast group
range. `swift-cidr` models the typed CIDR math underneath those uses; the
higher-level system decides what the prefix means operationally.

## Address Family

`AddressFamily` is the type-system boundary between IPv4 and IPv6. Each family
defines its storage width, parser, formatter, and POSIX address-family value.

This is intentionally different from POSIX-style code, where `AF_INET` and
`AF_INET6` are often runtime constants stored beside untyped buffers.
`swift-cidr` moves the family into the type:

```swift
import CIDR

if let v4 = IPv4Address("192.0.2.1/24"),
   let v6 = IPv6Address("2001:db8::1/64") {
    print(v4.description)
    print(v6.description)

    print(AF.V4.familyName)
    print(AF.V6.familyName)
}
```

That type boundary prevents accidentally mixing IPv4 and IPv6 values in generic
code unless the API explicitly accepts a mixed-family wrapper such as
`AnyIPAddress` or `AnyIPNetwork`.

## Prefix Length

`PrefixLength<Family>` validates the slash width for the address family.
`PrefixLength<AF.V4>` accepts `0...32`; `PrefixLength<AF.V6>` accepts `0...128`.

```swift
import CIDR

if let v4Prefix = IPv4PrefixLength(24),
   let v6Prefix = IPv6PrefixLength(64) {
    print(v4Prefix)
    print(v6Prefix)
}

print(IPv4PrefixLength.zero)     // /0
print(IPv4PrefixLength.maximum)  // /32
print(IPv6PrefixLength.maximum)  // /128
```

The family-bound prefix type makes invalid combinations unrepresentable in
normal API use.

## CIDR

`CIDR` is the base protocol for values that carry address-family-specific bits
and a prefix length.

The important point is that `CIDR` does not decide the operational meaning of
the slash. A `/24` may be a route prefix, a configured interface context, a
delegated block, or a multicast group-address range depending on the type using
it.

## IPAddress

`IPAddress<Family>` stores an address plus prefix context.

```swift
import CIDR

if let host = IPv4Address("192.0.2.1/24") {
    print(host.description)
    print(host.network.description)
}
```

Output:

```text
192.0.2.1/24
192.0.2.0/24
```

The address is still `192.0.2.1`; the `/24` says which prefix context it was
observed or configured within.

## IPNetwork

`IPNetwork<Family>` stores a canonical prefix boundary.

```swift
import CIDR

if let network = IPv4Network("192.0.2.123/24") {
    print(network.description)
}

```

Output:

```text
192.0.2.0/24
```

`IPNetwork` is the right type when the value represents a network prefix, route,
or subnet boundary.

## CIDRBlock

`CIDRBlock<Family>` is the neutral CIDR range type.

Use `CIDRBlock` when a value represents address-space delegation or allocation
without subnet, host, broadcast, gateway, or routing-table semantics. A Regional
Internet Registry delegation is a good mental model: the registry delegates a
prefix-shaped range of address space, but that delegation is not itself an
interface address, a LAN subnet, or a BGP route until some other system gives it
that context.

[RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632) uses `allocate` and
`assign` with registry-specific meaning. To allocate address space is to
delegate a block to an organization that may perform further sub-delegation. To
assign address space is to provide a block to a site for direct use, such as
numbering hosts or building site subnets.

```swift
import CIDR

if let allocation = CIDRBlock<V4>("198.51.100.0/24"),
   let assignedSubnet1 = IPv4Network("198.51.100.64/26", within: allocation),
   let assignedSubnet2 = IPv4Network("198.51.100.128/28", within: allocation) {
    print(allocation.contains(assignedSubnet1))
    print(allocation.contains(assignedSubnet2))
}
```

Output:

```text
true
true
```

The `within:` initializer verifies CIDR containment inside the allocation. It
does not track registry authority, assignment records, overlap policy, or
database state.

The examples use documentation prefixes, but the model is the same for real
authority-backed allocation data.

## Multicast Group Ranges

Multicast uses CIDR notation, but it does not use ordinary unicast subnet
semantics. `239.1.2.0/24` is a range containing multicast group destination
identifiers. It is not a LAN subnet with usable hosts or a broadcast address.

```swift
import CIDR

if let range = IPv4MulticastGroupRange("239.1.2.0/24"),
   let group = IPv4MulticastGroup("239.1.2.3") {
    print(range.contains(group))
}
```

Output:

```text
true
```

This is the reason `swift-cidr` keeps neutral range math, unicast network
semantics, and multicast group semantics in separate types.
