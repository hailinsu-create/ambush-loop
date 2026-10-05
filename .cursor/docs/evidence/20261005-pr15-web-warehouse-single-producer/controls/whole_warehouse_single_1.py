assert len(context.pages)==1
exec(Path('/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/driver_core.progressive.py').read_text(),globals())
d.__class__=Driver
print(json.dumps({'owned_browser_page_count':len(context.pages),'urls':[p.url for p in context.pages]}),flush=True)
warehouse_whole_1=whole(d,warehouse_record,1)
