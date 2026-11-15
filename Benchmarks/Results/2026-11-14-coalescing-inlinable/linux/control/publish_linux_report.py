#!/usr/bin/env python3
"""Plan additive report publication; --apply performs it after all validation passes.

Prior reports must exactly match the preexisting backups. No source, Git state,
binary, raw output or build cache is modified. Default mode writes nothing.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MAC = Path('MAC_EVIDENCE_ROOT')
DIRS = [Path('SWIFT_CIDR_REPOSITORY_ROOT/Benchmarks/Results/2026-11-14-coalescing-inlinable'),
        Path('CIDRMERGE_REPOSITORY_ROOT/Benchmarks/Results/2026-11-14-coalescing-inlinable')]
PRIOR = ROOT/'control/prior-reports'
BACKUPS = {MAC/'REPORT.md': PRIOR/'macos-report.md', DIRS[0]/'RESULTS.md': PRIOR/'swift-cidr-results.md', DIRS[1]/'RESULTS.md': PRIOR/'cidrmerge-results.md'}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def load(path):
    need(path.is_file(), 'Missing required file: '+str(path))
    return json.loads(path.read_text())


def sha(data):
    return hashlib.sha256(data).hexdigest()


def digest(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def stamp():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def priors():
    manifest = load(PRIOR/'manifest.json')
    need(set(manifest)=={str(p) for p in BACKUPS}, 'Prior manifest paths differ from the three approved reports')
    result = {}
    for target,backup in BACKUPS.items():
        original = backup.read_bytes()
        need(sha(original)==manifest[str(target)], 'Backup hash mismatch: '+str(backup))
        need(target.read_bytes()==original, 'Unexpected report change; refusing overwrite: '+str(target))
        result[target] = original
    return result


def final_report(preservation):
    generation = load(ROOT/'control/report-generation.json')
    need(generation['passed'] and digest(ROOT/'REPORT.md')==generation['report_sha256'], 'Report changed after generation')
    for name in ('arm64','x86_64'):
        p = ROOT/name
        audit_path = ROOT/'control'/f'independent-{name}-audit.json'
        audit, tests = load(audit_path), load(p/'control/build-tests/summary.json')
        summary, codegen = load(p/'measurements/summary.json'), load(p/'control/codegen.json')
        runtime = load(p/'control/runtime-postcheck.json')
        identity = generation['platforms'][name]
        need(audit['passed'] and not audit.get('errors') and tests['passed'] and summary['passed'], name+' incomplete or failed')
        need(codegen['specialization_gate_passed'] and runtime['passed'], name+' codegen/runtime failure')
        need(tests['test_executions']==1414 and summary['measured_samples']==132 and summary['measured_processes']==192, name+' count mismatch')
        need(identity['summary_sha256']==digest(p/'measurements/summary.json')==audit['summary_sha256'], name+' stale summary')
        need(identity['audit_sha256']==digest(audit_path), name+' stale audit')
        for v,k in [('B','baseline'),('C','candidate')]:
            need(identity['binary_sha256'][v]==tests['bin'][v]==audit['binary_sha256'][v]==codegen[k]['sha256'], name+' binary identity mismatch')
    need(preservation.is_relative_to(ROOT/'control'), 'Preservation receipt must be within this control directory')
    need(load(preservation).get('passed') is True, 'Preservation receipt did not pass')
    return (ROOT/'REPORT.md').read_text(), generation


def metadata(preservation):
    names = {'control/report-generation.json', 'control/generate_linux_report.py', 'control/publish_linux_report.py',
             'control/independent-arm64-audit.json', 'control/independent-x86_64-audit.json', 'shared/README.md', str(preservation.relative_to(ROOT)),
             'control/audit_linux.py', 'control/context.json', 'control/report-outline.md',
             'control/x86_64-outlier-review.json', 'control/x86_64-outlier-review.md',
             'control/retrieval-export-20261115T144301/transfer-receipt.json'}
    names.update(str(p.relative_to(ROOT)) for p in (ROOT/'control').glob('independent-x86_64-audit-*.json'))
    required = ('build-tests/summary.json','codegen.md','codegen.json','codegen-gate.json','runtime.json','runtime-postcheck.json',
                'host-before-benchmark.json','source-reference.json','pre-benchmark-freeze.json','config.json',
                'dependency-cleanliness.json','lock-normalization.json')
    optional = ('native-preflight.json','container.json','container-final-state.json','final-platform-check.json','source-parity.json','source-reference-full.json','validation-complete.json')
    for platform in ('arm64','x86_64'):
        names.add(platform+'/measurements/summary.json')
        names.update(platform+'/control/'+n for n in required)
        names.update(platform+'/control/'+n for n in optional if (ROOT/platform/'control'/n).is_file())
        p=ROOT/'control'/f'independent-{platform}-audit.md'
        if p.is_file():names.add(str(p.relative_to(ROOT)))
    names.update(str(p.relative_to(ROOT)) for p in (ROOT/'shared').iterdir() if p.is_file() and p.suffix in ('.py','.json'))
    result={}
    for rel in sorted(names):
        p=ROOT/rel
        need(p.is_file() and not p.is_symlink() and p.suffix in ('.md','.json','.py'), 'Not compact regular metadata: '+rel)
        need(p.stat().st_size<=5*1024**2, 'Metadata file too large: '+rel)
        result[rel]={'sha256':digest(p),'bytes':p.stat().st_size}
    need(sum(x['bytes'] for x in result.values())<=12*1024**2, 'Metadata bundle exceeds 12 MiB guard')
    return result


def links(base, text, pending=()):
    pending=set(pending)
    for target in re.findall(r'\]\((<[^>]+>|[^)\s]+)\)',text):
        t=target.removeprefix('<').removesuffix('>')
        if '://' in t or t.startswith('#'):continue
        p=(base/t.split('#',1)[0]).resolve()
        need(p in pending or p.is_file(), f'Broken Markdown link from {base}: {target}')


def portable(text,preservation):
    old_summary=f'../{MAC.name}/measurements/summary.json'
    old_report=f'../{MAC.name}/REPORT.md'
    need(text.count(']('+old_summary+')')==1 and text.count(']('+old_report+')')==1, 'Original Mac links not uniquely recognized')
    text=text.replace(']('+old_summary+')','](../measurements/summary.json)').replace(']('+old_report+')','](../RESULTS.md)')
    intro=(f'\nPortable Linux report and compact metadata. The full local evidence bundle is `{ROOT}`; '
           'raw outputs, binaries and build products remain in Downloads.\n')
    text=text.replace('\n\n','\n'+intro+'\n',1)
    text=text.replace('The complete new artifacts are under this Downloads directory, with independent platform directories.',
                      'The complete new artifacts remain in the Downloads directory named above, with independent platform directories.')
    rel=str(preservation.relative_to(ROOT))
    text+=('\n[Canonical working-copy preservation receipt]('+rel+'). Its exact allowed source differences are removal of four '
           '`// CHANGE:` comment prefixes; executable tokens and tests match the frozen candidate. '
           'The canonical CLI dependency requirement is unchanged; the local override belongs only to isolated snapshots.\n')
    need(all(line.rstrip()==line for line in text.splitlines()),'Trailing whitespace in portable report')
    return text


def notice(target,date):
    link=f'../{ROOT.name}/REPORT.md' if target==MAC/'REPORT.md' else 'linux/RESULTS.md'
    return (f'\n## Linux follow-up — {date}\n\n<!-- linux-followup:{ROOT.name} -->\n'
            'Matched Swift 6.4.2 validation is complete on ARM64 Linux and swift-dev x86-64: both actual sorting-call checks, '
            f'2,828 test executions and both matched benchmark runs passed. See the [Linux report]({link}) '
            'for separate platform results, retained observations and scope. This is an additive follow-up; '
            'the original macOS report contents and measurements above remain unchanged. '
            'Statements above about outstanding Linux performance checks describe the initial macOS stage; '
            'this follow-up completes the requested Linux comparisons. Release checks remain separate.\n').encode()


def append_exact(target,original,addition):
    need(target.read_bytes()==original,'Report changed immediately before append: '+str(target))
    fd,name=tempfile.mkstemp(prefix='.'+target.name+'.linux-',dir=target.parent)
    tmp=Path(name)
    os.fchmod(fd,target.stat().st_mode & 0o777)
    with os.fdopen(fd,'wb') as f:
        f.write(original+addition);f.flush();os.fsync(f.fileno())
    need(target.read_bytes()==original,'Report changed while preparing append; temp retained: '+str(tmp))
    os.replace(tmp,target)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true',help='Apply after reviewing the default read-only plan.')
    parser.add_argument('--date',required=True,help='Client-context YYYY-MM-DD date; never inferred from host clock.')
    parser.add_argument('--preservation-receipt',type=Path,required=True)
    a=parser.parse_args();datetime.date.fromisoformat(a.date)
    preservation=a.preservation_receipt.resolve()
    originals=priors();text,generation=final_report(preservation)
    files=metadata(preservation);report=portable(text,preservation)
    additions={p:notice(p,a.date) for p in originals};destinations=[d/'linux' for d in DIRS]
    need(not (ROOT/'control/report-publication.json').exists(),'Publication receipt already exists; refusing overwrite')
    for d in destinations:
        need(not d.exists(),'Destination already exists: '+str(d))
        pending={(d/f).resolve() for f in files}|{(d/'RESULTS.md').resolve()}
        links(d,report,pending)
    for p,b in originals.items():links(p.parent,(b+additions[p]).decode(),{(d/'RESULTS.md').resolve() for d in destinations})
    plan={'date':a.date,'report_sha256':generation['report_sha256'],'portable_report_sha256':sha(report.encode()),
          'destinations':[str(d) for d in destinations],'metadata_files':len(files),'metadata_bytes_per_repository':sum(v['bytes'] for v in files.values()),
          'preservation_receipt':str(preservation),'no_source_changes':True,
          'reports':{str(p):{'backup':str(BACKUPS[p]),'before_sha256':sha(b),'after_sha256':sha(b+additions[p]),'original_bytes':len(b),'added_bytes':len(additions[p])} for p,b in originals.items()}}
    if not a.apply:
        print(json.dumps({'dry_run':True,'passed':True,'plan':plan},indent=2));return
    events=ROOT/'control/report-publication-events.jsonl'
    need(not events.exists(),'Earlier publication journal exists; inspect it before retry')
    journal=events.open('x');installed=[]
    def event(value):
        journal.write(json.dumps({'at':stamp(),**value})+'\n');journal.flush();os.fsync(journal.fileno())
    try:
        event({'event':'begin','plan':plan});stages=[]
        for d in destinations:
            stage=Path(tempfile.mkdtemp(prefix='.linux-staging-',dir=d.parent))
            for rel,info in files.items():
                out=stage/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,out)
                need(digest(out)==info['sha256'],'Copy hash mismatch: '+rel)
            (stage/'RESULTS.md').write_text(report,encoding='utf-8');links(stage,report)
            stages.append((stage,d));event({'event':'staged','path':str(stage),'destination':str(d)})
        priors()
        for stage,d in stages:
            need(not d.exists(),'Destination appeared during staging: '+str(d));stage.rename(d);installed.append(str(d))
            event({'event':'installed','path':str(d)})
        for p,b in originals.items():
            append_exact(p,b,additions[p]);need(p.read_bytes()==b+additions[p],'Unexpected append result')
            event({'event':'appended','path':str(p),'sha256':digest(p)})
        for d in destinations:
            links(d,(d/'RESULTS.md').read_text())
            for rel,info in files.items():need(digest(d/rel)==info['sha256'],'Final metadata mismatch: '+rel)
        for p,b in originals.items():
            need(p.read_bytes().startswith(b) and digest(BACKUPS[p])==sha(b),'Original report/backup changed')
            links(p.parent,p.read_text())
        receipt={'passed':True,'completed_at':stamp(),'plan':plan,'metadata_files':files,'published_directories':installed,
                 'old_reports_preserved_as_exact_prefixes':True,'original_backup_hashes_unchanged':True,
                 'markdown_links_valid':True,'raw_outputs_binaries_build_caches_not_copied':True}
        with (ROOT/'control/report-publication.json').open('x') as f:json.dump(receipt,f,indent=2);f.write('\n')
        event({'event':'complete','receipt':'control/report-publication.json'})
        print(json.dumps({'passed':True,'published':installed,'receipt':str(ROOT/'control/report-publication.json')}))
    except BaseException as error:
        event({'event':'failed','error':repr(error),'installed':installed,'instruction':'Inspect journal and exact backups before retry; no rollback/deletion performed.'})
        raise
    finally:journal.close()


if __name__=='__main__':
    main()
