/// CIDR-oriented helpers for unsigned fixed-width address storage.
///
/// `AddressFamily.Storage` is an unsigned fixed-width integer (`UInt32` for IPv4 and `UInt128` for
/// IPv6). This extension centralizes the bit-mask operations shared by family-bound CIDR values so
/// address and prefix types can ask their storage type for masks directly.
extension FixedWidthInteger where Self: UnsignedInteger {
    /// Returns a high-bit network mask for a CIDR prefix length.
    ///
    /// The returned mask has `prefixLength` leading one bits followed by zero bits through the host
    /// portion of the address.
    ///
    /// Examples for `UInt32`:
    ///
    /// - `networkMask(for: 0)` returns `0.0.0.0`
    /// - `networkMask(for: 24)` returns `255.255.255.0`
    /// - `networkMask(for: 32)` returns `255.255.255.255`
    ///
    /// The prefix length must be in `0...Self.bitWidth`.
    static func networkMask(for prefixLength: Int) -> Self {
        precondition((0...Self.bitWidth).contains(prefixLength))
        return prefixLength == 0 ? 0 : (~0 << (Self.bitWidth - prefixLength))
    }

    /// The number of contiguous one bits at the most-significant end of the value.
    ///
    /// This is useful when converting a contiguous network mask back into a CIDR prefix length.
    var leadingOnesCount: Int { (~self).leadingZeroBitCount }
}
