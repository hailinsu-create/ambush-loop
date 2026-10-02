"""Render actual editable LOD0 source, clay and material front/side/rear."""
from pathlib import Path
import sys,math,json,bpy
from mathutils import Vector
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)
blend=Path(sys.argv[sys.argv.index('--')+2]) if len(sys.argv)>sys.argv.index('--')+2 else root/'actors.blend'
bpy.ops.wm.open_mainfile(filepath=str(blend))
scene=bpy.context.scene; report=[]
for collection in bpy.data.collections:
 if collection.name.startswith(('operator_','enemy_')):
  meshes=[o for o in collection.objects if o.type=='MESH'];rig=[o for o in collection.objects if o.type=='ARMATURE'][0]
  assert len(rig.data.bones)==20
  for mesh in meshes:assert not mesh.data.validate(clean_customdata=False),mesh.name
  report.append({'asset':collection.name,'bones':len(rig.data.bones),'meshes':len(meshes),'mesh_validate_changed':False})
for o in bpy.data.objects:o.hide_render=True
for id,x in [('operator_rifle',-.85),('enemy_patrol',.85)]:
 collection=bpy.data.collections[id]
 for o in collection.objects:o.hide_render=o.type=='MESH' and o.get('lod',0)>0
 rig=next(o for o in collection.objects if o.type=='ARMATURE');rig.location.x=x
 rig.animation_data.action=bpy.data.actions['idle']
scene.frame_set(18);bpy.context.view_layer.update()
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
world=bpy.data.worlds.new('ReviewWorld');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.46,.52,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
bpy.ops.mesh.primitive_plane_add(size=40);ground=bpy.context.object
material=bpy.data.materials.new('Ground');material.diffuse_color=(.12,.15,.17,1);ground.data.materials.append(material)
for p,e,size in [((3,4,6),750,4),((-3,-4,4),550,5)]:
 data=bpy.data.lights.new('Studio','AREA');data.energy=e;data.shape='DISK';data.size=size
 o=bpy.data.objects.new('Studio',data);scene.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Review');cam=bpy.data.objects.new('Review',data);scene.collection.objects.link(cam);scene.camera=cam;data.type='ORTHO';data.ortho_scale=4.8
clay=bpy.data.materials.new('Clay');clay.diffuse_color=(.55,.55,.55,1)
for shade in ['clay','material']:
 scene.view_layers[0].material_override=clay if shade=='clay' else None
 for label,angle in [('front',0),('side',90),('rear',180)]:
  a=math.radians(angle);cam.location=(7*math.sin(a),7*math.cos(a),3.7);cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler()
  scene.render.filepath=str(out/f'source_{shade}_{label}.png');bpy.ops.render.render(write_still=True)
(out/'source-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('ACTOR_SOURCE_REVIEW_OK characters',len(report),'renders',6,flush=True)
