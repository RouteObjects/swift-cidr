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

/// A normalized exact union of addresses from one IP address family.
///
/// `IPAddressCoverage` is an immutable coverage value. Its ``ranges`` are always ascending,
/// non-empty intervals with no duplicates, containment, overlap, or adjacency between neighbors.
/// Construction coalesces connected inputs but never widens across a gap.
///
/// Equality and hashing therefore compare exact address coverage, independent of the original
/// range ordering, duplication, or CIDR prefix structure.
public struct IPAddressCoverage<Family: IPAddressFamily>: Sendable, Hashable {
    /// The normalized, ascending closed ranges that form this exact coverage set.
    public let ranges: [IPAddressRange<Family>]

    /// Creates normalized exact coverage from family-bound ranges.
    ///
    /// Duplicate, contained, overlapping, and adjacent ranges are coalesced. Empty input produces
    /// empty coverage.
    public init<Ranges: Sequence>(_ ranges: Ranges)
    where Ranges.Element == IPAddressRange<Family> {
        self.ranges = IPAddressRange.coalescing(ranges)
    }

    /// Creates normalized exact coverage from canonical family-bound prefixes.
    ///
    /// Prefix representation is intentionally erased into address coverage before coalescing. A
    /// later call to ``summarizedNetworks()`` preserves the exact union but may return prefix lengths
    /// different from those in `prefixes`.
    public init<Prefixes: Sequence>(covering prefixes: Prefixes)
    where Prefixes.Element: IPPrefix, Prefixes.Element.Family == Family {
        self.init(prefixes.lazy.map(IPAddressRange.init(covering:)))
    }

    /// A Boolean value indicating whether this coverage contains no addresses.
    public var isEmpty: Bool {
        ranges.isEmpty
    }

    /// Returns whether `address` belongs to this coverage set.
    ///
    /// The implementation uses the normalized range index and does not enumerate addresses.
    public func contains(_ address: IPAddress<Family>) -> Bool {
        var lowerIndex = ranges.startIndex
        var upperIndex = ranges.endIndex

        // CHANGE: Normalized ranges are ascending and disjoint, so containment can use logarithmic
        // lookup while keeping the value representation itself simple and auditable.
        while lowerIndex < upperIndex {
            let middleIndex = lowerIndex + (upperIndex - lowerIndex) / 2
            let candidate = ranges[middleIndex]
            if address.address < candidate.lowerBound.address {
                upperIndex = middleIndex
            } else if address.address > candidate.upperBound.address {
                lowerIndex = middleIndex + 1
            } else {
                return true
            }
        }

        return false
    }

    /// Summarizes the exact coverage as the smallest ordered list of canonical networks.
    ///
    /// Each disjoint range delegates to swift-cidr's range summarizer. Because normalized ranges are
    /// ascending and separated by gaps, concatenating those summaries is deterministic and cannot
    /// merge across uncovered addresses.
    public func summarizedNetworks() -> [IPNetwork<Family>] {
        ranges.flatMap { $0.summarizedNetworks() }
    }
}
