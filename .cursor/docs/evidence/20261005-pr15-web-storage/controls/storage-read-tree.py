page.reload(wait_until='load');page.wait_for_function("typeof pr15StorageObserver==='function' && (!document.getElementById('status') || document.getElementById('status').style.display==='none')",timeout=45000)
state=page.evaluate('pr15StorageObserver()');(base/'baseline-tree.json').write_text(json.dumps(state,indent=2)+'\n');print(json.dumps(state),flush=True)
