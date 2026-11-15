#!/usr/bin/env python3
"""Frozen matched native Linux CLI controls. Existing measurements directories are never reused."""
import argparse
import json
import statistics
import sys
import linux_runner as runner
from common import ROOT, CASES, NATIVE_CASES, digest, disk_guard, host_snapshot, load, verify_fixtures, verify_sources, write_json

TOOLS = ['B', 'C']
SCHEDULE = [('split', CASES), ('native', NATIVE_CASES)]
ROUNDS = 6


def validate():
    assert sys.platform == 'linux', sys.platform
    freeze = load(ROOT / 'control/pre-benchmark-freeze.json')
    required = {'bin/B', 'bin/C', 'control/config.json', 'control/runtime.json', 'control/common.py',
                'control/linux_runner.py', 'control/run_matched.py', 'control/source-reference.json',
                'control/reference.json', 'control/matched-protocol.json', 'control/codegen-gate.json'}
    assert required <= set(freeze['files'])
    for rel, wanted in freeze['files'].items():
        assert digest(ROOT / rel) == wanted, rel
    runtime = load(ROOT / 'control/runtime.json')
    for path, wanted in runtime['libswiftCore_sha256'].items():
        assert digest(path) == wanted, path
    protocol = load(ROOT / 'control/matched-protocol.json')
    assert protocol['measured_rounds'] == ROUNDS and protocol['split_cases'] == CASES and protocol['native_cases'] == NATIVE_CASES
    return {'frozen_files': len(freeze['files']), 'sources': verify_sources(), 'fixture_files': verify_fixtures()}


def make_summary(samples, warmups):
    assert len(samples) == 132
    assert sum(len(x['parts']) for x in samples) == 192
    assert len(warmups) == 22
    assert sum(len(x['parts']) for x in warmups) == 32
    groups, comparisons = [], []
    for suite, cases in SCHEDULE:
        for case in cases:
            by_tool = {}
            for tool in TOOLS:
                selected = [x for x in samples if (x['suite'], x['case'], x['tool']) == (suite, case, tool)]
                assert len(selected) == ROUNDS
                assert sorted(x['round'] for x in selected) == list(range(1, ROUNDS + 1))
                by_tool[tool] = {x['round']: x for x in selected}
                elapsed = [x['elapsed_ns'] / 1e9 for x in selected]
                rss = [x['peak_rss_bytes'] / 1048576 for x in selected]
                groups.append({'suite': suite, 'case': case, 'tool': tool, 'n': ROUNDS,
                               'elapsed_median_s': statistics.median(elapsed),
                               'elapsed_min_s': min(elapsed), 'elapsed_max_s': max(elapsed),
                               'peak_rss_median_mib': statistics.median(rss),
                               'peak_rss_min_mib': min(rss), 'peak_rss_max_mib': max(rss),
                               'cpu_median_s': statistics.median(x['cpu_seconds'] for x in selected)})
            paired = []
            for i in range(1, ROUNDS + 1):
                b, c = by_tool['B'][i], by_tool['C'][i]
                assert b['order'] == c['order']
                paired.append({'round': i, 'order': b['order'],
                               'elapsed_change_pct': (c['elapsed_ns'] / b['elapsed_ns'] - 1) * 100,
                               'rss_change_pct': (c['peak_rss_bytes'] / b['peak_rss_bytes'] - 1) * 100,
                               'elapsed_difference_s': (c['elapsed_ns'] - b['elapsed_ns']) / 1e9,
                               'rss_difference_mib': (c['peak_rss_bytes'] - b['peak_rss_bytes']) / 1048576})
            comparisons.append({'suite': suite, 'case': case, 'n_pairs': ROUNDS,
                                'paired_elapsed_change_median_pct': statistics.median(x['elapsed_change_pct'] for x in paired),
                                'paired_elapsed_change_min_pct': min(x['elapsed_change_pct'] for x in paired),
                                'paired_elapsed_change_max_pct': max(x['elapsed_change_pct'] for x in paired),
                                'paired_rss_change_median_pct': statistics.median(x['rss_change_pct'] for x in paired),
                                'paired_rss_difference_median_mib': statistics.median(x['rss_difference_mib'] for x in paired),
                                'pairs': paired})
    return {'completed_at': runner.stamp(), 'passed': True, 'samples': samples,
            'warmup_samples': warmups, 'groups': groups, 'comparisons': comparisons,
            'measured_samples': 132, 'measured_processes': 192,
            'excluded_warmup_samples': 22, 'excluded_warmup_processes': 32,
            'no_samples_removed_or_retried': True, 'all_outputs_retained': True,
            'all_outputs_match_original_independent_coverage': True}



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-only', action='store_true')
    args = parser.parse_args()
    before = validate()
    if args.validate_only:
        print(json.dumps({'passed': True, 'validation': before}), flush=True)
        return
    disk_guard()
    measurements = ROOT / 'measurements'
    measurements.mkdir(exist_ok=False)
    write_json(measurements / 'start.json', {'started_at': runner.stamp(), 'validation': before, 'host': host_snapshot()})
    samples, warmups = [], []
    references = load(ROOT / 'control/reference.json')['expected']
    try:
        for suite, cases in SCHEDULE:
            for iteration in range(ROUNDS + 1):
                phase = 'warmup' if iteration == 0 else f'round-{iteration:02}'
                order = TOOLS if iteration == 0 or iteration % 2 else list(reversed(TOOLS))
                offset = max(0, iteration - 1) % len(cases)
                case_order = cases[offset:] + cases[:offset]
                for case in case_order:
                    for tool in order:
                        record = runner.run_one(suite, case, tool, measurements / suite / phase / case / tool, references[suite][case])
                        enriched = {'round': iteration, 'order': order, **record}
                        (samples if iteration else warmups).append(enriched)
                        print(json.dumps({'suite': suite, 'round': iteration, 'order': order, 'case': case, 'tool': tool,
                                          'elapsed_s': record['elapsed_ns'] / 1e9,
                                          'peak_mib': record['peak_rss_bytes'] / 1048576}), flush=True)
        after = validate()
        summary = make_summary(samples, warmups)
        summary['validation_before'] = before
        summary['validation_after'] = after
        summary['measurement_method'] = 'perf_counter_ns around Popen and blocking wait4; Linux per-child ru_maxrss KiB converted to bytes'
        summary['host_after'] = host_snapshot()
        write_json(measurements / 'summary.json', summary)
    except BaseException as error:
        write_json(measurements / 'failed.json', {'finished_at': runner.stamp(), 'error': repr(error),
                   'completed_measured_samples': len(samples), 'completed_warmup_samples': len(warmups), 'no_retry_performed': True})
        raise


if __name__ == '__main__':
    main()
