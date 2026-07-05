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
