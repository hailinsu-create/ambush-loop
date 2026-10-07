from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from pathlib import Path
import json,datetime,os
root=Path('/workspace/sites/ambush-loop-game-final-843f-portable/dist')
class H(SimpleHTTPRequestHandler):
 def __init__(self,*a,**k):super().__init__(*a,directory=str(root),**k)
 def translate_path(self,path):return super().translate_path(path[4:] if path.startswith('/bad/') else path)
 def guess_type(self,path):
  if '.pck.part' in path:return 'application/octet-stream'
  return super().guess_type(path)
 def do_GET(self):
  if self.path=='/bad/index.pck.part01':
   data=bytearray((root/'index.pck.part01').read_bytes());data[-1]^=1;self.send_response(200);self.send_header('Content-Type','application/octet-stream');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data);return
  super().do_GET()
print(json.dumps({'pid':os.getpid(),'bind':'127.0.0.1:12786','root':str(root),'no_Content_Encoding_override':True,'bad_route':'one byte flipped dynamically in part01; all stored bundle bytes unchanged','start':datetime.datetime.now(datetime.timezone.utc).isoformat()}),flush=True)
ThreadingHTTPServer(('127.0.0.1',12786),H).serve_forever()
