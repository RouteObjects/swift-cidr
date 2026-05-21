import Foundation
import Testing
@testable import CIDR

@Suite("CIDR Block Tests")
struct CIDRBlockTests {
    @Test("CIDRBlock canonicalizes stored prefix bits and exposes neutral range math")
    func cidrBlockCanonicalizesAndContains() throws {
        let block = try #require(CIDRBlock<V4>("192.0.2.1/24"))
        let child = try #require(CIDRBlock<V4>("192.0.2.128/25"))
        let overlap = try #require(CIDRBlock<V4>("192.0.2.192/26"))
        let outside = try #require(CIDRBlock<V4>("192.0.3.0/24"))
        let address = try #require(IPv4Address("192.0.2.42"))

        #expect(block.prefix == 0xC0000200)
        #expect(block.description == "192.0.2.0/24")
        #expect(block.firstAddress.description == "192.0.2.0/32")
        #expect(block.lastAddress.description == "192.0.2.255/32")
        #expect(block.rangeSizeIfRepresentable == 256)
        #expect(block.contains(address))
        #expect(block.contains(child))
        #expect(block.overlaps(overlap))
        #expect(child.isWithin(block))
        #expect(!block.contains(outside))
        #expect(!block.overlaps(outside))
    }

    @Test("CIDRBlock reports range sizes when UInt128 can represent the count")
    func cidrBlockRangeSizeRepresentation() throws {
        let ipv4Default = try #require(CIDRBlock<V4>("0.0.0.0/0"))
        let ipv6Half = try #require(CIDRBlock<V6>("8000::/1"))
        let ipv6Default = try #require(CIDRBlock<V6>("::/0"))

        #expect(ipv4Default.rangeSizeIfRepresentable == UInt128(UInt32.max) + 1)
        #expect(ipv6Half.rangeSizeIfRepresentable == UInt128(1) << 127)
        #expect(ipv6Default.rangeSizeIfRepresentable == nil)
    }

    @Test("CIDRBlock encodes and decodes as canonical CIDR text")
    func cidrBlockCodableRoundTrip() throws {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        let block = try #require(CIDRBlock<V4>("192.0.2.1/24"))
        let encoded = try encoder.encode(block)
        let decoded = try decoder.decode(CIDRBlock<V4>.self, from: encoded)

        #expect(try decoder.decode(String.self, from: encoded) == "192.0.2.0/24")
        #expect(decoded == block)
        #expect(try decoder.decode(CIDRBlock<V4>.self, from: Data(#""192.0.2.1/24""#.utf8)).description == "192.0.2.0/24")
    }
}
