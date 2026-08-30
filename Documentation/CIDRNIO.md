# CIDRNIO

`CIDRNIO` is the optional SwiftNIO adapter module in `swift-cidr`. It keeps the
core `CIDR` target free of `NIOCore` imports while adding strict adapters for
server-side Swift code that already uses SwiftNIO.

The module currently provides:

- `IPAddress` <-> `ByteBuffer` bridges for packed IPv4 and IPv6 values.
- Direct IPv6 address-literal formatting into `ByteBuffer`.
- `IPEndpoint` <-> `SocketAddress` bridges using explicit socket-identity
  projection rules.
- `AnyIPAddress` construction from `SocketAddress` for mixed-family admission
  and policy code.

`CIDRNIO` is intentionally strict. It rejects conversions that would silently
ignore IPv4 network or directed-broadcast boundaries, or IPv6 socket metadata
such as `sin6_flowinfo` and `sin6_scope_id`.

## Package Dependency

Add the `CIDRNIO` product only to targets that need SwiftNIO adapters:

```swift
.product(name: "CIDR", package: "swift-cidr"),
.product(name: "CIDRNIO", package: "swift-cidr"),
```

Then import the adapter explicitly:

```swift
import CIDR
import CIDRNIO
import NIOCore
```

## Endpoint To SocketAddress

```swift
import CIDR
import CIDRNIO
import NIOCore

if let address = IPv4Address("192.0.2.10/24") {
    let endpoint = IPEndpoint(
        address: address,
        port: Port(443)
    )

    let socketAddress = try SocketAddress(ipEndpoint: endpoint)
}
```

## SocketAddress Back To Typed IPEndpoint

```swift
import CIDR
import CIDRNIO
import NIOCore

let socketAddress = try SocketAddress(ipAddress: "2001:db8::1", port: 853)
let endpoint = try IPEndpoint<V6>(socketAddress: socketAddress)

print(endpoint.description)
// [2001:db8::1/128]:853
```

`SocketAddress` does not carry CIDR prefix context. Outbound conversion
therefore projects only address bits plus port, and inbound conversion
materializes `/32` for IPv4 or `/128` for IPv6.

## Socket Address Octets

On Linux and Apple OS 26 or later, the `SocketAddress` bridge uses
`IPv4Address.octets` and `IPv6Address.octets` as its address-byte boundary. The
network-byte-order bytes copied into `sin_addr` or `sin6_addr` are the same bytes
returned by the address's octet projection:

```swift
import CIDR
import CIDRNIO
import NIOCore

if let address = IPv4Address("192.0.2.1/24") {
    let endpoint = IPEndpoint(address: address, port: Port(443))
    let expected = address.octets
    let socketAddress = try SocketAddress(ipEndpoint: endpoint)

    if case .v4(let socketIPv4) = socketAddress {
        withUnsafeBytes(of: socketIPv4.address.sin_addr) { bytes in
            assert(bytes[0] == expected[0])
            assert(bytes[1] == expected[1])
            assert(bytes[2] == expected[2])
            assert(bytes[3] == expected[3])
        }
    }
}
```

The octets contain the address bits, including host bits, but do not contain the
`/24` prefix or any IPv6 scope. Converting the socket address back therefore
produces `/32` context, just as it did before the octet path was adopted.

The public conversion APIs retain their existing availability. On supported
pre-26 Apple deployments, a private integer network-byte-order implementation
preserves the same behavior because `InlineArray` is not back-deployed. The
`ByteBuffer` read/write APIs continue to use integer network-byte-order
operations on every platform.

`InlineArray` is a transient, owned value copied between the integer-backed
address and the POSIX socket field. It is not the literal storage of
`SocketAddress`, a zero-copy bridge, or a borrowed `View`. The octet projection
has allocation-free benchmark evidence, but SwiftNIO owns the resulting socket
storage; this documentation does not claim that constructing a complete
`SocketAddress` is allocation-free.

## SocketAddress To AnyIPAddress

```swift
import CIDR
import CIDRNIO
import NIOCore

let socketAddress = try SocketAddress(ipAddress: "192.0.2.10", port: 443)
let address = try AnyIPAddress(socketAddress: socketAddress)

print(address.description)
// 192.0.2.10/32
```

## Direct IPv6 Formatting To ByteBuffer

```swift
import CIDR
import CIDRNIO
import NIOCore

if let address = IPv6Address("2001:db8:0:0:0:0:0:1/64") {
    var buffer = ByteBufferAllocator().buffer(capacity: 39)

    address.writeCompressedAddressLiteral(to: &buffer)
    // buffer now contains "2001:db8::1"
}
```

## IPv4 Boundary Addresses Fail Explicitly

```swift
import CIDR
import CIDRNIO

if let address = IPv4Address("192.0.2.0/24") {
    let endpoint = IPEndpoint(
        address: address,
        port: Port(53)
    )

    do {
        _ = try endpoint.makeSocketAddress()
    } catch {
        // Handle NIOSocketAddressConversionError.ipv4NetworkAddress(prefixLength: 24).
    }
}
```
