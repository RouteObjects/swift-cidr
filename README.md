<h1 align="left">
  <img src="Documentation/Assets/swift-cidr-icon.png" alt="swift-cidr icon" width="75" height="75" valign="middle">
  &nbsp;CIDR
</h1>

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRouteObjects%2Fswift-cidr%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/RouteObjects/swift-cidr)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRouteObjects%2Fswift-cidr%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/RouteObjects/swift-cidr)

`CIDR` provides value-semantic Swift types for classless Internet Protocol
addressing and related routing identifiers: addresses, prefix lengths, networks,
endpoints, and Autonomous System numbers that need stable modeling across routing,
addressing, policy, validation, configuration, server, and POSIX boundaries.

Although an Autonomous System number is not a CIDR prefix, it is a foundational
Internet routing identifier. Inter-domain routing operates between autonomous
systems, and AS numbers are used alongside IP prefixes throughout BGP, RPSL, IRR
queries, route-origin validation, and routing policy. `swift-cidr` therefore owns
the protocol-neutral numeric `AutonomousSystemNumber` value, while higher-level
packages own contextual syntax and behavior. For example, `swift-rpsl` owns
`AS`-prefixed forms, AS expressions, sets, references, and policy semantics.

The core models are currency types: public value types intended to be
stored, passed, and composed throughout network infrastructure software.

**Swift for Network Infrastructure.** `swift-cidr` is a foundation for Swift
applications that model, validate, configure, and operate on IP networks. Built
from the network model outward, it provides type-safe foundations for IP
infrastructure software: routing, addressing, policy, validation,
configuration, and control-plane data.

`swift-cidr` brings native CIDR currency types to Swift on Server, apps,
services, tooling, and network control-plane systems. It is not "Swift
networking" in the URLSession or socket-adapter sense, and it is not just
another IP address parser: it is a typed, pure Swift foundation for carrying
addresses, prefixes, networks, and endpoint values through network
infrastructure software without falling back to loosely typed strings or
POSIX-shaped state.

That scope includes routing protocols, RPKI validation, access-list builders,
IPAM systems, NETCONF/SSH configuration tooling, ping and diagnostic utilities,
and other systems that process high-volume IP data or control-plane state.

## Why CIDR

- Family-safe APIs expose familiar IPv4 and IPv6 names like `IPv4Address`,
  `IPv6Address`, `IPv4Network`, and `IPv6Network`, while keeping
  address-family boundaries explicit in the type system.
- `AddressFamily` models selected IANA address-family values as compile-time
  traits instead of runtime tags, carrying storage width, parser, formatter, and
  IANA family metadata in the type system.
- `AutonomousSystemNumber`, also available as `ASN`, is the canonical numeric
  AS-number value, while `AF.ASN` remains its IANA address-family marker.
- `IPNetwork` is first-class, so CIDR prefixes can participate directly in
  containment checks, subnet traversal, summarization, and mixed-family API
  boundaries.
- RPSL-style prefix-range operators model route-policy prefix selection with
  `^+`, `^-`, `^n`, and `^n-m` forms.
- Multicast group addresses and group-address ranges are modeled explicitly, so
  multicast CIDR notation does not inherit unicast subnet, host, or broadcast
  semantics.
- The core `CIDR` module stays pure Swift and dependency-free. POSIX and
  SwiftNIO support live at adapter boundaries instead of shaping the core type
  system.
- The API is designed for network infrastructure software: routing, addressing,
  policy, validation, configuration, and control-plane data pipelines that need
  small value types, explicit family metadata, predictable formatting/parsing,
  and optional `CIDRNIO` interoperability for SwiftNIO users.
- Performance work is measured with benchmark coverage against Swift public APIs
  and system baselines, including IPv4/IPv6 `inet_pton` parser baselines and
  IPv4/IPv6 `inet_ntop` formatter baselines.

The package is organized around a family-bound core:

- `AddressFamily` is the compile-time trait that binds storage width, parsing,
   formatting, and IANA family metadata to selected registry families.
   `IPAddressFamily` narrows that surface to IP address families, with `AF.V4`
   and `AF.V6` as the concrete IPv4 and IPv6 marker types.
- `IPAddress<Family>` stores an IP address together with its prefix context.
- `IPNetwork<Family>` stores a canonical network boundary.
- `PrefixLength<Family>` validates CIDR prefix lengths per family.
- `IPMulticastGroup<Family>` and `IPMulticastGroupRange<Family>` model multicast
   destination identifiers and group-address ranges, with aliases such as
   `IPv4MulticastGroup` and `IPv6MulticastGroup`.
- `AnyIPAddress`, `AnyIPNetwork`, and `AnyPrefixLength` provide mixed-family
   wrappers for boundary APIs.
- `AutonomousSystemNumber` stores a four-octet AS number and parses its canonical
  bare `asplain` decimal representation.
- `Port` stores numeric transport-layer port values, and `IPEndpoint` combines
   an IP address with a port.

## Standards Grounding

`swift-cidr` is built around established Internet standards and registry
terminology rather than package-specific interpretations:

- The [IANA Address Family Numbers registry](https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml)
  grounds `AddressFamily.ianaValue` and the selected registry families modeled by
  `AF`, including IPv4, IPv6, AS Number, 48-bit MAC, and 64-bit MAC.
- [RFC 791](https://datatracker.ietf.org/doc/html/rfc791) grounds IPv4 as a
  32-bit Internet address family.
- [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291) grounds IPv6 as a
  128-bit address family and defines conventional IPv6 text forms.
- [RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632) defines Classless
  Inter-Domain Routing notation, aggregation context, and the registry
  distinction between allocation and assignment.
- [RFC 7020](https://datatracker.ietf.org/doc/html/rfc7020) describes the
  Internet Numbers Registry System for globally unique IP address space and AS
  numbers; that registry and delegation context is why `CIDRBlock` exists as a
  neutral address-space block separate from host addresses and configured
  network prefixes.
- [RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952) guides compressed
  IPv6 text formatting.
- [RFC 2622](https://datatracker.ietf.org/doc/html/rfc2622#section-2) defines
  the RPSL address-prefix-range operators modeled by `NetworkPrefixRange`.
- [RFC 6308](https://datatracker.ietf.org/doc/html/rfc6308) informs the
  multicast address allocation and assignment model used by multicast types.
- [RFC 1930](https://datatracker.ietf.org/doc/html/rfc1930) defines the
  Autonomous System concept modeled by `AutonomousSystemNumber` and identified
  by the `AF.ASN` family marker.
- [RFC 5396](https://datatracker.ietf.org/doc/html/rfc5396) defines bare decimal
  `asplain` as the canonical textual representation of an AS number.
- [RFC 6793](https://datatracker.ietf.org/doc/html/rfc6793) defines four-octet
  AS numbers, matching `AutonomousSystemNumber`'s `AF.ASN.Storage` backing.

## Learning Guides

The package includes short learning guides for developers who know Swift but may
not have deep network-architecture background:

- [CIDR Foundations](Documentation/Learning/01-cidr-foundations.md)
- [Subnets, Supernets, and Aggregation](Documentation/Learning/02-subnet-supernet-aggregation.md)
- [CIDR Context Use Cases](Documentation/Learning/03-cidr-context-use-cases.md)

These guides explain why `swift-cidr` separates host addresses, network
prefixes, Regional Internet Registry-style delegated CIDR blocks, and multicast
group ranges into distinct types while leaving operational context to higher
layers.

## Modules

- `CIDR`: Core address, network, prefix, mixed-family, and endpoint types.
- `CIDRPOSIX`: POSIX interoperability helpers for address families and
  `sockaddr` conversion.
- `CIDRNIO`: SwiftNIO adapters for `ByteBuffer` and `SocketAddress`. Importing
  `CIDRNIO` is explicit, and the core `CIDR` target does not import `NIOCore`.

IANA registry datasets are intentionally outside the core `CIDR` package,
keeping this package focused on value types, parsing, formatting, and CIDR math.

## Toolchains and Platforms

- Swift 6.3
- Swift 6.3 Command Line Tools for command-line and editor-based workflows
- Minimum Apple deployment targets:
  - macOS 15
  - iOS 18

The Apple platform minimums come from this toolchain's built-in `UInt128`
availability. Linux validation is handled in CI.

On macOS with standalone Command Line Tools, use the repository test wrapper:

```bash
./scripts/test.sh
```

The wrapper still runs SwiftPM tests. It only adds the Swift Testing framework
and runtime paths needed by standalone Command Line Tools installations where
plain `swift test` cannot locate `Testing.framework`.

For local Linux validation with Docker Desktop, use the Linux wrapper:

```bash
./scripts/linux-test.sh
```

The wrapper uses the official `swift:6.3` image and defaults to `linux/amd64` to
match GitHub Actions. On Apple Silicon, a faster architecture-native smoke test
is available with:

```bash
CIDR_LINUX_PLATFORM=linux/arm64 ./scripts/linux-test.sh
```

Use the interactive Linux shell when diagnosing platform-specific failures:

```bash
./scripts/linux-test.sh shell
```

## Examples

### Parse and Format

```swift
import CIDR

if let host = IPv4Address("192.0.2.1/24") {
    let endpoint = IPEndpoint(address: host, port: Port(53))

    print(host.description)
    // 192.0.2.1/24

    print(host.network.description)
    // 192.0.2.0/24

    print(endpoint.description)
    // 192.0.2.1/24:53
}
```

### Subnet Math

```swift
import CIDR

if let network = IPv4Network("192.0.2.0/24"),
   let start = IPv4Address("192.0.2.0"),
   let end = IPv4Address("192.0.2.255") {
    let subnets = Array(network.subnets(prefixLength: 26)).map(\.description)
    let summary = IPv4Network.summarize(from: start, to: end).map(\.description)

    print(subnets)
    // ["192.0.2.0/26", "192.0.2.64/26", "192.0.2.128/26", "192.0.2.192/26"]

    print(summary)
    // ["192.0.2.0/24"]
}
```

### Mixed-Family Boundary APIs

```swift
import CIDR

if let v4 = AnyIPAddress("192.0.2.1/24"),
   let v6 = AnyIPAddress("2001:db8::1/64") {
    let addresses = [v4, v6]

    for address in addresses {
        print(address.familyName, address.network.description)
    }
}
```

### Autonomous System Numbers

```swift
import CIDR

if let asn = AutonomousSystemNumber("64496") {
    print(asn.rawValue)
    // 64496

    print(asn.description)
    // 64496
}
```

The numeric value intentionally does not accept the RPSL form `AS64496` or
legacy `asdot` text. Those lexical and policy concerns belong in higher-level
packages.

## Development

Common local commands:

```bash
swift build --target CIDR
swift build --target CIDRPOSIX
swift build --target CIDRNIO
./scripts/test.sh
./scripts/linux-test.sh
./scripts/benchmarks.sh build
./scripts/benchmarks.sh check
```

## Benchmarking

### TL;DR

Build, test, and run the primary public/API-facing benchmarks from the repository
root:

```bash
./scripts/test.sh
./scripts/benchmarks.sh run --no-progress --scale --time-units nanoseconds
./scripts/benchmarks.sh check
```

`./scripts/benchmarks.sh run` defaults to `CIDRBenchmarkTarget`, which exercises
the normal public APIs such as `IPv4Address`, `IPv6Address`, `IPNetwork`, and
formatting paths. Deeper benchmark targets for parser experiments, fixed-loop CPU
research, and SwiftNIO adapters are documented below.

### Benchmark Details

Benchmark tooling lives in the separate `Benchmarks/` package rather than the
root library package, so contributors may not see it when opening only the root
`Package.swift` in Xcode.

From the repository root:

```bash
./scripts/benchmarks.sh build
./scripts/benchmarks.sh run
./scripts/benchmarks.sh check
./scripts/benchmarks.sh update
./scripts/benchmarks.sh graph
```

The wrapper defaults to `CIDRBenchmarkTarget`, the public/API-facing benchmark
target.

For fixed-loop research benchmarks that report only user CPU time, select
`CIDRCPUBenchmarkTarget`:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run
```

For opt-in SwiftNIO adapter benchmarks, select `CIDRNIOBenchmarkTarget`:

```bash
CIDR_BENCHMARK_TARGET=CIDRNIOBenchmarkTarget ./scripts/benchmarks.sh run
```

Open `Benchmarks/Package.swift` separately in Xcode if you want the benchmark
package to appear in Xcode's package navigator.

Benchmark details live in [Benchmarks/README.md](Benchmarks/README.md), and the
root wrapper script lives at [scripts/benchmarks.sh](scripts/benchmarks.sh).
Benchmark tooling is intentionally isolated in the nested `Benchmarks` package
so normal library builds, tests, and non-macOS Apple destinations do not pull
in Benchmark.
Linux remains part of normal build/test CI, and the opt-in Linux benchmark job
checks benchmark target compilation. Benchmark-threshold validation remains a
local/macOS workflow unless it is explicitly run on Linux.

## License

`CIDR` is licensed under Apache-2.0. See [LICENSE](LICENSE).
