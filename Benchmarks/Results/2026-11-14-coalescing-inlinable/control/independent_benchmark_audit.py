from pathlib import Path
from collections import Counter
import datetime, hashlib, json, math, statistics, traceback
R=Path(__file__).resolve().parents[1]
load=lambda p:json.loads(p.read_text())
S=load(R/'measurements/summary.json'); C=load(R/'control/context.json'); O=Path(C['previous_comparison']); P=load(R/'control/matched-protocol.json')
counts=Counter(); audit={'passed':False,'errors':[],'scope':'Independent read-only audit; no benchmark harness imported or benchmark rerun. Only audit artifacts written.','started_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
def check(x,m):
 counts['assertions']+=1
 if not x:raise AssertionError(m)
def close(a,b,m):check(math.isclose(a,b,rel_tol=1e-12,abs_tol=1e-12),m)
def sha(p):
 with p.open('rb') as f:d=hashlib.file_digest(f,'sha256').hexdigest()
 counts['files_hashed']+=1; counts['bytes_hashed']+=p.stat().st_size
 return d
try:
 audit['summary_sha256']=sha(R/'measurements/summary.json')
 check((R/'fixtures').resolve()==(O/'fixtures').resolve(),'same fixture directory')
 frozen={}
 for name,base,manifest in [('new',R,R/'control/pre-benchmark-freeze.json'),('old',O,O/'control/freeze.json'),('references',O,R/'control/reference-output-freeze.json')]:
  files=load(manifest)['files'];frozen[name]=len(files)
  for f,h in files.items():check(sha(base/f)==h,'frozen file '+name+'/'+f)
 audit['frozen_files_verified']=frozen
 check(frozen=={'new':203,'old':53,'references':39},'freeze counts')
 check(S['validation_before']==S['validation_after']=={'new_run_files':203,'previous_comparison_files':53,'reference_output_files':39},'before/after checks')
 measured=S['samples'];warmup=S['warmup_samples'];allrows=measured+warmup
 for rows,ns,np,label in [(measured,132,192,'measured'),(warmup,22,32,'warmup')]:
  check(len(rows)==ns,label+' sample count');check(sum(len(x['parts']) for x in rows)==np,label+' process count')
 check(S['measured_samples']==132 and S['measured_processes']==192 and S['excluded_warmup_samples']==22 and S['excluded_warmup_processes']==32,'summary counts')
 key=lambda x:(x['suite'],x['round'],x['case'],x['tool'])
 indexed={key(x):x for x in allrows};check(len(indexed)==154,'unique sample keys')
 schedule=[('split',P['split_cases']),('native',P['native_cases'])]
 check(len(schedule[0][1])==8 and len(schedule[1][1])==3 and P['measured_rounds']==6,'protocol')
 refs={};order=[];paths=set()
 for suite,cases in schedule:
  for case in cases:
   ref=load(O/f'warmup/{suite}/{case}/cidrmerge/sample.json');cov=load(O/f'warmup/{suite}/{case}/cidrmerge/coverage.json')
   check(ref['passed'] and cov['passed'] and ref['suite']==suite and ref['case']==case,'reference passed/identity')
   check(cov['actual']['coverage_sha256']==cov['expected_coverage_sha256'] and cov['actual']['minimal_cidr_count']==cov['expected_minimal_cidr_count'],'reference exact/minimal coverage')
   families=[None] if suite=='native' else [f for f in [4,6] if (R/f'fixtures/{case}/ipv{f}.txt').stat().st_size]
   check([p['family'] for p in ref['parts']]==families,'reference families')
   cf={Path(p['path']).name:p for p in cov['output_files']}
   for p in ref['parts']:
    co=cf[Path(p['output']).name]
    check(p['output_sha256']==co['sha256'] and p['output_bytes']==co['bytes']==(O/p['output']).stat().st_size,'reference output records')
   refs[(suite,case)]={p['family']:p for p in ref['parts']}
  for i in range(7):
   tools=['B','C'] if i==0 or i%2 else ['C','B'];offset=max(0,i-1)%len(cases)
   for case in cases[offset:]+cases[:offset]:
    for tool in tools:
     row=indexed[(suite,i,case,tool)];check(row['order']==tools,'balanced declared order')
     phase='warmup' if i==0 else f'round-{i:02d}'
     path=R/f'measurements/{suite}/{phase}/{case}/{tool}/sample.json';paths.add(path);raw=load(path)
     check(raw=={k:v for k,v in row.items() if k not in ('round','order')},'aggregate/raw sample equality')
     check(raw['passed'] and raw['matches_verified_warmup_bytes'] and 'error' not in raw,'sample passed')
     ref=refs[(suite,case)];check([p['family'] for p in raw['parts']]==list(ref),'sample family order')
     for part in raw['parts']:
      f=part['family'];label=str(f or 'mixed');out=path.parent/f'{label}.stdout';err=path.parent/f'{label}.stderr';time=path.parent/f'{label}.time'
      inp=R/'fixtures'/case/('input.txt' if f is None else f'ipv{f}.txt')
      check(part['command']==[str(R/'bin'/tool),'--raw','--representation','cidr',str(inp)],'exact command')
      check(part['input']==str(inp.relative_to(R)) and part['output']==str(out.relative_to(R)),'input/output paths')
      check(sha(out)==part['output_sha256']==ref[f]['output_sha256'],'output hash')
      check(out.stat().st_size==part['output_bytes']==ref[f]['output_bytes'],'output bytes')
      check(part['exit_code']==0 and part['stderr_bytes']==err.stat().st_size==0,'exit/stderr')
      lines=time.read_text().splitlines();bt={k:float(next(l.split()[1] for l in lines if l.startswith(k+' '))) for k in ['real','user','sys']};rss=int(next(l.split()[0] for l in lines if l.strip().endswith('maximum resident set size')))
      check(bt==part['bsd_time'] and rss==part['peak_rss_bytes'],'raw native time/RSS')
      check(part['elapsed_ns']>0 and part['elapsed_ns']/1e9>=bt['real']-.011,'external timer sanity')
      counts['outputs_verified']+=1;counts['raw_timing_files_verified']+=1
     check(raw['elapsed_ns']==sum(p['elapsed_ns'] for p in raw['parts']),'elapsed sum')
     check(raw['peak_rss_bytes']==max(p['peak_rss_bytes'] for p in raw['parts']),'RSS maximum')
     close(raw['cpu_seconds'],sum(p['bsd_time']['user']+p['bsd_time']['sys'] for p in raw['parts']),'CPU sum')
     check(raw['output_bytes']==sum(p['output_bytes'] for p in raw['parts']),'output sum');order.append(row)
 check(set(R.glob('measurements/**/sample.json'))==paths,'all raw sample files represented')
 check(len(list(R.glob('measurements/**/*.stdout')))==224 and len(list(R.glob('measurements/**/*.time')))==224,'224 retained stdout/time files')
 check(not (R/'measurements/failed.json').exists(),'no failure receipt')
 for a,b in zip(order,order[1:]):check(datetime.datetime.fromisoformat(a['finished_at'])<=datetime.datetime.fromisoformat(b['started_at']),'sequential nonoverlapping schedule')
 log=[json.loads(l) for l in (R/'control/matched.log').read_text().splitlines()];check(len(log)==154,'log count')
 for a,b in zip(log,order):
  check(all(a[k]==b[k] for k in ['suite','round','case','tool','order']),'log order');close(a['elapsed_s'],b['elapsed_ns']/1e9,'log elapsed');close(a['peak_mib'],b['peak_rss_bytes']/1048576,'log RSS')
 check([r for r in order if r['round']]==measured and [r for r in order if not r['round']]==warmup,'aggregate sample ordering')
 groups=[];comparisons=[]
 for suite,cases in schedule:
  for case in cases:
   for tool in ['B','C']:
    rows=[indexed[(suite,i,case,tool)] for i in range(1,7)];es=[r['elapsed_ns']/1e9 for r in rows];ms=[r['peak_rss_bytes']/1048576 for r in rows]
    calc={'n':6,'elapsed_median_s':statistics.median(es),'elapsed_min_s':min(es),'elapsed_max_s':max(es),'peak_rss_median_mib':statistics.median(ms),'peak_rss_min_mib':min(ms),'peak_rss_max_mib':max(ms),'cpu_median_s':statistics.median(r['cpu_seconds'] for r in rows)}
    found=[g for g in S['groups'] if (g['suite'],g['case'],g['tool'])==(suite,case,tool)];check(len(found)==1,'unique group')
    for k,v in calc.items():close(found[0][k],v,'group '+k)
    groups.append({'suite':suite,'case':case,'tool':tool,**calc})
   pairs=[]
   for i in range(1,7):
    b=indexed[(suite,i,case,'B')];c=indexed[(suite,i,case,'C')]
    pairs.append({'round':i,'order':b['order'],'elapsed_change_pct':(c['elapsed_ns']/b['elapsed_ns']-1)*100,'rss_change_pct':(c['peak_rss_bytes']/b['peak_rss_bytes']-1)*100,'elapsed_difference_s':(c['elapsed_ns']-b['elapsed_ns'])/1e9,'rss_difference_mib':(c['peak_rss_bytes']-b['peak_rss_bytes'])/1048576})
   found=[x for x in S['comparisons'] if (x['suite'],x['case'])==(suite,case)];check(len(found)==1,'unique comparison');check(found[0]['pairs']==pairs,'all paired records')
   check(Counter(tuple(p['order']) for p in pairs)=={('B','C'):3,('C','B'):3},'three of each pair order')
   calc={'n_pairs':6,'paired_elapsed_change_median_pct':statistics.median(p['elapsed_change_pct'] for p in pairs),'paired_elapsed_change_min_pct':min(p['elapsed_change_pct'] for p in pairs),'paired_elapsed_change_max_pct':max(p['elapsed_change_pct'] for p in pairs),'paired_rss_change_median_pct':statistics.median(p['rss_change_pct'] for p in pairs),'paired_rss_difference_median_mib':statistics.median(p['rss_difference_mib'] for p in pairs)}
   for k,v in calc.items():close(found[0][k],v,'comparison '+k)
   comparisons.append({'suite':suite,'case':case,**calc})
 check(len(S['groups'])==22 and len(S['comparisons'])==11,'summary group counts')
 audit.update(passed=True,measured_samples=132,measured_processes=192,excluded_warmup_samples=22,excluded_warmup_processes=32,all_sample_records_accounted_for=True,all_outputs_match_original_verified_coverage=True,balanced_six_rounds=True,no_observed_dropped_or_retried_samples=True,recomputed_groups=groups,recomputed_comparisons=comparisons)
 audit['limits']=['External nanoseconds originate in raw sample records; native time only supports a hundredth-second sanity check, not exact reconstruction.','Original independent coverage receipts and outputs were hash-verified; the coverage algorithm was not rerun.','Six pairs per workload validate this controlled Mac experiment, not cross-platform performance.']
except Exception as e:audit['errors'].append({'exception':repr(e),'traceback':traceback.format_exc()})
audit['checks']=dict(counts);audit['completed_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
(R/'control/independent-benchmark-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
text='# Independent matched-benchmark audit\n\n'+('Passed.' if audit['passed'] else 'Failed; see JSON receipt.')+'\n\n'
if audit['passed']:text+='All 132 measured samples (192 processes), 22 excluded warmup samples (32 processes), and 224 retained stdout files were checked. Every output hash matches its original independently verified coverage reference. Raw time/RSS, empty stderr, commands, sample inventory, schedule/log chronology, balanced six-round ordering, frozen source/binary/harness files and prior reference preservation pass. All 22 group statistics and 66 paired changes were independently recomputed and match the summary. No observed samples were dropped or retried.\n\nNo benchmark harness was imported and no benchmark or coverage process was run. Nanosecond timings come from the immutable raw records and pass native-time sanity checks; coverage reference receipts were hash-verified rather than rerun.\n'
(R/'control/independent-benchmark-audit.md').write_text(text)
print(json.dumps({'passed':audit['passed'],'checks':dict(counts),'errors':audit['errors'],'comparisons':audit.get('recomputed_comparisons',[])},indent=2))
