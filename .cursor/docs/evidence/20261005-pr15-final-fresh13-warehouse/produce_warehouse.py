warehouse_record=d.mission(plan)
assert warehouse_record['reason']=='win' and not warehouse_record['validation']['failures']
emit('NEXT_PRODUCER_END',record=warehouse_record,whole='UNRUN')
