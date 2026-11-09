# Constant-access optimization results — 2026-11-09

Implemented on `codex/constant-access-optimizations`, branched from local `main`
at `a7f661a313d2e9d97516aaeeb4fb0031a229fb02`.

## Changes

- Derive the mapped-IPv6 prefix byte count from the existing `StaticString`'s
  `utf8CodeUnitCount`, keeping both length properties as `static let`.
- Make `AF.V6.multicastAddressSpace` an `@inlinable` computed getter with the
  same `ff00::/8` construction. The IPv4 declaration is unchanged.
- Extend existing tests with zero and maximum mapped suffixes (including the
  22-byte output), plus the first/last IPv6 multicast addresses and the address
  immediately preceding the multicast block.

The package still declares Swift tools version 6.2 and uses no new language
features. No Swift 6.2 compiler was found locally. Compilation, tests, and
measurements below used Apple Swift 6.3.3; this does not constitute an actual
Swift 6.2 compiler verification.

## Correctness checks

Both debug and release runs passed **67 tests in 7 suites**:

```sh
./scripts/test.sh --disable-sandbox --disable-automatic-resolution \
  --filter 'IPMulticastTests|IPSummarizationTests|IPv6CompressionTests|CIDRUTF8FormattingTests|ConcreteCIDRFormattingTests|AnyIPTests|IPNetworkAddressesTests'
./scripts/test.sh --disable-sandbox --disable-automatic-resolution -c release \
  --filter 'IPMulticastTests|IPSummarizationTests|IPv6CompressionTests|CIDRUTF8FormattingTests|ConcreteCIDRFormattingTests|AnyIPTests|IPNetworkAddressesTests'
```

The SwiftPM sandbox flag was needed because nested `sandbox-exec` was unavailable
inside the task sandbox. Logs: `focused-debug.log` and `focused-release.log`.
`git diff --check` passed. Independent review found no actionable issues.

Default `swift format lint --strict` did not pass: the repository has no local
formatter configuration, and its existing style differs from the tool defaults.
The same four files at baseline produced 588 diagnostics; the modified files
produced 606. Both logs are retained. No repository-wide formatting was applied.

## Focused before/after measurements

Machine: Apple M1 Max, 64 GB. Compiler: Apple Swift 6.3.3. Deployment target:
`arm64-apple-macosx15.0`. Both source snapshots were compiled with `-O`,
whole-module optimization, and cross-module optimization. The separately
compiled probe prevents the timed runner from importing and hoisting its bodies.

Five repetitions alternated baseline/changed and changed/baseline order. Each
process warmed two batches and recorded seven timed batches. Inputs varied at
runtime. All independent semantic checks and cross-variant checksums passed.

| Workload | Median paired reduction in elapsed batch mean | Range across five paired repetitions |
| --- | ---: | ---: |
| Mapped formatting plus byte/length digest | 6.42% | 5.09–6.94% |
| IPv6 raw group validation | 52.71% | 51.27–53.00% |
| IPv6 raw range validation | 21.80% | 21.32–22.18% |
| IPv6 block read plus wrapper/checksum | 3.40% | 1.77–5.45% |

Each reduction is `1 - changed/baseline`, paired by repetition after taking the
median of that process's batch means. These are environment-specific observations,
not percentiles of individual operations or predictions of application-level
speedup. The formatting workload includes digest work; the block-read workload
includes wrapper overhead. The harness does not measure allocation counts or
cold first-use cost. Thermal and power conditions were not controlled.

Saved probe assembly confirms that baseline multicast wrappers retain
initialization checks and storage loads, while changed wrappers eliminate them.

The final source/test patch removes `CHANGE:` prefixes from the explanatory
comments added during implementation. This comment-only cleanup happened after
measurement; the measured production source hashes match after restoring those
two prefixes. The original `run-01` evidence and checksums are preserved.

## Evidence and reproduction

- `change.patch`: complete tracked source/test diff.
- `run-01/metadata.json`: toolchain, machine, exact commands, source/harness hashes.
- `run-01/source-diff.patch`: exact production diff measured.
- `run-01/raw-samples.json`: every measured batch and checksum.
- `run-01/summary.json`: paired ratios and per-repetition batch means.
- `run-01/baseline-probe.s`, `run-01/changed-probe.s`: optimized consumer assembly.
- `run-01/SHA256SUMS`: verified artifact checksums.
- `README.md`: harness methodology and fresh-output rerun instructions.

Existing benchmark results and committed threshold files were not modified.
