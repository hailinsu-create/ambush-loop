assert len(context.pages) == 1 and page.url == URL
state = d.state()
assert state['scene'] == 'res://scenes/title.tscn'
assert not state.get('fixture_ready', False)
assert_progress(state, plan['expected_after_natural_win'])
profile = json.loads((BASE/'profile-after-railcut.json').read_text())
assert profile['status'] == 'PASS' and profile['state']['settings']['configs'] == state['settings']['configs']
assert packet1['status'] == packet2['status'] == 'PASS'
assert not errors and not [r for r in console if r['type'] == 'error']
assert not [r for r in console if 'GL_INVALID' in r['text'] or 'SCRIPT ERROR:' in r['text'] or 'ERROR:' in r['text']]
(BASE/'console-final.json').write_text(json.dumps({'console': console, 'page_errors': errors}, ensure_ascii=False, indent=2)+'\n')
browser_before = json.loads((BASE/'railcut_reload-browser-before-reload.json').read_text())
browser_after = json.loads((BASE/'railcut-boundary-final-browser.json').read_text())
engine_before = json.loads((BASE/'railcut_reload-engine-before-reload.json').read_text())['inputs']
engine_after = json.loads((BASE/'railcut-boundary-final-fingerprints.json').read_text())['inputs']
assert all(r['isTrusted'] for r in browser_before+browser_after)
for label in ['initialize-railcut-original-profile', 'produce-railcut-natural', 'railcut-whole-natural-1x', 'railcut-whole-natural-2x', 'railcut-save-unlock-depot-reload']:
    receipt = json.loads((BASE/(label+'.json')).read_text())
    assert receipt['actual_exit'] == 0, label
proof = {'status': 'PASS', 'utc': utc(), 'controller_pid': os.getpid(), 'source': '8532c4c3084d1a5672bbe28dc96e1c02522a8f05', 'original_attempt': railcut_record['attempt'], 'original_record_sha256': railcut_record['sha256'], 'owned_pages': len(context.pages), 'scene': state['scene'], 'next_level': state['settings']['next'], 'fixture_ready': False, 'browser_trusted_before_reload': len(browser_before), 'browser_trusted_after_reload': len(browser_after), 'engine_inputs_before_reload': len(engine_before), 'engine_inputs_after_reload': len(engine_after), 'console_errors': 0, 'page_errors': 0, 'GL_invalid': 0, 'gpu_readpixels_warnings': len([r for r in console if 'ReadPixels' in r['text']]), 'whole_1x_callback_wall': packet1['input_to_terminal_callback_wall'], 'whole_2x_callback_wall': packet2['input_to_terminal_callback_wall'], 'rate_wall_ratio': packet1['input_to_terminal_callback_wall']/packet2['input_to_terminal_callback_wall'], 'scope': 'original railcut producer, same original recording natural whole1x/2x, depot handoff and exact saved reload; safe Title; browser END and pure artifact audit still separate'}
(BASE/'railcut-browser-final-proof.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({'RAILCUT_BROWSER_PROOF': proof}, ensure_ascii=False), flush=True)
