# Portable macOS evidence

This export contains selected correctness, timing, source/dependency/runtime freeze,
follow-up, failure, code-generation and retention records. MacTABLE.md rounds only
for display; JSON measurement values and numeric types remain unchanged. Paired
values were independently recomputed after serialization and path redaction.

Private paths use $EXPERIMENT, $REFERENCES, $DOWNLOADS, $WORKSPACE, $HOME and
$LINUX_HOME aliases. These are portability placeholders, not shell-ready paths.
MANIFEST.json binds each original relative path, byte count and SHA-256 to its
exported path, byte count and SHA-256. Hash fields inside redacted receipts still
refer to original bytes. EXPORT_RECEIPT.json binds the manifest and the export
inventory. Raw timed output, ordinary binaries, full build/test logs and heap/VM
captures remain in the original Downloads experiment.

The independent full audit imported no harness and executed no target binary.
Outside any timed run, with original paths restored, rerun its read-only checks:

```sh
python3 "$EXPERIMENT/control/audit_macos_compact.py" --label fresh-review
```

The original measurement harnesses and their frozen identities are recorded in
protocols and freeze manifests. Any new measurement uses new directories; never
pool a new candidate or silently replace an observation. This selected evidence
export does not package every input and dependency for a standalone rerun.
