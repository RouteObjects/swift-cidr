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
import CIDRArgumentParser
import Testing

@Suite("CIDR Argument Parser Adapter Tests")
struct CIDRArgumentParserTests {
    @Test("Ports accept the complete unsigned 16-bit range and canonicalize accepted text")
    func portsAcceptBoundaries() throws {
        let examples: [(source: String, canonical: String, value: UInt16)] = [
            ("0", "0", 0),
            ("-0", "0", 0),
            ("179", "179", 179),
            ("00179", "179", 179),
            ("+179", "179", 179),
            ("65535", "65535", .max),
        ]

        for example in examples {
            let port = try #require(Port(argument: example.source))
            #expect(port.rawValue == example.value)
            #expect(port.defaultValueDescription == example.canonical)
            #expect(Port(argument: port.description) == port)
        }
    }

    @Test("Ports reject empty, negative, overflowing, and nonnumeric values")
    func portsRejectInvalidValues() {
        for source in ["", "-1", "65536", "abc"] {
            #expect(Port(argument: source) == nil)
        }
    }

    @Test("ASNs accept boundaries and canonicalize asplain text")
    func asnsAcceptBoundariesAndCanonicalize() throws {
        let examples: [(source: String, canonical: String, value: UInt32)] = [
            ("0", "0", 0),
            ("65001", "65001", 65_001),
            ("4294967295", "4294967295", .max),
            ("00065001", "65001", 65_001),
        ]

        for example in examples {
            let asn = try #require(AutonomousSystemNumber(argument: example.source))
            #expect(asn.rawValue == example.value)
            #expect(asn.defaultValueDescription == example.canonical)
            #expect(AutonomousSystemNumber(argument: asn.description) == asn)
        }
    }

    @Test("ASNs reject non-asplain syntax")
    func asnsRejectInvalidValues() {
        let invalid = [
            "",
            " 65001",
            "65001 ",
            "+65001",
            "-1",
            "4294967296",
            "AS65001",
            "1.10",
            "abc",
        ]

        for source in invalid {
            #expect(AutonomousSystemNumber(argument: source) == nil)
        }
    }

    @Test("IPv4 arguments preserve explicit prefixes and canonicalize bare literals")
    func ipv4ArgumentsRoundTrip() throws {
        let examples: [(source: String, canonical: String, prefixLength: Int)] = [
            ("192.0.2.1", "192.0.2.1/32", 32),
            ("192.0.2.1/24", "192.0.2.1/24", 24),
        ]

        for example in examples {
            let address = try #require(IPv4Address(argument: example.source))
            #expect(address.description == example.canonical)
            #expect(address.prefixLength.intValue == example.prefixLength)
            #expect(address.defaultValueDescription == example.canonical)
            #expect(IPv4Address(argument: address.description) == address)
        }
    }

    @Test("IPv6 arguments preserve explicit prefixes and use canonical compressed text")
    func ipv6ArgumentsRoundTrip() throws {
        let examples: [(source: String, canonical: String, prefixLength: Int)] = [
            ("2001:0db8:0:0:0:0:0:1", "2001:db8::1/128", 128),
            ("2001:db8::1/64", "2001:db8::1/64", 64),
            ("0000::1", "::1/128", 128),
            ("1:2:3:4:5:6:7::", "1:2:3:4:5:6:7:0/128", 128),
        ]

        for example in examples {
            let address = try #require(IPv6Address(argument: example.source))
            #expect(address.description == example.canonical)
            #expect(address.prefixLength.intValue == example.prefixLength)
            #expect(address.defaultValueDescription == example.canonical)
            #expect(IPv6Address(argument: address.description) == address)
        }
    }

    @Test("IP arguments reject wrong families, invalid prefixes, names, and malformed text")
    func ipArgumentsRejectInvalidValues() {
        let invalidIPv4 = [
            "",
            "2001:db8::1",
            "192.0.2.1/33",
            "192.0.2.1/-1",
            "192.0.2.1/",
            "rr.example.com",
            "garbage",
        ]
        let invalidIPv6 = [
            "",
            "192.0.2.1",
            "2001:db8::1/129",
            "2001:db8::1/-1",
            "2001:db8::1/",
            "rr.example.com",
            "garbage",
        ]

        for source in invalidIPv4 {
            #expect(IPv4Address(argument: source) == nil)
        }
        for source in invalidIPv6 {
            #expect(IPv6Address(argument: source) == nil)
        }
    }

    @Test(
        "IP argument boundaries reject malformed IPv6 literals",
        arguments: [
            "00000::1",
            "1:2:3:4:5:6:7:8:",
            "1:2:3:4:5:6:7:8::",
            "1:2:3:4:5:6::192.0.2.1",
        ])
    func ipArgumentsRejectMalformedIPv6Literals(source: String) {
        // CHANGE: All adapters inherit the core parser's rejection, including bracketed endpoints.
        for literal in [source, "\(source)/128"] {
            #expect(IPv6Address(argument: literal) == nil)
            #expect(AnyIPAddress(argument: literal) == nil)
            #expect(IPEndpoint<V6>(argument: "[\(literal)]:53") == nil)
        }
        #expect(IPv6Network(argument: "\(source)/128") == nil)
        #expect(AnyIPNetwork(argument: "\(source)/128") == nil)
    }

    @Test("IP endpoint arguments require a port and round-trip canonically")
    func ipEndpointArgumentsRoundTrip() throws {
        let ipv4Examples: [(source: String, canonical: String)] = [
            ("192.0.2.1:0", "192.0.2.1/32:0"),
            ("192.0.2.1:00179", "192.0.2.1/32:179"),
            ("192.0.2.1/24:65535", "192.0.2.1/24:65535"),
        ]
        let ipv6Examples: [(source: String, canonical: String)] = [
            ("[2001:0db8:0:0:0:0:0:1]:179", "[2001:db8::1/128]:179"),
            ("[2001:0db8:0:0:0:0:0:1]:00179", "[2001:db8::1/128]:179"),
            ("[2001:db8::1/64]:443", "[2001:db8::1/64]:443"),
            ("[0000::1]:53", "[::1/128]:53"),
            ("[1:2:3:4:5:6:7::]:53", "[1:2:3:4:5:6:7:0/128]:53"),
        ]

        for example in ipv4Examples {
            let endpoint = try #require(IPEndpoint<V4>(argument: example.source))
            #expect(endpoint.description == example.canonical)
            #expect(endpoint.defaultValueDescription == example.canonical)
            #expect(IPEndpoint<V4>(argument: endpoint.description) == endpoint)
        }
        for example in ipv6Examples {
            let endpoint = try #require(IPEndpoint<V6>(argument: example.source))
            #expect(endpoint.description == example.canonical)
            #expect(endpoint.defaultValueDescription == example.canonical)
            #expect(IPEndpoint<V6>(argument: endpoint.description) == endpoint)
        }
    }

    @Test("IP endpoint arguments reject missing ports, ambiguous IPv6, and invalid components")
    func ipEndpointArgumentsRejectInvalidValues() {
        let invalidIPv4 = [
            "",
            "192.0.2.1",
            "192.0.2.1:",
            ":179",
            "192.0.2.1:-1",
            "192.0.2.1:65536",
            "[192.0.2.1]:179",
            "2001:db8::1:179",
            "rr.example.com:179",
        ]
        let invalidIPv6 = [
            "",
            "2001:db8::1:179",
            "[2001:db8::1]",
            "[2001:db8::1]179",
            "[2001:db8::1]:-1",
            "[2001:db8::1]:65536",
            "[2001:db8::1/129]:179",
            "[192.0.2.1]:179",
            "[rr.example.com]:179",
        ]

        for source in invalidIPv4 {
            #expect(IPEndpoint<V4>(argument: source) == nil)
        }
        for source in invalidIPv6 {
            #expect(IPEndpoint<V6>(argument: source) == nil)
        }
    }

    @Test("IP network arguments require CIDR notation and canonicalize host bits")
    func ipNetworkArgumentsRoundTrip() throws {
        let ipv4Examples: [(source: String, canonical: String)] = [
            ("0.0.0.0/0", "0.0.0.0/0"),
            ("192.0.2.129/24", "192.0.2.0/24"),
            ("255.255.255.255/32", "255.255.255.255/32"),
        ]
        let ipv6Examples: [(source: String, canonical: String)] = [
            ("::/0", "::/0"),
            ("2001:0db8:0:1::dead:beef/64", "2001:db8:0:1::/64"),
            ("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"),
        ]

        for example in ipv4Examples {
            let network = try #require(IPv4Network(argument: example.source))
            #expect(network.description == example.canonical)
            #expect(network.defaultValueDescription == example.canonical)
            #expect(IPv4Network(argument: network.description) == network)
        }
        for example in ipv6Examples {
            let network = try #require(IPv6Network(argument: example.source))
            #expect(network.description == example.canonical)
            #expect(network.defaultValueDescription == example.canonical)
            #expect(IPv6Network(argument: network.description) == network)
        }
    }

    @Test("IP network arguments reject bare addresses, wrong families, and invalid CIDR text")
    func ipNetworkArgumentsRejectInvalidValues() {
        let invalidIPv4 = [
            "",
            "192.0.2.0",
            "192.0.2.0/33",
            "192.0.2.0/-1",
            "192.0.2.0/24/25",
            "2001:db8::/64",
            "rr.example.com/24",
            "garbage",
        ]
        let invalidIPv6 = [
            "",
            "2001:db8::",
            "2001:db8::/129",
            "2001:db8::/-1",
            "2001:db8::/64/65",
            "192.0.2.0/24",
            "rr.example.com/64",
            "garbage",
        ]

        for source in invalidIPv4 {
            #expect(IPv4Network(argument: source) == nil)
        }
        for source in invalidIPv6 {
            #expect(IPv6Network(argument: source) == nil)
        }
    }

    @Test("Mixed-family IP address arguments select a family and round-trip canonically")
    func anyIPAddressArgumentsRoundTrip() throws {
        let examples: [(source: String, canonical: String, isIPv4: Bool)] = [
            ("192.0.2.1", "192.0.2.1/32", true),
            ("192.0.2.1/24", "192.0.2.1/24", true),
            ("2001:0db8:0:0:0:0:0:1", "2001:db8::1/128", false),
            ("2001:db8::1/64", "2001:db8::1/64", false),
        ]

        for example in examples {
            let address = try #require(AnyIPAddress(argument: example.source))
            #expect(address.description == example.canonical)
            #expect(address.isIPv4 == example.isIPv4)
            #expect(address.isIPv6 != example.isIPv4)
            #expect(address.defaultValueDescription == example.canonical)
            #expect(AnyIPAddress(argument: address.description) == address)
        }
    }

    @Test("Mixed-family IP address arguments reject names and malformed literals")
    func anyIPAddressArgumentsRejectInvalidValues() {
        let invalid = [
            "",
            "192.0.2.1/33",
            "192.0.2.1/",
            "2001:db8::1/129",
            "2001:db8::1/",
            "rr.example.com",
            "garbage",
        ]

        for source in invalid {
            #expect(AnyIPAddress(argument: source) == nil)
        }
    }

    @Test("Mixed-family IP network arguments select a family and canonicalize host bits")
    func anyIPNetworkArgumentsRoundTrip() throws {
        let examples: [(source: String, canonical: String, isIPv4: Bool)] = [
            ("0.0.0.0/0", "0.0.0.0/0", true),
            ("192.0.2.129/24", "192.0.2.0/24", true),
            ("::/0", "::/0", false),
            ("2001:0db8:0:1::dead:beef/64", "2001:db8:0:1::/64", false),
        ]

        for example in examples {
            let network = try #require(AnyIPNetwork(argument: example.source))
            #expect(network.description == example.canonical)
            #expect(network.isIPv4 == example.isIPv4)
            #expect(network.isIPv6 != example.isIPv4)
            #expect(network.defaultValueDescription == example.canonical)
            #expect(AnyIPNetwork(argument: network.description) == network)
        }
    }

    @Test("Mixed-family IP network arguments require valid CIDR notation")
    func anyIPNetworkArgumentsRejectInvalidValues() {
        let invalid = [
            "",
            "192.0.2.0",
            "192.0.2.0/33",
            "192.0.2.0/24/25",
            "2001:db8::",
            "2001:db8::/129",
            "rr.example.com/24",
            "garbage",
        ]

        for source in invalid {
            #expect(AnyIPNetwork(argument: source) == nil)
        }
    }

    @Test("Prefix-length arguments accept family boundaries and canonicalize decimal text")
    func prefixLengthArgumentsAcceptBoundariesAndCanonicalize() throws {
        let ipv4Examples: [(source: String, canonical: String, value: Int)] = [
            ("0", "0", 0),
            ("-0", "0", 0),
            ("024", "24", 24),
            ("+24", "24", 24),
            ("32", "32", 32),
        ]
        let ipv6Examples: [(source: String, canonical: String, value: Int)] = [
            ("0", "0", 0),
            ("-0", "0", 0),
            ("064", "64", 64),
            ("+64", "64", 64),
            ("128", "128", 128),
        ]

        for example in ipv4Examples {
            let prefixLength = try #require(IPv4PrefixLength(argument: example.source))
            #expect(prefixLength.intValue == example.value)
            #expect(prefixLength.defaultValueDescription == example.canonical)
            #expect(IPv4PrefixLength(argument: prefixLength.description) == prefixLength)
        }
        for example in ipv6Examples {
            let prefixLength = try #require(IPv6PrefixLength(argument: example.source))
            #expect(prefixLength.intValue == example.value)
            #expect(prefixLength.defaultValueDescription == example.canonical)
            #expect(IPv6PrefixLength(argument: prefixLength.description) == prefixLength)
        }
    }

    @Test("Prefix-length arguments reject out-of-family ranges and malformed text")
    func prefixLengthArgumentsRejectInvalidValues() {
        for source in ["", "-1", "33", "24/", "/24", " 24", "24 ", "abc"] {
            #expect(IPv4PrefixLength(argument: source) == nil)
        }
        for source in ["", "-1", "129", "64/", "/64", " 64", "64 ", "abc"] {
            #expect(IPv6PrefixLength(argument: source) == nil)
        }
    }

    @Test("Open-ended values do not advertise a finite completion list")
    func valuesDoNotAdvertiseFiniteLists() {
        #expect(Port.allValueStrings.isEmpty)
        #expect(AutonomousSystemNumber.allValueStrings.isEmpty)
        #expect(IPv4Address.allValueStrings.isEmpty)
        #expect(IPv6Address.allValueStrings.isEmpty)
        #expect(AnyIPAddress.allValueStrings.isEmpty)
        #expect(IPEndpoint<V4>.allValueStrings.isEmpty)
        #expect(IPEndpoint<V6>.allValueStrings.isEmpty)
        #expect(IPv4Network.allValueStrings.isEmpty)
        #expect(IPv6Network.allValueStrings.isEmpty)
        #expect(AnyIPNetwork.allValueStrings.isEmpty)
        #expect(IPv4PrefixLength.allValueStrings.isEmpty)
        #expect(IPv6PrefixLength.allValueStrings.isEmpty)
    }

    @Test("A bgpls-shaped options fixture parses CIDR currency types directly")
    func bgplsOptionsParseTypedOverrides() throws {
        let options = try BGPLSOptions.parse([
            "--peer", "198.51.100.7/24",
            "--port", "1179",
            "--local-as", "64496",
            "--peer-as", "64497",
            "--local-address", "198.51.100.8",
        ])

        #expect(options.peer == IPv4Address("198.51.100.7/24"))
        #expect(options.port.rawValue == 1_179)
        #expect(options.localAs == AutonomousSystemNumber(64_496))
        #expect(options.peerAs == AutonomousSystemNumber(64_497))
        #expect(options.localAddress == IPv4Address("198.51.100.8"))
    }

    @Test("The bgpls-shaped fixture preserves defaults and nil when an option is omitted")
    func bgplsOptionsUseDefaultsAndOptionalOmission() throws {
        let options = try BGPLSOptions.parse([])

        #expect(options.peer == IPv4Address("192.168.1.1"))
        #expect(options.port.rawValue == 179)
        #expect(options.localAs == AutonomousSystemNumber(65_001))
        #expect(options.peerAs == AutonomousSystemNumber(65_001))
        #expect(options.localAddress == nil)
    }

    @Test("An explicit empty optional value follows ArgumentParser's invalid-value path")
    func bgplsOptionsRejectExplicitEmptyOptionalValue() {
        #expect(throws: (any Error).self) {
            try BGPLSOptions.parse(["--local-address", ""])
        }
    }

    @Test("Invalid typed options follow ArgumentParser's invalid-value path")
    func bgplsOptionsRejectInvalidTypedValues() {
        let invalidArguments = [
            ["--port", "65536"],
            ["--local-as", "AS65001"],
            ["--peer", "2001:db8::1"],
        ]

        for arguments in invalidArguments {
            #expect(throws: (any Error).self) {
                try BGPLSOptions.parse(arguments)
            }
        }
    }

    @Test("Generated help renders canonical unpadded defaults")
    func helpUsesCanonicalDefaults() {
        let help = BGPLSOptions.helpMessage(columns: 100)

        #expect(help.contains("--peer <peer>"))
        #expect(help.contains("(default: 192.168.1.1/32)"))
        #expect(help.contains("--port <port>"))
        #expect(help.contains("(default: 179)"))
        #expect(help.contains("--local-as <local-as>"))
        #expect(help.contains("(default: 65001)"))
        #expect(!help.contains("Port(rawValue:"))
        #expect(!help.contains("0179"))
    }

    @Test("A P2 options fixture parses family-bound endpoints, networks, and prefix lengths")
    func p2OptionsParseTypedOverrides() throws {
        let options = try P2Options.parse([
            "--ipv4-endpoint", "198.51.100.7:1179",
            "--ipv6-endpoint", "[2001:db8::7]:2179",
            "--ipv4-network", "198.51.100.129/25",
            "--ipv6-network", "2001:db8:1::abcd/48",
            "--ipv4-prefix-length", "32",
            "--ipv6-prefix-length", "128",
        ])

        #expect(options.ipv4Endpoint.description == "198.51.100.7/32:1179")
        #expect(options.ipv6Endpoint?.description == "[2001:db8::7/128]:2179")
        #expect(options.ipv4Network.description == "198.51.100.128/25")
        #expect(options.ipv6Network?.description == "2001:db8:1::/48")
        #expect(options.ipv4PrefixLength == IPv4PrefixLength(32))
        #expect(options.ipv6PrefixLength == IPv6PrefixLength(128))
    }

    @Test("The P2 options fixture preserves canonical defaults and nil omission")
    func p2OptionsUseDefaultsAndOptionalOmission() throws {
        let options = try P2Options.parse([])

        #expect(options.ipv4Endpoint.description == "192.0.2.1/32:179")
        #expect(options.ipv6Endpoint == nil)
        #expect(options.ipv4Network.description == "192.0.2.0/24")
        #expect(options.ipv6Network == nil)
        #expect(options.ipv4PrefixLength == IPv4PrefixLength(24))
        #expect(options.ipv6PrefixLength == nil)
    }

    @Test("Explicit empty P2 option values follow ArgumentParser's invalid-value path")
    func p2OptionsRejectExplicitEmptyValues() {
        let options = [
            "--ipv4-endpoint",
            "--ipv6-endpoint",
            "--ipv4-network",
            "--ipv6-network",
            "--ipv4-prefix-length",
            "--ipv6-prefix-length",
        ]

        for option in options {
            #expect(throws: (any Error).self) {
                try P2Options.parse([option, ""])
            }
        }
    }

    @Test("Invalid P2 option values follow ArgumentParser's invalid-value path")
    func p2OptionsRejectInvalidTypedValues() {
        let invalidArguments = [
            ["--ipv4-endpoint", "192.0.2.1"],
            ["--ipv6-endpoint", "2001:db8::1:179"],
            ["--ipv4-network", "2001:db8::/64"],
            ["--ipv6-network", "192.0.2.0/24"],
            ["--ipv4-prefix-length", "33"],
            ["--ipv6-prefix-length", "129"],
        ]

        for arguments in invalidArguments {
            #expect(throws: (any Error).self) {
                try P2Options.parse(arguments)
            }
        }
    }

    @Test("Generated P2 help uses stable labels and canonical defaults")
    func p2HelpUsesCanonicalDefaults() {
        let help = P2Options.helpMessage(columns: 100)

        #expect(help.contains("--ipv4-endpoint <ipv4-endpoint>"))
        #expect(help.contains("(default: 192.0.2.1/32:179)"))
        #expect(help.contains("--ipv6-endpoint <ipv6-endpoint>"))
        #expect(help.contains("--ipv4-network <ipv4-network>"))
        #expect(help.contains("(default: 192.0.2.0/24)"))
        #expect(help.contains("--ipv6-network <ipv6-network>"))
        #expect(help.contains("--ipv4-prefix-length <ipv4-prefix-length>"))
        #expect(help.contains("(default: 24)"))
        #expect(help.contains("--ipv6-prefix-length <ipv6-prefix-length>"))
        #expect(!help.contains("IPEndpoint<"))
        #expect(!help.contains("PrefixLength<"))
    }

    @Test("A dual-stack options fixture parses mixed-family overrides")
    func dualStackOptionsParseTypedOverrides() throws {
        let options = try DualStackOptions.parse([
            "--address", "2001:db8::1",
            "--optional-address", "198.51.100.7/24",
            "--network", "2001:db8:1::abcd/48",
            "--optional-network", "198.51.100.129/25",
        ])

        #expect(options.address.description == "2001:db8::1/128")
        #expect(options.optionalAddress?.description == "198.51.100.7/24")
        #expect(options.network.description == "2001:db8:1::/48")
        #expect(options.optionalNetwork?.description == "198.51.100.128/25")
    }

    @Test("The dual-stack options fixture preserves canonical defaults and nil omission")
    func dualStackOptionsUseDefaultsAndOptionalOmission() throws {
        let options = try DualStackOptions.parse([])

        #expect(options.address.description == "192.0.2.1/32")
        #expect(options.optionalAddress == nil)
        #expect(options.network.description == "0.0.0.0/0")
        #expect(options.optionalNetwork == nil)
    }

    @Test("Explicit empty dual-stack option values follow ArgumentParser's invalid-value path")
    func dualStackOptionsRejectExplicitEmptyValues() {
        for option in ["--address", "--optional-address", "--network", "--optional-network"] {
            #expect(throws: (any Error).self) {
                try DualStackOptions.parse([option, ""])
            }
        }
    }

    @Test("Invalid dual-stack option values follow ArgumentParser's invalid-value path")
    func dualStackOptionsRejectInvalidValues() {
        let invalidArguments = [
            ["--address", "rr.example.com"],
            ["--optional-address", "192.0.2.1/33"],
            ["--network", "2001:db8::"],
            ["--optional-network", "2001:db8::/129"],
        ]

        for arguments in invalidArguments {
            #expect(throws: (any Error).self) {
                try DualStackOptions.parse(arguments)
            }
        }
    }

    @Test("Generated dual-stack option help uses canonical defaults")
    func dualStackOptionsHelpUsesCanonicalDefaults() {
        let help = DualStackOptions.helpMessage(columns: 100)

        #expect(help.contains("--address <address>"))
        #expect(help.contains("(default: 192.0.2.1/32)"))
        #expect(help.contains("--optional-address <optional-address>"))
        #expect(help.contains("--network <network>"))
        #expect(help.contains("(default: 0.0.0.0/0)"))
        #expect(help.contains("--optional-network <optional-network>"))
        #expect(!help.contains("AnyIPAddress."))
        #expect(!help.contains("AnyIPNetwork."))
    }

    @Test("Positional mixed-family arguments parse IPv4 and IPv6 combinations")
    func positionalMixedFamilyArgumentsParse() throws {
        let examples = [
            (address: "192.0.2.1", network: "2001:db8:1::abcd/48"),
            (address: "2001:db8::1/64", network: "198.51.100.129/25"),
        ]

        for example in examples {
            let arguments = try DualStackArguments.parse([example.address, example.network])
            #expect(arguments.address == AnyIPAddress(example.address))
            #expect(arguments.network == AnyIPNetwork(example.network))
        }
    }

    @Test("Positional mixed-family arguments use normal missing and invalid-value failures")
    func positionalMixedFamilyArgumentsRejectMissingEmptyAndInvalidValues() {
        let invalidArguments = [
            [String](),
            ["192.0.2.1"],
            ["", "192.0.2.0/24"],
            ["192.0.2.1", ""],
            ["rr.example.com", "192.0.2.0/24"],
            ["192.0.2.1", "192.0.2.0"],
        ]

        for arguments in invalidArguments {
            #expect(throws: (any Error).self) {
                try DualStackArguments.parse(arguments)
            }
        }
    }

    @Test("Generated positional help uses stable mixed-family labels")
    func positionalMixedFamilyHelpUsesStableLabels() {
        let help = DualStackArguments.helpMessage(columns: 100)

        #expect(help.contains("<address> <network>"))
        #expect(help.contains("Mixed-family IP address."))
        #expect(help.contains("Mixed-family IP network."))
    }
}

// This mirrors the bgpls typed option boundary and exercises real property-wrapper parsing.
private struct BGPLSOptions: ParsableArguments {
    @Option(name: .long, help: "BGP peer IPv4 address.")
    var peer: IPv4Address = IPv4Address("192.168.1.1")!

    @Option(name: .long, help: "BGP peer TCP port.")
    var port = Port(179)

    @Option(name: .long, help: "Local AS number (asplain).")
    var localAs = AutonomousSystemNumber(65_001)

    @Option(name: .long, help: "Peer AS number (asplain).")
    var peerAs = AutonomousSystemNumber(65_001)

    @Option(name: .long, help: "Optional local bind IPv4 address.")
    var localAddress: IPv4Address?
}

// Exercise P2 types through real ArgumentParser property wrappers, including optionality.
private struct P2Options: ParsableArguments {
    @Option(name: .long, help: "Default IPv4 endpoint.")
    var ipv4Endpoint = IPEndpoint(address: IPv4Address("192.0.2.1")!, port: Port(179))

    @Option(name: .long, help: "Optional IPv6 endpoint.")
    var ipv6Endpoint: IPEndpoint<V6>?

    @Option(name: .long, help: "Default IPv4 network.")
    var ipv4Network = IPv4Network("192.0.2.129/24")!

    @Option(name: .long, help: "Optional IPv6 network.")
    var ipv6Network: IPv6Network?

    @Option(name: .long, help: "Default IPv4 prefix length.")
    var ipv4PrefixLength = IPv4PrefixLength(24)!

    @Option(name: .long, help: "Optional IPv6 prefix length.")
    var ipv6PrefixLength: IPv6PrefixLength?
}

// Exercise family-erased values through defaulted and optional `@Option` properties.
private struct DualStackOptions: ParsableArguments {
    @Option(name: .long, help: "Default mixed-family IP address.")
    var address: AnyIPAddress

    @Option(name: .long, help: "Optional mixed-family IP address.")
    var optionalAddress: AnyIPAddress?

    @Option(name: .long, help: "Default mixed-family IP network.")
    var network: AnyIPNetwork

    @Option(name: .long, help: "Optional mixed-family IP network.")
    var optionalNetwork: AnyIPNetwork?

    // CHANGE: Spell out wrapper initialization to bypass the synthesized metadata path that
    // crashes for these aligned values under concurrent Swift Testing on Swift 6.2 and 6.3
    // x86_64 Linux.
    init() {
        _address = Option(
            wrappedValue: AnyIPAddress(IPv4Address(address: 0xC000_0201)),
            name: .long,
            help: "Default mixed-family IP address."
        )
        _optionalAddress = Option(
            name: .long,
            help: "Optional mixed-family IP address."
        )
        _network = Option(
            wrappedValue: AnyIPNetwork(IPv4Network(prefix: 0, prefixLength: .zero)),
            name: .long,
            help: "Default mixed-family IP network."
        )
        _optionalNetwork = Option(
            name: .long,
            help: "Optional mixed-family IP network."
        )
    }
}

// Verify the same adapter witnesses are usable by ArgumentParser's positional wrapper.
private struct DualStackArguments: ParsableArguments {
    @Argument(help: "Mixed-family IP address.")
    var address: AnyIPAddress

    @Argument(help: "Mixed-family IP network.")
    var network: AnyIPNetwork
}
