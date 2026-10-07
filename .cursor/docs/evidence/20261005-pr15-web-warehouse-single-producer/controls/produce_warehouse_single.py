assert len(context.pages)==1
exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_core.progressive.py').read_text(),globals());d.__class__=Driver
latencies=[]
for _ in range(10):
 start=time.monotonic();s=d.state();latencies.append(time.monotonic()-start)
 assert s['phase']==0 and s['attempt']=='1289c65c34af63cf62707bf18ddc4cca' and 'input_tail' in s
(BASE/'single-direct-reply-control.json').write_text(json.dumps({'latency_wall_s':latencies,'same_attempt':s['attempt'],'single_page':len(context.pages)==1,'scope':'controller immediate-reply read cost only; no game tick/process'},indent=2)+'\n')
print(json.dumps({'SINGLE_DIRECT_REPLY_CONTROL':latencies,'loaded_sync_bridge_input_marker_present':True}),flush=True)
warehouse_record=d.mission(spec['missions'][1])
