reload_original_uncaptured=reload_original
def reload_original(d,expected,label,reopen=False):
 before_fp=d.rpc('fingerprints')
 trusted=d.page.evaluate('window.pr15TrustedInputs')
 assert all(r['isTrusted'] for r in trusted)
 target=d.base/(label+'-before-refresh-input-proof.json');assert not target.exists()
 target.write_text(json.dumps({'fingerprints':before_fp,'browser_trusted':trusted,'scope':'read-only capture before original refresh/reopen discards this engine/input context'},ensure_ascii=False,indent=2)+'\n')
 return reload_original_uncaptured(d,expected,label,reopen)
assert len(context.pages)==1
assert warehouse_whole_1['status']=='PASS' and warehouse_whole_2['status']=='PASS'
assert json.loads((BASE/'warehouse-original-event-focus.json').read_text())['status']=='PASS'
boundary(d,spec['missions'][1])
assert len(context.pages)==1
