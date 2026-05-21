#if os(Linux)
import Glibc
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

import Testing
import CIDR
import CIDRPOSIX

@Suite("CIDR POSIX Adapter Tests")
struct IPCorePOSIXTests {
    @Test("POSIX family constants are exposed by concrete adapter extensions")
    func posixFamilyValues() {
        #expect(AF.V4.posixValue == CInt(AF_INET))
        #expect(AF.V6.posixValue == CInt(AF_INET6))
    }

    @Test("IPv4 sockaddr bridge decodes network byte order")
    func ipv4SockaddrBridge() {
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = UInt32(0xC0000201).bigEndian

        let decoded = IPAddress<V4>(sockaddr: address)

        #expect(decoded.address == UInt32(0xC0000201))
        #expect(decoded.prefixLength.intValue == 32)
    }

    @Test("IPv6 sockaddr bridge preserves the full 128-bit address")
    func ipv6SockaddrBridge() throws {
        var address = sockaddr_in6()
        address.sin6_family = sa_family_t(AF_INET6)

        let bytes: [UInt8] = [
            0x20, 0x01, 0x0d, 0xb8,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x01,
        ]

        withUnsafeMutableBytes(of: &address.sin6_addr) { rawBuffer in
            rawBuffer.copyBytes(from: bytes)
        }

        let decoded = IPAddress<V6>(sockaddr: address)
        let expected = try #require(IPAddress<V6>.v6("2001:db8:0:0:0:0:0:1"))

        #expect(decoded.address == expected.address)
        #expect(decoded.prefixLength.intValue == 128)
    }
}
