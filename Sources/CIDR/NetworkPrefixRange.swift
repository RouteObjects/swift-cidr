// [Routing Policy Specification Language (RPSL)](https://datatracker.ietf.org/doc/html/rfc2622)

postfix operator ^+
postfix operator ^-

// MARK: RPSL-style Network Prefix Range

/// An RPSL-style selector for prefix lengths contained by a base network.
///
/// `NetworkPrefixRange` models the RPSL address-prefix-range operators from
/// [RFC 2622, Section 2](https://datatracker.ietf.org/doc/html/rfc2622#section-2).
/// It does not store every matching network. Instead, it stores:
///
/// - a base network prefix
/// - the lower accepted prefix length
/// - the upper accepted prefix length
///
/// A candidate prefix matches when it is contained by `network` and its prefix length is inside the
/// closed interval `lowerPrefixLength...upperPrefixLength`.
///
/// For example, `IPv4Network("203.0.113.0/24")! ^ 26` represents every `/26` contained by
/// `203.0.113.0/24`.
///
/// The textual form follows the RPSL operators:
///
/// - `^+`: more specifics including the base prefix
/// - `^-`: more specifics excluding the base prefix
/// - `^n`: specifics with exactly prefix length `n`
/// - `^n-m`: specifics with prefix lengths from `n` through `m`
public struct NetworkPrefixRange<Family: AddressFamily>: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    /// The base network whose contained prefixes are selected.
    public let network: IPNetwork<Family>

    /// The shortest accepted prefix length.
    ///
    /// This value is always at least `network.prefixLength`.
    public let lowerPrefixLength: PrefixLength<Family>

    /// The longest accepted prefix length.
    ///
    /// This value is always greater than or equal to `lowerPrefixLength`.
    public let upperPrefixLength: PrefixLength<Family>

    /// Creates a prefix-range selector over prefixes contained by `network`.
    ///
    /// The initializer returns `nil` when the requested bounds cannot describe a valid range:
    ///
    /// - `lowerPrefixLength` must not be shorter than `network.prefixLength`.
    /// - `upperPrefixLength` must not be shorter than `lowerPrefixLength`.
    ///
    /// These rules preserve the RPSL meaning of "more specifics": selected candidates must be the
    /// base network itself or prefixes more specific than the base network.
    public init?(
        network: IPNetwork<Family>,
        lowerPrefixLength: PrefixLength<Family>,
        upperPrefixLength: PrefixLength<Family>
    ) {
        guard lowerPrefixLength >= network.prefixLength else { return nil }
        guard upperPrefixLength >= lowerPrefixLength else { return nil }
        self.network = network
        self.lowerPrefixLength = lowerPrefixLength
        self.upperPrefixLength = upperPrefixLength
    }

    /// Returns whether `candidate` is selected by this prefix range.
    ///
    /// A candidate matches only when both conditions are true:
    ///
    /// - `candidate` is contained by `network`.
    /// - `candidate.prefixLength` is inside `lowerPrefixLength...upperPrefixLength`.
    public func contains<P: IPPrefix>(_ candidate: P) -> Bool where P.Family == Family {
        guard candidate.prefixLength >= lowerPrefixLength else { return false }
        guard candidate.prefixLength <= upperPrefixLength else { return false }
        return network.contains(candidate)
    }

    /// The canonical RPSL-style text for this prefix range.
    ///
    /// The formatter chooses the shortest equivalent operator form:
    ///
    /// - `network^+` when the range includes the base prefix through the family maximum.
    /// - `network^-` when the range starts one bit longer than the base prefix and extends through
    ///   the family maximum.
    /// - `network^n` when the lower and upper bounds are equal.
    /// - `network^n-m` for all other bounded ranges.
    public var description: String {
        let base = network.description
        let maxPrefixLength = Family.bitWidth

        if lowerPrefixLength == network.prefixLength, upperPrefixLength.intValue == maxPrefixLength {
            return "\(base)^+"
        }

        if lowerPrefixLength.intValue == network.prefixLength.intValue + 1, upperPrefixLength.intValue == maxPrefixLength {
            return "\(base)^-"
        }

        if lowerPrefixLength == upperPrefixLength {
            return "\(base)^\(lowerPrefixLength.intValue)"
        }

        return "\(base)^\(lowerPrefixLength.intValue)-\(upperPrefixLength.intValue)"
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(description))"
    }
}

// MARK: IPPrefix Extensions

public extension IPPrefix {
    fileprivate var canonicalNetwork: IPNetwork<Family> {
        IPNetwork(prefix: prefix, prefixLength: prefixLength)
    }

    /// Returns all more-specific prefixes contained by this prefix, excluding this prefix itself.
    ///
    /// This is the method form of the RPSL `^-` operator. In RFC 2622 terms, `prefix/l^-` is
    /// equivalent to `prefix/l^(l+1)-max`, where `max` is `32` for IPv4 and `128` for IPv6.
    ///
    /// The result is `nil` for a host-length prefix because no more-specific prefix length exists.
    func moreSpecificsExcludingSelf() -> NetworkPrefixRange<Family>? {
        guard let nextLength = PrefixLength<Family>(prefixLength.intValue + 1),
              let maxLength = PrefixLength<Family>(Family.bitWidth)
        else {
            return nil
        }

        return NetworkPrefixRange(
            network: canonicalNetwork,
            lowerPrefixLength: nextLength,
            upperPrefixLength: maxLength
        )
    }

    /// Returns all more-specific prefixes contained by this prefix, including this prefix itself.
    ///
    /// This is the method form of the RPSL `^+` operator. In RFC 2622 terms, `prefix/l^+` is
    /// equivalent to `prefix/l^l-max`, where `max` is `32` for IPv4 and `128` for IPv6`.
    func moreSpecificsIncludingSelf() -> NetworkPrefixRange<Family> {
        let maxLength = PrefixLength<Family>(Family.bitWidth)!
        return NetworkPrefixRange(
            network: canonicalNetwork,
            lowerPrefixLength: prefixLength,
            upperPrefixLength: maxLength
        )!
    }

    /// Returns contained prefixes with exactly the requested prefix length.
    ///
    /// This is the method form of the RPSL `^n` operator. It returns `nil` when `prefixLength` is
    /// outside the address family width or shorter than this prefix's own length.
    func exactly(_ prefixLength: Int) -> NetworkPrefixRange<Family>? {
        guard let exactLength = PrefixLength<Family>(prefixLength) else { return nil }
        return NetworkPrefixRange(
            network: canonicalNetwork,
            lowerPrefixLength: exactLength,
            upperPrefixLength: exactLength
        )
    }

    /// Returns contained prefixes whose lengths are inside the requested closed range.
    ///
    /// This is the method form of the RPSL `^n-m` operator. It returns `nil` when either bound is
    /// outside the address family width, the lower bound is shorter than this prefix's own length,
    /// or the upper bound is shorter than the lower bound.
    func between(_ prefixLengths: ClosedRange<Int>) -> NetworkPrefixRange<Family>? {
        guard let lower = PrefixLength<Family>(prefixLengths.lowerBound),
              let upper = PrefixLength<Family>(prefixLengths.upperBound)
        else {
            return nil
        }

        return NetworkPrefixRange(
            network: canonicalNetwork,
            lowerPrefixLength: lower,
            upperPrefixLength: upper
        )
    }
}

// MARK: RPSL Operators

/// Selects more-specific prefixes including the base prefix.
///
/// This implements the RPSL `^+` operator from
/// [RFC 2622, Section 2](https://datatracker.ietf.org/doc/html/rfc2622#section-2).
/// For a base prefix `prefix/l`, the resulting range is equivalent to `prefix/l^l-max`.
public postfix func ^+ <P: IPPrefix>(lhs: P) -> NetworkPrefixRange<P.Family> {
    lhs.moreSpecificsIncludingSelf()
}

/// Selects more-specific prefixes excluding the base prefix.
///
/// This implements the RPSL `^-` operator from
/// [RFC 2622, Section 2](https://datatracker.ietf.org/doc/html/rfc2622#section-2).
/// For a base prefix `prefix/l`, the resulting range is equivalent to `prefix/l^(l+1)-max`.
///
/// The result is `nil` for a host-length prefix because no longer prefix length exists.
public postfix func ^- <P: IPPrefix>(lhs: P) -> NetworkPrefixRange<P.Family>? {
    lhs.moreSpecificsExcludingSelf()
}

/// Selects contained prefixes with exactly the requested prefix length.
///
/// This implements the RPSL `^n` operator from
/// [RFC 2622, Section 2](https://datatracker.ietf.org/doc/html/rfc2622#section-2).
/// The result is `nil` when `rhs` is outside the address family width or shorter than the base
/// prefix length.
public func ^ <P: IPPrefix>(lhs: P, rhs: Int) -> NetworkPrefixRange<P.Family>? {
    lhs.exactly(rhs)
}

/// Selects contained prefixes whose lengths are inside the requested closed range.
///
/// This implements the RPSL `^n-m` operator from
/// [RFC 2622, Section 2](https://datatracker.ietf.org/doc/html/rfc2622#section-2).
/// The result is `nil` when either bound is outside the address family width, when the lower bound
/// is shorter than the base prefix length, or when the upper bound is shorter than the lower bound.
public func ^ <P: IPPrefix>(lhs: P, rhs: ClosedRange<Int>) -> NetworkPrefixRange<P.Family>? {
    lhs.between(rhs)
}
