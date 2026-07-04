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
private func systemInetPton6(_ string: String) -> CInt {
    var storage = in6_addr()
    return string.withCString { source in
        inet_pton(AF_INET6, source, &storage)
    }
}

private let asciiSlash = UInt8(ascii: "/")
private let asciiZero = UInt8(ascii: "0")
private let prefixLengthDecimalTriplets: StaticString =
    "000001002003004005006007008009010011012013014015016017018019020021022023024025026027028029030031032033034035036037038039040041042043044045046047048049050051052053054055056057058059060061062063064065066067068069070071072073074075076077078079080081082083084085086087088089090091092093094095096097098099100101102103104105106107108109110111112113114115116117118119120121122123124125126127128"

@inline(__always)
private func writeSlashPrefixLengthCurrentBenchmark(
    _ prefixLength: Int,
    into buffer: UnsafeMutableBufferPointer<UInt8>,
    at writeIndex: inout Int
) {
    buffer[writeIndex] = asciiSlash
    writeIndex &+= 1

    if prefixLength >= 100 {
        buffer[writeIndex] = asciiZero &+ UInt8(prefixLength / 100)
        buffer[writeIndex &+ 1] = asciiZero &+ UInt8((prefixLength / 10) % 10)
        buffer[writeIndex &+ 2] = asciiZero &+ UInt8(prefixLength % 10)
        writeIndex &+= 3
    } else if prefixLength >= 10 {
        buffer[writeIndex] = asciiZero &+ UInt8(prefixLength / 10)
        buffer[writeIndex &+ 1] = asciiZero &+ UInt8(prefixLength % 10)
        writeIndex &+= 2
    } else {
        buffer[writeIndex] = asciiZero &+ UInt8(prefixLength)
        writeIndex &+= 1
    }
}

@inline(__always)
private func writeSlashPrefixLengthTripletBenchmark(
    _ prefixLength: UInt8,
    into buffer: UnsafeMutableBufferPointer<UInt8>,
    at writeIndex: inout Int
) {
    buffer[writeIndex] = asciiSlash
    writeIndex &+= 1

    let offset = Int(prefixLength) &* 3
    let table = prefixLengthDecimalTriplets.utf8Start

    switch prefixLength {
    case 100...:
        buffer[writeIndex] = table[offset]
        buffer[writeIndex &+ 1] = table[offset &+ 1]
        buffer[writeIndex &+ 2] = table[offset &+ 2]
        writeIndex &+= 3
    case 10...:
        buffer[writeIndex] = table[offset &+ 1]
        buffer[writeIndex &+ 1] = table[offset &+ 2]
        writeIndex &+= 2
    default:
        buffer[writeIndex] = asciiZero &+ prefixLength
        writeIndex &+= 1
    }
}

@inline(never)
private func benchmarkSlashPrefixCurrent(_ prefixes: [UInt8], batches: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
    ) { buffer in
        for _ in 0..<batches {
            for prefix in prefixes {
                var writeIndex = 0
                writeSlashPrefixLengthCurrentBenchmark(Int(prefix), into: buffer, at: &writeIndex)
                blackHole(writeIndex)
                blackHole(buffer[0])
            }
        }
    }
}

@inline(never)
private func benchmarkSlashPrefixTriplet(_ prefixes: [UInt8], batches: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
    ) { buffer in
        for _ in 0..<batches {
            for prefix in prefixes {
                var writeIndex = 0
                writeSlashPrefixLengthTripletBenchmark(prefix, into: buffer, at: &writeIndex)
                blackHole(writeIndex)
                blackHole(buffer[0])
            }
        }
    }
}

@inline(never)
private func benchmarkRawIPv4AddressFormatter(_ address: IPv4Address, iterations: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumIPv4AddressLiteralUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let written = address.writeAddressLiteralUTF8(into: rawBuffer)
            blackHole(written)
            blackHole(buffer[0])
        }
    }
}

@inline(never)
private func benchmarkRawIPv4CIDRFormatter(_ address: IPv4Address, iterations: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let written = address.writeCIDRNotationUTF8(into: rawBuffer)
            blackHole(written)
            blackHole(buffer[0])
        }
    }
}

@inline(never)
private func benchmarkRawCompressedIPv6Formatter(_ address: IPv6Address, iterations: Int) {
    // Measure the UTF-8 writer directly so hextet extraction changes are not hidden by String allocation.
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6AddressLiteralUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let written = address.writeCompressedAddressLiteralUTF8(into: rawBuffer)
            blackHole(written)
            blackHole(buffer[0])
        }
    }
}

@inline(never)
private func benchmarkRawCompressedIPv6CIDRFormatter(_ address: IPv6Address, iterations: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let written = address.writeCompressedCIDRNotationUTF8(into: rawBuffer)
            blackHole(written)
            blackHole(buffer[0])
        }
    }
}

@inline(never)
private func benchmarkBulkIPv4CIDRStringFormatter(_ addresses: [IPv4Address], batches: Int) {
    for _ in 0..<batches {
        for address in addresses {
            let text = address.description
            blackHole(text.utf8.count)
            blackHole(text)
        }
    }
}

@inline(never)
private func benchmarkBulkIPv4CIDRRawFormatter(_ addresses: [IPv4Address], batches: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<batches {
            for address in addresses {
                let written = address.writeCIDRNotationUTF8(into: rawBuffer)
                blackHole(written)
                blackHole(buffer[0])
            }
        }
    }
}

@inline(never)
private func benchmarkBulkCompressedIPv6CIDRStringFormatter(_ addresses: [IPv6Address], batches: Int) {
    for _ in 0..<batches {
        for address in addresses {
            let text = "\(address.formatted(.compressed))/\(address.prefixLength)"
            blackHole(text.utf8.count)
            blackHole(text)
        }
    }
}

@inline(never)
private func benchmarkBulkCompressedIPv6CIDRRawFormatter(_ addresses: [IPv6Address], batches: Int) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<batches {
            for address in addresses {
                let written = address.writeCompressedCIDRNotationUTF8(into: rawBuffer)
                blackHole(written)
                blackHole(buffer[0])
            }
        }
    }
}

@inline(never)
private func benchmarkConcreteIPv4Descriptions(
    network: IPv4Network,
    block: CIDRBlock<AF.V4>,
    multicastRange: IPv4MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        let networkText = network.description
        let blockText = block.description
        let rangeText = multicastRange.description
        blackHole(networkText.utf8.count)
        blackHole(blockText.utf8.count)
        blackHole(rangeText.utf8.count)
    }
}

@inline(never)
private func benchmarkConcreteIPv4CIDRText(
    network: IPv4Network,
    block: CIDRBlock<AF.V4>,
    multicastRange: IPv4MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        blackHole(network.formatted(.cidrNotation))
        blackHole(block.formatted(.cidrNotation))
        blackHole(multicastRange.formatted(.cidrNotation))
    }
}

@inline(never)
private func benchmarkConcreteIPv4AddressOnly(
    network: IPv4Network,
    block: CIDRBlock<AF.V4>,
    multicastRange: IPv4MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        blackHole(network.formatted(.addressOnly))
        blackHole(block.formatted(.addressOnly))
        blackHole(multicastRange.formatted(.addressOnly))
    }
}

@inline(never)
private func benchmarkConcreteIPv4NetmaskStyle(
    network: IPv4Network,
    block: CIDRBlock<AF.V4>,
    multicastRange: IPv4MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        blackHole(network.formatted(.addressAndNetmask))
        blackHole(block.formatted(.addressAndNetmask))
        blackHole(multicastRange.formatted(.addressAndNetmask))
    }
}

@inline(never)
private func benchmarkConcreteIPv4RawCIDR(
    network: IPv4Network,
    block: CIDRBlock<AF.V4>,
    multicastRange: IPv4MulticastGroupRange,
    iterations: Int
) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumIPv4CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let networkWritten = network.writeCIDRNotationUTF8(into: rawBuffer)
            let blockWritten = block.writeCIDRNotationUTF8(into: rawBuffer)
            let rangeWritten = multicastRange.writeCIDRNotationUTF8(into: rawBuffer)
            blackHole(networkWritten)
            blackHole(blockWritten)
            blackHole(rangeWritten)
            blackHole(buffer[0])
        }
    }
}

@inline(never)
private func benchmarkConcreteIPv6Descriptions(
    network: IPv6Network,
    block: CIDRBlock<AF.V6>,
    multicastRange: IPv6MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        let networkText = network.description
        let blockText = block.description
        let rangeText = multicastRange.description
        blackHole(networkText.utf8.count)
        blackHole(blockText.utf8.count)
        blackHole(rangeText.utf8.count)
    }
}

@inline(never)
private func benchmarkConcreteIPv6CIDRText(
    network: IPv6Network,
    block: CIDRBlock<AF.V6>,
    multicastRange: IPv6MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        blackHole(network.formatted(.cidrNotation))
        blackHole(block.formatted(.cidrNotation))
        blackHole(multicastRange.formatted(.cidrNotation))
    }
}

@inline(never)
private func benchmarkConcreteIPv6CompressedStyle(
    network: IPv6Network,
    block: CIDRBlock<AF.V6>,
    multicastRange: IPv6MulticastGroupRange,
    iterations: Int
) {
    for _ in 0..<iterations {
        blackHole(network.formatted(.compressed))
        blackHole(block.formatted(.compressed))
        blackHole(multicastRange.formatted(.compressed))
    }
}

@inline(never)
private func benchmarkConcreteIPv6RawCIDR(
    network: IPv6Network,
    block: CIDRBlock<AF.V6>,
    multicastRange: IPv6MulticastGroupRange,
    iterations: Int
) {
    withUnsafeTemporaryAllocation(
        of: UInt8.self,
        capacity: CIDRUTF8Formatting.maximumCompressedIPv6CIDRNotationUTF8Count
    ) { buffer in
        let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

        for _ in 0..<iterations {
            let networkWritten = network.writeCompressedCIDRNotationUTF8(into: rawBuffer)
            let blockWritten = block.writeCompressedCIDRNotationUTF8(into: rawBuffer)
            let rangeWritten = multicastRange.writeCompressedCIDRNotationUTF8(into: rawBuffer)
            blackHole(networkWritten)
            blackHole(blockWritten)
            blackHole(rangeWritten)
            blackHole(buffer[0])
        }
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

    // Mirror fixed-loop IPv4 formatter cases so CPU comparisons are apples-to-apples.
    let formatterIPv4ZeroStorage: UInt32 = 0
    let formatterIPv4LoopbackStorage: UInt32 = 0x7F00_0001
    let formatterIPv4LocalBroadcastStorage = UInt32.max
    let formatterIPv4MixedStorage: UInt32 = 0x7B2D_0600
    let formatterIPv4Zero = IPv4Address(address: formatterIPv4ZeroStorage)
    let formatterIPv4Loopback = IPv4Address(address: formatterIPv4LoopbackStorage)
    let formatterIPv4LocalBroadcast = IPv4Address(address: formatterIPv4LocalBroadcastStorage)
    let formatterIPv4Mixed = IPv4Address(address: formatterIPv4MixedStorage)
    let formatterIPv4Mixed24 = IPv4Address(
        address: formatterIPv4MixedStorage,
        prefixLength: IPv4PrefixLength(24)!
    )
    let formatterIPv4NetworkMixed24 = IPv4Network(
        prefix: formatterIPv4MixedStorage,
        prefixLength: IPv4PrefixLength(24)!
    )
    let formatterIPv4BlockMixed24 = CIDRBlock<AF.V4>(
        prefix: formatterIPv4MixedStorage,
        prefixLength: IPv4PrefixLength(24)!
    )
    let formatterIPv4MulticastRange = IPv4MulticastGroupRange("239.1.2.0/24")!

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
    let formatterIPv6MiddleCompressed64 = IPv6Address(
        address: formatterIPv6MiddleCompressedStorage,
        prefixLength: IPv6PrefixLength(64)!
    )
    let formatterIPv6MiddleCompressed2_48 = IPv6Address(
        address: formatterIPv6MiddleCompressed2Storage,
        prefixLength: IPv6PrefixLength(48)!
    )
    let formatterIPv6NetworkMiddleCompressed64 = IPv6Network(
        prefix: formatterIPv6MiddleCompressedStorage,
        prefixLength: IPv6PrefixLength(64)!
    )
    let formatterIPv6BlockMiddleCompressed64 = CIDRBlock<AF.V6>(
        prefix: formatterIPv6MiddleCompressedStorage,
        prefixLength: IPv6PrefixLength(64)!
    )
    let formatterIPv6MulticastRange = IPv6MulticastGroupRange("ff02::/16")!
    let bulkIPv4CIDRValues = [
        formatterIPv4Zero,
        formatterIPv4Loopback,
        formatterIPv4LocalBroadcast,
        formatterIPv4Mixed24,
    ]
    let bulkIPv6CIDRValues = [
        formatterIPv6AllZero,
        formatterIPv6Loopback,
        formatterIPv6MiddleCompressed64,
        formatterIPv6MiddleCompressed2_48,
    ]
    let slashPrefixIPv4Mix: [UInt8] = [0, 24, 24, 24, 30, 31, 32, 32]
    let slashPrefixIPv6Mix: [UInt8] = [0, 48, 56, 64, 64, 96, 127, 128]
    let slashPrefixExportMix: [UInt8] = [0, 24, 32, 48, 56, 64, 96, 128]

    Benchmark(
        "formatter.cpu.ipv4.public.zero.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(formatterIPv4Zero.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.public.loopback.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(formatterIPv4Loopback.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.public.localBroadcast.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(formatterIPv4LocalBroadcast.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.public.mixed.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(formatterIPv4Mixed.formatted(.addressOnly))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.engine.zero.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(AF.V4.formatAddress(formatterIPv4ZeroStorage))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.engine.loopback.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(AF.V4.formatAddress(formatterIPv4LoopbackStorage))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.engine.localBroadcast.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(AF.V4.formatAddress(formatterIPv4LocalBroadcastStorage))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.engine.mixed.15M",
        configuration: cpuConfiguration()
    ) { _ in
        for _ in 0..<15_000_000 {
            blackHole(AF.V4.formatAddress(formatterIPv4MixedStorage))
        }
    }

    Benchmark(
        "formatter.cpu.ipv4.raw.zero.15M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawIPv4AddressFormatter(formatterIPv4Zero, iterations: 15_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv4.raw.loopback.15M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawIPv4AddressFormatter(formatterIPv4Loopback, iterations: 15_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv4.raw.localBroadcast.15M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawIPv4AddressFormatter(formatterIPv4LocalBroadcast, iterations: 15_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv4.raw.mixed.15M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawIPv4AddressFormatter(formatterIPv4Mixed, iterations: 15_000_000)
    }

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
        "formatter.cpu.ipv6.compressed.raw.middleCompressed2.4M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6Formatter(formatterIPv6MiddleCompressed2, iterations: 4_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.raw.middleCompressed.4M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6Formatter(formatterIPv6MiddleCompressed, iterations: 4_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.raw.max.4M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6Formatter(formatterIPv6Max, iterations: 4_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.raw.loopback.10M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6Formatter(formatterIPv6Loopback, iterations: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.raw.allZero.20M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6Formatter(formatterIPv6AllZero, iterations: 20_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv4.cidr.raw.mixed24.15M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawIPv4CIDRFormatter(formatterIPv4Mixed24, iterations: 15_000_000)
    }

    Benchmark(
        "formatter.cpu.ipv6.compressed.cidr.raw.middleCompressed64.4M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkRawCompressedIPv6CIDRFormatter(formatterIPv6MiddleCompressed64, iterations: 4_000_000)
    }

    Benchmark(
        "formatter.cpu.bulk.ipv4.cidr.string.1M",
        configuration: cpuConfiguration()
    ) { _ in
        // Model export-style loops that currently force one String allocation per CIDR value.
        benchmarkBulkIPv4CIDRStringFormatter(bulkIPv4CIDRValues, batches: 250_000)
    }

    Benchmark(
        "formatter.cpu.bulk.ipv4.cidr.raw.1M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkBulkIPv4CIDRRawFormatter(bulkIPv4CIDRValues, batches: 250_000)
    }

    Benchmark(
        "formatter.cpu.bulk.ipv6.compressed.cidr.string.1M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkBulkCompressedIPv6CIDRStringFormatter(bulkIPv6CIDRValues, batches: 250_000)
    }

    Benchmark(
        "formatter.cpu.bulk.ipv6.compressed.cidr.raw.1M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkBulkCompressedIPv6CIDRRawFormatter(bulkIPv6CIDRValues, batches: 250_000)
    }

    Benchmark(
        "formatter.cpu.concrete.ipv4.description.9M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv4Descriptions(
            network: formatterIPv4NetworkMixed24,
            block: formatterIPv4BlockMixed24,
            multicastRange: formatterIPv4MulticastRange,
            iterations: 3_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv4.cidrText.9M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv4CIDRText(
            network: formatterIPv4NetworkMixed24,
            block: formatterIPv4BlockMixed24,
            multicastRange: formatterIPv4MulticastRange,
            iterations: 3_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv4.addressOnly.9M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv4AddressOnly(
            network: formatterIPv4NetworkMixed24,
            block: formatterIPv4BlockMixed24,
            multicastRange: formatterIPv4MulticastRange,
            iterations: 3_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv4.netmask.9M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv4NetmaskStyle(
            network: formatterIPv4NetworkMixed24,
            block: formatterIPv4BlockMixed24,
            multicastRange: formatterIPv4MulticastRange,
            iterations: 3_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv4.rawCIDR.9M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv4RawCIDR(
            network: formatterIPv4NetworkMixed24,
            block: formatterIPv4BlockMixed24,
            multicastRange: formatterIPv4MulticastRange,
            iterations: 3_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv6.description.3M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv6Descriptions(
            network: formatterIPv6NetworkMiddleCompressed64,
            block: formatterIPv6BlockMiddleCompressed64,
            multicastRange: formatterIPv6MulticastRange,
            iterations: 1_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv6.cidrText.3M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv6CIDRText(
            network: formatterIPv6NetworkMiddleCompressed64,
            block: formatterIPv6BlockMiddleCompressed64,
            multicastRange: formatterIPv6MulticastRange,
            iterations: 1_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv6.compressed.3M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv6CompressedStyle(
            network: formatterIPv6NetworkMiddleCompressed64,
            block: formatterIPv6BlockMiddleCompressed64,
            multicastRange: formatterIPv6MulticastRange,
            iterations: 1_000_000
        )
    }

    Benchmark(
        "formatter.cpu.concrete.ipv6.rawCIDR.3M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkConcreteIPv6RawCIDR(
            network: formatterIPv6NetworkMiddleCompressed64,
            block: formatterIPv6BlockMiddleCompressed64,
            multicastRange: formatterIPv6MulticastRange,
            iterations: 1_000_000
        )
    }

    Benchmark(
        "formatter.cpu.slashPrefix.current.ipv4Mix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        // Isolate the current slash-prefix suffix writer before changing production code.
        benchmarkSlashPrefixCurrent(slashPrefixIPv4Mix, batches: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.slashPrefix.triplet.ipv4Mix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkSlashPrefixTriplet(slashPrefixIPv4Mix, batches: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.slashPrefix.current.ipv6Mix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkSlashPrefixCurrent(slashPrefixIPv6Mix, batches: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.slashPrefix.triplet.ipv6Mix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkSlashPrefixTriplet(slashPrefixIPv6Mix, batches: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.slashPrefix.current.exportMix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkSlashPrefixCurrent(slashPrefixExportMix, batches: 10_000_000)
    }

    Benchmark(
        "formatter.cpu.slashPrefix.triplet.exportMix.80M",
        configuration: cpuConfiguration()
    ) { _ in
        benchmarkSlashPrefixTriplet(slashPrefixExportMix, batches: 10_000_000)
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
