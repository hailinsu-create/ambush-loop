page.mouse.click(814,650);page.wait_for_timeout(600);page.screenshot(path=str(base/'fixed-natural-original-replay.png'))
page.keyboard.press('Space');page.wait_for_timeout(600);page.screenshot(path=str(base/'fixed-original-space-scout.png'))
page.keyboard.press('m');page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=false')",timeout=5000)
checkpoint=page.evaluate("JSON.parse(localStorage.getItem('ambush-loop.config.v1'))")
assert 'muted=false' in checkpoint['files']['ambush_loop.cfg'] and 'level_id="yard"' in checkpoint['files']['ambush_loop.cfg']
saved=time.monotonic();page.wait_for_timeout(800);reload_begin=time.monotonic()
def final_handler(self,*a,**kw):SimpleHTTPRequestHandler.__init__(self,*a,directory='/workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/release',**kw)
H.__init__=final_handler
page.reload(wait_until='load');page.wait_for_function("!document.getElementById('status') || document.getElementById('status').style.display==='none'",timeout=45000)
page.screenshot(path=str(base/'final-source-title-continue-after800.png'))
page.mouse.click(1150,650);page.keyboard.press('m');page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=true')",timeout=5000)
loaded=page.evaluate("JSON.parse(localStorage.getItem('ambush-loop.config.v1'))")
page.mouse.click(640,393);page.wait_for_timeout(700);page.screenshot(path=str(base/'final-source-original-continue-scout.png'))
result={'flow_source':'bd9218a83047f1452cf8af910eed0f4784ec1335','reload_final_source':'dab870595175eed37a6d2a012bc69a76062d48b0','only_later_changes':'save feedback layout, exact same store/protocol/main functions','flow':'Original Title/tutorial/knife forceALERT/natural FAILED/original Replay/Space SCOUT/trusted M; no bridge/ticks/forced outcome.','before_reload_checkpoint':checkpoint,'reload_after_saved_s':reload_begin-saved,'after_actual_loaded_title_toggle':loaded,'continue_original_input':True,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors[:]}
(base/'fixed-original-flow-800-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
