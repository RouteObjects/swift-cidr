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

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension IPAddress where Family == AF.V4 {
    /// Creates an IPv4 address from four network-byte-order octets.
    ///
    /// The octets contain address bits only, with the most-significant octet first. They do not
    /// carry prefix context. When `prefixLength` is omitted, the address receives `/32` context.
    ///
    /// - Parameters:
    ///   - octets: An owned, fixed-size projection of the IPv4 address bits in network byte order.
    ///   - prefixLength: The CIDR prefix context to associate with the address.
    @inlinable
    public init(
        octets: InlineArray<4, UInt8>,
        prefixLength: IPv4PrefixLength = .maximum
    ) {
        // Widen each octet before shifting so packing uses safe, fixed-width math.
        let address =
            (UInt32(octets[0]) << 24)
            | (UInt32(octets[1]) << 16)
            | (UInt32(octets[2]) << 8)
            | UInt32(octets[3])

        self.init(address: address, prefixLength: prefixLength)
    }

    /// The address bits as four network-byte-order octets.
    ///
    /// This owned projection contains only address bits, with the most-significant octet first.
    /// It does not include ``prefixLength`` or any scope information.
    @inlinable
    public var octets: InlineArray<4, UInt8> {
        [
            UInt8(truncatingIfNeeded: address >> 24),
            UInt8(truncatingIfNeeded: address >> 16),
            UInt8(truncatingIfNeeded: address >> 8),
            UInt8(truncatingIfNeeded: address),
        ]
    }
}

@available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
extension IPAddress where Family == AF.V6 {
    /// Creates an IPv6 address from sixteen network-byte-order octets.
    ///
    /// The octets contain address bits only, with the most-significant octet first. They do not
    /// carry prefix context or IPv6 scope. When `prefixLength` is omitted, the address receives
    /// `/128` context.
    ///
    /// - Parameters:
    ///   - octets: An owned, fixed-size projection of the IPv6 address bits in network byte order.
    ///   - prefixLength: The CIDR prefix context to associate with the address.
    @inlinable
    public init(
        octets: InlineArray<16, UInt8>,
        prefixLength: IPv6PrefixLength = .maximum
    ) {
        // Pack two UInt64 halves so every octet shift remains below 64 bits,
        // then widen and join them using the same shape as the IPv6 parser.
        let high =
            (UInt64(octets[0]) << 56)
            | (UInt64(octets[1]) << 48)
            | (UInt64(octets[2]) << 40)
            | (UInt64(octets[3]) << 32)
            | (UInt64(octets[4]) << 24)
            | (UInt64(octets[5]) << 16)
            | (UInt64(octets[6]) << 8)
            | UInt64(octets[7])
        let low =
            (UInt64(octets[8]) << 56)
            | (UInt64(octets[9]) << 48)
            | (UInt64(octets[10]) << 40)
            | (UInt64(octets[11]) << 32)
            | (UInt64(octets[12]) << 24)
            | (UInt64(octets[13]) << 16)
            | (UInt64(octets[14]) << 8)
            | UInt64(octets[15])
        let address = (UInt128(high) << 64) | UInt128(low)

        self.init(address: address, prefixLength: prefixLength)
    }

    /// The address bits as sixteen network-byte-order octets.
    ///
    /// This owned projection contains only address bits, with the most-significant octet first.
    /// It does not include ``prefixLength`` or IPv6 scope information.
    @inlinable
    public var octets: InlineArray<16, UInt8> {
        let high = UInt64(truncatingIfNeeded: address >> 64)
        let low = UInt64(truncatingIfNeeded: address)

        return [
            UInt8(truncatingIfNeeded: high >> 56),
            UInt8(truncatingIfNeeded: high >> 48),
            UInt8(truncatingIfNeeded: high >> 40),
            UInt8(truncatingIfNeeded: high >> 32),
            UInt8(truncatingIfNeeded: high >> 24),
            UInt8(truncatingIfNeeded: high >> 16),
            UInt8(truncatingIfNeeded: high >> 8),
            UInt8(truncatingIfNeeded: high),
            UInt8(truncatingIfNeeded: low >> 56),
            UInt8(truncatingIfNeeded: low >> 48),
            UInt8(truncatingIfNeeded: low >> 40),
            UInt8(truncatingIfNeeded: low >> 32),
            UInt8(truncatingIfNeeded: low >> 24),
            UInt8(truncatingIfNeeded: low >> 16),
            UInt8(truncatingIfNeeded: low >> 8),
            UInt8(truncatingIfNeeded: low),
        ]
    }
}
