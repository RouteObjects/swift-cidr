# Focused constant-access comparison

This standalone harness compares the pinned pre-change CIDR sources (`a7f661a`)
with a snapshot of the current working-tree CIDR sources. It changes no historical
benchmark results and needs only the selected Swift compiler and Python 3.

From the repository root, after other builds/tests finish:

```sh
python3 Benchmarks/Results/2026-11-09-constant-access/run.py \
  --output Benchmarks/Results/2026-11-09-constant-access/run-01
```

The output path must not exist. To verify compilation without running the harness,
add `--build-only` and use a different output path. A build-only invocation removes
its temporary binaries; a later measurement invocation rebuilds clean snapshots.

Both CIDR variants use `-O -whole-module-optimization -cross-module-optimization`
in Swift 6 language mode. The selected compiler version is recorded; Swift 6
language mode does **not** mean this tested a Swift 6.2 compiler. Neither compilation
uses library evolution. A separate optimized probe module uses `@inline(never)`
wrappers and deliberately omits cross-module optimization, keeping the timed
runner from importing and hoisting their bodies. CIDR's optimizer-visible code
is available when compiling the probe. Its assembly is saved for inspection.
On macOS every compilation explicitly targets the machine architecture with the
package's macOS 15 deployment floor; `--target` can override this and is recorded.

The four cases measure:

- IPv4-mapped IPv6 string formatting over 512 runtime-generated IPv4 values with
  mixed decimal widths, plus a digest consuming every output byte and its length.
- IPv6 raw multicast group validation, with 75% multicast and 25% unicast inputs,
  consuming the accepted address and host prefix length.
- IPv6 raw multicast range validation across `/16`, `/32`, `/64`, and `/96`,
  including multicast, unicast, and deliberately misaligned prefixes; accepted
  prefix bits and lengths are consumed. Prefix-length construction is included.
- A direct IPv6 multicast-block read combined with a changing nonce. This case
  **includes the opaque wrapper call and checksum overhead**, so it is not a
  measurement of an isolated instruction or bare getter latency.

Input generation and independent semantic checks run outside timed batches.
Each process checks mapped output against decimal formatting and checks validation
results against direct mask/reference rules. It then warms two full batches.
An observable checksum from every timed batch must match the independent expected
value; baseline and changed process checksums must match as well. The nonce and
other inputs vary at runtime, and the runner cannot see the probe implementation.

Baseline calibration targets 50 ms per batch for each case. Both variants then use
identical iteration counts and seeds. Five process repetitions alternate A/B and
B/A order, with seven timed batches per case and process. The default timed and
warmup work should take roughly 20 seconds, plus compilation and startup; actual
duration depends on the machine. Use `--repetitions 3` for a shorter comparison.

`raw-samples.json` preserves every elapsed batch time and operation count.
`summary.json` reports the median batch mean within each process repetition and
the paired changed/baseline ratios. These are **batch-mean measurements**, not
percentiles of individual operation latency. Substantial run-to-run variation
should be reported rather than reduced to one universal speedup claim. There is
no threshold gate, CPU pinning, or claim of a controlled thermal/power environment.

`metadata.json` records compiler/target/machine information, source and harness
SHA-256 hashes, the pinned baseline commit, and exact build commands.
`source-diff.patch` records current source differences from that baseline.
`SHA256SUMS` covers completed-run artifacts; verify it with
`shasum -a 256 -c SHA256SUMS` from the run directory. Build-only output contains
metadata and assembly but no measurements.
