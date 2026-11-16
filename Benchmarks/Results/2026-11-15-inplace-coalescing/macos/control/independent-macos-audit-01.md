# Independent macOS evidence audit

Passed.

Verified 1,488 full-suite test executions and 77 differential CLI cases. Independently checked all 396 measured samples, 66 excluded warmups and 546 timed process outputs across the primary, scale and two follow-up sets. Full stdout hashes, reference provenance, native CPU/time/RSS, empty stderr, exact commands, raw sample inventory, alternating pairs, rotating case order, source/dependency/binary/runtime freezes and every reported group/paired/spread scalar pass. All cases triggered by any individual >5% elapsed/RSS regression received a separate six-pair follow-up. The failed first sandbox warmup remains preserved and contributes no valid sample. No benchmark harness was imported and no target binary, test or benchmark was run by this auditor.

- External nanosecond durations originate in preserved raw records; native time allows only a hundredth-second sanity check.
- Independent coverage references and their provenance are hash-verified; this audit does not rerun the original coverage algorithm.
- This audit verifies macOS evidence only; it makes no ARM64 Linux or x86-64 Linux performance conclusion.
- Supplemental documentation/consumer checks and retained-result probes are reported separately from this audit.
