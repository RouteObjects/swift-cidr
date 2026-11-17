# Span octet construction — November 16, 2026

**Snapshot:** The tests and timings below describe the initial indexed
implementation. The subsequent Swift 6.4 conditional-load implementation has
[separate validation](conditional/README.md). Original timing and assembly
artifacts are preserved; they are not presented as fresh measurements of the
conditional implementation. Evidence scripts operate on the selected checkout.

Implemented on `codex/nwg-bridge`, based on `main` at
`5e4b3d2f881340a6ced05742429f1bd680dfd1e0`. The measured working tree adds
Swift 6.2-compatible, exact-width `Span<UInt8>` initializers to IPv4 and IPv6.
Source hashes in the native and code-generation metadata identify the measured
implementation; the base commit alone does not identify it.

The initially measured constructors validate the count, read an explicitly typed
fixed-size octet literal, and delegate to the existing constructor. Existing InlineArray code,
package dependencies, deployment floors, CI, and committed benchmark thresholds
are unchanged. `CIDRNetworkingTypes` remains a documentation-only proposal.

## Correctness and compatibility

| Compiler and environment | Focused debug / release | Full debug / release |
| --- | --- | --- |
| Apple Swift 6.4.2, native macOS ARM64 | 17 tests each | 306 tests in 34 suites each |
| Swift 6.2.4, Linux ARM64 container | 17 tests each | 306 tests in 34 suites each |

Parameterized cases cover exact-length rejection (0–32, 64, and 4096 bytes),
all offsets 0–31, every legal IPv4 and IPv6 prefix, independent endian fixtures,
zero/maximum values, mapped IPv6, host bits, fixed-array parity, and owned-result
lifetime. The reported test totals count test functions, not parameterized cases.

All four library targets (`CIDR`, `CIDRArgumentParser`, `CIDRPOSIX`, `CIDRNIO`)
built on Swift 6.2.4/Linux. With Xcode 27.2/Swift 6.4.2, all four also built at
the macOS 15 and iOS 18 simulator deployment floors. Those are deployment-target
builds, not runtime tests on macOS 15 or an iOS 18 simulator.

The README's network-order examples typechecked in Swift 6 language mode with
`-strict-memory-safety -warnings-as-errors` under both compilers. The future
upstream bridge example is a proposal, not a compiled dependency or tested bridge.

Logs and the extracted README examples are in `validation/`. Existing test
deprecation/unnecessary-`try` warnings and sandbox cache-write warnings did not
fail validation. `git diff --check` and an independent static review passed.

## Native timing observations

Machine: Apple M1 Max. Compiler: Apple Swift 6.4.2, Xcode 27.2. Release SwiftPM
build. Three independent suite invocations measured the six selected workloads,
with five warmup batches and a two-second budget per case. Every batch performs
1,000,000 iterations. No other task builds ran during the retained measurements;
thermal conditions, power state, and unrelated background activity were not controlled.

Each reported number is the median of the three per-run medians, after dividing
elapsed batch time by the iteration count. Samples are histogram-quantized batch
measurements, not individual-call latency observations or chronological samples.

| Workload | Median ns/iteration from batch means | Range of run medians | Measured batches in runs 1 / 2 / 3 |
| --- | ---: | ---: | --- |
| IPv4 Span, aligned | 1.979 | 1.977–1.982 | 1006 / 1009 / 1008 |
| IPv4 Span, offset 1 | 1.972 | 1.972–1.975 | 1010 / 1009 / 997 |
| IPv6 Span, aligned | 2.092 | 2.089–2.093 | 950 / 953 / 947 |
| IPv6 Span, offset 1 | 2.092 | 2.083–2.094 | 949 / 955 / 926 |
| Existing IPv4 InlineArray constructor | 1.930 | 1.924–1.930 | 1033 / 1017 / 1016 |
| Existing IPv6 InlineArray constructor | 1.926 | 1.924–1.929 | 1032 / 1029 / 1031 |

The new cases cycle 128 runtime address fields in 32-byte records. Fixture
allocation is outside measurement; setup verifies a 16-byte-aligned base.
Measured work includes record selection, exact-length slicing, construction,
and consuming the optional result. The existing controls use invariant owned
InlineArray operands and consume nonoptional results. These are different
workloads: their ratio is not a Span-versus-InlineArray speedup or regression.
These measurements do not establish BGP, PCAP, or application throughput.

Every measured allocation/ARC metric was zero at p50, p75, and p90. Object
allocations, retains, and releases were zero in all recorded batches. Exactly
one batch per case per run recorded one small malloc, in both existing controls
and new Span workloads. Its origin was not isolated; the data does not support
claiming that every measured batch had zero mallocs. The separate constructor
assembly contains no allocation calls.

`native-arm64/summary.json` contains per-run quantiles and counts.
`native-arm64/run-*/samples.json` bundles the original histogram-export headers
and integer sample values without changing units; wall-clock units are
nanoseconds per million-iteration batch. Quantiles use nearest rank. The metadata
records commands, compiler, host, source hashes, and measurement settings.
An initial JMH export omitted these cases because that format requires a
throughput metric; none of its output is used here. The retained runs use the
existing metric set and histogram sample export.

## Public-client code generation

The [separate code-generation report](codegen/README.md) compiles the actual core
module and public-only clients, targeting ARM64 and x86-64 macOS 15. All six
inspection roots are call-free, with no heap allocation, generic dispatch,
metadata lookup, or indexing loops. Dynamic count guards precede input reads;
explicit prefix bytes survive and default prefixes fold to 32/128.

The successful IPv4 data path uses ARM64 `ldr` + `rev`, or x86-64 `movl` +
`bswapl`. IPv6 uses ARM64 `ldp` + two `rev`, or two x86-64 loads plus two
`bswapq`. Complete functions also contain length checks and result handling.
The x86-64 evidence is cross-compiled assembly, not native Intel execution or
timing. This is fixed-size copying into an owned value, not zero-copy storage.

## Reproduction

From the repository root, with Xcode 27.2 selected:

```sh
./scripts/test.sh --disable-sandbox --disable-automatic-resolution --filter IPAddressOctetsTests
./scripts/test.sh --disable-sandbox --disable-automatic-resolution -c release --filter IPAddressOctetsTests
./scripts/test.sh --disable-sandbox --disable-automatic-resolution
./scripts/test.sh --disable-sandbox --disable-automatic-resolution -c release
python3 Benchmarks/Results/2026-11-16-span-octets/run-native.py --output /tmp/cidr-span-native-new-run
python3 Benchmarks/Results/2026-11-16-span-octets/codegen/run.py --output /tmp/cidr-span-codegen-new-run
```

Both evidence scripts require a new output directory. Native measurement needs
normal hardware/measurement access outside the task sandbox. `--disable-sandbox`
was necessary for nested SwiftPM tooling in this task environment.

Linux tests used the locally available official `swift:6.2.4-noble` image with
`--platform linux/arm64`, a read-only repository mount at `/workspace`, and a
dedicated Docker build-cache volume mounted at `/workspace/.build`. After the
pinned dependencies were fetched, all four test invocations ran with Docker
`--network none`, `swift test --disable-automatic-resolution`, and the same
filter/configuration choices above. Existing `Package.resolved` files were preserved.

Deployment builds used `MACOSX_DEPLOYMENT_TARGET=15.0` for each target and
`--triple arm64-apple-ios18.0-simulator --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"`
with an isolated scratch directory for iOS. The existing CI configuration was
not modified or dispatched as part of this local validation.
