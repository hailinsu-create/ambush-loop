helper=ROOT/'whole_helper.py'
loaded=helper.read_bytes();assert hashlib.sha256(loaded).hexdigest()=='e093a1ba6cf30d5b0989b1588d600750feb8d25073d003e51fc6ee62f1d681e0'
with (BASE/'loaded-controls'/'yard-whole-1x-helper.py').open('xb') as f:f.write(loaded)
exec(compile(loaded,str(helper),'exec'),globals())
assert len(context.pages)==1 and page.url==URL
whole(d,record,1)
