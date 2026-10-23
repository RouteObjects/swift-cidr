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

/// The accepted IPv4 octet spelling when parsing IP address or CIDR text.
///
/// Both policies require canonical unsigned decimal prefix lengths. Neither policy resolves
/// hostnames, classifies special-use addresses, or requires one canonical IPv6 spelling.
public enum IPAddressParsingPolicy: Sendable, Hashable {
    /// Accepts padded IPv4 octets and interprets them as decimal, including IPv6 dotted tails.
    ///
    /// This is the policy used by existing initializers, Codable, and CLI adapters. Carry the
    /// parsed value into transport: a system resolver may interpret the original text as octal.
    case compatible

    /// Rejects multi-digit IPv4 octets beginning with zero, including IPv6 dotted tails.
    ///
    /// Valid IPv6 hextet padding, capitalization, compression, and expanded notation remain valid.
    case strict
}
