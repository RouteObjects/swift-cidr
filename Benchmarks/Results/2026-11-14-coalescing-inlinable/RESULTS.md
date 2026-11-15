# Coalescing inlinable prototype — 2026-11-14

> Publication note: Paths in this repository copy use placeholders. Embedded hashes and audit results describe the original immutable evidence; [path portability](PATH_PORTABILITY.md) explains the [manifest](portable-copy-manifest.json) binding these copies to their originals.

Full local evidence bundle: `MAC_EVIDENCE_ROOT/REPORT.md`. This repository directory contains the report, patches, generated-code captures and aggregate verification evidence. Raw logs, individual outputs, binaries and source/build snapshots remain in that Downloads bundle.

**The complete inlinable chain reaches specialized CLI sorting and improves elapsed time in every matched case.** Paired median elapsed changes range from −13.26% to −63.36%; all 66 individual elapsed-time pairs favor the candidate. Peak RSS is essentially unchanged. This addresses the generic sorting CPU cost; retained input chunks and large range/network/output buffers remain separate optimization targets.

This is an uncommitted prototype on `perf/coalescing-inlinable` in both swift-cidr and cidrmerge. No algorithm, public signature, dependency requirement, or compiler floor was changed. The compiler floor remains Swift 6.2. No release, push or commit was performed.

## Plan

1. Preserve the original Swift 6.4.2 profiling and competitor evidence, then freeze matching baseline/candidate source snapshots.
2. Expose the existing coalescing implementation and helper chain for downstream optimization; add generic-sequence boundary tests.
3. Verify the actual CLI sorting call path, run full tests, then perform balanced elapsed-time/peak-memory comparisons on the original inputs.

## Patch

Upstream changes: `IPAddressCoverage.init(_:)`, `IPAddressRange.coalescing(_:)`, the unchecked range initializer and adjacency helpers become inlinable. Immutable endpoint storage becomes internal usable-from-inline. Downstream change: the package-only generic `CIDRMergeCoverage` initializer becomes inlinable. Public semantics and signatures are unchanged; the general Sequence/custom-family fallback remains.

- [swift-cidr unified patch](control/swift-cidr.patch)
- [cidrmerge unified patch](control/cidrmerge.patch)

The upstream-only attempt C-v1 **did not** change the actual CLI sorting path. Its original binary and disassembly remain preserved. C-v2 adds visibility through the Core initializer and **does** change the actual caller edges. This does not establish that each individual upstream annotation is independently necessary.

| Actual generated path | Result |
|---|---|
| B, matched unmodified baseline | CLI calls generic Core initializer, generic coalescing, and external Sequence.sorted |
| C-v1, upstream visibility only | Same generic path; not selected for timing |
| C-v2, complete tested chain | CLI directly calls V4/Array and V6/Array specialized coalescing and concrete sorting |

The C-v2 comparator bodies contain fixed-width loads/comparisons without calls. The inspected specialized insertion-sort bodies access fixed-layout elements without generic Collection.subscript.read witnesses or the associated malloc/free access contexts. Ordinary sorting arrays, merge buffers and indirect comparator calls remain: this is not an allocation-free sorting claim.

[Actual callsite and disassembly evidence](control/codegen-C-v2.md), [preserved C-v1 failure](control/codegen-C-v1.md).

## Tests

| Toolchain/platform | Package | Debug | Release |
|---|---|---:|---:|
| Apple Swift 6.4.2, macOS ARM64 | swift-cidr | 298 passed | 298 passed |
| Apple Swift 6.4.2, macOS ARM64 | cidrmerge | 57 passed | 57 passed |
| Swift 6.2.4, OrbStack ARM64 Linux | swift-cidr | 298 passed | 298 passed |
| Swift 6.2.4, OrbStack ARM64 Linux | cidrmerge | 57 passed | 57 passed |

Total: **1,420 test executions passed**. Three new upstream tests cover direct AnySequence inputs with IPv4, IPv6 and custom UInt16 storage, including shuffled/duplicate/contained/adjacent ranges, equal lower bounds, maximum endpoints and empty input. Formatting and diff whitespace checks pass.

[macOS test receipts](control/macos-tests.json), [compiler-floor receipts](floor-6.2.4/verification.json), [formatting receipt](control/formatting.json).

The floor check used the already-cached OrbStack image `sha256:e508ef1e4be68087f720de622b91cbf1e32799a7aa96134b35e6f1a1d656db7a`, with networking disabled. The first launch attempted unavailable python3; no tests started. The bash retry passed. The first macOS upstream Debug attempt was blocked by sandbox access to the Clang module cache; the authorized rerun passed. These failures remain recorded separately from successful tests. Raw logs are preserved; one combined native SwiftPM log interleaves Unicode bytes, and the summary parser tolerates invalid glyph bytes without rewriting the log.

## Verification and matched benchmark method

Both timed binaries were built with Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`) in release mode on an Apple M1 Max with 64 GiB memory, macOS 27.2.1 build 26B131 and Xcode 27.2. Both use the same local-package dependency topology and the original seven external dependency pins. The local swift-cidr baseline is release 0.10.0, commit `e268b139e334a0662185d16a3e07b187ab0cbe70`; cidrmerge is 0.4.0, commit `e4f1aed90c013cc5b0d75bb0d29d80f0259e19b0`. Candidate sources differ only by the recorded visibility patch and new test file. The canonical cidrmerge manifest remains pinned to released swift-cidr; only isolated snapshots substitute the local package for this experiment.

- B SHA-256: `26c90ba7f8ae66bffb6dc897b5fc04fdb6529d8613815bc406332370391c7be6`.
- C-v2 SHA-256: `ab28022ecaf3a656c52ec83d7ba633886ad61b3b3255475c4984a9631eb57f3f`.

The frozen non-test release binaries were copied before release-test builds, which can relink instrumented/testable targets. All codegen and timed measurements refer to these exact immutable copies.

The eight split corpora and three native mixed corpora reuse the original bytes. Each configuration has one excluded warmup and six measured rounds, alternating BC/CB order and rotating case order: 132 measured samples/192 process invocations plus 22 warmup samples/32 processes. Every output must match the complete independently verified original output bytes. Split elapsed time is the sum of family process times; split peak RSS is their maximum. Native cases use one mixed-family process. Generation, independent verification, builds and profiling are outside timing. All stdout, stderr, native time records and failure observations are retained. No sample is removed or retried.

[Methodology](control/methodology.md), [frozen inputs](control/pre-benchmark-freeze.json), [host state](control/host-before-benchmark.json).

### Results

All cells are medians over six measurements. The percentage column is the median of six per-round percentage changes, so it need not exactly equal the ratio of the two displayed median times. Negative values favor C. Each original corpus contains one million records before split-family partitioning.

| Suite / corpus | B elapsed (s) | C elapsed (s) | Paired change | B peak RSS (MiB) | C peak RSS (MiB) |
|---|---:|---:|---:|---:|---:|
| split / ipv4-disjoint | 0.740 | 0.598 | -19.36% | 70.29 | 70.12 |
| split / ipv6-disjoint | 1.074 | 0.926 | -13.26% | 167.17 | 167.16 |
| split / mixed-disjoint | 0.916 | 0.769 | -16.54% | 86.94 | 86.79 |
| split / mixed-permuted | 2.211 | 0.917 | -58.49% | 86.92 | 86.95 |
| split / mixed-overlap | 1.827 | 0.764 | -58.11% | 71.29 | 71.30 |
| split / mixed-adjacent | 0.844 | 0.707 | -17.02% | 71.56 | 71.20 |
| split / bgp-like-ipv4 | 2.026 | 0.744 | -63.36% | 50.91 | 51.09 |
| split / range-derived-mixed | 0.976 | 0.792 | -18.81% | 94.70 | 94.80 |
| native / mixed-disjoint | 0.922 | 0.785 | -15.39% | 119.64 | 119.98 |
| native / mixed-permuted | 2.236 | 0.882 | -60.15% | 120.41 | 119.98 |
| native / mixed-overlap | 1.831 | 0.765 | -58.29% | 83.77 | 83.55 |

[Full samples, ranges and paired statistics](measurements/summary.json). All 132 measured samples and 22 warmups passed the original exact-output checks. No measured case regressed in elapsed time. The small RSS differences are not evidence of a memory optimization; the largest median paired difference is under 1 MiB in magnitude.

No competitor was rebenchmarked in this experiment. Do not combine these new candidate timings with historical rs-aggregate/iprange timings as a new matched ranking. Six pairs support the observed large improvements on these fixtures; they are not a broad workload distribution or p90 qualification. Performance was measured only on macOS ARM64. Linux runs establish compiler-floor correctness, not Linux performance.

Independent audit passed: all 224 process outputs and native time records, the full sample inventory, 520 file hashes, balanced ordering, and all group/paired statistics were checked. [Audit](control/independent-benchmark-audit.md), [machine-readable audit](control/independent-benchmark-audit.json).

### Reproduction and rollback

In the full local evidence bundle, the isolated source packages, exact build/test commands and logs are retained under `snapshots/`, `control/` and `floor-6.2.4/`. Both CLI snapshots use the relative local dependency `../swift-cidr`; canonical repository manifests are unchanged. Recreate a fresh directory, rebuild the frozen B/C source pairs using the commands in the build receipts, copy the non-test release binaries, populate the hash freeze, then run `python3 control/run_matched.py --validate-only` followed by `python3 control/run_matched.py`. The runner intentionally refuses to overwrite an existing measurements directory; preserve this directory and its references.

Rollback is limited to reversing the two recorded source patches and removing the newly added test/report files after review. Preserve unrelated pre-existing benchmark files and changes; do not reset either working tree wholesale. The branch bases remain the original main commits and no commit was created.

## Notes

- `@specialized` is supported in Swift 6.4.2 and was introduced in Swift 6.3. Unlike incidental compiler-generated clones, it can insert exact-type checks in a generic entry point and redispatch to requested pre-specializations. It is a credible separate experiment, but was not applied or benchmarked here. The current inlinable fix works while retaining the Swift 6.2 floor, so this prototype does not require a floor increase. [SE-0460](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0460-specialized.md); local tiny compiler probes are retained in `control/specialized-attribute-probe/`.
- `@inlinable` exposes an implementation for client optimization; it does not guarantee specialization for every caller/compiler. The actual CLI callsite evidence is therefore part of acceptance. [SE-0193](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0193-cross-module-inlining-and-specialization.md).
- The internal endpoint storage, unchecked initializer and helper methods become ABI-visible implementation commitments. They remain unavailable through normal public source access. Future binary-compatible changes must preserve compatible access; unchecked construction still requires ordered endpoints.
- No `@frozen`, forced inlining, algorithm rewrite, new dependency, public specialized API, or compiler-floor change was introduced.
- Before a release, qualify the selected patch with requested macOS/ARM64 Linux/x86-64 Linux performance and remaining release checks. Those cross-platform performance and release checks remain outstanding.
- Previous benchmark/profile directories and pre-existing repository changes remain preserved. New evidence is additive in this directory and the new repository result directories.

## Linux follow-up — 2026-11-15

<!-- linux-followup:cidrmerge-coalescing-linux-20261115T043459Z -->
Matched Swift 6.4.2 validation is complete on ARM64 Linux and swift-dev x86-64: both actual sorting-call checks, 2,828 test executions and both matched benchmark runs passed. See the [Linux report](linux/RESULTS.md) for separate platform results, retained observations and scope. This is an additive follow-up; the original macOS report contents and measurements above remain unchanged. Statements above about outstanding Linux performance checks describe the initial macOS stage; this follow-up completes the requested Linux comparisons. Release checks remain separate.
