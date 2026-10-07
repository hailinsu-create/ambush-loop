page.goto('http://127.0.0.1:12793/index.html',wait_until='load')
page.wait_for_function("typeof pr15StorageObserver==='function' && (!document.getElementById('status') || document.getElementById('status').style.display==='none')",timeout=60000)
page.screenshot(path=str(base/'baseline-title.png'))
print(json.dumps(page.evaluate('pr15StorageObserver()')),flush=True)
