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

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

import Testing
import CIDR
import CIDRNIO
import NIOCore

@Suite("CIDR NIO Adapter Tests")
struct CIDRNIOTests {
    @Test("Port nioPort conversion is lossless within UInt16 bounds")
    func portNIOConversion() {
        let port = Port(443)

        #expect(port.nioPort == 443)
        #expect(Port(nioPort: 0) == Port(0))
        #expect(Port(nioPort: 65535) == Port(65535))
        #expect(Port(nioPort: -1) == nil)
        #expect(Port(nioPort: 65536) == nil)
    }

    @Test("IPv4 ByteBuffer bridge round-trips")
    func ipv4ByteBufferBridge() throws {
        let original = try #require(IPv4Address("192.0.2.1"))
        var buffer = ByteBufferAllocator().buffer(capacity: MemoryLayout<UInt32>.size)

        original.write(to: &buffer)
        let decoded = try #require(IPAddress<V4>(from: &buffer))

        #expect(decoded.address == original.address)
        #expect(decoded.prefixLength.intValue == 32)
    }

    @Test("IPv6 ByteBuffer bridge round-trips")
    func ipv6ByteBufferBridge() throws {
        let original = try #require(IPv6Address("2001:db8:0:0:0:0:0:1"))
        var buffer = ByteBufferAllocator().buffer(capacity: MemoryLayout<UInt128>.size)

        original.write(to: &buffer)
        let decoded = try #require(IPAddress<V6>(from: &buffer))

        #expect(decoded.address == original.address)
        #expect(decoded.prefixLength.intValue == 128)
    }

    @Test("IPv6 compressed address literal writes directly to ByteBuffer")
    func ipv6CompressedAddressLiteralWritesToByteBuffer() throws {
        let address = try #require(IPv6Address("2001:db8:0:0:0:0:0:1/64"))
        var buffer = ByteBufferAllocator().buffer(capacity: 4)

        buffer.writeString("ip=")
        let written = address.writeCompressedAddressLiteral(to: &buffer)

        #expect(written == "2001:db8::1".utf8.count)
        #expect(buffer.readableBytes == "ip=2001:db8::1".utf8.count)
        #expect(buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) == "ip=2001:db8::1")
    }

    @Test("IPv6 compressed network literal writes the same bytes as formatted text")
    func ipv6CompressedNetworkLiteralMatchesFormattedText() throws {
        let address = try #require(IPv6Address("85a0:850a:8500:0:0:af:805a:85a"))
        let network = IPNetwork<V6>(host: address)
        var buffer = ByteBufferAllocator().buffer(capacity: 0)

        let written = network.writeCompressedAddressLiteral(to: &buffer)
        let formatted = network.formatted(.compressed)

        #expect(written == formatted.utf8.count)
        #expect(buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) == formatted)
    }

    @Test("IPv4 SocketAddress bridge round-trips host endpoints")
    func ipv4SocketAddressBridge() throws {
        let original = IPEndpoint(
            address: try #require(IPAddress<V4>("192.0.2.1")),
            port: Port(443)
        )

        let socketAddress = try SocketAddress(ipEndpoint: original)
        let roundTrip = try IPEndpoint<V4>(socketAddress: socketAddress)

        #expect(roundTrip == original)
    }

    @Test("Prefixed IPv4 host addresses project to SocketAddress and round-trip as /32")
    func ipv4PrefixedHostProjection() throws {
        let original = IPEndpoint(
            address: try #require(IPAddress<V4>("192.0.2.1/24")),
            port: Port(443)
        )

        let socketAddress = try SocketAddress(ipEndpoint: original)
        let roundTrip = try IPEndpoint<V4>(socketAddress: socketAddress)

        #expect(roundTrip.address.address == original.address.address)
        #expect(roundTrip.port == original.port)
        #expect(roundTrip.address.prefixLength.intValue == 32)
    }

    @Test("IPv6 SocketAddress bridge round-trips host endpoints")
    func ipv6SocketAddressBridge() throws {
        let original = IPEndpoint(
            address: try #require(IPAddress<V6>("2001:db8::1")),
            port: Port(853)
        )

        let socketAddress = try SocketAddress(ipEndpoint: original)
        let roundTrip = try IPEndpoint<V6>(socketAddress: socketAddress)

        #expect(roundTrip == original)
    }

    @Test("Prefixed IPv6 host addresses project to SocketAddress and round-trip as /128")
    func ipv6PrefixedHostProjection() throws {
        let endpoint = IPEndpoint(
            address: try #require(IPAddress<V6>("2001:db8::1/64")),
            port: Port(53)
        )

        let socketAddress = try SocketAddress(ipEndpoint: endpoint)
        let roundTrip = try IPEndpoint<V6>(socketAddress: socketAddress)

        #expect(roundTrip.address.address == endpoint.address.address)
        #expect(roundTrip.port == endpoint.port)
        #expect(roundTrip.address.prefixLength.intValue == 128)
    }

    @Test("IPv4 network boundary is rejected when creating a SocketAddress")
    func ipv4NetworkBoundaryRejection() throws {
        let endpoint = IPEndpoint(
            address: try #require(IPAddress<V4>("192.0.2.0/24")),
            port: Port(53)
        )

        do {
            _ = try endpoint.makeSocketAddress()
            Issue.record("Expected IPv4 network boundary conversion to throw.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .ipv4NetworkAddress(prefixLength: 24))
        }
    }

    @Test("IPv4 directed broadcast boundary is rejected when creating a SocketAddress")
    func ipv4DirectedBroadcastRejection() throws {
        let endpoint = IPEndpoint(
            address: try #require(IPAddress<V4>("192.0.2.255/24")),
            port: Port(53)
        )

        do {
            _ = try endpoint.makeSocketAddress()
            Issue.record("Expected IPv4 directed-broadcast conversion to throw.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .ipv4DirectedBroadcastAddress(prefixLength: 24))
        }
    }

    @Test("IPv4 endpoint initializer rejects IPv6 SocketAddress")
    func ipv4InitializerRejectsIPv6() throws {
        let socketAddress = try SocketAddress(ipAddress: "2001:db8::1", port: 443)

        do {
            _ = try IPEndpoint<V4>(socketAddress: socketAddress)
            Issue.record("Expected IPv4 endpoint initializer to reject IPv6 SocketAddress.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .notIPv4SocketAddress)
        }
    }

    @Test("IPv6 endpoint initializer rejects IPv4 SocketAddress")
    func ipv6InitializerRejectsIPv4() throws {
        let socketAddress = try SocketAddress(ipAddress: "192.0.2.1", port: 443)

        do {
            _ = try IPEndpoint<V6>(socketAddress: socketAddress)
            Issue.record("Expected IPv6 endpoint initializer to reject IPv4 SocketAddress.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .notIPv6SocketAddress)
        }
    }

    @Test("Unix domain sockets are rejected by endpoint initializers")
    func unixDomainSocketRejection() throws {
        let socketAddress = try SocketAddress(unixDomainSocketPath: "/tmp/cidr-nio.sock")

        do {
            _ = try IPEndpoint<V4>(socketAddress: socketAddress)
            Issue.record("Expected Unix domain socket conversion to throw.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .unixDomainSocketUnsupported)
        }
    }

    @Test("IPv6 scope ID metadata is rejected")
    func ipv6ScopeIDRejection() throws {
        let base = try SocketAddress(ipAddress: "2001:db8::1", port: 443)
        let socketAddress = try #require(mutatedIPv6SocketAddress(scopeID: 7, flowInfo: 0, basedOn: base))

        do {
            _ = try IPEndpoint<V6>(socketAddress: socketAddress)
            Issue.record("Expected IPv6 scope ID metadata to be rejected.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .unsupportedIPv6Metadata(flowInfo: 0, scopeID: 7))
        }
    }

    @Test("IPv6 flow info metadata is rejected")
    func ipv6FlowInfoRejection() throws {
        let base = try SocketAddress(ipAddress: "2001:db8::1", port: 443)
        let socketAddress = try #require(mutatedIPv6SocketAddress(scopeID: 0, flowInfo: 42, basedOn: base))

        do {
            _ = try IPEndpoint<V6>(socketAddress: socketAddress)
            Issue.record("Expected IPv6 flow info metadata to be rejected.")
        } catch let error as NIOSocketAddressConversionError {
            #expect(error == .unsupportedIPv6Metadata(flowInfo: 42, scopeID: 0))
        }
    }
}

private func mutatedIPv6SocketAddress(scopeID: UInt32, flowInfo: UInt32, basedOn base: SocketAddress) -> SocketAddress? {
    guard case .v6(let ipv6Address) = base else { return nil }

    var sockaddr = ipv6Address.address
    sockaddr.sin6_scope_id = scopeID
    sockaddr.sin6_flowinfo = flowInfo
    return SocketAddress(sockaddr)
}
