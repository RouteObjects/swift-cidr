/// A canonical, aligned IP prefix that supports network-level operations.
///
/// `IPPrefix` is the structural refinement of `CIDR` used for values whose stored bits are meant to
/// represent a formal prefix boundary. This is the level where containment, subnetting, and prefix
/// summarization become rational operations.
///
/// Conforming types own their stored prefix bits, so they also own enforcement of canonical
/// alignment. Implementations of ``init(prefix:prefixLength:)`` must clear any host bits below the
/// prefix boundary before storage. Protocol extension initializers and helpers adapt inputs and
/// share behavior, but they do not replace the conforming type's storage-boundary invariant.
public protocol IPPrefix: CIDR {
    /// The canonical prefix boundary for this value.
    ///
    /// Host bits below ``prefixLength`` are expected to be cleared by the conforming type's
    /// ``init(prefix:prefixLength:)`` implementation.
    var prefix: Family.Storage { get }

    /// Creates a canonical prefix value from raw prefix bits and a prefix length.
    ///
    /// Conforming implementations must normalize `prefix` by clearing host bits below
    /// `prefixLength` before storing it. This keeps construction through concrete initializers and
    /// protocol extension convenience initializers consistent.
    init(prefix: Family.Storage, prefixLength: PrefixLength<Family>)
}

public extension IPPrefix {
    var storage: Family.Storage { prefix }

    /// Creates a prefix value from address-shaped input.
    ///
    /// This convenience initializer adapts an `IPAddress` into the required
    /// `init(prefix:prefixLength:)` initializer. The conforming concrete type remains responsible
    /// for enforcing canonical prefix alignment at its storage boundary.
    init(address: IPAddress<Family>, prefixLength: PrefixLength<Family>) {
        self.init(
            prefix: address.address,
            prefixLength: prefixLength
        )
    }

    var isCanonical: Bool { prefix & mask == prefix }
    var networkAddress: IPAddress<Family> { first }

    func contains(_ address: IPAddress<Family>) -> Bool {
        (address.address & mask) == prefix
    }

    func contains<P: IPPrefix>(_ other: P) -> Bool where P.Family == Family {
        other.prefixLength >= self.prefixLength && self.contains(other.first)
    }

    var nextNetwork: Self? {
        let shift = Family.bitWidth - prefixBits
        guard shift < Family.bitWidth else { return nil }
        let stride = (1 as Family.Storage) << shift
        let (nextPrefix, overflow) = prefix.addingReportingOverflow(stride)
        guard !overflow else { return nil }
        return Self(prefix: nextPrefix, prefixLength: prefixLength)
    }

    func subnets(prefixLength newPrefixLength: PrefixLength<Family>) -> AnySequence<Self> {
        guard newPrefixLength >= self.prefixLength else { return AnySequence([]) }
        return AnySequence {
            var current: Family.Storage? = self.first.address
            let end = self.last.address
            let shift = Family.bitWidth - newPrefixLength.intValue
            let stride = shift < Family.bitWidth ? ((1 as Family.Storage) << shift) : nil
            return AnyIterator<Self> {
                guard let address = current else { return nil }
                let net = Self(prefix: address, prefixLength: newPrefixLength)
                if let stride {
                    let (next, overflow) = address.addingReportingOverflow(stride)
                    current = (overflow || next > end) ? nil : next
                } else {
                    current = nil
                }
                return net
            }
        }
    }

    func subnets(prefixLength rawValue: Int) -> AnySequence<Self> {
        guard let length = PrefixLength<Family>(rawValue) else { return AnySequence([]) }
        return subnets(prefixLength: length)
    }

    /// Summarizes an inclusive address range into the smallest set of aligned prefixes.
    ///
    /// Prefix summarization is the CIDR operation behind route aggregation. Instead of carrying
    /// every individual address in a range, the range is represented by the fewest canonical prefix
    /// blocks whose union covers exactly `start...end`.
    ///
    /// This is the same idea used when a routing system or BGP policy can advertise, filter, or
    /// reason about a compact set of prefixes instead of a long list of individual addresses. The
    /// result is pure CIDR math; whether any returned prefix is actually installed in a routing
    /// table or advertised by BGP is higher-layer context.
    ///
    /// Each returned value is initialized through `Self`, so the operation preserves the concrete
    /// `IPPrefix` type chosen by the caller. For example, calling `IPv4Network.summarize` returns
    /// `[IPv4Network]`, not an erased or loosely typed representation.
    ///
    /// Example:
    ///
    /// ```swift
    /// let summary = IPv4Network.summarize(
    ///     from: IPv4Address("192.168.1.1")!,
    ///     to: IPv4Address("192.168.1.189")!
    /// ).map(\.description)
    ///
    /// print(summary)
    /// ```
    ///
    /// Output:
    ///
    /// ```text
    /// [
    ///     "192.168.1.1/32",
    ///     "192.168.1.2/31",
    ///     "192.168.1.4/30",
    ///     "192.168.1.8/29",
    ///     "192.168.1.16/28",
    ///     "192.168.1.32/27",
    ///     "192.168.1.64/26",
    ///     "192.168.1.128/27",
    ///     "192.168.1.160/28",
    ///     "192.168.1.176/29",
    ///     "192.168.1.184/30",
    ///     "192.168.1.188/31"
    /// ]
    /// ```
    ///
    /// The first prefix is a `/32` because `192.168.1.1` is not aligned on a larger boundary. As
    /// the current address advances, the algorithm chooses the largest aligned prefix that does not
    /// exceed `end`.
    ///
    /// - Parameters:
    ///   - start: The first address in the inclusive range.
    ///   - end: The last address in the inclusive range.
    /// - Returns: A minimal ordered list of canonical prefixes covering `start...end`, or an empty
    ///   list when `start` is greater than `end`.
    static func summarize(from start: IPAddress<Family>, to end: IPAddress<Family>) -> [Self] {
        let bitWidth = Family.bitWidth
        let one: Family.Storage = 1
        if start.address == 0, end.address == Family.Storage.max {
            let prefix = PrefixLength<Family>(0)!
            return [Self(address: IPAddress(address: 0), prefixLength: prefix)]
        }
        var current = start.address
        let endAddr = end.address
        var result: [Self] = []
        while current <= endAddr {
            let remaining = endAddr - current + 1
            let maxBlockShift = bitWidth - remaining.leadingZeroBitCount - 1
            let shift = min(maxBlockShift, current.trailingZeroBitCount)
            let length = PrefixLength<Family>(bitWidth - shift)!
            result.append(Self(prefix: current, prefixLength: length))
            let (next, overflow) = current.addingReportingOverflow(one << shift)
            if overflow { break }
            current = next
        }
        return result
    }
}
