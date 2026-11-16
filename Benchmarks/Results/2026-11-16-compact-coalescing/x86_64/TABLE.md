# Native x86-64 matched results

Swift 6.4.2 on the retained swift-dev x86-64 Linux LXC environment; this is not bare-metal evidence. B and C use identical CLI sources and remote dependency pins, with separate local upstream snapshots. The upstream candidate changes coalescing buffer construction and adds focused tests.

Every case has one excluded B/C warmup and six alternating B/C and C/B measured pairs. Tables show medians and full paired min/max spread. Negative changes favor candidate. Paired-ratio medians are not ratios of the displayed absolute medians. JSON preserves every original numeric scalar and type without rounding. Split-family elapsed time sums child durations; split peak RSS takes the larger child maximum. Linux ru_maxrss is converted from KiB to bytes, then displayed as MiB.

The full test matrix contains 1,490 test executions: baseline upstream 298 and candidate upstream 303, plus 72 CLI tests for each, in Debug and Release. Ordinary release benchmark binaries were copied before tests and independently hash-bound to generated-code evidence. The temporary test memory scope was 6 GiB with swap disabled; timings run outside that scope.

## Primary matrix

132 measured samples; 22 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/ipv4-disjoint | 796.605 | 818.336 | +2.86 [-5.16, +9.61] | 43.414 | 43.516 | +0.16 [-0.02, +0.47] |
| split/ipv6-disjoint | 1685.986 | 1692.526 | +0.91 [-4.18, +3.33] | 112.223 | 112.123 | -0.01 [-0.21, +0.09] |
| split/mixed-disjoint | 1242.641 | 1279.573 | +2.98 [-0.90, +7.84] | 66.357 | 66.389 | -0.01 [-0.17, +0.25] |
| split/mixed-permuted | 1692.586 | 1689.214 | -0.48 [-1.87, +1.54] | 73.688 | 73.760 | +0.12 [-0.15, +0.28] |
| split/mixed-overlap | 1347.219 | 1348.166 | +0.16 [-0.89, +0.45] | 58.508 | 58.521 | +0.06 [-0.06, +0.29] |
| split/mixed-adjacent | 954.552 | 987.167 | +5.03 [-6.29, +5.54] | 51.148 | 51.127 | +0.08 [-0.34, +0.34] |
| split/bgp-like-ipv4 | 1150.209 | 1169.894 | +1.69 [-0.11, +3.48] | 40.984 | 39.389 | -3.88 [-4.05, -3.43] |
| split/range-derived-mixed | 1296.155 | 1320.031 | +1.03 [-0.20, +5.59] | 66.291 | 66.279 | +0.01 [-0.16, +0.18] |
| native/mixed-disjoint | 1280.474 | 1279.493 | +0.31 [-1.17, +1.43] | 77.799 | 77.793 | -0.01 [-0.32, +0.03] |
| native/mixed-permuted | 1698.616 | 1707.687 | +0.80 [-1.57, +4.07] | 85.279 | 81.525 | -4.50 [-4.57, -4.15] |
| native/mixed-overlap | 1374.746 | 1360.303 | -0.64 [-2.22, +1.40] | 68.113 | 66.354 | -2.73 [-2.91, -2.24] |

## Supplementary scale matrix

144 measured samples; 24 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 20.669 | 21.036 | +1.37 [-1.51, +3.33] | 21.205 | 21.146 | -0.23 [-0.72, +0.37] |
| mixed-disjoint-10000 | 32.256 | 32.197 | +0.63 [-3.13, +4.21] | 21.539 | 21.465 | -0.22 [-0.47, +0.17] |
| mixed-disjoint-100000 | 143.588 | 145.480 | +0.83 [-3.11, +7.40] | 26.459 | 26.459 | -0.24 [-0.62, +0.56] |
| mixed-permuted-1000 | 21.315 | 21.257 | +0.99 [-1.50, +3.84] | 21.178 | 21.211 | -0.05 [-0.53, +1.26] |
| mixed-permuted-10000 | 35.070 | 35.042 | -0.10 [-1.37, +1.12] | 21.566 | 21.377 | -0.83 [-1.39, +0.29] |
| mixed-permuted-100000 | 180.056 | 180.532 | +0.34 [-2.75, +1.57] | 27.232 | 26.748 | -1.48 [-2.51, -0.82] |
| mixed-overlap-1000 | 21.190 | 20.855 | -2.09 [-5.95, +3.42] | 21.273 | 21.168 | -0.55 [-1.76, +1.18] |
| mixed-overlap-10000 | 30.992 | 31.212 | +0.71 [-4.02, +3.14] | 21.199 | 21.361 | +0.98 [+0.18, +1.02] |
| mixed-overlap-100000 | 149.282 | 148.512 | +0.74 [-2.89, +3.96] | 25.344 | 24.922 | -1.65 [-1.96, -1.16] |
| mixed-adjacent-1000 | 20.655 | 20.419 | -0.17 [-3.14, +2.83] | 21.240 | 21.152 | -0.50 [-0.77, +0.39] |
| mixed-adjacent-10000 | 28.767 | 28.637 | -0.56 [-1.16, +2.07] | 21.252 | 21.307 | +0.30 [-0.33, +0.88] |
| mixed-adjacent-100000 | 113.834 | 114.842 | +1.29 [-2.17, +4.58] | 24.654 | 24.607 | +0.07 [-1.03, +0.57] |

## Supplementary sparse-duplicate matrix

24 measured samples; 4 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 32.159 | 32.838 | +2.77 [-6.19, +5.31] | 21.586 | 21.549 | -0.07 [-1.17, +0.93] |
| mixed-sparse-duplicate-1000000 | 1272.118 | 1301.249 | +2.38 [-0.55, +7.51] | 77.885 | 77.869 | -0.03 [-0.15, +0.18] |

## Separate follow-up: followups/regressions-primary-01

48 measured samples; 8 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/ipv4-disjoint | 797.269 | 804.971 | +1.61 [-8.34, +10.83] | 43.439 | 43.408 | -0.04 [-0.48, +0.15] |
| split/mixed-adjacent | 956.602 | 988.250 | +1.86 [-1.80, +5.35] | 51.141 | 51.162 | +0.03 [-0.24, +0.38] |
| split/mixed-disjoint | 1244.989 | 1240.236 | -0.41 [-5.76, +4.15] | 66.369 | 66.357 | -0.11 [-0.25, +0.22] |
| split/range-derived-mixed | 1293.201 | 1301.005 | +0.60 [-0.59, +2.71] | 66.258 | 66.242 | -0.04 [-0.27, +0.38] |

## Separate follow-up: followups/regressions-scale-01/measurements

12 measured samples; 2 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-100000 | 142.802 | 143.324 | +0.13 [-3.69, +1.64] | 26.566 | 26.473 | -0.33 [-1.21, +0.18] |

## Separate follow-up: followups/regressions-sparse-01/measurements

24 measured samples; 4 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 32.541 | 32.771 | +0.02 [-3.09, +1.28] | 21.592 | 21.609 | -0.12 [-0.59, +0.45] |
| mixed-sparse-duplicate-1000000 | 1279.165 | 1320.073 | +3.34 [+1.79, +6.82] | 77.848 | 77.893 | +0.04 [-0.14, +0.25] |

## Interpretation and scope

After each original timed sample has finished, its complete stdout is rechecked against the independent reference and shared through an immutable task-local hardlink store. Every per-process stdout path and full byte sequence remains. Timed child invocations, resource capture and sample JSON are unchanged. Extra hashing, byte comparison and journaling occur between samples; this storage policy can affect later cache state and is part of the x86 measurement scope. Both variants use the same policy, and initial unique content is established by excluded warmups. This output-storage procedure does not delete prior caches or results.

The concrete CLI coalescers compact completed groups into sorted storage. When the resulting count is unchanged, the candidate returns that sorted buffer. When the count shrinks, it reserves a distinct output buffer from resultCount, copies that many ranges and releases sorted storage. The baseline reserves from the original input count. Candidate completed-group and final writes still check uniqueness and can copy; comparator dispatch remains indirect through concrete supplied function pointers. Capacity rounding, sorting and input storage remain. Static code generation is not a dynamic allocation count; RSS covers the whole child process and does not identify retained result-buffer residence.

Original raw stdout, stderr, commands, test logs, frozen binaries, source snapshots and runtime library bytes remain preserved outside this compact export. All measured observations and failed attempts remain separate; no outlier has been silently removed.
