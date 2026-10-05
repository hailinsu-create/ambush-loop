s=d.state()
assert not s['settings']['seen'] and not s['settings']['has_progress'] and s['input_count']==0
page.goto('about:blank',wait_until='load')
print('Fixture method negative retained; no trusted game input occurred; browser WASM stopped before serial export',flush=True)
