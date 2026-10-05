from pathlib import Path
import shutil,hashlib,json
src=Path('/workspace/pr15-web-artifacts/1d17a16156d2afae0cbdd77cf73030a57f953ada/release')
dst=Path('/workspace/pr15-storage-baseline-observer');assert not dst.exists();shutil.copytree(src,dst)
hook='''
// External QA observer: retains original syncfs arguments/callback, no writes or sync requests.
(function(){const trace=[];let seq=0;const read=()=>{const rows={};for(const n of ['ambush_loop_settings.cfg','ambush_loop.cfg']){const p='/userfs/'+n;try{rows[n]=FS.readFile(p,{encoding:'utf8'});}catch(e){rows[n]=null;}}return rows;};const original=FS.syncfs;FS.syncfs=function(populate,callback){const row={seq:++seq,populate:populate,start:performance.now(),files:read()};trace.push(row);return original.call(this,populate,function(error){row.end=performance.now();row.error=error?String(error):null;callback(error);});};window.pr15StorageObserver=()=>({time:performance.now(),files:read(),trace:trace.map(x=>({...x}))});})();
'''
p=dst/'index.js';s=p.read_text();needle='var GodotOS=';assert s.count(needle)==1;p.write_text(s.replace(needle,hook+needle,1))
(dst/'observer-identity.json').write_text(json.dumps({'original_pck_sha256':hashlib.sha256((src/'index.pck').read_bytes()).hexdigest(),'original_js_sha256':hashlib.sha256((src/'index.js').read_bytes()).hexdigest(),'observer_js_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'hook':hook,'scope':'Only observe existing FS.syncfs callbacks/read current files. No mutation, no new sync requests.'},indent=2)+'\n')
