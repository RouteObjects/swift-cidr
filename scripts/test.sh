#!/usr/bin/env bash
#===----------------------------------------------------------------------===#
#
# This source file is part of the swift-cidr project.
#
# Copyright (c) 2026 Craig A. Munro
#
# Licensed under the Apache License, Version 2.0.
# See the LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0
#
#===----------------------------------------------------------------------===#

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${PACKAGE_ROOT}/.build/clang-module-cache}"
mkdir -p "${CLANG_MODULE_CACHE_PATH}"

swift_test_flags=()
source "${SCRIPT_DIR}/swift-testing-support.sh"
append_swift_testing_flags_for_command_line_tools

if [[ ${#swift_test_flags[@]} -eq 0 ]]; then
    exec swift test --package-path "${PACKAGE_ROOT}" "$@"
fi

exec swift test --package-path "${PACKAGE_ROOT}" "${swift_test_flags[@]}" "$@"
