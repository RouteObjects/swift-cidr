//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
//
// Copyright (c) 2026 Craig A. Munro
//
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CIDR
import NIOCore

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

/// Errors thrown when bridging between `CIDR` endpoints and `NIOCore.SocketAddress`.
public enum NIOSocketAddressConversionError: Error, Sendable, Equatable {
    /// Unix domain sockets are outside the scope of the IP-only adapter.
    case unixDomainSocketUnsupported
    /// The provided socket address was not IPv4.
    case notIPv4SocketAddress
    /// The provided socket address was not IPv6.
    case notIPv6SocketAddress
    /// The IPv4 address is the first address of a prefixed range and is treated conservatively as
    /// the network boundary.
    case ipv4NetworkAddress(prefixLength: Int)
    /// The IPv4 address is the last address of a prefixed range and is treated conservatively as a
    /// directed-broadcast boundary.
    case ipv4DirectedBroadcastAddress(prefixLength: Int)
    /// The IPv6 socket address contains metadata that `IPEndpoint` does not model.
    case unsupportedIPv6Metadata(flowInfo: UInt32, scopeID: UInt32)
}

extension Port {
    public init?(nioPort: Int) {
        guard let rawValue = UInt16(exactly: nioPort) else { return nil }
        self.init(rawValue)
    }

    public var nioPort: Int { Int(rawValue) }
}

extension IPEndpoint where Family == AF.V4 {
    /// Creates a typed IPv4 endpoint from a `SocketAddress`.
    ///
    /// `SocketAddress` does not carry CIDR prefix context, so inbound IPv4 socket identities are
    /// materialized as `/32` addresses.
    public init(socketAddress: SocketAddress) throws {
        switch socketAddress {
        case .v4(let address):
            self.init(
                address: decodeIPv4SocketAddress(address.address.sin_addr),
                port: decodePort(fromNetworkByteOrder: address.address.sin_port)
            )
        case .v6:
            throw NIOSocketAddressConversionError.notIPv4SocketAddress
        case .unixDomainSocket:
            throw NIOSocketAddressConversionError.unixDomainSocketUnsupported
        }
    }

    /// Converts this endpoint into an IPv4 `SocketAddress`.
    ///
    /// This is a projection to socket identity. The stored address bits and port are preserved, but
    /// the CIDR prefix context is not representable in `SocketAddress` and is therefore not carried
    /// across the conversion.
    ///
    /// Prefixed IPv4 host addresses such as `192.0.2.1/24` are allowed. The adapter rejects only
    /// the first and last address of a prefixed IPv4 range, treating them conservatively as the
    /// network and directed-broadcast boundaries.
    public func makeSocketAddress() throws -> SocketAddress {
        try validateIPv4SocketProjection(address)

        var sockaddr = sockaddr_in()
        #if canImport(Darwin)
            sockaddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        sockaddr.sin_family = sa_family_t(AF_INET)
        sockaddr.sin_port = in_port_t(port.nioPort).bigEndian
        sockaddr.sin_addr = encodeIPv4SocketAddress(address)
        return SocketAddress(sockaddr)
    }
}

extension IPEndpoint where Family == AF.V6 {
    /// Creates a typed IPv6 endpoint from a `SocketAddress`.
    ///
    /// `SocketAddress` does not carry CIDR prefix context, so inbound IPv6 socket identities are
    /// materialized as `/128` addresses.
    public init(socketAddress: SocketAddress) throws {
        switch socketAddress {
        case .v4:
            throw NIOSocketAddressConversionError.notIPv6SocketAddress
        case .v6(let address):
            let sockaddr = address.address
            guard sockaddr.sin6_flowinfo == 0, sockaddr.sin6_scope_id == 0 else {
                throw NIOSocketAddressConversionError.unsupportedIPv6Metadata(
                    flowInfo: sockaddr.sin6_flowinfo,
                    scopeID: sockaddr.sin6_scope_id
                )
            }

            self.init(
                address: decodeIPv6SocketAddress(sockaddr.sin6_addr),
                port: decodePort(fromNetworkByteOrder: sockaddr.sin6_port)
            )
        case .unixDomainSocket:
            throw NIOSocketAddressConversionError.unixDomainSocketUnsupported
        }
    }

    /// Converts this endpoint into an IPv6 `SocketAddress`.
    ///
    /// This is a projection to socket identity. The stored address bits and port are preserved, but
    /// the CIDR prefix context is not representable in `SocketAddress` and is therefore not carried
    /// across the conversion.
    ///
    /// Unlike IPv4, no directed-broadcast boundary rule is applied here.
    public func makeSocketAddress() throws -> SocketAddress {
        var sockaddr = sockaddr_in6()
        #if canImport(Darwin)
            sockaddr.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        #endif
        sockaddr.sin6_family = sa_family_t(AF_INET6)
        sockaddr.sin6_port = in_port_t(port.nioPort).bigEndian
        sockaddr.sin6_flowinfo = 0
        sockaddr.sin6_scope_id = 0
        sockaddr.sin6_addr = encodeIPv6SocketAddress(address)
        return SocketAddress(sockaddr)
    }
}

extension SocketAddress {
    /// Creates an IPv4 `SocketAddress` by projecting a typed IPv4 endpoint to socket identity.
    public init(ipEndpoint: IPEndpoint<AF.V4>) throws {
        self = try ipEndpoint.makeSocketAddress()
    }

    /// Creates an IPv6 `SocketAddress` by projecting a typed IPv6 endpoint to socket identity.
    public init(ipEndpoint: IPEndpoint<AF.V6>) throws {
        self = try ipEndpoint.makeSocketAddress()
    }
}

extension AnyIPAddress {
    /// Creates a family-erased IP address from a `SocketAddress`.
    ///
    /// `SocketAddress` does not carry CIDR prefix context, so IPv4 socket identities are
    /// materialized as `/32` and IPv6 socket identities are materialized as `/128`.
    public init(socketAddress: SocketAddress) throws {
        // CHANGE: reuse the existing endpoint bridges so SocketAddress metadata validation stays centralized.
        switch socketAddress {
        case .v4:
            self = .v4(try IPEndpoint<AF.V4>(socketAddress: socketAddress).address)
        case .v6:
            self = .v6(try IPEndpoint<AF.V6>(socketAddress: socketAddress).address)
        case .unixDomainSocket:
            throw NIOSocketAddressConversionError.unixDomainSocketUnsupported
        }
    }
}

private func validateIPv4SocketProjection(_ address: IPAddress<AF.V4>) throws {
    guard address.prefixLength.intValue < AF.V4.bitWidth else { return }

    let network = address.network
    if address.address == network.first.address {
        throw NIOSocketAddressConversionError.ipv4NetworkAddress(
            prefixLength: address.prefixLength.intValue
        )
    }

    if address.address == network.last.address {
        throw NIOSocketAddressConversionError.ipv4DirectedBroadcastAddress(
            prefixLength: address.prefixLength.intValue
        )
    }
}

private func decodePort(fromNetworkByteOrder networkByteOrder: in_port_t) -> Port {
    let rawPort = Int(in_port_t(bigEndian: networkByteOrder))
    guard let port = Port(nioPort: rawPort) else {
        preconditionFailure("NIO SocketAddress produced an out-of-range port: \(rawPort)")
    }
    return port
}

private func decodeIPv4SocketAddress(_ address: in_addr) -> IPv4Address {
    #if canImport(Darwin)
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return IPv4Address(octets: copyIPv4Octets(from: address))
        }

        // CHANGE: preserve the existing integer bridge on Apple releases where InlineArray is unavailable.
        return IPv4Address(address: decodeIPv4IntegerFallback(address))
    #else
        return IPv4Address(octets: copyIPv4Octets(from: address))
    #endif
}

private func encodeIPv4SocketAddress(_ address: IPv4Address) -> in_addr {
    #if canImport(Darwin)
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return copyIPv4SocketAddress(from: address.octets)
        }

        // CHANGE: preserve the existing integer bridge on Apple releases where InlineArray is unavailable.
        return encodeIPv4IntegerFallback(address.address)
    #else
        return copyIPv4SocketAddress(from: address.octets)
    #endif
}

private func decodeIPv6SocketAddress(_ address: in6_addr) -> IPv6Address {
    #if canImport(Darwin)
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return IPv6Address(octets: copyIPv6Octets(from: address))
        }

        // CHANGE: preserve the existing integer bridge on Apple releases where InlineArray is unavailable.
        return IPv6Address(address: decodeIPv6IntegerFallback(address))
    #else
        return IPv6Address(octets: copyIPv6Octets(from: address))
    #endif
}

private func encodeIPv6SocketAddress(_ address: IPv6Address) -> in6_addr {
    #if canImport(Darwin)
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            return copyIPv6SocketAddress(from: address.octets)
        }

        // CHANGE: preserve the existing integer bridge on Apple releases where InlineArray is unavailable.
        return encodeIPv6IntegerFallback(address.address)
    #else
        return copyIPv6SocketAddress(from: address.octets)
    #endif
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private func copyIPv4Octets(from address: in_addr) -> InlineArray<4, UInt8> {
    var octets: InlineArray<4, UInt8> = [0, 0, 0, 0]

    // SAFETY: both scoped raw views contain exactly the four network-order address bytes.
    withUnsafeMutableBytes(of: &octets) { destination in
        withUnsafeBytes(of: address) { source in
            precondition(destination.count == 4 && source.count == destination.count)
            destination.copyBytes(from: source)
        }
    }

    return octets
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private func copyIPv4SocketAddress(from octets: InlineArray<4, UInt8>) -> in_addr {
    var address = in_addr()

    // SAFETY: both scoped raw views contain exactly the four network-order address bytes.
    withUnsafeMutableBytes(of: &address) { destination in
        withUnsafeBytes(of: octets) { source in
            precondition(destination.count == 4 && source.count == destination.count)
            destination.copyBytes(from: source)
        }
    }

    return address
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private func copyIPv6Octets(from address: in6_addr) -> InlineArray<16, UInt8> {
    var octets: InlineArray<16, UInt8> = [
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
    ]

    // SAFETY: both scoped raw views contain exactly the sixteen network-order address bytes.
    withUnsafeMutableBytes(of: &octets) { destination in
        withUnsafeBytes(of: address) { source in
            precondition(destination.count == 16 && source.count == destination.count)
            destination.copyBytes(from: source)
        }
    }

    return octets
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
private func copyIPv6SocketAddress(from octets: InlineArray<16, UInt8>) -> in6_addr {
    var address = in6_addr()

    // SAFETY: both scoped raw views contain exactly the sixteen network-order address bytes.
    withUnsafeMutableBytes(of: &address) { destination in
        withUnsafeBytes(of: octets) { source in
            precondition(destination.count == 16 && source.count == destination.count)
            destination.copyBytes(from: source)
        }
    }

    return address
}

private func decodeIPv4IntegerFallback(_ address: in_addr) -> UInt32 {
    address.s_addr.bigEndian
}

private func encodeIPv4IntegerFallback(_ address: UInt32) -> in_addr {
    var encoded = in_addr()
    encoded.s_addr = address.bigEndian
    return encoded
}

private func decodeIPv6IntegerFallback(_ address: in6_addr) -> UInt128 {
    // SAFETY: `in6_addr` is a fixed 16-byte POSIX value; the raw view is local to this closure.
    withUnsafeBytes(of: address) { rawBuffer in
        // in6_addr is 16 bytes in network byte order. Use an unaligned load because the
        // buffer is not guaranteed to have UInt128 alignment on every platform.
        UInt128(bigEndian: rawBuffer.loadUnaligned(fromByteOffset: 0, as: UInt128.self))
    }
}

private func encodeIPv6IntegerFallback(_ address: UInt128) -> in6_addr {
    var encoded = in6_addr()
    var value = address

    // SAFETY: `encoded` is a local fixed-size POSIX value, and the loop writes only within its raw bytes.
    withUnsafeMutableBytes(of: &encoded) { rawBuffer in
        for index in stride(from: rawBuffer.count - 1, through: 0, by: -1) {
            rawBuffer[index] = UInt8(truncatingIfNeeded: value)
            value >>= 8
        }
    }

    return encoded
}
