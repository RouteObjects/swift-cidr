#!/usr/bin/env python3
"""Independent Linux evidence audit; run only after all timing has stopped.

Usage: python3 audit_linux.py PLATFORM_ROOT --output RECEIPT.json
Optional: --original-reference-root PATH checks the original Mac coverage receipts.
Optional: --check-runtime-files hashes native libswiftCore paths on the measured host.

No harness imports, subprocesses, builds, profiles, or benchmark executions occur.
All inputs are read-only. The only write is the explicitly selected output receipt.
"""
import argparse
from collections import Counter
import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import traceback


def load(path):
    return json.loads(path.read_text())


def audit(platform_root, original_reference_root=None, check_runtime_files=False):
    root = platform_root.resolve()
    counts = Counter()
    result = {
        'passed': False,
        'platform_root': str(root),
        'started_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'scope': 'Independent evidence-only audit; no harness imports or benchmark execution.',
        'errors': [],
    }

    def check(condition, label):
        counts['assertions'] += 1
        if not condition:
            raise AssertionError(label)

    def close(actual, expected, label):
        check(math.isclose(actual, expected, rel_tol=1e-12, abs_tol=1e-12), label)

    def sha(path):
        with path.open('rb') as stream:
            value = hashlib.file_digest(stream, 'sha256').hexdigest()
        counts['files_hashed'] += 1
        counts['bytes_hashed'] += path.stat().st_size
        return value

    def frozen(files, base, label):
        for relative, expected in files.items():
            check(sha(base / relative) == expected, label + ': ' + relative)
        return len(files)

    try:
        summary_path = root / 'measurements/summary.json'
        summary = load(summary_path)
        protocol = load(root / 'control/matched-protocol.json')
        reference = load(root / 'control/reference.json')
        source_reference = load(root / 'control/source-reference.json')
        freeze = load(root / 'control/pre-benchmark-freeze.json')
        runtime = load(root / 'control/runtime.json')
        result['summary_sha256'] = sha(summary_path)
        check(summary['passed'], 'summary passed')
        required = {'bin/B', 'bin/C', 'control/linux_runner.py', 'control/run_matched.py',
                    'control/common.py', 'control/runtime.json', 'control/reference.json',
                    'control/source-reference.json', 'control/matched-protocol.json',
                    'control/codegen-gate.json', 'control/build-tests/summary.json'}
        check(required <= set(freeze['files']), 'required freeze entries')
        result['frozen_files_verified'] = frozen(freeze['files'], root, 'pre-benchmark freeze')
        result['source_files_verified'] = frozen(source_reference['files'], root, 'source reference')
        inputs = reference['inputs']
        for relative, metadata in inputs.items():
            path = root / relative
            check(path.stat().st_size == metadata['bytes'], 'fixture bytes: ' + relative)
            check(sha(path) == metadata['sha256'], 'fixture hash: ' + relative)
        result['fixtures_verified'] = len(inputs)
        check(summary['validation_before'] == summary['validation_after'], 'before/after validation parity')
        check(summary['validation_before']['frozen_files'] == len(freeze['files']), 'frozen count')
        check(summary['validation_before']['fixture_files'] == len(inputs), 'fixture count')
        check('6.4.2' in runtime['target_info']['compilerVersion'], 'Swift 6.4.2 compiler')
        check(runtime['target_info']['target']['platform'] == 'linux', 'Linux runtime')
        result['runtime_arch'] = runtime['target_info']['target']['arch']
        if check_runtime_files:
            result['runtime_libraries_verified'] = frozen(runtime['libswiftCore_sha256'], Path('/'), 'runtime library')
        else:
            result['runtime_libraries_verified'] = False
            result['runtime_note'] = 'Runtime receipt frozen; native library paths are not rehashed on this retrieval host.'

        gate = load(root / 'control/codegen-gate.json')
        check(gate['passed'], 'codegen gate passed')
        check(sha(root / gate['evidence']) == gate['evidence_sha256'], 'codegen evidence hash')
        actual_binaries = {tool: sha(root / 'bin' / tool) for tool in ('B', 'C')}
        check(actual_binaries == gate['binary_sha256'], 'codegen gate binds actual measured binaries')
        check(all(freeze['files']['bin/' + tool] == actual_binaries[tool] for tool in ('B', 'C')), 'binary/freeze parity')
        result['binary_sha256'] = actual_binaries
        result['codegen_gate_verified'] = True

        tests = load(root / 'control/build-tests/summary.json')
        check(tests['passed'] and tests['bin'] == actual_binaries, 'build/test summary and binaries')
        test_cases = set()
        total = 0
        for record in tests['results']:
            label = '-'.join(record[k] for k in ('variant', 'package', 'action', 'configuration'))
            check(load(root / 'control/build-tests' / (label + '.json')) == record, 'raw build/test record: ' + label)
            log = root / record['log']
            check(record['exit_code'] == 0 and sha(log) == record['log_sha256'], 'build/test exit and log hash: ' + label)
            pins = {name: source_reference['dependency_pins'][name]
                    for name in source_reference['package_pin_identities'][record['package']]}
            check(record['dependency_pins'] == pins, 'locked dependency pins: ' + label)
            if record['action'] == 'test':
                key = (record['variant'], record['package'], record['configuration'])
                check(key not in test_cases, 'unique test configuration')
                test_cases.add(key)
                expected = 57 if record['package'] == 'cli' else (295 if record['variant'] == 'B' else 298)
                check(record['tests'] == expected, 'test count: ' + label)
                log_bytes = log.read_bytes()
                try:
                    log_bytes.decode('utf-8')
                except UnicodeDecodeError as error:
                    result.setdefault('log_encoding_notes', []).append({
                        'log': record['log'], 'invalid_utf8_start': error.start,
                        'reason': error.reason,
                        'context_hex': log_bytes[max(0, error.start - 12):error.start + 80].hex(),
                        'handling': 'Frozen bytes preserved; extract the ASCII test summary using a bytes regex.'})
                matches = re.findall(rb'Test run with (\d+) tests in (\d+) suites passed', log_bytes)
                check(matches and tuple(map(int, matches[-1])) == (expected, record['suites']), 'raw Swift Testing result: ' + label)
                total += expected
            else:
                check(record['action'] == 'build' and record['package'] == 'cli' and record['configuration'] == 'release', 'expected build action')
                check(record['binary_sha256'] == actual_binaries[record['variant']], 'release build binary')
        expected_tests = {(v, p, c) for v in ('B', 'C') for p in ('upstream', 'cli') for c in ('debug', 'release')}
        check(test_cases == expected_tests and len(tests['results']) == 10, 'complete build/test matrix')
        check(total == tests['test_executions'] == 1414, '1414 test executions')
        result['test_executions_verified'] = total
        result['test_configurations_verified'] = len(test_cases)

        if original_reference_root is not None:
            result['original_reference_files_verified'] = frozen(reference['original_reference_files'], original_reference_root, 'original reference')
        else:
            result['original_reference_files_verified'] = False
        measured, warmups = summary['samples'], summary['warmup_samples']
        for rows, samples, processes, label in ((measured, 132, 192, 'measured'), (warmups, 22, 32, 'warmup')):
            check(len(rows) == samples and sum(len(x['parts']) for x in rows) == processes, label + ' counts')
        check((summary['measured_samples'], summary['measured_processes'], summary['excluded_warmup_samples'], summary['excluded_warmup_processes']) == (132, 192, 22, 32), 'summary counts')
        check(protocol['measured_rounds'] == 6, 'six rounds')
        schedule = [('split', protocol['split_cases']), ('native', protocol['native_cases'])]
        check(len(schedule[0][1]) == 8 and len(schedule[1][1]) == 3, 'eight split and three native cases')
        indexed = {(s['suite'], s['round'], s['case'], s['tool']): s for s in measured + warmups}
        check(len(indexed) == 154, 'unique sample keys')
        execution_order, paths, binary_roots = [], set(), set()
        for suite, cases in schedule:
            for case in cases:
                expected = reference['expected'][suite][case]
                coverage = expected['coverage_receipt']
                check(coverage['passed'], 'reference coverage passed')
                check(coverage['actual']['coverage_sha256'] == coverage['expected_coverage_sha256'], 'reference exact coverage')
                check(coverage['actual']['minimal_cidr_count'] == coverage['expected_minimal_cidr_count'], 'reference minimal cover')
                by_name = {Path(p['path']).name: p for p in coverage['output_files']}
                families = [None] if suite == 'native' else [f for f in (4, 6) if inputs[f'fixtures/{case}/ipv{f}.txt']['bytes']]
                check([p['family'] for p in expected['parts']] == families, 'reference family partition')
                for part in expected['parts']:
                    name = str(part['family'] or 'mixed') + '.stdout'
                    check(part['output_sha256'] == by_name[name]['sha256'] and part['output_bytes'] == by_name[name]['bytes'], 'reference output/coverage parity')
            for iteration in range(7):
                order = ['B', 'C'] if iteration == 0 or iteration % 2 else ['C', 'B']
                offset = max(0, iteration - 1) % len(cases)
                for case in cases[offset:] + cases[:offset]:
                    for tool in order:
                        row = indexed[(suite, iteration, case, tool)]
                        check(row['order'] == order, 'balanced round order')
                        phase = 'warmup' if iteration == 0 else f'round-{iteration:02}'
                        path = root / f'measurements/{suite}/{phase}/{case}/{tool}/sample.json'
                        paths.add(path)
                        raw = load(path)
                        check(raw == {k: v for k, v in row.items() if k not in ('round', 'order')}, 'raw/aggregate sample parity')
                        check(raw['passed'] and raw['matches_verified_warmup_bytes'] and 'error' not in raw, 'sample passed')
                        check(raw['free_bytes_before'] >= protocol['minimum_free_bytes'], 'disk headroom at sample')
                        expected = reference['expected'][suite][case]['parts']
                        check([p['family'] for p in raw['parts']] == [p['family'] for p in expected], 'sample family partition')
                        for part, ref in zip(raw['parts'], expected):
                            label = str(part['family'] or 'mixed')
                            out, err = path.parent / (label + '.stdout'), path.parent / (label + '.stderr')
                            metrics = path.parent / (label + '.rusage.json')
                            check(load(metrics) == part and part['raw_metrics'] == str(metrics.relative_to(root)), 'raw wait4 metrics equality')
                            check(part['input'] == ref['input'] and part['output'] == str(out.relative_to(root)) and part['stderr'] == str(err.relative_to(root)), 'part paths')
                            native_root = Path(part['command'][0]).parent.parent
                            binary_roots.add(str(native_root))
                            check(part['command'] == [str(native_root / 'bin' / tool), '--raw', '--representation', 'cidr', str(native_root / ref['input'])], 'exact measured command')
                            environment = {'PATH': runtime['toolchain_bin'] + ':/usr/bin:/bin', 'LD_LIBRARY_PATH': ':'.join(runtime['library_paths']), 'LANG': 'C', 'LC_ALL': 'C', 'TZ': 'UTC', 'TMPDIR': str(native_root / path.parent.relative_to(root) / ('tmp-' + label)) + '/'}
                            check(part['environment'] == environment, 'controlled environment')
                            check(sha(out) == part['output_sha256'] == ref['output_sha256'], 'output exact hash')
                            check(out.stat().st_size == part['output_bytes'] == ref['output_bytes'], 'output exact bytes')
                            check(part['exit_code'] == 0 and part['stderr_bytes'] == err.stat().st_size == 0 and 'error' not in part, 'part exit/stderr')
                            usage = part['wait4_rusage']
                            check(usage['ru_maxrss'] > 0 and part['peak_rss_bytes'] == int(usage['ru_maxrss']) * 1024, 'per-child KiB to bytes')
                            close(part['cpu_seconds'], usage['ru_utime'] + usage['ru_stime'], 'per-child CPU')
                            check(part['elapsed_ns'] > 0 and usage['ru_utime'] >= 0 and usage['ru_stime'] >= 0, 'nonnegative timing')
                            counts['outputs_verified'] += 1
                            counts['raw_rusage_files_verified'] += 1
                        check(raw['elapsed_ns'] == sum(p['elapsed_ns'] for p in raw['parts']), 'split elapsed sum')
                        check(raw['peak_rss_bytes'] == max(p['peak_rss_bytes'] for p in raw['parts']), 'split RSS maximum')
                        close(raw['cpu_seconds'], sum(p['cpu_seconds'] for p in raw['parts']), 'split CPU sum')
                        check(raw['output_bytes'] == sum(p['output_bytes'] for p in raw['parts']), 'split output sum')
                        execution_order.append(row)
        check(len(binary_roots) == 1, 'single measured native root')
        result['native_execution_root'] = next(iter(binary_roots))
        check(set(root.glob('measurements/**/sample.json')) == paths, 'all raw samples represented')
        check(len(list(root.glob('measurements/**/*.stdout'))) == 224 and len(list(root.glob('measurements/**/*.rusage.json'))) == 224, 'all stdout and rusage files represented')
        check(not (root / 'measurements/failed.json').exists(), 'no failed measurement receipt')
        for first, second in zip(execution_order, execution_order[1:]):
            check(datetime.datetime.fromisoformat(first['finished_at']) <= datetime.datetime.fromisoformat(second['started_at']), 'nonoverlapping chronological execution')
        check([x for x in execution_order if x['round']] == measured and [x for x in execution_order if not x['round']] == warmups, 'aggregate chronological order')
        # The x86 completion controller redirects JSON progress to benchmark-driver.log.
        progress_path = root / 'control/benchmark-driver.log'
        if not progress_path.exists():
            progress_path = root / 'control/matched.log'
        result['progress_log'] = str(progress_path.relative_to(root))
        progress = [json.loads(line) for line in progress_path.read_text().splitlines() if line.strip()]
        check(len(progress) == 154, 'progress log count')
        for event, row in zip(progress, execution_order):
            check(all(event[k] == row[k] for k in ('suite', 'case', 'tool', 'round', 'order')), 'progress ordering')
            close(event['elapsed_s'], row['elapsed_ns'] / 1e9, 'progress elapsed')
            close(event['peak_mib'], row['peak_rss_bytes'] / 1048576, 'progress memory')
        check(datetime.datetime.fromisoformat(tests['finished_at']) <= datetime.datetime.fromisoformat(execution_order[0]['started_at']), 'tests completed before timing')
        if 'at' in gate:
            check(datetime.datetime.fromisoformat(gate['at']) <= datetime.datetime.fromisoformat(execution_order[0]['started_at']), 'codegen gate completed before timing')
            result['codegen_gate_timing_evidence'] = 'Explicit gate timestamp predates first warmup.'
        else:
            start = load(root / 'measurements/start.json')
            check(start['validation'] == summary['validation_before'], 'start receipt confirms gate-containing freeze')
            check(datetime.datetime.fromisoformat(start['started_at']) <= datetime.datetime.fromisoformat(execution_order[0]['started_at']), 'freeze validation precedes first warmup')
            result['codegen_gate_timing_evidence'] = 'No gate timestamp stored; required gate hash is bound by the pre-benchmark freeze and start validation receipt.'

        groups, comparisons = [], []
        for suite, cases in schedule:
            for case in cases:
                for tool in ('B', 'C'):
                    rows = [indexed[(suite, i, case, tool)] for i in range(1, 7)]
                    elapsed = [r['elapsed_ns'] / 1e9 for r in rows]
                    rss = [r['peak_rss_bytes'] / 1048576 for r in rows]
                    calculated = {'n': 6, 'elapsed_median_s': statistics.median(elapsed), 'elapsed_min_s': min(elapsed), 'elapsed_max_s': max(elapsed), 'peak_rss_median_mib': statistics.median(rss), 'peak_rss_min_mib': min(rss), 'peak_rss_max_mib': max(rss), 'cpu_median_s': statistics.median(r['cpu_seconds'] for r in rows)}
                    found = [g for g in summary['groups'] if (g['suite'], g['case'], g['tool']) == (suite, case, tool)]
                    check(len(found) == 1, 'unique group')
                    for key, value in calculated.items():
                        close(found[0][key], value, 'group statistic: ' + key)
                    groups.append({'suite': suite, 'case': case, 'tool': tool, **calculated})
                pairs = []
                for iteration in range(1, 7):
                    baseline, candidate = (indexed[(suite, iteration, case, tool)] for tool in ('B', 'C'))
                    pairs.append({'round': iteration, 'order': baseline['order'], 'elapsed_change_pct': (candidate['elapsed_ns'] / baseline['elapsed_ns'] - 1) * 100, 'rss_change_pct': (candidate['peak_rss_bytes'] / baseline['peak_rss_bytes'] - 1) * 100, 'elapsed_difference_s': (candidate['elapsed_ns'] - baseline['elapsed_ns']) / 1e9, 'rss_difference_mib': (candidate['peak_rss_bytes'] - baseline['peak_rss_bytes']) / 1048576})
                found = [g for g in summary['comparisons'] if (g['suite'], g['case']) == (suite, case)]
                check(len(found) == 1 and found[0]['pairs'] == pairs, 'all six paired changes')
                check(Counter(tuple(p['order']) for p in pairs) == {('B', 'C'): 3, ('C', 'B'): 3}, 'balanced three pairs each direction')
                calculated = {'n_pairs': 6, 'paired_elapsed_change_median_pct': statistics.median(p['elapsed_change_pct'] for p in pairs), 'paired_elapsed_change_min_pct': min(p['elapsed_change_pct'] for p in pairs), 'paired_elapsed_change_max_pct': max(p['elapsed_change_pct'] for p in pairs), 'paired_rss_change_median_pct': statistics.median(p['rss_change_pct'] for p in pairs), 'paired_rss_difference_median_mib': statistics.median(p['rss_difference_mib'] for p in pairs)}
                for key, value in calculated.items():
                    close(found[0][key], value, 'comparison statistic: ' + key)
                comparisons.append({'suite': suite, 'case': case, **calculated})
        check(len(summary['groups']) == 22 and len(summary['comparisons']) == 11, 'group/comparison count')
        result.update(passed=True, measured_samples=132, measured_processes=192, excluded_warmup_samples=22, excluded_warmup_processes=32, balanced_six_rounds=True, all_sample_files_accounted_for=True, all_outputs_match_verified_coverage=True, no_observed_dropped_or_retried_samples=True, recomputed_groups=groups, recomputed_comparisons=comparisons)
        result['limits'] = ['Nanosecond elapsed values originate in frozen raw per-child records; this audit checks consistency and accounting, not an independent clock recording.', 'Prior coverage receipts and exact output hashes establish unchanged coverage; the original coverage algorithm is not rerun.', 'Codegen gate and evidence hashes are checked; this audit does not repeat disassembly interpretation.']
    except Exception as error:
        result['errors'].append({'exception': repr(error), 'traceback': traceback.format_exc()})
    result['checks'] = dict(counts)
    result['completed_at'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('platform_root', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--original-reference-root', type=Path)
    parser.add_argument('--check-runtime-files', action='store_true')
    arguments = parser.parse_args()
    if arguments.output.exists():
        parser.error('Output already exists; choose a fresh audit receipt path.')
    result = audit(arguments.platform_root, arguments.original_reference_root, arguments.check_runtime_files)
    with arguments.output.open('x') as stream:
        json.dump(result, stream, indent=2)
        stream.write('\n')
    print(json.dumps({key: result[key] for key in ('passed', 'platform_root', 'checks', 'errors')}, indent=2))
    raise SystemExit(0 if result['passed'] else 1)


if __name__ == '__main__':
    main()
