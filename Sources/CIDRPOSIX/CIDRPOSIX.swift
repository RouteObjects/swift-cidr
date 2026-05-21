#if os(Linux)
import Glibc
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

import CIDR

public extension AF.V4 {
    static var posixValue: CInt { CInt(AF_INET) }
}

public extension AF.V6 {
    static var posixValue: CInt { CInt(AF_INET6) }
}

public extension IPAddress where Family == AF.V4 {
    init(sockaddr: sockaddr_in) {
        // sockaddr_in.sin_addr.s_addr is stored in network byte order.
        self.init(address: sockaddr.sin_addr.s_addr.bigEndian)
    }
}

public extension IPAddress where Family == AF.V6 {
    init(sockaddr: sockaddr_in6) {
        let address = withUnsafeBytes(of: sockaddr.sin6_addr) { rawBuffer -> UInt128 in
            // in6_addr is 16 bytes in network byte order. Use an unaligned load because the
            // buffer is not guaranteed to have UInt128 alignment on every platform.
            UInt128(bigEndian: rawBuffer.loadUnaligned(fromByteOffset: 0, as: UInt128.self))
        }

        self.init(address: address)
    }
}
