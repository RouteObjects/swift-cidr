// Focused consumer module. Build without cross-module optimization so the timed
// runner cannot import these wrapper bodies and hoist the measured operations.
import CIDR

@inline(never)
public func mappedText(_ address: UInt32) -> String {
    let mapped = (UInt128(0xFFFF) << 32) | UInt128(address)
    return IPAddress<AF.V6>(address: mapped).formatted(.ipv4Mapped)
}

@inline(never)
public func multicastGroup(_ address: UInt128) -> UInt64 {
    guard let group = IPMulticastGroup<AF.V6>(address: address) else { return 0 }
    return UInt64(truncatingIfNeeded: group.address)
        ^ UInt64(truncatingIfNeeded: group.address >> 64)
        ^ UInt64(group.prefixLength.rawValue)
}

@inline(never)
public func multicastRange(_ address: UInt128, _ prefix: UInt8) -> UInt64 {
    let length = PrefixLength<AF.V6>(rawValue: prefix)!
    guard let range = IPMulticastGroupRange<AF.V6>(prefix: address, prefixLength: length) else { return 0 }
    return UInt64(truncatingIfNeeded: range.prefix)
        ^ UInt64(truncatingIfNeeded: range.prefix >> 64)
        ^ UInt64(range.prefixLength.rawValue)
}

@inline(never)
public func multicastBlockRead(_ nonce: UInt64) -> UInt64 {
    let block = AF.V6.multicastAddressSpace
    return UInt64(truncatingIfNeeded: block.prefix)
        ^ UInt64(truncatingIfNeeded: block.prefix >> 64)
        ^ UInt64(block.prefixLength.rawValue)
        ^ nonce
}
