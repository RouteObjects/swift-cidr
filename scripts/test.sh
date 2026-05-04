#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${PACKAGE_ROOT}/.build/clang-module-cache}"
mkdir -p "${CLANG_MODULE_CACHE_PATH}"

swift_test_flags=()
source "${SCRIPT_DIR}/swift-testing-support.sh"
append_swift_testing_flags_for_command_line_tools

exec swift test --package-path "${PACKAGE_ROOT}" "${swift_test_flags[@]}" "$@"
