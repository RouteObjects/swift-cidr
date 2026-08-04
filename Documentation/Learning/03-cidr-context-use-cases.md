# CIDR Context Use Cases

CIDR notation is shared by many networking systems. The slash tells you how to
interpret the bits, but the surrounding system tells you what the value means.

`swift-cidr` models that distinction with separate types.

## Context inventory (overview)

Prefix and address values show up far wider than host or interface configuration.
A single CIDR-style wrapper around an address usually falls short across that
range. The inventory below matches the framing used on the Swift Forums
requirements thread
([Requirements for IP address and port APIs](https://forums.swift.org/t/requirements-for-ip-address-and-port-apis/88514/10))
so package docs and that discussion stay aligned.

**Host / link**

- Interface address assignment
- Link-local + zone/scope
- On-link subnet / point-to-point / host route
- Loopback and router-id style addresses

**Routing / control plane**

- Connected, static, IGP, and BGP destinations
- Aggregates, defaults, more-specifics
- RIB/FIB keys and next-hop addresses
- FlowSpec-style prefix match components

**Policy / filtering**

- Prefix-lists (exact / length-bounded / more-specific)
- Route policy match/set
- ACL / security-group CIDR operands
- Source validation (e.g. expected source prefixes)

**Registries / authorization**

- RIR allocations and assignments
- IRR `route` / `route6` objects
- RPKI ROAs (and related resource bindings)
- Working example: [`asroutes`](https://github.com/RouteObjects/asroutes) — IRR
  lookup by origin AS, results as **canonical networks**

**Planning / isolation / ops**

- IPAM pools and delegations
- VRF / tenant / VPC route entries
- VPN NLRI (prefix plus routing-instance context)
- Telemetry, collectors, and logging keys

Not every row above is a separate public type in `swift-cidr`. The package
supplies **currency** (addresses with context, canonical networks, neutral
blocks, selectors, multicast forms, ASN, mixed-family wrappers) so those
operational systems can share one precise foundation. Higher layers own
RIB/FIB state, policy engines, registry metadata, and transport choice.

The sections that follow walk through a few of these contexts in more detail
with concrete `swift-cidr` types.

## Interface Configuration

An interface configuration stores a host address and the prefix context of the
attached subnet.

```swift
import CIDR

if let configured = IPv4Address("192.0.2.10/24") {
    print(configured.description)
    print(configured.network.description)
}
```

Output:

```text
192.0.2.10/24
192.0.2.0/24
```

A hypothetical Cisco IOS-style configuration might look like this:

```text
interface GigabitEthernet0/0
 ip address 192.0.2.10 255.255.255.0
```

The configured value is not the subnet boundary. The host is `192.0.2.10`; the
prefix context says that the attached subnet is `192.0.2.0/24`.

## Routing and BGP

A routing table entry stores a prefix boundary. In `swift-cidr`, that is an
`IPNetwork`.

```swift
import CIDR

if let advertisedRoute = IPv4Network("203.0.113.0/24"),
   let coveringAggregate = IPv4Network("203.0.112.0/23") {
    print(coveringAggregate.contains(advertisedRoute))
}
```

Output:

```text
true
```

A hypothetical BGP-style route statement might refer to the same prefix:

```text
network 203.0.113.0 mask 255.255.255.0
```

The route is not an interface assignment. It is a prefix that can be announced,
filtered, summarized, or matched by policy.

## Regional Internet Registry Delegation

A Regional Internet Registry delegates address space as prefix-shaped CIDR
blocks. That delegation is authority and allocation context; it is not
automatically a route, an interface, or a LAN subnet.

`CIDRBlock` is the neutral type for this shape.

```swift
import CIDR

if let rirDelegation = CIDRBlock<AF.V4>("198.51.100.0/24"),
   let downstreamAssignment = CIDRBlock<AF.V4>("198.51.100.128/25") {
    print(rirDelegation.contains(downstreamAssignment))
    print(downstreamAssignment.isWithin(rirDelegation))
}
```

Output:

```text
true
true
```

This is the right abstraction when you need first address, last address,
containment, overlap, and range size without importing unicast subnet language.
Registry metadata such as status, RIR, organization, date, and policy belongs in
a registry/IPAM layer, not in the core CIDR math type.

## Multicast Group Ranges

Multicast group ranges also use CIDR notation, but they are not subnets.

```swift
import CIDR

if let administrativelyScoped = IPv4MulticastGroupRange("239.0.0.0/8"),
   let group = IPv4MulticastGroup("239.1.2.3") {
    print(administrativelyScoped.contains(group))
}
```

Output:

```text
true
```

`239.1.2.0/24` contains 256 multicast group destination identifiers. It does
not have 254 usable hosts, a default gateway, or a broadcast address.

## Practical Rule

Choose the type that matches the context:

| Context | Type |
| --- | --- |
| Host or interface address with prefix context | `IPAddress<Family>` |
| Route prefix or subnet boundary | `IPNetwork<Family>` |
| RIR-style delegated/address-space block | `CIDRBlock<Family>` |
| Multicast group destination | `IPMulticastGroup<Family>` |
| Multicast group-address range | `IPMulticastGroupRange<Family>` |

This keeps the same CIDR math reusable without mixing unrelated operational
semantics.

For a full type ↔ standards map, form comparison (`IPAddress` vs `IPNetwork` vs
`CIDRBlock` vs `NetworkPrefixRange`), and the math-core vs host/context layering
story, see [DESIGN.md](../DESIGN.md).
