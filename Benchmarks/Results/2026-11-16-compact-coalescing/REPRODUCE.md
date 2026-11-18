# Reproduction and preserved evidence

The original experiment lives under `$HOME/Downloads/cidrmerge-compact-coalescing-20261116T033826Z`. Start every rerun in a fresh directory. Do not overwrite this run or the previous `cidrmerge-inplace-coalescing-20261115T221013Z` experiment.

## Sources and dependencies

The baseline is cidrmerge main `8bba7629d7fc9c366ea47680ee6c38badd615092` with swift-cidr main `5e4b3d2f881340a6ced05742429f1bd680dfd1e0` (0.10.1). `control/before.json`, both `*-main.tar` files, the source freeze and `control/prior-evidence-binding.json` preserve the baseline and prior prototype. Apply `full.patch` only to candidate C; its repository-relative headers pass `git apply --check` against the frozen baseline. Canonical dependency manifests remain unchanged.

Both experiment-only CLI manifests use `.package(path: "../swift-cidr")`, with the same seven other locked revisions. The original upstream package retains its five pinned dependencies. Test baseline and candidate independently with their respective package graphs. Do not substitute fresh dependency resolutions. The previous candidate is historical context; the new measurements compare B and C within this experiment and are not pooled with old observations.

## macOS

Use the recorded Xcode 27.2 / Apple Swift 6.4.2 environment. Prepare fresh build/cache/config/security/log/bin directories; cloned bare dependency caches may seed resolution, but builds are fresh. Native timing must have access to `/usr/bin/time` resource information.

```sh
python3 control/mac_prepare.py sources
python3 control/mac_remaining.py
python3 control/mac_prepare.py inputs
python3 control/mac_correctness.py
python3 control/mac_prepare.py benchmark
python3 macos/control/run_matched.py --validate-only
# Only after all local/OrbStack builds, tests and profiling are idle:
python3 control/orchestrate_macos_timing.py
```

The build driver first freezes both ordinary release CLI binaries, then runs all eight Debug/Release package suites. The correctness gate verifies 298 baseline upstream tests, 303 candidate upstream tests and 72 CLI tests per configuration, plus 77 differential cases. Ordinary binaries remain separate from test products and inspection copies.

The timing driver runs primary, scale and sparse matrices separately. It selects every case with any individual elapsed-time or peak-RSS increase above 5% for one fixed six-pair follow-up with excluded warmups. Follow-ups remain separate; the driver never removes outliers or recursively retries noisy observations. Failure requires a new output directory and retained failure evidence.

## Native Linux

Use new native ARM64 OrbStack containers or the native x86-64 swift-dev host. Platform controls preserve actual image/toolchain identities, mount paths, CPU allocation, build commands and runtime library hashes. Recheck them before reproducing. ARM64 uses cached images with networking disabled and independent cloned dependency caches. swift-dev uses a fresh task-specific build/cache area and bounded user build scope. No global machine settings are changed.

`shared/build_tests.py` freezes ordinary CLI binaries before running the full matrix. Source/pin checks, generated-code inspection, differential parity and linked-runtime freezing precede timing. ARM64 also runs the candidate's four Swift 6.2.4 compatibility suites; these are not floor-toolchain performance measurements.

The x86 runner retains every stdout path and complete output bytes using a task-owned immutable hardlink store after each timed sample finishes and its receipt is written. Hashing, byte comparison and journaling happen between samples. This storage policy is part of the disclosed measurement conditions and matches the previous x86 experiment. Do not replace original timing functions or discard any observations when adapting paths.

For ARM64, after preparing fresh containers/mounts from the recorded setup, the actual phase sequence is:

```sh
# Inside the Swift 6.4.2 container, with the new experiment mounted at /validation:
/validation/python/bin/python3.12 /validation/control/freeze_sources.py
/validation/python/bin/python3.12 /validation/control/phase_runner.py build-tests
# Inside the separate Swift 6.2.4 container:
/validation/python/bin/python3.12 /validation/floor-6.2.4/control/run_floor.py
```

Capture the ARM64 ELF code on the Mac host using its LLVM tools, then review the new capture. The saved review script includes addresses specific to the frozen binaries; inspect and refresh those assertions when rebuilding instead of copying old addresses into a new pass receipt.

```sh
# CIDR_EXPERIMENT names your fresh Downloads experiment directory.
python3 "$CIDR_EXPERIMENT/arm64/control/capture_codegen.py"
python3 "$CIDR_EXPERIMENT/arm64/control/review_codegen.py"
# Back inside Swift 6.4.2, after the codegen gate and all full tests pass:
/validation/python/bin/python3.12 /validation/control/phase_runner.py correctness-freeze
# Run only when the Mac/OrbStack measurement slot is clear:
/validation/python/bin/python3.12 /validation/run_timing.py
```

`run_timing.py` runs the primary phase, separate scale/sparse runners, and their fixed follow-up selectors sequentially. The `*-launched.json` and `*-run.json` receipts preserve every expanded command. For swift-dev, `control/launch_phase.py` is the host launcher for `build-tests`, `correctness-freeze` and `benchmark`; its new socket/root/unit settings must match the fresh setup. The benchmark phase uses `phase_runner_dedup.py`, while supplementary runs use `scale_bench_dedup.py`. Their actual launch receipts and source files are preserved; retain the measured-function identity, post-sample storage policy and fresh output paths when adapting them.

## Matrices and validation

Every case has one excluded warmup per variant and six alternating B/C and C/B pairs, with rotating case order. Keep at least 3 GiB persistent space free throughout measurements. Use `cidrmerge --raw --representation cidr` with the frozen fixture files and verify complete output bytes against the independent references.

- Primary: eight original split-family cases plus three native mixed cases; 132 measured samples and 22 warmups per platform. Split samples sum child elapsed/CPU time and use the larger child RSS.
- Scale: 12 cases at 1,000, 10,000 and 100,000 entries; 144 measurements and 24 warmups. Shuffled prefixes have different address sets/text lengths from equal-sized ordered prefixes; compare B/C within each fixture.
- Sparse merge: 10,000 and 1,000,000 original disjoint entries plus one duplicate per family; 24 measurements and four warmups. Python's independent collapse verifies that coverage is unchanged. These expose the policy's nearly full copy after very few merges.

Linux records exact-child `wait4` resource usage. macOS uses native time records. Keep Mac and OrbStack timing separate and exclude task-owned builds/tests/profiling during either. Preserve all new and historical result directories and thresholds.

## Allocation and result lifetime

The separate release-built retention client holds only a coalesced result after its input-building function returns. B/C overlap, adjacency, disjoint and sparse cases run in fresh processes outside timings. Ordinary and inspection executable sections must match. Record count, capacity, element pointer, matching allocation and containing VM region.

`reserveCapacity` permits allocator rounding; exact capacity equality is not a requirement. A tiny result can share a malloc region with unrelated objects, so the region's resident/dirty bytes cannot be attributed wholly to the result. Neither static code generation nor one instrumented retention observation establishes general steady-state memory or throughput.

## Evidence

Per-platform manifests bind selected original artifacts and portable copies by SHA-256 and size; numerical observations remain unrounded, with private home paths redacted. Full output, source snapshots, binaries, runtime identity/hash evidence, native captures and logs remain in Downloads. ARM64 runtime libraries remain in the recorded cached images and stopped experiment containers; macOS system-runtime identity is recorded by loaded UUID. The x86 evidence records its preserved runtime-library copies separately. Final audits recompute schedules, raw metrics, paired summaries, output references and preservation checks. The top-level report describes the actual outcome and limitations.

## Returning to the baseline implementation

The prototype is uncommitted. To return only the production function to current main, run this from the swift-cidr repository after reviewing the diff:

```sh
git restore --source=main -- Sources/CIDR/IPAddressRange.swift
```

Keep the new tests and report directories for review and preserve Downloads evidence. The previous bare in-place implementation and its tests also remain in the prior experiment's frozen `sources/C/swift-cidr` tree. No canonical cidrmerge dependency or production change needs reverting.
