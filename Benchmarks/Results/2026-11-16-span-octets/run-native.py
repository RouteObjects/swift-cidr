#!/usr/bin/env python3
"""Run only the six octet-construction workloads, retaining histogram batch samples."""
import argparse
import hashlib
import json
import math
import platform
import statistics
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[3])
args = parser.parse_args()
if platform.system() != "Darwin" or platform.machine() != "arm64":
    parser.error("This collector reproduces native ARM64 macOS measurements")
repo = args.repo.resolve()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=False)

def capture(*command):
    return subprocess.check_output(command, cwd=repo, text=True, stderr=subprocess.STDOUT).strip()

source_paths = sorted((repo / "Sources/CIDR").glob("*.swift")) + [
    repo / "Benchmarks/CIDRBenchmarkTarget/CIDRBenchmarkTarget.swift",
    repo / "Package.swift", repo / "Package.resolved",
    repo / "Benchmarks/Package.swift", repo / "Benchmarks/Package.resolved",
]
source_hashes = {
    str(path.relative_to(repo)): hashlib.sha256(path.read_bytes()).hexdigest()
    for path in source_paths
}
metadata = {
    "git_head": capture("git", "rev-parse", "HEAD"),
    "compiler": capture("xcrun", "swift", "--version"),
    "xcode": capture("xcodebuild", "-version"),
    "os": capture("sw_vers"),
    "architecture": platform.machine(),
    "hardware": capture("sysctl", "-n", "machdep.cpu.brand_string"),
    "memory_bytes": capture("sysctl", "-n", "hw.memsize"),
    "source_sha256": source_hashes,
    "iterations_per_batch": 1_000_000,
    "warmup_batches": 5,
    "max_duration_seconds_per_case": 2,
    "repetitions": 3,
    "qualification": "Native ARM64 only. Samples are histogram-quantized batch measurements, not per-call latency or chronological samples. Span cases include record selection and slicing; InlineArray controls use invariant operands. No before/after speedup comparison.",
    "commands": [],
}
for repetition in range(1, 4):
    run_output = output / f"run-{repetition:02d}"
    run_output.mkdir()
    command = [
        "swift", "package", "--disable-sandbox", "--disable-automatic-resolution",
        "--package-path", str(repo / "Benchmarks"),
        "--allow-writing-to-package-directory", "benchmark",
        "--target", "CIDRBenchmarkTarget",
        "--filter", r"^currency\.ipAddress\.v[46]\.initOctet(s|Span\.(aligned|offset1))$",
        "--format", "histogramSamples", "--time-units", "nanoseconds",
        "--path", str(run_output), "--no-progress",
    ]
    metadata["commands"].append([
        part.replace(str(output), "$OUTPUT").replace(str(repo), "$REPO")
        for part in command
    ])
    with (output / f"run-{repetition:02d}.log").open("w") as log:
        subprocess.run(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT, check=True)
    exports = {}
    exported_paths = sorted(run_output.glob("*.histogram.samples.tsv"))
    assert len(exported_paths) >= 6, "Benchmark export did not contain all six workloads"
    for path in exported_paths:
        lines = path.read_text().splitlines()
        values = [int(value) for value in lines[1:]]
        assert values, f"No samples in {path.name}"
        exports[path.name] = {"header": lines[0], "values": values}
    assert sum("wall clock" in item["header"].lower() for item in exports.values()) == 6
    # Bundle the exact TSV headers and integer samples into one JSON artifact per repetition.
    (run_output / "samples.json").write_text(json.dumps(exports, indent=2) + "\n")
    for path in exported_paths:
        path.unlink()
    print(f"Completed native repetition {repetition}/3", flush=True)

assert all(hashlib.sha256((repo / path).read_bytes()).hexdigest() == value
           for path, value in source_hashes.items()), "Measured source changed during execution"

rows = {}
for path in sorted(output.glob("run-*/samples.json")):
    for name, entry in json.loads(path.read_text()).items():
        name = name.removeprefix("Current_run.CIDRBenchmarkTarget.").removesuffix(".histogram.samples.tsv")
        case, metric = name.rsplit(".", 1)
        values = sorted(entry["values"])
        rows.setdefault(case, {}).setdefault(metric, []).append({
            "run": path.parent.name, "samples": len(values),
            "p50": values[math.ceil(len(values) * .5) - 1],
            "p75": values[math.ceil(len(values) * .75) - 1],
            "p90": values[math.ceil(len(values) * .9) - 1],
            "max": max(values), "nonzero_samples": sum(value != 0 for value in values),
            "unit": entry["header"],
        })
summary = {}
for case, metrics in sorted(rows.items()):
    batches = metrics["wallClock"]
    medians = [batch["p50"] / metadata["iterations_per_batch"] for batch in batches]
    summary[case] = {
        "median_batch_mean_ns_per_iteration": statistics.median(medians),
        "run_median_range_ns": [min(medians), max(medians)],
        "batch_samples_per_run": [batch["samples"] for batch in batches],
        "metrics_per_run": metrics,
    }
(output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
(output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
checksums = []
for path in sorted(output.rglob("*")):
    if path.is_file():
        checksums.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(output)}")
(output / "SHA256SUMS").write_text("\n".join(checksums) + "\n")
