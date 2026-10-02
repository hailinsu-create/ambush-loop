#!/usr/bin/env python3
"""Blender source/pixel study from frozen exported geometry. Outputs to /tmp by default."""
import sys,math,json,argparse
from pathlib import Path
import bpy
from mathutils import Vector
H=Path(__file__).resolve().parent;P=H.parents[1];O=P/'art/environment_v2'
ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,default=Path('/tmp/environment-v2-blender'));args=ap.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []);T=args.output;T.mkdir(parents=True,exist_ok=True)
ex=json.loads((O/'exports.json').read_text());records={a['asset_id']:a for a in ex['assets']}
ids=['env_ammo_can','env_gun_case','env_handcart','env_jerry_can','env_rations_crate','env_spare_tire','env_wooden_barrel','env_yard_crate','env_warehouse_shell','env_warehouse_gantry','env_pump_skid','env_signal_mast','env_depot_tank_pair','env_radio_antenna']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.render.resolution_x=512;scene.render.resolution_y=320;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard';scene.world.color=(.20,.20,.20)
at=bpy.data.materials.new('EnvironmentReviewAtlas');at.use_nodes=True;bs=at.node_tree.nodes.get('Principled BSDF');nodes,links=at.node_tree.nodes,at.node_tree.links
for suffix,typ in [('albedo','base'),('normal','normal'),('orm','orm')]:
 im=bpy.data.images.load(str(O/'textures'/f'environment_v2_{suffix}.png'));im.colorspace_settings.name='sRGB' if typ=='base' else 'Non-Color';t=nodes.new('ShaderNodeTexImage');t.image=im
 if typ=='base':links.new(t.outputs['Color'],bs.inputs['Base Color'])
 elif typ=='normal':
  n=nodes.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=.45;links.new(t.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Normal'],bs.inputs['Normal'])
 else:
  n=nodes.new('ShaderNodeSeparateColor');links.new(t.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Green'],bs.inputs['Roughness']);links.new(n.outputs['Blue'],bs.inputs['Metallic'])
clay=bpy.data.materials.new('Clay');clay.diffuse_color=(.55,.56,.55,1);clay.use_nodes=True;clay.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.55,.56,.55,1);clay.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.9
for id in ids:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(O/'models'/f'{id}_lod0.glb'))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in meshes:
  for i,m in enumerate(o.data.materials):
   if not m or m.name.startswith('environment_v2_atlas'):o.data.materials[i]=at
 dims=records[id]['dimensions_m'];span=max(1.0,*dims)*1.55;focus=Vector((0,0,dims[1]/2))
 bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=span*1.6;scene.camera=cam
 bpy.ops.object.light_add(type='AREA',location=(-4,-5,8));light=bpy.context.object;light.data.energy=1100;light.data.size=7;light.rotation_euler=(Vector((0,0,.6))-light.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.light_add(type='AREA',location=(4,4,6));light=bpy.context.object;light.data.energy=800;light.data.size=6;light.rotation_euler=(focus-light.location).to_track_quat('-Z','Y').to_euler()
 for mode in ['shaded','clay']:
  if mode=='clay':
   for o in meshes:
    for i in range(len(o.data.materials)):o.data.materials[i]=clay
  for angle in [0,90,180]:
   a=math.radians(angle);cam.location=focus+Vector((math.sin(a)*15,-math.cos(a)*15,10));cam.rotation_euler=(focus-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(T/f'{id}_{mode}_{angle}.png');bpy.ops.render.render(write_still=True)
 print('BLENDER_STUDY',id,flush=True)
print('BLENDER_SOURCE_REVIEW_COMPLETE',flush=True)
