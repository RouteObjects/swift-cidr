# Candidate C-v2 versus matched baseline: generated code

**C-v2 passes the actual CLI specialization gate.** This result supports proceeding to semantic validation and matched timing. It does not establish a speedup or memory saving by itself.

| Actual call edge | Matched baseline B | Candidate C-v2 |
|---|---|---|
| `ParsedInput.merged` → coverage construction | `0x1000aad78` calls generic Core initializer `0x1000b48d4` | Core/Coverage wrappers disappear from this callsite |
| IPv4 construction | Core at `0x1000b491c` calls generic coalescing `0x10008ef40` | CLI at `0x1000aad74` calls V4/Array coalescing `0x10008eb70` |
| IPv6 construction | Core at `0x1000b4940` calls same generic coalescing | CLI at `0x1000aad80` calls V6/Array coalescing `0x10008ed38` |
| Sorting | Generic coalescing calls external `Sequence.sorted(by:)` at `0x10008f0fc` | Concrete coalescing calls local merged sort dispatcher `0x100092fa0` with concrete comparator/sort-function pointers |

The candidate's V4 path supplies comparator `0x100094d9c`, stable-sort body `0x10009356c` and insertion-sort body `0x100093a9c`. V6 supplies comparator `0x100094d04`, stable-sort body `0x1000930d4` and insertion-sort body `0x1000939a4`. The merged dispatcher invokes those supplied function pointers; a merged symbol's V6 label is not evidence that it treats V4 as V6.

Both comparator bodies contain fixed-width integer loads/comparisons and no call instructions. Both specialized insertion-sort bodies access fixed-size range values directly and call the supplied concrete comparator. They do not use `Collection.subscript.read` witnesses or call malloc/free on the inspected comparison-access path. This removes the previously observed generic coroutine-read allocation mechanism from that path; it does not make sorting allocation-free. Copy-on-write storage, merge scratch buffers, output arrays and indirect comparator calls remain.

The upstream-only C-v1 attempt failed this gate and is preserved in `codegen-C-v1.json` / `.md` with its original binary. Adding the Core package initializer's `@inlinable` completes the tested visibility chain for this Swift 6.4.2 macOS ARM64 build. This experiment does not isolate whether every upstream annotation is individually necessary, guarantee specialization for every caller/toolchain, or qualify another platform.

## Identity and method

- Baseline `bin/B`: SHA-256 `26c90ba7f8ae66bffb6dc897b5fc04fdb6529d8613815bc406332370391c7be6`.
- Candidate `bin/C`: SHA-256 `ab28022ecaf3a656c52ec83d7ba633886ad61b3b3255475c4984a9631eb57f3f`.
- Both binaries are frozen copies from the matched local-dependency builds.
- `codegen-C-v2.json` retains source hashes, exact tool commands, focused demangled disassembly, binary hashes and static assertions.
- Inspection used `nm`, `swift-demangle` and `llvm-objdump`; no target execution, build, profile or process attachment occurred in this review.

The generic implementations remain available for other consumers. The change is that the ordinary typed CLI route now reaches the concrete family/array copies; the finding is based on actual caller instructions, not specialized-symbol presence alone.
