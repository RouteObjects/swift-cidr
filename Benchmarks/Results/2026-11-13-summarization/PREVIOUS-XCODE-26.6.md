# Summarization candidate measurements — 2026-11-12–13

The `perf/summarization-append` candidate adds three append APIs, exposes both
append and returning forms to downstream specialization, and uses bounded
wrapping arithmetic with final-block termination. Its baseline is
`9a2e78c5f4e3d1d08dd54b2f9b856c874dae56d0` (main before these changes).
Results measure the combined patch, including specialization; they do not
isolate a speedup attributable solely to wrapping operators.

**Status:** implementation, correctness validation, and the requested benchmark
runs and controls are complete. Native x86-64 raw artifacts have been retrieved
and verified. Matched regression checks passed; existing absolute timing limits
still fail as detailed below. This is an unpublished 0.10.0 candidate; cidrmerge
remains behind the agreed release gate.

## Correctness and compatibility

All 295 tests passed in each of ten full runs: macOS Debug/Release with Apple
Swift 6.3.3; native Linux ARM64 and x86-64 Debug/Release with Swift 6.2.4 and
6.3.3. All four products built for the iOS 18 simulator. Root dependency pins
were unchanged. The three production files match the tested snapshots exactly;
one test file subsequently received formatting-only line wrapping.

Coverage includes all 65,536 eight-bit endpoint pairs, 2,000 seeded ranges and
their reversals per real family, independent prefix-tree comparison, maximum
endpoints, full space, 64-bit carries, custom prefix results and custom-family
width metadata. Empty/seeded/repeated appends and uncovered gaps are tested.

## Counter-disabled timing controls

The table covers 16,384 disjoint fragmented ranges: 491,520 emitted IPv4 networks
or 2,064,384 IPv6 networks per coverage call. Figures are medians across six
run-level medians; percentage changes are medians of paired run ratios.

| Environment | Family | Baseline ms | Candidate ms | Paired change |
|---|---|---:|---:|---:|
| macOS ARM64 | V4 | 113.017 | 1.453 | -98.71% |
| macOS ARM64 | V6 | 430.703 | 11.350 | -97.38% |
| Linux ARM64 | V4 | 188.318 | 1.436 | -99.24% |
| Linux ARM64 | V6 | 745.538 | 17.396 | -97.65% |
| Linux x86-64 | V4 | 316.277 | 4.407 | -98.60% |
| Linux x86-64 | V6 | 1320.157 | 125.043 | -90.56% |

Each platform used matched Release builds, identical fixtures, three warmup
batches and six alternating baseline/candidate rounds. The counter-disabled
pass covered six representative workloads and requested only wall-clock timing
on unchanged binaries: active malloc/ARC counting and CPU/RSS sampling were
disabled. Allocator interposers remained
loaded, so these are not completely uninstrumented executables. macOS ran on
ARM64 with Xcode 26.6 / Apple Swift 6.3.3; Linux ARM64 used the native OrbStack
architecture and the official Swift 6.3.3 Ubuntu Noble image, without emulation.
Linux x86-64 ran natively on an Intel host with Ubuntu 24.04.5 and Swift 6.3.3.
These are environment-specific observations, not an application-wide guarantee.

All 44 returning workloads improved in each platform's full-profile comparison;
none had a median paired wall-clock regression over 5%. Small cases use
1,000-call batches; 1,024/16,384-range coverage uses one call per sample. Exported
observations are quantized histogram values, not chronological raw samples.
Some large baseline cases produced only one sample per round; their six
independent measured calls do not support precise tail-latency claims.
For the x86-64 fragmented IPv6 timing control specifically, each round contains
one baseline and three candidate observations. No confidence interval is claimed.

## Allocation observations

On macOS, all 44 reused-buffer cases reported zero median mallocs in each of
three full-profile repetitions. Fresh fragmented coverage reported six IPv4
and eight IPv6 allocations, versus approximately 115,000 and 164,000 baseline
allocations. Large histogram counts are quantized, not exact source-array counts.

Linux full-profile reuse medians ranged from 16–20 allocations per batch on
ARM64 and 16–44 on x86-64. The locked Benchmark runtime places allocating
Linux process-stat reads inside its malloc snapshot window, and its RSS sampler
can also contribute process-wide allocations. No fixed offset was subtracted.

Separate controls on both native Linux architectures collected only
`mallocCountTotal`, retaining each platform's candidate binary. The table shows
per-call median counts for each of three repetitions; small-case batch counts
are divided by 1,000. Pre-reserving and final disposal are outside reuse
measurement; clearing with retained capacity is inside it. This qualifies those
ownership conditions, not arbitrary caller sharing/COW or insufficient capacity.

| Fixture / append mode | Linux ARM64 runs 1 / 2 / 3 | Linux x86-64 runs 1 / 2 / 3 |
|---|---|---|
| coverage v4 fragmented ranges16384 appendFresh | 6 / 6 / 6 | 6 / 6 / 6 |
| coverage v4 fragmented ranges16384 appendReused | 0 / 0 / 0 | 0 / 0 / 0 |
| coverage v6 fragmented ranges16384 appendFresh | 8 / 8 / 8 | 8 / 8 / 8 |
| coverage v6 fragmented ranges16384 appendReused | 0 / 0 / 0 | 0 / 0 / 0 |
| prefix v4 singleton appendFresh | 1 / 1 / 1 | 1 / 1 / 1 |
| prefix v4 singleton appendReused | 0 / 0 / 0 | 0 / 0 / 0 |
| prefix v6 singleton appendFresh | 1 / 1 / 1 | 1 / 1 / 1 |
| prefix v6 singleton appendReused | 0 / 0 / 0 | 0 / 0 / 0 |

Every exported reused-buffer sample was zero in these isolated controls.
The x86-64 fragmented IPv6 reuse control had four observations per repetition;
the sample and ownership limits still apply.

## Existing regression suite

The 79-case macOS `CIDRBenchmarkTarget` matched-policy check passed and every
count metric was unchanged. This check does not cover the CPU or NIO targets,
or establish a full cross-platform regression result.
Committed absolute timing thresholds failed in nine cases on both baseline and
candidate, with eight shared failures. The snapshots were not rewritten.

The host was upgraded to macOS 27.2 before this experiment. The experiment's
recorded environment is macOS 27.2.1 with selected Xcode 26.6 / Swift 6.3.3;
both the unchanged main snapshot and candidate were freshly built and measured
in that environment. Their matched comparison remains the relevant evidence
for this patch. Historical absolute timing thresholds are a different-environment
reference, so their crossings do not establish a patch regression. The OS change
plausibly contributes to drift, but its exact contribution was not measured.

Threshold JSON files contain numeric metrics without generation-environment
metadata. Earlier November 7 logs record macOS 26.7.2 / Xcode 26.6 / Swift 6.3.3,
but do not establish the environment that originally generated every threshold.
The history is preserved; no absolute gate is relabelled as passing or rebased.
Separate later checks confirmed installed Xcode 27.2 and standalone Command Line
Tools 27.2, both exposing Swift 6.4.2. Those tools did not produce these benchmark
results. Xcode 27.2 was selected afterward and a default-toolchain compile/run
check passed; a Swift 6.4.2 comparison requires fresh matched builds and measurements.

Six alternating follow-up pairs investigated the initial IPv6 hash increase
and two marginal absolute-threshold crossings. Median paired p50/p90 changes:
IPv6 hash +1.52% / -0.45%; IPv4 simple formatting 0.00% / +0.52%; IPv6
middleCompressed2 formatting -1.30% / -1.94%. Every repeated matched-policy check
passed. One hash p90 repetition still increased 6.15%; the increase did not
repeat consistently. IPv4 simple formatting exceeded its absolute limit in
two candidate rounds and one baseline round, including one candidate-only
crossing. Absolute gates are therefore not reported as passing.

## Generated code and reproduction

The ARM64 consumer probe exposes specialized append kernels and an
equality-driven loop. UInt128 carry arithmetic, prefix-length validation, and
Array uniqueness/growth checks remain. The compiler may perform the final
wrapping increment speculatively before testing equality. The old consumer
probe hides its loop behind a generic call, so no instruction-count comparison
of that hidden body is claimed.

Use the opt-in target and comparison runner documented in `Benchmarks/README.md`.
The candidate enables `SUMMARIZATION_APPEND_APIS`; the baseline omits it. Fixture
count validation ran separately, and its flag was absent from timing binaries.
Baseline/candidate dependency graphs match within each platform. Raw exports,
commands, hashes, logs, failed attempts, and control observations are retained
in the local evidence bundle; the CSV files here are compact reviewed summaries.
The earlier x86 summary preview is preserved for provenance; the full-profile
CSV is generated from the retrieved raw-result summary. `validation.json`
records the completed validation and preserved release gate.
