page.mouse.click(1150,650)
before=page.evaluate('pr15StorageObserver()')
expected='muted=false' if before['files']['ambush_loop_settings.cfg'] and 'muted=true' in before['files']['ambush_loop_settings.cfg'] else 'muted=true'
start=time.monotonic();page.keyboard.press('m');page.wait_for_function("token=>pr15StorageObserver().files['ambush_loop_settings.cfg']?.includes(token)",arg=expected,timeout=5000)
observed=time.monotonic();changed=page.evaluate('pr15StorageObserver()')
page.wait_for_timeout(800)
pre=page.evaluate('pr15StorageObserver()');reload_begin=time.monotonic();page.reload(wait_until='load')
page.wait_for_function("typeof pr15StorageObserver==='function' && (!document.getElementById('status') || document.getElementById('status').style.display==='none')",timeout=45000)
after=page.evaluate('pr15StorageObserver()');page.keyboard.press('Escape');page.wait_for_timeout(300);page.screenshot(path=str(base/'baseline-800-title-settings.png'))
result={'scope':'Original stock 1d17 release PCK, Title trusted physical M, observer-only JS. Narrow Title case, not independent failed/replay flow.','expected':expected,'before':before,'changed':changed,'pre_reload':pre,'after':after,'observed_s':observed-start,'reload_after_observed_s':reload_begin-observed,'preserved':bool(after['files']['ambush_loop_settings.cfg'] and expected in after['files']['ambush_loop_settings.cfg'])}
(base/'baseline-800-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
