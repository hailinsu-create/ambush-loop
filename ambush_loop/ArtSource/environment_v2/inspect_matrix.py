#!/usr/bin/env python3
"""Compact true framebuffer pages for manual eight-direction near/far pixel review."""
import argparse,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
H=Path(__file__).resolve().parent;P=H.parents[1];E=P/'art/environment_v2/evidence'
a=argparse.ArgumentParser();a.add_argument('frames',type=Path);args=a.parse_args();F=args.frames
cat=json.loads((H/'catalog_candidate.json').read_text());ids=[r['asset_id'] for r in cat['new_assets']+cat['reuse_assets']];font=ImageFont.load_default(size=14)
for lod,mode in [(0,'neutral'),(1,'dusk')]:
 for page in range((len(ids)+3)//4):
  subset=ids[page*4:page*4+4];out=Image.new('RGB',(1760,4*190),'#263039');d=ImageDraw.Draw(out)
  for row,id in enumerate(subset):
   for col,yaw in enumerate(range(0,360,45)):
    pitch=35 if col%2==0 else 65;p=F/f'asset_{id}_l{lod}_{mode}_p{pitch}_y{yaw}.png'
    im=Image.open(p).convert('RGB').crop((220,80,1060,720));im.thumbnail((220,165));out.paste(im,(col*220,row*190))
   d.text((8,row*190+166),f'{id} / LOD{lod} {mode} / yaw0,45,90,135,180,225,270,315 / pitch alternates35,65',font=font,fill='#e5e6df')
  out.save(E/f'pixel_matrix_lod{lod}_{page+1:02}.png')
print('PIXEL_MATRIX_PAGES',22)
