from pathlib import Path
p=Path('/workspace/pr15-storage-baseline-observer/index.js');s=p.read_text()
old="const read=()=>{const rows={};for(const n of ['ambush_loop_settings.cfg','ambush_loop.cfg']){const p='/userfs/'+n;try{rows[n]=FS.readFile(p,{encoding:'utf8'});}catch(e){rows[n]=null;}}return rows;}"
new="const read=()=>{const rows={'ambush_loop_settings.cfg':null,'ambush_loop.cfg':null};const walk=(p,d)=>{if(d>8)return;try{for(const n of FS.readdir(p)){if(n==='.'||n==='..')continue;const q=p+'/'+n;if(FS.isDir(FS.stat(q).mode))walk(q,d+1);else if(n in rows)rows[n]=FS.readFile(q,{encoding:'utf8'});}}catch(e){}};walk('/userfs',0);return rows;}"
assert s.count(old)==1;p.write_text(s.replace(old,new))
