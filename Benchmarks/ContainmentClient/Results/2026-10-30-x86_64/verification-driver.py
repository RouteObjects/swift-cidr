import csv
import difflib
import gzip
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess

from native_x86 import WORK, OUT, REMOTE

ROOT = Path('/Users/craig/Developer/Route Objects/Example Framework/Packages/swift-cidr')
DEST = ROOT / 'Benchmarks/ContainmentClient/Results/2026-10-30-x86_64'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

summaries = []
test_results = []
codegen = []
for version in ['6.2.4', '6.3.3']:
    for phase in ['baseline', 'mask-chain']:
        combined = []
        for run in ['run1', 'run2']:
            path = OUT / f'{version}-{phase}-{run}.csv'
            rows = list(csv.DictReader(path.open()))
            assert len(rows) == 164
            assert len({(r['case'], r['sample']) for r in rows}) == 164
            for r in rows:
                assert int(r['scans']) == 25 and int(r['checks_per_scan']) == 20000
                assert int(r['matches']) == 13 and int(r['elapsed_ns']) > 0
            combined.extend(rows)
        for case in ['v4.typed', 'v4.erased', 'v6.typed', 'v6.erased']:
            values = [int(r['elapsed_ns']) / int(r['scans']) for r in combined if r['case'] == case]
            assert len(values) == 82
            summaries.append({'platform': 'native-x86_64-linux', 'swift': version, 'phase': phase,
                              'case': case, 'samples': 82, 'scans_per_sample': 25, 'checks_per_scan': 20000,
                              'median_batch_mean_ns_per_scan': statistics.median(values)})
        assembly = gzip.decompress((OUT / f'{version}-{phase}-ContainmentClient.log.gz').read_bytes()).decode()
        for family in ['V4', 'V6']:
            match = re.search(r'^\w+ <[^\n]*scan' + family + r'[^\n]*>:\n.*?(?=\n\n|\Z)', assembly, re.M | re.S)
            assert match
            body = match.group()
            calls = len(re.findall(r'\tcallq?\s', body))
            if phase == 'mask-chain':
                assert calls == 0
                assert 'R_X86_64_PLT32' not in body
            else:
                assert calls > 0
            name = f'{version}-{phase}-scan{family}.s'
            (OUT / name).write_text(body + '\n')
            codegen.append({'file': name, 'call_instructions': calls})
    for config in ['debug', 'release']:
        label = f'{version}-tests-{config}'
        log = gzip.decompress((OUT / (label + '.log.gz')).read_bytes()).decode()
        command = json.loads((OUT / (label + '.command.json')).read_text())
        assert command['exit'] == 0 and '269 tests in 29 suites passed' in log
        test_results.append({'swift': version, 'configuration': config, 'tests': 269, 'suites': 29, 'passed': True})
with (OUT / 'comparison.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=list(summaries[0]), lineterminator='\n')
    writer.writeheader()
    writer.writerows(summaries)

for phase in ['baseline', 'mask-chain']:
    expected = json.loads((WORK / 'evidence' / f'{phase}.sources.json').read_text())
    for stage in ['before', 'after']:
        actual = json.loads(gzip.decompress((OUT / f'{phase}-sources-{stage}.log.gz').read_bytes()))
        assert actual == expected
for path, checksum in json.loads((WORK / 'evidence/mask-chain.sources.json').read_text()).items():
    assert sha(ROOT / path) == checksum

for path in OUT.glob('*.command.json'):
    assert json.loads(path.read_text())['exit'] == 0, path
assert not subprocess.check_output(['git', 'diff', '--cached'], cwd=ROOT)
assert subprocess.check_output(['git', 'diff', '--', 'Sources/CIDR'], cwd=ROOT) == (WORK / 'evidence/mask-chain.patch').read_bytes()

preserved = []
admission = ROOT.parents[2] / 'swift-cidr-admission'
for folder in [
    ROOT / 'Benchmarks/ContainmentClient/Results/2026-10-30',
    admission / 'Benchmarks/Results/2026-10-30-main-5d01867-benchmark-1.38.1',
    admission / 'Benchmarks/Results/2026-10-30-sampling-followup-benchmark-1.38.1',
]:
    check = subprocess.run(['shasum', '-a', '256', '-c', 'SHA256SUMS'], cwd=folder, capture_output=True)
    assert check.returncode == 0
    preserved.append(str(folder))

report = Path('Documentation/Performance/Containment-2026-10-30.md')
patch = ''.join(difflib.unified_diff(
    (WORK / 'x86-report-before.md').read_text().splitlines(keepends=True),
    (ROOT / report).read_text().splitlines(keepends=True),
    fromfile='a/' + str(report), tofile='b/' + str(report)))
with (OUT / 'report-update.patch.gz').open('wb') as raw:
    with gzip.GzipFile(fileobj=raw, mode='wb', mtime=0) as gz:
        gz.write(patch.encode())
(WORK / 'x86-report-update.patch').write_text(patch)
shutil.copy2(WORK / 'native_x86.py', OUT / 'capture-driver.py')
shutil.copy2(Path(__file__), OUT / 'verification-driver.py')
(OUT / 'verification.json').write_text(json.dumps({
    'host': 'swift-dev', 'architecture': 'x86_64', 'execution': 'native LXC, not emulation',
    'remote_directory': REMOTE, 'archive_sha256': sha(WORK / 'x86-sources.tar.gz'),
    'production_patch_unchanged': True, 'source_and_lock_hashes_match_before_and_after': True,
    'captures': 8, 'timing_rows': 1312, 'tests': test_results, 'codegen': codegen,
    'preserved_snapshots': preserved, 'nothing_staged': True,
}, indent=2) + '\n')
for path in OUT.glob('*.gz'):
    gzip.decompress(path.read_bytes())
files = sorted(p for p in OUT.iterdir() if p.is_file() and p.name != 'SHA256SUMS')
(OUT / 'SHA256SUMS').write_text(''.join(f'{sha(p)}  {p.name}\n' for p in files))
shutil.copytree(OUT, DEST, dirs_exist_ok=True)
print(json.dumps({'destination': str(DEST), 'files': len(files) + 1, 'tests': test_results, 'comparison': summaries}, indent=2))
