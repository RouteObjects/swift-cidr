import CIDR

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

enum InputPattern: String {
    case overlap
    case adjacent
    case disjoint
    case sparse
}

// Returning from this non-inlined function ends the input variable's lifetime
// before the caller reaches the checkpoint. Only the returned Array escapes.
@inline(never)
private func makeResult(pattern: InputPattern, count: Int) -> [IPv6AddressRange] {
    var input: [IPv6AddressRange] = []
    input.reserveCapacity(count + (pattern == .sparse ? 1 : 0))
    for index in 0..<count {
        let offset = UInt128(index)
        let lower: UInt128
        let upper: UInt128
        switch pattern {
        case .overlap:
            lower = 0
            upper = offset + 1
        case .adjacent:
            lower = offset * 2
            upper = lower + 1
        case .disjoint, .sparse:
            lower = offset * 4
            upper = lower + 1
        }
        input.append(
            IPv6AddressRange(
                lowerBound: IPv6Address(address: lower),
                upperBound: IPv6Address(address: upper)
            )!
        )
    }
    if pattern == .sparse { input.append(input[count / 2]) }
    return IPv6AddressRange.coalescing(input)
}

// Direct POSIX output avoids a buffered stdout handshake and Foundation Data.
@inline(never)
private func emit(_ line: String) {
    let bytes = Array((line + "\n").utf8)
    bytes.withUnsafeBytes { buffer in
        var sent = 0
        while sent < buffer.count {
            let amount = write(STDOUT_FILENO, buffer.baseAddress!.advanced(by: sent), buffer.count - sent)
            if amount < 0 && errno == EINTR { continue }
            guard amount > 0 else { exit(74) }
            sent += amount
        }
    }
}

guard CommandLine.arguments.count == 2,
    let pattern = InputPattern(rawValue: CommandLine.arguments[1])
else {
    exit(64)
}

let inputCount = 1_000_000
let result = makeResult(pattern: pattern, count: inputCount)
let firstLower = result.first!.lowerBound.address
let lastUpper = result.last!.upperBound.address
let actualInputCount = inputCount + (pattern == .sparse ? 1 : 0)
let expectedCount = pattern == .disjoint || pattern == .sparse ? inputCount : 1
let expectedUpper: UInt128
switch pattern {
case .overlap: expectedUpper = UInt128(inputCount)
case .adjacent: expectedUpper = UInt128(inputCount) * 2 - 1
case .disjoint, .sparse: expectedUpper = UInt128(inputCount - 1) * 4 + 1
}
guard result.count == expectedCount, firstLower == 0, lastUpper == expectedUpper else {
    exit(65)
}

withExtendedLifetime(result) {
    // The pointer is only borrowed while obtaining its numeric address. The
    // result itself remains alive across the external inspection checkpoint.
    let elementAddress = result.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress!) }
    let stride = MemoryLayout<IPv6AddressRange>.stride
    emit(
        "{\"phase\":\"result-only\",\"pid\":\(getpid()),\"case\":\"\(pattern.rawValue)\","
            + "\"base_input_count\":\(inputCount),\"input_count\":\(actualInputCount),\"result_count\":\(result.count),\"capacity\":\(result.capacity),"
            + "\"element_stride\":\(stride),\"capacity_bytes\":\(result.capacity * stride),"
            + "\"element_address\":\"0x\(String(elementAddress, radix: 16))\","
            + "\"first_lower\":\"\(firstLower)\",\"last_upper\":\"\(lastUpper)\"}"
    )
    var byte: UInt8 = 0
    var received: Int
    repeat {
        received = read(STDIN_FILENO, &byte, 1)
    } while received < 0 && errno == EINTR
    guard received == 1 else { exit(74) }
    emit("{\"phase\":\"resumed\",\"result_count\":\(result.count)}")
}
