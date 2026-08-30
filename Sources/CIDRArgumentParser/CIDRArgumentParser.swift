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

import ArgumentParser
import CIDR

// This sibling target is still in the same package, so Swift rejects `@retroactive` here.
// Keep the conformance in an opt-in adapter so CIDR does not link ArgumentParser.
/// Adds command-line argument parsing for numeric transport ports.
///
/// ArgumentParser's conditional `LosslessStringConvertible` witness delegates to `Port.init(_:)`,
/// and its default-value help uses the port's canonical unpadded numeric `description`. Service
/// names and transport-specific policy belong to the consuming command.
extension Port: ExpressibleByArgument {}

// Use ArgumentParser's conditional witness to keep ASN parsing identical to CIDR parsing.
/// Adds strict `asplain` command-line parsing for autonomous system numbers.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `AutonomousSystemNumber.init(_:)`, preserving its rejection of signs, whitespace, `AS` prefixes,
/// and `asdot` notation.
extension AutonomousSystemNumber: ExpressibleByArgument {}

// One generic conformance covers the IPv4 and IPv6 aliases without widening other CIDR APIs.
/// Adds literal IP address command-line parsing for every supported address family.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `IPAddress.init(_:)`. Bare literals receive maximum-length prefix context; explicit valid
/// prefixes are preserved. Host names are not resolved.
extension IPAddress: ExpressibleByArgument {}

// Offer a dual-stack CLI boundary without teaching the adapter a second IP grammar.
/// Adds literal mixed-family IP address parsing for command-line arguments.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `AnyIPAddress.init(_:)`. IPv4 and IPv6 literals retain the same bare-address and explicit-prefix
/// behavior as their family-bound counterparts. Host names are not resolved.
extension AnyIPAddress: ExpressibleByArgument {}

// Preserve CIDR's endpoint grammar; the adapter must not invent a default port or DNS lookup.
/// Adds literal IP endpoint command-line parsing for every supported address family.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `IPEndpoint.init(_:)`. IPv4 uses `address:port`, while IPv6 requires `[address]:port` so the
/// address colons remain unambiguous. A port is always required.
extension IPEndpoint: ExpressibleByArgument {}

// Reuse canonical network construction so CLI parsing cannot diverge from CIDR semantics.
/// Adds CIDR network command-line parsing for every supported address family.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `IPNetwork.init(_:)`. A prefix is required, and address host bits are cleared to the canonical
/// network boundary by the existing initializer.
extension IPNetwork: ExpressibleByArgument {}

// Preserve CIDR's family selection and network canonicalization in dual-stack CLIs.
/// Adds mixed-family CIDR network parsing for command-line arguments.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `AnyIPNetwork.init(_:)`. CIDR notation is required, the address literal selects IPv4 or IPv6,
/// and host bits are cleared by the existing family-bound network initializer.
extension AnyIPNetwork: ExpressibleByArgument {}

// One family-bound conformance keeps standalone slash lengths validated by CIDR itself.
/// Adds standalone prefix-length command-line parsing for every supported address family.
///
/// The witness supplied by ArgumentParser for `LosslessStringConvertible` delegates to
/// `PrefixLength.init(_:)`, accepting only values within the selected family's bit width. The
/// argument is the decimal number without a leading slash.
extension PrefixLength: ExpressibleByArgument {}
