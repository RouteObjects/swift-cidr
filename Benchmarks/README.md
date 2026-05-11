# CIDR Benchmarks

`CIDRBenchmarkTarget` is split into three benchmark suites with different goals.

- `parser.*` measures string-to-bits parser cost for the historical parser implementations in `ParserBenchSupport` and the current production parser path exposed through `AddressFamily.parseAddress(_:)`.
- `formatter.*` measures bits-to-string formatter cost and includes platform `inet_ntop` baselines where useful.
- `currency.*` measures already-constructed value operations to validate the currency-type claim for `PrefixLength`, `IPAddress`, `IPNetwork`, and the `Any*` wrappers.

`CIDRNIOBenchmarkTarget` is an opt-in adapter benchmark target for SwiftNIO
bridges. It is intentionally separate from the default threshold-gated target so
`NIOCore` measurements do not add noise to core CIDR parser, formatter, or
currency-type tracking.

The versioned parser benchmarks use a stable naming scheme:

- `parser.pton4v1` through `parser.pton4v4`
- `parser.pton6v1` through `parser.pton6v4`

`v4` is the parser currently selected by CIDR itself. Earlier versions stay benchmark-local so the library API surface does not carry historical implementations.

## Standard Commands

From the repository root:

```bash
./scripts/benchmarks.sh build
./scripts/benchmarks.sh run
./scripts/benchmarks.sh check
./scripts/benchmarks.sh update
./scripts/benchmarks.sh graph
```

From the `Benchmarks/` package root:

```bash
swift build -c release --target CIDRBenchmarkTarget
swift package benchmark
swift package benchmark list
swift package benchmark --target CIDRBenchmarkTarget
swift package --allow-writing-to-package-directory benchmark thresholds update --target CIDRBenchmarkTarget
swift package benchmark thresholds check --target CIDRBenchmarkTarget
```

The benchmark package is intentionally separate from the public `swift-cidr`
package so library users do not resolve benchmark-only dependencies. Raw
`swift package benchmark` commands should be run from this `Benchmarks/` package
root. The repository-root `./scripts/benchmarks.sh` wrapper remains the
recommended convenience path when working from the `swift-cidr` root.

To graph the parser suite for wall-clock time, mallocs, and ARC retains in one pass:

```bash
./scripts/benchmark-parser-graphs.sh
```

To run only the IPv6 compressed formatter suite:

```bash
./scripts/benchmarks.sh run --filter '^formatter\.ipv6\.compressed\..*$'
./scripts/benchmarks.sh check --filter '^formatter\.ipv6\.compressed\..*$'
./scripts/benchmarks.sh update --filter '^formatter\.ipv6\.compressed\..*$'
```

## CPU Benchmarks

`CIDRCPUBenchmarkTarget` is a research-only target for fixed-loop batch CPU measurements. It reports only `Time (user CPU)` and is intentionally not part of the default threshold gate.

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh build
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run --filter '^formatter\.cpu\.ipv6\.compressed\.swift\.middleCompressed2\.4M$'
```

The default benchmark commands remain unchanged:

```bash
./scripts/benchmarks.sh run
./scripts/benchmarks.sh check
```

## SwiftNIO Adapter Benchmarks

`CIDRNIOBenchmarkTarget` measures `ByteBuffer`, direct IPv6 literal formatting,
and `SocketAddress` adapter operations. It is research-oriented initially and is
not included in the default threshold gate.

```bash
CIDR_BENCHMARK_TARGET=CIDRNIOBenchmarkTarget ./scripts/benchmarks.sh build
CIDR_BENCHMARK_TARGET=CIDRNIOBenchmarkTarget ./scripts/benchmarks.sh run
```

## Profiling Target

`CIDRProfileTarget` is a profiling CLI, not a `package-benchmark` suite. It
lives under `Tools/` so `swift package benchmark` does not auto-discover it as a
benchmark target.

```bash
swift build --target CIDRProfileTarget
.build/debug/CIDRProfileTarget --case middleCompressed2 --mode bytes --iterations 10
```

## Threshold Policy

- `parser.*`
  - tracks regressions in wall-clock time, throughput, malloc counts, and ARC traffic
  - parser benchmarks are allowed to allocate, but regressions beyond the configured thresholds should fail
- `formatter.*`
  - tracks formatter regressions in wall-clock time, throughput, malloc counts, and ARC traffic
  - formatter benchmarks return `String`; on current Swift runtimes, ASCII output longer than the small-string inline capacity, typically 15 UTF-8 bytes, is expected to allocate once
  - IPv6 formatter allocations should be interpreted as `String` storage cost, not currency-type allocation; compare `formatter.ipv6.compressed.swift.*` against matching `formatter.ipv6.compressed.inet_ntop.*` baselines
- `currency.*`
  - must stay at zero mallocs, zero object allocations, and zero ARC traffic
  - any nonzero `mallocCount*`, `objectAllocCount`, `retainCount`, `releaseCount`, or `retainReleaseDelta` is a failure

## Workflow

1. Run the benchmarks in release mode.
2. Update the committed threshold snapshot only after an intentional performance change.
3. Use `thresholds check` in regular verification to catch regressions.
4. Use named baselines only for local A/B performance work, not as the long-term reviewed artifact.
