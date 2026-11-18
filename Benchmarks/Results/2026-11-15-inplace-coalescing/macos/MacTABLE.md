# macOS matched results

The macOS matrix does not show a consistent general throughput improvement. Every primary workload's six paired elapsed changes spans both improvement and regression. Most primary RSS medians are close to baseline; the BGP-like IPv4 and range-derived mixed cases show approximately 4% and 9% lower peak RSS, respectively. Treat small or noisy timing changes as inconclusive.

The 10,000-entry disjoint scale case improves in all six original pairs (paired median -2.15%), but this isolated scale result does not establish a repeatable gain across the targeted main workloads. Separate follow-ups retain substantial small-input timing spread; they are not pooled with primary observations.

All four sets retain 396 measured samples and 66 excluded warmups, comprising 546 timed child outputs. Each case uses one excluded B/C warmup, then six alternating B/C and C/B pairs with rotating case order. Split-family elapsed time sums the family processes; split peak RSS takes their maximum. Negative percentage changes favor candidate. Percentages are medians of paired ratios, not ratios of the displayed medians. Tables round for display; exported JSON preserves all numeric values and types exactly.

Apple Swift 6.4.2, macOS 27.2.1 (26B131), Apple M1 Max. B uses upstream baseline 5e4b3d2; C changes only in-place compaction plus focused tests. CLI source is identical at 8bba762; both experimental manifests use local upstream snapshots with the same seven remote dependency pins.

## Primary million-entry matrix

132 measured samples and 22 excluded warmups; 224 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/ipv4-disjoint | 239.077 | 237.781 | +0.14 [-1.19, +2.68] | 56.133 | 56.203 | +0.14 [+0.00, +0.31] |
| split/ipv6-disjoint | 458.562 | 461.554 | -0.50 [-3.08, +1.64] | 146.750 | 146.797 | +0.03 [+0.00, +0.04] |
| split/mixed-disjoint | 354.998 | 357.872 | +0.12 [-8.64, +2.83] | 76.930 | 76.945 | +0.03 [-0.14, +0.96] |
| split/mixed-permuted | 448.565 | 452.703 | +0.65 [-0.78, +4.40] | 76.938 | 77.000 | +0.07 [-0.77, +0.14] |
| split/mixed-overlap | 352.533 | 349.043 | -1.25 [-8.67, +1.07] | 61.703 | 61.727 | +0.05 [-0.08, +0.13] |
| split/mixed-adjacent | 275.214 | 274.430 | +0.02 [-2.36, +5.24] | 61.609 | 61.727 | +0.19 [+0.00, +0.28] |
| split/bgp-like-ipv4 | 352.377 | 355.751 | +0.68 [-0.29, +1.75] | 35.852 | 34.414 | -4.05 [-4.71, -3.97] |
| split/range-derived-mixed | 366.037 | 361.213 | -0.70 [-2.51, +0.96] | 84.625 | 77.000 | -9.03 [-9.15, -8.87] |
| native/mixed-disjoint | 348.743 | 347.575 | -0.75 [-6.15, +6.79] | 101.750 | 101.789 | +0.01 [-2.24, +0.78] |
| native/mixed-permuted | 441.283 | 438.087 | -0.69 [-2.06, +1.11] | 101.750 | 101.781 | +0.05 [-1.50, +1.50] |
| native/mixed-overlap | 339.962 | 343.700 | +1.66 [-2.18, +3.69] | 65.578 | 65.594 | +0.05 [-0.14, +0.12] |

## Supplementary scale matrix

144 measured samples and 24 excluded warmups; 168 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 11.409 | 11.447 | -1.51 [-5.92, +8.58] | 6.977 | 6.984 | +0.00 [-0.67, +0.67] |
| mixed-disjoint-10000 | 13.631 | 13.372 | -2.15 [-7.39, -1.15] | 7.727 | 7.750 | +0.30 [-0.20, +0.81] |
| mixed-disjoint-100000 | 44.241 | 45.280 | +0.67 [-2.00, +3.12] | 15.258 | 15.242 | -0.10 [-13.49, +11.09] |
| mixed-permuted-1000 | 12.235 | 11.660 | -1.45 [-18.30, +19.53] | 7.008 | 7.008 | +0.11 [-0.44, +0.44] |
| mixed-permuted-10000 | 14.581 | 15.096 | +1.51 [-4.03, +12.05] | 7.711 | 7.734 | +0.41 [-0.20, +0.81] |
| mixed-permuted-100000 | 53.496 | 51.589 | -3.39 [-11.58, +4.20] | 15.289 | 15.711 | +2.86 [-3.14, +3.17] |
| mixed-overlap-1000 | 10.978 | 11.102 | -2.15 [-6.70, +9.32] | 6.922 | 6.945 | +0.34 [-0.45, +0.68] |
| mixed-overlap-10000 | 13.053 | 13.727 | +2.83 [-13.25, +7.05] | 7.578 | 7.594 | +0.31 [-0.41, +2.68] |
| mixed-overlap-100000 | 43.238 | 42.765 | -2.35 [-4.04, +8.71] | 12.750 | 12.992 | +2.31 [-2.94, +16.57] |
| mixed-adjacent-1000 | 11.425 | 11.615 | -0.99 [-41.27, +35.53] | 6.938 | 6.938 | +0.00 [-0.22, +0.45] |
| mixed-adjacent-10000 | 12.503 | 12.892 | +3.17 [-2.07, +4.77] | 7.500 | 7.531 | +0.42 [+0.21, +2.92] |
| mixed-adjacent-100000 | 36.300 | 35.879 | -1.32 [-2.85, +3.07] | 11.984 | 11.648 | -2.80 [-3.00, -2.47] |

## Separate primary follow-up

24 measured samples and 4 excluded warmups; 42 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| split/mixed-adjacent | 281.064 | 276.546 | -1.21 [-7.33, +2.68] | 61.727 | 61.695 | -0.04 [-0.48, +0.05] |
| native/mixed-disjoint | 350.911 | 353.896 | +0.49 [-0.01, +3.85] | 101.781 | 101.797 | -0.02 [-1.15, +0.80] |

## Separate scale follow-up

96 measured samples and 16 excluded warmups; 112 child outputs.

| Case | B median ms | C median ms | Paired elapsed % median [min, max] | B RSS MiB | C RSS MiB | Paired RSS % median [min, max] |
|---|---:|---:|---:|---:|---:|---:|
| mixed-disjoint-1000 | 11.637 | 11.704 | -3.70 [-8.49, +15.25] | 6.992 | 6.969 | -0.34 [-0.67, +0.45] |
| mixed-disjoint-100000 | 44.900 | 43.902 | -2.44 [-13.48, +2.38] | 15.219 | 15.227 | +0.00 [-0.51, +0.10] |
| mixed-permuted-1000 | 10.960 | 11.163 | +0.08 [-3.83, +6.10] | 7.016 | 7.008 | -0.22 [-0.22, +0.22] |
| mixed-permuted-10000 | 14.582 | 14.295 | -0.67 [-5.86, +4.17] | 7.742 | 7.734 | +0.00 [-1.20, +0.61] |
| mixed-overlap-1000 | 10.602 | 11.687 | +4.67 [-26.48, +12.22] | 6.945 | 6.930 | -0.22 [-0.89, +0.00] |
| mixed-overlap-10000 | 14.268 | 13.829 | +0.81 [-7.06, +8.39] | 7.578 | 7.594 | +0.21 [+0.00, +0.21] |
| mixed-overlap-100000 | 44.271 | 41.808 | -5.07 [-16.44, +6.31] | 12.758 | 12.375 | -3.06 [-10.42, -2.33] |
| mixed-adjacent-1000 | 10.953 | 10.669 | -4.50 [-23.45, +21.95] | 6.938 | 6.938 | -0.11 [-0.45, +0.23] |

## Correctness, failures and retained-result tradeoff

The independent audit verified 1,488 full-suite test executions (both packages, both variants, Debug and Release), 77 differential CLI cases, every timed output/reference hash, native CPU/time/RSS, sample inventory, schedule, and every reported group/paired/spread scalar. All cases with any original individual elapsed/RSS regression above 5% received a separate six-pair follow-up.

The first primary attempt failed on its first warmup because the sandbox denied BSD time's kern.clockrate query. Its output and failure remain preserved; it contributes zero valid samples. The successful run is measurements-02, using the same harness logic with only its output directory changed. No outlier was removed.

The retained-result probe exposes a separate library tradeoff. After million-to-one overlap or adjacency collapse, both variants retain a 32,014,336-byte Array allocation, but the candidate's result-containing region has 30.5M resident/dirty memory versus baseline's 16K. Equal 62.8M whole-process physical footprint conceals the difference because empty allocator regions remain resident. The disjoint control retains 30.5M in either result region. These are one fresh instrumented macOS observation per case, not repeated benchmarks or Linux memory evidence. Physical footprint is distinct from RSS. See retention/SUMMARY.md and retention/summary.json for exact address attribution.

This evidence supports keeping the current candidate as a prototype for design discussion. A policy to avoid retaining a fully touched buffer after heavy collapse would be a separate candidate with its own allocation/copying tradeoff and measurements. No shrink threshold was added.
