// Public-client probes: compile this separately from CIDR with optimization enabled.
import CIDR

@available(macOS 26.0, *)
@inline(never)
public func ipv4Span(
    _ octets: Span<UInt8>,
    prefixLength: IPv4PrefixLength
) -> (address: UInt32, prefixLength: UInt8)? {
    guard let address = IPv4Address(octets: octets, prefixLength: prefixLength) else {
        return nil
    }
    return (address.address, address.prefixLength.rawValue)
}

@available(macOS 26.0, *)
@inline(never)
public func ipv6Span(
    _ octets: Span<UInt8>,
    prefixLength: IPv6PrefixLength
) -> (address: UInt128, prefixLength: UInt8)? {
    guard let address = IPv6Address(octets: octets, prefixLength: prefixLength) else {
        return nil
    }
    return (address.address, address.prefixLength.rawValue)
}

@available(macOS 26.0, *)
@inline(never)
public func ipv4SpanDefault(_ octets: Span<UInt8>) -> (address: UInt32, prefixLength: UInt8)? {
    guard let address = IPv4Address(octets: octets) else { return nil }
    return (address.address, address.prefixLength.rawValue)
}

@available(macOS 26.0, *)
@inline(never)
public func ipv6SpanDefault(_ octets: Span<UInt8>) -> (address: UInt128, prefixLength: UInt8)? {
    guard let address = IPv6Address(octets: octets) else { return nil }
    return (address.address, address.prefixLength.rawValue)
}

@available(macOS 26.0, *)
@inline(never)
public func ipv4Inline(
    _ octets: InlineArray<4, UInt8>,
    prefixLength: IPv4PrefixLength
) -> (address: UInt32, prefixLength: UInt8) {
    let address = IPv4Address(octets: octets, prefixLength: prefixLength)
    return (address.address, address.prefixLength.rawValue)
}

@available(macOS 26.0, *)
@inline(never)
public func ipv6Inline(
    _ octets: InlineArray<16, UInt8>,
    prefixLength: IPv6PrefixLength
) -> (address: UInt128, prefixLength: UInt8) {
    let address = IPv6Address(octets: octets, prefixLength: prefixLength)
    return (address.address, address.prefixLength.rawValue)
}
