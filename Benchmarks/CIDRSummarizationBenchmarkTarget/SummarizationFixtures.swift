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

import CIDR

struct SummarizationRangeFixture<Family: IPAddressFamily>: Sendable {
    let name: String
    let lower: IPAddress<Family>
    let upper: IPAddress<Family>
    let range: IPAddressRange<Family>
    let networkCount: Int

    init(name: String, lower: Family.Storage, upper: Family.Storage, networkCount: Int) {
        self.name = name
        self.lower = IPAddress(address: lower)
        self.upper = IPAddress(address: upper)
        self.range = IPAddressRange(lowerBound: self.lower, upperBound: self.upper)!
        self.networkCount = networkCount
    }
}

struct SummarizationCoverageFixture<Family: IPAddressFamily>: Sendable {
    let name: String
    let coverage: IPAddressCoverage<Family>
    let rangeCount: Int
    let networkCount: Int
}

func summarizationRangeFixtures<Family: IPAddressFamily>(
    _: Family.Type
) -> [SummarizationRangeFixture<Family>] {
    let one: Family.Storage = 1
    let base = one << (Family.Storage.bitWidth - 2)
    let blockWidth = Family.Storage.bitWidth / 2
    let span = one << blockWidth

    return [
        .init(name: "singleton", lower: base + 1, upper: base + 1, networkCount: 1),
        .init(name: "aligned", lower: base, upper: base + span - 1, networkCount: 1),
        .init(
            name: "fragmented", lower: 1, upper: .max - 1,
            networkCount: 2 * Family.Storage.bitWidth - 2
        ),
        .init(
            name: "nearMax", lower: .max - (span - 2), upper: .max,
            networkCount: blockWidth
        ),
        .init(name: "fullSpace", lower: 0, upper: .max, networkCount: 1),
    ]
}

func summarizationCoverageFixtures<Family: IPAddressFamily>(
    _: Family.Type
) -> [SummarizationCoverageFixture<Family>] {
    let one: Family.Storage = 1
    let blockWidth = Family.Storage.bitWidth / 2
    let slotWidth = one << blockWidth
    let base = one << (Family.Storage.bitWidth - 2)
    var fixtures: [SummarizationCoverageFixture<Family>] = []

    for rangeCount in [1, 1_024, 16_384] {
        for shape in ["singleton", "aligned", "fragmented", "nearMax"] {
            var ranges: [IPAddressRange<Family>] = []
            ranges.reserveCapacity(rangeCount)
            let firstSlot =
                shape == "nearMax"
                ? Family.Storage.max - Family.Storage(rangeCount) * slotWidth + 1
                : base
            let networksPerRange: Int
            switch shape {
            case "singleton", "aligned": networksPerRange = 1
            case "fragmented": networksPerRange = 2 * blockWidth - 2
            default: networksPerRange = blockWidth
            }

            for index in 0..<rangeCount {
                let slot = firstSlot + Family.Storage(index) * slotWidth
                let lower: Family.Storage
                let upper: Family.Storage
                switch shape {
                case "singleton":
                    lower = slot + 1
                    upper = lower
                case "aligned":
                    lower = slot
                    upper = slot + (slotWidth / 2 - 1)
                case "fragmented":
                    lower = slot + 1
                    upper = slot + (slotWidth - 2)
                default:
                    lower = slot + 1
                    upper = slot + (slotWidth - 1)
                }
                ranges.append(
                    IPAddressRange(
                        lowerBound: IPAddress(address: lower),
                        upperBound: IPAddress(address: upper)
                    )!
                )
            }

            // CHANGE: Normalize once before measurement and verify every generated gap survives.
            let coverage = IPAddressCoverage(ranges)
            precondition(coverage.ranges.count == rangeCount)
            fixtures.append(
                .init(
                    name: "\(shape).ranges\(rangeCount)", coverage: coverage,
                    rangeCount: rangeCount, networkCount: rangeCount * networksPerRange
                )
            )
        }
    }
    return fixtures
}
