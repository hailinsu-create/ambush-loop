#!/usr/bin/env python3
"""Original skinned military characters, in-place clips and the ten-gun kit.
Blender 4.3.2: blender -b --python ArtSource/v2/build_actors.py
Authoring metres, +Z up/+Y forward; runtime +Y up/-Z forward.
No root motion, downloaded meshes, markings or external services.
"""
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_yard_kit as kit
from actor_acceptance.canonicalize import normalize_glb
PROJECT = HERE.parents[1]
OUT = PROJECT / 'art/v2'
PARTS = []
MAT = None
SEED = 194407
CLIPS = {'idle': (2.4, True), 'walk': (.9, True), 'run': (.6, True),
         'aim': (1.8, True), 'fire': (.24, False), 'pickup': (1.0, False),
         'death': (1.2, False), 'crouch': (2., True), 'crouch_walk': (1.15, True),
         'deploy': (1.25, False), 'hit': (.3, False), 'haul': (1.2, True)}
CHARACTERS = {'operator_rifle': (0, 'helmet'), 'operator_mg': (1, 'rolled'),
              'operator_scout': (6, 'beret'), 'enemy_patrol': (13, 'helmet'),
              'enemy_flank': (2, 'cap'), 'enemy_sneak': (6, 'hood'),
              'enemy_radio': (13, 'radio')}
GUNS = {'m1911': (.22, 'pistol'), 'luger': (.25, 'pistol'),
        'm1_garand': (1.10, 'rifle'), 'kar98k': (1.11, 'rifle'),
        'thompson': (.82, 'smg'), 'mp40': (.83, 'smg'),
        'bar': (1.20, 'mg'), 'mg42': (1.22, 'mg'),
        'springfield': (1.12, 'scout'), 'kar98k_zf': (1.11, 'scout')}
LOD_BUDGET = {'character': (8000, 4000, 1800), 'weapon': (3000, 1500), 'tool': (2000, 1000)}


def atlas():
    global MAT
    rng = np.random.default_rng(SEED)
    n = 256
    yy, xx = np.mgrid[0:n, 0:n] / n
    rgb = np.zeros((1024, 1024, 3), np.float32)
    orm = np.zeros_like(rgb); normal = np.zeros_like(rgb)
    palette = [(.26,.30,.19), (.47,.42,.29), (.16,.19,.18), (.22,.24,.25),
               (.18,.11,.064), (.59,.40,.27), (.26,.30,.18), (.055,.057,.052),
               (.50,.38,.15), (.49,.46,.34), (.72,.67,.52), (.047,.035,.028),
               (.39,.12,.085), (.28,.32,.30), (.31,.17,.078), (.20,.27,.26)]
    for tile, base in enumerate(palette):
        noise = rng.random((n,n)).astype(np.float32)-.5
        broad = np.sin(xx*24+np.cos(yy*17))*.5+np.sin(yy*39+xx*12)*.23
        weave = np.sin(xx*math.tau*90)*np.sin(yy*math.tau*90)
        shade = noise*.09 + broad*.05
        height = noise*.01
        rough = np.full((n,n), .84, np.float32); metal = np.zeros_like(rough)
        if tile in (0,1,2,6,9,12,13):
            height += weave*.025; shade += weave*.04
        if tile == 6:
            patches = np.sin(xx*17+np.sin(yy*21)*2)+np.cos(yy*12-xx*7)
            shade += np.where(patches>.7,.27,np.where(patches<-.6,-.27,0))
        if tile == 5:
            shade += .055*np.sin(yy*7); rough[:]=.78
        if tile in (3,8):
            metal[:]=.78; rough[:]=.49+noise*.06
        if tile == 14:
            shade+=np.sin(xx*230+np.sin(yy*12)*5)*.09; height+=np.sin(xx*230)*.014
        if tile == 15: metal[:]=.3; rough[:]=.23
        pixels=np.clip(np.array(base)[None,None,:]*(1+shade[:,:,None]),.01,.95)
        dy,dx=np.gradient(height)
        vectors=np.stack((-dx*7,-dy*7,np.ones_like(height)),axis=2)
        vectors/=np.linalg.norm(vectors,axis=2)[:,:,None]
        row,col=divmod(tile,4); area=np.s_[row*n:(row+1)*n,col*n:(col+1)*n]
        idx=np.clip(np.arange(n),4,n-5)
        rgb[area]=pixels[idx[:,None],idx[None,:]]
        normal[area]=(vectors*.5+.5)[idx[:,None],idx[None,:]]
        orm[area]=np.stack((np.ones_like(rough),rough,metal),axis=2)[idx[:,None],idx[None,:]]
    images=[kit.image('actor_atlas_'+name,values,space) for name,values,space in
            [('albedo',rgb,'sRGB'),('normal',normal,'Non-Color'),('orm',orm,'Non-Color')]]
    MAT=bpy.data.materials.new('v2_actor_atlas'); MAT.use_nodes=True
    nodes,links=MAT.node_tree.nodes,MAT.node_tree.links
    shader=nodes.get('Principled BSDF')
    for img in images:
        tex=nodes.new('ShaderNodeTexImage'); tex.image=img
        if img.name.endswith('normal'):
            convert=nodes.new('ShaderNodeNormalMap'); convert.inputs['Strength'].default_value=.4
            links.new(tex.outputs['Color'],convert.inputs['Color']); links.new(convert.outputs['Normal'],shader.inputs['Normal'])
        elif img.name.endswith('orm'):
            split=nodes.new('ShaderNodeSeparateColor'); links.new(tex.outputs['Color'],split.inputs['Color'])
            links.new(split.outputs['Green'],shader.inputs['Roughness']); links.new(split.outputs['Blue'],shader.inputs['Metallic'])
        else: links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    kit.ATLAS=MAT


def finish(obj,name,tile,bone=None,bevel=0):
    obj=kit.finish(obj,name,tile,bevel)
    # kit owns UV and material normalization; this module owns rig membership.
    if bone:
        group=obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))),1.,'REPLACE')
    PARTS.append(obj)
    return obj


def box(name,size,at,tile,bone=None,bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at)
    obj=bpy.context.object; obj.dimensions=size
    return finish(obj,name,tile,bone,bevel)


def ellipsoid(name,size,at,tile,bone=None,segments=16,rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=at)
    obj=bpy.context.object; obj.scale=size
    for poly in obj.data.polygons: poly.use_smooth=True
    return finish(obj,name,tile,bone)


def tube(name,a,b,r0,r1,tile,bone=None,sides=12,rings=7,fold=.006):
    a,b=Vector(a),Vector(b); direction=(b-a).normalized()
    x=direction.cross(Vector((0,1,0)))
    if x.length<.1: x=direction.cross(Vector((1,0,0)))
    x.normalize(); y=direction.cross(x).normalized()
    verts=[]; faces=[]
    for j in range(rings+1):
        t=j/rings; radius=r0*(1-t)+r1*t
        for i in range(sides):
            theta=math.tau*i/sides
            wrinkle=fold*math.sin(t*math.pi)*math.sin(t*28+theta*3)
            verts.append(a.lerp(b,t)+(x*math.cos(theta)+y*math.sin(theta))*(radius+wrinkle))
    for j in range(rings):
        for i in range(sides):
            p=j*sides+i; q=j*sides+(i+1)%sides
            faces.append((p,q,q+sides,p+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range(rings*sides,(rings+1)*sides))])
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for face in mesh.polygons:
        for loop in face.loop_indices:
            index=mesh.loops[loop].vertex_index
            row,col=divmod(index,sides)
            if len(face.vertices)==4:
                # Unwrap the tube seam explicitly; UV smart-project packing
                # has nondeterministic ties on these repeated symmetric parts.
                seam=min(v%sides for v in face.vertices)==0 and max(v%sides for v in face.vertices)==sides-1
                uv.data[loop].uv=((1 if seam and col==0 else col/sides),row/rings)
            else:
                theta=math.tau*col/sides
                uv.data[loop].uv=(.5+.48*math.cos(theta),.5+.48*math.sin(theta))
    obj=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    for poly in mesh.polygons: poly.use_smooth=len(poly.vertices)==4
    return finish(obj,name,tile,bone)


def skeleton():
    joints={'root': ((0,0,0),(0,0,.2),None),
      'pelvis': ((0,0,.93),(0,0,1.08),'root'),
      'spine': ((0,0,1.08),(0,0,1.30),'pelvis'),
      'chest': ((0,0,1.30),(0,0,1.48),'spine'),
      'neck': ((0,0,1.48),(0,0,1.56),'chest'),
      'head': ((0,0,1.56),(0,0,1.79),'neck')}
    for suffix,side in [('L',-1),('R',1)]:
        s=lambda x: side*x
        joints.update({
          'clavicle.'+suffix: ((0,0,1.43),(s(.205),0,1.43),'chest'),
          'upper_arm.'+suffix: ((s(.205),0,1.43),(s(.27),.065,1.14),'clavicle.'+suffix),
          'forearm.'+suffix: ((s(.27),.065,1.14),(s(.15),.32,1.20),'upper_arm.'+suffix),
          'hand.'+suffix: ((s(.15),.32,1.20),(s(.15),.41,1.20),'forearm.'+suffix),
          'thigh.'+suffix: ((s(.105),0,.95),(s(.13),.025,.52),'pelvis'),
          'shin.'+suffix: ((s(.13),.025,.52),(s(.135),0,.14),'thigh.'+suffix),
          'foot.'+suffix: ((s(.135),0,.14),(s(.135),.18,.08),'shin.'+suffix)})
    arm=bpy.data.armatures.new('SharedHumanoid'); rig=bpy.data.objects.new('Rig',arm)
    bpy.context.collection.objects.link(rig); bpy.context.view_layer.objects.active=rig
    rig.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
    for name,(head,tail,parent) in joints.items():
        bone=arm.edit_bones.new(name); bone.head=head; bone.tail=tail
        if parent: bone.parent=arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT'); rig.show_in_front=True
    return rig,joints


def character(asset,cloth,style):
    kit.CURRENT=asset
    # Slightly tapered, folded jacket, with overlapping panels at the waist.
    ellipsoid('trousers_seat',(.19,.125,.20),(0,-.007,.98),cloth,'pelvis')
    ellipsoid('jacket_lower',(.205,.139,.21),(0,.0,1.15),cloth,'spine')
    ellipsoid('jacket_chest',(.22,.137,.205),(0,.002,1.34),cloth,'chest',20,12)
    tube('neck',(0,0,1.47),(0,0,1.60),.061,.06,5,'neck',12,3,0)
    ellipsoid('head',(.095,.096,.135),(0,.014,1.674),5,'head',20,12)
    ellipsoid('jaw',(.073,.085,.068),(0,.04,1.605),5,'head')
    ellipsoid('nose',(.022,.035,.028),(0,.108,1.665),5,'head',10,6)
    for side in (-1,1):
        ellipsoid('ear',(.018,.025,.037),(side*.095,.01,1.67),5,'head',10,6)
        box('brow',(.035,.009,.010),(side*.038,.104,1.711),4,'head',.003)
        ellipsoid('eye',(.012,.006,.006),(side*.037,.110,1.699),11,'head',8,4)
    box('mouth',(.036,.006,.004),(0,.123,1.624),4,'head',.001)
    # Headgear gives distinguishable silhouettes from every side.
    if style in ('helmet','heavy','radio','rolled'):
        ellipsoid('helmet_shell',(.118,.124,.073),(0,.007,1.771),3 if cloth==13 else 0,'head',20,10)
        ellipsoid('helmet_rim',(.133,.144,.017),(0,.016,1.748),3 if cloth==13 else 0,'head',20,6)
        for side in (-1,1):
            tube('chin_strap',(side*.093,.01,1.74),(side*.043,.075,1.588),.008,.008,4,'head',6,1,0)
        if style=='rolled':
            box('helmet_band',(.185,.013,.022),(0,.134,1.754),9,'head',.003)
    elif style=='hood':
        bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,
                                           location=(0,-.012,1.705))
        hood=bpy.context.object
        bm=bmesh.new(); bm.from_mesh(hood.data)
        # Genuine face aperture, rather than an opaque cap over the face.
        opening=[f for f in bm.faces if f.calc_center_median().y>.48 and f.calc_center_median().z<.72]
        bmesh.ops.delete(bm,geom=opening,context='FACES')
        bm.to_mesh(hood.data); bm.free()
        hood.scale=(.128,.135,.161); finish(hood,'hood',cloth,'head')
        for side in (-1,1): tube('hood_edge',(side*.099,.080,1.62),(side*.094,.086,1.78),.011,.012,cloth,'head',8,2,0)
        ellipsoid('smock_back',(.236,.111,.24),(0,-.086,1.305),cloth,'chest',20,12)
    elif style=='beret':
        ellipsoid('soft_beret',(.124,.12,.053),(-.02,0,1.785),2,'head',20,8)
        box('unit_tab',(.025,.006,.027),(.05,.107,1.775),10,'head',.002)
    else:
        ellipsoid('field_cap',(.108,.109,.05),(0,.007,1.774),cloth,'head')
        box('cap_peak',(.16,.086,.008),(0,.103,1.754),cloth,'head',.01)
    # Collar, webbing, pouches and belt are geometry, not painted shadow.
    for side in (-1,1):
        collar=box('collar',(.066,.035,.065),(side*.053,.121,1.473),cloth,'chest',.008)
        collar.rotation_euler.y=side*.35
        tube('suspender',(side*.12,.113,1.46),(side*.105,.148,1.11),.015,.016,9,'chest',6,3,0)
        box('breast_pocket',(.078,.032,.090),(side*.11,.133,1.335),cloth,'chest',.012)
        box('pocket_flap',(.084,.035,.021),(side*.11,.152,1.373),cloth,'chest',.004)
        box('ammo_pouch',(.098,.065,.095),(side*.145,.137,1.061),4 if style!='rolled' else 9,'pelvis',.012)
        box('cargo_pocket',(.046,.115,.105),(side*.196,.02,.788),cloth,'thigh.'+('R' if side>0 else 'L'),.014)
    tube('jacket_placket',(0,.143,1.12),(0,.139,1.44),.012,.012,cloth,'spine',6,1,0)
    for z in (1.19,1.27,1.35,1.42): ellipsoid('button',(.005,.004,.005),(0,.153,z),8,'chest',8,4)
    ellipsoid('belt',(.207,.146,.025),(0,0,1.041),4,'pelvis',20,6)
    box('buckle',(.043,.013,.033),(0,.15,1.041),8,'pelvis',.003)
    box('pack',(.255,.135,.27),(0,-.159,1.282),9,'chest',.025)
    for x in (-.078,.078): box('pack_strap',(.022,.014,.25),(x,-.235,1.282),4,'chest',.004)
    ellipsoid('canteen',(.065,.057,.093),(.205,-.068,1.012),3,'pelvis')
    if style in ('heavy','rolled'):
        for i in range(10): tube('cartridge',(-.13+i*.028,.16,1.29),(-.13+i*.028,.16,1.35),.010,.008,8,'chest',6,1,0)
    if style=='radio':
        box('radio_pack',(.29,.14,.37),(0,-.18,1.32),2,'chest',.013)
        tube('radio_aerial',(.105,-.22,1.49),(.105,-.22,2.15),.005,.003,3,'chest',6,1,0)
    # Anatomy and clothing follow the exact bind skeleton.
    _,joints=skeleton(); rig=bpy.context.object
    for suffix in ('L','R'):
        for bone,r0,r1,tile in [('upper_arm',.083,.061,cloth),('forearm',.061,.043,cloth),('thigh',.110,.083,cloth),('shin',.078,.053,cloth)]:
            name=bone+'.'+suffix; a,b,_=joints[name]
            tube(bone,a,b,r0,r1,tile,name,14,9)
            # Filled joints prevent visible gaps while the garment bends.
            ellipsoid(bone+'_joint',(r0*.92,r0*.92,r0*.92),a,tile,name,12,8)
        hx,hy,hz=joints['hand.'+suffix][0]
        ellipsoid('glove',(.042,.062,.039),(hx,hy+.032,hz),4,'hand.'+suffix,12,8)
        # Individual curled fingers and opposed thumb remain attached to hand.
        for finger in range(4):
            ellipsoid('finger',(.009,.028,.012),(hx-.029+finger*.019,hy+.073,hz-.012),4,'hand.'+suffix,8,6)
        ellipsoid('thumb',(.014,.032,.017),(hx+(-.035 if suffix=='R' else .035),hy+.025,hz+.009),4,'hand.'+suffix,8,6)
        x=joints['foot.'+suffix][0][0]
        box('boot_sole',(.125,.273,.027),(x,.067,.0135),7,'foot.'+suffix,.010)
        ellipsoid('boot_toe',(.063,.13,.055),(x,.081,.075),4,'foot.'+suffix,16,8)
        tube('boot_shaft',(x,-.02,.08),(x,-.009,.26),.064,.057,4,'shin.'+suffix,12,4,.002)
        for z in (.11,.145,.18,.215): box('boot_lace',(.068,.007,.008),(x,.052,z),2,'shin.'+suffix,.002)
    return rig,joints


def animation(rig,joints):
    rig.animation_data_create()
    for clip,(duration,loop) in CLIPS.items():
        action=bpy.data.actions.get(clip)
        if action:
            continue
        action=bpy.data.actions.new(clip); action.use_fake_user=True
        rig.animation_data.action=action
        frames=round(duration*30)
        for frame in range(frames+1):
            t=frame/frames; phase=math.tau*t
            targets={n:[Vector(a),Vector(b)] for n,(a,b,_) in joints.items()}
            crouch=clip in ('crouch','crouch_walk','deploy')
            moving=clip in ('walk','run','crouch_walk','haul')
            bend=math.sin(math.pi*t) if clip in ('pickup','deploy') else 0
            recoil=math.exp(-t*12)*math.sin(t*math.pi*4) if clip=='fire' else 0
            hit=math.sin(math.pi*t)*.12 if clip=='hit' else 0
            drop=.36 if crouch else .13 if clip=='run' else .06 if moving else 0
            bob=(.028 if clip=='run' else .014)*math.cos(phase*2) if moving else .004*(math.sin(phase)-1)
            shift=Vector((0,-bend*.10-recoil*.03, -drop-bend*(.32 if clip=='pickup' else .16)+bob))
            for name in targets:
                if name!='root': targets[name]=[p+shift for p in targets[name]]
            # Torso lean about the pelvis; legs are recomputed with foot contacts.
            lean=(.35 if crouch else .1 if clip=='run' else .035)+bend*.65-hit
            pivot=targets['pelvis'][0]
            rotation=Matrix.Rotation(-lean,3,'X')
            for name in targets:
                if name=='root' or name.startswith(('thigh','shin','foot')): continue
                targets[name]=[pivot+rotation@(p-pivot) for p in targets[name]]
            for suffix,side in [('L',-1),('R',1)]:
                thigh='thigh.'+suffix; shin='shin.'+suffix; foot='foot.'+suffix
                hip=Vector(joints[thigh][0])+shift
                wave=math.sin(phase+(0 if side==1 else math.pi))
                stride=(.28 if clip=='walk' else .40 if clip=='run' else .18) if moving else 0
                ankle=Vector((side*.135,wave*stride,.14+max(0,math.cos(phase+(0 if side==1 else math.pi)))*(.13 if clip=='run' else .065))) if moving else Vector(joints[shin][1])
                # Analytic two-bone knee solve with fixed segment lengths.
                upper=(Vector(joints[thigh][1])-Vector(joints[thigh][0])).length
                lower=(Vector(joints[shin][1])-Vector(joints[shin][0])).length
                knee=solve_joint(hip,ankle,upper,lower,Vector((0,1,0)))
                targets[thigh]=[hip,knee]; targets[shin]=[knee,ankle]
                targets[foot]=[ankle,ankle+Vector((0,.18,-.06))]
                shoulder=targets['upper_arm.'+suffix][0]
                aiming=clip in ('aim','fire')
                # Both palms lie on the rifle grip axis, 0.26 m apart.
                hand=Vector((.035, .24 if side==1 else .50,1.39 if aiming else 1.22))+shift
                if aiming: hand.y-=recoil*.07
                if clip in ('pickup','deploy'): hand=hand.lerp(Vector((side*.10,.47,.49)),bend)
                if clip=='haul': hand=Vector((side*.15,-.13,.86))+shift
                if clip=='run': hand.z+=.035*math.sin(phase)
                if clip=='death':
                    tuck=min(t/.75,1)
                    hand=hand.lerp(Vector((side*.23,.025,1.12))+shift,tuck)
                upper=(Vector(joints['upper_arm.'+suffix][1])-Vector(joints['upper_arm.'+suffix][0])).length
                lower=(Vector(joints['forearm.'+suffix][1])-Vector(joints['forearm.'+suffix][0])).length
                delta=hand-shoulder
                if delta.length>upper+lower-.001: hand=shoulder+delta.normalized()*(upper+lower-.001)
                elbow=solve_joint(shoulder,hand,upper,lower,Vector((side*.65,-.15,-1)))
                targets['upper_arm.'+suffix]=[shoulder,elbow]
                targets['forearm.'+suffix]=[elbow,hand]
                targets['hand.'+suffix]=[hand,hand+Vector((0,.09,0))]
            if clip=='death':
                # Falling body stays in the actor's cell; only the skeleton moves.
                fall=min(t/.75,1); angle=-math.pi*.49*fall
                turn=Matrix.Rotation(angle,3,'X')
                for name in targets:
                    if name=='root': continue
                    targets[name]=[Vector((p.x,p.y,p.z)) for p in targets[name]]
                    targets[name]=[turn@(p-Vector((0,0,.9)))+Vector((0,0,.22+.68*(1-fall))) for p in targets[name]]
            bpy.context.scene.frame_set(frame)
            # Compute every local basis from absolute target matrices. Setting
            # pb.matrix one-by-one reads a stale evaluated parent from the
            # previous clip/frame, which corrupts keys at clip boundaries.
            matrices={}
            for name in joints:
                a,b=targets[name]; rest=rig.data.bones[name].matrix_local
                if name=='root': matrices[name]=rest.copy()
                else:
                    direction=(b-a).normalized(); original=(Vector(joints[name][1])-Vector(joints[name][0])).normalized()
                    q=original.rotation_difference(direction)@rest.to_quaternion()
                    matrices[name]=Matrix.LocRotScale(a,q,Vector((1,1,1)))
            if clip=='death':
                # Keep the collapsing skinned surface on the floor, including
                # hands/pack, instead of guessing a pelvis height.
                bottom=min((matrices[obj.vertex_groups[0].name]@
                            rig.data.bones[obj.vertex_groups[0].name].matrix_local.inverted()@
                            obj.matrix_world@v.co).z for obj in PARTS for v in obj.data.vertices)
                lift=max(0,.003-bottom)
                for name,matrix in matrices.items():
                    if name!='root': matrix.translation.z+=lift
            for name in joints:
                pb=rig.pose.bones[name]; rest=rig.data.bones[name].matrix_local
                parent=joints[name][2]
                basis=rest.inverted()@matrices[name]
                if parent:
                    basis=rest.inverted()@rig.data.bones[parent].matrix_local@matrices[parent].inverted()@matrices[name]
                pb.rotation_mode='QUATERNION'
                pb.location,pb.rotation_quaternion,pb.scale=basis.decompose()
                pb.keyframe_insert('location',frame=frame,group=name)
                pb.keyframe_insert('rotation_quaternion',frame=frame,group=name)
                pb.keyframe_insert('scale',frame=frame,group=name)
            bpy.context.view_layer.update()
        for fc in action.fcurves:
            for key in fc.keyframe_points: key.interpolation='LINEAR'
        action['loop']=loop; action['root_motion']=False
    rig.animation_data.action=None
    for pb in rig.pose.bones: pb.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(0)


def solve_joint(a,b,upper,lower,pole):
    delta=b-a; d=max(.001,min(delta.length,upper+lower-.001)); direction=delta.normalized()
    along=(upper*upper-lower*lower+d*d)/(2*d)
    height=math.sqrt(max(.0001,upper*upper-along*along))
    axis=pole-direction*pole.dot(direction); axis.normalize()
    return a+direction*along+axis*height


def weapon(asset,length,family):
    kit.CURRENT=asset
    pistol=family=='pistol'; end=length-(.07 if pistol else .32)
    wood=asset in ('m1_garand','kar98k','springfield','kar98k_zf','bar','thompson','mg42')
    stock_tile=14 if wood else 3
    if pistol:
        grip=box('grip',(.031,.070,.109),(0,-.016,-.059),4,None,.008); grip.rotation_euler.x=-.20
        box('receiver',(.035,.145,.030),(0,.046,.028),3,None,.006)
        tube('barrel',(0,.065,.035),(0,end,.035),.012,.010,3,None,12,1,0)
        if asset=='luger': box('toggle',(.034,.040,.022),(0,.025,.052),3,None,.003)
    else:
        if asset=='mp40':
            for side in (-1,1):
                tube('folding_stock_rail',(side*.027,-.08,-.04),(side*.027,-.34,-.06),.006,.006,3,None,8,1,0)
            box('stock_loop',(.065,.014,.06),(0,-.34,-.037),3,None,.003)
            grip=box('pistol_grip',(.039,.058,.11),(0,-.065,-.055),4,None,.005); grip.rotation_euler.x=-.25
        else:
            stock=box('shoulder_stock',(.053,.245,.110),(0,-.21,-.012),stock_tile,None,.012); stock.rotation_euler.x=-.10
            box('buttplate',(.058,.014,.114),(0,-.332,-.002),3,None,.004)
        box('receiver',(.056,.25,.066),(0,.025,.035),3,None,.007)
        box('fore_stock',(.052,.28,.042),(0,.257,.012),stock_tile,None,.008)
        tube('barrel',(0,.21,.045),(0,end,.045),.018,.011,3,None,12,2,0)
        box('front_sight',(.018,.011,.038),(0,end-.025,.073),3,None,.002)
        box('rear_sight',(.031,.025,.021),(0,.055,.077),3,None,.003)
        tube('bolt',(0,.046,.053),(.065,.046,.053),.006,.006,3,None,8,1,0)
        ellipsoid('bolt_knob',(.012,.012,.012),(.07,.046,.053),3,None,10,6)
        if asset=='m1_garand':
            tube('gas_cylinder',(0,.46,.022),(0,end-.012,.022),.017,.015,3,None,12,1,0)
            for x in (-.024,.024): box('aperture_ears',(.009,.04,.034),(x,-.052,.083),3,None,.002)
        if asset in ('kar98k','kar98k_zf'):
            for y in (.27,.49): box('barrel_band',(.058,.024,.062),(0,y,.03),3,None,.002)
        if family in ('mg','smg'):
            if asset=='thompson':
                tube('drum_mag',(-.04,.09,-.072),(.04,.09,-.072),.072,.072,3,None,20,1,0)
                box('vertical_grip',(.035,.052,.108),(0,.29,-.056),14,None,.006)
            else:
                box('magazine',(.032,.065,.175),(.0,.09,-.069),3,None,.005)
            if family=='mg':
                for side in (-1,1): tube('bipod',(0,end-.1,.037),(side*.145,end-.13,-.145),.007,.006,3,None,8,1,0)
            if asset=='mg42':
                box('barrel_jacket',(.063,.43,.057),(0,.39,.043),3,None,.005)
                for y in np.linspace(.23,.55,9):
                    for side in (-1,1): box('cooling_slot',(.001,.021,.021),(side*.032,y,.046),7,None,.001)
        if family=='scout':
            scope_front=.238 if asset=='springfield' else .18
            tube('scope',(0,-.048,.12),(0,scope_front,.12),.023,.023,3,None,14,1,0)
            for y in (0,.18): box('scope_mount',(.025,.018,.07),(0,y,.09),3,None,.003)
            tube('scope_lens',(0,scope_front-.001,.12),(0,scope_front+.001,.12),.021,.021,15,None,14,1,0)
        for y in (-.20,.33): box('sling_swivel',(.05,.008,.021),(0,y,-.042),3,None,.003)
    # Open trigger guard is a four-sided hoop rather than an opaque rectangle.
    for x in (-.014,.014): box('trigger_guard',(.005,.060,.007),(x,.015,-.046),3,None,.002)
    for y in (-.017,.047): box('trigger_guard_end',(.033,.006,.030),(0,y,-.033),3,None,.002)
    box('trigger',(.005,.011,.025),(0,.008,-.029),3,None,.001)
    return {'grip':[0,0,0],'muzzle':[0,.035 if pistol else .045,-end],
            'support_hand':[0,0,-.26] if not pistol else None}


def tool(asset):
    kit.CURRENT=asset
    if asset=='knife':
        box('grip',(.030,.105,.023),(0,-.02,0),4,None,.005)
        box('guard',(.072,.012,.009),(0,.035,0),3,None,.002)
        box('blade',(.027,.16,.006),(0,.12,0),3,None,.001)
        tube('tip',(0,.194,0),(0,.238,0),.013,0.001,3,None,4,1,0)
    elif asset=='grenade':
        ellipsoid('body',(.043,.043,.065),(0,0,.064),0,None,16,10)
        box('spoon',(.017,.071,.008),(0,.01,.133),3,None,.002)
        tube('fuse',(0,0,.11),(0,0,.145),.014,.014,3,None,10,1,0)
    elif asset=='mine':
        tube('mine',(0,0,.01),(0,0,.07),.135,.135,0,None,24,1,0)
        tube('pressure_plate',(0,0,.07),(0,0,.085),.08,.08,3,None,20,1,0)
    elif asset=='decoy':
        box('case',(.16,.23,.11),(0,0,.065),2,None,.012)
        for x in (-.045,0,.045): box('speaker_slot',(.014,.11,.001),(x,.02,.122),7,None,.002)
        tube('aerial',(.05,-.08,.1),(.05,-.08,.35),.003,.002,3,None,6,1,0)
    elif asset=='ammo_pack':
        box('satchel',(.33,.20,.22),(0,0,.13),9,None,.025)
        for x in (-.105,.105): box('strap',(.034,.211,.018),(x,0,.248),4,None,.003)
    return {'grip':[0,0,0],'tip':[0,0,-.238]} if asset=='knife' else {}


def export(asset,objects,level,animated=False):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    path=OUT/'models'/f'{asset}_lod{level}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_apply=False,export_materials='EXPORT',export_image_format='NONE',export_extras=True,
        export_yup=True,export_animations=animated,export_animation_mode='ACTIONS',
        export_force_sampling=True,export_frame_range=False,export_skins=animated,
        export_cameras=False,export_lights=False,export_optimize_animation_size=True)
    normalize_glb(path)
    tris=0; surfaces=0
    for obj in objects:
        if obj.type!='MESH': continue
        obj.data.calc_loop_triangles(); tris+=len(obj.data.loop_triangles); surfaces+=len(obj.data.materials)
    return {'path':path.relative_to(PROJECT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'triangles':tris,'surfaces':surfaces}


def clean_mesh(obj):
    # Decimate on n-gons can collapse opposite faces into duplicate polygons.
    # Triangulate first and validate the *result*, including corner/UV arrays.
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bmesh.ops.dissolve_degenerate(bm, dist=1e-7, edges=list(bm.edges))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data); bm.free()
    changed=obj.data.validate(clean_customdata=False)
    obj.data.update()
    assert not obj.data.validate(clean_customdata=False), obj.name
    if changed: print('MESH_REPAIRED',obj.name,flush=True)


def reduce_mesh(obj, budget):
    clean_mesh(obj)
    obj.data.calc_loop_triangles()
    count=len(obj.data.loop_triangles)
    if count>budget:
        bpy.context.view_layer.objects.active=obj
        dec=obj.modifiers.new('BudgetLOD','DECIMATE'); dec.ratio=(budget-40)/count
        dec.use_collapse_triangulate=True
        while list(obj.modifiers).index(dec)>0: bpy.ops.object.modifier_move_up(modifier=dec.name)
        bpy.ops.object.modifier_apply(modifier=dec.name)
        clean_mesh(obj)
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles)<=budget, (obj.name,len(obj.data.loop_triangles),budget)
    # Symmetric Decimate corners choose different inherited UV values across
    # processes. Preserve each corner's atlas tile and deterministically project
    # bind-space metre coordinates, with the same inset/gutter contract.
    uv=obj.data.uv_layers.active.data
    for face in obj.data.polygons:
        normal=[round(abs(v),6) for v in face.normal]
        axis=max(range(3),key=lambda i:normal[i])
        axes=(1,2) if axis==0 else (0,2) if axis==1 else (0,1)
        for loop in face.loop_indices:
            col,row=[min(3,max(0,int(v*4))) for v in uv[loop].uv]
            point=[round(v,6) for v in obj.data.vertices[obj.data.loops[loop].vertex_index].co]
            uv[loop].uv=((col+.025+.95*((point[axes[0]]*2)%1))/4,
                         (row+.025+.95*((point[axes[1]]*2)%1))/4)


def build():
    global PARTS
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.context.scene.render.fps=30
    bpy.context.scene.unit_settings.system='METRIC'
    atlas(); entries=[]
    # Retire only the misidentified WIP candidate; the game has no heavy enemy.
    for level in range(3): (OUT/'models'/f'enemy_heavy_lod{level}.glb').unlink(missing_ok=True)
    for asset in [*CHARACTERS,*GUNS,'knife','grenade','mine','decoy','ammo_pack']:
        PARTS=[]; rig=None; sockets={}
        if asset in CHARACTERS:
            rig,joints=character(asset,*CHARACTERS[asset]); category='character'
            animation(rig,joints)
            sockets={'weapon_hand':{'bone':'hand.R','position_bone_local_m':[0,.035,0],
                       'rotation_bone_local_deg':[90,0,0]},
                     'support_hand':{'bone':'hand.L','position_bone_local_m':[0,.035,0],
                       'rotation_bone_local_deg':[90,0,0]}}
        elif asset in GUNS:
            sockets=weapon(asset,*GUNS[asset]); category='weapon'
        else: sockets=tool(asset); category='tool'
        mesh=kit.join_parts(PARTS,asset+'_body')
        if category=='tool' and asset!='knife':
            floor=min(v.co.z for v in mesh.data.vertices)
            mesh.data.transform(Matrix.Translation((0,0,-floor)))
            mesh.data.update()
        reduce_mesh(mesh,LOD_BUDGET[category][0])
        if rig:
            mesh.parent=rig; modifier=mesh.modifiers.new('SharedSkin','ARMATURE'); modifier.object=rig
        collection=bpy.data.collections.new(asset); bpy.context.scene.collection.children.link(collection)
        originals=[mesh]+([rig] if rig else [])
        if category=='weapon' or asset=='knife':
            for name,position in sockets.items():
                if position is None: continue
                marker=bpy.data.objects.new(asset+'__socket_'+name,None)
                bpy.context.collection.objects.link(marker)
                # Contract stores exported (+Y up/-Z forward) coordinates.
                marker.location=(position[0],-position[2],position[1])
                originals.append(marker)
        for obj in originals:
            for old in list(obj.users_collection): old.objects.unlink(obj)
            collection.objects.link(obj)
            obj['asset_id']=asset; obj['collision_class']='visual_only'
        lods=[export(asset,originals,0,rig is not None)]
        for level,budget in enumerate(LOD_BUDGET[category][1:],1):
            copy=mesh.copy(); copy.data=mesh.data.copy(); collection.objects.link(copy)
            bpy.context.view_layer.objects.active=copy
            # Always work from LOD0 in bind space, ahead of SharedSkin.
            reduce_mesh(copy,min(budget,int(lods[0]['triangles']*.52**level)))
            lods.append(export(asset,[copy]+[o for o in originals if o!=mesh],level,rig is not None))
            bpy.data.objects.remove(copy,do_unlink=True)
        points=[mesh.matrix_world@Vector(p) for p in mesh.bound_box]
        dims=[max(p[i] for p in points)-min(p[i] for p in points) for i in (0,2,1)]
        entries.append({'asset_id':asset,'category':category,'source':'ArtSource/v2/build_actors.py',
            'editable_source':'ArtSource/v2/actors.blend','tool':'Blender '+bpy.app.version_string,
            'provenance':'Original authored geometry, material fields, rig and analytic animation; no third-party assets',
            'usage':'Project-authored; same repository terms; generic equipment without insignia',
            'unit':'metre','runtime_axes':'+Y up, -Z forward','origin':'ground centre' if rig else 'weapon grip' if category=='weapon' or asset=='knife' else 'ground centre',
            'logic_id':None,'dimensions_m':[round(v,4) for v in dims], 'lods':lods,
            'materials':['shared actor 1024px albedo/normal/ORM atlas'],'collision':'visual_only',
            'skeleton':list(joints) if rig else [],'animations':[{'name':n,'duration':round(d*30)/30,'loop':l,'root_motion':False} for n,(d,l) in CLIPS.items()] if rig else [],
            'sockets':sockets,'lod_triangle_budget':LOD_BUDGET[category],
            'validation_scene':'res://ArtSource/v2/actor_acceptance/review.gd','status':'repaired candidate; acceptance report required'})
        # Hide other collections in Blender viewport; exports use selection only.
        for obj in originals: obj.hide_set(True)
        print('ACTOR_ASSET',asset,[(x['triangles'],x['surfaces']) for x in lods],flush=True)
    manifest={'schema':2,'seed':SEED,'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'canonicalizer_sha256':hashlib.sha256((HERE/'actor_acceptance/canonicalize.py').read_bytes()).hexdigest(),'assets':entries,
              'textures':[{'path':p.relative_to(PROJECT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted((OUT/'textures').glob('actor_*.png'))]}
    (OUT/'actors_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    for img in bpy.data.images:
        if img.filepath: img.pack()
    for obj in bpy.data.objects: obj.hide_set(False)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'actors.blend'))
    print('ACTOR_KIT_EXPORTED',len(entries),flush=True)


if __name__=='__main__': build()
