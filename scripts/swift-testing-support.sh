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

append_swift_testing_flags_for_command_line_tools() {
    local developer_dir
    developer_dir="${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || true)}"

    local testing_framework_dir="${developer_dir}/Library/Developer/Frameworks"
    local testing_interop_dir="${developer_dir}/Library/Developer/usr/lib"

    if [[ "${developer_dir}" == "/Library/Developer/CommandLineTools" \
        && -d "${testing_framework_dir}/Testing.framework" \
        && -f "${testing_interop_dir}/lib_TestingInterop.dylib" ]]; then
        # Standalone Command Line Tools 26.4.1 installs Swift Testing
        # outside the default paths used by SwiftPM's test compile and launch.
        swift_test_flags+=(
            -Xswiftc -F
            -Xswiftc "${testing_framework_dir}"
            -Xlinker -rpath
            -Xlinker "${testing_framework_dir}"
            -Xlinker -rpath
            -Xlinker "${testing_interop_dir}"
        )
    fi
}
