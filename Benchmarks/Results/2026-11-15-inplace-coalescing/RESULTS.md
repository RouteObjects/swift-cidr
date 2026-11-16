# In-place coalescing prototype

Updated 2026-11-15T23:28:55.811957+00:00.

## Decision

The bare in-place prototype preserves correctness, but should not advance as the general replacement in its current form. macOS timing changes are mostly small or mixed; both Linux architectures have a repeatable peak-memory regression in the range-derived workload. A separate result-retention probe also identifies a memory-lifetime tradeoff after heavy collapse. This is an experimental result, not a release recommendation.

## Plan and patch

Current-main baseline: cidrmerge `8bba7629d7fc9c366ea47680ee6c38badd615092`, with swift-cidr 0.10.1 / `5e4b3d2f881340a6ced05742429f1bd680dfd1e0`. The prototype is on `perf/inplace-coalescing`. It makes the sorted temporary mutable, coalesces through integer read/write indices and removes the unused suffix. It retains the public generic Sequence interface, sorting comparator, checked adjacency helper, active interval and empty/singleton guard. Caller-owned Array values remain unchanged; single-pass sequences are consumed once.

The production diff changes one function in swift-cidr: 10 added lines and 7 removed lines, with the same sort-plus-linear-coalescing complexity. cidrmerge production code and canonical dependency manifests are unchanged. Both frozen experiment manifests use the same local upstream package path; the other seven CLI dependency revisions remain identical. Upstream tests retain their original five-dependency lock, which differs from the downstream lock. The compiler floor remains Swift 6.2.

[Production diff](production.patch) and [upstream code-and-test diff](full.patch). Ordinary release binaries were frozen before testing and are separate from inspection copies. No commit, push, merge, dependency update or release is part of this prototype.

## Fresh main profile

Before changing production code, a fresh Swift 6.4.2 baseline build was inspected on macOS. A stack-confirmed coalescing capture reached its specialized array-copy path with two live IPv6 range allocations totaling 82,345,984 bytes. Separate captures identify parsing, summarization and rendering. The post-parse captures contain no retained NSConcreteData byte storage. All completed inspection runs resumed to exact reference output.

These are separate paused processes. They identify phase and live allocation sizes, not CPU proportions, retaining roots or peak RSS. The current captures do not reproduce the historical three-array/109-MiB census; that older observation is not used as a current savings forecast. Source still explicitly creates a sorted buffer and a separate coalesced destination. The candidate tests that design change.

## Tests and compatibility

Four focused upstream tests cover genuine single-pass consumption, input Array/ArraySlice aliases and independent mutations, empty/singleton/disjoint/collapsed/multiple-group shapes, full storage coverage and maximum-endpoint gaps. Each covers IPv4, IPv6 and a custom UInt16 family. Existing randomized exact-membership and idempotence tests remain.

| Platform | B upstream D/R | C upstream D/R | B CLI D/R | C CLI D/R | Differential |
|---|---:|---:|---:|---:|---:|
| macOS ARM64 / Swift 6.4.2 | 298 / 298 | 302 / 302 | 72 / 72 | 72 / 72 | 77 |
| OrbStack ARM64 Linux / Swift 6.4.2 | 298 / 298 | 302 / 302 | 72 / 72 | 72 / 72 | 77 |
| swift-dev x86-64 Linux / Swift 6.4.2 | 298 / 298 | 302 / 302 | 72 / 72 | 72 / 72 | 77 |

Candidate Swift 6.2.4 on ARM64 Linux also passed all four configurations: upstream 302 Debug and 302 Release, CLI 72 Debug and 72 Release. Across the three Swift 6.4.2 platforms and the separate floor-toolchain suites, all 5,212 test executions passed; these are repeated configurations, not unique tests. All 231 baseline/candidate differential comparisons passed. These are compatibility results, not floor-toolchain performance measurements. The focused source/test formatting check passed. The retention probe is a separately built external consumer of the unchanged public API.

Linux generated-code evidence confirms ordinary CLI calls still reach concrete IPv4/IPv6 array coalescers and the appropriate sorting helpers. Indexed writes retain uniqueness checks and conditional copies; removing an explicit destination array does not establish zero overhead or zero allocation.

## Matched measurements

Timed commands use `cidrmerge --raw --representation cidr ...`. The primary matrix reuses eight million-entry split-family corpora and three native mixed configurations. One excluded warmup per configuration precedes six alternating BC/CB pairs with rotating case order: 132 measured samples and 22 warmups per completed platform. Split samples sum family elapsed/CPU and use the maximum child RSS; native samples use one process. Every complete output is checked against preserved independent coverage references. macOS uses native time resource records, Linux exact-child wait4. Sources, compiler executables, binaries, harnesses and references are frozen. Linux linked runtime libraries are hashed; macOS system-runtime identity is recorded by loaded UUID rather than copied into isolation. Mac and OrbStack measurements are separate, without task-owned builds, tests or profiling.

Supplementary inputs use prefixes of the original disjoint, shuffled, overlapping and adjacent mixed corpora at 1,000, 10,000 and 100,000 entries. Independent Python ipaddress references verify exact output. Each platform has 144 measured samples and 24 warmups in this separate 12-case matrix. These short CLI timings can include substantial startup variation. Shuffled scale fixtures are prefixes of the original million-entry permutation; they contain different address sets and text lengths from equal-sized ordered prefixes. Only the B/C comparison within each fixture isolates the candidate. Scale results are not pooled with the million-entry matrix.

Every case with an individual elapsed/RSS pair above +5% receives one separate fixed six-pair follow-up. Original observations remain, and no outliers are removed. Tables report paired medians and spreads; negative changes favor candidate. Small or mixed changes are inconclusive.

| Platform | Primary elapsed paired-median range | Primary RSS paired-median range |
|---|---:|---:|
| macOS ARM64 | -1.25% to +1.66% | -9.03% to +0.19% |
| ARM64 Linux | -0.16% to +2.16% | -4.44% to +11.73% |
| x86-64 Linux | -1.95% to +1.59% | -4.34% to +11.56% |

The range-derived split workload illustrates the cross-platform tradeoff: macOS peak RSS moves from 84.63 to 77.00 MiB (paired median −9.03%), whereas ARM64 Linux moves from 65.05 to 72.68 MiB (+11.73%). Its separate ARM follow-up is +11.74%, with all six memory pairs above +5% in both runs. swift-dev independently repeats the same direction: +11.56% primary and +11.54% in its separate follow-up, with all twelve pairs above +5%. This fails the regression criterion on both Linux architectures. The retention probe provides a plausible mechanism, but the precise CLI peak-lifetime explanation across allocators/compiler builds is not established.

Per-platform tables, unrounded observations, follow-ups, validation, audits and original-artifact bindings: [macOS](macos/MacTABLE.md), [ARM64 Linux](arm64/TABLE.md), [x86-64 Linux](x86_64/TABLE.md).

## Result lifetime matters

A separate release-built IPv6 client calls ordinary coalescing once and holds only its returned result at a handshake after the input variable leaves scope. Each B/C overlap, adjacency and disjoint case runs in a fresh process. Inspection copies match the ordinary executable instruction sections. Heap allocation and VM-region addresses are matched to the reported element pointer.

All six results retain capacity for 1,000,447 elements and a 32,014,336-byte allocation. In the million-to-one cases, baseline result storage has 16 KiB resident/dirty pages, while the candidate result region has approximately 30.5 MiB. For disjoint output, both regions have approximately 30.5 MiB resident/dirty. The collapse probes report the same rounded physical-footprint reading (62.8M), while freed allocator regions remain resident. Those aggregate readings do not expose the different live-result regions and are distinct from peak RSS; this evidence does not prove an exact aggregate equality or its sole cause.

This is one instrumented macOS observation per configuration, not a repeated-load, steady-state, memory-pressure or cross-platform result. Live allocation size, capacity, region residency and process peak RSS are distinct. See [retention findings](retention/SUMMARY.md) and the hashed observations beside them.

## What a million entries establishes

A million entries is a useful capacity checkpoint, rather than the sole definition of the workload. The smaller-input matrix, output cardinality, ordering, duplicates and overlap all matter. The prototype needs only a small production change and keeps the same sort-plus-linear-coalescing complexity; the memory issue is the lifetime of a partially occupied buffer. The same storage-lifetime concern can apply at smaller sizes; that is a design inference, not a measured smaller-size retention result. These synthetic workloads do not establish general carrier deployment qualification. Representative production input distributions, repeated-call lifetimes and explicit latency/memory budgets should guide later qualification.

A focused next design to discuss is to retain the sorted buffer when no ranges disappear, and materialize a suitably sized result when coalescing reduces the count. That offers a deterministic policy without choosing a shrink ratio in advance, at the cost of copying the reduced output. A ratio-based policy is another experiment. Neither has been implemented or benchmarked here. Preserve the current implementation until a candidate demonstrates acceptable throughput and memory behavior across the supported workloads.

## Preserved attempts and reproduction

The initial Mac manifest build was blocked by nested sandboxing; the retry used SwiftPM's supported sandbox option. A first heap capture lacked process-inspection access, and the first timing warmup could not read kern.clockrate. Those failures remain; the valid primary run is in macos/measurements-02, with zero valid measured samples discarded from the first attempt. An ARM audit path-spelling assumption was corrected in a separately retained auditor. Source snapshots and measured binaries were unchanged.

On swift-dev, verified byte-identical outputs share storage through a task-owned readonly hardlink store. Sharing happens after the original timed function has finished and its sample receipt is written. Every output path and complete byte stream remains available; helpers, protocol, inode/content mappings and original timing-function identity are verified. This introduces between-sample I/O, disclosed as a measurement condition. The older cache-cleanup proposal was not used. Original artifacts remain under `$HOME/Downloads/cidrmerge-inplace-coalescing-20261115T221013Z`, with the same Downloads-relative experiment on swift-dev. Older results and threshold files are preserved. Portable evidence carries original byte counts/hashes and transformed-output hashes; raw binaries, full stdout/stderr, native metrics, heap/VM captures, sources and logs remain in Downloads.

[Protocol and reproduction](REPRODUCE.md). Reports and prototype remain uncommitted for review.
