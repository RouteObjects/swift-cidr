# Swift 6.4.2 ARM64 Linux generated-code verification

**Passed: the candidate CLI reaches specialized sorting for both IPv4 and IPv6.** This is a static code-generation gate, not a timing or allocation-count result.

| Actual call edge | Baseline B | Candidate C |
|---|---|---|
| `ParsedInput.merged` | `0x195d24` calls generic Core initializer `0x1a03ac` | Core/Coverage wrappers disappear from this callsite |
| IPv4 construction | Core at `0x1a03f4` calls generic coalescing `0x17be2c` | CLI at `0x195d40` calls V4/Array coalescing `0x177b8c` |
| IPv6 construction | Core at `0x1a0418` calls the same generic coalescing | CLI at `0x195d4c` calls V6/Array coalescing `0x177d2c` |
| Sorting | Generic coalescing at `0x17bf50` calls external `Sequence.sorted(by:)` | Both concrete coalescers call local sort dispatcher `0x178fd0` with family-specific comparator and sort-function pointers |

The V4 path supplies comparator `0x17a9ec`, stable-sort body `0x179588`, and insertion-sort body `0x179aa0`. V6 supplies comparator `0x17a984`, stable-sort body `0x1790f8`, and insertion-sort body `0x1799a8`. The `ADRP`/`ADD` argument construction and dispatcher register moves establish those call paths. The merged dispatcher's V6 symbol label does not mean that it interprets V4 elements as V6.

Both concrete comparator bodies contain fixed-width loads/comparisons and no calls. The inspected insertion-sort bodies use fixed-layout element access and an indirect concrete comparator call, without generic `Collection.subscript.read` witnesses or direct `malloc`/`free` calls on that access path. Sorting still uses copy-on-write arrays, merge scratch buffers and other runtime operations. No allocation-free claim is made, and the macOS runtime's 40-byte generic access-context observation is not asserted for the uninspected Linux runtime.

## Identity and scope

- B SHA-256: `46526cf942a91687cf231cbeaaf6bb65d9e19f233fc54b0e6b1839d27c8a4af8`.
- C SHA-256: `3ce0ef33d754242e0629c20443853b081ca3f1ec0bc622cae77c1ebc93b480e9`.
- Both are immutable ordinary release ELF binaries copied before test builds.
- Addresses are ELF virtual addresses before load relocation.
- `codegen.json` contains exact commands, hashes, 16 focused function captures, assertions and reviewed pointer flow. `verify_codegen.py` reproduces the automated capture/check portion in a fresh result location; the pointer-flow explanation was reviewed against the captured assembly.
- Local Xcode LLVM tools and Swift demangler read these ELF binaries without executing them. No build, target execution or profiling occurred during this inspection.
- Generic implementations remain available to other callers. The verified difference is the actual typed CLI route, not merely the existence of specialized symbols.
