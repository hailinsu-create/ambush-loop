exec(Path('/tmp/pr15-web-controls/fresh-native-dab-20261005/driver_core.py').read_text(),globals())
d.__class__=Driver
d.last_state=d.rpc('state')
yard_record=d.mission(spec['missions'][0])
