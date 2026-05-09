#if os(Linux)
import Glibc
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

import CIDR

/// POSIX socket interoperability for the IPv4 address family.
///
/// `CIDRPOSIX` keeps POSIX constants at the address-family boundary so callers can bridge between
/// Swift CIDR types and system socket APIs without losing the family-specific type information.
public extension AF.V4 {
    /// The POSIX `AF_INET` value for IPv4 sockets.
    ///
    /// Use this when constructing or inspecting POSIX socket structures that require the address
    /// family as a `CInt`.
    static var posixValue: CInt { CInt(AF_INET) }
}

/// POSIX socket interoperability for the IPv6 address family.
///
/// `CIDRPOSIX` keeps POSIX constants at the address-family boundary so callers can bridge between
/// Swift CIDR types and system socket APIs without losing the family-specific type information.
public extension AF.V6 {
    /// The POSIX `AF_INET6` value for IPv6 sockets.
    ///
    /// Use this when constructing or inspecting POSIX socket structures that require the address
    /// family as a `CInt`.
    static var posixValue: CInt { CInt(AF_INET6) }
}

public extension IPAddress where Family == AF.V4 {
    /// Creates an IPv4 address from a POSIX `sockaddr_in`.
    ///
    /// POSIX stores `sin_addr.s_addr` in network byte order. The initializer converts that value to
    /// the host-order storage used by `IPAddress<AF.V4>` and applies full-width `/32` prefix
    /// context.
    ///
    /// This initializer models only the address payload. It does not preserve or validate
    /// `sin_family`, port values, socket state, interface binding, or routing metadata.
    init(sockaddr: sockaddr_in) {
        // sockaddr_in.sin_addr.s_addr is stored in network byte order.
        self.init(address: sockaddr.sin_addr.s_addr.bigEndian)
    }
}

public extension IPAddress where Family == AF.V6 {
    /// Creates an IPv6 address from a POSIX `sockaddr_in6`.
    ///
    /// POSIX stores `sin6_addr` as 16 bytes in network byte order. The initializer decodes those
    /// bytes into the host-order `UInt128` storage used by `IPAddress<AF.V6>` and applies
    /// full-width `/128` prefix context.
    ///
    /// This initializer models only the address payload. It does not preserve or validate
    /// `sin6_family`, port values, flow information, scope ID, socket state, interface binding, or
    /// routing metadata.
    init(sockaddr: sockaddr_in6) {
        let address = withUnsafeBytes(of: sockaddr.sin6_addr) { rawBuffer -> UInt128 in
            // in6_addr is 16 bytes in network byte order. Use an unaligned load because the
            // buffer is not guaranteed to have UInt128 alignment on every platform.
            UInt128(bigEndian: rawBuffer.loadUnaligned(fromByteOffset: 0, as: UInt128.self))
        }

        self.init(address: address)
    }
}
