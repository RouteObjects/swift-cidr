# CIDR Context Use Cases

CIDR notation is shared by many networking systems. The slash tells you how to
interpret the bits, but the surrounding system tells you what the value means.

`swift-cidr` models that distinction with separate types.

## Interface Configuration

An interface configuration stores a host address and the prefix context of the
attached subnet.

```swift
import CIDR
import CIDRConfig

let configured = IPv4Address("192.0.2.10/24")!
let interface = InterfaceAddress(host: configured)

print(interface.host.description)
print(interface.network.description)
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

let advertisedRoute = IPv4Network("203.0.113.0/24")!
let coveringAggregate = IPv4Network("203.0.112.0/23")!

print(coveringAggregate.contains(advertisedRoute))
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

let rirDelegation = CIDRBlock<AF.V4>("198.51.100.0/24")!
let downstreamAssignment = CIDRBlock<AF.V4>("198.51.100.128/25")!

print(rirDelegation.contains(downstreamAssignment))
print(downstreamAssignment.isWithin(rirDelegation))
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

let administrativelyScoped = IPv4MulticastGroupRange("239.0.0.0/8")!
let group = IPv4MulticastGroup("239.1.2.3")!

print(administrativelyScoped.contains(group))
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
| Host address with prefix context | `IPAddress<Family>` |
| Interface assignment | `CIDRConfig.InterfaceAddress<Family>` |
| Route prefix or subnet boundary | `IPNetwork<Family>` |
| RIR-style delegated/address-space block | `CIDRBlock<Family>` |
| Multicast group destination | `IPMulticastGroup<Family>` |
| Multicast group-address range | `IPMulticastGroupRange<Family>` |

This keeps the same CIDR math reusable without mixing unrelated operational
semantics.
