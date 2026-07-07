# CIDR Benchmarks

`CIDRBenchmarkTarget` is the default public/API-facing benchmark target. It is
split into three benchmark suites with different goals.

- `parser.*` measures string-to-bits parser cost through public IP entry points such as `IPv4Address(...)`, `IPv6Address(...)`, `IPNetwork(...)`, and `IPAddressFamily.parseAddress(_:)`.
- `formatter.*` measures bits-to-string formatter cost through public formatting APIs and includes platform `inet_ntop` baselines where useful.
- `currency.*` measures already-constructed value operations to validate the currency-type claim for `PrefixLength`, `IPAddress`, `IPNetwork`, and the `Any*` wrappers.

Historical parser-engine experiments were removed from the release benchmark
package and archived outside the repository for future writing/reference work.

`CIDRNIOBenchmarkTarget` is an opt-in adapter benchmark target for SwiftNIO
bridges. It is intentionally separate from the default threshold-gated target so
`NIOCore` measurements do not add noise to core CIDR parser, formatter, or
currency-type tracking.

See [PERFORMANCE.md](PERFORMANCE.md) for a dated performance snapshot. It separates
wall-clock public API latency (Mode A) from fixed-loop bulk CPU throughput (Mode B),
with a headline summary, detailed tables, and an engineering appendix.

## Platform Notes

Benchmarks are intended for macOS and Linux command-line workflows. The nested
benchmark package still declares the same Apple platform minimums as the root
package so SwiftPM and Xcode resolve dependencies consistently. The iOS
declaration is not a supported execution path for benchmark binaries.

## Standard Commands

From the repository root:

```bash
./scripts/benchmarks.sh build
./scripts/benchmarks.sh list
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

## Filter Semantics

Benchmark filters are Swift `Regex` whole-match patterns. They are not substring
searches. Use `./scripts/benchmarks.sh list` to inspect exact benchmark names
before writing a filter.

Exact names work as-is:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run \
  --filter 'formatter.cpu.ipv4.raw.mixed.15M'
```

Prefix-style filters need a trailing `.*`, and contains-style filters need both
leading and trailing `.*`:

```bash
./scripts/benchmarks.sh run --filter '^formatter\.ipv6\.compressed\..*$'
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run --filter '.*bulk.*'
```

Filters such as `raw` or `^formatter\.cpu\.ipv6\.compressed\.raw\.` match
nothing because they do not match the entire benchmark name.

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
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh list
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run --filter '^formatter\.cpu\.ipv6\.compressed\.swift\.middleCompressed2\.4M$'
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run --filter '^formatter\.cpu\.ipv6\.compressed\.raw\.(middleCompressed2|middleCompressed|max|loopback|allZero)\..*$'
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

`CIDRProfileTarget` is a profiling CLI, not a Benchmark suite. It
lives under `Tools/` so `swift package benchmark` does not auto-discover it as a
benchmark target.

```bash
swift build --target CIDRProfileTarget
.build/debug/CIDRProfileTarget --case middleCompressed2 --mode bytes --iterations 10
```

## Threshold Policy

- `parser.*`
  - tracks regressions in wall-clock time, malloc counts, and ARC traffic
  - omits throughput from the threshold-gated target because wall-clock already gates the same timing behavior with less reciprocal-metric noise
  - parser benchmarks are allowed to allocate, but regressions beyond the configured thresholds should fail
- `formatter.*`
  - tracks formatter regressions in wall-clock time, malloc counts, and ARC traffic
  - omits throughput from the threshold-gated target because `String`-returning formatter runs showed noisy reciprocal throughput checks
  - formatter benchmarks return `String`; on current Swift runtimes, ASCII output longer than the small-string inline capacity, typically 15 UTF-8 bytes, is expected to allocate once
  - formatter allocations should be interpreted as `String` storage cost, not currency-type allocation; compare Swift formatter cases against matching `formatter.*.inet_ntop.*` baselines where present
- `currency.*`
  - must stay at zero mallocs, zero object allocations, and zero ARC traffic
  - any nonzero `mallocCount*`, `objectAllocCount`, `retainCount`, `releaseCount`, or `retainReleaseDelta` is a failure

## Workflow

1. Run the benchmarks in release mode.
2. Update the committed threshold snapshot only after an intentional performance change.
3. Use `thresholds check` in regular verification to catch regressions.
4. Use named baselines only for local A/B performance work, not as the long-term reviewed artifact.
