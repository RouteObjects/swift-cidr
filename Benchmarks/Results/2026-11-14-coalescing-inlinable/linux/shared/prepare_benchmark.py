#!/usr/bin/env python3
"""Freeze after tests and externally reviewed generated-code gate; never starts timings."""
import sys
from common import ROOT, digest, disk_guard, host_snapshot, load, verify_fixtures, verify_sources, write_json


def main():
    assert sys.platform == 'linux'
    disk_guard()
    result = load(ROOT / 'control/build-tests/summary.json')
    assert result['passed'] and result['test_executions'] == 1414, result
    gate = load(ROOT / 'control/codegen-gate.json')
    assert gate['passed']
    for v in ('B', 'C'):
        current = digest(ROOT / 'bin' / v)
        assert current == result['bin'][v]
        assert current == gate['binary_sha256'][v]
    verify_sources()
    verify_fixtures()
    files = ['bin/B', 'bin/C', 'control/config.json', 'control/runtime.json', 'control/common.py',
             'control/linux_runner.py', 'control/run_matched.py', 'control/prepare_benchmark.py',
             'control/source-reference.json', 'control/reference.json', 'control/matched-protocol.json',
             'control/codegen-gate.json', 'control/build-tests/summary.json']
    files += list(load(ROOT / 'control/source-reference.json')['files'])
    write_json(ROOT / 'control/pre-benchmark-freeze.json', {'files': {p: digest(ROOT / p) for p in files}})
    write_json(ROOT / 'control/host-before-benchmark.json', host_snapshot())
    print('Frozen baseline/candidate, source, runtime, protocol and references; timing requires separate launch.', flush=True)


if __name__ == '__main__':
    main()
