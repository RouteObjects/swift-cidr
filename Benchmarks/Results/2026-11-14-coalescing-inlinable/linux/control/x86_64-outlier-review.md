# Retained x86-64 timing observations

All six pairs remain in every reported median and range. This review compares raw per-child wall time and wait4 counters; it does not identify the cause of the observations.

## ipv6-disjoint

All-six-pair elapsed median change: -1.984%; pair range -4.566% to +70.668%. All-six-pair CPU-time median change: -1.991%.

| Round | Binary | Family | Wall s | User s | System s | Wall−CPU ms | Minor faults | Major faults | Voluntary / involuntary switches |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | B | 6 | 10.564177 | 10.384792 | 0.171930 | 7.455 | 45610 | 0 | 14 / 108 |
| 1 | C | 6 | 10.429527 | 10.248957 | 0.172914 | 7.656 | 45608 | 0 | 14 / 100 |
| 2 | C | 6 | 18.413003 | 18.146549 | 0.257922 | 8.532 | 45606 | 0 | 14 / 120 |
| 2 | B | 6 | 10.788805 | 10.604349 | 0.180971 | 3.485 | 45611 | 0 | 14 / 53 |
| 3 | B | 6 | 10.775409 | 10.602819 | 0.165950 | 6.640 | 45611 | 0 | 14 / 109 |
| 3 | C | 6 | 10.613783 | 10.434665 | 0.171912 | 7.206 | 45606 | 0 | 14 / 99 |

## mixed-disjoint

All-six-pair elapsed median change: -1.196%; pair range -3.763% to +32.419%. All-six-pair CPU-time median change: -1.202%.

| Round | Binary | Family | Wall s | User s | System s | Wall−CPU ms | Minor faults | Major faults | Voluntary / involuntary switches |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | B | 6 | 5.354888 | 5.270982 | 0.078984 | 4.922 | 23171 | 0 | 14 / 63 |
| 1 | C | 6 | 5.222181 | 5.118262 | 0.098966 | 4.953 | 23166 | 0 | 14 / 54 |
| 2 | C | 6 | 8.433193 | 8.298202 | 0.130987 | 4.004 | 23164 | 0 | 14 / 41 |
| 2 | B | 6 | 5.318625 | 5.219843 | 0.095960 | 2.822 | 23171 | 0 | 14 / 34 |
| 3 | B | 6 | 5.290804 | 5.191827 | 0.093960 | 5.017 | 23170 | 0 | 14 / 52 |
| 3 | C | 6 | 5.382397 | 5.275394 | 0.101949 | 5.054 | 23164 | 0 | 14 / 58 |

## mixed-adjacent

All-six-pair elapsed median change: -3.015%; pair range -32.433% to -0.425%. All-six-pair CPU-time median change: -3.011%.

| Round | Binary | Family | Wall s | User s | System s | Wall−CPU ms | Minor faults | Major faults | Voluntary / involuntary switches |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | B | 6 | 9.108622 | 9.022912 | 0.080972 | 4.738 | 12838 | 0 | 14 / 46 |
| 1 | C | 6 | 5.028455 | 4.975000 | 0.050989 | 2.466 | 12833 | 0 | 14 / 17 |
| 2 | C | 6 | 5.051059 | 5.001010 | 0.046000 | 4.049 | 12834 | 0 | 14 / 52 |
| 2 | B | 6 | 5.204578 | 5.152990 | 0.046981 | 4.607 | 12837 | 0 | 14 / 59 |
| 3 | B | 6 | 5.124876 | 5.060307 | 0.059968 | 4.601 | 12838 | 0 | 14 / 51 |
| 3 | C | 6 | 5.104866 | 5.045293 | 0.054970 | 4.603 | 12833 | 0 | 14 / 51 |

## Interpretation

- The split IPv6-disjoint candidate in round 2 takes 18.413003418 s wall and 18.404471 s CPU; nearby candidate rounds 1 and 3 take 10.429526738 s and 10.613783297 s wall. Paired elapsed change: +70.667685912%.
- The split mixed-disjoint candidate round 2 excess is concentrated in its IPv6 child: 8.433192766 s wall and 8.429189 s CPU. The IPv4 child takes 4.123365979 s, close to nearby IPv4 values. Total paired elapsed change: +32.418591631%.
- The favorable split mixed-adjacent round 1 comparison includes a slower baseline: 13.141830735 s total wall and 13.135077 s CPU. Its IPv6 child takes 9.108622072 s wall and 9.103884 s CPU, versus 5.204577603 s and 5.124876100 s wall in baseline rounds 2 and 3. The paired elapsed change is -32.432887860%.
- For these nearby records, major faults, swaps and input-block counts are zero; output-block counts are unchanged within each fixture/family, and minor-fault counts are close. Context-switch counts vary but do not show a consistent increase sufficient to identify a cause.
- Extra wall time is also charged as child CPU time; wall-minus-CPU remains on the millisecond scale. These counters do not support treating the observations merely as parent waiting or blocking-input-I/O delays.
- The data do not establish thermal throttling, CPU frequency changes, hypervisor scheduling/steal, allocator behavior, or a specific algorithmic cause. No hardware/perf trace was taken for these individual runs.
- Small 1–3% paired median changes require qualification given six pairs and retained variability. Larger consistent sorting-heavy improvements should be described separately, with platform-specific scope.

Exact raw sample/rusage paths and SHA-256 hashes are recorded in [x86_64-outlier-review.json](x86_64-outlier-review.json). All compared outputs pass the independent exact-byte coverage audit.
