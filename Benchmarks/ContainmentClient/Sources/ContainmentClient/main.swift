//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-cidr project.
// Copyright (c) 2026 Craig A. Munro
// Licensed under the Apache License, Version 2.0.
// See the LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CIDR
import Dispatch

// CHANGE: Keep runtime inputs across a call boundary so the optimizer cannot fold a fixture.
// The containment calls inside these loops have no consumer-side specialization annotations.
@inline(never)
func scanV4(_ networks: [IPv4Network], _ peer: IPv4Address) -> Int {
    var matches = 0
    for network in networks {
        if network.contains(address: peer) { matches += 1 }
    }
    return matches
}

@inline(never)
func scanV6(_ networks: [IPv6Network], _ peer: IPv6Address) -> Int {
    var matches = 0
    for network in networks {
        if network.contains(address: peer) { matches += 1 }
    }
    return matches
}

@inline(never)
func scanErased(_ networks: [AnyIPNetwork], _ peer: AnyIPAddress) -> Int {
    var matches = 0
    for network in networks {
        if network.contains(address: peer) { matches += 1 }
    }
    return matches
}

func required<T>(_ value: T?) -> T {
    guard let value else { preconditionFailure("Invalid benchmark fixture") }
    return value
}

// Construction and family erasure are deliberately outside the measured region.
let count = 20_000
let v4 = (0..<count).map {
    IPv4Network(prefix: 0x0A000000 + UInt32($0) * 256, prefixLength: required(IPv4PrefixLength(24)))
}
let v6 = (0..<count).map {
    IPv6Network(prefix: (UInt128(0x20010DB8) << 96) + (UInt128($0) << 64), prefixLength: required(IPv6PrefixLength(64)))
}
let v4Peers = [IPv4Address(address: v4[count - 1].prefix + 1), IPv4Address(address: 0xC6336401)]
let v6Peers = [IPv6Address(address: v6[count - 1].prefix + 1), IPv6Address(address: UInt128.max)]
let erasedV4 = v4.map(AnyIPNetwork.init)
let erasedV6 = v6.map(AnyIPNetwork.init)
let erasedV4Peers = v4Peers.map(AnyIPAddress.init)
let erasedV6Peers = v6Peers.map(AnyIPAddress.init)
let samples = 41
let scans = 25
let cases: [(String, (Int) -> Int)] = [
    ("v4.typed", { scanV4(v4, v4Peers[$0 & 1]) }),
    ("v4.erased", { scanErased(erasedV4, erasedV4Peers[$0 & 1]) }),
    ("v6.typed", { scanV6(v6, v6Peers[$0 & 1]) }),
    ("v6.erased", { scanErased(erasedV6, erasedV6Peers[$0 & 1]) }),
]

// CHANGE: Rotate case order between samples and retain every batch duration, not call percentiles.
// Alternating peers and checking the checksum keeps the entire scan observable.
print("case,sample,scans,checks_per_scan,elapsed_ns,matches")
for sample in -5..<samples {
    for offset in cases.indices {
        let index = (sample + 5 + offset) % cases.count
        let (name, run) = cases[index]
        var checksum = 0
        let start = DispatchTime.now().uptimeNanoseconds
        for iteration in 0..<scans { checksum += run(iteration) }
        let elapsed = DispatchTime.now().uptimeNanoseconds - start
        precondition(checksum == (scans + 1) / 2)
        if sample >= 0 {
            print("\(name),\(sample),\(scans),\(count),\(elapsed),\(checksum)")
        }
    }
}
