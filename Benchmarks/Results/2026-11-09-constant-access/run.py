#!/usr/bin/env python3
"""Build isolated snapshots; collect alternating warmed batch measurements."""
import argparse
import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import shutil
import statistics
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
CASES = ["mapped-format-and-digest", "ipv6-group-validation", "ipv6-range-validation", "ipv6-block-read-with-wrapper"]


def command(args, **kwargs):
    return subprocess.check_output([str(arg) for arg in args], **kwargs)


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default="a7f661a", help="Git revision for baseline Sources/CIDR")
    parser.add_argument("--output", type=Path, required=True, help="New directory; existing paths are refused")
    parser.add_argument("--build-only", action="store_true", help="Compile and save build evidence without executing benchmarks")
    parser.add_argument("--repetitions", type=int, choices=[3, 5], default=5)
    parser.add_argument("--samples", type=int, default=7)
    parser.add_argument("--target-batch-ms", type=float, default=50)
    parser.add_argument("--seed", type=int, default=20261109)
    parser.add_argument("--swiftc", default=shutil.which("swiftc"))
    parser.add_argument("--target", default=f"{platform.machine()}-apple-macosx15.0" if platform.system() == "Darwin" else None)
    options = parser.parse_args()
    if options.samples <= 0 or options.target_batch_ms <= 0:
        parser.error("samples and target batch time must be positive")
    output = options.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    root = Path(command(["git", "rev-parse", "--show-toplevel"], cwd=HERE).decode().strip())
    baseline = command(["git", "rev-parse", f"{options.baseline}^{{commit}}"], cwd=root).decode().strip()
    flags = ["-O", "-whole-module-optimization", "-parse-as-library", "-swift-version", "6"]
    if options.target:
        flags += ["-target", options.target]
    evidence = {
        "created_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "baseline_commit": baseline,
        "working_head": command(["git", "rev-parse", "HEAD"], cwd=root).decode().strip(),
        "swift_version": command([options.swiftc, "--version"], stderr=subprocess.STDOUT).decode().strip(),
        "target_info": json.loads(command([options.swiftc, "-print-target-info", *(["-target", options.target] if options.target else [])])),
        "explicit_build_target": options.target,
        "platform": platform.platform(), "machine": platform.machine(),
        "cpu_count": os.cpu_count(), "cpu_brand": platform.processor(),
        "repetitions": options.repetitions, "samples_per_process": options.samples,
        "target_batch_ms": options.target_batch_ms, "seed": options.seed,
        "measurement": "elapsed monotonic wall time; each sample is a batch mean, not individual-operation latency",
        "harness_sha256": {p.name: digest(p) for p in [HERE / "Probe.swift", HERE / "Runner.swift", HERE / "run.py"]},
        "commands": [], "source_sha256": {},
    }
    if platform.system() == "Darwin":
        try:
            evidence["cpu_brand"] = command(["sysctl", "-n", "machdep.cpu.brand_string"], stderr=subprocess.STDOUT).decode().strip()
        except subprocess.CalledProcessError as error:
            evidence["cpu_brand_lookup_error"] = error.output.decode().strip()
            try:
                hardware = json.loads(command(["system_profiler", "SPHardwareDataType", "-json"]))["SPHardwareDataType"][0]
                # Record benchmark-relevant fields only, excluding device identifiers.
                evidence["cpu_brand"] = hardware.get("chip_type", hardware.get("cpu_type", "unknown"))
                evidence["hardware"] = {key: hardware.get(key) for key in ["machine_model", "number_processors", "physical_memory"]}
            except (subprocess.CalledProcessError, KeyError, IndexError, json.JSONDecodeError) as error:
                evidence["hardware_lookup_error"] = str(error)
    (output / "source-diff.patch").write_bytes(command(["git", "diff", baseline, "--", "Sources/CIDR"], cwd=root))
    with tempfile.TemporaryDirectory(prefix="cidr-constant-access-") as temporary:
        temporary = Path(temporary)
        flags += ["-module-cache-path", str(temporary / "module-cache")]
        binaries = {}
        for variant in ["baseline", "changed"]:
            build = temporary / variant
            source = build / "Sources"
            source.mkdir(parents=True)
            if variant == "baseline":
                paths = command(["git", "ls-tree", "-r", "--name-only", baseline, "--", "Sources/CIDR"], cwd=root).decode().splitlines()
                for relative in paths:
                    path = source / Path(relative).relative_to("Sources/CIDR")
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(command(["git", "show", f"{baseline}:{relative}"], cwd=root))
            else:
                shutil.copytree(root / "Sources/CIDR", source, dirs_exist_ok=True)
            evidence["source_sha256"][variant] = {str(p.relative_to(source)): digest(p) for p in sorted(source.rglob("*.swift"))}
            steps = [
                [options.swiftc, *flags, "-cross-module-optimization", "-module-name", "CIDR", "-package-name", "swift_cidr", "-emit-module", "-emit-object", *sorted(source.rglob("*.swift")), "-emit-module-path", build / "CIDR.swiftmodule", "-o", build / "CIDR.o"],
                [options.swiftc, *flags, "-module-name", "ConstantAccessProbe", "-I", build, "-emit-module", "-emit-object", HERE / "Probe.swift", "-emit-module-path", build / "ConstantAccessProbe.swiftmodule", "-o", build / "Probe.o"],
                [options.swiftc, *flags, "-I", build, HERE / "Runner.swift", build / "CIDR.o", build / "Probe.o", "-o", build / "benchmark"],
                [options.swiftc, *flags, "-module-name", "ConstantAccessProbe", "-I", build, "-emit-assembly", HERE / "Probe.swift", "-o", output / f"{variant}-probe.s"],
            ]
            for args in steps:
                evidence["commands"].append([str(arg) for arg in args])
                write_json(output / "metadata.json", evidence)
                subprocess.run([str(arg) for arg in args], check=True)
            binaries[variant] = build / "benchmark"
        evidence["builds_completed"] = True
        write_json(output / "metadata.json", evidence)
        if options.build_only:
            print(f"Built both variants without executing timed samples: {output}")
            return

        def measure(variant, case, rounds, samples):
            return json.loads(command([binaries[variant], case, rounds, samples, options.seed]))

        calibration = {}
        rounds = {}
        for case in CASES:
            calibration[case] = measure("baseline", case, 128, 1)
            elapsed = calibration[case]["samples"][0]["elapsed_ns"]
            rounds[case] = max(1, min(1 << 20, math.ceil(128 * options.target_batch_ms * 1_000_000 / elapsed)))
        write_json(output / "calibration.json", {"measurements": calibration, "selected_rounds": rounds})
        records = []
        for repetition in range(options.repetitions):
            order = ["baseline", "changed"] if repetition % 2 == 0 else ["changed", "baseline"]
            for case in CASES:
                for variant in order:
                    print(f"repetition {repetition + 1}/{options.repetitions}: {case}: {variant}", flush=True)
                    result = measure(variant, case, rounds[case], options.samples)
                    records.append({"repetition": repetition, "variant": variant, **result})
                    write_json(output / "raw-samples.json", records)
        summary = {}
        for case in CASES:
            selected = [record for record in records if record["case"] == case]
            checksums = {sample["checksum_hex"] for record in selected for sample in record["samples"]}
            if len(checksums) != 1:
                raise RuntimeError(f"Checksum mismatch for {case}: {checksums}")
            medians = {
                variant: [statistics.median(sample["ns_per_operation_batch_mean"] for sample in record["samples"])
                          for record in selected if record["variant"] == variant]
                for variant in ["baseline", "changed"]
            }
            ratios = [changed / baseline for baseline, changed in zip(medians["baseline"], medians["changed"])]
            summary[case] = {
                "per_repetition_median_batch_mean_ns": medians,
                "paired_changed_over_baseline_ratios": ratios,
                "median_paired_ratio": statistics.median(ratios),
                "checksum_hex": checksums.pop(),
                "all_checksums_match": True,
            }
        write_json(output / "summary.json", summary)
    files = sorted(p for p in output.iterdir() if p.is_file())
    (output / "SHA256SUMS").write_text("".join(f"{digest(p)}  {p.name}\n" for p in files))
    print(f"Results: {output / 'summary.json'}")


if __name__ == "__main__":
    main()
