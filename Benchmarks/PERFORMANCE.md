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
| Date | 2026-07-06 |
| Host | Craig-MacBook-Pro.local |
| CPU / memory | 10 arm64 processors, 64 GB memory (Apple M1 Max) |
| OS | macOS 26.5.2, Darwin 25.5.0 |
| Swift | Apple Swift 6.3.2 |
| Benchmark package | `benchmark` 1.35.0 |
| Mode A metric | p90 wall-clock time, nanoseconds |
| Mode B metric | p90 user CPU time |

## How To Read This Snapshot

### Two measurement modes (do not mix)

swift-cidr reports performance in two different ways. They answer different
questions and must not be compared as the same kind of number.

| Mode | Target | Metric | Question it answers |
|---|---|---|---|
| **A — Public API latency** | `CIDRBenchmarkTarget` | p90 **wall-clock** nanoseconds | How fast is one call through a public Swift API? |
| **B — Bulk CPU throughput** | `CIDRCPUBenchmarkTarget` | p90 **user CPU** time over a fixed loop | How fast is a hot export loop over millions of records? |

**Mode A** is what `./scripts/benchmarks.sh check` gates. Use it when comparing
swift-cidr to other libraries or to POSIX `inet_pton` / `inet_ntop`.

At nanosecond scale, ±1 ns fluctuation on Mode A rows is expected OS background
noise and does not by itself indicate a regression.

**Mode B** is research-only (not threshold-gated). Per-record nanoseconds in
Part II are derived by dividing total user CPU time by the loop count encoded in
the benchmark name (`15M`, `4M`, `1M`, etc.). Use Part II when tuning bulk
export or log-pipeline hot paths — not when writing a library comparison.

Mode A and Mode B per-record values are often numerically close for the same
workload, but they measure different things. Do not cite them interchangeably.

### POSIX baseline limits

The `inet_pton` and `inet_ntop` rows are system baselines for address-only work.
They are useful reference points, but they do not parse CIDR suffixes, validate
prefix lengths, canonicalize networks, or emit `address/prefix` notation.

The CIDR-aware and direct UTF-8 rows therefore have no direct POSIX equivalent.
They measure work that is specific to swift-cidr's typed CIDR model.

Direct UTF-8 rows write into caller-owned buffers and avoid creating one
`String` per record. They are most relevant for bulk workflows such as file,
database, socket, or telemetry export.

### What to cite externally

| Audience / use case | Cite from |
|---|---|
| Library comparison, README, blog | **Headline Summary** or **Part I** (Mode A) |
| Export pipeline / log volume tuning | **Part II** (Mode B) |
| Regression hunting on a specific type | **Appendix** |

When comparing to other Swift networking libraries, use Mode A address-format rows
and state that POSIX baselines are address-only.

## Headline Summary

The rows most readers need. Every row is labeled by measurement mode.

| Workload | p90 result | Mode | vs POSIX |
|---|---:|---|---|
| IPv4 address parse (`192.168.1.1`) | 11 ns | A | 38 ns `inet_pton` |
| IPv4 address format (mixed) | 8 ns | A | 174 ns `inet_ntop` |
| IPv4 network CIDR parse | 15 ns | A | no POSIX equivalent |
| IPv6 address parse (middle-compressed) | 38 ns | A | 120 ns `inet_pton` |
| IPv6 address format (middle-compressed) | 81 ns | A | 360 ns `inet_ntop` |
| IPv6 network CIDR parse | 27 ns | A | no POSIX equivalent |
| IPv4 CIDR bulk export (raw UTF-8, 1M records) | 11.0 ns/record | B | no POSIX equivalent |
| IPv6 compressed CIDR bulk export (raw, 1M records) | 22.7 ns/record | B | no POSIX equivalent |

---

## Part I — Public API Latency (Wall-Clock)

**Target:** `CIDRBenchmarkTarget`
**Metric:** p90 wall-clock nanoseconds per invocation
**Gated by:** `./scripts/benchmarks.sh check`

These rows measure single-call cost through public Swift APIs. They are the
right numbers for external library comparisons.

### Address Parsing

These rows compare address-only parsing through swift-cidr's address-family
parsers against `inet_pton`.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 literal, `192.168.1.1` | `parser.pton4v4.simple` | 11 ns | `parser.inet_pton4.simple` | 38 ns |
| IPv4 literal, `255.255.255.255` | `parser.pton4v4.edge` | 12 ns | `parser.inet_pton4.edge` | 44 ns |
| IPv6 literal, `2001:db8::1` | `parser.pton6v4.simple` | 17 ns | `parser.inet_pton6.simple` | 53 ns |
| IPv6 full literal | `parser.pton6v4.full` | 18 ns | `parser.inet_pton6.full` | 171 ns |
| IPv6 middle-compressed literal | `parser.pton6v4.middleCompressed` | 38 ns | `parser.inet_pton6.middleCompressed` | 120 ns |
| IPv4-mapped IPv6 literal | `parser.pton6v4.mapped` | 28 ns | `parser.inet_pton6.mapped` | 86 ns |

### Address Formatting

These rows compare address-only `String` formatting against `inet_ntop`. They do
not include CIDR suffixes.

| Workload | swift-cidr benchmark | swift-cidr p90 | System baseline | Baseline p90 |
|---|---|---:|---|---:|
| IPv4 zero | `formatter.ipv4.swift.zero` | 7 ns | `formatter.ipv4.inet_ntop.zero` | 167 ns |
| IPv4 simple | `formatter.ipv4.swift.simple` | 7 ns | `formatter.ipv4.inet_ntop.simple` | 167 ns |
| IPv4 mixed | `formatter.ipv4.swift.mixed` | 8 ns | `formatter.ipv4.inet_ntop.mixed` | 174 ns |
| IPv4 max | `formatter.ipv4.swift.max` | 8 ns | `formatter.ipv4.inet_ntop.max` | 176 ns |
| IPv6 simple compressed | `formatter.ipv6.compressed.swift.simple` | 74 ns | `formatter.ipv6.compressed.inet_ntop.simple` | 174 ns |
| IPv6 middle compressed | `formatter.ipv6.compressed.swift.middleCompressed` | 81 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed` | 360 ns |
| IPv6 second middle-compressed case | `formatter.ipv6.compressed.swift.middleCompressed2` | 84 ns | `formatter.ipv6.compressed.inet_ntop.middleCompressed2` | 364 ns |
| IPv6 trailing compressed | `formatter.ipv6.compressed.swift.trailingCompressed` | 73 ns | `formatter.ipv6.compressed.inet_ntop.trailingCompressed` | 175 ns |
| IPv6 loopback | `formatter.ipv6.compressed.swift.loopback` | 72 ns | `formatter.ipv6.compressed.inet_ntop.loopback` | 98 ns |
| IPv6 all zero | `formatter.ipv6.compressed.swift.allZero` | 3 ns | `formatter.ipv6.compressed.inet_ntop.allZero` | 63 ns |
| IPv6 mapped hexadecimal | `formatter.ipv6.compressed.swift.mappedHex` | 73 ns | `formatter.ipv6.compressed.inet_ntop.mappedHex` | 322 ns |

### CIDR-Aware Parsing

These rows parse CIDR notation and return typed swift-cidr values. The network
rows also canonicalize host bits to the network boundary. No POSIX equivalent
exists for this work.

| Workload | Benchmark | p90 | Extra work included |
|---|---|---:|---|
| IPv4 address CIDR | `parser.cidr.ipAddress.v4` | 11 ns | address parse plus prefix validation |
| IPv6 address CIDR | `parser.cidr.ipAddress.v6` | 24 ns | address parse plus prefix validation |
| IPv4 network CIDR | `parser.cidr.ipNetwork.v4` | 15 ns | parse, prefix validation, network canonicalization |
| IPv6 network CIDR | `parser.cidr.ipNetwork.v6` | 27 ns | parse, prefix validation, network canonicalization |

---

## Part II — Bulk CPU Throughput (Fixed-Loop)

> **Warning:** These rows use `CIDRCPUBenchmarkTarget`. They measure p90 **user
> CPU time** over fixed loops, not wall-clock latency. Per-record nanoseconds are
> computed from the benchmark name suffix (`15M`, `4M`, `1M`, etc.). Use Part I
> for library comparisons; use Part II for export-loop and bulk-format tuning.

**Target:** `CIDRCPUBenchmarkTarget`
**Metric:** p90 user CPU time (totals in ms; per-record derived from loop count)
**Not gated by:** `./scripts/benchmarks.sh check`

### IPv4 Formatting Hot Path

The public and engine rows create `String` values. The raw rows write address
bytes into caller-owned UTF-8 buffers.

| Workload | Public p90 | Public per record | Engine p90 | Engine per record | Raw p90 | Raw per record |
|---|---:|---:|---:|---:|---:|---:|
| IPv4 zero, 15M records | 104 ms | 6.9 ns | 104 ms | 6.9 ns | 109 ms | 7.3 ns |
| IPv4 loopback, 15M records | 109 ms | 7.3 ns | 109 ms | 7.3 ns | 114 ms | 7.6 ns |
| IPv4 mixed, 15M records | 118 ms | 7.9 ns | 118 ms | 7.9 ns | 123 ms | 8.2 ns |
| IPv4 broadcast, 15M records | 124 ms | 8.3 ns | 142 ms | 9.5 ns | 128 ms | 8.5 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv4 CIDR mixed `/24`, 15M records | `formatter.cpu.ipv4.cidr.raw.mixed24.15M` | 147 ms | 9.8 ns |

### IPv6 Compressed Formatting

The `String` rows use the public compressed formatter. The raw rows write
compressed address literals into caller-owned UTF-8 buffers.

| Workload | `String` p90 total | `String` per record | Raw p90 total | Raw per record |
|---|---:|---:|---:|---:|
| IPv6 all zero, 20M records | 62.9 ms | 3.1 ns | 139 ms | 7.0 ns |
| IPv6 loopback, 10M records | 709 ms | 70.9 ns | 160 ms | 16.0 ns |
| IPv6 max, 4M records | 317 ms | 79.2 ns | 107 ms | 26.8 ns |
| IPv6 middle compressed, 4M records | 320 ms | 80.0 ns | 99.4 ms | 24.9 ns |
| IPv6 second middle-compressed case, 4M records | 331 ms | 82.8 ns | 109 ms | 27.2 ns |

| Workload | Benchmark | Raw p90 total | Raw per record |
|---|---|---:|---:|
| IPv6 compressed CIDR `/64`, 4M records | `formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M` | 106 ms | 26.5 ns |

### Bulk Direct UTF-8 Output

The raw rows write CIDR notation into caller-owned UTF-8 buffers and avoid
creating one `String` per record.

| Workload | Raw p90 total | `String` p90 total | Raw per record | `String` per record |
|---|---:|---:|---:|---:|
| IPv4 CIDR, 1M records | 11.0 ms | 26.6 ms | 11.0 ns | 26.6 ns |
| IPv6 compressed CIDR, 1M records | 22.7 ms | 103 ms | 22.7 ns | 103 ns |

---

## Appendix — Engineering Deep Dives

Detailed rows for regression analysis and per-type attribution. Skip unless you
are tuning a specific hot path or investigating a threshold failure.

### Concrete CIDR Type Formatting

These rows are from the same snapshot as the other CPU rows. Address values are
included as concrete baseline rows; network, block, and multicast range rows
show per-type formatting cost for the concrete CIDR shapes used in bulk exports.

| Type | Operation | Benchmark | p90 total | p90 per record |
|---|---|---|---:|---:|
| `IPv4Address` | address literal | `formatter.cpu.ipv4.public.mixed.15M` | 118 ms | 7.9 ns |
| `IPv4Address` | raw CIDR | `formatter.cpu.ipv4.cidr.raw.mixed24.15M` | 147 ms | 9.8 ns |
| `IPv6Address` | compressed literal | `formatter.cpu.ipv6.compressed.swift.middleCompressed.4M` | 320 ms | 80.0 ns |
| `IPv6Address` | raw compressed CIDR | `formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M` | 106 ms | 26.5 ns |

| IPv4 operation | `IPNetwork` | `CIDRBlock` | `IPMulticastGroupRange` |
|---|---:|---:|---:|
| `description` | 27.7 ms / 9.2 ns | 27.7 ms / 9.2 ns | 26.7 ms / 8.9 ns |
| `cidrText` | 27.7 ms / 9.2 ns | 27.7 ms / 9.2 ns | 24.8 ms / 8.3 ns |
| `addressOnly` | 25.8 ms / 8.6 ns | 25.8 ms / 8.6 ns | 22.9 ms / 7.6 ns |
| `netmask` | 310 ms / 103.3 ns | 312 ms / 104.0 ns | 306 ms / 102.0 ns |
| `rawCIDR` | 29.5 ms / 9.8 ns | 27.6 ms / 9.2 ns | 27.6 ms / 9.2 ns |

| IPv6 operation | `IPNetwork` | `CIDRBlock` | `IPMulticastGroupRange` |
|---|---:|---:|---:|
| `description` | 252 ms / 84.0 ns | 265 ms / 88.3 ns | 249 ms / 83.0 ns |
| `cidrText` | 250 ms / 83.3 ns | 249 ms / 83.0 ns | 239 ms / 79.7 ns |
| `compressed` | 219 ms / 73.0 ns | 220 ms / 73.3 ns | 218 ms / 72.7 ns |
| `rawCIDR` | 63.3 ms / 21.1 ns | 61.8 ms / 20.6 ns | 54.0 ms / 18.0 ns |

### Slash-Prefix Microbenchmark

These rows compare the current decimal prefix writer against a triplet-table
alternative. The measured result does not justify replacing the current writer.

| Workload | Current p90 total | Current per record | Triplet p90 total | Triplet per record |
|---|---:|---:|---:|---:|
| IPv4 prefix mix, 80M records | 132 ms | 1.6 ns | 132 ms | 1.6 ns |
| IPv6 prefix mix, 80M records | 132 ms | 1.6 ns | 132 ms | 1.6 ns |
| Export prefix mix, 80M records | 132 ms | 1.6 ns | 132 ms | 1.6 ns |

### CPU Parser Check

This fixed-loop parser check mirrors the public parser result for a
middle-compressed IPv6 literal and compares it to `inet_pton`.

| Workload | swift-cidr p90 total | swift-cidr per record | `inet_pton` p90 total | `inet_pton` per record |
|---|---:|---:|---:|---:|
| IPv6 middle-compressed parse, 3M records | 118 ms | 39.3 ns | 372 ms | 124.0 ns |

---

## Reproduce This Snapshot

This snapshot is hand-curated from benchmark output captured on 2026-07-06.
Re-running benchmarks may differ slightly from the snapshot date.

Benchmark filters are Swift `Regex` whole-match patterns. Use
`./scripts/benchmarks.sh list` first if you need to inspect benchmark names.
Prefix-style filters should end in `.*`.

### Part I — Public API latency (wall-clock)

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

Address-literal parser rows only:

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

### Part II — Bulk CPU throughput (fixed-loop)

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run \
  --filter '^formatter\.cpu\..*$|^parser\.cpu\..*$' \
  --format markdown \
  --path stdout \
  --no-progress \
  --time-units nanoseconds \
  --grouping benchmark
```
