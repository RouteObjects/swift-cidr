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
/// is useful reference data layered above this core currency type.
public struct Port: Sendable, Hashable, Codable {
    /// The raw 16-bit numeric port value.
    public let rawValue: UInt16

    /// Creates a port from a raw 16-bit numeric value.
    public init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

/// A transport-agnostic IP endpoint composed from an IP address and port.
///
/// `IPEndpoint` intentionally models only `IPAddress + Port`. It does not include a transport
/// protocol such as TCP or UDP, because that choice belongs one layer above this transport-neutral
/// currency type.
///
/// IPv4 endpoints format as `192.0.2.1/24:53`.
/// IPv6 endpoints format as `[2001:db8::1/64]:443`.
public struct IPEndpoint<Family: IPAddressFamily>: Sendable, Hashable, Codable, CustomStringConvertible, LosslessStringConvertible {
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
        if Family.self == AF.V6.self {
            return "[\(address)]:\(port.rawValue)"
        }

        return "\(address):\(port.rawValue)"
    }
}

private extension IPEndpoint {
    static func parsePort(_ description: Substring) -> Port? {
        guard let rawValue = UInt16(String(description)) else { return nil }
        return Port(rawValue)
    }
}
