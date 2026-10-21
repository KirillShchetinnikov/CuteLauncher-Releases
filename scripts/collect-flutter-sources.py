from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import urllib.request
import shutil

import argparse
import importlib.util
import subprocess

parser = argparse.ArgumentParser(description='Collect all pinned root Flutter DEPS Git archives locally.')
parser.add_argument('--flutter', type=Path, default=Path('.tools/flutter-upgrade'))
parser.add_argument('--output', type=Path, default=Path('.local/engine-source-archives'))
args = parser.parse_args()
root = args.flutter
spec = importlib.util.spec_from_file_location('release_source', Path(__file__).with_name('export-release-source.py'))
source_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source_module)
sources = source_module.engine_sources((root / 'DEPS').read_text())
print('Pinned root DEPS git repositories:',len(sources),flush=True)
out=args.output
out.mkdir(parents=True, exist_ok=True)
previous = json.loads((out / 'manifest.json').read_text()) if (out / 'manifest.json').exists() else {}
known = {item['archive']: item['sha256'] for item in previous.get('sources', []) if 'archive' in item}
def collect(item):
    name=item['path'].replace('/','_')+'-'+item['revision'][:12]+'.tar.gz'
    file=out/name
    url=item['repository'].removesuffix('.git')+'/+archive/'+item['revision']+'.tar.gz'
    try:
        if not file.exists():
            request=urllib.request.Request(url,headers={'User-Agent':'CuteLauncher-source-kit'})
            with urllib.request.urlopen(request,timeout=60) as response,file.with_suffix('.partial').open('wb') as stream:
                shutil.copyfileobj(response,stream)
            file.with_suffix('.partial').replace(file)
        with file.open('rb') as stream: sha=hashlib.file_digest(stream,'sha256').hexdigest()
        if name in known and known[name] != sha: raise ValueError('Cached archive checksum mismatch')
        result={**item,'archive':name,'sha256':sha,'size':file.stat().st_size}
        print('OK',item['path'],file.stat().st_size,flush=True)
        return result
    except Exception as error:
        print('UNAVAILABLE',item['path'],type(error).__name__,str(error),flush=True)
        return {**item,'error':str(error)}
with ThreadPoolExecutor(max_workers=6) as executor:
    results=list(executor.map(collect,sources))
(out/'manifest.json').write_text(json.dumps({'sdkFrameworkRevision':subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD']).decode().strip(),'sources':results},indent=2)+'\n')
print('Collected:',sum('archive' in r for r in results),'Missing:',sum('error' in r for r in results),flush=True)

if any('error' in item for item in results): raise SystemExit(1)
