# Independent macOS evidence audit

Passed.

Verified 1,490 full-suite test executions and 77 differential CLI cases. Independently checked all 504 measured samples, 84 excluded warmups and 672 timed child outputs across 6 separate sets. Full stdout hashes, reference provenance, native CPU/time/RSS, empty stderr, exact commands, raw sample inventory, alternating pairs, rotating case order, source/dependency/binary/runtime freezes and every reported group/paired/spread scalar pass. All cases triggered by any individual >5% elapsed/RSS regression received a separate six-pair follow-up. No benchmark harness was imported and no target binary, test or benchmark was run by this auditor.

- External nanosecond durations originate in preserved raw records; native time allows only a hundredth-second sanity check.
- Independent coverage references and their provenance are hash-verified; this audit does not rerun the original coverage algorithm.
- This audit verifies macOS evidence only; it makes no ARM64 Linux or x86-64 Linux performance conclusion.
- Supplemental documentation/consumer checks are reported separately; retention and static codegen bindings are audited without rerunning their tools.
