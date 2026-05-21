/// A transport-layer port number stored independently from registry metadata.
///
/// The name stays `TransportPort` rather than `ServicePort` because the value is the numeric port
/// itself, not an IANA service-name record. The
/// [IANA Service Name and Port Number registry](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml)
/// is useful reference data layered on top of this scalar value.
public struct TransportPort: Sendable, Hashable, Codable {
    public let rawValue: UInt16

    public init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

/// A transport-agnostic IP endpoint composed from an IP address and port.
///
/// `IPEndpoint` intentionally models only `IPAddress + TransportPort`. It does not include a
/// transport protocol such as TCP or UDP, because that choice belongs one layer above this
/// transport-neutral currency type.
///
/// IPv4 endpoints format as `192.0.2.1/24:53`.
/// IPv6 endpoints format as `[2001:db8:0:0:0:0:0:1/64]:443`.
public struct IPEndpoint<Family: AddressFamily>: Sendable, Hashable, Codable, CustomStringConvertible, LosslessStringConvertible {
    public let address: IPAddress<Family>
    public let port: TransportPort

    public init(address: IPAddress<Family>, port: TransportPort) {
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
    static func parsePort(_ description: Substring) -> TransportPort? {
        guard let rawValue = UInt16(String(description)) else { return nil }
        return TransportPort(rawValue)
    }
}
