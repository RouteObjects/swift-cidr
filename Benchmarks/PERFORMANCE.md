# Performance Snapshot

This is a point-in-time snapshot from the swift-cidr benchmark suite. It gives
readers a practical feel for current performance before they clone the package
and run the benchmarks locally.

Benchmark numbers vary by hardware, OS, Swift toolchain, thermal state, and
background load. Treat these numbers as evidence from one measured environment,
not as universal guarantees. Lower numbers are better.

## Environment

| Field | Value |
|---|---|
| Date | 2026-06-28 |
| Host | Craig-MacBook-Pro.local |
| CPU / memory | 10 arm64 processors, 64 GB memory |
| OS | macOS 26.5.1, Darwin 25.5.0 |
| Swift | Apple Swift 6.3.2 |
| Benchmark package | `benchmark` 1.35.0 |
| Public benchmark metric | p90 wall-clock time, nanoseconds |
| CPU benchmark metric | p90 user CPU time |

## How To Read These Results

The `inet_pton` and `inet_ntop` rows are system baselines for address-only work.
They are useful reference points, but they do not parse CIDR suffixes, validate
prefix lengths, canonicalize networks, or emit `address/prefix` notation.

The CIDR-aware and direct UTF-8 rows therefore have no direct POSIX equivalent.
They measure work that is specific to swift-cidr's typed CIDR model.

## Address Parsing

These rows compare address-only parsing through swift-cidr's address-family
parsers against `inet_pton`.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 literal, `192.168.1.1` | `parser.pton4v4.simple` | 11 ns | `parser.inet_pton4.simple` | 38 ns |
| IPv4 literal, `255.255.255.255` | `parser.pton4v4.edge` | 12 ns | `parser.inet_pton4.edge` | 44 ns |
| IPv6 literal, `2001:db8::1` | `parser.pton6v4.simple` | 17 ns | `parser.inet_pton6.simple` | 56 ns |
| IPv6 full literal | `parser.pton6v4.full` | 19 ns | `parser.inet_pton6.full` | 171 ns |
| IPv6 middle-compressed literal | `parser.pton6v4.middleCompressed` | 39 ns | `parser.inet_pton6.middleCompressed` | 120 ns |
| IPv4-mapped IPv6 literal | `parser.pton6v4.mapped` | 28 ns | `parser.inet_pton6.mapped` | 87 ns |

## Address Formatting

These rows compare address-only `String` formatting against `inet_ntop`. They do
not include CIDR suffixes.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 zero | `formatter.ipv4.swift.zero` | 7 ns | `formatter.ipv4.inet_ntop.zero` | 165 ns |
| IPv4 simple | `formatter.ipv4.swift.simple` | 7 ns | `formatter.ipv4.inet_ntop.simple` | 166 ns |
| IPv4 mixed | `formatter.ipv4.swift.mixed` | 8 ns | `formatter.ipv4.inet_ntop.mixed` | 172 ns |
| IPv4 max | `formatter.ipv4.swift.max` | 8 ns | `formatter.ipv4.inet_ntop.max` | 174 ns |
| IPv6 simple compressed | `formatter.ipv6.compressed.swift.simple` | 81 ns | `formatter.ipv6.compressed.inet_ntop.simple` | 168 ns |
| IPv6 middle compressed | `formatter.ipv6.compressed.swift.middleCompressed` | 85 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed` | 361 ns |
| IPv6 second middle-compressed case | `formatter.ipv6.compressed.swift.middleCompressed2` | 88 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed2` | 364 ns |
| IPv6 trailing compressed | `formatter.ipv6.compressed.swift.trailingCompressed` | 80 ns | `formatter.ipv6.compressed.inet_ntop.trailingCompressed` | 176 ns |
| IPv6 loopback | `formatter.ipv6.compressed.swift.loopback` | 75 ns | `formatter.ipv6.compressed.inet_ntop.loopback` | 98 ns |
| IPv6 all zero | `formatter.ipv6.compressed.swift.allZero` | 7 ns | `formatter.ipv6.compressed.inet_ntop.allZero` | 63 ns |
| IPv6 mapped hexadecimal | `formatter.ipv6.compressed.swift.mappedHex` | 77 ns | `formatter.ipv6.compressed.inet_ntop.mappedHex` | 318 ns |

## CIDR-Aware Parsing

These rows parse CIDR notation and return typed swift-cidr values. The network
rows also canonicalize host bits to the network boundary.

| Workload | Benchmark | p90 | Extra work included |
|---|---|---:|---|
| IPv4 address CIDR | `parser.cidr.ipAddress.v4` | 11 ns | address parse plus prefix validation |
| IPv6 address CIDR | `parser.cidr.ipAddress.v6` | 25 ns | address parse plus prefix validation |
| IPv4 network CIDR | `parser.cidr.ipNetwork.v4` | 15 ns | parse, prefix validation, network canonicalization |
| IPv6 network CIDR | `parser.cidr.ipNetwork.v6` | 27 ns | parse, prefix validation, network canonicalization |

## Fixed-Loop CPU Measurements

These rows use `CIDRCPUBenchmarkTarget`, which runs fixed-loop batch CPU
measurements. Totals are p90 user CPU time for the full loop. Per-record values
are calculated from the benchmark name suffix, such as `15M`, `4M`, or `1M`.

### IPv4 Formatting Hot Path

The public and engine rows create `String` values. The raw rows write address
bytes into caller-owned UTF-8 buffers.

| Workload | Public p90 | Public per record | Engine p90 | Engine per record | Raw p90 | Raw per record |
|---|---:|---:|---:|---:|---:|---:|
| IPv4 zero, 15M records | 104 ms | 6.9 ns | 105 ms | 7.0 ns | 109 ms | 7.3 ns |
| IPv4 loopback, 15M records | 110 ms | 7.3 ns | 110 ms | 7.3 ns | 114 ms | 7.6 ns |
| IPv4 mixed, 15M records | 119 ms | 7.9 ns | 119 ms | 7.9 ns | 124 ms | 8.3 ns |
| IPv4 broadcast, 15M records | 125 ms | 8.3 ns | 124 ms | 8.3 ns | 133 ms | 8.9 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv4 CIDR mixed `/24`, 15M records | `formatter.cpu.ipv4.cidr.raw.mixed24.15M` | 147 ms | 9.8 ns |

### IPv6 Compressed Formatting

The `String` rows use the public compressed formatter. The raw rows write
compressed address literals into caller-owned UTF-8 buffers.

| Workload | `String` p90 total | `String` per record | Raw p90 total | Raw per record |
|---|---:|---:|---:|---:|
| IPv6 all zero, 20M records | 139 ms | 7.0 ns | 140 ms | 7.0 ns |
| IPv6 loopback, 10M records | 741 ms | 74.1 ns | 158 ms | 15.8 ns |
| IPv6 max, 4M records | 333 ms | 83.3 ns | 108 ms | 27.0 ns |
| IPv6 middle compressed, 4M records | 347 ms | 86.8 ns | 100 ms | 25.0 ns |
| IPv6 second middle-compressed case, 4M records | 347 ms | 86.8 ns | 110 ms | 27.5 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv6 compressed CIDR `/64`, 4M records | `formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M` | 106 ms | 26.5 ns |

### Bulk Direct UTF-8 Output

The raw rows write CIDR notation into caller-owned UTF-8 buffers and avoid
creating one `String` per record.

| Workload | Raw p90 total | `String` p90 total | Raw per record | `String` per record |
|---|---:|---:|---:|---:|
| IPv4 CIDR, 1M records | 11.0 ms | 53.9 ms | 11.0 ns | 53.9 ns |
| IPv6 compressed CIDR, 1M records | 22.3 ms | 108 ms | 22.3 ns | 108 ns |

### Slash-Prefix Microbenchmark

These rows compare the current decimal prefix writer against a triplet-table
alternative. The measured result does not justify replacing the current writer.

| Workload | Current p90 total | Current per record | Triplet p90 total | Triplet per record |
|---|---:|---:|---:|---:|
| IPv4 prefix mix, 80M records | 133 ms | 1.66 ns | 133 ms | 1.66 ns |
| IPv6 prefix mix, 80M records | 132 ms | 1.65 ns | 133 ms | 1.66 ns |
| Export prefix mix, 80M records | 133 ms | 1.66 ns | 132 ms | 1.65 ns |

### CPU Parser Check

This fixed-loop parser check mirrors the public parser result for a
middle-compressed IPv6 literal and compares it to `inet_pton`.

| Workload | swift-cidr p90 total | swift-cidr per record | `inet_pton` p90 total | `inet_pton` per record |
|---|---:|---:|---:|---:|
| IPv6 middle-compressed parse, 3M records | 119 ms | 39.7 ns | 374 ms | 124.7 ns |

## Reproduce These Numbers

Benchmark filters are Swift `Regex` whole-match patterns. Use
`./scripts/benchmarks.sh list` first if you need to inspect benchmark names.
Prefix-style filters should end in `.*`.

From the repository root:

```bash
./scripts/benchmarks.sh run \
  --filter '^(parser\.(pton|inet_pton|cidr)|formatter\.(ipv4|ipv6)).*$' \
  --metric wallClock \
  --format markdown \
  --path stdout \
  --no-progress \
  --time-units nanoseconds \
  --grouping benchmark
```

The address-literal parser rows can also be run directly:

```bash
./scripts/benchmarks.sh run \
  --filter '^parser\.(pton|inet_pton).*$' \
  --metric wallClock \
  --format markdown \
  --path stdout \
  --no-progress \
  --time-units nanoseconds \
  --grouping benchmark
```

For the fixed-loop CPU rows:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run \
  --filter '^formatter\.cpu\..*$|^parser\.cpu\..*$' \
  --format markdown \
  --path stdout \
  --no-progress \
  --time-units nanoseconds \
  --grouping benchmark
```
