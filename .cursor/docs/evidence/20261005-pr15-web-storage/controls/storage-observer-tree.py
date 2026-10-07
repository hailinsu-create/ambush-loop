from pathlib import Path
p=Path('/workspace/pr15-storage-baseline-observer/index.js');s=p.read_text();old='window.pr15StorageObserver=()=>({time:performance.now(),files:read(),trace:trace.map(x=>({...x}))});'
new="window.pr15StorageObserver=()=>{const tree=[];const walk=(p,d)=>{if(d>8)return;try{for(const n of FS.readdir(p)){if(n==='.'||n==='..')continue;const q=p+'/'+n,st=FS.stat(q);if(FS.isDir(st.mode))walk(q,d+1);else tree.push({path:q,bytes:st.size});}}catch(e){}};walk('/userfs',0);return {time:performance.now(),files:read(),tree:tree,trace:trace.map(x=>({...x}))};};"
assert s.count(old)==1;p.write_text(s.replace(old,new))
