for _ in range(3):
 page.mouse.click(830,437);page.wait_for_timeout(350)
page.screenshot(path=str(base/'fixed-yard-scout-original-tutorial.png'))
checkpoint=page.evaluate("JSON.parse(localStorage.getItem('ambush-loop.config.v1'))")
assert 'seen_yard=true' in checkpoint['files']['ambush_loop_settings.cfg']
assert 'level_id="yard"' in checkpoint['files']['ambush_loop.cfg']
page.keyboard.press('Space');page.wait_for_timeout(250);page.keyboard.press('Space');page.wait_for_timeout(600)
page.screenshot(path=str(base/'fixed-yard-alert-natural.png'))
print(json.dumps({'checkpoint':checkpoint,'trusted_original_input':'Three original tutorial Next; twice Space for original weak-equipment force alarm','errors':errors[:]}),flush=True)
