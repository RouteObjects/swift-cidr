import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import shlex
import shutil
import statistics
import subprocess
import sys
import time

WORK = Path(__file__).parent
OUT = WORK / 'x86-evidence'
OUT.mkdir(exist_ok=True)
REMOTE = '/tmp/cidr-containment-20261030.fPBtAc'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
       '-o', 'ConnectTimeout=15', '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=3', 'swift-dev']

def capture(args, label):
    command = SSH + [shlex.join(args)]
    print('+', label, shlex.join(args)[:400], flush=True)
    start = time.time()
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    with gzip.open(OUT / (label + '.log.gz'), 'wb') as f:
        f.write(result.stdout)
    (OUT / (label + '.command.json')).write_text(json.dumps({
        'command': command, 'started_unix': start, 'elapsed_seconds': time.time() - start,
        'exit': result.returncode,
    }, indent=2) + '\n')
    if result.returncode:
        print(result.stdout.decode(errors='replace')[-15000:], flush=True)
        raise SystemExit(result.returncode)
    return result.stdout

def verify_sources(label):
    for phase in ['baseline', 'mask-chain']:
        original = WORK / 'evidence' / (phase + '.sources.json')
        expected = json.loads(original.read_text())
        program = "import hashlib,json,pathlib; root=pathlib.Path(" + repr(REMOTE + '/' + phase + '/swift-cidr') + "); paths=" + repr(list(expected)) + "; print(json.dumps({p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths},sort_keys=True))"
        actual = json.loads(capture(['python3', '-c', program], phase + '-sources-' + label))
        assert actual == expected, phase
        shutil.copy2(original, OUT / original.name)

def environment():
    for label, args in [
        ('host-kernel', ['uname', '-a']), ('host-os', ['cat', '/etc/os-release']),
        ('host-cpu', ['lscpu']), ('host-virtualization', ['systemd-detect-virt']),
        ('host-memory', ['free', '-m']), ('host-load', ['uptime']),
        ('host-cgroup-cpu', ['cat', '/sys/fs/cgroup/cpu.max']),
        ('host-cpuset', ['cat', '/sys/fs/cgroup/cpuset.cpus.effective']),
    ]:
        capture(args, label)
    verify_sources('before')

def matrix(version):
    binpath = '/home/craig/.local/share/swiftly/toolchains/' + version + '/usr/bin'
    env = ['env', 'PATH=' + binpath + ':/usr/bin:/bin']
    capture(env + ['swift', '--version'], version + '-swift-version')
    capture(env + ['llvm-objdump', '--version'], version + '-objdump-version')
    capture(['sha256sum', binpath + '/swift-frontend', binpath + '/llvm-objdump'], version + '-toolchain-sha256')
    for phase in ['baseline', 'mask-chain']:
        package = REMOTE + '/' + phase + '/swift-cidr/Benchmarks/ContainmentClient'
        scratch = REMOTE + '/build/' + version + '/' + phase
        label = version + '-' + phase
        capture(env + ['swift', 'build', '-v', '-c', 'release', '-j', '4', '--disable-automatic-resolution',
                       '--scratch-path', scratch, '--package-path', package], label + '-build')
        for module, filename in [('ContainmentClient', 'main.swift'), ('CIDR', 'IPPrefix.swift')]:
            capture(env + ['llvm-objdump', '-dr', '--no-show-raw-insn', scratch + '/release/' + module + '.build/' + filename + '.o'], label + '-' + module)
        capture(['sha256sum', scratch + '/release/ContainmentClient'], label + '-binary-sha256')
    for phase, run in [('baseline', 'run1'), ('mask-chain', 'run1'), ('mask-chain', 'run2'), ('baseline', 'run2')]:
        label = version + '-' + phase + '-' + run
        capture(['uptime'], label + '-load')
        data = capture(env + [REMOTE + '/build/' + version + '/' + phase + '/release/ContainmentClient'], label)
        rows = list(csv.DictReader(io.StringIO(data.decode())))
        assert len(rows) == 164
        (OUT / (label + '.csv')).write_bytes(data)
        summary = {case: statistics.median(int(r['elapsed_ns']) / int(r['scans']) for r in rows if r['case'] == case)
                   for case in ['v4.typed', 'v4.erased', 'v6.typed', 'v6.erased']}
        (OUT / (label + '.summary.json')).write_text(json.dumps(summary, indent=2) + '\n')
        print(json.dumps(summary), flush=True)
    for config in ['debug', 'release']:
        capture(env + ['swift', 'test', '-c', config, '-j', '4', '--disable-automatic-resolution',
                       '--scratch-path', REMOTE + '/build/' + version + '/tests',
                       '--package-path', REMOTE + '/mask-chain/swift-cidr'], version + '-tests-' + config)

if __name__ == '__main__':
    action, *args = sys.argv[1:]
    if action == 'environment': environment()
    elif action == 'matrix': matrix(*args)
    elif action == 'verify':
        verify_sources('after')
        archive = capture(['sha256sum', REMOTE + '/sources.tar.gz'], 'source-archive-sha256')
        assert archive.decode().split()[0] == hashlib.sha256((WORK / 'x86-sources.tar.gz').read_bytes()).hexdigest()
        capture(['bash', '-lc', 'swift --version'], 'default-toolchain-after')
