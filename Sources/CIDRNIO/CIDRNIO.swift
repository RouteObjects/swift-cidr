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
            minimumWritableBytes: CIDRUTF8Formatting.maximumCompressedIPv6AddressLiteralUTF8Count
        ) { writableBytes in
            writeCompressedAddressLiteralUTF8(into: writableBytes)
        }
    }
}
