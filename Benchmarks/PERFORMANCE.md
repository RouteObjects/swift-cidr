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
| Date | 2026-07-05 |
| Host | Craig-MacBook-Pro.local |
| CPU / memory | 10 arm64 processors, 64 GB memory |
| OS | macOS 26.5.2, Darwin 25.5.0 |
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
| IPv4 literal, `192.168.1.1` | `parser.pton4v4.simple` | 11 ns | `parser.inet_pton4.simple` | 40 ns |
| IPv4 literal, `255.255.255.255` | `parser.pton4v4.edge` | 12 ns | `parser.inet_pton4.edge` | 46 ns |
| IPv6 literal, `2001:db8::1` | `parser.pton6v4.simple` | 18 ns | `parser.inet_pton6.simple` | 54 ns |
| IPv6 full literal | `parser.pton6v4.full` | 19 ns | `parser.inet_pton6.full` | 173 ns |
| IPv6 middle-compressed literal | `parser.pton6v4.middleCompressed` | 40 ns | `parser.inet_pton6.middleCompressed` | 123 ns |
| IPv4-mapped IPv6 literal | `parser.pton6v4.mapped` | 29 ns | `parser.inet_pton6.mapped` | 89 ns |

## Address Formatting

These rows compare address-only `String` formatting against `inet_ntop`. They do
not include CIDR suffixes.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 zero | `formatter.ipv4.swift.zero` | 7 ns | `formatter.ipv4.inet_ntop.zero` | 172 ns |
| IPv4 simple | `formatter.ipv4.swift.simple` | 7 ns | `formatter.ipv4.inet_ntop.simple` | 172 ns |
| IPv4 mixed | `formatter.ipv4.swift.mixed` | 8 ns | `formatter.ipv4.inet_ntop.mixed` | 180 ns |
| IPv4 max | `formatter.ipv4.swift.max` | 8 ns | `formatter.ipv4.inet_ntop.max` | 181 ns |
| IPv6 simple compressed | `formatter.ipv6.compressed.swift.simple` | 77 ns | `formatter.ipv6.compressed.inet_ntop.simple` | 180 ns |
| IPv6 middle compressed | `formatter.ipv6.compressed.swift.middleCompressed` | 85 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed` | 362 ns |
| IPv6 second middle-compressed case | `formatter.ipv6.compressed.swift.middleCompressed2` | 87 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed2` | 371 ns |
| IPv6 trailing compressed | `formatter.ipv6.compressed.swift.trailingCompressed` | 76 ns | `formatter.ipv6.compressed.inet_ntop.trailingCompressed` | 181 ns |
| IPv6 loopback | `formatter.ipv6.compressed.swift.loopback` | 75 ns | `formatter.ipv6.compressed.inet_ntop.loopback` | 108 ns |
| IPv6 all zero | `formatter.ipv6.compressed.swift.allZero` | 3 ns | `formatter.ipv6.compressed.inet_ntop.allZero` | 66 ns |
| IPv6 mapped hexadecimal | `formatter.ipv6.compressed.swift.mappedHex` | 76 ns | `formatter.ipv6.compressed.inet_ntop.mappedHex` | 325 ns |

## CIDR-Aware Parsing

These rows parse CIDR notation and return typed swift-cidr values. The network
rows also canonicalize host bits to the network boundary.

| Workload | Benchmark | p90 | Extra work included |
|---|---|---:|---|
| IPv4 address CIDR | `parser.cidr.ipAddress.v4` | 11 ns | address parse plus prefix validation |
| IPv6 address CIDR | `parser.cidr.ipAddress.v6` | 25 ns | address parse plus prefix validation |
| IPv4 network CIDR | `parser.cidr.ipNetwork.v4` | 16 ns | parse, prefix validation, network canonicalization |
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
| IPv4 zero, 15M records | 105 ms | 7.0 ns | 106 ms | 7.1 ns | 110 ms | 7.3 ns |
| IPv4 loopback, 15M records | 110 ms | 7.3 ns | 111 ms | 7.4 ns | 115 ms | 7.7 ns |
| IPv4 mixed, 15M records | 120 ms | 8.0 ns | 122 ms | 8.1 ns | 125 ms | 8.3 ns |
| IPv4 broadcast, 15M records | 132 ms | 8.8 ns | 127 ms | 8.5 ns | 129 ms | 8.6 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv4 CIDR mixed `/24`, 15M records | `formatter.cpu.ipv4.cidr.raw.mixed24.15M` | 150 ms | 10.0 ns |

### IPv6 Compressed Formatting

The `String` rows use the public compressed formatter. The raw rows write
compressed address literals into caller-owned UTF-8 buffers.

| Workload | `String` p90 total | `String` per record | Raw p90 total | Raw per record |
|---|---:|---:|---:|---:|
| IPv6 all zero, 20M records | 64.0 ms | 3.2 ns | 143 ms | 7.2 ns |
| IPv6 loopback, 10M records | 734 ms | 73.4 ns | 160 ms | 16.0 ns |
| IPv6 max, 4M records | 330 ms | 82.5 ns | 108 ms | 27.0 ns |
| IPv6 middle compressed, 4M records | 337 ms | 84.2 ns | 98.8 ms | 24.7 ns |
| IPv6 second middle-compressed case, 4M records | 342 ms | 85.5 ns | 108 ms | 27.0 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv6 compressed CIDR `/64`, 4M records | `formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M` | 107 ms | 26.8 ns |

### Bulk Direct UTF-8 Output

The raw rows write CIDR notation into caller-owned UTF-8 buffers and avoid
creating one `String` per record.

| Workload | Raw p90 total | `String` p90 total | Raw per record | `String` per record |
|---|---:|---:|---:|---:|
| IPv4 CIDR, 1M records | 11.1 ms | 55.8 ms | 11.1 ns | 55.8 ns |
| IPv6 compressed CIDR, 1M records | 22.6 ms | 105 ms | 22.6 ns | 105 ns |

### Concrete CIDR Type Formatting

These rows are from the same snapshot as the other CPU rows. Address values are
included as concrete baseline rows; network, block, and multicast range rows
show per-type formatting cost for the concrete CIDR shapes used in bulk exports.

| Type | Operation | Benchmark | p90 total | p90 per record |
|---|---|---|---:|---:|
| `IPv4Address` | address literal | `formatter.cpu.ipv4.public.mixed.15M` | 120 ms | 8.0 ns |
| `IPv4Address` | raw CIDR | `formatter.cpu.ipv4.cidr.raw.mixed24.15M` | 150 ms | 10.0 ns |
| `IPv6Address` | compressed literal | `formatter.cpu.ipv6.compressed.swift.middleCompressed.4M` | 337 ms | 84.2 ns |
| `IPv6Address` | raw compressed CIDR | `formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M` | 106 ms | 26.5 ns |

| IPv4 operation | `IPNetwork` | `CIDRBlock` | `IPMulticastGroupRange` |
|---|---:|---:|---:|
| `description` | 100 ms / 33.3 ns | 103 ms / 34.3 ns | 99.4 ms / 33.1 ns |
| `cidrText` | 101 ms / 33.7 ns | 103 ms / 34.3 ns | 99.5 ms / 33.2 ns |
| `addressOnly` | 26.1 ms / 8.7 ns | 26.5 ms / 8.8 ns | 22.9 ms / 7.6 ns |
| `netmask` | 313 ms / 104.3 ns | 325 ms / 108.3 ns | 305 ms / 101.7 ns |
| `rawCIDR` | 29.5 ms / 9.8 ns | 27.7 ms / 9.2 ns | 27.9 ms / 9.3 ns |

| IPv6 operation | `IPNetwork` | `CIDRBlock` | `IPMulticastGroupRange` |
|---|---:|---:|---:|
| `description` | 327 ms / 109.0 ns | 324 ms / 108.0 ns | 325 ms / 108.3 ns |
| `cidrText` | 330 ms / 110.0 ns | 327 ms / 109.0 ns | 326 ms / 108.7 ns |
| `compressed` | 224 ms / 74.7 ns | 226 ms / 75.3 ns | 224 ms / 74.7 ns |
| `rawCIDR` | 64.6 ms / 21.5 ns | 62.4 ms / 20.8 ns | 53.9 ms / 18.0 ns |

### Slash-Prefix Microbenchmark

These rows compare the current decimal prefix writer against a triplet-table
alternative. The measured result does not justify replacing the current writer.

| Workload | Current p90 total | Current per record | Triplet p90 total | Triplet per record |
|---|---:|---:|---:|---:|
| IPv4 prefix mix, 80M records | 137 ms | 1.7 ns | 143 ms | 1.8 ns |
| IPv6 prefix mix, 80M records | 147 ms | 1.8 ns | 133 ms | 1.7 ns |
| Export prefix mix, 80M records | 137 ms | 1.7 ns | 133 ms | 1.7 ns |

### CPU Parser Check

This fixed-loop parser check mirrors the public parser result for a
middle-compressed IPv6 literal and compares it to `inet_pton`.

| Workload | swift-cidr p90 total | swift-cidr per record | `inet_pton` p90 total | `inet_pton` per record |
|---|---:|---:|---:|---:|
| IPv6 middle-compressed parse, 3M records | 124 ms | 41.3 ns | 377 ms | 125.7 ns |

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
