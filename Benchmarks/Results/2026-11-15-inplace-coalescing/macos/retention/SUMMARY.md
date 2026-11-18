# Result-retention probe

In-place compaction retains a fully touched result buffer after heavy collapse.
This is a concrete tradeoff for long-lived library results, even though the
fresh-process physical footprint is unchanged in the two collapse cases. The
candidate remains unchanged.

This probe used one fresh process for each variant/case on macOS 27.2.1 (26B131),
ARM64, Apple Swift 6.4.2. Each process constructed one million IPv6 ranges inside
a non-inlined function, coalesced them once, and returned only the result. The
input variable's lifetime ended before the stdout/stdin checkpoint;
`withExtendedLifetime(result)` kept the result alive during inspection. All six
cases and all heap/VM inspections passed.

| Case | Variant | Result count | Capacity | Result-region resident / dirty | Physical footprint | Empty large malloc regions resident |
|---|---|---:|---:|---:|---:|---:|
| overlap | B | 1 | 1,000,447 | 16K / 16K | 62.8M | 61.1M |
| overlap | C | 1 | 1,000,447 | 30.5M / 30.5M | 62.8M | 30.5M |
| adjacent | B | 1 | 1,000,447 | 16K / 16K | 62.8M | 61.1M |
| adjacent | C | 1 | 1,000,447 | 30.5M / 30.5M | 62.8M | 30.5M |
| disjoint | B | 1,000,000 | 1,000,447 | 30.5M / 30.5M | 93.3M | 61.1M |
| disjoint | C | 1,000,000 | 1,000,447 | 30.5M / 30.5M | 62.8M | 30.5M |

Sizes with K/M suffixes above are the rounded strings reported by `vmmap`; swap is
zero in every result region. B is baseline and C is candidate. Physical footprint
is not RSS.

Every case has exactly one live
`Swift._ContiguousArrayStorage<CIDR.IPAddressRange<CIDR.AF.V6>>` allocation,
exactly 32,014,336 bytes. Its element address is 32 bytes after that allocation's
start. The Array reports stride 32 and capacity 1,000,447 (32,014,304 element-capacity
bytes). The complete allocation is contained within the identified `Malloc Large`
VM region. Thus the resident/dirty comparison is tied to the live result's
allocation, rather than inferred from a whole-process total.

For overlapping and adjacent inputs, only one range survives. Baseline's result
region has 16K resident/dirty; candidate's has 30.5M. Both retain the same nominal
capacity. Baseline also has 61.1M resident in regions marked `Malloc Large (empty)`,
compared with 30.5M for candidate. The equal 62.8M physical-footprint readings
therefore conceal the different live-result residency. The disjoint control keeps
one million results: both result regions have 30.5M resident/dirty, while candidate's
physical footprint is 30.5M lower at this checkpoint.

These observations support a retained-result residency concern for unconditional
in-place compaction. They do not establish steady-state process-memory behavior or
justify a particular shrink threshold. Any policy to copy or shrink a heavily
collapsed result should be a separate candidate, evaluated against its allocation
and copying cost.

## Evidence and reproduction

[summary.json](summary.json) records all six observations, exact allocation/region
addresses, raw-file hashes, binary/build receipt hashes and limits.
[README.md](README.md) contains build and run commands. Ordinary binaries and their
separately signed inspection copies have identical executable-section hashes.
Both clients use identical source and the original five upstream dependency
revisions. The optional BSD timing wrapper was not used.

## Limits

- One fresh process per variant/case is mechanism evidence, not a repeated benchmark.
- Heap and `vmmap` inspection can perturb process state; no throughput or cross-platform residency claim follows.
- VM region sizes are rounded display values. Capacity and malloc allocation sizes are exact integers.
- The identified region contains the result allocation and may also contain padding.
- Freed allocator regions remain resident in these observations. Whole-process physical footprint does not isolate the live result and is distinct from RSS.
- Sustained memory pressure, compression, allocator purge, later reuse and repeated-call workloads were not tested.
- Baseline already reserves input-sized result capacity. The collapse difference concerns resident/dirty pages, not nominal allocation size.
