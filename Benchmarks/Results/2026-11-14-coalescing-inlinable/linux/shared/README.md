# Portable Swift 6.4.2 Linux matched validation

Copy these files into each platform root's `control/` directory. `common.ROOT` is the parent of that directory. The scripts do not use local Mac paths at execution time.

Required platform layout:

```
control/config.json
control/{common,build_tests,linux_runner,run_matched,prepare_benchmark}.py
control/{source-reference,reference,matched-protocol}.json
sources/{B,C}/{swift-cidr,cidrmerge}/
fixtures/<original case>/{input,ipv4,ipv6}.txt
build/{B,C}/{upstream,cli}/{repositories,checkouts}/  # offline dependency seeds
```

Configuration:

```json
{"swift":"/absolute/path/to/swift","jobs":4,"platform_label":"x86_64-linux"}
```

Run phases separately:

1. `python3 control/build_tests.py` builds both ordinary release CLI executables and copies them to immutable `bin/B` and `bin/C` before running full upstream/CLI Debug/Release tests on B and C. Logs and per-step receipts are retained. Source hashes and actual checkout revisions are checked. B has295 upstream tests, C has298; both have57 CLI tests:1414 test executions per platform.
2. Inspect actual CLI caller edges and specialized sorting in both binaries. Write `control/codegen-gate.json` with `passed: true`, `binary_sha256: {B: "...", C: "..."}`, and evidence references only after that review.
3. `python3 control/prepare_benchmark.py` verifies tests/codegen/source/fixtures/runtime and creates the immutable pre-benchmark freeze.
4. `python3 control/run_matched.py --validate-only` launches no measured processes.
5. `python3 control/run_matched.py` performs the single retained run. It refuses an existing `measurements/` directory.

Both binary variants inherit only a fresh benchmark environment: resolved Swift toolchain PATH and LD_LIBRARY_PATH, C locale, UTC, and a per-process temporary directory. The Swift runtime directory and libswiftCore hash are recorded. Builds record `ldd` results. No network credentials are needed by this harness.

The original eight split and three native cases use exact original byte/hash coverage references. There is one excluded warmup per configuration and six balanced BC/CB measured rounds with case rotation. This produces132 measured samples/192 processes, plus22 warmup samples/32 processes. Every stdout, stderr, sample record and per-child `.rusage.json` remains retained. No sample is retried or removed.

`perf_counter_ns` spans process launch through blocking `os.wait4` for that exact child. Linux `ru_maxrss` is in KiB and is multiplied by1024; CPU time is that child's `ru_utime + ru_stime`. This avoids aggregate `RUSAGE_CHILDREN` peaks. Output hashing and coverage checks happen after timing. Split elapsed time is summed, split RSS is the maximum; native cases use one mixed process. Paired-change summary formulas match the earlier macOS runner. Measurement mechanics differ from macOS BSD time, so interpret within-platform matched differences instead of cross-platform absolute rankings.

A180-second timeout kills only the newly created process group, reaps it, writes failure evidence, then stops the run. A3GiB free-space guard runs before each build and measured sample; no cleanup is performed automatically. Hash validation is repeated after the run. Input and existing result directories are never modified.

The source reference covers185 frozen Swift/Package.swift files from the Mac experiment. Package.resolved is instead validated by selected dependency revisions; B's upstream lock may be normalized to C's upstream lock to remove unused app pins, with that preparation recorded by the platform controller. No Swift source changes are allowed.
