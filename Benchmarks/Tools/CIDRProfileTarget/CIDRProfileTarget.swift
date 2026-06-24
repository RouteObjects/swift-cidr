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
@_spi(Benchmark) import CIDR

/// A focused profiling executable for the IPv6 compressed formatter hot path.
///
/// `CIDRProfileTarget` is intentionally not a `swift package benchmark`
/// suite. It exists for Instruments and `xctrace` sessions that need a tight,
/// repeatable loop around one formatter scenario without the benchmark harness
/// in the sample stack.
///
/// Use this target when you need to answer where formatter time is spent:
///
/// ```bash
/// CIDRProfileTarget --case middleCompressed2 --mode string --iterations 100000000
/// CIDRProfileTarget --case middleCompressed2 --mode bytes --iterations 100000000
/// ```
///
/// The `string` mode measures the realistic public formatter path, including
/// zero-run detection, UTF-8 byte writing, `String` construction, allocation,
/// and wrapper overhead.
///
/// The `bytes` mode measures the lower-level formatter engine by writing UTF-8
/// directly into caller-provided storage. It excludes `String` construction so
/// profiler traces can separate Swift `String` cost from CIDR's zero-run finder
/// and ASCII writer.
@main
struct CIDRProfileTarget {
    static func main() throws {
        let options = try ProfileOptions.parse(CommandLine.arguments.dropFirst())
        let checksum: UInt64

        switch options.mode {
        case .string:
            checksum = runStringMode(address: options.profileCase.address, iterations: options.iterations)
        case .bytes:
            checksum = runBytesMode(address: options.profileCase.storage, iterations: options.iterations)
        }

        print("case=\(options.profileCase.rawValue) mode=\(options.mode.rawValue) iterations=\(options.iterations) checksum=\(checksum)")
    }

    @inline(never)
    private static func runStringMode(address: IPv6Address, iterations: Int) -> UInt64 {
        var checksum: UInt64 = 0

        for _ in 0..<iterations {
            let output = address.formatted(.compressed)
            checksum &+= UInt64(output.utf8.count)
            withExtendedLifetime(output) {}
        }

        return checksum
    }

    @inline(never)
    private static func runBytesMode(address: UInt128, iterations: Int) -> UInt64 {
        var checksum: UInt64 = 0

        // SAFETY: The scratch buffer is sized for the maximum compressed IPv6 literal and stays local.
        return withUnsafeTemporaryAllocation(
            of: UInt8.self,
            capacity: CIDRBenchmarkUTF8Writer.maximumCompressedIPv6AddressLiteralUTF8Count
        ) { buffer in
            // SAFETY: Rebinding the temporary UInt8 allocation as raw bytes is needed by the formatter API.
            let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

            for _ in 0..<iterations {
                let written = CIDRBenchmarkUTF8Writer.writeCompressedIPv6AddressLiteral(address, into: rawBuffer)
                // Touch output-derived state so the optimizer cannot discard the formatting work.
                checksum &+= UInt64(written)
                checksum &+= UInt64(buffer[0])
            }

            return checksum
        }
    }
}

private struct ProfileOptions {
    static let defaultIterations = 100_000_000

    let profileCase: ProfileCase
    let mode: ProfileMode
    let iterations: Int

    static func parse<Arguments: Collection>(_ arguments: Arguments) throws -> Self
    where Arguments.Element == String {
        var profileCase: ProfileCase = .middleCompressed
        var mode: ProfileMode = .string
        var iterations = defaultIterations
        var index = arguments.startIndex

        while index != arguments.endIndex {
            let argument = arguments[index]
            index = arguments.index(after: index)

            switch argument {
            case "--case":
                let value = try nextValue(for: argument, from: arguments, advancing: &index)
                guard let parsed = ProfileCase(rawValue: value) else {
                    throw ProfileError.invalidValue(option: argument, value: value, allowed: ProfileCase.allowedValues)
                }
                profileCase = parsed
            case "--mode":
                let value = try nextValue(for: argument, from: arguments, advancing: &index)
                guard let parsed = ProfileMode(rawValue: value) else {
                    throw ProfileError.invalidValue(option: argument, value: value, allowed: ProfileMode.allowedValues)
                }
                mode = parsed
            case "--iterations":
                let value = try nextValue(for: argument, from: arguments, advancing: &index)
                guard let parsed = Int(value), parsed > 0 else {
                    throw ProfileError.invalidPositiveInteger(option: argument, value: value)
                }
                iterations = parsed
            case "--help", "-h":
                throw ProfileError.helpRequested
            default:
                throw ProfileError.unknownOption(argument)
            }
        }

        return Self(profileCase: profileCase, mode: mode, iterations: iterations)
    }

    private static func nextValue<Arguments: Collection>(
        for option: String,
        from arguments: Arguments,
        advancing index: inout Arguments.Index
    ) throws -> String where Arguments.Element == String {
        guard index != arguments.endIndex else {
            throw ProfileError.missingValue(option: option)
        }

        let value = arguments[index]
        index = arguments.index(after: index)
        return value
    }
}

private enum ProfileCase: String, CaseIterable {
    case allZero
    case loopback
    case mappedHex
    case middleCompressed
    case middleCompressed2
    case simple
    case trailingCompressed

    static var allowedValues: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }

    var storage: UInt128 {
        switch self {
        case .allZero:
            return 0
        case .loopback:
            return 1
        case .mappedHex:
            return (UInt128(0xFFFF) << 32) | UInt128(0xC0000201)
        case .middleCompressed:
            return 0x2001_0db8_85a3_0000_0000_0000_0100_0020
        case .middleCompressed2:
            return 0x85a0_850a_8500_0000_0000_00af_805a_085a
        case .simple:
            return (UInt128(0x20010DB8) << 96) | 1
        case .trailingCompressed:
            return 0x2001_0db8_0001_0000_0000_0000_0000_0000
        }
    }

    var address: IPv6Address {
        IPv6Address(address: storage, prefixLength: .maximum)
    }
}

private enum ProfileMode: String, CaseIterable {
    /// Measures direct UTF-8 output into caller-provided storage.
    ///
    /// This mode is useful for isolating the formatter engine and for evaluating
    /// future direct-byte integrations such as NIO `ByteBuffer` output or
    /// logging paths that do not need an intermediate `String`.
    case bytes

    /// Measures the public compressed formatter path that returns `String`.
    ///
    /// This mode represents the cost a normal library caller pays when asking
    /// an IPv6 address for `.formatted(.compressed)`, including the unavoidable
    /// `String` construction and allocation behavior.
    case string

    static var allowedValues: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
}

private enum ProfileError: Error, CustomStringConvertible {
    case helpRequested
    case invalidPositiveInteger(option: String, value: String)
    case invalidValue(option: String, value: String, allowed: String)
    case missingValue(option: String)
    case unknownOption(String)

    var description: String {
        switch self {
        case .helpRequested:
            return Self.usage
        case .invalidPositiveInteger(let option, let value):
            return "Invalid \(option) value '\(value)'. Expected a positive integer.\n\n\(Self.usage)"
        case .invalidValue(let option, let value, let allowed):
            return "Invalid \(option) value '\(value)'. Allowed values: \(allowed).\n\n\(Self.usage)"
        case .missingValue(let option):
            return "Missing value for \(option).\n\n\(Self.usage)"
        case .unknownOption(let option):
            return "Unknown option '\(option)'.\n\n\(Self.usage)"
        }
    }

    private static let usage = """
    Usage:
      CIDRProfileTarget [--case <case>] [--mode <mode>] [--iterations <count>]

    Cases:
      \(ProfileCase.allowedValues)

    Modes:
      \(ProfileMode.allowedValues)
    """
}
