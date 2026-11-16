# x86-64 generated-code review

Both ordinary release binaries preserve concrete V4/Array and V6/Array coalescing on the actual `ParsedInput.merged` path. Each supplies the matching comparator (rsi), stable-sort (r8), and insertion-sort (r9) pointers to a shared dispatcher. The dispatcher saves and invokes the supplied pointers; its merged V6 symbol name does not imply V4 data uses a V6 layout.

| Variant | CLI caller | V4 coalescing | V6 coalescing | Sort dispatcher |
|---|---|---|---|---|
| B | 0x1df210 | 0x1c0140 | 0x1c0310 | 0x1c1730 |
| C | 0x1df2b0 | 0x1c0140 | 0x1c02c0 | 0x1c1770 |

Candidate coalescing writes completed ranges back into its sorted buffer and uses specialized suffix removal. The baseline result-array reserve/growth signature is absent from those candidate bodies. Candidate bodies retain three uniqueness-check call sites (initial, completed-group, final) versus one initial site in baseline, with conditional copy fallbacks. Comparator bodies use fixed-width comparisons without calls. Sorting and input storage still allocate or retain capacity; no allocation-free or performance claim is made.

Both capture hashes are independently matched to current frozen binary bytes and the ordinary release build receipts. All 22 selected disassemblies per arm and complete symbol inventories are retained.
