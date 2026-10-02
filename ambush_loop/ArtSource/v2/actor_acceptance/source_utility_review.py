"""Actual editable source pose board; three tools, clay/material/three views."""
import bpy,json,math,sys
from pathlib import Path
from mathutils import Vector,Matrix
args=sys.argv[sys.argv.index('--')+1:];out=Path(args[0]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(Path(args[1])))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
for obj in bpy.data.objects:obj.hide_render=True
cases=[];report=[]
for role,clip,tool,x,frame in [('operator_rifle','knife_stab','knife',-2.0,12),('operator_mg','grenade_throw','grenade',0.,15),('operator_scout','decoy_place','decoy',2.,18)]:
    collection=bpy.data.collections[role];rig=next(o for o in collection.objects if o.type=='ARMATURE')
    for obj in collection.objects:
        if obj.type=='MESH':
            assert not obj.data.validate(clean_customdata=False),obj.name
            obj.hide_render=obj.get('lod',0)>0
    rig.animation_data.action=bpy.data.actions[clip];rig.animation_data.action.use_fake_user=True
    # Independent pose frames via constant-time NLA strip evaluated at frame0.
    track=rig.animation_data.nla_tracks.new();strip=track.strips.new(clip,0,rig.animation_data.action)
    strip.use_animated_time=True;strip.strip_time=frame;rig.animation_data.action=None
    meshes=[o for o in bpy.data.collections[tool].objects if o.type=='MESH']
    obj=meshes[0];obj.hide_render=False
    markers={o.name.split('__socket_')[-1]:o for o in bpy.data.collections[tool].objects if '__socket_' in o.name}
    cases.append((rig,obj,markers['grip'].location.copy(),x));report.append({'role':role,'clip':clip,'frame':frame,'tool':tool,'mesh_validate_changed':False})
world=bpy.data.worlds.new('UtilityReviewWorld');world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.42,.46,.52,1);world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.world=world
bpy.ops.mesh.primitive_plane_add(size=40);floor=bpy.context.object
mat=bpy.data.materials.new('ReviewFloor');mat.diffuse_color=(.12,.15,.17,1);floor.data.materials.append(mat)
for loc,energy in [((4,4,7),950),((-4,-3,5),700)]:
    data=bpy.data.lights.new('UtilityStudio','AREA');data.energy=energy;data.size=5
    obj=bpy.data.objects.new('UtilityStudio',data);scene.collection.objects.link(obj);obj.location=loc;obj.rotation_euler=(Vector((0,0,.9))-obj.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('UtilitySourceCamera');camera=bpy.data.objects.new('UtilitySourceCamera',data);scene.collection.objects.link(camera);scene.camera=camera;data.type='ORTHO';data.ortho_scale=7.3
clay=bpy.data.materials.new('UtilityClay');clay.diffuse_color=(.55,.55,.55,1)
for shade in ['clay','material']:
    scene.view_layers[0].material_override=clay if shade=='clay' else None;scene.view_settings.exposure=-1.5 if shade=='clay' else 0
    for view,angle in [('front',0),('side',90),('rear',180)]:
        a=math.radians(angle);right=Vector((math.cos(a),-math.sin(a),0))
        for rig,obj,grip,x in cases:rig.location=right*x
        scene.frame_set(0);bpy.context.view_layer.update()
        for rig,obj,grip,x in cases:
            obj.matrix_world=rig.matrix_world@rig.pose.bones['hand.R'].matrix@Matrix.Translation((0,.035,0))@Matrix.Translation(-grip)
        bpy.context.view_layer.update()
        camera.location=(8*math.sin(a),8*math.cos(a),5.2);camera.rotation_euler=(Vector((0,0,.9))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(out/f'utility_source_{shade}_{view}.png');bpy.ops.render.render(write_still=True)
(out/'utility-source-report.json').write_text(json.dumps({'cases':report,'renders':6,'scope':'actual editable source poses/held tools; source material and clay; eight-sample CPU study'},indent=2)+'\n')
print('UTILITY_SOURCE_REVIEW_OK renders6',flush=True)
