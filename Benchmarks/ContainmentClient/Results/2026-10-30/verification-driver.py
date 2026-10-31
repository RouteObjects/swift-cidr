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

from experiment import ROOT, WORK, OUT, BASE, CLIENT

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

summary = []
for platform, stem in [('macos-swift-6.3.3', 'mac-run'), ('linux-swift-6.2.4', 'linux-6.2.4-run'), ('linux-swift-6.3.3', 'linux-6.3.3-run')]:
    for phase in ['baseline', 'mask-chain']:
        rows = [r for run in (1, 2) for r in csv.DictReader((OUT / f'{phase}-{stem}{run}.csv').open())]
        for case in ['v4.typed', 'v4.erased', 'v6.typed', 'v6.erased']:
            values = [int(r['elapsed_ns']) / int(r['scans']) for r in rows if r['case'] == case]
            assert len(values) == 82
            summary.append({'platform': platform, 'phase': phase, 'case': case, 'samples': len(values),
                            'scans_per_sample': 25, 'checks_per_scan': 20000,
                            'median_batch_mean_ns_per_scan': statistics.median(values)})
with (OUT / 'comparison.csv').open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=list(summary[0]), lineterminator='\n')
    writer.writeheader()
    writer.writerows(summary)

capture_count = 0
for path in OUT.glob('*.csv'):
    if path.name == 'comparison.csv':
        continue
    rows = list(csv.DictReader(path.open()))
    assert len(rows) == 164
    assert len({(r['case'], r['sample']) for r in rows}) == 164
    for r in rows:
        assert int(r['scans']) == 25 and int(r['checks_per_scan']) == 20000
        assert int(r['matches']) == 13 and int(r['elapsed_ns']) > 0
    capture_count += 1
assert capture_count == 15

codegen = []
for phase in ['baseline', 'entry-only', 'mask-chain']:
    for platform in ['mac', 'linux-6.2.4-build', 'linux-6.3.3-build']:
        path = OUT / f'{phase}-{platform}-ContainmentClient.log.gz'
        if not path.exists():
            continue
        assembly = gzip.decompress(path.read_bytes()).decode()
        for family in ['V4', 'V6']:
            block = re.search(r'^\w+ <[^\n]*scan' + family + r'[^\n]*>:\n.*?(?=\n\n|\Z)', assembly, re.M | re.S)
            assert block, (phase, platform, family)
            body = block.group()
            calls = len(re.findall(r'\t(?:bl|blr)\s', body))
            if phase == 'mask-chain':
                assert calls == 0
                assert 'RELOC_BRANCH26' not in body and 'R_AARCH64_CALL26' not in body
            else:
                assert calls > 0
            name = f'{phase}-{platform}-scan{family}.s'
            (OUT / name).write_text(body + '\n')
            codegen.append({'file': name, 'call_instructions': calls})

base = json.loads((OUT / 'baseline.sources.json').read_text())
final = json.loads((OUT / 'mask-chain.sources.json').read_text())
changed = sorted(k for k in base if base[k] != final[k])
assert changed == ['Sources/CIDR/CIDR.swift', 'Sources/CIDR/FixedWidthInteger+NetworkMask.swift', 'Sources/CIDR/IPPrefix.swift']
assert base.keys() == final.keys()
for k, v in final.items():
    assert digest(ROOT / k) == v, k
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip() == BASE
assert not subprocess.check_output(['git', 'diff', '--cached'], cwd=ROOT)
assert not subprocess.check_output(['git', 'diff', '--', 'Package.swift', 'Package.resolved', 'Benchmarks/Package.swift', 'Benchmarks/Package.resolved'], cwd=ROOT)

tests = {}
for label in ['mask-chain-mac-debug-tests', 'mask-chain-mac-release-tests', 'mask-chain-linux-6.2.4-test', 'mask-chain-linux-6.3.3-test']:
    text = gzip.decompress((OUT / (label + '.log.gz')).read_bytes()).decode()
    assert '269 tests in 29 suites passed' in text
    assert json.loads((OUT / (label + '.command.json')).read_text())['exit'] == 0
    tests[label] = {'tests': 269, 'suites': 29, 'passed': True}

admission = ROOT.parents[2] / 'swift-cidr-admission'
for folder in ['2026-10-30-main-5d01867-benchmark-1.38.1', '2026-10-30-sampling-followup-benchmark-1.38.1']:
    directory = admission / 'Benchmarks/Results' / folder
    result = subprocess.run(['shasum', '-a', '256', '-c', 'SHA256SUMS'], cwd=directory, capture_output=True)
    assert result.returncode == 0
    with gzip.open(OUT / (folder + '-preservation.log.gz'), 'wb') as f:
        f.write(result.stdout)

review = subprocess.check_output(['git', 'diff', '--', 'Sources/CIDR'], cwd=ROOT).decode()
review_files = [
    CLIENT / 'Package.swift', CLIENT / 'Package.resolved', CLIENT / 'Sources/ContainmentClient/main.swift',
    CLIENT / 'README.md', Path('Tests/CIDRTests/ContainmentSpecializationTests.swift'),
    Path('Documentation/Performance/Containment-2026-10-30.md')
]
for relative in review_files:
    content = (ROOT / relative).read_text()
    review += f'diff --git a/{relative} b/{relative}\nnew file mode 100644\n'
    review += ''.join(difflib.unified_diff([], content.splitlines(keepends=True), fromfile='/dev/null', tofile=f'b/{relative}'))
(OUT / 'review.patch').write_text(review)

verification = {
    'base_commit': BASE, 'branch': 'perf/typed-prefix-containment', 'index_empty': True,
    'production_files_changed': changed, 'benchmark_and_pins_identical_across_phases': True,
    'timing_captures': capture_count, 'timing_rows': capture_count * 164,
    'codegen': codegen, 'tests': tests, 'admission_snapshots_preserved': True,
    'binaries': {p.name: digest(p) for p in WORK.iterdir() if p.is_file() and (p.name.endswith('-mac') or '-linux-' in p.name)},
}
(OUT / 'verification.json').write_text(json.dumps(verification, indent=2, sort_keys=True) + '\n')
shutil.copy2(WORK / 'experiment.py', OUT / 'capture-driver.py')
shutil.copy2(Path(__file__), OUT / 'verification-driver.py')
for path in OUT.glob('*.patch'):
    with (OUT / (path.name + '.gz')).open('wb') as raw:
        with gzip.GzipFile(fileobj=raw, mode='wb', mtime=0) as compressed:
            compressed.write(path.read_bytes())
for path in OUT.glob('*.gz'):
    gzip.decompress(path.read_bytes())
checksum_files = sorted(p for p in OUT.iterdir() if p.is_file() and p.name != 'SHA256SUMS' and p.suffix != '.patch')
(OUT / 'SHA256SUMS').write_text(''.join(f'{digest(p)}  {p.name}\n' for p in checksum_files))
destination = ROOT / CLIENT / 'Results/2026-10-30'
destination.mkdir(parents=True, exist_ok=True)
for path in checksum_files + [OUT / 'SHA256SUMS']:
    shutil.copy2(path, destination / path.name)
print(json.dumps({'files': len(checksum_files) + 1, 'captures': capture_count, 'destination': str(destination), 'verification': verification}, indent=2))
