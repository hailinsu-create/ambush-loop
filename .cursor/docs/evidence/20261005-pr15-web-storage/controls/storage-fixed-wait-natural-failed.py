page.wait_for_timeout(15000);page.screenshot(path=str(base/'fixed-yard-natural-terminal.png'))
print(json.dumps({'natural_elapsed_wait_s':15,'no_manual_tick_or_outcome':True,'console_errors':[x for x in console if x['type']=='error'],'page_errors':errors[:]}),flush=True)
