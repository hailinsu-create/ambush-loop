from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from pathlib import Path
import json,hashlib,datetime,os
root=Path('/workspace/pr15-web-artifacts/843f55c3bc618706d1ddc7aa18d01223927233fc/qa-polygon-caller');manifest=json.loads(Path('/workspace/ambush-pr15/.cursor/docs/evidence/20261004-pr15-native-record3d/fixed-d9c-six-r/producer-manifest.json').read_text());records={x['level']:x for x in manifest['records']}
for r in records.values():assert hashlib.sha256(Path(r['path']).read_bytes()).hexdigest()==r['sha256']
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**k):super().__init__(*a,directory=str(root),**k)
 def do_GET(self):
  if self.path.startswith('/fixtures/'):
   level=self.path[10:].removesuffix('.bin');r=records.get(level)
   if not r:self.send_error(404);return
   data=Path(r['path']).read_bytes();self.send_response(200);self.send_header('Content-Type','application/octet-stream');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data);return
  super().do_GET()
print(json.dumps({'pid':os.getpid(),'bind':'127.0.0.1:12788','root':str(root),'source_sha':manifest['source_sha'],'records':[{'level':x['level'],'sha256':x['sha256'],'bytes':x['bytes']} for x in records.values()],'start':datetime.datetime.now(datetime.timezone.utc).isoformat(),'debug_only':True}),flush=True)
ThreadingHTTPServer(('127.0.0.1',12788),H).serve_forever()
