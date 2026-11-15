# Portable copies of historical benchmark evidence

These repository files are publication copies. Host-specific path prefixes in
the original evidence have been replaced with the named placeholders below,
including paths used as JSON object keys, command arguments, captured diagnostic
text, and historical helper literals. The original local Markdown artifact link
is now an inline placeholder path rather than a link that cannot resolve here.

No timing, CPU, memory, count, output digest, source digest, binary digest, or
recorded audit result has changed. The original raw Downloads evidence bundles
and exact pre-publication repository copies are retained outside the repository.

Embedded SHA-256 values and successful audit receipts describe the original
immutable evidence, **not the bytes of these path-substituted copies**. In
particular, do not compare an original recorded summary/helper hash directly
against a transformed file. [The copy manifest](portable-copy-manifest.json)
records the original and published SHA-256 for every changed existing file.
Unlisted existing files are byte-for-byte unchanged. The private exact-prefix
mapping and original copies are retained with the publication work records;
reversing the mapping, single Markdown-link conversion and two publication
notices was checked to recover every original byte. The manifest does not hash
itself or this new note.

| Placeholder | Meaning |
| --- | --- |
| `SWIFT_CIDR_REPOSITORY_ROOT` | The upstream source checkout used to publish the original report. |
| `MAC_EVIDENCE_ROOT` | The original macOS coalescing evidence bundle (20261115T040514Z). |
| `LINUX_EVIDENCE_ROOT` | The local Linux evidence bundle (20261115T043459Z). |
| `LINUX_REMOTE_EVIDENCE_ROOT` | The retained x86-64 host evidence bundle (20261115T043459Z). |
| `COMPETITOR_EVIDENCE_ROOT` | The original matched competitor evidence bundle (20261114T210745Z). |
| `BENCHMARK_SSH_CONTROL_SOCKET` | The historical SSH connection control socket; not needed for reproducing measurements. |
| `CIDRMERGE_REPOSITORY_ROOT` | The downstream source checkout used to publish the original report. |
| `SWIFTLY_TOOLCHAINS_ROOT` | The x86-64 host Swiftly toolchain installation directory. |

Placeholders are evidence labels, not environment-variable expansion syntax or
usable filesystem locations. The copied `linux/control/publish_linux_report.py`
is a historical publishing helper and requires explicit path remapping before
execution. Other copied audit/report helpers also require the original evidence
layout and original bytes when validating recorded hashes. This directory is a
compact report, not the complete runnable evidence bundle.

The generic matched-run harness and its
[reproduction instructions](linux/shared/README.md) are unchanged. To reproduce
the experiment, provide the documented source, fixture and dependency layout and
a fresh configuration containing your actual toolchain path. Remap historical
configuration placeholders before reuse; retain original bytes when verifying
the historical run. No measurements were rerun for this publication fix.
