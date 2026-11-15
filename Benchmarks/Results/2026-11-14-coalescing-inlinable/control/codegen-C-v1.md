# Candidate C-v1 generated-code check

**The actual CLI sorting-specialization gate fails.** This is a static result, not a throughput measurement. Upstream annotation changes alone do not move this call chain onto concrete array/family sorting.

| Caller | Call instruction | Target |
|---|---|---|
| `ParsedInput.merged` | `0x1000aae30` | generic Core initializer, `0x1000b48c0` |
| Core initializer, IPv4 | `0x1000b4908` | generic coalescing, `0x10008ef40` |
| Core initializer, IPv6 | `0x1000b492c` | same generic coalescing |
| Generic coalescing | `0x10008f0fc` | external `Sequence.sorted(by:)`, stub `0x1000b6e00` |

The family/Array specialized copies exist, but the inspected CLI does not call them. The next bounded experiment is to expose the Core initializer to the concrete CLI array call, then re-inspect actual edges. This result does not prove that upstream visibility changes are useless or that a Core annotation alone suffices.

Evidence was recaptured from immutable `bin/C-v1-upstream-only` after a binary-stability assertion caught the build path being replaced by C-v2; no mismatched artifact was written. Its SHA-256 matches the C-v1 build receipt. Exact commands and disassembly are in `codegen-C-v1.json`. No target execution, build, attachment, or profile was performed for this inspection.
