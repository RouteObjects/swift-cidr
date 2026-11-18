# Portable macOS evidence

This export contains selected correctness, timing, source/dependency/runtime freeze,
follow-up, failure and retention records. Read MacTABLE.md for the rounded display
tables; JSON measurement values and numeric types are unchanged. Paired changes
were recomputed again after redaction and serialization. The independent full
audit imported no timing harness and launched no target binary.

Private paths use $EXPERIMENT, $REFERENCES, $DOWNLOADS, $WORKSPACE, $HOME and
$LINUX_HOME aliases. They are portability placeholders, not shell-ready paths.
System toolchain paths remain when they disclose no private home directory.

MANIFEST.json binds every selected original relative path, original byte count and
SHA-256 to its exported path, byte count and SHA-256. Redacted JSON hashes therefore
differ from originals where path strings changed. Original SHA fields inside
receipts continue to refer to original bytes. EXPORT_RECEIPT.json binds the
manifest and all export artifacts through a deterministic inventory fingerprint.

Raw timed stdout, ordinary binaries, test logs and full heap/VM captures remain in
the preserved Downloads experiment. Their recorded hashes, audit receipts and
retention address-linkage summary are included here. No prior report or original
observation was replaced. Source/toolchain/reference freezes are provenance
records; they do not package all original inputs or make this directory a complete
standalone rerun environment.

With the original experiment layout restored and aliases set locally, reproduce
the evidence checks outside any timed run:

```sh
python3 "$EXPERIMENT/control/audit_macos_inplace.py" --label fresh-review
```

The original primary/scale/follow-up reproduction scripts and their frozen
identities are recorded in the selected protocols and freeze manifests. Reruns
must use fresh result directories and remain separate from the retained samples.
