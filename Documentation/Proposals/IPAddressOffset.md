# IPAddress offset exploration

**Status:** Ideas for future maintainer review. Neither API is approved or implemented.
**Captured:** October 8, 2026.

Explore an explicit way to change an address and its prefix context together. The
two ideas to retain are `struct IPAddressOffset` and
`x.offsetBy(address: 8, prefixLength: 8)`. Names, signatures, and failure behavior
remain open. This exploration is separate from the `IPAddress` equality repair.

## Current address movement

`IPAddress` equality includes both address bits and prefix length. Its existing
`Stride` is `Int128`; `distance(to:)` measures address bits, and `advanced(by:)`
preserves the starting prefix length. Advancement needs only a representable
result within the address family's range; it does not require a target value
with a matching prefix.

For a representable distance, the full-value round trip
`x.advanced(by: x.distance(to: y)) == y` succeeds when the prefix contexts match.
With different prefixes, advancement reaches the destination's address bits but
retains the starting context. That mixed-prefix limitation remains documented in
[IPAddress](../../Sources/CIDR/IPAddress.swift) and covered by the
[stride tests](../../Tests/CIDRTests/IPAddressStrideTests.swift).

## A reusable offset value

One candidate holds independent signed changes for the two components:

```swift
// Proposed shape only.
struct IPAddressOffset {
    let addressDelta: Int128
    let prefixLengthDelta: Int
}
```

An offset of `(addressDelta: 8, prefixLengthDelta: 8)` could transform
`192.0.2.1/24` into `192.0.2.9/32`. A future difference operation could calculate
both components between two same-family values, subject to representability.

## An explicit operation

A candidate convenience API makes both requested changes visible:

```swift
// Proposed call only; this API does not exist.
let x = IPv4Address("192.0.2.1/24")!
x.offsetBy(address: 8, prefixLength: 8)
// Intended successful result: 192.0.2.9/32
```

Here `prefixLength: 8` means add eight to the existing length, not replace it
with `/8`. The operation would preserve the resulting complete address bits;
computing the containing network would remain a separate projection. A failable
result is one option when either component leaves its valid range.

## Relationship to Strideable

Swift requires `Stride` to conform to `SignedNumeric` and `Comparable`.
`(Int128, Int)` cannot directly satisfy those requirements in the checked Swift
6.3.3 toolchain. A named composite stride would need coherent arithmetic,
including multiplication, integer literals, magnitude, and ordering. See the
[Swift standard-library definition](https://raw.githubusercontent.com/swiftlang/swift/main/stdlib/public/core/Stride.swift).

Replacing `Int128` would also affect callers that pass or expect that type, and
could make generic `stride(...)` operations change prefix context repeatedly.
An independent offset operation is a candidate that preserves existing striding.
It would not itself repair the mixed-prefix `Strideable` limitation.

## Questions for future review

- Which network-engineering or operations workflow needs a relative change to
  both components? Would an absolute prefix replacement better express it?
- Should the reusable offset and labeled convenience method both exist? Should
  the offset be family-independent or bound to an `IPAddressFamily`?
- Would `addressBy` and `prefixLengthBy` communicate relative deltas more clearly?
- Should invalid results return `nil` or throw an error identifying the failing
  component? Define rejection of address overflow/underflow and lengths outside
  IPv4 `0...32` or IPv6 `0...128`, without silent wrapping or clamping.
- Is a two-component difference operation useful? How should it report address
  separations that cannot fit in `Int128`?
- If offsets can be combined or applied repeatedly, what are their composition,
  overflow, and inversion rules?

Before adopting either API, work through IPv4 and IPv6 examples with positive,
negative, and zero deltas; prefix-only and address-only changes; network-boundary
crossing; both family endpoints; prefix-length limits; and signed-distance
limits. Verify full-value reconstruction where representable and confirm that
ordinary `advanced(by:)` continues to preserve prefix context.
