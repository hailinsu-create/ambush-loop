page.keyboard.press('m')
page.wait_for_function("localStorage.getItem('ambush-loop.config.v1')!==null",timeout=5000)
saved_at=time.monotonic();checkpoint=page.evaluate("JSON.parse(localStorage.getItem('ambush-loop.config.v1'))")
assert checkpoint['schema']==1 and 'muted=true' in checkpoint['files']['ambush_loop_settings.cfg'] and checkpoint['files']['ambush_loop.cfg'] is None
page.wait_for_timeout(800);before_reload=time.monotonic();page.reload(wait_until='load')
page.wait_for_function("!document.getElementById('status') || document.getElementById('status').style.display==='none'",timeout=45000)
page.mouse.click(1150,650);page.keyboard.press('m')
page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=false')",timeout=5000)
after=page.evaluate("JSON.parse(localStorage.getItem('ambush-loop.config.v1'))")
# The opposite next physical toggle proves actual GameSettings loaded true after refresh,
# rather than merely observing an untouched localStorage string.
page.screenshot(path=str(base/'fixed-title-800-after-next-toggle.png'))
result={'source':'bd9218a83047f1452cf8af910eed0f4784ec1335','checkpoint':checkpoint,'after_next_physical_toggle':after,'reload_after_saved_s':before_reload-saved_at,'preserved_via_actual_loaded_next_toggle':True,'page_errors':errors[:]}
(base/'fixed-title-800-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
