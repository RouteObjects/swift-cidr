import ConstantAccessProbe
import Dispatch
import Foundation

struct Inputs {
    var mapped: [UInt32] = []
    var groups: [UInt128] = []
    var ranges: [(UInt128, UInt8)] = []
    var nonces: [UInt64] = []

    init(seed: UInt64) {
        var state = seed
        func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
        for index in 0..<512 {
            let random = next()
            let byteLimit: UInt32 = [10, 100, 256][index % 3]
            var v4: UInt32 = 0
            for shift in [0, 8, 16, 24] {
                v4 |= (UInt32(truncatingIfNeeded: random >> shift) % byteLimit) << shift
            }
            mapped.append(v4)
            let raw = (UInt128(next()) << 64) | UInt128(next())
            let group = (raw & (UInt128.max >> 8)) | (UInt128(index % 4 == 0 ? 0x20 : 0xFF) << 120)
            groups.append(group)
            let length: UInt8 = [16, 32, 64, 96][index % 4]
            let mask = UInt128.max << (128 - Int(length))
            var prefix = group & mask
            if index % 8 == 1 { prefix |= 1 } // Reject host bits in an otherwise multicast prefix.
            ranges.append((prefix, length))
            nonces.append(next())
        }
    }
}

@inline(never)
func textDigest(_ text: String) -> UInt64 {
    var digest: UInt64 = 14695981039346656037
    for byte in text.utf8 { digest = (digest ^ UInt64(byte)) &* 1099511628211 }
    return digest ^ UInt64(text.utf8.count)
}

func expectedChecksum(_ name: String, _ inputs: Inputs) -> UInt64 {
    var result: UInt64 = 0
    for index in inputs.mapped.indices {
        let expected: UInt64
        let observed: UInt64
        switch name {
        case "mapped-format-and-digest":
            let v4 = inputs.mapped[index]
            let octets = [24, 16, 8, 0].map { String((v4 >> $0) & 255) }
            let reference = "::ffff:" + octets.joined(separator: ".")
            let actual = mappedText(v4)
            precondition(actual == reference, "Mapped output differs from independent decimal reference")
            expected = textDigest(reference)
            observed = textDigest(actual)
        case "ipv6-group-validation":
            let address = inputs.groups[index]
            expected = address >> 120 == 0xFF
                ? UInt64(truncatingIfNeeded: address) ^ UInt64(truncatingIfNeeded: address >> 64) ^ 128 : 0
            observed = multicastGroup(address)
        case "ipv6-range-validation":
            let (prefix, length) = inputs.ranges[index]
            let mask = UInt128.max << (128 - Int(length))
            expected = prefix >> 120 == 0xFF && prefix & mask == prefix
                ? UInt64(truncatingIfNeeded: prefix) ^ UInt64(truncatingIfNeeded: prefix >> 64) ^ UInt64(length) : 0
            observed = multicastRange(prefix, length)
        case "ipv6-block-read-with-wrapper":
            expected = 0xFF00000000000000 ^ 8 ^ inputs.nonces[index]
            observed = multicastBlockRead(inputs.nonces[index])
        default:
            fatalError("Unknown case: \(name)")
        }
        precondition(observed == expected, "Output checksum differs from independent reference")
        result &+= expected
    }
    return result
}

@inline(never)
func batch(_ name: String, _ inputs: Inputs, _ rounds: Int) -> UInt64 {
    var checksum: UInt64 = 0
    switch name {
    case "mapped-format-and-digest":
        for _ in 0..<rounds { for value in inputs.mapped { checksum &+= textDigest(mappedText(value)) } }
    case "ipv6-group-validation":
        for _ in 0..<rounds { for value in inputs.groups { checksum &+= multicastGroup(value) } }
    case "ipv6-range-validation":
        for _ in 0..<rounds { for (value, length) in inputs.ranges { checksum &+= multicastRange(value, length) } }
    case "ipv6-block-read-with-wrapper":
        for _ in 0..<rounds { for value in inputs.nonces { checksum &+= multicastBlockRead(value) } }
    default:
        fatalError("Unknown case: \(name)")
    }
    return checksum
}

@main
enum Main {
    static func main() throws {
        let arguments = CommandLine.arguments
        precondition(arguments.count == 5, "Usage: benchmark CASE ROUNDS SAMPLES SEED")
        let name = arguments[1]
        let rounds = Int(arguments[2])!
        let samples = Int(arguments[3])!
        let seed = UInt64(arguments[4])!
        precondition(rounds > 0 && samples > 0)
        let inputs = Inputs(seed: seed)
        let expected = expectedChecksum(name, inputs) &* UInt64(rounds)
        // Validate and initialize lazy state before timing; this measures warmed access.
        for _ in 0..<2 { precondition(batch(name, inputs, rounds) == expected) }
        var measurements: [[String: Any]] = []
        for sample in 0..<samples {
            let start = DispatchTime.now().uptimeNanoseconds
            let checksum = batch(name, inputs, rounds)
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            precondition(checksum == expected, "Timed batch result changed")
            measurements.append([
                "sample": sample,
                "elapsed_ns": elapsed,
                "operations": inputs.mapped.count * rounds,
                "ns_per_operation_batch_mean": Double(elapsed) / Double(inputs.mapped.count * rounds),
                "checksum_hex": String(checksum, radix: 16),
            ])
        }
        let output: [String: Any] = [
            "case": name, "seed": String(seed), "input_count": inputs.mapped.count,
            "rounds": rounds, "warmup_batches": 2, "validated": true, "samples": measurements,
        ]
        let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
