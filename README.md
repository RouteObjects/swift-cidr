<p align="center">
  <img src="Documentation/Assets/swift-cidr-icon.png" alt="swift-cidr icon" width="160">
</p>

# CIDR

`CIDR` provides value-semantic IP types for Swift packages that need stable
address, network, and endpoint modeling across configuration, server, and POSIX
boundaries.
The core models are currency types: public value types intended to be
stored, passed, and composed throughout networking code.

`swift-cidr` gives Swift server code native CIDR currency types. It is not just
another IP address parser: it is a typed, pure Swift foundation for carrying
addresses, prefixes, networks, and endpoint values through networking systems
without falling back to loosely typed strings or POSIX-shaped state.

## Why CIDR

- Family-safe APIs make IPv4 and IPv6 boundaries explicit with
  `IPAddress<AF.V4>`, `IPAddress<AF.V6>`, `IPNetwork<AF.V4>`, and
  `IPNetwork<AF.V6>`.
- `IPNetwork` is first-class, so CIDR prefixes can participate directly in
  containment checks, subnet traversal, summarization, and mixed-family API
  boundaries.
- The core package stays pure Swift and dependency-light. POSIX and SwiftNIO
  support live at adapter boundaries instead of shaping the core type system.
- The API is designed for Swift on Server: small value types, explicit family
  metadata, predictable formatting/parsing, and optional `swift-cidr-nio`
  interoperability.
- Performance work is measured with benchmark coverage against Swift and system
  baselines such as `inet_pton` and `inet_ntop`.

The package is organized around a family-bound core:

- `IPAddress<Family>` stores an IP address together with its prefix context.
- `IPNetwork<Family>` stores a canonical network boundary.
- `PrefixLength<Family>` validates CIDR prefix lengths per family.
- `AnyIPAddress`, `AnyIPNetwork`, and `AnyPrefixLength` provide mixed-family
  wrappers for boundary APIs.
- `TransportPort` and `IPEndpoint` model transport endpoints.

## Learning Guides

The package includes short learning guides for developers who know Swift but may
not have deep network-architecture background:

- [CIDR Foundations](Documentation/Learning/01-cidr-foundations.md)
- [Subnets, Supernets, and Aggregation](Documentation/Learning/02-subnet-supernet-aggregation.md)
- [CIDR Context Use Cases](Documentation/Learning/03-cidr-context-use-cases.md)

These guides explain why `swift-cidr` separates host addresses, network
prefixes, Regional Internet Registry-style delegated CIDR blocks, interface
configuration context, and multicast group ranges into distinct types.

## Modules

- `CIDR`: Core address, network, prefix, mixed-family, and endpoint types.
- `CIDRConfig`: Interface-address configuration semantics layered on top of the
  core CIDR model.
- `CIDRPOSIX`: POSIX interoperability helpers for address families and
  `sockaddr` conversion.

Companion package:

- `swift-cidr-registry` with `import CIDRRegistry` for authority-backed
  registry datasets such as `IPv4SpecialPurpose`.
- `swift-cidr-nio` with `import CIDRNIO` for SwiftNIO adapters.
  `CIDRNIO` currently provides strict `ByteBuffer` and `SocketAddress`
  conversions while the core package intentionally stays independent of
  SwiftNIO.

## Toolchains and Platforms

- Swift 6.3
- Xcode 26.4 for local macOS development and `swift test`
- Minimum Apple deployment targets:
  - macOS 15
  - iOS 18

The Apple platform minimums come from this toolchain's built-in `UInt128`
availability. Linux validation is handled in CI.

Before running `swift test` on macOS, make sure the active developer tools point
at Xcode rather than Command Line Tools:

```bash
xcode-select -p
```

Expected path:

```text
/Applications/Xcode-26.4.0.app/Contents/Developer
```

## Examples

### Parse and Format

```swift
import CIDR

let host = IPv4Address("192.0.2.1/24")!
let endpoint = IPEndpoint(address: host, port: TransportPort(53))

print(host.description)
// 192.0.2.1/24

print(host.network.description)
// 192.0.2.0/24

print(endpoint.description)
// 192.0.2.1/24:53
```

### Subnet Math

```swift
import CIDR

let network = IPv4Network("192.0.2.0/24")!
let subnets = Array(network.subnets(prefixLength: 26)).map(\.description)
let summary = IPv4Network.summarize(
    from: IPv4Address("192.0.2.0")!,
    to: IPv4Address("192.0.2.255")!
).map(\.description)

print(subnets)
// ["192.0.2.0/26", "192.0.2.64/26", "192.0.2.128/26", "192.0.2.192/26"]

print(summary)
// ["192.0.2.0/24"]
```

### Mixed-Family Boundary APIs

```swift
import CIDR

let addresses = [
    AnyIPAddress("192.0.2.1/24")!,
    AnyIPAddress("2001:db8::1/64")!
]

for address in addresses {
    print(address.familyName, address.network.description)
}
```

## Development

Common local commands:

```bash
swift build --target CIDR
swift build --target CIDRConfig
swift build --target CIDRPOSIX
swift test
./scripts/benchmarks.sh build
./scripts/benchmarks.sh check
```

## Benchmarking

Benchmark tooling lives in the separate `Benchmarks/` package rather than the
root library package, so contributors may not see it when opening only the root
`Package.swift` in Xcode.

From the repository root:

```bash
./scripts/benchmarks.sh build
./scripts/benchmarks.sh test
./scripts/benchmarks.sh run
./scripts/benchmarks.sh check
./scripts/benchmarks.sh update
./scripts/benchmarks.sh graph
```

The wrapper defaults to `CIDRBenchmarkTarget`. For fixed-loop research
benchmarks that report only user CPU time, select `CIDRCPUBenchmarkTarget`:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run
```

Open `Benchmarks/Package.swift` separately in Xcode if you want the benchmark
package to appear in Xcode's package navigator.

Benchmark details live in [Benchmarks/README.md](Benchmarks/README.md), and the
root wrapper script lives at [scripts/benchmarks.sh](scripts/benchmarks.sh).
Benchmark tooling is intentionally isolated in the nested `Benchmarks` package
so normal library builds, tests, and non-macOS Apple destinations do not pull
in `package-benchmark`.
Linux remains part of normal build/test CI, but benchmark-threshold validation is
currently treated as a macOS workflow because `package-benchmark` relies on ARC
hooks that are fragile on Linux with Swift 6.3.

## License

`CIDR` is licensed under Apache-2.0. See [LICENSE](LICENSE).
