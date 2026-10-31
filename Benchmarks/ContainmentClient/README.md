# Downstream Containment Benchmark

This separate Swift package compares ordinary typed `network.contains(address:)`
calls with `AnyIPNetwork.contains(address:)` across the `CIDR` module boundary.
It depends on the local root package and adds no third-party dependencies.

Run from the repository root:

```bash
swift run -c release --package-path Benchmarks/ContainmentClient \
  --disable-automatic-resolution ContainmentClient
```

The output is CSV. Each case scans 20,000 networks, alternating between a peer in
the last network and a peer outside all networks. Construction and family erasure
are outside timing. Five warmup batches precede 41 measured batches; each batch
contains 25 complete scans. Case order rotates between batches. Every batch must
produce the expected match count.

Divide `elapsed_ns` by `scans` to obtain the **batch mean time per scan**. A median
or percentile calculated from these values describes batch means, not individual
call latency. These are containment microbenchmarks, not connection-throughput
measurements or complete admission-policy decisions. Background load and the
compiler configuration can affect results.

The `@inline(never)` scan functions preserve runtime inputs and inspectable
assembly; they do not specialize or otherwise annotate the containment calls.
The typed IPv4/IPv6 and family-erased cases use the same address bits and prefix
contexts. No deprecated address-bits-only containment API is used.

For semantic validation, run the exhaustive prefix/context boundary tests:

```bash
./scripts/test.sh -c release --filter ContainmentSpecializationTests
```

See [the investigation report](../../Documentation/Performance/Containment-2026-10-30.md)
for baseline comparisons, generated-code findings, validation scope, and evidence.
