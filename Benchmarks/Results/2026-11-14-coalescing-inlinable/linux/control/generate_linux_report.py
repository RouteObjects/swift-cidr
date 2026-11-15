#!/usr/bin/env python3
"""Generate the final Linux report only after both independently audited platforms pass."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import statistics

ROOT = Path(__file__).resolve().parents[1]
PLATFORMS = ('arm64', 'x86_64')
LABELS = {'arm64': 'ARM64 Linux / OrbStack', 'x86_64': 'x86-64 Linux / swift-dev'}
EXPECTED_ARCH = {'arm64': 'aarch64', 'x86_64': 'x86_64'}
CASES = [('split', n) for n in ('ipv4-disjoint', 'ipv6-disjoint', 'mixed-disjoint', 'mixed-permuted',
          'mixed-overlap', 'mixed-adjacent', 'bgp-like-ipv4', 'range-derived-mixed')]
CASES += [('native', n) for n in ('mixed-disjoint', 'mixed-permuted', 'mixed-overlap')]


def require(condition, detail):
    if not condition:
        raise ValueError(detail)


def load(path):
    require(path.is_file(), f'Not ready: missing {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}')
    return json.loads(path.read_text())


def digest(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def close(a, b):
    return abs(a-b) <= 1e-10 * max(1, abs(a), abs(b))


def validate_platform(name, mac):
    p = ROOT / name
    s = load(p / 'measurements/summary.json')
    tests = load(p / 'control/build-tests/summary.json')
    audit_path = ROOT / 'control' / f'independent-{name}-audit.json'
    audit = load(audit_path)
    gate = load(p / 'control/codegen-gate.json')
    codegen = load(p / 'control/codegen.json')
    freeze = load(p / 'control/pre-benchmark-freeze.json')
    source = load(p / 'control/source-reference.json')
    runtime = load(p / 'control/runtime.json')
    post = load(p / 'control/runtime-postcheck.json')
    host = load(p / 'control/host-before-benchmark.json')
    cleanliness = load(p / 'control/dependency-cleanliness.json')
    require(s['passed'] and tests['passed'] and audit['passed'] and not audit.get('errors'), name+' failed result or audit')
    require(gate['passed'] and codegen['specialization_gate_passed'], name+' codegen gate not passed')
    require(cleanliness['passed'], name+' dependency cleanliness failed')
    require(post['passed'], name+' runtime postcheck failed')
    require(audit['summary_sha256'] == digest(p / 'measurements/summary.json'), name+' audit refers to another summary')
    require(s['measured_samples'] == 132 and s['measured_processes'] == 192, name+' measured counts')
    require(s['excluded_warmup_samples'] == 22 and s['excluded_warmup_processes'] == 32, name+' warmup counts')
    require(s['no_samples_removed_or_retried'] and s['all_outputs_match_original_independent_coverage'], name+' sample or coverage failure')
    require(audit['measured_samples'] == 132 and audit['measured_processes'] == 192 and audit['balanced_six_rounds'], name+' audit counts/order')
    require(audit['all_outputs_match_verified_coverage'] and audit['no_observed_dropped_or_retried_samples'], name+' audit output/retention failure')
    require(tests['test_executions'] == 1414 and audit['test_executions_verified'] == 1414, name+' tests')
    test_rows = [x for x in tests['results'] if x['action'] == 'test']
    require(len(test_rows) == 8, name+' incomplete test matrix')
    for variant in ('B', 'C'):
        for package in ('upstream', 'cli'):
            for configuration in ('debug', 'release'):
                rows = [x for x in test_rows if (x['variant'], x['package'], x['configuration']) == (variant, package, configuration)]
                expected = 57 if package == 'cli' else (295 if variant == 'B' else 298)
                require(len(rows) == 1 and rows[0]['exit_code'] == 0 and rows[0]['tests'] == expected,
                        f'{name} missing or failed {variant}/{package}/{configuration}')
    hashes = {}
    for variant, key in [('B', 'baseline'), ('C', 'candidate')]:
        h = digest(p / 'bin' / variant)
        hashes[variant] = h
        require(h == tests['bin'][variant] == audit['binary_sha256'][variant] == gate['binary_sha256'][variant] == codegen[key]['sha256'],
                f'{name} binary {variant} identity mismatch')
    if 'evidence_sha256' in gate:
        require(gate['evidence_sha256'] == digest(p / gate.get('evidence', 'control/codegen.json')), name+' stale codegen gate evidence')
    for rel, wanted in freeze['files'].items():
        require(digest(p / rel) == wanted, name+' frozen file changed: '+rel)
    mac_freeze_path = mac / 'control/pre-benchmark-freeze.json'
    mac_freeze = load(mac_freeze_path)
    require(source['macos_source_freeze_sha256'] == digest(mac_freeze_path), name+' different Mac source freeze')
    for rel, wanted in source['files'].items():
        require(digest(p / rel) == wanted, name+' changed source '+rel)
        previous = rel.replace('sources/', 'snapshots/', 1)
        require(mac_freeze['files'][previous] == wanted, name+' source not identical to Mac '+rel)
    require(len(source['files']) == 185, name+' source coverage differs')
    expected_runtime = runtime['libswiftCore_sha256']
    if 'files' in post:
        require(post['files'] == expected_runtime, name+' native runtime postcheck differs')
    else:
        checked = {}
        for c in post['checks']:
            path = c.get('container_path', c.get('path'))
            require(c['matches_prebuild_runtime'], name+' runtime changed')
            checked[path] = c['sha256']
            if 'copied_path' in c:
                require(digest(p / c['copied_path']) == c['sha256'], name+' runtime copy differs')
        require(checked == expected_runtime, name+' runtime postcheck incomplete')
    require(runtime['target_info']['target']['arch'] == EXPECTED_ARCH[name], name+' unexpected runtime architecture')
    require(host['machine'] == EXPECTED_ARCH[name], name+' unexpected host architecture')
    require('Swift version 6.4.2' in host['swift']['stdout'] and host['swift']['exit_code'] == 0, name+' unexpected compiler')
    require('Swift version 6.4.2' in runtime['target_info']['compilerVersion'], name+' compiler target-info version')
    for x in tests['results']:
        require(x['exit_code'] == 0, name+' failed build/test step')
        if x['action'] == 'build':
            require(x['ldd']['exit_code'] == 0 and 'not found' not in x['ldd']['stdout'], name+' linkage failure')
    require(len(s['groups']) == 22 and len(s['comparisons']) == 11 and len(s['samples']) == 132, name+' group counts')
    groups = {(x['suite'], x['case'], x['tool']): x for x in s['groups']}
    comparisons = {(x['suite'], x['case']): x for x in s['comparisons']}
    rows, individual_pairs = [], []
    for suite, case in CASES:
        by_tool = {}
        for variant in ('B', 'C'):
            values = [x for x in s['samples'] if (x['suite'], x['case'], x['tool']) == (suite, case, variant)]
            require(len(values) == 6 and sorted(x['round'] for x in values) == list(range(1, 7)), name+' incomplete rounds')
            by_tool[variant] = {x['round']: x for x in values}
            g = groups[suite, case, variant]
            require(close(g['elapsed_median_s'], statistics.median(x['elapsed_ns']/1e9 for x in values)), name+' elapsed median differs')
            require(close(g['peak_rss_median_mib'], statistics.median(x['peak_rss_bytes']/1048576 for x in values)), name+' RSS median differs')
        paired = []
        for i in range(1, 7):
            b, c = by_tool['B'][i], by_tool['C'][i]
            require(b['order'] == c['order'] == (['B', 'C'] if i % 2 else ['C', 'B']), name+' order differs')
            value = (c['elapsed_ns']/b['elapsed_ns']-1)*100
            paired.append(value)
            individual_pairs.append({'suite': suite, 'case': case, 'round': i, 'elapsed_change_pct': value})
        comparison = comparisons[suite, case]
        require(close(comparison['paired_elapsed_change_median_pct'], statistics.median(paired)), name+' paired median differs')
        rows.append((suite, case, groups[suite, case, 'B'], groups[suite, case, 'C'], comparison))
    return {'name': name, 'summary': s, 'tests': tests, 'audit': audit, 'hashes': hashes,
            'runtime': runtime, 'host': host, 'rows': rows, 'pairs': individual_pairs,
            'runtime_postcheck': post, 'source_reference': source}


def table(data):
    lines = ['| Suite / corpus | B elapsed (s) | C elapsed (s) | Paired elapsed change | B peak RSS (MiB) | C peak RSS (MiB) |',
             '|---|---:|---:|---:|---:|---:|']
    for suite, case, b, c, pair in data['rows']:
        lines.append(f"| {suite} / {case} | {b['elapsed_median_s']:.3f} | {c['elapsed_median_s']:.3f} | {pair['paired_elapsed_change_median_pct']:+.2f}% | {b['peak_rss_median_mib']:.2f} | {c['peak_rss_median_mib']:.2f} |")
    return '\n'.join(lines)


def platform_section(data):
    name = data['name']
    comparisons = [x[-1] for x in data['rows']]
    changes = [x['paired_elapsed_change_median_pct'] for x in comparisons]
    rss = [x['paired_rss_difference_median_mib'] for x in comparisons]
    favorable = sum(x['elapsed_change_pct'] < 0 for x in data['pairs'])
    unfavorable = [x for x in data['pairs'] if x['elapsed_change_pct'] >= 0]
    count_improved = sum(x < 0 for x in changes)
    h = data['host']
    memory = re.search(r'^MemTotal:\s+(\d+) kB', h['memory'], re.M)
    cpu = re.search(r'^model name\s*:\s*(.+)$', h['cpuinfo'], re.M)
    model = cpu[1].strip() if cpu else 'Apple Silicon host, native ARM64 guest'
    lines = [f"## {LABELS[name]}", '',
             f"{count_improved}/11 workload paired medians improved; elapsed changes range from {min(changes):+.2f}% to {max(changes):+.2f}%. "
             f"{favorable}/66 individual pairs favor C. Median paired RSS differences range from {min(rss):+.2f} to {max(rss):+.2f} MiB.", '',
             f"Host: {model}; `{h['machine']}`; {len(h['affinity'])} allowed logical CPUs; "
             f"{int(memory[1])/1048576:.2f} GiB guest-visible memory; kernel `{h['kernel']}`. "
             f"Swift executable: `{data['runtime']['swift']}`. Measurement completion timestamp: `{data['summary']['completed_at']}`.", '',
             table(data), '']
    if unfavorable:
        lines.append('Retained non-improving individual pairs (not removed or retried):')
        lines.append('')
        for pair in unfavorable:
            lines.append(f"- {pair['suite']} / {pair['case']}, round {pair['round']}: {pair['elapsed_change_pct']:+.2f}% elapsed.")
        lines.append('')
    if name == 'x86_64':
        lines += ['The roughly 1–3% paired median gains on the easier inputs are small relative to the observed run-to-run variation and should not be treated as conclusive improvements. The five sorting-heavy cases (split mixed-permuted, split mixed-overlap, split bgp-like-ipv4, native mixed-permuted and native mixed-overlap) show approximately 20–28% lower paired medians, with every measured pair in those cases favoring C.', '',
                  'The two large candidate slowdowns above, and a slower baseline mixed-adjacent sample, are retained. Their additional elapsed time is also charged as child CPU time; major faults, swaps and input blocks are zero. Those counters do not identify the cause. No observation is removed or retried. See the [raw-record outlier review](control/x86_64-outlier-review.md).', '']
    lines += [f"[Raw aggregate measurements]({name}/measurements/summary.json), "
              f"[full tests]({name}/control/build-tests/summary.json), "
              f"[actual sorting calls]({name}/control/codegen.md), "
              f"[independent audit](control/independent-{name}-audit.json), "
              f"[runtime postcheck]({name}/control/runtime-postcheck.json), "
              f"[host metadata]({name}/control/host-before-benchmark.json).", '',
              '| Binary | SHA-256 |', '|---|---|',
              f"| B | `{data['hashes']['B']}` |", f"| C | `{data['hashes']['C']}` |", '']
    return '\n'.join(lines)


def generate(data, mac):
    # Keep the reviewed methodological prose, adding results entirely from validated JSON.
    outline = (ROOT / 'control/report-outline.md').read_text()
    plan = outline[outline.index('## Plan and patch'):outline.index('## Tests and generated code')]
    tests_prose = outline[outline.index('## Tests and generated code'):outline.index('## Verification method')]
    method = outline[outline.index('## Verification method'):outline.index('## Notes and reproducibility')]
    notes = outline[outline.index('## Notes and reproducibility'):]
    parts = ['# Linux Swift 6.4.2 validation', '',
             'The frozen candidate reaches specialized sorting on both Linux architectures. Both complete test matrices and both independently audited matched benchmark runs passed. Results below are kept separate by platform; no pooled speedup is calculated.', '',
             'This validation adds no executable source changes to the existing uncommitted `perf/coalescing-inlinable` prototype. B is the original swift-cidr 0.10.0 / cidrmerge 0.4.0 source; C is the same source plus the tested visibility chain and three upstream tests.', '',
             plan, tests_prose,
             '| Platform | Variant | swift-cidr Debug / Release | cidrmerge Debug / Release | Total test executions |',
             '|---|---|---:|---:|---:|',
             '| ARM64 Linux | B | 295 / 295 | 57 / 57 | 704 |',
             '| ARM64 Linux | C | 298 / 298 | 57 / 57 | 710 |',
             '| swift-dev x86-64 | B | 295 / 295 | 57 / 57 | 704 |',
             '| swift-dev x86-64 | C | 298 / 298 | 57 / 57 | 710 |', '',
             '**2,828 test executions passed**, with 1,414 on each platform. Each platform contributes 132 measured samples/192 child processes and 22 excluded warmups/32 processes. The two platforms therefore retain 264 measured samples/384 processes and 44 warmups/64 processes. These counts are not pooled performance statistics.', '',
             method,
             'The tables show six-sample medians. The percentage column is the median of the six per-round elapsed changes; negative values favor C. Peak RSS values are medians in MiB. Individual exceptions are retained below each platform table.', '']
    parts += [platform_section(d) for d in data]
    parts += ['## Source and runtime identity', '',
              'The report generator independently checks both binary hashes against build receipts, frozen inputs, generated-code captures, codegen gates and audit receipts. All 185 Swift source/Package.swift files per platform match the original macOS source freeze. Runtime postchecks match the originally recorded libswiftCore hash; the ARM64 check additionally hashes the copied library from the completed container. The independent output audit itself does not claim to have executed or reprofiled the binaries.', '',
              'Source bases: swift-cidr `e268b139e334a0662185d16a3e07b187ab0cbe70`; cidrmerge `e4f1aed90c013cc5b0d75bb0d29d80f0259e19b0`. All actual dependency revisions retain the original lock selection. Source and runtime receipts remain platform-specific.', '',
              notes,
              'The candidate still supports the previously tested Swift 6.2 floor. No `@specialized` attribute was applied or benchmarked in this work; the actual change is the `@inlinable` visibility chain. Internal usable-from-inline storage and helpers remain ABI-visible implementation commitments.', '',
              'Canonical working copies differ from the frozen candidate only by removal of four `// CHANGE:` comment prefixes in three production files. Executable tokens and tests are unchanged; the preservation audit records the exact allowed differences. The isolated CLI manifest uses the documented local dependency override, while the canonical CLI manifest retains its released dependency requirement.', '',
              '## Reproduce without overwriting evidence', '',
              'Use a fresh platform directory and follow [the shared harness instructions](shared/README.md): prepare the frozen sources/fixtures/dependency seeds, configure the explicit Swift 6.4.2 executable, run the build/test phase, review actual codegen and bind the gate to the binaries, freeze/validate, then start the separate matched benchmark phase. Preserve the original outputs. All build/test commands are retained in per-step receipts, while each measured child record contains its complete command and safe environment. The runners refuse an existing phase/results directory.', '',
              f"The earlier [macOS measurement archive](../{mac.name}/measurements/summary.json) and [macOS experiment report](../{mac.name}/REPORT.md) remain separate evidence. Their timings are not recomputed or replaced here.", '']
    report = '\n'.join(parts)
    for target in re.findall(r'\]\(([^)]+)\)', report):
        if '://' not in target:
            require((ROOT / target).is_file(), 'Report link missing: '+target)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-only', action='store_true')
    parser.add_argument('--platform', choices=PLATFORMS, help='Validate one platform only; requires --check-only.')
    args = parser.parse_args()
    require(not args.platform or args.check_only, '--platform is validation-only; final report requires both platforms')
    context = load(ROOT / 'control/context.json')
    mac = Path(context['macos_evidence'])
    selected = (args.platform,) if args.platform else PLATFORMS
    data = [validate_platform(name, mac) for name in selected]
    if args.check_only:
        print(json.dumps({'passed': True, 'validated_platforms': list(selected), 'report_written': False}))
        return
    require(len(data) == 2, 'Both platforms required')
    report = generate(data, mac)
    destination = ROOT / 'REPORT.md'
    with destination.open('x') as f:
        f.write(report)
    receipt = {'passed': True, 'generated_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'report_sha256': digest(destination), 'platforms': {d['name']: {'binary_sha256': d['hashes'],
               'summary_sha256': digest(ROOT / d['name'] / 'measurements/summary.json'),
               'audit_sha256': digest(ROOT / 'control' / f"independent-{d['name']}-audit.json")} for d in data}}
    with (ROOT / 'control/report-generation.json').open('x') as f:
        json.dump(receipt, f, indent=2)
        f.write('\n')
    print(json.dumps({'passed': True, 'report': str(destination), 'report_sha256': receipt['report_sha256']}))


if __name__ == '__main__':
    main()
