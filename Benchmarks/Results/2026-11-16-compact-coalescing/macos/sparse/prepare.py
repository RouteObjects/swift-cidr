#!/usr/bin/env python3
"""Freeze two original-corpus prefixes plus one duplicate per address family."""
from pathlib import Path
import datetime
import hashlib
import ipaddress
import json
import platform
import sys

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "sparse"
ORIGINAL = Path("$REFERENCES")
PRIOR = Path("$DOWNLOADS/cidrmerge-inplace-coalescing-20261115T221013Z")


def digest(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def write_json(path, value):
    with path.open("x") as handle:
        json.dump(value, handle, indent=2)
        handle.write("\n")


def main():
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    original_freeze = json.loads((ORIGINAL / "control/freeze.json").read_text())
    source = ORIGINAL / "fixtures/mixed-disjoint/input.txt"
    assert digest(source) == original_freeze["files"]["fixtures/mixed-disjoint/input.txt"]
    with source.open("rb") as handle:
        base_lines = list(handle)
    assert len(base_lines) == 1_000_000
    first_by_family = {}
    for line in base_lines:
        family = ipaddress.ip_network(line.decode().strip(), strict=False).version
        first_by_family.setdefault(family, line)
        if len(first_by_family) == 2:
            break
    assert set(first_by_family) == {4, 6}
    cases = []
    records = []
    for count in (10_000, 1_000_000):
        name = f"mixed-sparse-duplicate-{count}"
        folder = DEST / name
        folder.mkdir(exist_ok=False)
        prefix = b"".join(base_lines[:count])
        payload = prefix + first_by_family[4] + first_by_family[6]
        input_path = folder / "input.txt"
        input_path.write_bytes(payload)
        by_family = {4: [], 6: []}
        for line in payload.splitlines():
            network = ipaddress.ip_network(line.decode(), strict=False)
            by_family[network.version].append(network)
        assert {family: len(values) for family, values in by_family.items()} == {4: count // 2 + 1, 6: count // 2 + 1}
        collapsed = [str(network) for family in (4, 6) for network in ipaddress.collapse_addresses(by_family[family])]
        assert len(collapsed) == count
        reference = ("\n".join(collapsed) + "\n").encode()
        if count == 1_000_000:
            historical = ORIGINAL / "warmup/native/mixed-disjoint/cidrmerge/mixed.stdout"
            receipt = json.loads((ORIGINAL / "warmup/native/mixed-disjoint/cidrmerge/sample.json").read_text())
            expected_hash = receipt["parts"][0]["output_sha256"]
        else:
            historical = PRIOR / "scale/mixed-disjoint-10000/reference.txt"
            receipt = json.loads((PRIOR / "scale/reference.json").read_text())
            expected_hash = next(case["output_sha256"] for case in receipt["cases"] if case["case"] == "mixed-disjoint-10000")
        assert digest(historical) == expected_hash
        assert reference == historical.read_bytes()
        output_path = folder / "reference.txt"
        output_path.write_bytes(reference)
        cases.append({"case": name, "entries": count + 2, "base_entries": count,
                      "duplicates_added": {"ipv4": 1, "ipv6": 1}, "pattern": "mixed-disjoint plus one duplicate per family",
                      "input": str(input_path.relative_to(DEST)), "input_bytes": len(payload), "input_sha256": digest(input_path),
                      "output": str(output_path.relative_to(DEST)), "output_bytes": len(reference),
                      "output_sha256": digest(output_path), "output_count": len(collapsed)})
        records.append({"case": name, "base_prefix_bytes": len(prefix), "base_prefix_sha256": hashlib.sha256(prefix).hexdigest(),
                        "original_input": str(source), "original_input_sha256": digest(source),
                        "historical_reference": str(historical), "historical_reference_sha256": expected_hash,
                        "independent_collapse_matches_historical_bytes": True,
                        "duplicate_records": {str(family): first_by_family[family].decode().strip() for family in (4, 6)}})
        print(json.dumps({"case": name, "entries": count + 2, "outputs": len(collapsed), "reference_sha256": digest(output_path)}), flush=True)
        del by_family, collapsed, payload, reference
    write_json(DEST / "reference.json", {"cases": cases, "method": "Independent Python ipaddress.collapse_addresses after adding exactly one duplicate per family; exact bytes also equal preserved original coverage references."})
    write_json(DEST / "provenance.json", {"passed": True, "started_at": started,
               "finished_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "python": sys.version,
               "platform": platform.platform(), "generator_sha256": digest(Path(__file__)),
               "original_freeze_sha256": digest(ORIGINAL / "control/freeze.json"), "reference_sha256": digest(DEST / "reference.json"),
               "records": records, "no_measurement_run": True})


if __name__ == "__main__":
    main()
