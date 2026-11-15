"""Shared Linux validation helpers; no target runs at import time."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CASES = ['ipv4-disjoint', 'ipv6-disjoint', 'mixed-disjoint', 'mixed-permuted',
         'mixed-overlap', 'mixed-adjacent', 'bgp-like-ipv4', 'range-derived-mixed']
NATIVE_CASES = ['mixed-disjoint', 'mixed-permuted', 'mixed-overlap']
MIN_FREE = 3 * 1024 ** 3


def stamp():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def load(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x') as f:
        json.dump(value, f, indent=2)
        f.write('\n')


def config():
    d = load(ROOT / 'control/config.json')
    p = Path(d['swift'])
    assert p.is_absolute() and p.is_file(), p
    assert isinstance(d['jobs'], int) and d['jobs'] > 0
    return d


def disk_guard():
    free = shutil.disk_usage(ROOT).free
    if free < MIN_FREE:
        raise RuntimeError(f'Only {free} bytes free; minimum is {MIN_FREE}. No cleanup performed.')
    return free


def verify_sources():
    expected = load(ROOT / 'control/source-reference.json')
    for rel, wanted in expected['files'].items():
        if digest(ROOT / rel) != wanted:
            raise RuntimeError(f'Source/reference mismatch: {rel}')
    return len(expected['files'])


def verify_fixtures():
    reference = load(ROOT / 'control/reference.json')
    for rel, info in reference['inputs'].items():
        p = ROOT / rel
        assert p.stat().st_size == info['bytes'], rel
        assert digest(p) == info['sha256'], rel
    return len(reference['inputs'])


def verify_pins(variant, package):
    expected = load(ROOT / 'control/source-reference.json')['dependency_pins']
    state = load(ROOT / 'build' / variant / package / 'workspace-state.json')
    records = {}
    for dep in state['object']['dependencies']:
        checkout = dep['state'].get('checkoutState')
        if checkout is None:
            continue
        identity = dep['packageRef']['identity']
        assert identity in expected, identity
        assert checkout['revision'] == expected[identity]['revision'], (identity, checkout)
        if 'version' in checkout:
            assert checkout['version'] == expected[identity].get('version'), identity
        actual = subprocess.check_output(['git', '-C', str(ROOT / 'build' / variant / package / 'checkouts' / dep['subpath']), 'rev-parse', 'HEAD'], text=True).strip()
        assert actual == checkout['revision'], (identity, actual)
        records[identity] = checkout
    wanted = set(load(ROOT / 'control/source-reference.json')['package_pin_identities'][package])
    assert set(records) == wanted, (package, set(records), wanted)
    return records


def host_snapshot():
    cfg = config()
    def capture(command):
        p = subprocess.run(command, text=True, capture_output=True)
        return {'command': command, 'exit_code': p.returncode, 'stdout': p.stdout, 'stderr': p.stderr}
    return {'at': stamp(), 'platform_label': cfg['platform_label'], 'machine': platform.machine(),
            'kernel': platform.release(), 'affinity': sorted(os.sched_getaffinity(0)),
            'loadavg': Path('/proc/loadavg').read_text(), 'memory': Path('/proc/meminfo').read_text(),
            'cpuinfo': Path('/proc/cpuinfo').read_text(), 'disk_free_bytes': disk_guard(),
            'swift': capture([cfg['swift'], '--version']),
            'os_release': Path('/etc/os-release').read_text(),
            'cpu_max': Path('/sys/fs/cgroup/cpu.max').read_text() if Path('/sys/fs/cgroup/cpu.max').exists() else None}


def prepare_runtime():
    cfg = config()
    info = json.loads(subprocess.check_output([cfg['swift'], '-print-target-info'], text=True))
    paths = info['paths']['runtimeLibraryPaths']
    assert paths and all(Path(x).is_dir() for x in paths), paths
    value = {'swift': cfg['swift'], 'toolchain_bin': str(Path(cfg['swift']).resolve().parent),
             'library_paths': paths, 'target_info': info,
             'libswiftCore_sha256': {str(Path(x) / 'libswiftCore.so'): digest(Path(x) / 'libswiftCore.so')
                                      for x in paths if (Path(x) / 'libswiftCore.so').is_file()}}
    assert value['libswiftCore_sha256'], 'No Swift runtime library found'
    write_json(ROOT / 'control/runtime.json', value)
    return value


def runtime_environment():
    d = load(ROOT / 'control/runtime.json')
    return {'PATH': d['toolchain_bin'] + ':/usr/bin:/bin', 'LD_LIBRARY_PATH': ':'.join(d['library_paths'])}
