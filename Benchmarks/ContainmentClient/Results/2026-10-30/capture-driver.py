import csv
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import tarfile
import time

ROOT = Path('/Users/craig/Developer/Route Objects/Example Framework/Packages/swift-cidr')
WORK = Path(__file__).parent
OUT = WORK / 'evidence'
OUT.mkdir(exist_ok=True)
BASE = 'cdc2e592beb9095875bc42fc4c269396b20d99e3'
CLIENT = Path('Benchmarks/ContainmentClient')

def capture(command, name, cwd=ROOT):
    print('+', ' '.join(map(str, command)), flush=True)
    start = time.time()
    result = subprocess.run(list(map(str, command)), cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    with gzip.open(OUT / (name + '.log.gz'), 'wb') as f:
        f.write(result.stdout)
    (OUT / (name + '.command.json')).write_text(json.dumps({
        'command': list(map(str, command)), 'cwd': str(cwd), 'exit': result.returncode,
        'started_unix': start, 'elapsed_seconds': time.time() - start,
    }, indent=2) + '\n')
    if result.returncode:
        print(result.stdout.decode(errors='replace')[-12000:], flush=True)
        raise SystemExit(result.returncode)
    return result.stdout

def snapshot(phase):
    target = WORK / phase / 'swift-cidr'
    target.mkdir(parents=True)
    archive = subprocess.check_output(['git', 'archive', BASE], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        tar.extractall(target, filter='data')
    for p in (ROOT / 'Sources/CIDR').glob('*.swift'):
        shutil.copy2(p, target / 'Sources/CIDR' / p.name)
    shutil.copytree(ROOT / CLIENT, target / CLIENT, ignore=shutil.ignore_patterns('.build', '.swiftpm', 'Results'))
    shutil.copy2(ROOT / 'Tests/CIDRTests/ContainmentSpecializationTests.swift', target / 'Tests/CIDRTests/ContainmentSpecializationTests.swift')
    (OUT / (phase + '.patch')).write_bytes(subprocess.check_output(['git', 'diff', '--', 'Sources/CIDR'], cwd=ROOT))
    files = [p for p in target.rglob('*') if p.is_file() and (p.suffix == '.swift' or p.name == 'Package.resolved')]
    (OUT / (phase + '.sources.json')).write_text(json.dumps({str(p.relative_to(target)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}, indent=2, sort_keys=True) + '\n')
    return target

def mac_build(phase):
    capture(['swift', 'build', '-v', '-c', 'release', '--disable-sandbox', '--disable-automatic-resolution', '--package-path', CLIENT], phase + '-mac-build')
    build = ROOT / CLIENT / '.build/arm64-apple-macosx/release'
    shutil.copy2(build / 'ContainmentClient', WORK / (phase + '-mac'))
    for module, file in [('ContainmentClient', 'main.swift'), ('CIDR', 'IPPrefix.swift')]:
        obj = build / (module + '.build') / (file + '.o')
        data = capture(['xcrun', 'llvm-objdump', '-dr', '--no-show-raw-insn', obj], phase + '-mac-' + module)
    return run_mac(phase)

def summarize(data, label):
    rows = list(csv.DictReader(io.StringIO(data.decode())))
    assert len(rows) == 164
    summary = {}
    for case in sorted(set(row['case'] for row in rows)):
        values = [int(row['elapsed_ns']) / int(row['scans']) for row in rows if row['case'] == case]
        assert len(values) == 41
        summary[case] = {'median_batch_mean_ns_per_scan': statistics.median(values), 'samples': len(values)}
    (OUT / (label + '.summary.json')).write_text(json.dumps(summary, indent=2) + '\n')
    (OUT / (label + '.csv')).write_bytes(data)
    print(json.dumps(summary), flush=True)

def run_mac(phase, suffix=''):
    label = phase + '-mac' + suffix
    data = capture([WORK / (phase + '-mac')], label)
    summarize(data, label)

def linux(phase, version, mode):
    image = {'6.2.4': 'sha256:e508ef1e4be68087f720de622b91cbf1e32799a7aa96134b35e6f1a1d656db7a',
             '6.3.3': 'sha256:1038d54c80063f5cdfabc4560990c30af64b5de8ebf28161deb22ca4ad5db866'}[version]
    target = WORK / phase / 'swift-cidr'
    prefix = ['docker', 'run', '--rm', '--platform', 'linux/arm64', '-v', f'{target}:/source/swift-cidr:ro', '-v', f'{WORK}:/experiment',
              '-v', f'cidr-containment-{version}-{phase}:/build', '-v', f'cidr-containment-cache-{version}:/root/.cache', '-w', '/source/swift-cidr', image]
    label = phase + '-linux-' + version + '-' + mode
    if mode == 'build':
        capture(prefix + ['swift', 'build', '-v', '-c', 'release', '--disable-automatic-resolution', '--scratch-path', '/build/client', '--package-path', '/source/swift-cidr/' + str(CLIENT)], label)
        capture(prefix + ['cp', '/build/client/release/ContainmentClient', '/experiment/' + phase + '-linux-' + version], label + '-binary')
        for module, filename in [('ContainmentClient', 'main.swift'), ('CIDR', 'IPPrefix.swift')]:
            capture(prefix + ['llvm-objdump', '-dr', '--no-show-raw-insn', '/build/client/release/' + module + '.build/' + filename + '.o'], label + '-' + module)
    elif mode.startswith('run'):
        data = capture(prefix + ['/experiment/' + phase + '-linux-' + version], label)
        summarize(data, label)
    elif mode == 'test':
        capture(prefix + ['swift', 'test', '-c', 'release', '--disable-automatic-resolution', '--scratch-path', '/build/tests'], label)
    elif mode == 'version':
        capture(prefix + ['swift', '--version'], label)
        capture(prefix + ['uname', '-a'], label + '-host')

if __name__ == '__main__':
    action, *args = sys.argv[1:]
    if action == 'snapshot': snapshot(*args)
    elif action == 'mac-build': mac_build(*args)
    elif action == 'mac-run': run_mac(*args)
    elif action == 'linux': linux(*args)
    elif action == 'linux-matrix':
        version = args[0]
        linux('mask-chain', version, 'version')
        linux('mask-chain', version, 'build')
        for phase, run in [('baseline', 'run1'), ('mask-chain', 'run1'), ('mask-chain', 'run2'), ('baseline', 'run2')]:
            linux(phase, version, run)
        linux('mask-chain', version, 'test')
    elif action == 'mac-tests':
        capture(['./scripts/test.sh', '--disable-sandbox', '--disable-automatic-resolution'], 'mask-chain-mac-debug-tests')
        capture(['./scripts/test.sh', '-c', 'release', '--disable-sandbox', '--disable-automatic-resolution'], 'mask-chain-mac-release-tests')
    elif action == 'mac-repeat':
        for phase, suffix in [('baseline', '-run1'), ('mask-chain', '-run1'), ('mask-chain', '-run2'), ('baseline', '-run2')]:
            run_mac(phase, suffix)
    elif action == 'environment':
        for label, command in [
            ('mac-swift', ['swift', '--version']), ('mac-os', ['sw_vers']),
            ('mac-kernel', ['uname', '-a']), ('mac-xcode', ['xcodebuild', '-version']),
            ('mac-hardware', ['sysctl', 'hw.model', 'hw.memsize', 'hw.ncpu', 'machdep.cpu.brand_string']),
            ('mac-power', ['pmset', '-g', 'batt']), ('mac-load', ['uptime']),
            ('linux-images', ['docker', 'image', 'inspect', 'swift:6.2.4-noble', 'swift:6.3.3-noble']),
        ]:
            capture(command, label)
