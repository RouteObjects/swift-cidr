# Subnets, Supernets, and Aggregation

CIDR prefix length controls how many leading bits define a range.

For IPv4:

```text
192.0.2.0/24
```

The first 24 bits are the prefix. The remaining 8 bits vary, so the range spans
`192.0.2.0` through `192.0.2.255`.

## Subnet

A subnet is a more-specific prefix inside a larger prefix.

```swift
import CIDR

let parent = IPv4Network("192.0.2.0/24")!
let subnets = Array(parent.subnets(prefixLength: 26)).map(\.description)

print(subnets)
```

Output:

```text
["192.0.2.0/26", "192.0.2.64/26", "192.0.2.128/26", "192.0.2.192/26"]
```

The `/26` prefixes are more specific than the parent `/24`. Each one contains
64 addresses.

## Supernet and Aggregation

A supernet is a less-specific prefix that covers one or more more-specific
prefixes. In routing, aggregation is the act of representing multiple adjacent
routes with a shorter prefix when the ranges align.

```swift
import CIDR

let summary = IPv4Network.summarize(
    from: IPv4Address("192.0.2.0")!,
    to: IPv4Address("192.0.3.255")!
).map(\.description)

print(summary)
```

Output:

```text
["192.0.2.0/23"]
```

`192.0.2.0/24` and `192.0.3.0/24` can aggregate into `192.0.2.0/23` because
the combined range is contiguous and aligned on a `/23` boundary.

## Prefix Alignment

Network prefixes are canonical boundaries. Host bits below the prefix length
are zeroed when constructing an `IPNetwork`.

```swift
import CIDR

let network = IPv4Network("192.0.2.77/24")!

print(network.description)
```

Output:

```text
192.0.2.0/24
```

This is correct for `IPNetwork`, because the type represents the boundary.
If you need to preserve the configured host address and its subnet context, use
`IPAddress` or `CIDRConfig.InterfaceAddress`.

## Containment

Containment answers whether an address or prefix is inside another prefix.

```swift
import CIDR

let aggregate = IPv4Network("192.0.2.0/23")!
let route = IPv4Network("192.0.3.0/24")!
let host = IPv4Address("192.0.3.10")!

print(aggregate.contains(route))
print(aggregate.contains(host))
```

Output:

```text
true
true
```

Containment is pure CIDR math. Whether the prefix is installed in a router,
assigned to an interface, delegated by a registry, or used as documentation is
separate context.

## Why Context Matters

The same slash notation can be valid in several domains:

```text
192.0.2.1/24      host address with subnet context
192.0.2.0/24      network boundary or route prefix
198.51.100.0/24   neutral delegated block
239.1.2.0/24      multicast group-address range
```

`swift-cidr` uses separate types so the API can expose operations that make
sense for each context.
