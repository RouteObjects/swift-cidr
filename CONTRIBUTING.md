# Contributing to swift-cidr

Thank you for considering a contribution to `swift-cidr`.

`swift-cidr` is a type-driven CIDR math library. Contributions should preserve
the library's main goal: small, value-semantic Swift types that model IP
addresses, prefix lengths, network boundaries, delegated blocks, endpoints, and
multicast group ranges without collapsing those meanings into strings or
POSIX-shaped buffers.

## Contribution Workflow

For significant changes, please open an issue in the project repository before
starting implementation. This helps align the change with the library's design
goals before code is written. Small bug fixes, documentation corrections, and
test-only improvements may go directly to a pull request.

When opening a pull request, include:

- the problem being solved
- a summary of the behavior or API change
- relevant RFC or IANA registry references, when applicable
- test evidence
- benchmark evidence for performance-sensitive changes
- DocC or learning-document updates for public API or terminology changes

Draft pull requests are welcome when early design feedback would reduce rework.

## Core Principles

### 1. Standards and Terminology Matter

The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

Behavior tied to Internet standards or registries MUST cite the relevant
document or registry section in the pull request. Contributors are expected to
read the standard they are implementing or changing.

Common references for this package include:

- [RFC 791](https://datatracker.ietf.org/doc/html/rfc791): IPv4 addressing
- [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291): IPv6 addressing
  architecture and IPv6 text forms
- [RFC 4632](https://datatracker.ietf.org/doc/html/rfc4632): CIDR address
  strategy, aggregation, allocation, and assignment terminology
- [RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952): canonical IPv6
  text representation
- [RFC 2622](https://datatracker.ietf.org/doc/html/rfc2622): RPSL prefix-range
  operators
- [RFC 6308](https://datatracker.ietf.org/doc/html/rfc6308): multicast address
  allocation and assignment architecture
- [IANA Address Family Numbers](https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml)
- [IANA Service Name and Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)
- [IANA IPv4 Multicast Address Space Registry](https://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml)
- [IANA IPv6 Multicast Address Space Registry](https://www.iana.org/assignments/ipv6-multicast-addresses/ipv6-multicast-addresses.xhtml)

### 2. Preserve the Type Model

`swift-cidr` uses distinct types because CIDR-looking values do not all mean the
same thing.

- `IPAddress<Family>` represents an address with prefix context.
- `IPNetwork<Family>` represents a canonical network boundary.
- `CIDRBlock<Family>` represents neutral CIDR range math, such as delegated or
  allocated address space.
- `InterfaceAddress<Family>` represents interface configuration context.
- `IPEndpoint<Family>` represents an address plus transport port.
- `IPMulticastGroup<Family>` and `IPMulticastGroupRange<Family>` represent
  multicast destination identifiers and multicast group-address ranges.

Do not collapse these meanings into one generic container unless the design has
been discussed and accepted. A contribution that makes the API easier by
removing semantic distinctions is likely to be rejected.

### 3. Keep Math, Policy, and Adapters Separate

The core `CIDR` module models typed CIDR math. It should not become an IPAM
database, routing policy engine, registry authority checker, socket wrapper, or
SwiftNIO dependency.

- Policy decisions, overlap rules, and authority-backed registry data belong in
  higher-level packages or applications.
- POSIX interop belongs in `CIDRPOSIX`.
- SwiftNIO interop belongs in the `CIDRNIO` target.
- Registry datasets belong in the registry package, not the core math module.

The core package should remain pure Swift, dependency-light, and value-semantic.

### 4. Design for Swift Currency Types

The public value types in this package are intended to be currency types:
compact values that can be stored, passed, compared, encoded, decoded, and
composed throughout Swift networking code.

Contributions SHOULD preserve:

- value semantics
- `Sendable` correctness where appropriate
- predictable parsing and formatting
- explicit IPv4 and IPv6 family boundaries
- mixed-family wrappers only at API boundaries that need runtime family choice
- clear DocC explaining public API semantics

## API Design and Naming

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

Names should reflect network meaning, not just implementation mechanics. Prefer
terms that match industry usage and existing library vocabulary: address,
prefix length, network, block, allocation, assignment, endpoint, multicast
group, and group range.

Avoid adding convenience APIs that blur the distinction between mathematical
CIDR context and operational context. For example, the core library can prove
that a subnet is inside a parent block; it should not claim that the subnet has
actually been assigned by an authority or is safe to allocate in a database.
Likewise, a `.broadcast` convenience belongs to an interface or subnet-use
context, not neutral CIDR math. The last address of a range is mathematical;
whether that address is a broadcast address depends on how the prefix is used.

## Code Quality and Testing

All source changes MUST include appropriate tests.

- New behavior MUST include unit tests.
- Bug fixes MUST include a regression test that fails before the fix and passes
  after.
- Public API changes SHOULD include DocC updates.
- Learning-document changes SHOULD reinforce correct networking terminology
  when they introduce or explain industry concepts.

Run the root test wrapper for normal verification:

```bash
./scripts/test.sh
```

The wrapper runs SwiftPM tests and adds the framework paths needed by standalone
Command Line Tools installations where plain `swift test` cannot locate
`Testing.framework`.

Run the Docker-based Linux validation before changes that affect portability,
POSIX interop, SwiftNIO adapters, package manifests, or release readiness:

```bash
./scripts/linux-test.sh
```

The Linux wrapper uses the official Swift Docker image and defaults to
`linux/amd64` for GitHub Actions parity. On Apple Silicon, contributors may use
`CIDR_LINUX_PLATFORM=linux/arm64 ./scripts/linux-test.sh` as a faster local
smoke test, but `linux/amd64` remains the closer CI match.

Documentation-only, comments-only, example-only, and learning-material changes
do not require benchmark evidence.

## Performance Requirements

Performance is part of the public contract for `swift-cidr`.

Benchmark evidence is REQUIRED for changes that affect parser paths, formatter
paths, currency-type operations, allocation behavior, low-level byte handling,
or other hot-path code. The benchmark result should show the same or better
performance, or no regression beyond configured thresholds.

From the repository root:

```bash
./scripts/benchmarks.sh build
./scripts/benchmarks.sh check
```

The default target, `CIDRBenchmarkTarget`, is the public/API-facing regression
suite. Parser-engine experiments that require benchmark SPI belong in
`CIDRParserExperimentBenchmarkTarget`:

```bash
CIDR_BENCHMARK_TARGET=CIDRParserExperimentBenchmarkTarget ./scripts/benchmarks.sh run
```

Use targeted benchmark runs when the change affects a specific area:

```bash
./scripts/benchmarks.sh run --filter '<benchmark-pattern>'
./scripts/benchmarks.sh check --filter '<benchmark-pattern>'
```

Use the CPU benchmark target for fixed-loop research and comparison work:

```bash
CIDR_BENCHMARK_TARGET=CIDRCPUBenchmarkTarget ./scripts/benchmarks.sh run
```

Linux benchmark target compilation can be checked without treating Docker
Desktop timings as authoritative performance evidence:

```bash
./scripts/linux-test.sh benchmark-build
```

This benchmark build mode installs the Linux `jemalloc` development headers
inside the ephemeral Docker container because `package-benchmark` uses them for
allocation metrics on Linux.

Threshold updates MUST be intentional and reviewed. If a change deliberately
trades performance for correctness, portability, or API clarity, explain that
tradeoff in the pull request.

The `currency.*` benchmark suite has a stricter expectation: currency-type
operations should remain at zero mallocs, zero object allocations, and zero ARC
traffic. Any nonzero allocation or ARC traffic in those benchmarks needs a clear
explanation and review.

## Commit Messages

Write clear commit messages in the imperative mood when practical, for example:

```text
Fix IPv6 parser rejection for malformed embedded IPv4 tails
```

The subject line should describe the change. Use the body for standards
references, migration notes, benchmark results, or design rationale when those
details matter.

## Review Criteria

Pull requests are reviewed for:

- standards correctness
- preservation of the type model
- separation of math, policy, and adapter concerns
- Swift API clarity
- tests and DocC coverage
- benchmark evidence when performance-sensitive code changes
- portability across supported Swift platforms

By following these guidelines, you help keep `swift-cidr` accurate, fast, and
useful as a foundation for Swift networking, server, routing, IPAM, and
configuration tools.
