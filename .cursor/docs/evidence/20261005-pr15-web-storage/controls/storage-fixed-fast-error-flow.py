# Completion-triggered refresh: no fixed waiting period.
page.evaluate("()=>{if(window.__originalSetItem)Storage.prototype.setItem=window.__originalSetItem;}")
prior=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
page.keyboard.press('m');page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=true')",timeout=5000)
saved=time.monotonic();page.reload(wait_until='load');page.wait_for_function("!document.getElementById('status') || document.getElementById('status').style.display==='none'",timeout=45000)
page.mouse.click(1150,650);page.keyboard.press('m');page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=false')",timeout=5000)
page.screenshot(path=str(base/'fixed-completion-immediate.png'))
# Actual quota rejection from the public API (external QA fault injection only).
good=page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
page.evaluate("()=>{window.__originalSetItem=Storage.prototype.setItem;Storage.prototype.setItem=function(k,v){if(k==='ambush-loop.config.v1')throw new DOMException('QA quota fault','QuotaExceededError');return window.__originalSetItem.call(this,k,v)};}")
page.keyboard.press('m');page.wait_for_timeout(400)
assert page.evaluate("localStorage.getItem('ambush-loop.config.v1')")==good
page.screenshot(path=str(base/'fixed-storage-quota-feedback.png'))
page.evaluate("()=>{Storage.prototype.setItem=window.__originalSetItem;}")
page.reload(wait_until='load');page.wait_for_function("!document.getElementById('status') || document.getElementById('status').style.display==='none'",timeout=45000)
page.mouse.click(1150,650);page.keyboard.press('m');page.wait_for_function("JSON.parse(localStorage.getItem('ambush-loop.config.v1')).files['ambush_loop_settings.cfg'].includes('muted=true')",timeout=5000)
page.screenshot(path=str(base/'fixed-quota-reload-previous-good.png'))
result={'completion_triggered_refresh':True,'no_sleep_before_refresh':True,'quota_fault':'External public Storage.setItem throwing QuotaExceededError; production method restored before navigation.','quota_prior_checkpoint_retained':True,'actual_loaded_previous_good_state':True,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors[:]}
(base/'fixed-fast-error-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
