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

extension AF {
    internal static func parseMACText(_ string: String, octetCount: Int) -> UInt64? {
        precondition(octetCount == 6 || octetCount == 8)

        let expectedLength = (octetCount * 3) - 1
        guard string.utf8.count == expectedLength else { return nil }

        var value: UInt64 = 0
        for (index, byte) in string.utf8.enumerated() {
            if index % 3 == 2 {
                guard byte == 58 else { return nil }
                continue
            }

            guard let nibble = hexNibble(byte) else { return nil }
            value = (value << 4) | UInt64(nibble)
        }

        return value
    }

    internal static func formatMAC(_ address: UInt64, octetCount: Int) -> String {
        precondition(octetCount == 6 || octetCount == 8)
        if octetCount == 6 {
            precondition(address >> 48 == 0, "MAC48 storage must fit in 48 bits.")
        }

        let hexDigitsLiteral: StaticString = "0123456789abcdef"
        let hexDigits = hexDigitsLiteral.utf8Start
        var bytes: [UInt8] = []
        bytes.reserveCapacity((octetCount * 3) - 1)

        for octetIndex in 0..<octetCount {
            let shift = (octetCount - octetIndex - 1) * 8
            let octet = UInt8(truncatingIfNeeded: address >> shift)
            bytes.append(hexDigits[Int(octet >> 4)])
            bytes.append(hexDigits[Int(octet & 0x0F)])

            if octetIndex != octetCount - 1 {
                bytes.append(58)
            }
        }

        return String(decoding: bytes, as: UTF8.self)
    }

    private static func hexNibble(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 48...57:
            return byte &- 48
        case 65...70:
            return byte &- 55
        case 97...102:
            return byte &- 87
        default:
            return nil
        }
    }
}
