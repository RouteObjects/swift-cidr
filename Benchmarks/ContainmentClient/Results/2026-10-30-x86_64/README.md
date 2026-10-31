# Native x86-64 Containment Validation

Captured on `swift-dev` in an Ubuntu 24.04.5 LXC container running natively on
Intel x86-64 hardware. This is not emulated AMD64 evidence.

- Swift 6.2.4 and 6.3.3; four complete test runs, each passing 269 tests in 29 suites.
- Unchanged benchmark and dependency pins; only the three core `@inlinable`
  annotations differ between baseline and patched snapshots.
- Eight timing captures in baseline/patched/patched/baseline order per toolchain.
- Each case has 41 measured batches per process, 25 scans per batch, and 20,000
  prefix checks per scan. Five warmup batches are excluded from the CSV files.

[comparison.csv](comparison.csv) pools 82 batch means per case and variant.
These are batch-mean scan times, not individual-call percentiles or admission
decision timings. Per-run CSV and summary files preserve baseline variability.
[verification.json](verification.json) records test, source-integrity, and code
generation checks. The `*-scanV4.s` and `*-scanV6.s` files extract the typed loops
from the complete compressed disassembly logs.

Each command has a JSON record with exact arguments, time, and exit status.
Build/test output is retained as `*.log.gz`. The two Python drivers are archival
and contain machine-specific paths; use the parent benchmark README for the
portable benchmark command.

Verify this bundle from this directory with:

```bash
shasum -a 256 -c SHA256SUMS
```

The earlier ARM64 bundle and all admission benchmark snapshots are unchanged.
