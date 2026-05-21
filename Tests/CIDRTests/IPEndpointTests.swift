import Foundation
import Testing
@testable import CIDR

@Suite("IP Endpoint Tests")
struct IPEndpointTests {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    @Test("TransportPort stores the raw UInt16 value")
    func transportPortStoresRawValue() {
        let port = TransportPort(443)

        #expect(port.rawValue == 443)
    }

    @Test("IPEndpoint stores the provided address and port")
    func ipEndpointStoresAddressAndPort() throws {
        let address = try #require(IPv4Address("192.0.2.1/24"))
        let endpoint = IPEndpoint(address: address, port: TransportPort(53))

        #expect(endpoint.address == address)
        #expect(endpoint.port.rawValue == 53)
    }

    @Test("TransportPort and IPEndpoint round-trip through Codable")
    func transportTypesCodableRoundTrip() throws {
        let address = try #require(IPv6Address("2001:db8::1/64"))
        let endpoint = IPEndpoint(address: address, port: TransportPort(443))

        let encodedPort = try encoder.encode(TransportPort(443))
        let encodedEndpoint = try encoder.encode(endpoint)

        #expect(String(decoding: encodedPort, as: UTF8.self) == #"{"rawValue":443}"#)
        let endpointObject = try #require(JSONSerialization.jsonObject(with: encodedEndpoint) as? [String: Any])
        #expect(endpointObject["address"] as? String == "2001:db8:0:0:0:0:0:1/64")
        let portObject = try #require(endpointObject["port"] as? [String: Any])
        #expect(portObject["rawValue"] as? Int == 443)
        #expect(try decoder.decode(TransportPort.self, from: encodedPort) == TransportPort(443))
        #expect(try decoder.decode(IPEndpoint<V6>.self, from: encodedEndpoint) == endpoint)
    }

    @Test("IPEndpoint formats and parses IPv4 endpoints losslessly")
    func ipEndpointIPv4LosslessStringConvertible() throws {
        let endpoint = IPEndpoint(
            address: try #require(IPv4Address("192.0.2.1/24")),
            port: TransportPort(53)
        )

        #expect(endpoint.description == "192.0.2.1/24:53")
        #expect(IPEndpoint<V4>(endpoint.description) == endpoint)
    }

    @Test("IPEndpoint formats and parses IPv6 endpoints losslessly")
    func ipEndpointIPv6LosslessStringConvertible() throws {
        let endpoint = IPEndpoint(
            address: try #require(IPv6Address("2001:db8::1/64")),
            port: TransportPort(443)
        )

        #expect(endpoint.description == "[2001:db8:0:0:0:0:0:1/64]:443")
        #expect(IPEndpoint<V6>(endpoint.description) == endpoint)
    }

    @Test("IPEndpoint rejects malformed endpoint strings")
    func ipEndpointRejectsMalformedStrings() {
        #expect(IPEndpoint<V4>("192.0.2.1/24") == nil)
        #expect(IPEndpoint<V4>("192.0.2.1/24:65536") == nil)
        #expect(IPEndpoint<V6>("2001:db8::1/64:443") == nil)
        #expect(IPEndpoint<V6>("[2001:db8::1/64]443") == nil)
        #expect(IPEndpoint<V6>("[2001:db8::1/129]:443") == nil)
    }
}
