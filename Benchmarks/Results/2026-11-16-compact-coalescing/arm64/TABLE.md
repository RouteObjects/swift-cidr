# ARM64 Linux compact-storage coalescing evidence

Primary paired elapsed medians span -2.02% to +1.28%; primary paired peak-RSS medians span -4.49% to +0.02%. The separate follow-ups below investigate every original case with an individual elapsed/RSS regression greater than 5%. Results from different pools or candidates are not combined. Small or mixed timing differences are inconclusive.

B is frozen main. C compacts the sorted range buffer, returns it when count is unchanged, and copies merged output into freshly reserved storage otherwise. Only upstream coalescing and focused tests differ. Both experiment-only CLI manifests use the same local swift-cidr substitution; canonical manifests remain unchanged. Upstream's five remote revisions and the CLI's seven remote revisions match B/C within each package. Ordinary release binaries were frozen before tests. Previous experiment results remain untouched.

## Correctness and platform

Native OrbStack ARM64, Swift 6.4.2; the preflight records preserve OS/kernel/image identity, ten allowed logical CPUs, and runtime details. Twenty resolved linked runtime libraries were hashed before measurement and verified afterward. Mac and ARM64 measurements were scheduled separately without task-owned builds, tests or profiling.

B passed 298 upstream tests in Debug and Release; C passed 303 in each. Both CLI variants passed 72 tests per configuration: **1,490 main test executions**. Candidate Swift 6.2.4 upstream and CLI Debug/Release suites passed **750 additional executions** (303+72 per configuration). The exact differential gate passed all 77 cases / 154 processes, preserving exit status, output and diagnostics, statistics, raw/JSON/checksum behavior, and invalid-input boundaries.

Static inspection binds the ordinary CLI's actual V4/V6 call targets and concrete sorting pointers to the frozen binary hashes. C retains uniqueness checks and conditional copies during indexed compaction. On collapse it reserves resultCount, copies the typed prefix, and releases sorted storage; unchanged count returns sorted storage directly. Copy-loop capacity checks and growth fallbacks remain. This is neither an allocation-count measurement nor a zero-allocation claim.

## Primary matrix

Six alternating BC/CB pairs with rotating case order, one excluded warmup per configuration: **132 measured samples / 192 children**, plus **22 warmups / 32 children**. Complete output bytes match preserved independent coverage references. Linux elapsed covers launch and blocking wait4; CPU/RSS belong to the exact child. Split elapsed/CPU sum the family processes; split RSS takes their maximum. Negative changes favor C. Displayed spreads are minimum/maximum individual paired changes, not confidence intervals.

| Suite / case | B time s | C time s | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split / ipv4-disjoint | 0.337 | 0.333 | -1.23 [-6.63, +9.31] | 42.23 | 42.23 | +0.01 [-0.02, +0.05] |
| split / ipv6-disjoint | 0.536 | 0.538 | -0.43 [-3.30, +1.70] | 110.90 | 110.89 | -0.01 [-0.07, +0.01] |
| split / mixed-disjoint | 0.437 | 0.431 | -1.46 [-11.92, +0.13] | 65.17 | 65.18 | +0.01 [-0.02, +0.13] |
| split / mixed-permuted | 0.533 | 0.535 | -0.30 [-8.49, +1.65] | 72.55 | 72.56 | +0.02 [+0.01, +0.10] |
| split / mixed-overlap | 0.402 | 0.396 | -2.02 [-5.50, +0.99] | 57.29 | 57.29 | -0.01 [-0.10, +0.07] |
| split / mixed-adjacent | 0.324 | 0.320 | -1.38 [-3.54, +5.39] | 49.91 | 49.91 | +0.02 [-0.15, +0.12] |
| split / bgp-like-ipv4 | 0.425 | 0.421 | -0.24 [-2.71, +20.09] | 39.74 | 38.22 | -3.82 [-3.94, -3.76] |
| split / range-derived-mixed | 0.451 | 0.450 | +1.28 [-29.35, +10.77] | 65.05 | 65.03 | -0.02 [-0.14, +0.07] |
| native / mixed-disjoint | 0.436 | 0.438 | +0.70 [-13.55, +3.66] | 76.59 | 76.60 | +0.01 [-0.07, +0.06] |
| native / mixed-permuted | 0.549 | 0.535 | -1.17 [-3.65, +6.49] | 84.09 | 80.33 | -4.49 [-4.52, -4.41] |
| native / mixed-overlap | 0.398 | 0.404 | +0.61 [-0.39, +5.91] | 66.95 | 65.07 | -2.79 [-2.81, -2.77] |

## Separate scale matrix

Mixed disjoint, shuffled, overlapping and adjacent inputs at 1,000, 10,000 and 100,000 entries; **144 measured samples and 24 warmups**. Independent Python ipaddress references verify output. Shuffled inputs are prefixes of the original million-entry permutation, so they differ in address set/text lengths from equal-sized ordered prefixes; only within-fixture B/C comparisons isolate the candidate change. Short CLI timings include startup and scheduling variation.

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 1,000 | 6.319 | 6.075 | +0.98 [-13.24, +8.71] | 19.84 | 19.79 | -0.02 [-0.67, +0.10] |
| mixed-disjoint-10000 | 10,000 | 10.278 | 10.162 | +0.96 [-4.48, +57.30] | 20.26 | 20.04 | -1.07 [-1.63, -0.95] |
| mixed-disjoint-100000 | 100,000 | 50.561 | 50.628 | +2.06 [-8.36, +8.74] | 25.31 | 25.26 | -0.24 [-0.52, -0.19] |
| mixed-permuted-1000 | 1,000 | 6.268 | 5.882 | -4.47 [-16.52, +5.08] | 19.79 | 19.79 | +0.00 [-0.02, +0.67] |
| mixed-permuted-10000 | 10,000 | 10.544 | 10.381 | -2.52 [-24.48, +2.34] | 20.24 | 20.05 | -0.97 [-1.21, -0.95] |
| mixed-permuted-100000 | 100,000 | 57.687 | 56.942 | -2.30 [-5.83, +3.64] | 26.01 | 25.72 | -1.10 [-1.30, -0.99] |
| mixed-overlap-1000 | 1,000 | 6.274 | 5.913 | -7.25 [-13.15, +0.79] | 19.79 | 19.86 | +0.31 [-0.59, +0.73] |
| mixed-overlap-10000 | 10,000 | 9.833 | 9.938 | +5.48 [-11.95, +38.09] | 19.89 | 20.02 | +0.67 [+0.51, +1.14] |
| mixed-overlap-100000 | 100,000 | 43.682 | 43.515 | -0.27 [-2.52, +2.31] | 24.12 | 23.74 | -1.63 [-1.83, -1.23] |
| mixed-adjacent-1000 | 1,000 | 5.842 | 5.933 | +3.33 [-15.26, +8.32] | 19.79 | 19.79 | -0.01 [-0.08, +0.63] |
| mixed-adjacent-10000 | 10,000 | 8.547 | 8.733 | -2.19 [-13.12, +6.37] | 19.90 | 20.02 | +0.61 [-0.08, +1.26] |
| mixed-adjacent-100000 | 100,000 | 38.111 | 36.244 | -4.67 [-6.93, -2.02] | 23.36 | 23.37 | +0.04 [-0.28, +0.38] |

## Separate sparse-merge matrix

The ordered mixed-disjoint inputs receive exactly one duplicate per family: 10,002 inputs produce 10,000 outputs, and 1,000,002 inputs produce 1,000,000 outputs. Independently verified output bytes equal the corresponding disjoint coverage. These cases specifically expose near-full compact-copy cost. **24 measured samples and 4 warmups**, retained separately.

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 10,002 | 10.430 | 10.328 | -2.21 [-7.05, +7.41] | 20.24 | 20.25 | +0.07 [-0.06, +0.60] |
| mixed-sparse-duplicate-1000000 | 1,000,002 | 450.202 | 452.665 | -0.39 [-8.86, +10.27] | 76.61 | 76.64 | +0.03 [-0.07, +0.09] |

## Fixed follow-ups

Selection uses any individual original elapsed or RSS pair above +5%. Each selected case receives one separate six-pair follow-up with excluded warmups. No outliers are removed, no pools are combined, and follow-ups are not recursively rerun to chase noisy observations.


### Primary follow-up

**72 measured samples and 12 excluded warmups.**

| Suite / case | B time s | C time s | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| native / mixed-overlap | 0.412 | 0.399 | -2.57 [-8.26, +2.60] | 66.95 | 65.08 | -2.78 [-2.84, -2.71] |
| native / mixed-permuted | 0.540 | 0.545 | +1.38 [-8.33, +4.69] | 84.07 | 80.32 | -4.47 [-4.49, -4.42] |
| split / bgp-like-ipv4 | 0.421 | 0.421 | -0.04 [-7.32, +15.53] | 39.73 | 38.24 | -3.77 [-3.91, -3.61] |
| split / ipv4-disjoint | 0.334 | 0.334 | -0.37 [-0.56, +1.04] | 42.23 | 42.24 | +0.03 [+0.00, +0.15] |
| split / mixed-adjacent | 0.322 | 0.322 | -0.53 [-14.32, +9.91] | 49.91 | 49.91 | -0.02 [-0.02, +0.08] |
| split / range-derived-mixed | 0.449 | 0.451 | -0.38 [-0.94, +4.33] | 65.05 | 65.04 | -0.02 [-0.13, +0.01] |

### Scale follow-up

**84 measured samples and 14 excluded warmups.**

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 1,000 | 6.599 | 6.472 | -0.40 [-20.11, +4.11] | 19.79 | 19.79 | +0.00 [-0.12, +0.08] |
| mixed-disjoint-10000 | 10,000 | 10.562 | 10.768 | -1.87 [-5.82, +10.18] | 20.24 | 20.05 | -0.94 [-1.10, -0.60] |
| mixed-disjoint-100000 | 100,000 | 50.221 | 49.278 | -2.54 [-8.52, +1.07] | 25.34 | 25.25 | -0.35 [-0.51, -0.14] |
| mixed-permuted-1000 | 1,000 | 6.257 | 6.183 | +0.63 [-6.18, +13.73] | 19.79 | 19.79 | +0.01 [-0.65, +0.63] |
| mixed-overlap-10000 | 10,000 | 9.475 | 9.769 | +3.28 [-7.05, +10.88] | 19.90 | 20.02 | +0.59 [+0.02, +1.30] |
| mixed-adjacent-1000 | 1,000 | 5.739 | 5.977 | +1.57 [-17.76, +6.78] | 19.80 | 19.79 | -0.05 [-0.57, +0.55] |
| mixed-adjacent-10000 | 10,000 | 8.673 | 8.728 | -1.93 [-3.83, +2.53] | 19.89 | 20.01 | +0.63 [+0.00, +1.40] |

### Sparse follow-up

**24 measured samples and 4 excluded warmups.**

| Case | Entries | B time ms | C time ms | Paired time change % [min, max] | B RSS MiB | C RSS MiB | Paired RSS change % [min, max] |
|---|---:|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 10,002 | 9.968 | 10.423 | +4.04 [-1.65, +8.07] | 20.25 | 20.25 | -0.01 [-0.06, +0.02] |
| mixed-sparse-duplicate-1000000 | 1,000,002 | 448.197 | 452.354 | +0.44 [-1.36, +52.86] | 76.59 | 76.63 | +0.04 [-0.06, +0.16] |

## Evidence integrity and limits

Independent auditors verify raw-output inventories and independent-reference hashes, schedules, exact-child resource conversions, frozen inputs/runtime, and recomputed comparisons for every measurement pool. Original observations and failures remain preserved. JSON values retain their original numeric spellings; TABLE.md rounds only display values. EXPORT_MANIFEST.json records original and exported byte counts/hashes. Portable export changes path text only; raw outputs, full logs, scripts, binaries and source snapshots remain in the complete Downloads experiment.

These are synthetic CLI workloads on the listed compiler/platform. They do not establish general carrier deployment qualification, a zero-allocation implementation, or behavior under repeated-load memory pressure. Separate retention probes identify result-lifetime mechanisms and must not be substituted for timed CLI measurements.

Reproduce into fresh directories: seed frozen remote repositories, run freeze_sources.py and phase_runner.py build-tests; capture/review ordinary release code generation; run phase_runner.py correctness-freeze; start phase_runner.py benchmark only with the host clear. Run scale_bench.py separately with the scale and sparse fixture trees, then run the fixed follow-up selectors. Preserve every output/failure and never retry inside an existing measurement directory.
