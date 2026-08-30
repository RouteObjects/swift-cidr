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

/// A transport-layer numeric port number.
///
/// `Port` stores only the 16-bit numeric port value used by transport protocols such as TCP and
/// UDP. It does not model an IANA service-name registration, transport protocol selection, socket
/// metadata, or a physical/interface port. The
/// [IANA Service Name and Port Number registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)
/// is useful reference data layered above this currency type.
///
/// **Layering:** with ``IPEndpoint``, design intent places port/endpoint in a **host/context**
/// layer above pure classless prefix math (see package DESIGN.md).
public struct Port: Sendable, Hashable, Codable {
    /// The raw 16-bit numeric port value.
    public let rawValue: UInt16

    /// Creates a port from a raw 16-bit numeric value.
    public init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

// Make the numeric port grammar reusable outside CLI adapters and endpoint parsing.
extension Port: CustomStringConvertible, LosslessStringConvertible {
    /// Creates a port from base-10 integer text accepted by `UInt16`.
    ///
    /// The complete `0...65535` range is valid. Service names, surrounding whitespace, negative
    /// nonzero values, overflow, and other nonnumeric text are rejected.
    public init?(_ description: String) {
        guard let rawValue = UInt16(description) else { return nil }
        self.init(rawValue)
    }

    /// Canonical unpadded base-10 text for the numeric port.
    public var description: String {
        rawValue.description
    }
}

/// A transport-agnostic IP endpoint composed from an IP address and port.
///
/// `IPEndpoint` intentionally models only `IPAddress + Port`. It does not include a transport
/// protocol such as TCP or UDP, because that choice belongs one layer above this transport-neutral
/// currency type.
///
/// **Layering:** endpoint composition is **host/context** currency (sockets, services), not pure
/// classless prefix math. Design intent is to keep the math module focused on addresses, networks,
/// and related forms; `IPEndpoint` / ``Port`` may move to a dedicated host/context package. Scoped
/// IPv6 (`addr%zone`) belongs in that same layer—see package DESIGN.md and issue #10.
///
/// IPv4 endpoints format as `192.0.2.1/24:53`.
/// IPv6 endpoints format as `[2001:db8::1/64]:443`.
public struct IPEndpoint<Family: IPAddressFamily>: Sendable, Hashable, Codable, CustomStringConvertible,
    LosslessStringConvertible
{
    public let address: IPAddress<Family>
    public let port: Port

    public init(address: IPAddress<Family>, port: Port) {
        self.address = address
        self.port = port
    }

    public init?(_ description: String) {
        if Family.self == AF.V6.self {
            guard description.first == "[",
                let closingBracket = description.lastIndex(of: "]")
            else {
                return nil
            }

            let colonIndex = description.index(after: closingBracket)
            guard colonIndex < description.endIndex,
                description[colonIndex] == ":"
            else {
                return nil
            }

            let addressStart = description.index(after: description.startIndex)
            let portStart = description.index(after: colonIndex)
            let addressText = String(description[addressStart..<closingBracket])
            let portText = description[portStart...]

            guard let address = IPAddress<Family>(addressText),
                let port = Self.parsePort(portText)
            else {
                return nil
            }

            self.init(address: address, port: port)
            return
        }

        guard let separator = description.lastIndex(of: ":") else { return nil }
        let addressText = String(description[..<separator])
        let portText = description[description.index(after: separator)...]

        guard let address = IPAddress<Family>(addressText),
            let port = Self.parsePort(portText)
        else {
            return nil
        }

        self.init(address: address, port: port)
    }

    public var description: String {
        // Compose endpoint text from Port's canonical representation.
        if Family.self == AF.V6.self {
            return "[\(address)]:\(port)"
        }

        return "\(address):\(port)"
    }
}

extension IPEndpoint {
    fileprivate static func parsePort(_ description: Substring) -> Port? {
        // Keep standalone Port and composite endpoint text on one parsing path.
        Port(String(description))
    }
}
