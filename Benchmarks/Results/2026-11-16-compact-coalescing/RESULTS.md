# Coalescing with conditional compact storage

Updated 2026-11-16T04:36:59.171914+00:00.

## Outcome

Accepted by the project owner on 2026-11-16 as-is. Preserve sorted storage when no ranges merge and allocate fresh compact storage after merges. The measured sparse-merge CPU cost is an accepted tradeoff for this simple, deterministic policy; no shrink-threshold heuristic or further candidate is planned. The implementation and benchmark observations are unchanged.

All three platform matrices are complete; the interpretation below must be read with their retained spreads and follow-ups.

The candidate addresses the oversized returned-buffer problem by preserving sorted storage when no ranges disappear and allocating fresh result storage after merges. The macOS retention probe confirms that heavy collapse now returns a tiny allocation. Mac range-derived CLI peak RSS falls substantially, while neither Linux architecture repeats the prior candidate's range-derived memory regression. Throughput changes are generally small relative to the retained timing variation; this does not establish a general CLI speedup. The x86-64 million-entry sparse case shows a modest repeatable CPU cost, so the candidate is a memory/CPU tradeoff.

## Patch and baseline

Baseline B is unchanged local main: cidrmerge `8bba7629d7fc9c366ea47680ee6c38badd615092` and swift-cidr `5e4b3d2f881340a6ced05742429f1bd680dfd1e0` (0.10.1). Candidate C is on `perf/coalescing-compact-storage`. Both experimental CLI manifests use the same local swift-cidr path and retain identical seven other dependency pins; upstream tests use their original five-pin graph. Canonical manifests and compiler floor are unchanged.

The production change affects one function, `IPAddressRange.coalescing`: 16 added lines and 6 removed lines against main. It retains the comparator, adjacency/max-endpoint logic, active interval, generic Sequence API and empty/singleton path. Integer indices compact the sorted prefix. If output count equals input count, the sorted Array is returned. Otherwise a fresh Array reserves the output count and receives that prefix through indexed appends. The same sorting and linear coalescing complexity remains, with an additional output-sized copy only after merges.

The explicit fresh-storage path is verified in generated code. `reserveCapacity` permits allocator rounding, so this is not a guarantee that capacity equals count or that every small reduction changes the allocation size. Ordinary CLI code generation confirms typed IPv4/IPv6 coalescing and sorting, plus the conditional compact-copy path. Uniqueness and growth checks remain.

[Production diff](production.patch), [complete upstream code-and-test diff](full.patch), and [macOS generated-code evidence](macos/retention/codegen/SUMMARY.md). The complete patch applies cleanly to the frozen baseline. The experiment did not change canonical dependency pins or publish a release; branch publication is a separate follow-up.

## Correctness and compatibility

The prior focused tests remain: single-pass consumption, caller Array/ArraySlice aliases and independent mutation, empty/singleton/disjoint/collapsed shapes, complete storage coverage and gaps beside maximum endpoints. A new sparse-merge test covers 4,096 otherwise-disjoint ranges with one duplicate at the beginning, middle or end. All five tests exercise IPv4, IPv6 and a custom UInt16 family. Existing randomized exact-membership/idempotence tests remain.

| Platform / Swift 6.4.2 | B upstream Debug/Release | C upstream Debug/Release | B CLI Debug/Release | C CLI Debug/Release | Differential cases |
|---|---:|---:|---:|---:|---:|
| macOS ARM64 | 298 / 298 | 303 / 303 | 72 / 72 | 72 / 72 | 77 |
| OrbStack ARM64 Linux | 298 / 298 | 303 / 303 | 72 / 72 | 72 / 72 | 77 |
| swift-dev x86-64 Linux | 298 / 298 | 303 / 303 | 72 / 72 | 72 / 72 | 77 |

Candidate Swift 6.2.4 ARM64 compatibility suites passed: upstream 303 Debug and 303 Release; CLI 72 Debug and 72 Release, totaling 750 test executions. The floor-toolchain suites are compatibility evidence, not performance measurements. Each complete Swift 6.4.2 platform contributes 1,490 executions across eight full suites. All 5,220 test executions passed across the complete matrix, along with all 231 differential comparisons; these are repeated configurations, not unique tests. [Formatting and source-preservation checks](SOURCE_REVIEW.json) passed; original tracked files, refs, empty indexes and both copies of the previous report were verified. The final [independent x86 export review](X86_EXPORT_REVIEW.json) also passed. The retention client is an external consumer of the unchanged public API.

## Matched protocol

All variants run `cidrmerge --raw --representation cidr ...`. Each configuration receives one excluded warmup per variant and six alternating B/C and C/B pairs, with rotating case order. Every complete output matches independently preserved coverage bytes. Primary, smaller-input, sparse-merge and follow-up observations stay separate. No outliers are discarded or pooled.

- Primary: eight original million-entry split-family corpora and three native mixed cases; 132 measured samples and 22 warmups per platform. Split samples sum family elapsed/CPU time and use the larger child peak RSS.
- Scale: 12 cases at 1,000, 10,000 and 100,000 entries; 144 measurements and 24 warmups. Smaller shuffled prefixes contain different address sets/text lengths from ordered prefixes; only within-fixture B/C comparisons isolate the change.
- Sparse merge: 10,000 and 1,000,000 disjoint base entries plus exactly one duplicate per family; 24 measurements and four warmups. Independent Python collapse confirms unchanged coverage. These specifically exercise a nearly full copy after very few merges.

Every case with an individual elapsed/RSS pair above +5% receives one separate fixed six-pair follow-up. A follow-up can still contain a large observation; the fixed protocol does not recursively rerun until a preferred result appears. Tables show paired medians and complete pair spreads. Small/noisy timing changes remain inconclusive.

Sources, ordinary release binaries, compiler/runtime identities, harnesses and references are frozen. Ordinary binaries are copied before test builds. Linux records exact-child wait4 resources and hashes linked runtime library bytes; macOS records native time resources and loaded system-runtime UUIDs. Mac and OrbStack timing run separately without task builds/tests/profiling. swift-dev is native x86-64 Linux in an LXC environment, not bare-metal qualification. Its stdout hardlink store operates after timed samples and receipts; complete outputs remain at every path. Between-sample hashing/comparison/journaling is disclosed as part of that platform's conditions. Compare B/C within each platform; absolute cross-platform times are not normalized for hardware or compiler/runtime build differences.

## Primary results

Negative percentages favor the candidate. These ranges summarize the per-case paired medians; they do not represent confidence intervals or a pooled result.

| Platform | Elapsed paired-median range | Peak RSS paired-median range |
|---|---:|---:|
| macOS ARM64 | -0.97% to +0.78% | -27.15% to +1.93% |
| ARM64 Linux | -2.02% to +1.28% | -4.49% to +0.02% |
| x86-64 Linux | -0.64% to +5.03% | -4.50% to +0.16% |

Mac range-derived peak RSS moves from 84.75 to 61.74 MiB: paired median −27.15%, with all six pairs between −27.18% and −27.12%. ARM64 range-derived RSS is effectively unchanged: −0.015% initially and −0.018% in its separate follow-up, replacing the previous prototype's repeated roughly +11.7% regression. x86-64 range-derived RSS is also effectively unchanged: +0.015% initially and −0.035% in its follow-up, with follow-up pairs from −0.265% to +0.378%. The prior roughly +11.6% regression is absent. The old prototype remains historical evidence; it was not rerun or pooled with this new B/C comparison.

ARM64 native-permuted RSS improves −4.49% initially and −4.47% in its follow-up; BGP-like RSS improves −3.82% and −3.77%. These are workload-specific process-peak observations, not a universal memory reduction.

## Sparse-copy cost and timing limits

For the native million-entry sparse case, macOS elapsed paired median is −0.23% and RSS +0.02%. ARM64 elapsed is −0.39% initially and +0.44% in its follow-up; RSS is +0.031% and +0.036%. The ARM follow-up elapsed spread includes −1.36% to +52.86%. This does not establish a cost-free copy: the extra observation is retained, and throughput remains noisy.

On x86-64, the million-entry sparse case has elapsed paired medians +2.38% initially and +3.34% in the fixed follow-up. All six follow-up pairs are slower (+1.79% to +6.82%). Paired CPU-time change medians increase +2.39% and +3.34%, supporting a modest additional CPU-cost interpretation; this does not isolate the copy from every other generated-code effect. Peak RSS stays essentially unchanged (−0.033% initially, +0.043% follow-up). This cost remains relevant despite sub-5% medians; individual pairs exceeding 5% triggered the follow-up.

x86-64 mixed-adjacent elapsed moves from +5.03% initially to +1.86% in the follow-up, whose spread is −1.80% to +5.35%; paired CPU-time change medians move similarly (+5.08% to +1.87%). The follow-up weakens a stable above-5% slowdown claim and provides no speedup evidence.

Another visible timing regression is ARM64 overlap at 10,000 entries: +5.48% paired median initially and +3.28% in its fixed follow-up. macOS also contains large individual timing deviations (including +47.49% in a smaller permuted case), with small or direction-changing follow-up medians. These checks did not find a repeatable above-5% median regression on those cases, but they do not prove general performance noninferiority.

Full per-case tables, every unrounded pair, native resources, validation receipts and audit bindings: [macOS](macos/MacTABLE.md), [ARM64 Linux](arm64/TABLE.md), [x86-64 Linux](x86_64/TABLE.md).

## Returned-storage lifetime

Eight separate release-built IPv6 consumer processes hold only the returned result after their input-building function exits: B/C overlap, adjacency, disjoint and sparse cases. Inspection and ordinary executable sections match, and reported element addresses are matched to heap allocations and containing VM regions.

For overlap and adjacency, both results contain one range. Baseline capacity is 1,000,447, in a 32,014,336-byte typed Array allocation. Candidate capacity is 1, in a 64-byte typed Array allocation. Candidate's containing Malloc Tiny region has 64 KiB resident/dirty, but it also contains unrelated objects; those region bytes are not the Array's own footprint.

The collapsed B/C processes still report matching rounded physical-footprint readings of 62.8M while empty large allocator regions retain 61.1M. A smaller live result allocation therefore does not guarantee an immediate equal RSS/physical-footprint reduction. Disjoint results keep the same capacity in both variants. The sparse typed probe (1,000,001 inputs to 1,000,000 outputs) also has the same 32,014,336-byte result allocation in B/C: rounding leaves no observed capacity benefit from that nearly full copy.

These are one instrumented observation per configuration on macOS, not repeated-load, memory-pressure, steady-state or cross-platform retention evidence. See [retention findings](macos/retention/SUMMARY.md) and the bound captures.

## Scale, preserved attempts and review status

The million-entry target remains a useful capacity checkpoint, supported here by smaller inputs, different ordering/overlap patterns, a sparse-merge boundary case and retained-result inspection. The production change stays small. Representative production traces, repeated-call lifetimes and explicit latency/memory budgets remain appropriate inputs to carrier deployment qualification; these synthetic tests alone do not supply that qualification.

The first retention client builds stopped on a cache-permission restriction before compilation; fresh retry paths passed, and both failed receipts remain. The first Mac portable export selected an obsolete receipt name; its partial output/exporter are preserved outside the final report tree and the corrected export passed. A malformed test-file diff header was corrected and checked without changing frozen source or measured binaries. All benchmark observations, follow-ups and prior reports/thresholds remain preserved.

Raw evidence is under `$HOME/Downloads/cidrmerge-compact-coalescing-20261116T033826Z`, with corresponding preserved swift-dev evidence. [Reproduction instructions](REPRODUCE.md) describe exact commands and measurement boundaries. The prototype is accepted as-is and this experiment is closed. The sparse-merge cost remains documented as an accepted tradeoff; no shrink-threshold heuristic is required. The accepted source, tests and reports are prepared on `perf/coalescing-compact-storage` for signed commits and branch publication, authorized on 2026-11-16. No merge, release or downstream dependency update is included in that publication.
