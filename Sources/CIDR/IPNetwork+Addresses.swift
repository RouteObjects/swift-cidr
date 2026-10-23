// Copyright (c) 2026 Craig A. Munro
// SPDX-License-Identifier: Apache-2.0

extension IPNetwork {
    /// A repeatable sequence of addresses carrying this network's prefix context.
    ///
    /// All address bits, including IPv4 boundary addresses, are included. The view makes no
    /// operational host-selection policy. Exact `contains(_:)` membership is O(1), while
    /// enumerating or materializing the view takes time proportional to its address count.
    public var addresses: Addresses { Addresses(network: self) }

    /// A contextual address sequence with exact element membership.
    ///
    /// This view deliberately does not conform to `IPPrefix`: its `contains(_:)` asks whether
    /// an equal address is yielded, rather than using the legacy raw-address containment overload.
    public struct Addresses: Sequence, Sendable {
        public typealias Element = IPAddress<Family>
        private let network: IPNetwork<Family>

        fileprivate init(network: IPNetwork<Family>) {
            self.network = network
        }

        public func makeIterator() -> Iterator {
            Iterator(network: network)
        }

        /// Answers the standard sequence membership question without a linear scan.
        /// - Complexity: O(1).
        public func _customContainsEquatableElement(_ element: Element) -> Bool? {
            // CHANGE: The fast path must agree with equality of the actual yielded elements.
            element.prefixLength == network.prefixLength && (element.address & network.mask) == network.prefix
        }

        /// Independent raw-storage cursor, including full-width IPv6 endpoints.
        public struct Iterator: IteratorProtocol, Sendable {
            public typealias Element = IPAddress<Family>
            private var current: Family.Storage
            private let end: Family.Storage
            private let prefixLength: PrefixLength<Family>
            private var finished = false

            fileprivate init(network: IPNetwork<Family>) {
                current = network.prefix
                end = network.prefix | network.inverseMask
                prefixLength = network.prefixLength
            }

            public mutating func next() -> Element? {
                guard !finished else { return nil }
                let element = Element(address: current, prefixLength: prefixLength)
                if current == end {
                    finished = true
                } else {
                    // CHANGE: Stop at the inclusive endpoint before attempting a potentially overflowing step.
                    let (next, overflow) = current.addingReportingOverflow(1)
                    precondition(!overflow)
                    current = next
                }
                return element
            }
        }
    }
}
