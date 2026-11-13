# CIDR Benchmarks

`CIDRBenchmarkTarget` is the default public/API-facing benchmark target. It is
split into three benchmark suites with different goals.

- `parser.*` measures string-to-bits parser cost through public entry points such as `IPv4Address(...)`, `IPv6Address(...)`, `IPNetwork(...)`, `AutonomousSystemNumber(...)`, and `IPAddressFamily.parseAddress(_:)`.
- `formatter.*` measures bits-to-string formatter cost through public formatting APIs, including `AutonomousSystemNumber.description`, and includes platform `inet_ntop` baselines where useful.
- `currency.*` measures already-constructed value operations to validate the
  currency-type claim for `PrefixLength`, `IPAddress`, `IPNetwork`,
  `IPAddressRange`, `IPAddressCoverage`, `AutonomousSystemNumber`, and the
  `Any*` wrappers, including the allocation-free `IPAddress` InlineArray octet
  boundary.

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

## Summarization Benchmarks

`CIDRSummarizationBenchmarkTarget` is opt-in and has no committed thresholds.
It measures the public prefix, range, and coverage summarizers with prebuilt
IPv4/IPv6 fixtures, reporting wall/user CPU time, malloc counts/bytes, ARC
traffic, and process-level peak resident memory. Peak memory is not an
allocation-per-call measurement. Fixture construction and coverage coalescing
are excluded; every result passes through `blackHole`. Count/memory metrics
explicitly use base units so histogram exports do not round them to K/M units.

```bash
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh build
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh list
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh run \
  --filter '.*\.returning' --no-progress
```

The same sources compile against the pre-optimization library: the default
44 cases use only the existing array-returning API. Compile the candidate with
`SUMMARIZATION_APPEND_APIS` to add fresh-array and reusable-buffer append cases
(132 total), preserving the original names for matched comparisons:

```bash
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh build \
  -Xswiftc -DSUMMARIZATION_APPEND_APIS
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh list \
  --Xswiftc -DSUMMARIZATION_APPEND_APIS
CIDR_BENCHMARK_TARGET=CIDRSummarizationBenchmarkTarget ./scripts/benchmarks.sh run \
  --Xswiftc -DSUMMARIZATION_APPEND_APIS --filter '.*\.appendReused' --no-progress
```

Each case uses three warmup batches, at most 300 ms and 1,000 measured batches.
Prefix/range calls and one-range coverage use 1,000 calls per batch; coverage
with 1,024 or 16,384 normalized disjoint ranges uses one call per batch. Use
`--scale` for per-call batch means. Those percentiles describe batch means,
not individual-call latency; further division by the range count yields a
per-input-range mean. `histogramSamples` exports quantized histogram
observations, not chronological exact samples. Keep original unscaled exports,
compiler versions, revisions, commands, and repeat ordering when comparing.

For a separate fixture check, build/list with
`--Xswiftc -DSUMMARIZATION_VALIDATE_FIXTURES` (or `-Xswiftc` with `build`). This
verifies every expected output count using the returning APIs. Rebuild without
that flag before timing so validation does not precondition allocator state.

Single-range cases are singleton, aligned, maximally fragmented (`1...max-1`),
near-maximum ending at `max`, and full-family `/0`. Coverage fixtures use
singleton, aligned, fragmented, and near-maximum shapes at each range count.
The slot width is `2^16` for IPv4 and `2^64` for IPv6; gaps keep all input ranges
disjoint after normalization. Each coverage range emits these network counts:

| Shape | IPv4 | IPv6 |
|---|---:|---:|
| singleton / aligned | 1 | 1 |
| fragmented | 30 | 126 |
| nearMax | 16 | 64 |

`appendFresh` includes allocation and disposal. `appendReused` reserves the
known output capacity in a uniquely owned local array before measurement,
then clears it with `removeAll(keepingCapacity: true)` inside the measured
loop. Its setup allocation and final disposal are excluded. No array alias is
retained across mutations. Compare these as distinct ownership workloads;
do not attribute their difference solely to the summarization loop.

`Tools/SummarizationComparison/compare.py` runs six alternating baseline/candidate
rounds against already-built executables. Point `CIDR_BASELINE_BUILD` and
`CIDR_CANDIDATE_BUILD` at their Release binary directories and choose a new
`CIDR_RESULTS_DIR`; existing result directories are rejected:

```bash
python3 Benchmarks/Tools/SummarizationComparison/compare.py \
  --baseline-tool "$CIDR_BASELINE_BUILD/BenchmarkTool" \
  --baseline-executable "$CIDR_BASELINE_BUILD/CIDRSummarizationBenchmarkTarget" \
  --candidate-tool "$CIDR_CANDIDATE_BUILD/BenchmarkTool" \
  --candidate-executable "$CIDR_CANDIDATE_BUILD/CIDRSummarizationBenchmarkTarget" \
  --output "$CIDR_RESULTS_DIR"
```

The runner retains commands, executable hashes, unscaled histogram exports,
sample counts, per-run medians, and paired ratios. Use `--metric wallClock`
for a counter-disabled timing control, with malloc and ARC measurement disabled.
The linked allocator interposer remains loaded, so this is not a completely
uninstrumented executable. On Linux,
provide `--baseline-preload` and `--candidate-preload` with the interposer paths
selected by the locked Benchmark plugin; verify that allocation runs report
nonzero counts for fresh arrays before interpreting zero-allocation results.
Peak resident memory describes the benchmark process and is not divided by
the batch size.

On Linux, the full profile can count allocations made by the benchmark's own
CPU/RSS process-stat collection. Those reads occur inside its malloc snapshot
window even when they occur outside the wall-clock interval. Preserve these
observations as process-wide measurements. To check the append buffer's
allocation behavior separately, override the metrics with `mallocCountTotal`
only; do not subtract an assumed fixed profiling overhead from the full pass.

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
  - covers the Apple-26-available/Linux InlineArray octet projections and
    initializers, endpoint-based `IPAddressRange` construction, range and
    coverage containment, and allocation-free mixed-family wrapping in addition
    to the existing address, network, prefix-length, and ASN cases
  - passes octet-adapter fixtures through `Benchmark.identity` before benchmark
    registration, preventing compile-time constant folding without including
    fixture setup in measured closures
  - intentionally excludes range coalescing and network summarization because
    those operations produce arrays and do not belong under a zero-allocation
    currency benchmark contract
  - must stay at zero mallocs, zero object allocations, and zero ARC traffic
  - any nonzero `mallocCount*`, `objectAllocCount`, `retainCount`, `releaseCount`, or `retainReleaseDelta` is a failure

## Workflow

1. Run the benchmarks in release mode.
2. Update the committed threshold snapshot only after an intentional performance change.
3. Use `thresholds check` in regular verification to catch regressions.
4. Use named baselines only for local A/B performance work, not as the long-term reviewed artifact.
The committed 79-case threshold snapshot was regenerated on 2026-11-13 using
Xcode 27.2 / Swift 6.4.2 after the host and toolchain upgrade. This intentional
environment refresh preserves allocation/ARC limits and all existing tolerances.
See the [maintenance provenance](Results/2026-11-13-swift64-thresholds/MAINTENANCE.md)
for the native export procedure and independent fresh verification.
