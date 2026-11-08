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

/// The aligned subnets of a parent prefix at a longer prefix length, in address order.
///
/// Returned by `IPPrefix.subnets(prefixLength:)`. The sequence is lazy: no
/// subnet is constructed until iteration reaches it. A requested length shorter than the parent's,
/// or an out-of-range integer length, yields an empty sequence.
// CHANGE (new file): Replaces AnySequence/AnyIterator so subnet traversal is a specializable value
// type with no per-iteration heap box or indirect call.
public struct IPPrefixSubnets<Prefix: IPPrefix>: Sequence, Sendable {
    public typealias Element = Prefix

    @usableFromInline
    internal let start: Prefix.Family.Storage?
    @usableFromInline
    internal let end: Prefix.Family.Storage
    @usableFromInline
    internal let length: PrefixLength<Prefix.Family>

    /// Creates the subnets of `parent` at `length`; `nil` length means an empty sequence.
    @usableFromInline
    internal init(parent: Prefix, length: PrefixLength<Prefix.Family>?) {
        let valid = length.map { $0 >= parent.prefixLength } ?? false
        self.start = valid ? parent.first.address : nil
        self.end = parent.last.address
        self.length = length ?? parent.prefixLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(start: start, end: end, length: length)
    }

    /// A cursor over aligned subnet boundaries.
    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline
        internal var current: Prefix.Family.Storage?
        @usableFromInline
        internal let end: Prefix.Family.Storage
        @usableFromInline
        internal let length: PrefixLength<Prefix.Family>
        /// The distance between subnet boundaries, or `nil` for a single `/0` subnet.
        @usableFromInline
        internal let stride: Prefix.Family.Storage?

        @inlinable
        internal init(start: Prefix.Family.Storage?, end: Prefix.Family.Storage, length: PrefixLength<Prefix.Family>) {
            self.current = start
            self.end = end
            self.length = length
            let shift = Prefix.Family.Storage.bitWidth - length.intValue
            self.stride = shift < Prefix.Family.Storage.bitWidth ? (1 as Prefix.Family.Storage) << shift : nil
        }

        @inlinable
        public mutating func next() -> Prefix? {
            guard let address = current else { return nil }
            let subnet = Prefix(prefix: address, prefixLength: length)
            if let stride {
                let (next, overflow) = address.addingReportingOverflow(stride)
                current = (overflow || next > end) ? nil : next
            } else {
                current = nil
            }
            return subnet
        }
    }
}
