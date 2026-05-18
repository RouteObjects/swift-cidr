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
import Benchmark
import CIDR
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@inline(never)
private func systemInetPton4(_ string: String) -> CInt {
    var storage = in_addr()
    return string.withCString { source in
        inet_pton(AF_INET, source, &storage)
    }
}

@inline(never)
private func systemInetPton6(_ string: String) -> CInt {
    var storage = in6_addr()
    return string.withCString { source in
        inet_pton(AF_INET6, source, &storage)
    }
}

@inline(never)
private func systemInetNtop4(_ address: UInt32) -> String {
    var storage = in_addr()
    storage.s_addr = address.bigEndian

    // SAFETY: `INET_ADDRSTRLEN` is the POSIX-required output capacity for `inet_ntop`.
    return withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(INET_ADDRSTRLEN)) { output in
        guard let baseAddress = output.baseAddress else { return "" }
        // SAFETY: `storage` is initialized above and remains alive for the duration of the C call.
        let result = withUnsafePointer(to: &storage) { source in
            inet_ntop(AF_INET, source, baseAddress, socklen_t(INET_ADDRSTRLEN))
        }

        guard let result else { return "" }
        return String(cString: result)
    }
}

@inline(never)
private func systemInetNtop6(_ address: UInt128) -> String {
    var storage = in6_addr()
    var networkOrder = address.bigEndian

    // SAFETY: Both values are local fixed-size address buffers and remain alive during the copy.
    withUnsafeMutableBytes(of: &storage) { destination in
        withUnsafeBytes(of: &networkOrder) { source in
            // Keep the platform baseline allocation-free before the required Swift String result.
            destination.copyMemory(from: source)
        }
    }

    // SAFETY: `INET6_ADDRSTRLEN` is the POSIX-required output capacity for `inet_ntop`.
    return withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(INET6_ADDRSTRLEN)) { output in
        guard let baseAddress = output.baseAddress else { return "" }
        // SAFETY: `storage` is initialized above and remains alive for the duration of the C call.
        let result = withUnsafePointer(to: &storage) { source in
            inet_ntop(AF_INET6, source, baseAddress, socklen_t(INET6_ADDRSTRLEN))
        }

        guard let result else { return "" }
        return String(cString: result)
    }
}

private func benchmarkPrefixLength<Family: IPAddressFamily>(_ value: Int) -> PrefixLength<Family> {
    guard let prefixLength = PrefixLength<Family>(value) else {
        preconditionFailure("Benchmark fixture uses invalid \(Family.familyName) prefix length \(value).")
    }

    return prefixLength
}

@MainActor
let benchmarks = {
    let parserMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountSmall,
        .mallocCountLarge,
        .mallocCountTotal,
        .objectAllocCount,
        .retainCount,
        .releaseCount,
        .retainReleaseDelta,
    ]

    let currencyMetrics: [BenchmarkMetric] = [
        .wallClock,
        .mallocCountSmall,
        .mallocCountLarge,
        .mallocCountTotal,
        .objectAllocCount,
        .retainCount,
        .releaseCount,
        .retainReleaseDelta,
    ]

    let formatterMetrics = parserMetrics

    let parserTimeThreshold = BenchmarkThresholds(relative: [.p90: 15.0])
    let parserCountThreshold = BenchmarkThresholds(relative: [.p90: 10.0])
    let parserDeltaThreshold = BenchmarkThresholds(absolute: [.p90: 0])

    let currencyTimeThreshold = BenchmarkThresholds(relative: [.p90: 20.0])
    let zeroCountThreshold = BenchmarkThresholds(
        absolute: [
            .p50: 0,
            .p75: 0,
            .p90: 0,
        ]
    )

    let parserThresholds: [BenchmarkMetric: BenchmarkThresholds] = [
        .wallClock: parserTimeThreshold,
        .mallocCountSmall: parserCountThreshold,
        .mallocCountLarge: parserCountThreshold,
        .mallocCountTotal: parserCountThreshold,
        .objectAllocCount: parserCountThreshold,
        .retainCount: parserCountThreshold,
        .releaseCount: parserCountThreshold,
        .retainReleaseDelta: parserDeltaThreshold,
    ]

    let currencyThresholds: [BenchmarkMetric: BenchmarkThresholds] = [
        .wallClock: currencyTimeThreshold,
        .mallocCountSmall: zeroCountThreshold,
        .mallocCountLarge: zeroCountThreshold,
        .mallocCountTotal: zeroCountThreshold,
        .objectAllocCount: zeroCountThreshold,
        .retainCount: zeroCountThreshold,
        .releaseCount: zeroCountThreshold,
        .retainReleaseDelta: zeroCountThreshold,
    ]

    let formatterThresholds = parserThresholds

    func parserConfiguration(tags _: [String: String] = [:]) -> Benchmark.Configuration {
        .init(
            metrics: parserMetrics,
            tags: [:], // package-benchmark threshold files are read back by target+name only, so benchmark tags must stay empty to keep threshold filenames discoverable.
            warmupIterations: 3,
            scalingFactor: .kilo,
            maxDuration: .seconds(2),
            thresholds: parserThresholds
        )
    }

    func formatterConfiguration(tags _: [String: String] = [:]) -> Benchmark.Configuration {
        .init(
            metrics: formatterMetrics,
            tags: [:], // keep formatter threshold filenames stable like parser and currency benchmarks.
            warmupIterations: 3,
            scalingFactor: .kilo,
            maxDuration: .seconds(2),
            thresholds: formatterThresholds
        )
    }

    func currencyConfiguration(tags _: [String: String] = [:]) -> Benchmark.Configuration {
        .init(
            metrics: currencyMetrics,
            tags: [:], // keep static threshold filenames stable and readable by `thresholds check`.
            warmupIterations: 5,
            scalingFactor: .mega,
            maxDuration: .seconds(2),
            thresholds: currencyThresholds
        )
    }

    let ipv4Simple = "192.168.1.1"
    let ipv4Edge = "255.255.255.255"
    let ipv6Simple = "2001:db8::1"
    let ipv6MiddleCompressed = "2001:db8:85a3::8a2e:370:7334"
    let ipv6Full = "2001:0db8:0000:0000:0000:ff00:0042:8329"
    let ipv6Mapped = "::ffff:192.0.2.1"
    let ipv4AddressCIDR = "192.0.2.1/24"
    let ipv6AddressCIDR = "2001:db8::1/64"
    let ipv4NetworkCIDR = "198.51.100.4/30"
    let ipv6NetworkCIDR = "2001:db8:1::/48"

    let ipv4Prefix: IPv4PrefixLength = benchmarkPrefixLength(24)
    let ipv6Prefix: IPv6PrefixLength = benchmarkPrefixLength(64)

    let ipv4HostStorage: UInt32 = 0xC0000201
    let ipv4CompareStorage: UInt32 = 0xC0000202
    let ipv6HostStorage = (UInt128(0x20010DB8) << 96) | 1
    let ipv6CompareStorage = (UInt128(0x20010DB8) << 96) | 2

    let ipv4Host = IPv4Address(address: ipv4HostStorage, prefixLength: ipv4Prefix)
    let ipv4Compare = IPv4Address(address: ipv4CompareStorage, prefixLength: ipv4Prefix)
    let ipv4Network = IPv4Network(address: ipv4Host, prefixLength: ipv4Prefix)

    let ipv6Host = IPv6Address(address: ipv6HostStorage, prefixLength: ipv6Prefix)
    let ipv6Compare = IPv6Address(address: ipv6CompareStorage, prefixLength: ipv6Prefix)
    let ipv6Network = IPv6Network(address: ipv6Host, prefixLength: ipv6Prefix)

    let formatterIPv4ZeroStorage: UInt32 = 0
    let formatterIPv4SimpleStorage: UInt32 = 0x01020304
    let formatterIPv4MixedStorage: UInt32 = 0xC0A80101
    let formatterIPv4MaxStorage = UInt32.max
    let formatterIPv4Zero = IPv4Address(address: formatterIPv4ZeroStorage)
    let formatterIPv4Simple = IPv4Address(address: formatterIPv4SimpleStorage)
    let formatterIPv4Mixed = IPv4Address(address: formatterIPv4MixedStorage)
    let formatterIPv4Max = IPv4Address(address: formatterIPv4MaxStorage)

    let ipv6HostPrefix = IPv6PrefixLength.maximum
    let formatterIPv6SimpleStorage = (UInt128(0x20010DB8) << 96) | 1
    let formatterIPv6MiddleCompressedStorage =
        (UInt128(0x20010DB8) << 96)
        | (UInt128(0x85A3) << 80)
        | (UInt128(0x8A2E) << 32)
        | (UInt128(0x0370) << 16)
        | UInt128(0x7334)
    let formatterIPv6TrailingCompressedStorage =
        (UInt128(0x20010DB8) << 96)
        | (UInt128(0x0001) << 80)
    let formatterIPv6LoopbackStorage = UInt128(1)
    let formatterIPv6AllZeroStorage = UInt128(0)
    let formatterIPv6MaxStorage = UInt128.max
    let formatterIPv6MappedHexStorage = (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)
    let formatterIPv6MiddleCompressed2Storage: UInt128 = 0x85a0_850a_8500_0000_0000_00af_805a_085a

    let formatterIPv6Simple = IPv6Address(address: formatterIPv6SimpleStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6MiddleCompressed = IPv6Address(address: formatterIPv6MiddleCompressedStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6TrailingCompressed = IPv6Address(address: formatterIPv6TrailingCompressedStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6Loopback = IPv6Address(address: formatterIPv6LoopbackStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6AllZero = IPv6Address(address: formatterIPv6AllZeroStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6Max = IPv6Address(address: formatterIPv6MaxStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6MappedHex = IPv6Address(address: formatterIPv6MappedHexStorage, prefixLength: ipv6HostPrefix)
    let formatterIPv6MiddleCompressed2 = IPv6Address(address: formatterIPv6MiddleCompressed2Storage, prefixLength: ipv6HostPrefix)

    let anyIPv4Address = AnyIPAddress(ipv4Host)
    let anyIPv4Network = AnyIPNetwork(ipv4Network)

    Benchmark(
        "parser.pton4v4.simple",
        configuration: parserConfiguration(tags: ["family": "v4", "variant": "simple"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V4.parseAddress(ipv4Simple)) // benchmark the production IPv4 parser through the public AddressFamily entry point.
        }
    }

    Benchmark(
        "parser.pton4v4.edge",
        configuration: parserConfiguration(tags: ["family": "v4", "variant": "edge"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V4.parseAddress(ipv4Edge))
        }
    }

    Benchmark(
        "parser.inet_pton4.simple",
        configuration: parserConfiguration(tags: ["family": "v4", "variant": "simple"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton4(ipv4Simple)) // include the platform IPv4 parser as a baseline system comparison for CIDR's IPv4 parser variants.
        }
    }

    Benchmark(
        "parser.inet_pton4.edge",
        configuration: parserConfiguration(tags: ["family": "v4", "variant": "edge"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton4(ipv4Edge))
        }
    }

    Benchmark(
        "parser.pton6v4.simple",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "simple"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V6.parseAddress(ipv6Simple))
        }
    }

    Benchmark(
        "parser.pton6v4.full",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "full"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V6.parseAddress(ipv6Full))
        }
    }

    Benchmark(
        "parser.pton6v4.middleCompressed",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "middleCompressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V6.parseAddress(ipv6MiddleCompressed))
        }
    }

    Benchmark(
        "parser.pton6v4.mapped",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "mapped"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AF.V6.parseAddress(ipv6Mapped))
        }
    }

    Benchmark(
        "parser.inet_pton6.simple",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "simple"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton6(ipv6Simple)) // include the platform IPv6 parser as a baseline system comparison for CIDR's IPv6 parser variants.
        }
    }

    Benchmark(
        "parser.inet_pton6.full",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "full"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton6(ipv6Full))
        }
    }

    Benchmark(
        "parser.inet_pton6.middleCompressed",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "middleCompressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton6(ipv6MiddleCompressed))
        }
    }

    Benchmark(
        "parser.inet_pton6.mapped",
        configuration: parserConfiguration(tags: ["family": "v6", "variant": "mapped"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetPton6(ipv6Mapped))
        }
    }

    Benchmark(
        "parser.cidr.ipAddress.v4",
        configuration: parserConfiguration(tags: ["family": "v4", "kind": "ipAddress"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv4Address(ipv4AddressCIDR))
        }
    }

    Benchmark(
        "parser.cidr.ipAddress.v6",
        configuration: parserConfiguration(tags: ["family": "v6", "kind": "ipAddress"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv6Address(ipv6AddressCIDR))
        }
    }

    Benchmark(
        "parser.cidr.ipNetwork.v4",
        configuration: parserConfiguration(tags: ["family": "v4", "kind": "ipNetwork"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv4Network(ipv4NetworkCIDR))
        }
    }

    Benchmark(
        "parser.cidr.ipNetwork.v6",
        configuration: parserConfiguration(tags: ["family": "v6", "kind": "ipNetwork"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv6Network(ipv6NetworkCIDR))
        }
    }

    Benchmark(
        "formatter.ipv4.swift.zero",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv4Zero.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.ipv4.inet_ntop.zero",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop4(formatterIPv4ZeroStorage))
        }
    }

    Benchmark(
        "formatter.ipv4.swift.simple",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv4Simple.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.ipv4.inet_ntop.simple",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop4(formatterIPv4SimpleStorage))
        }
    }

    Benchmark(
        "formatter.ipv4.swift.mixed",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv4Mixed.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.ipv4.inet_ntop.mixed",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop4(formatterIPv4MixedStorage))
        }
    }

    Benchmark(
        "formatter.ipv4.swift.max",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv4Max.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.ipv4.inet_ntop.max",
        configuration: formatterConfiguration(tags: ["family": "v4", "style": "addressOnly"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop4(formatterIPv4MaxStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.preferred.swift.simple",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "preferred"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6Simple.formatted(.preferred)) // Track the full IPv6 formatter separately from RFC 5952 compression.
        }
    }

    Benchmark(
        "formatter.ipv6.preferred.swift.middleCompressed",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "preferred"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MiddleCompressed.formatted(.preferred))
        }
    }

    Benchmark(
        "formatter.ipv6.preferred.swift.max",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "preferred"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6Max.formatted(.preferred))
        }
    }

    Benchmark(
        "formatter.ipv6.preferred.swift.middleCompressed2",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "preferred"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MiddleCompressed2.formatted(.preferred))
        }
    }

    Benchmark(
        "formatter.ipv6.ipv4Mapped.swift.mapped",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "ipv4Mapped"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MappedHex.formatted(.ipv4Mapped))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.simple",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6Simple.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.simple",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6SimpleStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.middleCompressed",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MiddleCompressed.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.max",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6Max.formatted(.compressed)) // Cover the no-compressible-zero-run compressed formatter path.
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.middleCompressed",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6MiddleCompressedStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.trailingCompressed",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6TrailingCompressed.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.trailingCompressed",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6TrailingCompressedStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.loopback",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6Loopback.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.loopback",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6LoopbackStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.allZero",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6AllZero.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.allZero",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6AllZeroStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.mappedHex",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MappedHex.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.mappedHex",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6MappedHexStorage))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.swift.middleCompressed2",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(formatterIPv6MiddleCompressed2.formatted(.compressed))
        }
    }

    Benchmark(
        "formatter.ipv6.compressed.inet_ntop.middleCompressed2",
        configuration: formatterConfiguration(tags: ["family": "v6", "style": "compressed"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(systemInetNtop6(formatterIPv6MiddleCompressed2Storage))
        }
    }

    Benchmark(
        "currency.prefixLength.v4.init",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "prefixLength"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv4PrefixLength(24))
        }
    }

    Benchmark(
        "currency.prefixLength.v6.init",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "prefixLength"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv6PrefixLength(64))
        }
    }

    Benchmark(
        "currency.ipAddress.v4.init",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "address"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv4Address(address: ipv4HostStorage, prefixLength: ipv4Prefix))
        }
    }

    Benchmark(
        "currency.ipAddress.v6.init",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "address"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv6Address(address: ipv6HostStorage, prefixLength: ipv6Prefix))
        }
    }

    Benchmark(
        "currency.ipNetwork.v4.init",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "network"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv4Network(address: ipv4Host, prefixLength: ipv4Prefix))
        }
    }

    Benchmark(
        "currency.ipNetwork.v6.init",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "network"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(IPv6Network(address: ipv6Host, prefixLength: ipv6Prefix))
        }
    }

    Benchmark(
        "currency.ipAddress.v4.network",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "projection"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv4Host.network)
        }
    }

    Benchmark(
        "currency.ipAddress.v6.network",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "projection"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv6Host.network)
        }
    }

    Benchmark(
        "currency.ipNetwork.v4.containsAddress",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "contains"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv4Network.contains(ipv4Host))
        }
    }

    Benchmark(
        "currency.ipNetwork.v6.containsAddress",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "contains"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv6Network.contains(ipv6Host))
        }
    }

    Benchmark(
        "currency.ipAddress.v4.compare",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "compare"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv4Host < ipv4Compare)
        }
    }

    Benchmark(
        "currency.ipAddress.v6.compare",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "compare"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ipv6Host < ipv6Compare)
        }
    }

    Benchmark(
        "currency.ipAddress.v4.hash",
        configuration: currencyConfiguration(tags: ["family": "v4", "kind": "hash"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(ipv4Host) // direct Hasher use measures the value-type hash path without Set/Dictionary allocation noise.
            blackHole(hasher.finalize())
        }
    }

    Benchmark(
        "currency.ipAddress.v6.hash",
        configuration: currencyConfiguration(tags: ["family": "v6", "kind": "hash"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            var hasher = Hasher()
            hasher.combine(ipv6Host)
            blackHole(hasher.finalize())
        }
    }

    Benchmark(
        "currency.anyIPAddress.wrap",
        configuration: currencyConfiguration(tags: ["family": "mixed", "kind": "wrap"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AnyIPAddress(ipv4Host))
        }
    }

    Benchmark(
        "currency.anyIPAddress.projection",
        configuration: currencyConfiguration(tags: ["family": "mixed", "kind": "projection"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(anyIPv4Address.v4?.address)
        }
    }

    Benchmark(
        "currency.anyIPNetwork.wrap",
        configuration: currencyConfiguration(tags: ["family": "mixed", "kind": "wrap"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AnyIPNetwork(ipv4Network))
        }
    }

    Benchmark(
        "currency.anyIPNetwork.containsAddress",
        configuration: currencyConfiguration(tags: ["family": "mixed", "kind": "contains"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(anyIPv4Network.contains(anyIPv4Address))
        }
    }

    Benchmark(
        "currency.anyPrefixLength.wrap",
        configuration: currencyConfiguration(tags: ["family": "mixed", "kind": "wrap"])
    ) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(AnyPrefixLength(ipv4Prefix))
        }
    }
}
