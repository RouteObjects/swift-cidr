# macOS Swift 6.4.2 threshold refresh — 2026-11-13

This maintenance update regenerates all 79 committed `CIDRBenchmarkTarget`
threshold snapshots for the measured macOS 27.2.1 / Xcode 27.2 / Apple Swift
6.4.2 environment. It is separate from the summarization implementation commit
`7b3ec99c2be80c0f273f2321eb202a5f76a6eabc` and does not change library code,
benchmark callbacks, fixtures, dependency pins, instrumentation or tolerances.

The native Benchmark 1.35.0 `thresholds update` operation read the preserved
candidate baseline from the completed Swift 6.4.2 experiment. Every generated
file is byte-identical to the earlier official native candidate p90 export.
The entire suite was refreshed: 17 parser, 29 formatter and 33 currency cases,
with eight metrics per file. No failing-case selection, maximum selection,
padding or mixing of follow-up repetitions was used.

Each snapshot stores an integer HDR histogram p90 for a timed batch in base
metric units; wall-clock values are nanoseconds. These values are not divided
by the operation count. All 79 wall-clock references changed: 25 decreased and
54 increased. All 553 allocation and ARC references are unchanged, including
the currency suite's zero counts.

Parser and formatter configurations retain three warmup batches, 1,000
operations per batch and a two-second maximum duration. Currency configurations
retain five warmup batches, 1,000,000 operations per batch and the same duration.
The configured wall-clock allowances remain 15% for parser/formatter and 20%
for currency; count allowances and zero-allocation/ARC requirements are unchanged.

One independent full-suite run then measured all 79 cases using the preserved
Swift 6.4.2 candidate executable and normal allocation/ARC instrumentation.
The native check against the regenerated snapshots exited **0: within
thresholds**, with no failed cases and no changed allocation/ARC metrics.
The verification run did not update the regenerated snapshots. Its wall-clock
p90 changes ranged from −8.69% to +10.59%; the largest increase was
`currency.ipAddressCoverage.v4.containsAddress`, based on 11 batch observations
and within its unchanged 20% policy. No additional run was selected to replace it.

The measurement environment was macOS 27.2.1 (26B131), ARM64, Xcode 27.2
(27B52), Apple Swift 6.4.2 (`swiftlang-6.4.2.1.9`, `clang-2100.4.1.1`), using
freshly built SwiftBuild Release executables and Benchmark 1.35.0. These
thresholds are a reference for this environment, not a hardware-independent
latency promise. Histogram quantization and workload-dependent sample counts
still apply.

The earlier historical-limit failures, original threshold hashes, matched
baseline/candidate comparisons, six formatter follow-up pairs, and Xcode
26.6/native Linux evidence remain preserved. This refresh does not relabel
those checks as passing or revise their measured results. CPU, NIO and opt-in
summarization benchmark targets are outside this 79-case threshold set.

`provenance.json` records old/new threshold hashes, source/pin/binary identities,
the native baseline and fresh verification hashes, configuration, and results.
The complete raw baselines, commands, logs and generated snapshots remain in
the local `macos-xcode27/threshold-refresh` evidence directory.
