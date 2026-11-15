# Linux Swift 6.4.2 validation

Portable Linux report and compact metadata. The full local evidence bundle is `/Users/craig/Downloads/cidrmerge-coalescing-linux-20261115T043459Z`; raw outputs, binaries and build products remain in Downloads.

The frozen candidate reaches specialized sorting on both Linux architectures. Both complete test matrices and both independently audited matched benchmark runs passed. Results below are kept separate by platform; no pooled speedup is calculated.

This validation adds no executable source changes to the existing uncommitted `perf/coalescing-inlinable` prototype. B is the original swift-cidr 0.10.0 / cidrmerge 0.4.0 source; C is the same source plus the tested visibility chain and three upstream tests.

## Plan and patch

Run full baseline/candidate Debug/Release tests and the same eight split plus three native matched workloads on native ARM64 Linux and native x86-64 swift-dev. Verify actual CLI sorting calls before timing. The existing patch exposes the coalescing/helper/coverage chain and the package Core initializer; no additional production patch is part of this validation.


## Tests and generated code

Each platform runs baseline swift-cidr 295 tests and cidrmerge 57 tests in both configurations, plus candidate swift-cidr 298 tests and cidrmerge 57 tests in both configurations: 1,414 test executions per platform. The candidate's three additional tests cover arbitrary sequences, custom storage families and maximum endpoints.

On both Linux architectures, actual caller instructions show baseline CLI construction reaching generic coalescing and external Sequence.sorted, while the candidate directly reaches V4/Array and V6/Array coalescing and concrete sorting. The inspected concrete comparator bodies have no calls; fixed-layout insertion-sort access avoids generic read witnesses. Ordinary sorting/merge buffers remain. This is not an allocation-free sorting claim.


| Platform | Variant | swift-cidr Debug / Release | cidrmerge Debug / Release | Total test executions |
|---|---|---:|---:|---:|
| ARM64 Linux | B | 295 / 295 | 57 / 57 | 704 |
| ARM64 Linux | C | 298 / 298 | 57 / 57 | 710 |
| swift-dev x86-64 | B | 295 / 295 | 57 / 57 | 704 |
| swift-dev x86-64 | C | 298 / 298 | 57 / 57 | 710 |

**2,828 test executions passed**, with 1,414 on each platform. Each platform contributes 132 measured samples/192 child processes and 22 excluded warmups/32 processes. The two platforms therefore retain 264 measured samples/384 processes and 44 warmups/64 processes. These counts are not pooled performance statistics.

## Verification method

Both platforms use Swift 6.4.2 release toolchains and frozen non-test release binaries, copied before test builds can relink targets. Swift runtime paths and libswiftCore hashes are explicit, and ldd linkage is recorded. Source/manifest bytes match the macOS freeze. Baseline upstream Package.resolved was normalized to the candidate's upstream-only dependency graph; this only removes irrelevant app pins. All actual dependency revisions match the original locked versions and their tracked checkout contents are clean.

There are six measured BC/CB paired rounds and one excluded warmup per case: 132 measured samples / 192 child processes and 22 warmups / 32 processes per platform. Each corpus has one million entries before family splitting. Every output hash/byte count must match the original independently verified coverage output. Raw outputs, stderr, timing/usage records and all observations are retained. No sample is removed or retried.

Linux elapsed time surrounds process launch and wait. Peak RSS is obtained separately for each child with wait4, converting ru_maxrss KiB to bytes. For split inputs, elapsed times are summed and RSS is the maximum of the family processes. Native mixed cases run one process. Linux timing excludes the BSD time wrapper used on macOS; comparisons are baseline versus candidate within each platform, not pooled cross-platform scores. Profiling, builds, independent hashing and substantial transfers are outside each host's timed phase.

Peak-memory values are process RSS, not total allocated bytes or allocator-call counts. Percent changes are medians of six per-pair changes and may differ slightly from ratios of displayed median times. Six pairs are limited evidence for these exact fixtures, not broad production-tail latency qualification.

ARM64 runs natively under OrbStack in the pinned cached Swift 6.4.2 image, with networking disabled. swift-dev is native x86-64 on an Intel Xeon E5520 with four allowed logical CPUs; the explicit Swiftly 6.4.2 path avoids its empty noninteractive Swift PATH. Host/kernel/CPU/memory/disk/cgroup metadata are retained. A three-GiB disk guard applies before each build and benchmark sample. The dedicated ARM64 container is stopped after completion; prior containers/images and toolchains are unchanged.


The tables show six-sample medians. The percentage column is the median of the six per-round elapsed changes; negative values favor C. Peak RSS values are medians in MiB. Individual exceptions are retained below each platform table.

## ARM64 Linux / OrbStack

11/11 workload paired medians improved; elapsed changes range from -46.42% to -6.55%. 65/66 individual pairs favor C. Median paired RSS differences range from -0.03 to +0.14 MiB.

Host: Apple Silicon host, native ARM64 guest; `aarch64`; 10 allowed logical CPUs; 15.66 GiB guest-visible memory; kernel `7.2.12-orbstack-00394-gbecdd6130068`. Swift executable: `/usr/bin/swift`. Measurement completion timestamp: `2026-11-15T04:54:54.923531+00:00`.

| Suite / corpus | B elapsed (s) | C elapsed (s) | Paired elapsed change | B peak RSS (MiB) | C peak RSS (MiB) |
|---|---:|---:|---:|---:|---:|
| split / ipv4-disjoint | 2.226 | 2.000 | -10.54% | 42.76 | 42.75 |
| split / ipv6-disjoint | 3.035 | 2.719 | -10.70% | 111.33 | 111.44 |
| split / mixed-disjoint | 2.601 | 2.443 | -6.62% | 65.58 | 65.69 |
| split / mixed-permuted | 4.425 | 2.459 | -43.70% | 72.95 | 73.06 |
| split / mixed-overlap | 3.896 | 2.339 | -40.81% | 57.69 | 57.82 |
| split / mixed-adjacent | 2.505 | 2.160 | -13.11% | 50.31 | 50.46 |
| split / bgp-like-ipv4 | 4.178 | 2.245 | -46.42% | 40.26 | 40.26 |
| split / range-derived-mixed | 2.702 | 2.405 | -10.24% | 65.47 | 65.58 |
| native / mixed-disjoint | 2.584 | 2.410 | -6.55% | 77.15 | 77.12 |
| native / mixed-permuted | 4.419 | 2.466 | -44.19% | 84.60 | 84.61 |
| native / mixed-overlap | 3.809 | 2.304 | -39.44% | 67.46 | 67.47 |

Retained non-improving individual pairs (not removed or retried):

- native / mixed-disjoint, round 6: +0.43% elapsed.

[Raw aggregate measurements](arm64/measurements/summary.json), [full tests](arm64/control/build-tests/summary.json), [actual sorting calls](arm64/control/codegen.md), [independent audit](control/independent-arm64-audit.json), [runtime postcheck](arm64/control/runtime-postcheck.json), [host metadata](arm64/control/host-before-benchmark.json).

| Binary | SHA-256 |
|---|---|
| B | `46526cf942a91687cf231cbeaaf6bb65d9e19f233fc54b0e6b1839d27c8a4af8` |
| C | `3ce0ef33d754242e0629c20443853b081ca3f1ec0bc622cae77c1ebc93b480e9` |

## x86-64 Linux / swift-dev

11/11 workload paired medians improved; elapsed changes range from -27.58% to -1.20%. 61/66 individual pairs favor C. Median paired RSS differences range from -0.30 to -0.04 MiB.

Host: Intel(R) Xeon(R) CPU           E5520  @ 2.27GHz; `x86_64`; 4 allowed logical CPUs; 8.00 GiB guest-visible memory; kernel `6.14.8-2-pve`. Swift executable: `/home/craig/.local/share/swiftly/toolchains/6.4.2/usr/bin/swift`. Measurement completion timestamp: `2026-11-15T05:29:26.827497+00:00`.

| Suite / corpus | B elapsed (s) | C elapsed (s) | Paired elapsed change | B peak RSS (MiB) | C peak RSS (MiB) |
|---|---:|---:|---:|---:|---:|
| split / ipv4-disjoint | 8.290 | 8.164 | -1.31% | 44.08 | 43.91 |
| split / ipv6-disjoint | 10.761 | 10.404 | -1.98% | 112.64 | 112.63 |
| split / mixed-disjoint | 9.462 | 9.318 | -1.20% | 66.95 | 66.83 |
| split / mixed-permuted | 12.823 | 9.714 | -24.81% | 74.32 | 74.25 |
| split / mixed-overlap | 11.713 | 9.251 | -20.91% | 58.98 | 58.95 |
| split / mixed-adjacent | 9.203 | 8.937 | -3.01% | 51.70 | 51.62 |
| split / bgp-like-ipv4 | 12.112 | 8.749 | -27.58% | 41.60 | 41.45 |
| split / range-derived-mixed | 9.739 | 9.408 | -2.95% | 66.89 | 66.78 |
| native / mixed-disjoint | 9.736 | 9.408 | -2.60% | 78.55 | 78.26 |
| native / mixed-permuted | 13.010 | 9.858 | -24.36% | 85.98 | 85.72 |
| native / mixed-overlap | 11.898 | 9.403 | -21.43% | 68.74 | 68.61 |

Retained non-improving individual pairs (not removed or retried):

- split / ipv4-disjoint, round 1: +0.89% elapsed.
- split / ipv6-disjoint, round 2: +70.67% elapsed.
- split / mixed-disjoint, round 2: +32.42% elapsed.
- split / mixed-disjoint, round 3: +0.49% elapsed.
- split / range-derived-mixed, round 3: +0.17% elapsed.

The roughly 1–3% paired median gains on the easier inputs are small relative to the observed run-to-run variation and should not be treated as conclusive improvements. The five sorting-heavy cases (split mixed-permuted, split mixed-overlap, split bgp-like-ipv4, native mixed-permuted and native mixed-overlap) show approximately 20–28% lower paired medians, with every measured pair in those cases favoring C.

The two large candidate slowdowns above, and a slower baseline mixed-adjacent sample, are retained. Their additional elapsed time is also charged as child CPU time; major faults, swaps and input blocks are zero. Those counters do not identify the cause. No observation is removed or retried. See the [raw-record outlier review](control/x86_64-outlier-review.md).

[Raw aggregate measurements](x86_64/measurements/summary.json), [full tests](x86_64/control/build-tests/summary.json), [actual sorting calls](x86_64/control/codegen.md), [independent audit](control/independent-x86_64-audit.json), [runtime postcheck](x86_64/control/runtime-postcheck.json), [host metadata](x86_64/control/host-before-benchmark.json).

| Binary | SHA-256 |
|---|---|
| B | `341234e40b810847b2b33de12b6bfb7ccdfbfb882aa5424061dd299d23832211` |
| C | `5aceca2a43b1edc362763b546273c620b4a2fe05c8f7ed4336f9ddc4dbc62fa2` |

## Source and runtime identity

The report generator independently checks both binary hashes against build receipts, frozen inputs, generated-code captures, codegen gates and audit receipts. All 185 Swift source/Package.swift files per platform match the original macOS source freeze. Runtime postchecks match the originally recorded libswiftCore hash; the ARM64 check additionally hashes the copied library from the completed container. The independent output audit itself does not claim to have executed or reprofiled the binaries.

Source bases: swift-cidr `e268b139e334a0662185d16a3e07b187ab0cbe70`; cidrmerge `e4f1aed90c013cc5b0d75bb0d29d80f0259e19b0`. All actual dependency revisions retain the original lock selection. Source and runtime receipts remain platform-specific.

## Notes and reproducibility

The complete new artifacts remain in the Downloads directory named above, with independent platform directories. Frozen sources, commands, logs, config/runtime metadata, codegen captures and retained measurements permit reproduction in a new directory. The runners refuse to overwrite existing phases/results. The x86 remote copy lives under the same named Downloads directory on swift-dev.

These tests do not raise the Swift 6.2 floor previously checked by the prototype. No commit, release or dependency adoption is performed. Reverting the prototype still means reversing the existing source patches and preserving unrelated files, not resetting either repository wholesale. Broader release gates and non-benchmark deployment qualification remain separate.

The candidate still supports the previously tested Swift 6.2 floor. No `@specialized` attribute was applied or benchmarked in this work; the actual change is the `@inlinable` visibility chain. Internal usable-from-inline storage and helpers remain ABI-visible implementation commitments.

Canonical working copies differ from the frozen candidate only by removal of four `// CHANGE:` comment prefixes in three production files. Executable tokens and tests are unchanged; the preservation audit records the exact allowed differences. The isolated CLI manifest uses the documented local dependency override, while the canonical CLI manifest retains its released dependency requirement.

## Reproduce without overwriting evidence

Use a fresh platform directory and follow [the shared harness instructions](shared/README.md): prepare the frozen sources/fixtures/dependency seeds, configure the explicit Swift 6.4.2 executable, run the build/test phase, review actual codegen and bind the gate to the binaries, freeze/validate, then start the separate matched benchmark phase. Preserve the original outputs. All build/test commands are retained in per-step receipts, while each measured child record contains its complete command and safe environment. The runners refuse an existing phase/results directory.

The earlier [macOS measurement archive](../measurements/summary.json) and [macOS experiment report](../RESULTS.md) remain separate evidence. Their timings are not recomputed or replaced here.

[Canonical working-copy preservation receipt](control/preservation-20261115T144404Z.json). Its exact allowed source differences are removal of four `// CHANGE:` comment prefixes; executable tokens and tests match the frozen candidate. The canonical CLI dependency requirement is unchanged; the local override belongs only to isolated snapshots.
