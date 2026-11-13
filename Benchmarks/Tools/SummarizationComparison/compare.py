#!/usr/bin/env python3
# Copyright (c) 2026 Craig A. Munro
# SPDX-License-Identifier: Apache-2.0
"""Preserve matched, interleaved Benchmark exports without overwriting earlier runs."""

import argparse
import hashlib
import json
import math
import os
import platform
import re
import statistics
import subprocess
import time
from pathlib import Path


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[max(0, math.ceil(len(ordered) * fraction) - 1)]


def read_exports(directory, target):
    results = {}
    for path in sorted(directory.glob("*.histogram.samples.tsv")):
        lines = path.read_text().splitlines()
        header = lines[0]
        # Benchmark can auto-scale count metrics independently of --time-units. Normalize
        # recognized exported unit suffixes before comparing variants.
        unit_match = re.search(r"\((ns|μs|us|ms|s|ks|Ms|#|K|M|G|T|P)\)\s*$", header)
        factors = {"ns": 1, "μs": 1_000, "us": 1_000, "ms": 1_000_000,
                   "s": 1_000_000_000, "ks": 1_000_000_000_000, "Ms": 1_000_000_000_000_000,
                   "#": 1, "K": 1_000, "M": 1_000_000, "G": 1_000_000_000,
                   "T": 1_000_000_000_000, "P": 1_000_000_000_000_000}
        factor = factors[unit_match.group(1)] if unit_match else 1
        values = [float(line) * factor for line in lines[1:] if line.strip()]
        if not values:
            raise RuntimeError(f"No samples in {path}")
        stem = path.name.split(target + ".", 1)[1].removesuffix(".histogram.samples.tsv")
        name, metric = stem.rsplit(".", 1)
        batch_size = 1 if ".ranges1024." in name or ".ranges16384." in name else 1000
        # Memory high-water marks describe the process and must not be divided by batch size.
        divisor = 1 if metric.startswith("peakMemory") else batch_size
        results.setdefault(name, {})[metric] = {
            "header": header,
            "unit_multiplier": factor,
            "sample_count": len(values),
            "calls_per_sample": batch_size,
            "p50_batch": statistics.median(values),
            "p90_batch": percentile(values, 0.9),
            "p50_per_call": statistics.median(values) / divisor,
            "p90_per_call": percentile(values, 0.9) / divisor,
            "export": str(path.relative_to(directory)),
        }
    if not results:
        raise RuntimeError(f"No exported benchmarks in {directory}")
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for side in ("baseline", "candidate"):
        parser.add_argument(f"--{side}-tool", type=Path, required=True)
        parser.add_argument(f"--{side}-executable", type=Path, required=True)
        parser.add_argument(f"--{side}-preload", help="Linux LD_PRELOAD value required by the locked Benchmark plugin")
    parser.add_argument("--target", default="CIDRSummarizationBenchmarkTarget")
    parser.add_argument("--filter", default=r"^summarization\..*\.returning$")
    parser.add_argument("--metric", action="append", default=[], help="Override measured metrics; repeat for multiple metrics")
    parser.add_argument("--rounds", type=int, default=6)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.rounds < 2:
        parser.error("at least two rounds are required")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    binaries = {}
    for side in ("baseline", "candidate"):
        tool = getattr(args, side + "_tool").resolve()
        executable = getattr(args, side + "_executable").resolve()
        binaries[side] = {"tool": str(tool), "executable": str(executable),
                          "tool_sha256": digest(tool), "executable_sha256": digest(executable)}
    metadata = {"platform": platform.platform(), "machine": platform.machine(),
                "target": args.target, "filter": args.filter, "rounds": args.rounds,
                "metrics_override": args.metric,
                "binaries": binaries,
                "instrumentation_environment": {name: os.environ[name] for name in
                    ("LD_PRELOAD", "DYLD_INSERT_LIBRARIES", "SWIFT_DETERMINISTIC_HASHING") if name in os.environ},
                "sample_note": "Framework exports are quantized histogram observations, not chronological raw samples. Small cases measure 1000-call batches; per-call percentiles are batch means.",
                "commands": []}
    observations = []
    for round_index in range(args.rounds):
        order = ("baseline", "candidate") if round_index % 2 == 0 else ("candidate", "baseline")
        for side in order:
            destination = output / f"round-{round_index + 1:02d}-{side}"
            destination.mkdir()
            command = [binaries[side]["tool"], "--benchmark-executable-paths",
                       binaries[side]["executable"], "--command", "run", "--format",
                       "histogramSamples", "--baseline-storage-path", str(output / "baselines"),
                       "--grouping", "benchmark", "--path", str(destination), "--no-progress",
                       "--time-units", "nanoseconds", "--filter", args.filter]
            for metric in args.metric:
                command.extend(["--metrics", metric])
            started = time.time()
            environment = os.environ.copy()
            preload = getattr(args, side + "_preload")
            if preload is not None:
                environment["LD_PRELOAD"] = preload
            with (destination / "run.log").open("w") as log:
                completed = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, env=environment)
            record = {"round": round_index + 1, "side": side, "command": command,
                      "started_unix": started, "seconds": time.time() - started,
                      "exit_code": completed.returncode, "LD_PRELOAD": environment.get("LD_PRELOAD")}
            metadata["commands"].append(record)
            (output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
            if completed.returncode:
                raise RuntimeError(f"Benchmark failed; preserved {destination / 'run.log'}")
            measurements = read_exports(destination, args.target)
            observations.append({"round": round_index + 1, "side": side, "results": measurements})
            (output / "observations.json").write_text(json.dumps(observations, indent=2) + "\n")
            print(f"round {round_index + 1}/{args.rounds} {side}: {len(measurements)} cases", flush=True)

    pairs = {}
    for round_index in range(1, args.rounds + 1):
        sides = {item["side"]: item["results"] for item in observations if item["round"] == round_index}
        if sides["baseline"].keys() != sides["candidate"].keys():
            raise RuntimeError("Baseline/candidate benchmark names differ")
        for name, metrics in sides["baseline"].items():
            for metric, baseline in metrics.items():
                candidate = sides["candidate"][name][metric]
                entry = pairs.setdefault(name, {}).setdefault(metric, {"baseline": [], "candidate": [], "ratios": []})
                before, after = baseline["p50_per_call"], candidate["p50_per_call"]
                entry["baseline"].append(before)
                entry["candidate"].append(after)
                entry["ratios"].append(after / before if before else None)
    summary = {}
    for name, metrics in pairs.items():
        summary[name] = {}
        for metric, data in metrics.items():
            ratios = [value for value in data["ratios"] if value is not None]
            ratio = statistics.median(ratios) if ratios else None
            summary[name][metric] = {"baseline_median": statistics.median(data["baseline"]),
                                     "candidate_median": statistics.median(data["candidate"]),
                                     "paired_ratios": data["ratios"],
                                     "median_paired_change_percent": 100 * (ratio - 1) if ratio is not None else None}
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
