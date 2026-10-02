#!/usr/bin/env python3
"""Curate actual rendered pixels; never synthesize substitute scene screenshots."""
import argparse,json,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
H=Path(__file__).resolve().parent;P=H.parents[1];O=P/'art/environment_v2';E=O/'evidence'
a=argparse.ArgumentParser();a.add_argument('frames',type=Path);a.add_argument('--blender',type=Path,default=Path('/tmp/environment-v2-blender'));args=a.parse_args();F=args.frames;E.mkdir(exist_ok=True)
cat=json.loads((H/'catalog_candidate.json').read_text())
font=ImageFont.load_default(size=14)
def tile(path,size,label):
 im=Image.open(path).convert('RGB');im.thumbnail((size[0],size[1]-26));box=Image.new('RGB',size,'#263039');box.paste(im,((size[0]-im.width)//2,0));ImageDraw.Draw(box).text((7,size[1]-23),label,font=font,fill='#e3e5de');return box
def board(name,items,cols,size=(400,250)):
 out=Image.new('RGB',(cols*size[0],((len(items)+cols-1)//cols)*size[1]),'#263039')
 for i,(path,label) in enumerate(items):out.paste(tile(path,size,label),((i%cols)*size[0],(i//cols)*size[1]))
 out.save(E/name)
props=[r for r in cat['original_14_mapping'] if r['mode']=='new_environment_candidate']
board('props_gaps.png',[(F/f'asset_{r["asset_id"]}_l0_neutral_p35_y180.png',r['original_class']) for r in props],5,(320,220))
board('props_reused.png',[(F/f'asset_{r["asset_id"]}_l0_dusk_p35_y180.png',r['original_class']+' (baseline bytes)') for r in cat['original_14_mapping'] if r['mode']=='reuse_baseline_bytes'],4,(400,250))
modules=[r for r in cat['new_assets'] if r['category'] in ('building','ground')]
board('modules.png',[(F/f'asset_{r["asset_id"]}_l0_neutral_p65_y135.png',r['asset_id'].removeprefix('env_')) for r in modules],5,(320,220))
landmarks=[r for r in cat['new_assets'] if r['category']=='landmark']+[next(r for r in cat['new_assets'] if r['asset_id']=='env_warehouse_shell')]
board('landmarks_front_rear.png',[(F/f'asset_{r["asset_id"]}_l0_neutral_p35_y{yaw}.png',r['asset_id']+' yaw'+str(yaw)) for r in landmarks for yaw in (180,0)],4,(400,250))
board('themes_dusk.png',[(F/f'theme_{k}_l0_dusk_p35_y{0 if k=="yard" else 180}.png',k.upper()+' / exhibition candidate') for k in cat['themes']],2,(640,385))
board('themes_neutral.png',[(F/f'theme_{k}_l0_neutral_p65_y135.png',k.upper()+' / exhibition candidate') for k in cat['themes']],2,(640,385))
board('yard_360.png',[(F/f'theme_yard_l0_{mode}_p{pitch}_y{yaw}.png',f'yard {mode} yaw{yaw} pitch{pitch}') for mode,pitch in [('neutral',35),('dusk',65)] for yaw in range(0,360,45)],4,(400,250))
board('yard_far_lod1.png',[(F/f'theme_yard_l1_dusk_p{pitch}_y{yaw}.png',f'yard LOD1 far pitch{pitch} yaw{yaw}') for pitch in (35,65) for yaw in (0,90,180,270)],4,(400,250))
board('themes_roof_removed.png',[(F/f'theme_{k}_roof_removed.png',k.upper()+' / roof removed') for k in cat['themes']],2,(640,385))
board('motion_keyframes.png',[(F/f'motion_{i:03}.png',f'actual Godot motion frame {i}') for i in (0,45,90,135)],2,(640,385))
shutil.copy2(F/'phone_yard_800x450.png',E/'phone_yard_800x450.png');shutil.copy2(F/'godot_report.json',E/'godot_report.json')
for k in cat['themes']:shutil.copy2(F/f'theme_{k}_l0_dusk_p35_y{0 if k=="yard" else 180}.png',E/f'{k}_dusk.png')
blenders=list(args.blender.glob('*_clay_*.png'))
if blenders:
 ids=['env_ammo_can','env_yard_crate','env_warehouse_shell','env_pump_skid','env_depot_tank_pair','env_radio_antenna']
 board('blender_source_review.png',[(args.blender/f'{id}_{m}_{y}.png',id+' '+m+' '+str(y)) for id in ids for m,y in [('shaded',0),('shaded',90),('shaded',180),('clay',180)]],4,(320,220))
# Full frame ledger is small and makes every inspected camera configuration reproducible.
ledger=[{'path':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'dimensions':list(Image.open(p).size)} for p in sorted(F.glob('*.png'))]
(E/'frame_ledger.json').write_text(json.dumps({'frames':ledger,'count':len(ledger),'origin':'actual Godot framebuffer, no painted substitute','retention':'full frames in cloud /tmp, reproducible via sample; curated PNGs committed'},indent=2)+'\n')
print('CURATED',len(list(E.glob('*.png'))),'boards/frames','FULL_FRAME_COUNT',len(ledger),'PHONE_SIZE',Image.open(E/'phone_yard_800x450.png').size)
