print(json.dumps({'url':page.url,'title':page.title(),'state':d.state()},ensure_ascii=False),flush=True)
page.screenshot(path=str(BASE/'initial-state-method-check.png'))
