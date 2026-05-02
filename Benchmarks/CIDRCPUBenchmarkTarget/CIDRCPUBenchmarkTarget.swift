import Benchmark
import CIDR

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@inline(never)
private func systemInetPton6(_ string: String) -> CInt {
    var storage = in6_addr()
    return string.withCString { source in
        inet_pton(AF_INET6, source, &storage)
    }
}

@MainActor
let benchmarks = {
    func cpuConfiguration() -> Benchmark.Configuration {
        // Use fixed-loop user CPU measurements for batch performance analysis.
        .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    }

    let ipv6HostPrefix = IPv6PrefixLength(128)!
    let middleCompressedText = "2001:0db8:85a3::8a2e:0370:7334"

    let formatterIPv6MiddleCompressed2Storage: UInt128 = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    let formatterIPv6MiddleCompressedStorage: UInt128 =
        (UInt128(0x20010DB8) << 96)
        | (UInt128(0x85A3) << 80)
        | (UInt128(0x8A2E) << 32)
        | (UInt128(0x0370) << 16)
        | UInt128(0x7334)
    let formatterIPv6MaxStorage = UInt128.max
    let formatterIPv6LoopbackStorage = UInt128(1)
    let formatterIPv6AllZeroStorage = UInt128(0)

    let formatterIPv6MiddleCompressed2 = IPv6Address(
        address: formatterIPv6MiddleCompressed2Storage,
        prefixLength: ipv6HostPrefix
    )
    let formatterIPv6MiddleCompressed = IPv6Address(
        address: formatterIPv6MiddleCompressedStorage,
        prefixLength: ipv6HostPrefix
    )
    let formatterIPv6Max = IPv6Address(address: formatterIPv6MaxStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6Loopback = IPv6Address(address: formatterIPv6LoopbackStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6AllZero = IPv6Address(address: formatterIPv6AllZeroStorage, prefixLength: ipv6HostPrefix)

    Benchmark(
        "formatter.cpu.ipv6.compressed.swift.middleCompressed2.4M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<4_000_000 {
            blackHole(formatterIPv6MiddleCompressed2.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.swift.middleCompressed.4M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<4_000_000 {
            blackHole(formatterIPv6MiddleCompressed.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.swift.max.4M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<4_000_000 {
            blackHole(formatterIPv6Max.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.swift.loopback.10M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<10_000_000 {
            blackHole(formatterIPv6Loopback.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.swift.allZero.20M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<20_000_000 {
            blackHole(formatterIPv6AllZero.formatted(.compressed))
        }
    }

    Benchmark(
        "parser.cpu.ipv6.middleCompressed.3M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<3_000_000 {
            blackHole(AF.V6.parseAddress(middleCompressedText))
        }
    }

    Benchmark(
        "parser.cpu.ipv6.inet_pton.middleCompressed.3M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<3_000_000 {
            blackHole(systemInetPton6(middleCompressedText))
        }
    }
}
