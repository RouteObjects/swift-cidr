import Benchmark
import CIDR
import CIDRNIO
import NIOCore

@MainActor
let benchmarks = {
    let metrics: [BenchmarkMetric] = [
        .throughput,
        .wallClock,
        .mallocCountSmall,
        .mallocCountLarge,
        .mallocCountTotal,
        .objectAllocCount,
        .retainCount,
        .releaseCount,
        .retainReleaseDelta,
    ]

    func adapterConfiguration() -> Benchmark.Configuration {
        .init(
            metrics: metrics,
            warmupIterations: 3,
            scalingFactor: .mega,
            maxDuration: .seconds(2)
        )
    }

    let allocator = ByteBufferAllocator()
    let ipv4Address = IPv4Address("192.0.2.1")!
    let ipv6Address = IPv6Address("2001:db8:0:0:0:0:0:1")!
    let ipv6CompressedAddress = IPv6Address("85a0:850a:8500:0:0:af:805a:85a")!
    let ipv4Endpoint = IPEndpoint(address: ipv4Address, port: TransportPort(443))
    let ipv6Endpoint = IPEndpoint(address: ipv6Address, port: TransportPort(853))
    let ipv4SocketAddress = try! SocketAddress(ipEndpoint: ipv4Endpoint)
    let ipv6SocketAddress = try! SocketAddress(ipEndpoint: ipv6Endpoint)

    var ipv4Template = allocator.buffer(capacity: MemoryLayout<UInt32>.size)
    ipv4Address.write(to: &ipv4Template)

    var ipv6Template = allocator.buffer(capacity: MemoryLayout<UInt128>.size)
    ipv6Address.write(to: &ipv6Template)

    Benchmark(
        "nio.byteBuffer.ipv4.write",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var buffer = allocator.buffer(capacity: MemoryLayout<UInt32>.size)
            ipv4Address.write(to: &buffer)
            blackHole(buffer.readableBytes)
        }
    }

    Benchmark(
        "nio.byteBuffer.ipv4.read",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var buffer = ipv4Template
            blackHole(IPAddress<V4>(from: &buffer))
        }
    }

    Benchmark(
        "nio.byteBuffer.ipv6.write",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var buffer = allocator.buffer(capacity: MemoryLayout<UInt128>.size)
            ipv6Address.write(to: &buffer)
            blackHole(buffer.readableBytes)
        }
    }

    Benchmark(
        "nio.byteBuffer.ipv6.read",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var buffer = ipv6Template
            blackHole(IPAddress<V6>(from: &buffer))
        }
    }

    Benchmark(
        "nio.formatter.ipv6.compressed.byteBuffer.middleCompressed2",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var buffer = allocator.buffer(capacity: 39)
            blackHole(ipv6CompressedAddress.writeCompressedAddressLiteral(to: &buffer))
        }
    }

    Benchmark(
        "nio.socketAddress.ipv4.endpointToSocketAddress",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! SocketAddress(ipEndpoint: ipv4Endpoint))
        }
    }

    Benchmark(
        "nio.socketAddress.ipv4.socketAddressToEndpoint",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! IPEndpoint<V4>(socketAddress: ipv4SocketAddress))
        }
    }

    Benchmark(
        "nio.socketAddress.ipv6.endpointToSocketAddress",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! SocketAddress(ipEndpoint: ipv6Endpoint))
        }
    }

    Benchmark(
        "nio.socketAddress.ipv6.socketAddressToEndpoint",
        configuration: adapterConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(try! IPEndpoint<V6>(socketAddress: ipv6SocketAddress))
        }
    }
}
