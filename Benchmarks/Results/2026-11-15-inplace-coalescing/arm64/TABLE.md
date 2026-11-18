# ARM64 Linux in-place coalescing evidence

Throughput changes are small on this matrix, and peak RSS has a repeatable regression on the range-derived corpus. Primary paired elapsed medians range from −0.16% to +2.16%. Most primary RSS differences are near zero; BGP-like IPv4, native mixed-permuted and native mixed-overlap improve in this run. Split range-derived-mixed RSS rises **11.73%**, then **11.74%** in its separate fixed follow-up; every RSS pair in both runs exceeds +5%. This candidate therefore has a material memory tradeoff and does not establish a general throughput improvement on ARM64 Linux.

B is frozen main; C differs by the in-place coalescing compaction plus its focused tests. Both isolated CLI manifests use the same local swift-cidr substitution. The canonical dependency files are unchanged. Upstream's five remote dependency pins and the CLI's seven remote pins are each matched B/C; the upstream and CLI lock sets are intentionally distinct. Both ordinary release executables were frozen before test builds. No candidate changes, discarded observations or workload retries occurred.

## Correctness and platform

Native OrbStack ARM64 Ubuntu 24.04.5, kernel `7.2.12-orbstack-00394-gbecdd6130068`, Swift 6.4.2; 10 allowed logical CPUs, no cgroup CPU quota. The cached image ID, runtime hashes, full host metadata and compiler output are in the exported control records. All 20 resolved linked runtime libraries were frozen before timing and rechecked afterward. Mac and OrbStack measurement phases ran separately; task-owned builds, tests and profiling were complete before timing.

B swift-cidr passed 298 Debug and 298 Release tests; C passed 302 and 302. Both CLI variants passed 72 Debug and 72 Release tests: **1,488 executions** in the main matrix. The candidate also passed all four Swift 6.2.4 configurations (302 upstream + 72 CLI in each configuration: **748 executions**). The 77-case exact differential gate passed (154 processes), preserving exit status, stdout/stderr, statistics, raw/JSON bytes, checksums, invalid-input and boundary behavior.

Static ELF inspection confirms that actual CLI calls reach V4/Array and V6/Array coalescing and concrete sorting in both binaries. C compacts the sorted storage and removes its suffix; uniqueness checks and conditional copy fallbacks remain at indexed writes. Sorting scratch, original input storage and retained array capacity remain. This is not an allocation-free claim. Generated-code evidence does not by itself prove the cause of every RSS or timing difference.

## Original million-entry matrix

Six alternating BC/CB pairs and one excluded warmup per configuration; rotating case order. **132 measured samples / 192 children**, plus **22 warmups / 32 children**. All full output bytes match the preserved independent coverage references. Linux elapsed surrounds process launch and blocking wait4; CPU and peak RSS belong to the exact child. Split elapsed/CPU sum the family processes and split peak RSS is their maximum. Medians below are within this platform; positive changes favor B, negative changes favor C. Spread is the minimum and maximum individual paired change, not a confidence interval.

| Suite / case | B time s | C time s | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split / ipv4-disjoint | 0.321 | 0.327 | +1.46 [-1.20, +2.69] | 42.22 | 42.23 | +0.00 [-0.30, +0.05] |
| split / ipv6-disjoint | 0.531 | 0.532 | -0.16 [-5.50, +3.86] | 110.90 | 110.91 | +0.01 [-0.02, +0.12] |
| split / mixed-disjoint | 0.426 | 0.427 | +0.26 [-0.25, +2.12] | 65.16 | 65.18 | +0.04 [-0.11, +0.13] |
| split / mixed-permuted | 0.517 | 0.524 | +1.60 [-1.50, +6.03] | 72.54 | 72.56 | +0.02 [-0.01, +0.10] |
| split / mixed-overlap | 0.384 | 0.393 | +2.16 [+0.46, +4.64] | 57.29 | 57.29 | +0.00 [-0.14, +0.11] |
| split / mixed-adjacent | 0.313 | 0.315 | +0.75 [-2.55, +3.12] | 49.91 | 49.91 | +0.01 [-0.03, +0.24] |
| split / bgp-like-ipv4 | 0.408 | 0.409 | +0.34 [-1.71, +1.89] | 39.73 | 38.24 | -3.76 [-3.92, -3.63] |
| split / range-derived-mixed | 0.438 | 0.438 | +0.95 [-6.68, +3.61] | 65.05 | 72.68 | +11.73 [+11.69, +11.80] |
| native / mixed-disjoint | 0.427 | 0.430 | +0.60 [-7.75, +2.67] | 76.61 | 76.59 | -0.04 [-0.10, +0.08] |
| native / mixed-permuted | 0.517 | 0.524 | +0.76 [-1.53, +4.03] | 84.07 | 80.35 | -4.44 [-4.51, -4.36] |
| native / mixed-overlap | 0.387 | 0.390 | +0.37 [-5.37, +7.84] | 66.95 | 65.07 | -2.87 [-2.91, -2.77] |

## Separate scale matrix

Mixed disjoint, permuted, overlapping and adjacent inputs at 1,000, 10,000 and 100,000 entries. Independent Python ipaddress outputs were frozen before measurement. **144 measured samples plus 24 excluded warmups**, separate from the million-entry matrix. Small process times are sensitive to launch and scheduling variation; classify small or changing differences as inconclusive.

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 1,000 | 4.848 | 5.223 | +2.22 [-7.32, +13.05] | 19.79 | 19.79 | -0.02 [-0.57, +0.67] |
| mixed-disjoint-10000 | 10,000 | 8.551 | 8.882 | +3.87 [+1.61, +5.14] | 20.25 | 20.05 | -0.97 [-1.10, -0.33] |
| mixed-disjoint-100000 | 100,000 | 47.012 | 46.513 | -0.42 [-2.36, +1.20] | 25.34 | 25.26 | -0.29 [-0.43, -0.08] |
| mixed-permuted-1000 | 1,000 | 5.254 | 5.364 | -1.67 [-12.20, +9.61] | 19.79 | 19.78 | -0.06 [-0.08, +0.02] |
| mixed-permuted-10000 | 10,000 | 8.987 | 9.296 | +2.91 [-4.51, +5.79] | 20.25 | 20.05 | -0.98 [-1.61, -0.91] |
| mixed-permuted-100000 | 100,000 | 54.477 | 54.670 | -0.82 [-4.66, +2.62] | 26.01 | 25.67 | -1.32 [-1.50, -1.02] |
| mixed-overlap-1000 | 1,000 | 5.048 | 5.033 | +3.61 [-9.35, +10.68] | 19.79 | 19.79 | -0.00 [-0.57, +0.04] |
| mixed-overlap-10000 | 10,000 | 7.728 | 7.857 | +0.22 [-9.56, +11.11] | 19.90 | 20.01 | +0.55 [-0.02, +1.26] |
| mixed-overlap-100000 | 100,000 | 40.836 | 41.059 | +3.35 [-5.39, +25.55] | 24.12 | 24.12 | +0.01 [-0.08, +0.34] |
| mixed-adjacent-1000 | 1,000 | 4.693 | 4.620 | -3.34 [-11.36, +5.70] | 19.80 | 19.79 | -0.07 [-0.59, +0.12] |
| mixed-adjacent-10000 | 10,000 | 7.222 | 7.294 | +0.62 [-4.28, +2.72] | 19.89 | 20.02 | +0.62 [+0.06, +1.28] |
| mixed-adjacent-100000 | 100,000 | 34.328 | 36.015 | +4.23 [-2.24, +7.76] | 23.36 | 23.37 | -0.01 [-0.12, +0.10] |

## Fixed follow-ups

The rule selects every original case with any individual elapsed or RSS pair above +5%. One new six-pair run plus excluded warmups was performed for each selected case. No results are pooled with the original observations, and this fixed investigation is not recursively rerun when another noisy pair appears.

The three primary cases add **36 measured samples / 60 children** and **6 warmups / 10 children**. The range-derived RSS regression repeats; elapsed changes in the other investigated primary cases remain small.

| Suite / case | B time s | C time s | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| native / mixed-overlap | 0.393 | 0.399 | +1.13 [-3.58, +6.61] | 66.97 | 65.07 | -2.83 [-2.91, -2.80] |
| split / mixed-permuted | 0.513 | 0.520 | +0.93 [+0.58, +1.89] | 72.54 | 72.54 | -0.00 [-0.10, +0.03] |
| split / range-derived-mixed | 0.430 | 0.434 | +0.58 [-4.61, +6.41] | 65.05 | 72.68 | +11.74 [+11.70, +11.91] |

Nine scale cases add **108 measured samples and 18 excluded warmups**. Some small-case time changes reverse direction or move materially between runs. The preserved per-pair values show the variability; these results do not support a general small-input speedup.

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 1,000 | 5.174 | 4.965 | +0.14 [-8.06, +8.47] | 19.80 | 19.79 | -0.08 [-0.75, +0.02] |
| mixed-disjoint-10000 | 10,000 | 8.816 | 8.899 | +3.14 [-6.44, +7.16] | 20.25 | 20.05 | -0.96 [-1.55, -0.48] |
| mixed-permuted-1000 | 1,000 | 4.747 | 5.193 | +3.43 [+0.50, +20.31] | 19.79 | 19.79 | +0.04 [-0.06, +0.51] |
| mixed-permuted-10000 | 10,000 | 9.868 | 9.746 | +0.22 [-3.71, +6.88] | 20.25 | 20.05 | -1.00 [-1.34, -0.64] |
| mixed-overlap-1000 | 1,000 | 4.959 | 5.223 | -0.09 [-5.98, +22.64] | 19.79 | 19.79 | +0.00 [-0.10, +0.53] |
| mixed-overlap-10000 | 10,000 | 8.461 | 7.982 | -0.94 [-7.94, +2.14] | 19.88 | 20.01 | +0.65 [+0.57, +0.71] |
| mixed-overlap-100000 | 100,000 | 41.578 | 41.285 | +0.65 [-4.58, +7.07] | 24.11 | 24.11 | +0.00 [-0.06, +0.26] |
| mixed-adjacent-1000 | 1,000 | 4.847 | 4.832 | +2.17 [-7.60, +26.40] | 19.79 | 19.79 | -0.02 [-0.63, +0.06] |
| mixed-adjacent-100000 | 100,000 | 33.617 | 34.319 | +2.95 [-8.04, +6.13] | 23.37 | 23.38 | +0.09 [-0.35, +0.30] |

## Evidence integrity and limits

Independent auditors passed for the primary, scale and both follow-up pools. They verified complete raw-output inventories, independent-reference hashes, schedules, per-child resource conversions, frozen inputs/runtime and recomputed summaries. The initial primary auditor stopped on a path-spelling assumption: the container resolves `/validation/sources` to `/sources`. Its failed receipt and original frozen auditor remain preserved. A new auditor canonicalizes the expected local path and passes; no source, binary, fixture, observation, metric formula or original frozen artifact changed.

All scalar values remain unrounded in JSON. TABLE.md rounds only its display values. Raw stdout/stderr, complete logs, binaries, source snapshots, scripts and unsuccessful audit evidence remain in Downloads. This selected portable export replaces local home/root paths with placeholders; EXPORT_MANIFEST.json binds each exported file to the original bytes and hash and records the exported hash. Full freeze manifests refer to additional artifacts retained in the complete evidence bundle.

These results cover the listed synthetic CLI inputs, compiler and native platform. They do not establish a general Unicode-input gain, cross-platform ranking, zero-allocation behavior or constant retained memory. The profile and retained-array observations reported elsewhere are separate mechanism evidence, not substitutes for these timings.

Reproduction uses fresh roots: copy the frozen sources and shared helpers, run `freeze_sources.py`, then `phase_runner.py build-tests`; inspect frozen binaries and write the binary-bound codegen gate; run exact differential/runtime freeze/prepare/validate steps; launch `phase_runner.py benchmark` only with the host clear. Run `scale_bench.py --root ROOT --fixtures ROOT/scale --output ROOT/scale-measurements` separately, then the fixed follow-up selector. Preserve every output and failure; never resume into an existing measurements directory.
