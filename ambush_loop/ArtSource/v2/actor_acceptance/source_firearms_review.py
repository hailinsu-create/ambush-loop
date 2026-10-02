"""Render the actual editable ten-gun source from three angles, clay/material."""
from pathlib import Path
import sys, math, json, bpy
from mathutils import Vector
here=Path(__file__).resolve().parent
sys.path.insert(0,str(here))
from firearm_contract import FAMILIES
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=args[1])
scene=bpy.context.scene
for obj in bpy.data.objects:obj.hide_render=True
meshes=[];report=[]
for gun in FAMILIES:
    mesh=next(o for o in bpy.data.collections[gun].objects if o.type=='MESH')
    assert not mesh.data.validate(clean_customdata=False),gun
    mesh.data.calc_loop_triangles();mesh.hide_render=False
    centre=sum((Vector(p) for p in mesh.bound_box),Vector())/8
    meshes.append((mesh,centre))
    report.append({'weapon':gun,'triangles':len(mesh.data.loop_triangles),'mesh_validate_changed':False})
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
world=bpy.data.worlds.new('FirearmReview');world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.46,.52,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
for position,energy,size in [((3,4,6),750,4),((-3,-4,4),550,5)]:
    data=bpy.data.lights.new('Studio','AREA');data.energy=energy;data.shape='DISK';data.size=size
    light=bpy.data.objects.new('Studio',data);scene.collection.objects.link(light);light.location=position
    light.rotation_euler=(Vector((0,0,.2))-light.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Camera');camera=bpy.data.objects.new('Camera',data);scene.collection.objects.link(camera);scene.camera=camera;data.type='ORTHO';data.ortho_scale=4.7
clay=bpy.data.materials.new('Clay');clay.diffuse_color=(.55,.55,.55,1)
for shade in ['clay','material']:
    scene.view_layers[0].material_override=clay if shade=='clay' else None
    scene.view_settings.exposure=-1.5 if shade=='clay' else 0
    for name,degrees in [('front',0),('side',90),('rear',180)]:
        angle=math.radians(degrees);screen_right=Vector((math.cos(angle),-math.sin(angle),0))
        for index,(mesh,centre) in enumerate(meshes):
            column=index//2;row=index%2
            mesh.location=screen_right*((column-2)*1.5)+Vector((0,0,.7-row*.9))-centre
        camera.location=Vector((7*math.sin(angle),7*math.cos(angle),2.2))
        camera.rotation_euler=(Vector((0,0,.2))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(out/f'guns_{shade}_{name}.png');bpy.ops.render.render(write_still=True)
(out/'source-firearms-report.json').write_text(json.dumps({'weapons':report,'renders':6,'columns':'pistol/rifle/smg/mg/scout; allied upper / axis lower','scope':'actual editable LOD0 sources; eight-sample CPU clay/material study'},indent=2)+'\n')
print('FIREARM_SOURCE_REVIEW_OK weapons',len(report),'renders',6,flush=True)
