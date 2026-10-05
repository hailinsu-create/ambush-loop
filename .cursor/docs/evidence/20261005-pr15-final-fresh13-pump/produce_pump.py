try:
 pump_record=d.mission(plan)
except Exception:
 if d.state().get('phase')==2:
  failed_record=d.archive('pump-failed-attempt')
  seal_checkpoint(d,'pump_natural_FAILED',failed_record)
 raise
assert pump_record['reason']=='win' and not pump_record['validation']['failures']
emit('NEXT_PRODUCER_END',record=pump_record,whole='UNRUN')
