# ARM64 generated-code review

Both frozen ordinary release binaries preserve the specialized CLI coalescing/sorting path. `ParsedInput.merged` directly calls the V4/Array and V6/Array coalescing functions. Each supplies concrete comparator, stable-sort and insertion-sort function pointers to a shared dispatcher; the dispatcher calls the supplied pointers. The V6 name on that merged dispatcher does not mean V4 values take a V6 layout.

| Variant | CLI caller | V4 coalescing | V6 coalescing | Sort dispatcher |
|---|---|---|---|---|
| B | 0x195d18 | 0x177b8c | 0x177d2c | 0x178fd0 |
| C | 0x195db8 | 0x177b4c | 0x177cc4 | 0x179020 |

Candidate coalescing uses indexed stores into its sorted buffer and a specialized suffix removal. Its coalescing bodies no longer contain the baseline result-array reserve/growth call signature. However, Swift retains uniqueness checks at completed-group writes (V4: 0x177c14; V6: 0x177db8) and final writes, with conditional copy fallbacks. This is not unchecked or allocation-free compaction, and timing must determine the throughput effect.

Comparator bodies contain fixed-width integer comparisons and no calls. Stable/insertion sort bodies remain concrete V4/V6 specializations. Sorting scratch buffers, the caller's input storage and retained array capacities remain. Evidence is static code generation, not a dynamic allocation count.

`review.json` binds these assertions to captures, pointer addresses and the exact pre-test ordinary-release build hashes. Full symbol inventories and 22 selected disassemblies per variant are retained. The capture's initial stability boolean is not relied on; the separate review verifies current binary hashes against both capture hashes and original release-build receipts.
