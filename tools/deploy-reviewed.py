"""Deploy an explicit reviewed file list via websupport, with hashes and backups.

Plan: python tools/deploy-reviewed.py --file path [--file path] --plan plan.json
Apply the unchanged plan: python tools/deploy-reviewed.py --apply plan.json
No directory cleanup, no secret handling, no GitHub dependency.
"""
from pathlib import Path
import argparse, subprocess, hashlib, json, re, tarfile, datetime, urllib.request
TARGETS = {'sk.polascin.net': ('polascin.net/sub/sk','https://sk.polascin.net/'),
 'books.polascin.net': ('polascin.net/sub/books','https://books.polascin.net/'),
 'arenibuspropaganda': ('polascin.net/arenibus','https://arenibus.polascin.net/')}
def run(*args):
 return subprocess.check_output(args,text=True,stderr=subprocess.STDOUT).strip()
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=20','websupport']
def q(s):
 if not re.fullmatch(r'[A-Za-z0-9_./-]+',s) or '..' in s.split('/'):raise ValueError('Unsafe path')
 return "'"+s+"'"
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def remote_hash(target):
 return run(*SSH,'if test -f '+q(target)+'; then sha256sum '+q(target)+" | cut -d ' ' -f 1; else echo missing; fi")
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--file',action='append',default=[]);parser.add_argument('--plan',type=Path);parser.add_argument('--apply',type=Path)
 args=parser.parse_args();root=Path(__file__).resolve().parent.parent
 remote,url=TARGETS[root.name]
 if args.plan:
  items=[]
  for name in args.file:
   q(name);p=root/name
   if not p.is_file() or name.startswith(('.git/','private/')) or p.name in ['.env','env.ini','db.config.php','db_config.php'] or p.suffix not in ['.html','.php','.js','.css','.txt','.json','.map',''] and p.name!='.htaccess':raise ValueError('Not a public deploy file: '+name)
   if p.suffix=='.php':run('php','-l',str(p))
   old_hash=remote_hash(remote+'/'+name);new_hash=digest(p)
   if old_hash != new_hash: items.append({'name':name,'old':old_hash,'new':new_hash})
  if not items:raise ValueError('No files')
  args.plan.parent.mkdir(parents=True,exist_ok=True)
  args.plan.write_text(json.dumps({'root':str(root),'remote':remote,'url':url,'files':items},indent=2),encoding='utf-8')
  print('Plan:',args.plan,'files:',len(items));return
 if not args.apply:parser.error('Use --plan or --apply')
 plan=json.loads(args.apply.read_text(encoding='utf-8'))
 if plan['root']!=str(root) or plan['remote']!=remote:raise ValueError('Plan belongs to another checkout')
 items=plan['files']
 for item in items:
  if digest(root/item['name'])!=item['new'] or remote_hash(remote+'/'+item['name'])!=item['old']:raise RuntimeError('File changed: '+item['name'])
 stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
 backup='codex-deploy-backups/'+stamp+'/'+root.name
 run(*SSH,'mkdir -p '+q(backup+'/stage')+' '+q(backup+'/original'))
 archive=args.apply.with_suffix('.tar.gz')
 with tarfile.open(archive,'w:gz') as tar:
  for item in items:tar.add(root/item['name'],arcname=item['name'],recursive=False)
 run('scp','-o','BatchMode=yes',str(archive),'websupport:'+backup+'/payload.tar.gz')
 run(*SSH,'tar -xzf '+q(backup+'/payload.tar.gz')+' -C '+q(backup+'/stage'))
 # Back up all current files before publishing any file.
 for item in items:
  name=item['name'];target=remote+'/'+name
  if remote_hash(target)!=item['old']:raise RuntimeError('Concurrent change: '+name)
  if item['old']!='missing':run(*SSH,'mkdir -p '+q(str(Path(backup+'/original/'+name).parent).replace('\\','/'))+' && cp -p '+q(target)+' '+q(backup+'/original/'+name))
 published=[]
 try:
  # Publish assets first, then CSP, then entry pages that reference them.
  for item in sorted(items,key=lambda i: 1 if i['name'].endswith('.htaccess') else (2 if Path(i['name']).suffix in ['.html','.php'] else 0)):
   name=item['name'];target=remote+'/'+name;stage=backup+'/stage/'+name
   if remote_hash(target)!=item['old']:raise RuntimeError('Concurrent change: '+name)
   run(*SSH,'mkdir -p '+q(str(Path(target).parent).replace('\\','/'))+' && chmod 644 '+q(stage)+' && mv '+q(stage)+' '+q(target))
   published.append(item)
   if remote_hash(target)!=item['new']:raise RuntimeError('Hash mismatch: '+name)
  req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36'})
  with urllib.request.urlopen(req,timeout=30) as response:
   if response.status!=200:raise RuntimeError('HTTP smoke failed')
 except Exception:
  for item in published:
   if item['old']!='missing':run(*SSH,'cp -p '+q(backup+'/original/'+item['name'])+' '+q(remote+'/'+item['name']))
  raise
 print('PASS: hashes and HTTP 200; backup:',backup)
if __name__=='__main__':main()
