# Shared CIDR byte parsing exploration

**Status:** Future investigation; no implementation approved.
**Captured:** October 22, 2026.

Explore whether a shared internal byte-based helper can reduce repeated CIDR
delimiter and suffix handling while preserving custom-family behavior. This
follow-up is separate from the parsing-witness organization change. No helper,
digit-arithmetic change, or performance improvement is approved by this note.

## Current parsing paths

The IPv4 and IPv6 `parseAddress` and `parseCIDR` witnesses live beside their
family scanners in [AF+IPv4Parsing.swift](../../Sources/CIDR/AF+IPv4Parsing.swift)
and [AF+IPv6Parsing.swift](../../Sources/CIDR/AF+IPv6Parsing.swift). Built-in CIDR
parsing uses `String.withUTF8`, a bounded search for possible suffix slash
positions, and family-specific address scanners. The shared prefix-length lexer
receives a borrowed suffix-byte slice.

[IPAddressFamily.swift](../../Sources/CIDR/IPAddressFamily.swift) declares the
`IPAddressFamily.parseCIDR` requirement and supplies its compatible default for
custom families. That default finds the slash using `String` operations,
validates the suffix, and delegates address text to the family's existing
`parseAddress(String)` witness. IPv4 and IPv6 use their own witnesses instead of
this default.

[PrefixLength.swift](../../Sources/CIDR/PrefixLength.swift) owns the shared
textual prefix grammar. Its lexer accepts `0` or unpadded unsigned ASCII decimal
within the family range. It serves standalone lengths, the built-in parsers,
and the custom-family default.

## Candidate direction

Investigate a scoped UTF-8 helper for locating the address/suffix boundary and
validating the suffix. Determine which work is useful to share without replacing
the family-specific address scanners or imposing their syntax on custom families.
The helper's shape, ownership, and callers remain open.

The existing `parseAddress(String)` requirement may still need a `String` at a
custom-family boundary. `withUTF8` can also materialize contiguous storage for
some strings. Borrowing suffix bytes therefore does not establish that an entire
parsing operation is allocation-free.

## Behavior to preserve

- Keep custom-family address spelling and delegation to that family's
  `parseAddress`. Do not assume that custom addresses use IPv4 or IPv6 syntax,
  have an ASCII-only alphabet, or fit built-in address-length limits.
- Preserve `.compatible` support in the default witness and its rejection of
  `.strict` unless the custom family supplies a policy-aware implementation.
- Preserve required and optional prefix handling, the family maximum when
  context is omitted, and the shared prefix grammar and range checks.
- Compare behavior for Unicode address text and delimiter-adjacent combining
  characters before replacing `String` delimiter handling with byte searches.
  Do not silently accept or reject new custom-family spellings.
- Preserve rejection of empty CIDR-qualified addresses and invalid suffixes,
  including empty text, extra separators, padding, signs, whitespace, non-ASCII
  digits, and oversized numbers. Keep address-only acceptance delegated to the
  family's existing parser.
- Keep borrowed buffers and derived slices within their valid lifetimes. Retain
  explicit bounds checks and avoid escaping pointers from scoped closures.
- Preserve concrete and generic dispatch, returned address bits and prefix
  context, and the compatible/strict rules for IPv4 and IPv6 dotted tails.

## Evidence before an implementation decision

First establish behavioral parity using the existing
[parsing-policy tests](../../Tests/CIDRTests/IPParsingPolicyTests.swift) and
[prefix-consistency tests](../../Tests/CIDRTests/PrefixParsingConsistencyTests.swift),
plus targeted custom-family and Unicode cases for any proposed byte helper.

Defer both the shared helper and changes to digit arithmetic until an experiment
has optimized-build benchmarks, allocation evidence, and generated-code
inspection. Compare representative accepted and rejected IPv4, IPv6, standalone
prefix, and custom-family inputs, including bridged or noncontiguous strings
where relevant. Record toolchains, build modes, platforms, and input corpora.

Check generic dispatch, specialization and inlining, actual allocation behavior,
and overflow/bounds safety rather than inferring them from pointer-oriented
source. Evaluate wrapping subtraction and bit masking only with complete ASCII
digit validation. Any arithmetic, integer-width, or loop-shape change must retain
the grammar and demonstrate a useful benefit before adoption. Keep performance
conclusions limited to the measured configurations.
