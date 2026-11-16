# ARM64 compact-storage generated-code review

The frozen ordinary release binaries preserve the concrete CLI coalescing/sorting path. ParsedInput.merged directly calls the V4/Array and V6/Array coalescers. Each supplies concrete comparator, stable-sort and insertion-sort pointers to the shared dispatcher, which calls those supplied pointers. The merged dispatcher's V6 name does not imply a V6 layout for V4 values.

| Variant | CLI caller | V4 coalescer | V6 coalescer | Sort dispatcher |
|---|---|---|---|---|
| B | 0x195d18 | 0x177b8c | 0x177d2c | 0x178fd0 |
| C | 0x195d04 | 0x177acc | 0x177cdc | 0x179104 |

Both candidate coalescers compute resultCount = writeIndex + 1, compare it with the sorted buffer's original count, and branch directly to returning that buffer when no entries disappear. Otherwise they pass resultCount as the reserve helper's minimum capacity, copy the compacted prefix with concrete fixed-width loads/stores, then release the sorted buffer. The V4 guard is at 0x177c0c; V6 at 0x177e7c. Reservation calls are at 0x177c24 and 0x177e98 respectively. There is no suffix-removal operation in this candidate.

Indexed compaction still performs uniqueness checks with conditional-copy fallbacks. The copy loop retains capacity checks and potential growth calls; the source reserves enough space, but this inspection is not a dynamic allocation count or a zero-allocation claim. Swift's allocator may round the requested capacity. The collapse-only copy introduces additional work for nearly full output; timing and separate lifetime observations must assess that tradeoff.

review.json records exact checked instruction lines and binary hashes matching the pre-test ordinary release receipts. The captures record actual before/after hashes. Comparator bodies contain fixed-width comparisons without calls; stable/insertion sort bodies remain concrete V4/V6 specializations. Full symbols and selected disassembly are retained. No benchmarked process was run by this static inspection.
