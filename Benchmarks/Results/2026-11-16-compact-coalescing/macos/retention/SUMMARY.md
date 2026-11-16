# Retained-result storage: compact candidate

The compact branch removes the previous candidate's retained large-buffer problem on heavy collapse. For one million overlapping or adjacent IPv6 ranges, C returns one interval with capacity 1 in a 64-byte live typed Array allocation. B returns one interval while reserving capacity 1,000,447 in a 32,014,336-byte allocation. These are observed allocation sizes, not API guarantees.

| Case | Variant | Input count | Result count | Capacity | Live Array bytes | Containing region | Region resident / dirty | Physical footprint |
|---|---|---:|---:|---:|---:|---|---|---|
| overlap | B | 1,000,000 | 1 | 1,000,447 | 32,014,336 | Malloc Large | 16K / 16K | 62.8M |
| overlap | C | 1,000,000 | 1 | 1 | 64 | Malloc Tiny | 64K / 64K | 62.8M |
| adjacent | B | 1,000,000 | 1 | 1,000,447 | 32,014,336 | Malloc Large | 16K / 16K | 62.8M |
| adjacent | C | 1,000,000 | 1 | 1 | 64 | Malloc Tiny | 64K / 64K | 62.8M |
| disjoint | B | 1,000,000 | 1,000,000 | 1,000,447 | 32,014,336 | Malloc Large | 30.5M / 30.5M | 93.4M |
| disjoint | C | 1,000,000 | 1,000,000 | 1,000,447 | 32,014,336 | Malloc Large | 30.5M / 30.5M | 62.8M |
| sparse | B | 1,000,001 | 1,000,000 | 1,000,447 | 32,014,336 | Malloc Large | 30.5M / 30.5M | 93.4M |
| sparse | C | 1,000,001 | 1,000,000 | 1,000,447 | 32,014,336 | Malloc Large | 30.5M / 30.5M | 93.3M |

The compact result lives in a shared Malloc Tiny region: its 64K resident/dirty total is **not** the memory attributable to the 64-byte Array. The exact allocation is linked by its heap start address, the emitted element pointer at offset 32, and the containing VM address range. Each case has exactly one live typed range Array after the source-producing function returns.

Both heavy-collapse variants still show 62.8M whole-process physical footprint at this immediate checkpoint. Both retain 61.1M resident memory in empty large malloc regions. Freeing the large live buffer therefore does not imply an immediate process-footprint reduction or allocator return to the operating system.

The no-merge disjoint control keeps the large result in both variants. The sparse case adds only one duplicate to one million disjoint typed ranges: both variants still return one million intervals with the same rounded capacity and allocation size. C takes its fresh-copy branch, so this case tests the additional-copy tradeoff without a live-result capacity benefit. Its end-to-end elapsed and peak-RSS cost belongs to the separate sparse CLI matrix.

No original observation was replaced. The two initial build failures were cache-permission failures before compilation; retry02 built the same probe source successfully. The ordinary/profile binaries have identical executable-section hashes, and every raw heap/VM/stdout file is hash-bound in summary.json. All eight inspections succeeded in fresh processes.

## Limits

- One fresh process per variant/case, not a repeated memory benchmark, throughput timing, allocation counter, or Linux retention result.
- Every pointer is a borrowed numeric element address inside withExtendedLifetime(result); makeResult has returned and the source Array does not escape. Heap detects one live typed range Array.
- Array capacity and exact heap allocation bytes are observed for this toolchain/allocator, not public API guarantees; reserveCapacity may round capacity.
- The candidate collapse Array is in a shared Malloc Tiny region. The region's 64K resident/dirty total includes unrelated allocations and cannot be attributed to the 64-byte Array.
- VM displays are rounded; no precise per-object resident-page count is claimed. Whole-process physical footprint is not RSS and includes empty allocator regions.
- No memory-pressure, long-term reuse, concurrent workload, or allocator-reclamation experiment was performed. Inspection uses a separately ad-hoc signed copy whose executable sections match the ordinary Release binary.
