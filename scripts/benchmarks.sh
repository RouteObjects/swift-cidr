#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BENCHMARK_PACKAGE_ROOT="${PACKAGE_ROOT}/Benchmarks"
TARGET="${CIDR_BENCHMARK_TARGET:-CIDRBenchmarkTarget}"

swift_test_flags=()
source "${SCRIPT_DIR}/swift-testing-support.sh"

usage() {
    cat <<EOF
Usage: ./scripts/benchmarks.sh <command> [swift-package-benchmark args...]

Commands:
  build    Build the benchmark target in release mode
  test     Run the benchmark package tests
  run      Run the benchmark suite
  check    Check committed benchmark thresholds
  update   Update committed benchmark thresholds
  graph    Render parser benchmark graphs with youplot
  help     Show this help text

Examples:
  ./scripts/benchmarks.sh build
  ./scripts/benchmarks.sh run --filter '^parser\\.pton6v4\\.'
  ./scripts/benchmarks.sh check
  ./scripts/benchmarks.sh update --filter '^parser\\.'
  ./scripts/benchmarks.sh graph
EOF
}

if [[ ! -f "${BENCHMARK_PACKAGE_ROOT}/Package.swift" ]]; then
    echo "error: could not find Benchmarks/Package.swift at ${BENCHMARK_PACKAGE_ROOT}" >&2
    exit 1
fi

command="${1:-help}"
if [[ $# -gt 0 ]]; then
    shift
fi

case "${command}" in
build)
    exec swift build -c release --package-path "${BENCHMARK_PACKAGE_ROOT}" --target "${TARGET}" "$@"
    ;;
test)
    benchmark_test_file=""
    if [[ -d "${BENCHMARK_PACKAGE_ROOT}/Tests" ]]; then
        benchmark_test_file="$(find "${BENCHMARK_PACKAGE_ROOT}/Tests" -type f -name '*.swift' -print -quit)"
    fi

    if [[ -z "${benchmark_test_file}" ]]; then
        echo "No benchmark package tests are currently defined."
        exit 0
    fi
    append_swift_testing_flags_for_command_line_tools
    exec swift test --package-path "${BENCHMARK_PACKAGE_ROOT}" "${swift_test_flags[@]}" "$@"
    ;;
run)
    exec swift package --package-path "${BENCHMARK_PACKAGE_ROOT}" benchmark --target "${TARGET}" "$@"
    ;;
check)
    exec swift package --package-path "${BENCHMARK_PACKAGE_ROOT}" benchmark thresholds check --target "${TARGET}" --path "${BENCHMARK_PACKAGE_ROOT}/Thresholds" "$@"
    ;;
update)
    exec swift package --package-path "${BENCHMARK_PACKAGE_ROOT}" --allow-writing-to-package-directory benchmark thresholds update --target "${TARGET}" --path "${BENCHMARK_PACKAGE_ROOT}/Thresholds" "$@"
    ;;
graph)
    exec "${SCRIPT_DIR}/benchmark-parser-graphs.sh" "$@"
    ;;
help | -h | --help)
    usage
    ;;
*)
    echo "error: unknown command '${command}'" >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac
