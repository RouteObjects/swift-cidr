# Matched CLI benchmark protocol

This run compares newly built Swift 6.4.2 baseline (`bin/B`) and candidate (`bin/C`)
executables on the eight original split corpora and three original native mixed
corpora. Fixtures are a read-only symlink to the preserved competitor run. Original
reference output bytes, hashes, coverage receipts, and frozen input files are
validated before and after the run; every new output must match the independently
verified original cidrmerge output exactly.

For each suite/corpus there is one excluded warmup per binary, followed by six
measured pairs. Each pair runs B then C on odd rounds and C then B on even rounds.
Case order rotates each round. This is 132 measured samples / 192 child CLI
processes and 22 excluded warmup samples / 32 child CLI processes. No concurrent
builds, tests, profiling, or heavy analysis should be running during measurement.

Elapsed time uses the existing monotonic `perf_counter_ns` wrapper around native
`/usr/bin/time -p -l`; raw BSD elapsed/user/sys data is also retained. A split
sample sums sequential IPv4 and IPv6 elapsed/CPU times and takes the larger peak
RSS, rather than adding nonconcurrent memory peaks. Peak RSS bytes are converted
to MiB with 1,048,576 bytes per MiB. Each child has a fresh minimal environment,
null stdin, redirected stdout/stderr, and the existing 180-second timeout.

Summaries report per-binary medians and min/max plus the median of the six paired
candidate/baseline percentage changes. The paired percentage is not the ratio of
the separate medians. Warmups are excluded; no measured observation is retried,
removed as an outlier, or pooled with older binaries. All raw timing files,
stderr, stdout, sample records, and failures remain in this new evidence folder.
A failed run stops and must be investigated; reruns require a fresh destination.

Before launch, populate `control/pre-benchmark-freeze.json` with a `files` map
including `bin/B`, `bin/C`, `control/run_matched.py`, `control/base_runner.py`,
`control/matched-protocol.json`, `control/reference-output-freeze.json`, and
`control/context.json`. Additional source/build manifests may be frozen too.
`python3 control/run_matched.py --validate-only` checks the inputs without running
benchmarks. `python3 control/run_matched.py` performs the controls once. Native
BSD timing requires the host access used by previous controls.
