# Internals

Notes for contributors and for people exploring this repository as **prior art** (including Swift Networking Workgroup experiments).  

**Public API contract:** depend only on documented public types. Internals may change without a semantic version major bump when they are not part of the public surface.

For *why* public types exist, see [DESIGN.md](DESIGN.md).

---

## 1. Public vs internal

| Layer | Examples | Stability |
|-------|----------|-----------|
| Public currency | `IPAddress`, `IPNetwork`, `PrefixLength`, `CIDRBlock`, … | Semantic versioning |
| Public adapters | `CIDRPOSIX`, `CIDRNIO` APIs | Semantic versioning |
| Internal helpers | UTF-8 writers, parse micro-helpers, mask utilities | May change |

---

## 2. Why some non-public pieces exist

### Formatting and parsing hot paths

| Area | Why |
|------|-----|
| Allocation-conscious UTF-8 formatting helpers | Infrastructure and CLI tools format many addresses/prefixes; avoiding intermediate `String` churn matters |
| Family-specific parse paths | IPv4 dotted-quad and IPv6 text forms differ; keep correctness and speed without a single slow generic parser |
| Network mask helpers on storage integers | Contiguous leading-one masks implement classless lengths efficiently |

These are **implementation machinery**, not currency types. Callers should use `LosslessStringConvertible`, span/text initializers, and public format APIs.

### Family markers (`AF.*`)

`AF.V4`, `AF.V6`, `AF.MAC48`, `AF.MAC64`, and `AF.ASN` are empty (or storage-associated) **marker types** that carry associated type metadata (width, parse/format). They exist so generic algorithms are **compile-time family-safe** instead of switching on runtime enums for every operation.

### Mixed-family enums (`AnyIP*`)

Exist for **API boundaries** (config files, multi-family ROA sets, “either v4 or v6” parameters). Core math stays on `Family`-bound types so algorithms are not full of dynamic casts.

---

## 3. Adapters and scoped IPv6

- **Core** `IPv6Address` is **128-bit identity only** (no zone).  
- **CIDRNIO** (and related paths) may **reject** non-zero `sin6_scope_id` / flowinfo when converting to bits-only types. That avoids silently dropping scope.  
- **Scoped IPv6** (`addr%zone`, RFC 4007) is planned as **host/context layer** composition (address + zone), alongside `IPEndpoint`—see [issue #10](https://github.com/RouteObjects/swift-cidr/issues/10) and [DESIGN.md §7](DESIGN.md).  

Do not treat MAC families as a substitute for zone identifiers.

---

## 4. Platform and representation notes

These document **this package’s choices** for explorers comparing designs—not a mandate for a future standard.

### Integer storage and InlineArray I/O

Addresses use **family-appropriate integer / fixed-width storage** suited to
masking, comparison, ordering, and generic bit operations. `IPv4Address` stores
`UInt32`; `IPv6Address` stores `UInt128`. Prefix context remains a separate part
of `IPAddress` identity, and `IPNetwork` continues to canonicalize with integer
mask operations.

`IPv4Address` and `IPv6Address` also expose `InlineArray<4, UInt8>` and
`InlineArray<16, UInt8>` as **I/O projections**. The arrays are owned values in
network byte order and contain address bits only. They do not contain prefix
length, perform network masking, or represent IPv6 scope. Constructing or
projecting octets is therefore an exact, allocation-free, text-free
interoperability boundary around the integer representation.

This adapter is deliberately not stored inside `IPAddress`, is not the basis of
equality or hashing, and is not added to `IPNetwork`. It also does not model a
borrowed view over another value's storage. A future workgroup `View` API may
share the same byte-level boundary while having different ownership and
lifetime semantics.

### Span vs scoped pointers

Hot parse/format paths currently favor **scoped pointer** techniques measured for this codebase.  

An experiment with **Span**-oriented APIs showed roughly **10–13% regression** on measured paths in one evaluation. That may reflect API usage or bridging cost rather than Span itself. Span remains a reasonable future direction; it is not required to rewrite stable hot paths without new measurements.

### Deployment targets

Core aims to stay **pure Swift** and usable across the platforms the package declares. Adapter modules pull in POSIX or NIO only when imported. Raising minimums for new language features is a **semver / ecosystem** decision—document tradeoffs when changing them.

### Performance testing

Benchmarks under `Benchmarks/` compare against system baselines (e.g. `inet_pton` / `inet_ntop`) where applicable. Prefer evidence over micro-optimizing unmeasured code.

---

## 5. Unsafe / unchecked usage

Some internal and performance-oriented paths use unchecked indexing or unsafe buffers after bounds have been established by construction or earlier validation.  

**Policy:** prefer safe APIs at the public boundary; confine unchecked work to verified hot loops; keep tests (including edge cases) around those paths. Fuzzing and extra hardening are welcome contributions.

---

## 6. What not to do

- Depend on underscored or file-private helpers from another package  
- Assume `IPEndpoint` will remain in the math module forever  
- Assume scoped addresses will be encoded only in the 128-bit value  
- Treat internal formatters as a stable serialization standard for interchange (use documented textual forms / Codable instead)  
