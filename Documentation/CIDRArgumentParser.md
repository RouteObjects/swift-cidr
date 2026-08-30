# CIDRArgumentParser

`CIDRArgumentParser` is the opt-in command-line adapter between `swift-cidr`
currency types and
[Swift Argument Parser](https://github.com/apple/swift-argument-parser). It is
introduced in `swift-cidr` 0.7.0 and requires Swift Argument
Parser `>=1.7.0,<2.0.0`.

The adapter keeps command-line concerns out of the core `CIDR` module. It adds
same-package `ExpressibleByArgument` conformances without changing the parsing,
normalization, or policy boundaries of the underlying values.

## Add the Products

Declare both packages and make all three imported products direct dependencies
of the CLI target:

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/RouteObjects/swift-cidr.git",
        .upToNextMinor(from: "0.7.0")
    ),
    .package(
        url: "https://github.com/apple/swift-argument-parser.git",
        "1.7.0"..<"2.0.0"
    ),
],
targets: [
    .executableTarget(
        name: "NetworkCLI",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "CIDR", package: "swift-cidr"),
            .product(name: "CIDRArgumentParser", package: "swift-cidr"),
        ]
    ),
]
```

Import the modules explicitly wherever the conformances are used:

```swift
import ArgumentParser
import CIDR
import CIDRArgumentParser
```

`CIDRArgumentParser` intentionally does not use underscored re-exports. A source
file that imports only `CIDR` does not opt into the Argument Parser adapter.

## Typed Options

```swift
import ArgumentParser
import CIDR
import CIDRArgumentParser

struct PeerOptions: ParsableArguments {
    @Option(help: "Literal peer address.")
    var peer: IPv4Address

    @Option(help: "Numeric peer port.")
    var port: Port = Port(179)

    @Option(name: .customLong("local-as"), help: "Local asplain ASN.")
    var localAS: AutonomousSystemNumber = AutonomousSystemNumber(65001)

    @Option(name: .customLong("peer-as"), help: "Peer asplain ASN.")
    var peerAS: AutonomousSystemNumber

    @Option(name: .customLong("local-address"), help: "Optional literal bind address.")
    var localAddress: IPv4Address?

    @Option(name: .customLong("allowed-prefix"), help: "Optional allowed IPv4 network.")
    var allowedPrefix: IPv4Network?

    @Option(name: .customLong("listen-endpoint"), help: "Optional bracketed IPv6 endpoint.")
    var listenEndpoint: IPEndpoint<V6>?

    @Option(name: .customLong("maximum-prefix-length"), help: "Optional IPv4 prefix limit.")
    var maximumPrefixLength: IPv4PrefixLength?

    @Option(name: .customLong("next-hop"), help: "Optional IPv4 or IPv6 next hop.")
    var nextHop: AnyIPAddress?

    @Option(name: .customLong("route"), help: "Optional IPv4 or IPv6 route prefix.")
    var route: AnyIPNetwork?
}
```

Omitting any optional option leaves its property as `nil`. Passing an explicit
empty value is invalid and follows Argument Parser's normal invalid-value path;
omit the option to express no value.

Mixed-family currency types also work as positional arguments when a command's
boundary accepts either address family:

```swift
import ArgumentParser
import CIDR
import CIDRArgumentParser

struct RouteLookup: ParsableArguments {
    @Argument(help: "Literal IPv4 or IPv6 address.")
    var address: AnyIPAddress

    @Argument(help: "IPv4 or IPv6 network in CIDR notation.")
    var network: AnyIPNetwork
}
```

## Accepted Forms

| Type | Accepted examples | Canonical description | Rejected examples |
|------|-------------------|-----------------------|-------------------|
| `Port` | `0`, `00179`, `+179`, `-0`, `65535` | `00179` and `+179` become `179`; `-0` becomes `0` | empty, `-1`, `65536`, `http`, other nonnumeric text |
| `AutonomousSystemNumber` | `0`, `65001`, `4294967295` | Bare asplain decimal, such as `65001` | whitespace, signs, overflow, `AS65001`, `1.10`, empty |
| `IPv4Address` | `192.0.2.1`, `192.0.2.1/24` | `192.0.2.1/32`, `192.0.2.1/24` | IPv6, DNS names, invalid prefixes, garbage, empty |
| `IPv6Address` | `2001:db8::1`, `2001:db8::1/64` | `2001:db8::1/128`, `2001:db8::1/64` | IPv4, DNS names, invalid prefixes, garbage, empty |
| `AnyIPAddress` | `192.0.2.1`, `2001:db8::1/64` | `192.0.2.1/32`, `2001:db8::1/64` | DNS names, invalid prefixes, garbage, empty |
| `IPEndpoint<V4>` | `192.0.2.1:00179`, `192.0.2.1/24:179` | `192.0.2.1/32:179`, `192.0.2.1/24:179` | missing or invalid ports, IPv6, DNS names, garbage, empty |
| `IPEndpoint<V6>` | `[2001:db8::1]:00179`, `[2001:db8::1/64]:179` | `[2001:db8::1/128]:179`, `[2001:db8::1/64]:179` | unbracketed IPv6, missing or invalid ports, IPv4, DNS names, garbage, empty |
| `IPv4Network` | `192.0.2.0/24`, `192.0.2.129/24` | `192.0.2.0/24` | bare addresses, IPv6, invalid prefixes, DNS names, garbage, empty |
| `IPv6Network` | `2001:db8::/64`, `2001:db8::1/64` | `2001:db8::/64` | bare addresses, IPv4, invalid prefixes, DNS names, garbage, empty |
| `AnyIPNetwork` | `192.0.2.129/24`, `2001:db8::1/64` | `192.0.2.0/24`, `2001:db8::/64` | bare addresses, invalid prefixes, DNS names, garbage, empty |
| `IPv4PrefixLength` | `0`, `024`, `32` | Unpadded decimal, such as `24` | values outside `0...32`, whitespace, `/24`, nonnumeric text, empty |
| `IPv6PrefixLength` | `0`, `064`, `128` | Unpadded decimal, such as `64` | values outside `0...128`, whitespace, `/64`, nonnumeric text, empty |

`Port(0)` remains a valid shared currency value. A CLI such as a BGP client may
apply a stricter policy for a remote peer port after parsing without changing
the shared type.

`Port` defines its numeric text contract in the core `CIDR` module through
`LosslessStringConvertible`. The adapter uses Argument Parser's conditional
witness, so CLI parsing and `Port("179")` accept the same `UInt16`-backed text.
Canonicalizable forms such as `0179`, `+179`, and `-0` describe as `179`, `179`,
and `0`; service names and surrounding whitespace remain invalid.

The address conformance is generic on `IPAddress<Family>`, so it covers the
`IPv4Address` and `IPv6Address` aliases. Parsing delegates to the existing
family-bound literal parser: bare addresses receive the family's maximum prefix
length, while explicit valid prefixes and host bits are preserved. There is no
DNS resolution.

`AnyIPAddress` delegates to the same lossless IPv4 and IPv6 parsers and keeps
the selected family in its tagged boundary value. Bare literals receive `/32`
or `/128` context, and explicit valid prefixes and host bits are preserved.

The generic `IPEndpoint<Family>` conformance delegates to the existing endpoint
parser. A numeric port is required, including when the address is otherwise a
valid literal. IPv4 uses `address:port`; IPv6 uses `[address]:port` so its colons
remain unambiguous. Bare endpoint addresses receive maximum-length prefix
context, explicit address prefixes are preserved, and port zero remains valid.
The endpoint parser reuses `Port`, so canonicalizable spellings such as
`192.0.2.1:00179` describe as `192.0.2.1/32:179`.

The generic `IPNetwork<Family>` conformance covers `IPv4Network` and
`IPv6Network`. Unlike an address, a network requires CIDR notation. Input host
bits are accepted and cleared by the existing initializer, so
`192.0.2.129/24` becomes `192.0.2.0/24` rather than failing.

`AnyIPNetwork` applies those network rules across both address families. CIDR
notation remains mandatory, the family is selected from the literal, and host
bits are cleared to the canonical IPv4 or IPv6 network boundary.

The generic `PrefixLength<Family>` conformance covers `IPv4PrefixLength` and
`IPv6PrefixLength`. It delegates to the existing `Int`-based parser and then
validates `0...32` or `0...128`. Consequently, canonicalizable integer forms
such as `024`, `+24`, and `-0` remain accepted; `description` normalizes them to
`24`, `24`, and `0`. The argument is the number without a slash. The adapter
does not impose a stricter lexical policy than the underlying type.

All lossless values round-trip through their canonical `description`. Port
default-value help therefore uses canonical numeric text, so accepted
zero-padded input does not leak padding into generated help. The conformances
do not expose a finite `allValueStrings` list because the accepted domains are
not useful as enumerated completion lists.

## Deliberately Limited Surface

The 0.7.0 adapter covers the essentials needed by typed infrastructure CLIs
plus the family-bound values that compose naturally with them:

- `Port`
- `AutonomousSystemNumber` (and its `ASN` alias)
- generic `IPAddress<Family>` (including `IPv4Address` and `IPv6Address`)
- `AnyIPAddress`
- generic `IPEndpoint<Family>`
- generic `IPNetwork<Family>` (including `IPv4Network` and `IPv6Network`)
- `AnyIPNetwork`
- generic `PrefixLength<Family>` (including `IPv4PrefixLength` and
  `IPv6PrefixLength`)

The first release does not add conformances for `AnyPrefixLength`,
`NetworkPrefixRange`, address ranges or coverage, `CIDRBlock`, or multicast
group/range types, including their mixed-family wrappers. It also does not add
DNS resolution, service-name ports, ASN `AS` prefixes/asdot parsing, or
empty-string to-optional coercion.

## Dependency Boundary

`CIDRArgumentParser` depends on `CIDR` and `ArgumentParser`. The `CIDR`,
`CIDRPOSIX`, and `CIDRNIO` targets have no target or link dependency on
Argument Parser.

SwiftPM resolves dependencies declared by a package manifest at package-graph
resolution time. Consequently, resolving `swift-cidr` 0.7.0 also resolves the
`swift-argument-parser` package even when a consumer selects only the `CIDR`
product. That package-graph resolution cost is distinct from importing or
linking Argument Parser into the core library target.

Downstream packages using a pre-1.0 `.upToNextMinor` requirement starting in
the 0.6.x line will not select 0.7.0. Adopt the adapter explicitly by moving the
constraint to `.upToNextMinor(from: "0.7.0")` and adding the products and
imports shown above.
