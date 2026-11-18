# Result-retention probe

This is a focused external client of the unchanged public coalescing API. It is
separate from the primary CLI benchmark matrix. Each process makes one call with
one million IPv6 ranges, then stops at a handshake while the returned Array lives.
The non-inlined construction function has returned before that handshake, so its
input variable is no longer in scope. No closure captures the input Array.

The three cases are nested overlapping ranges, a chain of adjacent two-address
ranges, and disjoint two-address ranges. The first two produce one output range;
the control produces one million. The checkpoint reports count, capacity, element
stride, capacity bytes and the element-buffer address. That address identifies
Array element storage, not necessarily the start of its malloc allocation.

Builds use Apple Swift 6.4.2 release mode and the same client source with B/C local
upstream dependencies. The upstream's existing five dependency revisions are
copied into the client lock and verified after SwiftPM adjusts the manifest's
origin hash. A separately signed inspection copy permits `heap` and `vmmap`;
executable-section hashes must match its preserved ordinary binary. All source,
lock, binary, build-log and dependency evidence is retained in build receipts.

From the experiment directory, outside any timed runs:

```sh
python3 retention/build_probe.py B
python3 retention/build_probe.py C
```

Do not build or inspect while macOS or OrbStack benchmark measurements are active.
After the measurement coordinator clears the host, run each case as a fresh
process. For example:

```sh
python3 retention/run_probe.py B overlap
python3 retention/run_probe.py C overlap
python3 retention/run_probe.py C adjacent
python3 retention/run_probe.py B adjacent
python3 retention/run_probe.py B disjoint
python3 retention/run_probe.py C disjoint
```

The runner waits for the exact checkpoint, captures live heap addresses and VM
summary/regions, then sends the resume byte. Each invocation creates a new result
directory; failures and partial output remain. The optional `--time` flag retains
BSD time output, whose elapsed duration includes the inspection pause and whose
peak can be affected by inspection. It is not a throughput benchmark.

Interpret capacity, live allocated bytes and resident/dirty pages separately.
Baseline coalescing already reserves input-count capacity for its result, so both
variants may have the same large capacity after collapsing to one range. Candidate
compaction may retain pages that were touched during sorting, whereas baseline's
new destination may leave most capacity untouched. Conversely, freed staging
allocations can remain resident in malloc caches. Whole-process RSS alone cannot
attribute resident pages to the result buffer. Use the reported element address
and allocation/region evidence where possible, and state any attribution limits.
There is no allocator purge, memory-pressure simulation, arbitrary shrink threshold
or repeated-call workload in this probe.
