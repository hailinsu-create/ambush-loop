from pathlib import Path
import json
r=Path('/tmp/pr15-replay-first-draw-20261005')
j=json.loads((r/'analysis.json').read_text())
bad=[{'label':x['label'],'differences':x['differences']} for x in j['rows'] if x['full_difference_count']]
print(json.dumps({'strict_complete_AB_equal':not bad,'failed_rows':len(bad),'differences':sum(len(x['differences']) for x in bad),'UI_different_nodes':sum(len(x['UI_different_nodes']) for x in j['rows']),'scope':'all captured fields; no exclusions; generated scope/domain hash differences retained'}))
raise SystemExit(1 if bad else 0)
