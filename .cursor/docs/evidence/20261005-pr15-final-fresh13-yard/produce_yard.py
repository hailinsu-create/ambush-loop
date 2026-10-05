yard_record=d.mission(spec['missions'][0])
assert yard_record['reason']=='win' and not yard_record['validation']['failures']
emit('FIRST_PRODUCER_END',record=yard_record,whole_1x='UNRUN',whole_2x='UNRUN')
