# Conditional Swift 6.4 loads

This follow-up changes only the bodies of the two Span initializers and their
documentation. `#if compiler(>=6.4)` selects safe `RawSpan.load` into UInt32 or
UInt128, followed by explicit big-endian interpretation. Swift 6.2/6.3 retain
the fixed-index InlineArray delegation. Both branches share the exact-width
guard and preserve the caller's prefix and all address bits.

The package still declares Swift tools 6.2. Compiler selection, rather than the
manifest's minimum, selects the body. Availability remains Apple OS 26; the
newer OS 27 `ByteOrder` overload is not used. Defaults remain `.maximum`.

## Validation

- Swift 6.4.2/macOS ARM64: 17 focused tests passed in debug and release, executing
  the safe-load branch.
- Swift 6.2.4/Linux ARM64: 17 focused tests passed in debug and release, executing
  the indexed fallback.
- Existing parameterized tests cover exact lengths, offsets 0–31, every prefix,
  byte order, host bits, fixed-array parity, and owned-result lifetime.
- All four targets built at the macOS 15 and iOS 18 simulator deployment floors
  with Xcode 27.2. These are build checks, not older-OS runtime tests.
- Public-client probes passed `-strict-memory-safety -warnings-as-errors` for
  ARM64 and x86-64 macOS 15 targets with OS26-annotated APIs.

Logs are in this directory. The full 306-test suites and native timing results
in the parent report belong to the initial indexed implementation; this follow-up
reran the affected tests, deployment builds, and code-generation checks. Timing
benchmarks were not repeated, and no new timing improvement is claimed.

## Assembly comparison

The new [run-02-conditional](../codegen/run-02-conditional/metadata.json) compiles
the actual core module and the same six public-client roots used in `run-01`.
It records the measured source hashes and retains raw/demangled assembly and logs.
The final source removes the two `CHANGE:` prefixes from its explanatory comments
after validation. Restoring only those prefixes reproduces the measured source
hash; executable code is unchanged. The frozen run metadata is preserved.

- ARM64: the entire client assembly is byte-identical to `run-01`.
- x86-64: the explicit-prefix IPv6 root returns directly on success, removing
  the previous jump and eight-instruction result-reconciliation sequence.
  The explicit-prefix IPv4 root changes register allocation; the default IPv6
  failure path reorders two register-zeroing instructions. Other roots are unchanged.
- All roots remain call-free, without heap allocation calls, witness dispatch,
  metadata lookup, or indexing loops. Count guards precede all input loads.

x86-64 is cross-compiled evidence, not native Intel execution. Its simpler
result handling does not establish a runtime speedup.

The exact earlier source is retained at
[`snapshots/IPAddress+Octets-initial-indexed.swift`](../snapshots/IPAddress+Octets-initial-indexed.swift).
Its SHA-256 matches the original timing and assembly metadata. Original raw
evidence was not overwritten. Reproduction scripts always compile the selected
checkout; reproducing the initial snapshot requires its matching source.
