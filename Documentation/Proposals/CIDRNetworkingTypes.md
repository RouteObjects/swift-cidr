# CIDRNetworkingTypes bridge proposal

**Status:** Documented for future implementation; no bridge product, target, or
upstream dependency is included in swift-cidr.
**Captured:** November 16, 2026.
**Upstream reference:** [swift-networking-types PR #3](https://github.com/swiftlang/swift-networking-types/pull/3),
revision [`de280cb30e7c5a9295963af9a10472d1075212c6`](https://github.com/kpodosin/swift-networking-types/tree/de280cb30e7c5a9295963af9a10472d1075212c6).

## Purpose and compatibility

Introduce an opt-in `CIDRNetworkingTypes` module following the separation used
by `CIDRPOSIX` and `CIDRNIO`. Its dependencies would be `CIDR` and the upstream
`NetworkingTypes` product. The core `CIDR` target would remain dependency-free.

The referenced upstream API exposes owned network-order `bytes` as
`InlineArray<4, UInt8>` or `InlineArray<16, UInt8>`. CIDR's corresponding
`octets` projections and constructors provide the fixed-size conversion
boundary. The bridge copies address bytes between value representations; it
does not parse text, retain borrowed storage, or make the types share storage.

At the referenced revision, upstream requires Swift tools 6.4, while swift-cidr
retains Swift tools 6.2. An opt-in target alone would not establish that adding
this dependency preserves the root package's Swift 6.2 compatibility. Resolve
that toolchain policy before introducing a normal bridge product. Recheck the
upstream API, minimum tools version, and release status at implementation time;
the PR revision is a design reference, not a dependency pin in this package.

Both octet boundaries require macOS 26, iOS 26, tvOS 26, watchOS 26, or
visionOS 26 on Apple platforms. These proposed declarations use that same
availability. The bytes-based bridge avoids the newer availability requirement
of upstream's `ByteOrder` integer initializers.

## Conversion contract

- Preserve every address bit and the address family in both directions.
- Concrete inbound conversions accept `CIDR.IPv4PrefixLength` or
  `CIDR.IPv6PrefixLength`. Omitted context defaults to `.maximum`, meaning
  `/32` or `/128`. Explicit `/0` and all other legal prefix lengths are retained.
- Mixed-family inbound conversion assigns `/32` or `/128` to the selected
  family. Upstream's address value has no prefix context to recover.
- Outbound conversion discards prefix context. It preserves host bits rather
  than constructing a canonical network. For example, `192.0.2.129/24` becomes
  the upstream address `192.0.2.129`, not `192.0.2.0`.
- A complete CIDR value can round-trip only if its prefix is carried separately
  and explicitly supplied on the return conversion. Returning without that
  prefix produces host-length context.
- IPv4-mapped IPv6 remains IPv6. Do not infer scope, an interface, a subnet, or
  a multicast-specific type from the address bytes.

These six conversions are nonfailable because their fixed-size byte inputs
already establish the address width. CIDR's separate `Span<UInt8>` constructors
are failable because their input length is dynamic.

## Proposed API

The following source is a proposal only. It is not compiled into a product.
Fully qualified names keep the two libraries' address types and prefix context
unambiguous.

```swift
import CIDR
import NetworkingTypes

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension CIDR.IPv4Address {
    /// Copies address bits and attaches the caller's prefix context.
    @inlinable
    public init(
        _ address: NetworkingTypes.IPv4Address,
        prefixLength: CIDR.IPv4PrefixLength = .maximum
    ) {
        self.init(octets: address.bytes, prefixLength: prefixLength)
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension CIDR.IPv6Address {
    /// Copies address bits and attaches the caller's prefix context.
    @inlinable
    public init(
        _ address: NetworkingTypes.IPv6Address,
        prefixLength: CIDR.IPv6PrefixLength = .maximum
    ) {
        self.init(octets: address.bytes, prefixLength: prefixLength)
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension CIDR.AnyIPAddress {
    /// Copies the selected family and assigns host-length prefix context.
    @inlinable
    public init(_ address: NetworkingTypes.IPAddress) {
        switch address {
        case .v4(let value):
            self = .v4(CIDR.IPv4Address(value))
        case .v6(let value):
            self = .v6(CIDR.IPv6Address(value))
        }
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension NetworkingTypes.IPv4Address {
    /// Copies address bits, discarding CIDR prefix context.
    @inlinable
    public init(_ address: CIDR.IPv4Address) {
        self.init(bytes: address.octets)
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension NetworkingTypes.IPv6Address {
    /// Copies address bits, discarding CIDR prefix context.
    @inlinable
    public init(_ address: CIDR.IPv6Address) {
        self.init(bytes: address.octets)
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension NetworkingTypes.IPAddress {
    /// Copies the selected family and address bits, discarding CIDR prefix context.
    @inlinable
    public init(_ address: CIDR.AnyIPAddress) {
        switch address {
        case .v4(let value):
            self = .v4(NetworkingTypes.IPv4Address(value))
        case .v6(let value):
            self = .v6(NetworkingTypes.IPv6Address(value))
        }
    }
}
```

## Evidence required before implementation

Revalidate all six signatures against the selected upstream release or immutable
revision, including enum exhaustiveness, byte access, availability, and module
visibility. Test both families with zero, maximum, distinct-octet fixtures,
mapped IPv6, and every legal prefix context. Verify the distinction between an
address-bit round trip and a complete CIDR value round trip with an explicitly
restored prefix.

The fixed-size representation permits allocation-free copying, but the complete
bridge has not been measured. Inspect optimized cross-module clients and measure
allocations and representative conversion workloads before making performance
claims. `@inlinable` exposes the bridge body; it does not itself guarantee that
every upstream call disappears or that conversions take a fixed instruction count.
