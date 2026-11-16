# Native x86-64 matched results

Swift 6.4.2 on the retained swift-dev x86-64 Linux LXC environment; this is not bare-metal evidence. B and C use identical CLI sources and remote dependency pins, with separate local upstream snapshots. The upstream candidate changes coalescing buffer construction and adds focused tests.

Every case has one excluded B/C warmup and six alternating B/C and C/B measured pairs. Tables show medians and full paired min/max spread. Negative changes favor candidate. Paired-ratio medians are not ratios of the displayed absolute medians. JSON preserves every original numeric scalar and type without rounding. Split-family elapsed time sums child durations; split peak RSS takes the larger child maximum. Linux ru_maxrss is converted from KiB to bytes, then displayed as MiB.

The full test matrix contains 1,488 test executions: baseline upstream 298 and candidate upstream 302, plus 72 CLI tests for each, in Debug and Release. Ordinary release benchmark binaries were copied before tests and independently hash-bound to generated-code evidence. The temporary test memory scope was 6 GiB with swap disabled; timings run outside that scope.

## Primary matrix

132 measured samples; 22 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/ipv4-disjoint | 802.820 | 786.341 | -1.95 [-6.53, +1.44] | 43.445 | 43.449 | +0.00 [-0.42, +0.76] |
| split/ipv6-disjoint | 1683.632 | 1687.718 | -0.31 [-1.66, +5.17] | 112.154 | 112.082 | -0.09 [-0.17, +0.07] |
| split/mixed-disjoint | 1246.569 | 1231.278 | -0.62 [-2.20, -0.47] | 66.393 | 66.385 | -0.03 [-0.31, +0.38] |
| split/mixed-permuted | 1671.119 | 1672.664 | -0.15 [-2.83, +2.49] | 73.783 | 73.777 | +0.05 [-0.13, +0.25] |
| split/mixed-overlap | 1333.382 | 1355.488 | +1.59 [-1.18, +4.05] | 58.520 | 58.473 | -0.11 [-0.24, +0.07] |
| split/mixed-adjacent | 967.120 | 966.134 | -0.10 [-2.86, +2.31] | 51.182 | 51.090 | -0.15 [-0.59, +0.09] |
| split/bgp-like-ipv4 | 1169.763 | 1165.924 | -0.44 [-2.47, +4.50] | 40.967 | 39.432 | -3.75 [-4.00, -3.13] |
| split/range-derived-mixed | 1296.066 | 1295.106 | +0.48 [-2.31, +5.43] | 66.262 | 73.934 | +11.56 [+11.44, +11.93] |
| native/mixed-disjoint | 1271.130 | 1271.279 | -0.21 [-2.85, +5.21] | 77.822 | 77.799 | -0.06 [-0.18, +0.10] |
| native/mixed-permuted | 1728.745 | 1697.915 | -1.36 [-3.07, +0.50] | 85.238 | 81.562 | -4.34 [-4.72, -4.21] |
| native/mixed-overlap | 1380.619 | 1393.157 | +0.98 [-2.07, +3.57] | 68.078 | 66.266 | -2.67 [-2.92, -2.34] |

## Supplementary scale matrix

144 measured samples; 24 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 21.679 | 21.947 | +1.98 [-3.49, +3.36] | 21.344 | 21.336 | +0.00 [-0.07, +0.00] |
| mixed-disjoint-10000 | 33.140 | 33.078 | +0.39 [-1.07, +2.73] | 21.625 | 21.430 | -0.76 [-1.10, -0.04] |
| mixed-disjoint-100000 | 145.928 | 148.392 | +0.43 [-2.29, +6.58] | 26.605 | 26.537 | -0.43 [-1.19, +0.58] |
| mixed-permuted-1000 | 22.147 | 22.090 | +0.61 [-2.38, +3.00] | 21.330 | 21.299 | -0.04 [-0.33, +0.00] |
| mixed-permuted-10000 | 36.521 | 36.032 | -0.04 [-4.43, +4.25] | 21.629 | 21.408 | -1.17 [-1.61, +0.25] |
| mixed-permuted-100000 | 180.111 | 180.478 | +0.16 [-6.24, +1.28] | 27.195 | 26.742 | -1.57 [-2.76, -1.21] |
| mixed-overlap-1000 | 21.325 | 21.553 | +2.01 [-3.03, +2.82] | 21.291 | 21.289 | +0.00 [-0.07, +0.06] |
| mixed-overlap-10000 | 31.385 | 31.866 | +0.30 [-2.26, +6.42] | 21.348 | 21.363 | +0.07 [-0.66, +0.50] |
| mixed-overlap-100000 | 146.891 | 147.574 | +0.94 [-1.46, +3.38] | 25.348 | 25.311 | -0.21 [-1.36, +1.29] |
| mixed-adjacent-1000 | 21.282 | 21.232 | +0.20 [-2.59, +1.59] | 21.344 | 21.320 | +0.00 [-0.57, +0.35] |
| mixed-adjacent-10000 | 29.526 | 29.848 | +0.82 [+0.12, +1.44] | 21.355 | 21.422 | +0.34 [-0.40, +1.07] |
| mixed-adjacent-100000 | 118.176 | 119.571 | +2.20 [-2.53, +3.33] | 24.568 | 24.562 | -0.18 [-0.52, +0.96] |

## Separate follow-up: followups/regressions-primary-01

36 measured samples; 6 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| native/mixed-disjoint | 1282.542 | 1266.089 | -0.46 [-5.86, +2.20] | 77.824 | 77.789 | +0.02 [-0.23, +0.15] |
| split/ipv6-disjoint | 1669.960 | 1688.936 | -0.16 [-0.67, +4.22] | 112.107 | 112.150 | +0.03 [-0.14, +0.21] |
| split/range-derived-mixed | 1307.086 | 1316.166 | +1.08 [-3.84, +5.41] | 66.273 | 73.854 | +11.54 [+11.08, +11.60] |

## Separate follow-up: followups/regressions-scale-01/measurements

24 measured samples; 4 excluded warmups. This set is retained separately.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-100000 | 145.048 | 144.928 | -0.20 [-3.94, +1.96] | 26.512 | 26.516 | +0.10 [-0.92, +0.88] |
| mixed-overlap-10000 | 32.533 | 32.993 | -0.21 [-1.54, +2.46] | 21.262 | 21.326 | +0.27 [-0.13, +0.74] |

## Interpretation and scope

After each original timed sample has finished, its complete stdout is rechecked against the independent reference and shared through an immutable task-local hardlink store. Every per-process stdout path and full byte sequence remains. Timed child invocations, resource capture and sample JSON are unchanged. Extra hashing, byte comparison and journaling occur between samples; this storage policy can affect later cache state and is part of the x86 measurement scope. Both variants use the same policy, and initial unique content is established by excluded warmups. No old cache or result directory was deleted.

The generated code removes the baseline separate result-array reserve/growth calls from the concrete CLI coalescers. Candidate completed-group and final writes still check uniqueness and can copy; comparator dispatch remains indirect through concrete supplied function pointers. Static code generation is not a dynamic allocation count. RSS includes the whole child process and does not identify retained result-buffer residence. The macOS retained-result probe must not be generalized into Linux memory evidence.

Original raw stdout, stderr, commands, test logs, frozen binaries, source snapshots and runtime library bytes remain preserved outside this compact export. All measured observations and failed attempts remain separate; no outlier has been silently removed.
