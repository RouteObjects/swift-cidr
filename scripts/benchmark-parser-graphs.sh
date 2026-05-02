#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
BENCHMARK_PACKAGE_ROOT="${PACKAGE_ROOT}/Benchmarks"
TARGET="CIDRBenchmarkTarget"
FILTER='^parser\..*'

if ! command -v swift >/dev/null 2>&1; then
    echo "error: swift is not available in PATH" >&2
    exit 1
fi

if ! command -v uplot >/dev/null 2>&1; then
    echo "error: uplot is not installed. Install it with: brew install youplot" >&2
    exit 1
fi

if [[ ! -f "${BENCHMARK_PACKAGE_ROOT}/Package.swift" ]]; then
    echo "error: could not find Benchmarks/Package.swift at ${BENCHMARK_PACKAGE_ROOT}" >&2
    exit 1
fi

run_graph() {
    local metric="$1"
    local title="$2"
    local output_file

    output_file="$(mktemp)"

    echo
    echo "=== ${title} (${metric}) ==="

    # capture benchmark output first so a SwiftPM failure does not get piped into uplot as bogus TSV input.
    if ! (
        cd "${BENCHMARK_PACKAGE_ROOT}"
        swift package benchmark \
            --target "${TARGET}" \
            --filter "${FILTER}" \
            --metric "${metric}" \
            --format histogramPercentiles \
            --path stdout \
            --no-progress >"${output_file}"
    ); then
        cat "${output_file}" >&2
        rm -f "${output_file}"
        return 1
    fi

    if [[ ! -s "${output_file}" ]]; then
        echo "error: benchmark export was empty for filter '${FILTER}' and metric '${metric}'" >&2
        rm -f "${output_file}"
        return 1
    fi

    uplot lineplot -H -w 120 -h 30 <"${output_file}"
    rm -f "${output_file}"
}

# wall-clock, total mallocs, and retain count are the three high-signal parser metrics for latency, allocation pressure, and ARC traffic.
run_graph "wallClock" "Parser Wall Clock"
run_graph "mallocCountTotal" "Parser Total Mallocs"
run_graph "retainCount" "Parser Retain Count"
