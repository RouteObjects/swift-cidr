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
    internal static func parseASNText(_ string: String) -> UInt32? {
        guard !string.isEmpty else { return nil }

        var value: UInt32 = 0
        for byte in string.utf8 {
            guard byte >= 48, byte <= 57 else { return nil }

            let digit = UInt32(byte &- 48)
            let multiplied = value.multipliedReportingOverflow(by: 10)
            guard !multiplied.overflow else { return nil }

            let added = multiplied.partialValue.addingReportingOverflow(digit)
            guard !added.overflow else { return nil }

            value = added.partialValue
        }

        return value
    }
}
