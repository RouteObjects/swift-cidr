import Benchmark
@_spi(Benchmark) import CIDR

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

    func experimentConfiguration() -> Benchmark.Configuration {
        .init(
            metrics: metrics,
            tags: [:],
            warmupIterations: 3,
            scalingFactor: .kilo,
            maxDuration: .seconds(2)
        )
    }

    let ipv4AddressCIDR = "192.0.2.1/24"
    let ipv6AddressCIDR = "2001:db8::1/64"
    let ipv4MaxLengthCIDR = "255.255.255.255/32"
    let ipv6MaxLengthCIDR = "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"

    Benchmark(
        "parser.cidr.ipv4.scalar",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextScalar(ipv4AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv4.simdSlash",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextSIMDSlash(ipv4AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv4.suffix",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextSuffix(ipv4AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv4.scalar.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextScalar(ipv4MaxLengthCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv4.simdSlash.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextSIMDSlash(ipv4MaxLengthCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv4.suffix.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv4CIDRTextSuffix(ipv4MaxLengthCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.scalar",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextScalar(ipv6AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.simdSlash",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextSIMDSlash(ipv6AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.suffix",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextSuffix(ipv6AddressCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.scalar.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextScalar(ipv6MaxLengthCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.simdSlash.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextSIMDSlash(ipv6MaxLengthCIDR, requiresPrefix: false))
        }
    }

    Benchmark(
        "parser.cidr.ipv6.suffix.maxLength",
        configuration: experimentConfiguration()
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.parseIPv6CIDRTextSuffix(ipv6MaxLengthCIDR, requiresPrefix: false))
        }
    }
}
