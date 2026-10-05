from playwright.sync_api import sync_playwright
from pathlib import Path
import json,datetime,time
out=Path('/tmp/pr15-web-controls/polygon-caller-diagnostic/runtime');out.mkdir()
hook='''(() => { window.__pr15BadGlBindings=[];
const p=WebGL2RenderingContext.prototype, original=p.bindBuffer, initial=new WeakMap();
p.bindBuffer=function(target,buffer){const prior=buffer?initial.get(buffer):null;if(prior===this.ELEMENT_ARRAY_BUFFER&&target===this.ARRAY_BUFFER&&window.__pr15BadGlBindings.length<24){window.__pr15BadGlBindings.push({target,prior,polygon:window.pr15PolygonDraw,stack:new Error('Invalid Godot index buffer target').stack});}if(buffer&&!prior)initial.set(buffer,target);return original.call(this,target,buffer);};
})();'''
logs=[];errors=[]
with sync_playwright() as pw:
 b=pw.chromium.connect_over_cdp('ws://127.0.0.1:45153/devtools/browser/2fe75df8-11af-437c-ae38-df82d05b1f7b');page=b.contexts[0].pages[0];page.add_init_script(hook);page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}));page.on('pageerror',lambda e:errors.append(str(e)));page.goto('http://127.0.0.1:12788/index.html',wait_until='load');page.wait_for_function("typeof window.pr15QA === 'function' && document.getElementById('status')===null",timeout=45000)
 def request(r):page.evaluate('(r)=>{window.pr15QAResult=null;window.pr15QA(JSON.stringify(r));}',r);page.wait_for_function("typeof window.pr15QAResult==='string'",timeout=60000);return json.loads(page.evaluate('window.pr15QAResult'))
 page.evaluate("async()=>{const b=await (await fetch('/fixtures/yard.bin')).arrayBuffer();engine.copyToFS('/tmp/native-record.bin',new Uint8Array(b));}");loaded=request({'action':'load_record','level':'yard'});request({'action':'seek','tick':2657});page.evaluate('new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))');page.screenshot(path=str(out/'yard-first-alert.png'));bad=page.evaluate('window.__pr15BadGlBindings');(out/'report.json').write_text(json.dumps({'loaded':loaded,'bad_bindings':bad,'console':logs,'errors':errors,'end':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'External per-Polygon2D DRAW + GL bind observers only; no GL error suppression/correction; excludes performance'},indent=2)+'\n');print(json.dumps({'bad_bindings':bad,'console_count':len(logs),'errors':errors}),flush=True)
