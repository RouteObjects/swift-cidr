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
| Date | 2026-06-27 |
| Host | Craig-MacBook-Pro.local |
| CPU / memory | 10 arm64 processors, 64 GB memory |
| OS | macOS 26.5.1, Darwin 25.5.0 |
| Swift | Apple Swift 6.3.2 |
| Benchmark package | `benchmark` 1.35.0 |
| Public benchmark metric | p90 wall-clock time, nanoseconds |
| Bulk benchmark metric | p90 user CPU time, nanoseconds |

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
| IPv4 literal, `192.168.1.1` | `parser.pton4v4.simple` | 11 ns | `parser.inet_pton4.simple` | 39 ns |
| IPv4 literal, `255.255.255.255` | `parser.pton4v4.edge` | 13 ns | `parser.inet_pton4.edge` | 46 ns |
| IPv6 literal, `2001:db8::1` | `parser.pton6v4.simple` | 18 ns | `parser.inet_pton6.simple` | 55 ns |
| IPv6 full literal | `parser.pton6v4.full` | 19 ns | `parser.inet_pton6.full` | 185 ns |
| IPv6 middle-compressed literal | `parser.pton6v4.middleCompressed` | 40 ns | `parser.inet_pton6.middleCompressed` | 127 ns |
| IPv4-mapped IPv6 literal | `parser.pton6v4.mapped` | 29 ns | `parser.inet_pton6.mapped` | 89 ns |

## Address Formatting

These rows compare address-only `String` formatting against `inet_ntop`. They do
not include CIDR suffixes.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 zero | `formatter.ipv4.swift.zero` | 11 ns | `formatter.ipv4.inet_ntop.zero` | 170 ns |
| IPv4 simple | `formatter.ipv4.swift.simple` | 10 ns | `formatter.ipv4.inet_ntop.simple` | 169 ns |
| IPv4 mixed | `formatter.ipv4.swift.mixed` | 10 ns | `formatter.ipv4.inet_ntop.mixed` | 176 ns |
| IPv4 max | `formatter.ipv4.swift.max` | 12 ns | `formatter.ipv4.inet_ntop.max` | 179 ns |
| IPv6 simple compressed | `formatter.ipv6.compressed.swift.simple` | 81 ns | `formatter.ipv6.compressed.inet_ntop.simple` | 180 ns |
| IPv6 middle compressed | `formatter.ipv6.compressed.swift.middleCompressed` | 88 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed` | 374 ns |
| IPv6 second middle-compressed case | `formatter.ipv6.compressed.swift.middleCompressed2` | 92 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed2` | 386 ns |
| IPv6 trailing compressed | `formatter.ipv6.compressed.swift.trailingCompressed` | 80 ns | `formatter.ipv6.compressed.inet_ntop.trailingCompressed` | 205 ns |
| IPv6 loopback | `formatter.ipv6.compressed.swift.loopback` | 83 ns | `formatter.ipv6.compressed.inet_ntop.loopback` | 101 ns |
| IPv6 all zero | `formatter.ipv6.compressed.swift.allZero` | 8 ns | `formatter.ipv6.compressed.inet_ntop.allZero` | 65 ns |
| IPv6 mapped hexadecimal | `formatter.ipv6.compressed.swift.mappedHex` | 80 ns | `formatter.ipv6.compressed.inet_ntop.mappedHex` | 331 ns |

## CIDR-Aware Parsing

These rows parse CIDR notation and return typed swift-cidr values. The network
rows also canonicalize host bits to the network boundary.

| Workload | Benchmark | p90 | Extra work included |
|---|---|---:|---|
| IPv4 address CIDR | `parser.cidr.ipAddress.v4` | 11 ns | address parse plus prefix validation |
| IPv6 address CIDR | `parser.cidr.ipAddress.v6` | 25 ns | address parse plus prefix validation |
| IPv4 network CIDR | `parser.cidr.ipNetwork.v4` | 16 ns | parse, prefix validation, network canonicalization |
| IPv6 network CIDR | `parser.cidr.ipNetwork.v6` | 28 ns | parse, prefix validation, network canonicalization |

## Bulk Direct UTF-8 Output

These rows use `CIDRCPUBenchmarkTarget`, which runs fixed-loop batch CPU
benchmarks. The raw rows write into caller-owned UTF-8 buffers and avoid
creating one `String` per record.

| Workload | Raw p90 total | `String` p90 total | Raw per record | `String` per record |
|---|---:|---:|---:|---:|
| IPv4 CIDR, 1M records | 10.7 ms | 129 ms | 10.7 ns | 129 ns |
| IPv6 compressed CIDR, 1M records | 23.6 ms | 108 ms | 23.6 ns | 108 ns |

## Reproduce These Numbers

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

For the fixed-loop bulk output rows:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run \
  --filter '.*bulk.*' \
  --format markdown \
  --path stdout \
  --no-progress \
  --time-units nanoseconds \
  --grouping benchmark
```
