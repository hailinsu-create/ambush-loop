"""Curate traceable screenshots/reports and sampled clip videos from the fixture."""
from pathlib import Path
import json,hashlib,subprocess,sys,shutil
from PIL import Image,ImageDraw,ImageFont
root=Path(sys.argv[1]);dest=Path(sys.argv[2]);dest.mkdir(parents=True,exist_ok=True)
engine=root/'evidence/final-engine';font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)

def sheet(name,files,columns=3):
 w,h=480,298;canvas=Image.new('RGB',(w*columns,h*((len(files)+columns-1)//columns)),(24,30,38));draw=ImageDraw.Draw(canvas)
 for i,p in enumerate(files):
  im=Image.open(p).convert('RGB');im.thumbnail((w,270));x=(i%columns)*w;y=(i//columns)*h;canvas.paste(im,(x,y));draw.text((x+5,y+273),p.stem,fill='white',font=font)
 canvas.save(dest/name)
clips=['idle','walk','run','aim','fire','pickup','death','crouch','crouch_walk','deploy','hit','haul']
sheet('priority-lods.png',[engine/f'priority_lod{l}_yaw{a:03}.png' for a in [0,90,180,270] for l in range(3)])
sheet('all-actions-lod0.png',[engine/f'all_{c}_lod0.png' for c in clips])
sheet('temporal-poses.png',[engine/f'pose_{c}_{s:02}.png' for c in ['walk','fire','pickup','death'] for s in [0,6,12,18,24]],5)
sheet('equipment-360.png',[engine/f'equipment_lod{l}_yaw{a:03}.png' for l in range(2) for a in [0,90,180,270]],4)
sheet('dusk-360.png',[engine/f'dusk_yaw{a:03}.png' for a in range(0,360,45)],4)
for name in ['priority_lod0_yaw270.png','pose_pickup_12.png','pose_death_24.png','reference_16_actor_load.png','characters_lod0_yaw180.png','characters_far_lod2.png']:
 shutil.copy2(engine/name,dest/name)
for p in (root/'evidence/final-source').glob('*.png'):shutil.copy2(p,dest/p.name)
for p in [root/'evidence/final-binary.json',engine/'engine-report.json',root/'evidence/final-source/source-report.json',root/'evidence/protected-paths.json',root/'evidence/rebuild.json']:
 shutil.copy2(p,dest/p.name)
for name in ['repaired-export.log','rebuild-second.log','final-binary.log','final-binary.exit','final-project-import.log','final-project-import.exit','final-engine.log','final-engine.exit','final-source.log','final-source.exit']:
 shutil.copy2(root/'evidence'/name,dest/name)
shutil.copy2(engine/'fixture-import.log',dest/'fixture-import.log')
record={'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'raw_capture_count':len(list(engine.glob('*.png'))),'raw_captures':[],'curated':[]}
for p in sorted(engine.glob('*.png')):record['raw_captures'].append({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
project=Path(__file__).resolve().parents[3];manifest=json.loads((project/'art/v2/actors_manifest.json').read_text());videos=dest/'clips';videos.mkdir(exist_ok=True)
for c in manifest['assets'][0]['animations']:
 out=videos/(c['name']+'.mp4')
 subprocess.run(['ffmpeg','-loglevel','error','-y','-framerate',str(24/c['duration']),'-i',str(engine/f"pose_{c['name']}_%02d.png"),'-vf','fps=30','-c:v','libx264','-preset','veryfast','-crf','20','-pix_fmt','yuv420p',str(out)],check=True)
for p in sorted(dest.rglob('*')):
 if p.is_file() and p.name!='capture-index.json':record['curated'].append({'file':p.relative_to(dest).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
(dest/'capture-index.json').write_text(json.dumps(record,indent=2)+'\n')
print('ACTOR_EVIDENCE_PACKED',record['raw_capture_count'],'raw',len(record['curated']),'curated')
