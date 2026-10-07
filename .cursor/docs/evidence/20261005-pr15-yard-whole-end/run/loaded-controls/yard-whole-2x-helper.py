def whole(d,record,rate):
 request_started=time.monotonic()
 level=record['level'];emit('WHOLE_START',level=level,rate=rate,attempt=record['attempt'],record_sha256=record['sha256'])
 assert d.state()['phase']==3
 d.click('replay');s=d.state();assert s['phase']==4 and s['replay']['speed']==2
 if s['replay']['playing']:d.click('pause')
 if d.state()['replay']['speed']!=rate:d.click('speed')
 slider=d.rpc('controls')['scrub'];x,y,w,h=slider['rect'];point=d.coords([x+1,y+h/2]);d.page.mouse.click(*point);d.page.keyboard.press('Home');d.settle()
 s=d.state();assert s['replay']['tick']==0 and not s['replay']['playing'] and s['replay']['speed']==rate,s['replay']
 before=d.rpc('fingerprints');assert before['record_sha256']==record['sha256'] and not before['frame_checks']['failures'],before['frame_checks']
 before['state']=d.state()
 before['public_checkpoint']=d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 before_path=d.base/(level+'-whole-'+str(rate)+'x-before-natural-full-fingerprint.json');assert not before_path.exists();before_path.write_text(json.dumps(before,ensure_ascii=False,indent=2)+'\n')
 row_start=len(before['replay_rows']);input_start=len(before['inputs'])
 start=time.monotonic();d.click('pause')
 deadline=max(180,6*(record['terminal']/60)/rate+30)
 s=d.wait(lambda x:x['replay']['tick']==record['terminal'] and not x['replay']['playing'],'natural whole terminal',deadline-(time.monotonic()-request_started))
 after=d.rpc('fingerprints');rows=after['replay_rows'][row_start:];inputs=after['inputs'][input_start:]
 after['state']=d.state()
 after['public_checkpoint']=d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 assert after['public_checkpoint']==before['public_checkpoint']
 assert after['state']['settings']['configs']==before['state']['settings']['configs']
 after_path=d.base/(level+'-whole-'+str(rate)+'x-after-terminal-full-fingerprint.json');assert not after_path.exists();after_path.write_text(json.dumps(after,ensure_ascii=False,indent=2)+'\n')
 first_playing=next((r for r in rows if r['playing']),None)
 terminal=next((r for r in rows if r['tick']==record['terminal'] and not r['playing']),None)
 actual_press=next((r for r in inputs if r.get('kind')=='mouse' and r.get('pressed')),None)
 assert terminal and first_playing and actual_press
 callback_wall=(terminal['us']-actual_press['us'])/1e6
 assert all(r['view_tick']==r['tick'] and r['attempt']==record['attempt'] and r['rate']==rate for r in rows)
 assert all(rows[i]['tick']<=rows[i+1]['tick'] for i in range(len(rows)-1))
 assert after['record_sha256']==record['sha256'] and after['domain']==before['domain']
 assert not after['frame_checks']['failures'] and not after['record_validation']['failures']
 elapsed=time.monotonic()-start
 packet={'status':'PASS','level':level,'rate':rate,'attempt':record['attempt'],'source':'1ec3198e9c0db367af96fc264604c5a286003b5e','record_sha256':record['sha256'],'terminal_tick':record['terminal'],'record_duration':record['terminal']/60,'deadline_wall':deadline,'controller_total_wall':elapsed,'input_to_terminal_callback_wall':callback_wall,'record_unchanged':True,'domain_unchanged':True,'observer_rows':rows,'actual_input_rows':inputs,'frame_checks':after['frame_checks'],'scope':'original ReplayButton/pause/speed/scrub/Home/resume; natural terminal; software WebGL, not frame budget acceptance'}
 (d.base/(level+'-whole-'+str(rate)+'x.json')).write_text(json.dumps(packet,indent=2)+'\n')
 d.capture(level+'_whole_'+str(rate)+'x_terminal')
 # UI-only scrub and original event lists are separate from whole accounting.
 d.key('ArrowLeft');assert not d.state()['replay']['playing']
 d.key('ArrowRight');assert not d.state()['replay']['playing']
 d.key('Space');assert d.state()['phase']==3
 post=d.rpc('fingerprints');post['state']=d.state();post['public_checkpoint']=d.page.evaluate("localStorage.getItem('ambush-loop.config.v1')")
 assert post['record_sha256']==before['record_sha256'] and post['domain']==before['domain']
 assert post['state']['settings']['configs']==before['state']['settings']['configs'] and post['public_checkpoint']==before['public_checkpoint']
 assert not post['record_validation']['failures']
 (d.base/(level+'-whole-'+str(rate)+'x-post-WON-full-fingerprint.json')).write_text(json.dumps(post,ensure_ascii=False,indent=2)+'\n')
 d.capture(level+'_whole_'+str(rate)+'x_returned_WON')
 packet['complete_helper_wall']=time.monotonic()-request_started
 packet['post_WON_record_domain_cfg_checkpoint_exact']=True
 (d.base/(level+'-whole-'+str(rate)+'x.json')).write_text(json.dumps(packet,indent=2)+'\n')
 emit('WHOLE_END',**{k:v for k,v in packet.items() if k not in ['observer_rows','actual_input_rows','frame_checks']})
 return packet

