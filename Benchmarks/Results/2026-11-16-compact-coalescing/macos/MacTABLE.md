# macOS matched results

Primary six-pair directions: 1 cases improve in every pair, 0 regress in every pair, and 10 span both directions. This directional count is descriptive; effect size, spread and independent follow-ups still govern repeatable-gain conclusions.

All 6 sets retain 504 measured samples and 84 excluded warmups, comprising 672 timed child outputs. Each case has one excluded B/C warmup and six alternating pairs with rotating case order. Split-family elapsed time sums the two processes; split peak RSS takes their maximum. Negative percentage changes favor C. Percentages are medians of paired ratios, not ratios of displayed group medians. Tables round for display; JSON retains the original numbers and numeric types.

Apple Swift 6.4.2, macOS 27.2.1 (26B131), Apple M1 Max. B uses upstream baseline 5e4b3d2; C uses conditional compact result storage after in-place coalescing. CLI source is identical at 8bba762; experimental manifests use local upstream snapshots and the same seven remote dependency pins. No candidate or observation from the earlier unconditional in-place experiment is pooled here.

## Primary million-entry matrix

132 measured samples, 22 excluded warmups and 224 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/ipv4-disjoint | 243.813 | 244.001 | +0.18 [-9.76, +2.32] | 56.273 | 56.227 | -0.08 [-0.69, -0.06] |
| split/ipv6-disjoint | 466.010 | 460.838 | -0.97 [-7.82, -0.63] | 146.859 | 146.828 | -0.02 [-0.12, +0.01] |
| split/mixed-disjoint | 367.634 | 365.630 | -0.78 [-15.79, +0.52] | 77.047 | 77.000 | -0.06 [-0.16, -0.02] |
| split/mixed-permuted | 473.230 | 462.114 | +0.78 [-9.06, +5.59] | 77.031 | 77.031 | -0.02 [-0.06, +0.31] |
| split/mixed-overlap | 361.352 | 358.747 | -0.69 [-1.32, +4.20] | 61.828 | 61.750 | -0.13 [-0.18, -0.05] |
| split/mixed-adjacent | 282.217 | 282.599 | +0.36 [-1.93, +1.90] | 61.797 | 61.719 | -0.13 [-0.63, -0.08] |
| split/bgp-like-ipv4 | 364.420 | 363.480 | -0.14 [-1.17, +0.88] | 35.984 | 36.711 | +1.93 [-4.21, +6.03] |
| split/range-derived-mixed | 374.952 | 371.863 | -0.91 [-2.14, +2.07] | 84.750 | 61.742 | -27.15 [-27.18, -27.12] |
| native/mixed-disjoint | 360.456 | 363.741 | +0.76 [-1.14, +29.38] | 102.938 | 102.219 | -0.52 [-1.82, +1.31] |
| native/mixed-permuted | 454.250 | 454.001 | +0.38 [-0.92, +6.56] | 103.359 | 103.211 | -0.13 [-0.62, +0.33] |
| native/mixed-overlap | 354.122 | 353.299 | +0.20 [-1.09, +2.01] | 66.898 | 66.656 | -1.08 [-1.66, +3.19] |

## Separate primary follow-up

48 measured samples, 8 excluded warmups and 70 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/mixed-permuted | 460.811 | 468.538 | -0.06 [-1.62, +10.58] | 77.039 | 77.008 | -0.05 [-0.06, -0.02] |
| split/bgp-like-ipv4 | 366.371 | 365.053 | -0.36 [-0.92, +15.88] | 35.977 | 35.016 | -2.11 [-4.26, +3.47] |
| native/mixed-disjoint | 364.834 | 363.393 | +0.00 [-14.27, +22.46] | 102.781 | 103.039 | +0.72 [-0.29, +1.18] |
| native/mixed-permuted | 455.905 | 456.494 | +0.30 [-7.37, +1.72] | 102.609 | 103.281 | +0.73 [-1.08, +1.40] |

## Supplementary scale matrix

144 measured samples, 24 excluded warmups and 168 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 13.671 | 13.851 | +1.49 [-9.01, +9.78] | 7.047 | 6.992 | -0.99 [-1.33, -0.22] |
| mixed-disjoint-10000 | 16.032 | 16.842 | +0.35 [-11.55, +12.61] | 7.938 | 7.797 | -0.30 [-2.15, +0.59] |
| mixed-disjoint-100000 | 47.064 | 47.602 | +0.88 [-2.95, +6.65] | 16.930 | 16.922 | -0.05 [-5.00, +14.87] |
| mixed-permuted-1000 | 13.139 | 13.050 | +0.86 [-11.95, +7.47] | 7.078 | 7.000 | -0.99 [-1.55, -0.44] |
| mixed-permuted-10000 | 17.101 | 16.795 | -2.12 [-11.78, +6.56] | 7.867 | 7.961 | +0.69 [-2.54, +3.01] |
| mixed-permuted-100000 | 55.950 | 55.055 | +0.79 [-9.79, +47.49] | 17.484 | 15.977 | -6.49 [-10.96, +3.74] |
| mixed-overlap-1000 | 13.558 | 13.582 | +0.57 [-11.89, +8.16] | 6.992 | 6.930 | -0.89 [-1.56, +0.00] |
| mixed-overlap-10000 | 16.023 | 16.641 | +4.98 [-2.95, +7.42] | 7.641 | 7.570 | -1.02 [-1.03, +0.82] |
| mixed-overlap-100000 | 45.868 | 45.195 | -0.75 [-3.92, +2.05] | 13.297 | 13.320 | +1.00 [-16.65, +9.79] |
| mixed-adjacent-1000 | 13.836 | 13.211 | -0.75 [-12.37, +33.25] | 7.016 | 6.953 | -0.89 [-1.33, +0.00] |
| mixed-adjacent-10000 | 15.936 | 16.279 | -0.43 [-9.79, +10.75] | 7.594 | 7.633 | -0.31 [-1.20, +1.86] |
| mixed-adjacent-100000 | 39.710 | 38.872 | -1.41 [-4.79, +6.93] | 13.297 | 12.914 | -1.57 [-12.76, +5.56] |

## Separate scale follow-up

144 measured samples, 24 excluded warmups and 168 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 13.423 | 13.315 | -1.79 [-13.68, +11.74] | 7.047 | 7.000 | -0.67 [-1.33, -0.22] |
| mixed-disjoint-10000 | 15.858 | 16.365 | +2.68 [-3.45, +6.67] | 7.797 | 7.820 | +0.30 [-1.77, +1.20] |
| mixed-disjoint-100000 | 47.719 | 47.608 | +0.10 [-2.10, +23.51] | 16.734 | 16.695 | +1.32 [-11.06, +15.19] |
| mixed-permuted-1000 | 13.821 | 13.658 | -0.90 [-16.23, +5.67] | 7.094 | 7.031 | -0.88 [-1.54, -0.66] |
| mixed-permuted-10000 | 17.383 | 17.501 | +0.32 [-5.37, +6.69] | 7.820 | 7.797 | +0.00 [-3.30, +2.61] |
| mixed-permuted-100000 | 55.446 | 55.667 | +0.61 [-1.55, +2.56] | 17.812 | 15.883 | -8.33 [-12.11, +3.36] |
| mixed-overlap-1000 | 13.089 | 13.034 | +1.80 [-5.60, +19.86] | 6.984 | 6.938 | -0.67 [-1.11, -0.45] |
| mixed-overlap-10000 | 16.514 | 15.489 | -4.01 [-15.39, +6.00] | 7.656 | 7.664 | -0.30 [-1.84, +1.02] |
| mixed-overlap-100000 | 45.418 | 45.256 | +0.20 [-2.30, +2.70] | 14.125 | 13.188 | -8.71 [-13.43, +4.18] |
| mixed-adjacent-1000 | 13.414 | 12.795 | -4.78 [-8.34, -1.60] | 7.008 | 6.945 | -0.89 [-1.34, -0.22] |
| mixed-adjacent-10000 | 15.530 | 15.371 | -1.02 [-13.94, +5.85] | 7.633 | 7.570 | -0.72 [-1.43, -0.21] |
| mixed-adjacent-100000 | 38.586 | 38.901 | +1.15 [-2.91, +6.80] | 13.625 | 12.914 | -5.32 [-14.11, +6.31] |

## Supplementary sparse-merge matrix

24 measured samples, 4 excluded warmups and 28 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 16.096 | 16.590 | -2.22 [-7.06, +12.34] | 7.797 | 7.773 | -0.30 [-2.35, +0.20] |
| mixed-sparse-duplicate-1000000 | 362.299 | 361.531 | -0.23 [-4.74, +0.62] | 102.523 | 102.352 | +0.02 [-1.15, +0.47] |

## Separate sparse-merge follow-up

12 measured samples, 2 excluded warmups and 14 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-sparse-duplicate-10000 | 15.766 | 15.628 | -0.07 [-4.07, +6.50] | 7.828 | 7.797 | -0.49 [-3.68, +2.21] |

## Correctness and mechanism

The independent audit verified 1,490 full-suite test executions and 77 differential CLI cases, every timed output/reference hash, native CPU/time/RSS, sample inventory, schedule, and every reported group/paired/spread scalar. Every initial individual elapsed/RSS regression above 5% received a separate fixed six-pair follow-up; follow-ups are not pooled or recursively rerun.

Sparse cases append one duplicate per family to the unchanged 10,000- and 1,000,000-entry mixed-disjoint corpora. Independent Python collapse produces the exact preserved original coverage bytes. This specifically exercises a nearly complete additional prefix copy after very little merging.

The ordinary CLI code-generation inspection confirms both concrete coalescing/sorting paths and the candidate's conditional fresh-array branch; it is separate from timed measurements. See retention/codegen/SUMMARY.md. The result-only retention probe uses one fresh process per variant/case; see retention/SUMMARY.md for exact count, capacity and address-linked live allocation evidence. Region-level dirty/resident totals include unrelated allocations when a compact Array shares a small-object region. These are mechanism observations, not repeated memory benchmarks or Linux retention evidence.

Two initial retention build attempts failed immediately because the sandbox could not write the existing dependency cache. Both failure receipts/logs are preserved. After a narrow cache permission grant, separate retry02 clients built and froze successfully; no failed build produced a measurement sample. No outlier or earlier benchmark observation was discarded.
