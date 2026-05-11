import CIDR
import NIOCore

public extension IPAddress {
    init?(from buffer: inout ByteBuffer) {
        guard let value = buffer.readInteger(as: Family.Storage.self) else { return nil }
        self.init(address: value)
    }

    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(address)
    }
}

public extension CIDR where Family == AF.V6 {
    /// Writes this IPv6 CIDR value's address literal directly into a `ByteBuffer`.
    ///
    /// This avoids creating an intermediate `String`. Only the address literal is written; prefix
    /// length text is intentionally not included.
    @discardableResult
    func writeCompressedAddressLiteral(to buffer: inout ByteBuffer) -> Int {
        // SAFETY: NIO exposes writable bytes only for this closure; the CIDR writer does not escape them.
        buffer.writeWithUnsafeMutableBytes(
            minimumWritableBytes: CIDRUTF8Writer.maximumCompressedIPv6AddressLiteralUTF8Count
        ) { writableBytes in
            CIDRUTF8Writer.writeCompressedIPv6AddressLiteral(storage, into: writableBytes)
        }
    }
}
