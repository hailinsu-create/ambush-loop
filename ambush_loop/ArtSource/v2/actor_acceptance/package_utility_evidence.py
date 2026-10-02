"""Package actual captured PNGs into sparse-sample review videos; no AI frames."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path

CLIPS={'knife_stab':.8,'grenade_throw':1.,'decoy_place':1.2,'corpse_grab':1.,'corpse_drag':1.2,'corpse_release':.7,'death_prone':1.2}

def package(source,output,raw_source):
    output.mkdir(parents=True,exist_ok=True);videos=[]
    for name,duration in CLIPS.items():
        for lod in [0,2]:
            frames=[source/f'{name}_lod{lod}_{i:02d}.png' for i in range(9)]
            assert all(p.exists() for p in frames),frames
            concat=output/f'{name}-lod{lod}.ffconcat'
            lines=['ffconcat version 1.0']
            for i,p in enumerate(frames):
                assert "'" not in str(p)
                lines.extend(["file '"+str(p.resolve())+"'",f'duration {duration/8 if i<8 else 1/30:.9f}'])
            concat.write_text('\n'.join(lines)+'\n');target=output/f'{name}-lod{lod}.mp4'
            subprocess.run(['ffmpeg','-y','-loglevel','error','-f','concat','-safe','0','-i',str(concat),'-vf','fps=30','-c:v','libx264','-threads','2','-crf','22','-pix_fmt','yuv420p','-movflags','+faststart',str(target)],check=True)
            concat.unlink()
            metadata=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height,nb_frames,duration','-of','json',str(target)]))
            videos.append({'file':target.name,'clip':name,'lod':lod,'authored_duration_s':duration,'capture_phases':[i/8 for i in range(9)],'encoding':metadata['streams'][0],'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
                'scope':'25-phase real AnimationPlayer review, nine actual captures held at sparse intervals; final frame30fps hold; no interpolated frames, flight or combat claim'})
    for p in source.glob('*contact_close.png'):shutil.copy2(p,output/p.name)
    for p in source.glob('*ground_side*.png'):shutil.copy2(p,output/p.name)
    for name in ['knife_stab_lod0_04','grenade_throw_lod0_04','decoy_place_lod0_04','corpse_grab_lod0_00','corpse_grab_lod0_08','corpse_release_lod0_08','death_prone_lod0_08']:
        shutil.copy2(source/(name+'.png'),output/(name+'.png'))
    for p in source.glob('pair_*_yaw*.png'):shutil.copy2(p,output/p.name)
    (output/'videos.json').write_text(json.dumps(videos,indent=2)+'\n')
    captures=[]
    for folder in [source,raw_source]:
        for p in sorted(folder.glob('*.png')):captures.append({'path':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
    (output/'capture-index.json').write_text(json.dumps(captures,indent=2)+'\n')
    print('UTILITY_VIDEO_PACKAGE videos',len(videos),'raw_capture_index',len(captures))

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--regression-captures',type=Path,required=True);a=ap.parse_args()
    package(a.source,a.output,a.regression_captures)
