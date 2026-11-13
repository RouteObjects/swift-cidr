# Summarization candidate — Xcode 27.2 rerun, 2026-11-13

Fresh matched builds under Xcode 27.2 / Apple Swift 6.4.2 reproduce the
summarization improvement. For 16,384 fragmented ranges, counter-disabled
median wall time falls from 114.491 to 1.481 ms for IPv4 and from
432.407 to 11.629 ms for IPv6. The table below derives its values from
the new measurements; this measures the combined patch, including downstream
specialization, rather than isolating the wrapping operators.

The baseline remains `9a2e78c5f4e3d1d08dd54b2f9b856c874dae56d0`. The
`perf/summarization-append` candidate is unpublished. cidrmerge remains behind
the agreed swift-cidr review and release gate. Standard-suite gate outcomes
are reported explicitly below; no general all-gates-pass claim is made.

## Environment and preserved evidence

The new macOS ARM64 runs use macOS 27.2.1 (26B131), Xcode 27.2 (27B52), and
Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`, `clang-2100.4.1.1`), selected explicitly
through `DEVELOPER_DIR`. Both Release benchmark variants use the new default
SwiftBuild engine and freshly built, preserved binaries. Production source,
fixture, dependency-lock, executable, BenchmarkTool, and malloc-interposer
hashes are recorded and audited. Baseline and candidate share the same
fixtures, benchmark harnesses and dependency pins.

Swift 6.4.2 required a registration compatibility adjustment in both the
summarization and existing standard benchmark targets: an immutable
`@Sendable () -> Void` registration closure matches the locked Benchmark
plugin's nonisolated hook. The identical adjustment is applied to baseline
and candidate. Measured callback bodies, fixture configurations and production
code were unchanged by that adjustment. Both adjusted benchmark targets also
compile with Apple Swift 6.3.3; that check did not produce new timing results.

The earlier Xcode 26.6 / Swift 6.3.3 report is preserved byte-for-byte as
[PREVIOUS-XCODE-26.6.md](PREVIOUS-XCODE-26.6.md). Its CSV files, validation JSON,
and raw observations remain unchanged. Linux ARM64 and native x86-64 tests,
measurements and controls were not rerun and retain their original toolchain
labels. Results are not pooled across the old and new macOS toolchains.
Preservation checks verified unchanged hashes for all 27,004 prior evidence
files and four archived deliverables.

## Correctness and compatibility

The new-toolchain macOS Debug and Release suites each passed **295 tests in
33 suites**. `CIDR`, `CIDRArgumentParser`, `CIDRPOSIX`, and `CIDRNIO` also built
for the arm64 iOS 18 simulator deployment target using SDK 27.2. These are
compile checks, not iOS runtime tests. Test source and dependency hashes were
unchanged; the canonical append test differs from the frozen test snapshot
only by formatting. The earlier ten full macOS/Linux test configurations
remain recorded in the previous report.

Coverage includes all 65,536 eight-bit endpoint pairs, 2,000 seeded ranges and
their reversals per real family, an independent prefix-tree oracle, maximum
endpoints, full space, 64-bit carries, custom prefix results and custom-family
width metadata. Empty, seeded and repeated appends and coverage gaps are tested.

## New matched measurements

The new full-profile run covers 44 returning workloads in six alternating
baseline/candidate pairs. All 11 metrics are retained: wall/CPU time, peak
resident memory, malloc counts/bytes, object allocations, and ARC counts.
Candidate append modes cover 88 workloads in three repetitions. The wall-only
control covers six representative workloads in six alternating pairs using
the same preserved binaries, with active malloc/ARC counting and CPU/RSS
sampling disabled. Allocator interposers remain loaded, so these are not fully
uninstrumented executables. All fixtures use three warmup batches.

The following control covers 16,384 disjoint fragmented ranges: 491,520 emitted
IPv4 networks or 2,064,384 IPv6 networks per coverage call. Times are medians of
six run-level medians; changes are medians of the six paired candidate/baseline
ratios.

| Family | Baseline ms | Candidate ms | Median paired change |
|---|---:|---:|---:|
| V4 | 114.491 | 1.481 | -98.70% |
| V6 | 432.407 | 11.629 | -97.31% |

44 of 44 returning workloads improved in the full-profile comparison.
Their median paired wall-clock changes range from -99.76% to
-75.19%. The measurements are environment-specific and do not
establish an application-wide performance guarantee.

Small cases use 1,000-call batches; coverage with 1,024 or 16,384 ranges uses
one call per sample. Exports contain quantized histogram observations, not
chronological raw samples. Dividing a batch percentile by its call count gives
a batch-mean statistic, not an individually timed call-latency percentile.
Peak resident memory is process-level and is not divided by the call count.
Some large cases yielded only one observation per round. Six independent
rounds do not establish precise tail latency, and no confidence interval is
claimed.

## Allocation observations

All 44 reused-buffer cases reported zero median mallocs in each of three
full-profile repetitions. The independent audit also verified zero in every one
of the 113,636 exported reused-buffer malloc observations.
Fresh-buffer controls recorded nonzero allocations in all three repetitions.

Fresh fragmented coverage reports 6 IPv4 and 8 IPv6 median allocations
per call, versus approximately 114,751 and 163,967 in the returning baseline.
Large counts are histogram-quantized and are not exact source-array counts.
Reuse pre-reserves a uniquely owned result buffer; reservation and final
disposal are outside measurement, while clearing with retained capacity is
inside. These observations do not cover arbitrary sharing/copy-on-write or
insufficient capacity. Linux process-stat counter contamination and the
separate Linux allocation-only controls remain documented in the previous
report, with no fixed allocation offset subtracted.

## Existing macOS regression suite

The new standard comparison covers exactly 79 `CIDRBenchmarkTarget` cases on
macOS. It does not cover the CPU or NIO benchmark targets and does not establish
a full cross-platform standard-suite regression result. Every exported count metric was unchanged.

| Check | Actual exit code | Failing cases |
|---|---|---:|
| Fresh matched-policy check | 0 (within thresholds) | 0 |
| Committed absolute limits, baseline | 2 (regression) | 15 |
| Committed absolute limits, candidate | 2 (regression) | 16 |

The absolute checks have 15 shared failing cases. Historical thresholds
remain unchanged; their failures are not reported as passing. A crossing
against a historical threshold alone does not establish a patch regression.
Candidate-only absolute failures: `formatter.ipv6.ipv4Mapped.swift.mapped`.
The validation JSON records exact failure names, shared and variant-only
failures, changed metrics, and the gate exit codes.

The first full-suite comparison had 5 p90 increases over 5%. They ranged from +5.77% to +8.46%. Six alternating follow-up pairs produced these median paired changes:

| Case | p50 change | p90 change | Baseline / candidate absolute-failure rounds | Candidate-only rounds |
|---|---:|---:|---|---|
| `formatter.ipv6.compressed.swift.mappedHex` | -1.30% | -1.33% | [1, 2, 3, 4, 5, 6] / [1, 2, 3, 4, 5, 6] | [] |
| `formatter.ipv6.ipv4Mapped.swift.mapped` | +1.14% | +0.54% | [] / [6] | [6] |
| `formatter.ipv6.preferred.swift.max` | +1.61% | +0.73% | [] / [] | [] |
| `formatter.ipv6.preferred.swift.middleCompressed` | +1.11% | +1.12% | [] / [] | [] |
| `formatter.ipv6.preferred.swift.middleCompressed2` | +0.85% | +0.22% | [] / [] | [] |

The six repeated matched-policy checks returned exit codes [0, 0, 0, 0, 0, 0]. All six were within the existing matched policy.

Historical threshold JSON contains numeric metrics without generation-host,
OS or compiler metadata. November 7 logs establish macOS 26.7.2 / Xcode 26.6 /
Swift 6.3.3 for those earlier runs, not the original environment of every
threshold. The current OS and compiler differ; their individual contributions
to threshold drift were not isolated. The fresh same-host baseline/candidate
comparison is the relevant patch comparison. No threshold was rewritten.

## Reproduction and audit

Use the opt-in target and comparison runner documented in `Benchmarks/README.md`.
The candidate enables `SUMMARIZATION_APPEND_APIS`; the baseline omits it.
Fixture validation was performed separately from timed callbacks. The prior
ARM64 assembly inspection belongs to Swift 6.3.3 and is not relabelled as new
Swift 6.4.2 generated-code evidence. The targeted histogram decoder was checked
against all 1,264 official full-suite p90 exports, including exact recorded
endpoint clamping for sparse histograms; measured records were unchanged.

New compact exports are `macos-xcode27-full-profile.csv`,
`macos-xcode27-counter-disabled.csv`, `macos-xcode27-append-metrics.csv`, and
`macos-xcode27-standard-p90.csv`; completed targeted follow-ups receive a
separate CSV when present. `macos-xcode27-validation.json` records evidence
hashes, audit checks, exact standard gate outcomes and the unchanged release
gate. Raw exports, commands, build logs, binary hashes, and failed attempts
remain in the separate local `macos-xcode27` evidence bundle.
