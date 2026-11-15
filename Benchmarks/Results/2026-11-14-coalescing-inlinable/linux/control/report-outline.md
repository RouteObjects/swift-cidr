# Linux Swift 6.4.2 follow-up

This follow-up uses the frozen B/C sources from the completed macOS coalescing experiment. Production source and compiler/dependency requirements are unchanged. Both repositories remain on the uncommitted `perf/coalescing-inlinable` branch. Existing macOS evidence and the original report versions are preserved.

## Plan and patch

Run full baseline/candidate Debug/Release tests and the same eight split plus three native matched workloads on native ARM64 Linux and native x86-64 swift-dev. Verify actual CLI sorting calls before timing. The existing patch exposes the coalescing/helper/coverage chain and the package Core initializer; no additional production patch is part of this validation.

## Tests and generated code

Each platform runs baseline swift-cidr 295 tests and cidrmerge 57 tests in both configurations, plus candidate swift-cidr 298 tests and cidrmerge 57 tests in both configurations: 1,414 test executions per platform. The candidate's three additional tests cover arbitrary sequences, custom storage families and maximum endpoints.

On both Linux architectures, actual caller instructions show baseline CLI construction reaching generic coalescing and external Sequence.sorted, while the candidate directly reaches V4/Array and V6/Array coalescing and concrete sorting. The inspected concrete comparator bodies have no calls; fixed-layout insertion-sort access avoids generic read witnesses. Ordinary sorting/merge buffers remain. This is not an allocation-free sorting claim.

## Verification method

Both platforms use Swift 6.4.2 release toolchains and frozen non-test release binaries, copied before test builds can relink targets. Swift runtime paths and libswiftCore hashes are explicit, and ldd linkage is recorded. Source/manifest bytes match the macOS freeze. Baseline upstream Package.resolved was normalized to the candidate's upstream-only dependency graph; this only removes irrelevant app pins. All actual dependency revisions match the original locked versions and their tracked checkout contents are clean.

There are six measured BC/CB paired rounds and one excluded warmup per case: 132 measured samples / 192 child processes and 22 warmups / 32 processes per platform. Each corpus has one million entries before family splitting. Every output hash/byte count must match the original independently verified coverage output. Raw outputs, stderr, timing/usage records and all observations are retained. No sample is removed or retried.

Linux elapsed time surrounds process launch and wait. Peak RSS is obtained separately for each child with wait4, converting ru_maxrss KiB to bytes. For split inputs, elapsed times are summed and RSS is the maximum of the family processes. Native mixed cases run one process. Linux timing excludes the BSD time wrapper used on macOS; comparisons are baseline versus candidate within each platform, not pooled cross-platform scores. Profiling, builds, independent hashing and substantial transfers are outside each host's timed phase.

Peak-memory values are process RSS, not total allocated bytes or allocator-call counts. Percent changes are medians of six per-pair changes and may differ slightly from ratios of displayed median times. Six pairs are limited evidence for these exact fixtures, not broad production-tail latency qualification.

ARM64 runs natively under OrbStack in the pinned cached Swift 6.4.2 image, with networking disabled. swift-dev is native x86-64 on an Intel Xeon E5520 with four allowed logical CPUs; the explicit Swiftly 6.4.2 path avoids its empty noninteractive Swift PATH. Host/kernel/CPU/memory/disk/cgroup metadata are retained. A three-GiB disk guard applies before each build and benchmark sample. The dedicated ARM64 container is stopped after completion; prior containers/images and toolchains are unchanged.

## Notes and reproducibility

The complete new artifacts are under this Downloads directory, with independent platform directories. Frozen sources, commands, logs, config/runtime metadata, codegen captures and retained measurements permit reproduction in a new directory. The runners refuse to overwrite existing phases/results. The x86 remote copy lives under the same named Downloads directory on swift-dev.

These tests do not raise the Swift 6.2 floor previously checked by the prototype. No commit, release or dependency adoption is performed. Reverting the prototype still means reversing the existing source patches and preserving unrelated files, not resetting either repository wholesale. Broader release gates and non-benchmark deployment qualification remain separate.
