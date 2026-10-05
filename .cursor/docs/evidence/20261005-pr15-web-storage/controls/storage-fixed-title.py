page.goto('http://127.0.0.1:12793/index.html',wait_until='load')
page.wait_for_function("!document.getElementById('status') || document.getElementById('status').style.display==='none'",timeout=60000)
page.mouse.click(1150,650);page.screenshot(path=str(base/'fixed-title-legacy-idb.png'))
print(json.dumps({'storage':page.evaluate("localStorage.getItem('ambush-loop.config.v1')"),'scope':'Unmodified fixed release JS+PCK; same original profile/origin, legacy IDB settings, physical input only.'}),flush=True)
