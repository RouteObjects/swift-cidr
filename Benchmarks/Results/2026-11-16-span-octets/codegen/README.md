# Span octet public-client code generation

`run-01` uses the actual `Sources/CIDR` implementation, compiled as a separate
module, and the public-only client in `Probe.swift`. It does not substitute a
standalone integer-packing model for the package API.

## Configuration

- Compiler: Apple Swift 6.4.2, Xcode 27.2; SDK: macOS 27.2.
- Targets: `arm64-apple-macosx15.0` and `x86_64-apple-macosx15.0`.
- CIDR: `-O -whole-module-optimization -cross-module-optimization`, without
  library evolution, compiled directly from all core source files.
- Client: separately compiled with `-O -strict-memory-safety -warnings-as-errors`.
  Its package identity differs from CIDR's; it imports public APIs only.
- The six inspection roots use `@inline(never)` to keep them visible. No probe
  forces the constructors or their helpers to inline.

Both architectures were compiled on an ARM64 Mac. This is assembly evidence;
the script executes neither target and records no timing measurements. In
particular, x86-64 is cross-compiled, not native Intel runtime validation. These
results do not establish code generation with the Swift 6.2 compiler, debug
builds, library evolution, or different optimization settings.

## Findings

All six public-client roots are call-free in both architectures. They contain no
heap-allocation calls, generic/witness dispatch, metadata lookup, or indexing
loops. Dynamic `Span` lengths retain an exact-count check before reading the
input. Wrong lengths select `nil` without loading any input bytes. Explicit
prefix bytes pass through to the result; omitted prefixes fold to 32 or 128.

| Conversion | ARM64 successful data read | x86-64 successful data read |
| --- | --- | --- |
| IPv4 Span | `ldr` + `rev` | `movl` + `bswapl` |
| IPv6 Span | `ldp` + two `rev` | two `movq` + two `bswapq` |

Those are only the address-loading operations. Count checks, prefix/result
packing, optional handling, and architecture-specific function bookkeeping are
also present. The complete IPv6 initializer is not one load plus one reversal.

The existing `InlineArray` overloads are controls. Their address bytes arrive in
registers and compile to byte reversals plus result/prefix handling, without
loops or allocations. This evidence supports adding a borrowed-input API; it
does not establish a speed improvement from rewriting the existing overloads.
The new API copies fixed address bytes into an owned value; it is allocation-free
in the inspected paths, not a zero-copy view over the original packet.

## Reproduction and artifacts

From the repository root, with the desired Xcode selected:

```sh
python3 Benchmarks/Results/2026-11-16-span-octets/codegen/run.py \
  --output /tmp/cidr-span-codegen-new-run
```

The output directory must not already exist. `--repo` can select another checkout
containing these APIs. The script discovers the selected compiler and SDK with
`xcrun`, uses an isolated temporary module/cache directory, and does not invoke
SwiftPM or change repository source.

`run-01/metadata.json` contains exact compiler commands with portable path
placeholders, the toolchain and target settings, Git HEAD, and SHA-256 hashes for
all 29 core source files, the client probe, and the reproduction script. The
measured source includes the working-tree Span initializer additions; HEAD alone
does not identify that snapshot. Raw and demangled assembly and successful build
logs are retained. `run-01/SHA256SUMS` covers every file in that run directory
except the checksum file itself.
