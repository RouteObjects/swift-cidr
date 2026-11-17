#!/usr/bin/env python3
"""Compile the real CIDR module and independent public-client assembly probes.

Requires macOS with Xcode's Swift toolchain and SDK selected through xcrun.
No SwiftPM build directories, checked-in source, or existing evidence are changed.
"""

import argparse
import hashlib
import json
import platform
import shlex
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def capture(command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout.strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--output", type=Path, required=True, help="New evidence directory")
    args = parser.parse_args()
    repo = args.repo.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    probe = Path(__file__).resolve().with_name("Probe.swift")
    swiftc = capture(["xcrun", "--find", "swiftc"])
    demangler = capture(["xcrun", "--find", "swift-demangle"])
    sdk = capture(["xcrun", "--sdk", "macosx", "--show-sdk-path"])
    sources = sorted((repo / "Sources" / "CIDR").glob("*.swift"))
    metadata = {
        "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        "compiler": capture([swiftc, "--version"]),
        "host_machine": platform.machine(),
        "host_os": platform.platform(),
        "sdk_version": capture(["xcrun", "--sdk", "macosx", "--show-sdk-version"]),
        "repository_head": capture(["git", "-C", str(repo), "rev-parse", "HEAD"]),
        "source_sha256": {str(path.relative_to(repo)): digest(path) for path in sources},
        "probe_sha256": digest(probe),
        "script_sha256": digest(Path(__file__).resolve()),
        "commands": [],
        "scope": "Assembly inspection only; no executable or timing measurements. x86_64 is cross-compiled.",
    }

    with tempfile.TemporaryDirectory(prefix="cidr-span-public-client-") as scratch_name:
        scratch = Path(scratch_name)
        substitutions = [
            (str(probe), "{probe}"),
            (str(scratch), "{scratch}"),
            (str(output), "{output}"),
            (str(repo), "{repo}"),
            (swiftc, "{swiftc}"),
            (sdk, "{sdk}"),
        ]

        def run(command, log_path):
            portable_command = list(map(str, command))
            for old, new in substitutions:
                portable_command = [argument.replace(old, new) for argument in portable_command]
            metadata["commands"].append(shlex.join(portable_command))
            result = subprocess.run(command, capture_output=True, text=True)
            log_path.write_text(result.stdout + result.stderr)
            result.check_returncode()

        for arch in ("arm64", "x86_64"):
            target = f"{arch}-apple-macosx15.0"
            modules = scratch / arch
            modules.mkdir()
            common = [
                swiftc, "-swift-version", "6", "-target", target, "-sdk", sdk,
                "-module-cache-path", str(scratch / "module-cache"), "-O", "-parse-as-library",
            ]
            run(
                common + [
                    "-whole-module-optimization", "-cross-module-optimization",
                    "-package-name", "swift_cidr",
                    "-module-name", "CIDR", "-emit-module", "-emit-module-path",
                    str(modules / "CIDR.swiftmodule"),
                ] + list(map(str, sources)),
                output / f"{arch}-module.log",
            )
            assembly = output / f"{arch}-client.s"
            run(
                common + [
                    "-strict-memory-safety", "-warnings-as-errors", "-module-name", "SpanClient",
                    "-package-name", "span_client",
                    "-I", str(modules), "-emit-assembly", str(probe), "-o", str(assembly),
                ],
                output / f"{arch}-client.log",
            )
            result = subprocess.run(
                [demangler], input=assembly.read_text(), capture_output=True, text=True, check=True
            )
            (output / f"{arch}-client.demangled.s").write_text(result.stdout)
            print(f"Compiled CIDR and separate public-client probe: {target}")

    (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    checksums = [f"{digest(path)}  {path.name}" for path in sorted(output.iterdir()) if path.is_file()]
    (output / "SHA256SUMS").write_text("\n".join(checksums) + "\n")


if __name__ == "__main__":
    main()
