import CIDR

let wireOctets: InlineArray<4, UInt8> = [192, 0, 2, 129]

let address = IPv4Address(octets: wireOctets)

print(address.description)
// 192.0.2.129/32

let projected = address.octets
print(projected[0], projected[1], projected[2], projected[3])
// 192 0 2 129


let packet: InlineArray<6, UInt8> = [0xAA, 192, 0, 2, 129, 0xBB]
let addressBytes = packet.span.extracting(1..<5)

if let prefix = IPv4PrefixLength(24),
   let address = IPv4Address(octets: addressBytes, prefixLength: prefix) {
    print(address.description)
    // 192.0.2.129/24 — host bits are preserved
}

let invalid = IPv4Address(octets: packet.span)
// nil: the complete packet has six bytes, not four

let ipv6Bytes: InlineArray<16, UInt8> = [
    0x20, 0x01, 0x0D, 0xB8, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 1,
]
if let address = IPv6Address(octets: ipv6Bytes.span) {
    print(address.description)
    // 2001:db8::1/128
}
