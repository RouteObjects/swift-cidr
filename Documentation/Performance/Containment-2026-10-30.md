# Downstream Typed Containment Investigation

## Outcome

Ordinary typed `IPNetwork.contains(address:)` calls can compile to direct integer
operations across the `CIDR` module boundary. Consumers do not need a faster
family-erased wrapper or IPv4/IPv6-specific containment APIs.

The candidate patch adds `@inlinable` to exactly three existing declarations:

- `IPPrefix.contains(address:)`
- `CIDR.mask`
- the internal `FixedWidthInteger.networkMask(for:)` helper

The expressions, validation, and containment semantics are unchanged. No new
`@inline(__always)`, underscored specialization attributes, concrete overloads,
or family-specific algorithms were added to the library. `PrefixLength`, its
comparators, and the address/network constructors did not require edits under
the tested compiler configurations.

This is a confirmed cross-module specialization gap in the tested 0.8.0 code,
not evidence identifying which historical OS, compiler, package, or call-site
change first exposed it.

## Controlled Comparison

Base: `cdc2e592beb9095875bc42fc4c269396b20d99e3` (`swift-cidr` 0.8.0).
Working branch: `perf/typed-prefix-containment`.

The [downstream package](../../Benchmarks/ContainmentClient/README.md) imports
public `CIDR` from a separate SwiftPM package. All four cases use identical
20,000-network fixtures per family and alternate between last-network hits and
misses. There is no early exit; every scan checks every network. Parsing,
construction, and family erasure occur before timing. A checksum validates every
batch. The benchmark itself has no allocation/ARC instrumentation.

Within each platform/toolchain pair, source hashes establish that only the three
core files changed. Benchmark inputs/source, dependency pins, OS, hardware, and
compiler options stayed fixed. Builds used ordinary SwiftPM Release settings:
`-O`, whole-module optimization, and default cross-module optimization. No
unchecked optimization or consumer-side specialization was enabled.

Each process runs five warmup batches followed by 41 measured batches, with 25
scans per batch. Case order rotates each batch. After build completion, retained
binaries ran in baseline/patched/patched/baseline order, without overlapping
benchmark or build jobs. Results below pool the two corresponding runs:
**median of 82 batch means, in microseconds per complete 20,000-prefix scan**.
These are not individual-call latency percentiles or admission-policy timings.

| Native ARM64 environment | Family | Typed baseline | Typed patched | Erased patched |
| --- | --- | ---: | ---: | ---: |
| macOS, Apple Swift 6.3.3 | IPv4 | 3005.468 | 16.105 | 51.792 |
| macOS, Apple Swift 6.3.3 | IPv6 | 3027.168 | 25.792 | 51.888 |
| Linux, Swift 6.2.4 | IPv4 | 4826.843 | 17.673 | 46.492 |
| Linux, Swift 6.2.4 | IPv6 | 4838.941 | 29.657 | 53.238 |
| Linux, Swift 6.3.3 | IPv4 | 5302.804 | 16.447 | 53.490 |
| Linux, Swift 6.3.3 | IPv6 | 5295.598 | 26.950 | 52.877 |

The same snapshots were subsequently tested on `swift-dev`, a native x86-64
Linux LXC environment. The method and units are unchanged; each entry below is
also the median of 82 batch means in microseconds per 20,000-prefix scan.

| Native x86-64 environment | Family | Typed baseline | Typed patched | Erased patched |
| --- | --- | ---: | ---: | ---: |
| Linux, Swift 6.2.4 | IPv4 | 8497.630 | 53.535 | 170.543 |
| Linux, Swift 6.2.4 | IPv6 | 9173.805 | 128.438 | 198.028 |
| Linux, Swift 6.3.3 | IPv4 | 9434.601 | 53.499 | 195.994 |
| Linux, Swift 6.3.3 | IPv6 | 9051.389 | 135.821 | 224.013 |

The native x86-64 baseline varied between repeat processes. For example, the
Swift 6.2.4 IPv6 baseline run medians were 10467.146 and 7892.537 us; patched
run medians were 128.496 and 128.425 us. The raw runs are retained separately.
The pooled numbers demonstrate the large improvement, not a latency guarantee.

The erased control stayed approximately stable. The patched typed calls are
faster than the wrapper control on all five tested configurations. Do not
compare absolute times as an OS or architecture ranking: hardware, compiler,
runtime, and virtualization environments differ between these groups.

## Why These Three Annotations

The initial macOS baseline measured approximately 3.06/3.08 ms for IPv4/IPv6.
Making only `IPPrefix.contains(address:)` inlinable reduced both to about 1.33 ms.
The resulting assembly still called generic `CIDR.mask`. Making that property
and its internal mask helper inlinable reduced the initial typed scans to about
16.6/26.4 us. The later alternating runs confirmed the result in the table above.

Saved downstream ARM64 assembly on all three configurations shows:

- Baseline typed scans call the generic containment implementation.
- Entry-only macOS scans still call generic mask generation.
- Patched typed IPv4/IPv6 scan functions contain no `bl`/`blr` calls or external
  call relocations. They contain prefix-context comparisons, shifts, masks, and
  address comparisons directly, including the `/0` and valid-length checks.

The native x86-64 Swift 6.2.4 and 6.3.3 builds show the same result: the patched
typed IPv4/IPv6 scan functions contain no `call`/`callq` instructions or external
call relocations, while retaining the context, `/0`, and valid-length checks.

This fixes the compiled path, rather than changing its mathematical definition.
The generic fallback implementation remains available for other call sites.

`@inlinable` exposes a body to downstream optimization; it does not force the
optimizer to inline it. On an internal declaration it also makes that symbol
ABI-public without making it a public source API. The mask helper therefore
acquires an ABI maintenance obligation. Keep that exposure narrow; clients must
rebuild to benefit from new inlined bodies. See Swift's
[cross-module inlining and specialization design](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0193-cross-module-inlining-and-specialization.md).

## Semantic Validation

All **269 tests in 29 suites** passed on:

- macOS Apple Swift 6.3.3, Debug and Release.
- Native ARM64 Linux Swift 6.2.4, Release.
- Native ARM64 Linux Swift 6.3.3, Release.
- Native x86-64 Linux Swift 6.2.4, Debug and Release.
- Native x86-64 Linux Swift 6.3.3, Debug and Release.

The three new tests use public `CIDR` imports and cover every valid IPv4/IPv6
network prefix length crossed with every valid candidate prefix context. Fixtures
include zero, maximum and alternating bits; canonical endpoints; host bits; and
addresses immediately outside each representable boundary. An independent
high-bit-shift oracle checks typed and erased containment. Mixed-family `/0`
checks remain false. Existing traversal, range, subnet, summarization, and
adapter tests also passed.

In particular, an address whose bits match but whose prefix context is broader
than the network is still rejected. This patch does not replace hierarchical
containment with address-bits-only containment.

## Environment And Limits

- Apple M1 Max, 10 logical CPUs, 64 GiB RAM, macOS 26.7.1 (25G241).
- Xcode 26.6, Apple Swift 6.3.3, macOS 15 deployment target.
- Native ARM64 Linux in OrbStack, kernel `7.2.12-orbstack-00394-gbecdd6130068`.
- Pinned official `swift:6.2.4-noble` image ID
  `sha256:e508ef1e4be68087f720de622b91cbf1e32799a7aa96134b35e6f1a1d656db7a`.
- Pinned official `swift:6.3.3-noble` image ID
  `sha256:1038d54c80063f5cdfabc4560990c30af64b5de8ebf28161deb22ca4ad5db866`.
- `swift-dev`: native x86-64 LXC, Ubuntu 24.04.5, kernel `6.14.8-2-pve`;
  Intel Xeon E5520 at 2.27 GHz, four allowed logical CPUs, 8 GiB RAM.
  Explicit installed Swift 6.2.4 and 6.3.3 paths selected per process; no default
  toolchain change, system installation, or existing project modification.
  Builds used `-j 4` and otherwise the same Release settings for each pair.
  Transferred source and lockfile hashes match the earlier snapshots.

Background host workload was not controlled. These measurements do not establish
production service throughput, tail-latency guarantees, compile-time savings, or
the speed of every possible prefix workload. They do not cover macOS Swift 6.2,
older macOS runtime compatibility, iOS, resilient binary-library builds, or
nondefault optimization settings. The existing Apple compatibility CI checks
remain pre-merge validation work.

During this containment investigation, the `swift-cidr-admission` checkout,
dependency pins, and original/historical benchmark captures were not modified.
Separate downstream admission experiments are outside this patch's scope and
are not a prerequisite for landing the containment fix. The numbers above
measure only containment scans, not end-to-end admission decisions.

## Commit Readiness Review

The final local review on October 30, 2026 confirmed:

- The current source, tests, benchmark, and dependency pins match the recorded
  patched-source hashes. Both original evidence bundles pass checksum validation.
- All 269 tests in 29 suites pass again in Debug and Release on macOS with
  Apple Swift 6.3.3 and Xcode 26.6.
- All four library targets build for `arm64-apple-ios18.0-simulator` using the
  Xcode 26.6 SDK. This is a compile check, not iOS runtime validation.
- The downstream Release benchmark builds and completes all four cases, with
  41 measured batches per case and all 164 batch checksums correct. This smoke
  run is separate from the historical performance measurements above.
- GitHub `main` still points to the tested base commit `cdc2e59`; the production
  patch remains exactly three annotations and explanatory comments.

The existing GitHub Actions checks should pass before merge, including the
macOS 15 / Xcode 26.3 compatibility job that cannot be reproduced on this
macOS 26 host. No dependency, deployment-target, or CI configuration changes
are needed for this patch. The separate admission experiments remain untouched.

## Evidence And Review

[Evidence directory](../../Benchmarks/ContainmentClient/Results/2026-10-30/) contains
raw CSV samples, pooled summaries, exact commands with exit codes, compressed
build/test/disassembly logs, extracted scan assembly, source hashes, stage
patches (`*.patch.gz`), environment information, and SHA-256 checksums. The capture driver is
archival and contains this machine's paths; the portable benchmark invocation is
in the downstream package README.

The separate [native x86-64 evidence directory](../../Benchmarks/ContainmentClient/Results/2026-10-30-x86_64/)
adds eight timing captures, native assembly, full test logs, transferred-source
hash verification, compiler binary hashes, host metadata, exact commands, and
its own checksum manifest. The original ARM64 evidence bundle remains unchanged.
The isolated remote directory is `/tmp/cidr-containment-20261030.fPBtAc`;
no Git worktree or branch was created on the server.

`baseline` has no production edits; `entry-only` adds the containment annotation;
`mask-chain` is the final three-annotation patch. The saved initial Linux build
failure was a harness mount-name mistake (`/source` instead of a directory named
`swift-cidr`), corrected before any Linux measurement. No library change was
needed for that setup error.

The investigation was captured before staging, committing, or pushing. Review
the source patch independently of the generated evidence. To back out later, remove only these annotations and
their explanatory comments, then remove the new benchmark/test/report files
after preserving any wanted evidence. Do not reset unrelated work or the
separate admission benchmark branch.
