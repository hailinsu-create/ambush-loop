from pathlib import Path
import json,sys
R=Path('/tmp/pr15-final-fresh13-1ec-20261005');level=sys.argv[1]
assert level in ['warehouse','pump','railcut','depot','radio']
text=(R/'audit_yard.py').read_text().replace('yard',level).replace("BASE/'run/",f"BASE/'{level}-run/")
text=text.replace("BASE/'run/engine-window-lifecycle.json'",f"BASE/'{level}-run/engine-window-lifecycle.json'")
(R/('audit_'+level+'.py')).write_text(text)
compile(text,str(R/('audit_'+level+'.py')),'exec')
print(json.dumps({'prepared':level,'runtime_started':False,'auditor':'same frozen record_audit.gd','scope':'after actual browser END only; new original artifact and fresh Guard UUID'}))
