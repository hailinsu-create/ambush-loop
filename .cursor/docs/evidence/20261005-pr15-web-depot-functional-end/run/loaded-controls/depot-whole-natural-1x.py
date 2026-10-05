assert d.state()['phase']==3 and len(context.pages)==1 and not d.state()['fixture_ready']
original_whole_state=d.state
natural_wave1_visual={'captured':False}
def state_with_natural_wave1_capture():
 current=original_whole_state()
 if not natural_wave1_visual['captured'] and current.get('phase')==4 and current['replay']['playing'] and current.get('view',{}).get('wave')==1 and current['view'].get('recorded_phase')==1:
  natural_wave1_visual['captured']=True
  image_path=BASE/'depot_whole1x_natural_wave1_alert.png'
  assert not image_path.exists()
  page.screenshot(path=str(image_path));following=original_whole_state()
  visual={'before':current,'after':following,'png_sha256':hashlib.sha256(image_path.read_bytes()).hexdigest(),'status':'SAVED_ALERT_BEFORE_AND_AFTER_SCREENSHOT' if following.get('view',{}).get('wave')==1 and following['view'].get('recorded_phase')==1 else 'PHASE_CHANGED_DURING_SCREENSHOT','scope':'screenshot during original natural whole1x, no pause/seek/phase write; saved second ALERT visual, not producer paused checkpoint'}
  (BASE/'depot-whole1x-natural-wave1-visual.json').write_text(json.dumps(visual,ensure_ascii=False,indent=2)+'\n')
  d.log('natural whole1x saved second ALERT screenshot',proof=visual)
  return following
 return current
d.state=state_with_natural_wave1_capture
try:packet1=whole(d,depot_record,1)
finally:d.state=original_whole_state
fp=d.rpc('fingerprints');trusted=page.evaluate('window.pr15TrustedInputs')
assert fp['record_sha256']==depot_record['sha256'] and all(row['isTrusted'] for row in trusted)
(BASE/'depot-whole-1x-fingerprints.json').write_text(json.dumps(fp,ensure_ascii=False,indent=2)+'\n')
(BASE/'depot-whole-1x-browser.json').write_text(json.dumps(trusted,ensure_ascii=False,indent=2)+'\n')
assert not errors and not [row for row in console if row['type']=='error' or 'SCRIPT ERROR:' in row['text'] or 'GL_INVALID' in row['text'] or 'INVALID_OPERATION' in row['text']]
