@_spi(NIO) import CIDR

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

        return withUnsafeTemporaryAllocation(
            of: UInt8.self,
            capacity: CIDRUTF8Writer.maximumCompressedIPv6AddressLiteralUTF8Count
        ) { buffer in
            let rawBuffer = UnsafeMutableRawBufferPointer(buffer)

            for _ in 0..<iterations {
                let written = CIDRUTF8Writer.writeCompressedIPv6AddressLiteral(address, into: rawBuffer)
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
        IPv6Address(address: storage, prefixLength: IPv6PrefixLength(128)!)
    }
}

private enum ProfileMode: String, CaseIterable {
    case bytes
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
