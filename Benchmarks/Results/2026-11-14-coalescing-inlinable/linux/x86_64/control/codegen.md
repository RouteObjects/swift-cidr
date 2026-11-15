# Swift 6.4.2 x86-64 Linux generated-code verification

**Passed: the candidate CLI reaches specialized sorting for both IPv4 and IPv6 on swift-dev.** This is a static code-generation gate, not a timing or allocation-count result.

| Actual call edge | Baseline B | Candidate C |
|---|---|---|
| `ParsedInput.merged` | `0x1df1fc` calls generic Core initializer `0x1ea450` | Core/Coverage wrappers disappear from this callsite |
| IPv4 construction | Core at `0x1ea48c` calls generic coalescing `0x1c49e0` | CLI at `0x1df22d` calls V4/Array coalescing `0x1c0140` |
| IPv6 construction | Core at `0x1ea4ae` calls the same generic coalescing | CLI at `0x1df238` calls V6/Array coalescing `0x1c0310` |
| Sorting | Generic coalescing at `0x1c4b12` calls external `Sequence.sorted(by:)` | Both concrete coalescers call local sort dispatcher `0x1c1730` with family-specific comparator and sort-function pointers |

The V4 path supplies comparator `0x1c34f0`, stable-sort body `0x1c1e40`, and insertion-sort body `0x1c2420`. V6 supplies comparator `0x1c3460`, stable-sort body `0x1c1830`, and insertion-sort body `0x1c22f0`. RIP-relative `LEA` instructions and the dispatcher's saved argument pointers establish these paths. The merged dispatcher's V6 symbol label does not mean that it interprets V4 elements as V6.

Both concrete comparator bodies contain fixed-width loads/comparisons and no calls. The inspected insertion-sort bodies use fixed-layout element access and an indirect concrete comparator call, without generic `Collection.subscript.read` witnesses or direct `malloc`/`free` calls on that access path. Sorting still uses copy-on-write arrays, merge scratch buffers and other runtime operations. No allocation-free claim is made, and the macOS runtime's 40-byte generic access-context observation is not asserted for the uninspected Linux runtime.

## Identity and scope

- B SHA-256: `341234e40b810847b2b33de12b6bfb7ccdfbfb882aa5424061dd299d23832211`.
- C SHA-256: `5aceca2a43b1edc362763b546273c620b4a2fe05c8f7ed4336f9ddc4dbc62fa2`.
- Both are immutable ordinary release ELF binaries copied before test builds on swift-dev.
- Addresses are ELF virtual addresses before load relocation.
- `codegen.json` contains exact commands, hashes, 16 focused function captures, assertions and reviewed pointer flow. `verify_codegen_remote.py` reproduces the automated capture/check portion in a fresh result location; the pointer-flow explanation was reviewed against the captured assembly.
- Inspection ran remotely with GNU `nm`/`objdump` and the installed Swift 6.4.2 demangler. Only small text evidence was transferred while ARM64 benchmarks were active; no ELF disassembly ran locally.
- No target execution, build or profiling occurred during this inspection. Generic implementations remain available to other callers; the gate verifies the actual typed CLI route, not merely specialized-symbol presence.
