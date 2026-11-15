"""Unprofiled Linux child execution. Per-child wait4 RSS, not aggregate RUSAGE_CHILDREN."""
import os
import signal
import subprocess
import time
from common import ROOT, CASES, NATIVE_CASES, digest, disk_guard, load, runtime_environment, stamp, write_json


def timed_out(signum, frame):
    raise TimeoutError('180-second process timeout')


def run_one(suite, case, tool, location, reference):
    assert tool in ('B', 'C')
    free = disk_guard()
    location.mkdir(parents=True, exist_ok=False)
    record = {'suite': suite, 'case': case, 'tool': tool, 'started_at': stamp(),
              'free_bytes_before': free, 'parts': [], 'passed': False}
    try:
        for expected in reference['parts']:
            family = expected['family']
            label = str(family or 'mixed')
            source = ROOT / expected['input']
            output, stderr = location / (label + '.stdout'), location / (label + '.stderr')
            temporary = location / ('tmp-' + label)
            temporary.mkdir()
            env = {**runtime_environment(), 'LANG': 'C', 'LC_ALL': 'C', 'TZ': 'UTC',
                   'TMPDIR': str(temporary) + '/'}
            command = [str(ROOT / 'bin' / tool), '--raw', '--representation', 'cidr', str(source)]
            part = {'family': family, 'command': command, 'environment': env,
                    'input': expected['input'], 'output': str(output.relative_to(ROOT)),
                    'stderr': str(stderr.relative_to(ROOT)), 'started_at': stamp()}
            usage = None
            process = None
            failure = None
            previous = signal.signal(signal.SIGALRM, timed_out)
            with output.open('xb') as out, stderr.open('xb') as err:
                start = time.perf_counter_ns()
                signal.setitimer(signal.ITIMER_REAL, 180)
                try:
                    process = subprocess.Popen(command, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                               stdout=out, stderr=err, start_new_session=True)
                    pid, status, usage = os.wait4(process.pid, 0)
                    assert pid == process.pid
                    process.returncode = os.waitstatus_to_exitcode(status)
                except BaseException as error:
                    failure = error
                    if process is not None and process.returncode is None:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        try:
                            _, status, usage = os.wait4(process.pid, 0)
                            process.returncode = os.waitstatus_to_exitcode(status)
                        except ChildProcessError:
                            pass
                finally:
                    elapsed_ns = time.perf_counter_ns() - start
                    signal.setitimer(signal.ITIMER_REAL, 0)
                    signal.signal(signal.SIGALRM, previous)
            part.update(elapsed_ns=elapsed_ns, exit_code=process.returncode if process else None,
                        output_bytes=output.stat().st_size, output_sha256=digest(output),
                        stderr_bytes=stderr.stat().st_size)
            if usage is not None:
                raw = {key: getattr(usage, key) for key in ('ru_utime', 'ru_stime', 'ru_maxrss', 'ru_minflt',
                       'ru_majflt', 'ru_nswap', 'ru_inblock', 'ru_oublock', 'ru_nvcsw', 'ru_nivcsw')}
                part.update(wait4_rusage=raw, peak_rss_bytes=int(usage.ru_maxrss) * 1024,
                            cpu_seconds=usage.ru_utime + usage.ru_stime)
            if failure is not None:
                part['error'] = repr(failure)
            metric = location / (label + '.rusage.json')
            part['raw_metrics'] = str(metric.relative_to(ROOT))
            write_json(metric, part)
            record['parts'].append(part)
            if failure is not None:
                raise failure
            assert process.returncode == 0, (case, tool, part)
            assert part['stderr_bytes'] == 0, (case, tool, 'unexpected stderr')
            assert part['peak_rss_bytes'] > 0, (case, tool, 'missing RSS')
            assert (part['output_sha256'], part['output_bytes']) == (expected['output_sha256'], expected['output_bytes']), (case, tool, 'output differs from original verified coverage')
        record.update(elapsed_ns=sum(x['elapsed_ns'] for x in record['parts']),
                      peak_rss_bytes=max(x['peak_rss_bytes'] for x in record['parts']),
                      cpu_seconds=sum(x['cpu_seconds'] for x in record['parts']),
                      output_bytes=sum(x['output_bytes'] for x in record['parts']),
                      matches_verified_warmup_bytes=True, passed=True)
        return record
    except BaseException as error:
        record['error'] = repr(error)
        raise
    finally:
        record['finished_at'] = stamp()
        write_json(location / 'sample.json', record)
