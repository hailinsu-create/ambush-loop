#!/usr/bin/env python3
"""Original skinned military characters, in-place clips and the ten-gun kit.
Blender 4.3.2: blender -b --python-exit-code 1 --python ArtSource/v2/build_actors.py
              -- --output-root /tmp/independent-actor-build
Authoring metres, +Z up/+Y forward; runtime +Y up/-Z forward.
No root motion, downloaded meshes, markings or external services.
"""
import hashlib
import json
import math
from pathlib import Path
import sys
import argparse
import bpy
import bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_yard_kit as kit
from actor_acceptance.canonicalize import normalize_glb
from actor_acceptance import firearm_contract as firearms
PROJECT = HERE.parents[1]
OUT = PROJECT / 'art/v2'
PARTS = []
MAT = None
DETAIL_LEVEL = None
DETAIL_KIND = None
CATALOG = OUT / 'actors_manifest.json'
BLEND_SOURCE = HERE / 'actors.blend'
SEED = 194407
CLIPS = {'idle': (2.4, True), 'walk': (.9, True), 'run': (.6, True),
         'aim': (1.8, True), 'fire': (.24, False), 'pickup': (1.0, False),
         'death': (1.2, False), 'crouch': (2., True), 'crouch_walk': (1.15, True),
         'deploy': (1.25, False), 'hit': (.3, False), 'haul': (1.2, True)}
CLIPS.update(firearms.ADDED_CLIPS)
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
    palette = [(.15,.19,.12), (.28,.25,.18), (.10,.13,.12), (.12,.14,.15),
               (.18,.11,.064), (.42,.29,.20), (.14,.17,.10), (.055,.057,.052),
               (.50,.38,.15), (.27,.25,.19), (.72,.67,.52), (.047,.035,.028),
               (.27,.10,.07), (.18,.22,.21), (.31,.17,.078), (.20,.27,.26)]
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
    return finish(obj,name,tile,bone,0 if DETAIL_LEVEL==2 or (DETAIL_KIND!='character' and DETAIL_LEVEL==1) else bevel)


def resolution(segments,rings):
    if DETAIL_LEVEL is None: return segments,rings
    scale=(.8,.5,.3)[DETAIL_LEVEL]
    return max(6,round(segments*scale)),max(2,round(rings*scale))


def ellipsoid(name,size,at,tile,bone=None,segments=16,rings=10):
    segments,rings=resolution(segments,rings)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=at)
    obj=bpy.context.object; obj.scale=size
    for poly in obj.data.polygons: poly.use_smooth=True
    return finish(obj,name,tile,bone)


def tube(name,a,b,r0,r1,tile,bone=None,sides=12,rings=7,fold=.006):
    if DETAIL_LEVEL is not None:
        sides,rings=resolution(sides,rings)
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


def jacket(cloth):
    # One continuous garment rather than overlapping spherical chest shells.
    sections=[(1.025,.185,.13),(1.10,.204,.13),(1.20,.206,.135),
              (1.32,.225,.135),(1.43,.222,.142),(1.47,.14,.08)]
    sides=(16,10,6)[DETAIL_LEVEL];vertices=[];faces=[]
    for z,rx,ry in sections:
        for i in range(sides):
            a=math.tau*i/sides
            vertices.append((rx*math.cos(a),ry*math.sin(a),z))
    for row in range(len(sections)-1):
        for i in range(sides):
            a=row*sides+i;b=row*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(sections)-1)*sides,len(sections)*sides))])
    data=bpy.data.meshes.new('jacket');data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new('jacket',data);bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    finish(obj,'jacket',cloth)
    spine=obj.vertex_groups.new(name='spine');chest=obj.vertex_groups.new(name='chest')
    for v in data.vertices:
        w=max(0,min(1,(v.co.z-1.20)/.16))
        if w<1:spine.add([v.index],1-w,'REPLACE')
        if w>0:chest.add([v.index],w,'REPLACE')
    for p in data.polygons:p.use_smooth=len(p.vertices)==4


def authored_mesh(name,vertices,faces,tile,bone=None):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    finish(obj,name,tile,bone)
    return obj


def ring_shell(name,sections,sides,tile,bone,facial=True):
    vertices=[];faces=[]
    for z,rx,front,back in sections:
        for i in range(sides):
            a=math.tau*i/sides;c,s=math.cos(a),math.sin(a)
            # Broad facial planes, narrower jaw: avoid an egg with floating eyes.
            vertices.append((rx*math.copysign(abs(c)**(.85 if facial else 1),c),
                             (front if s>=0 else back)*math.copysign(abs(s)**(.6 if facial else 1),s),z))
    for row in range(len(sections)-1):
        for i in range(sides):
            a=row*sides+i;b=row*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(sections)-1)*sides,len(sections)*sides))])
    obj=authored_mesh(name,vertices,faces,tile,bone)
    for face in obj.data.polygons:face.use_smooth=len(face.vertices)==4
    return obj


def face_and_helmet(cloth,style):
    ring_shell('head',[(1.574,.029,.069,.044),(1.599,.061,.087,.059),
        (1.628,.079,.105,.074),(1.663,.086,.108,.085),
        (1.699,.084,.110,.090),(1.730,.088,.106,.095),
        (1.773,.083,.087,.091),(1.811,.047,.042,.049)],(20,12,8)[DETAIL_LEVEL],5,'head')
    ellipsoid('nose',(.012,.024,.031),(0,.113,1.670),5,'head',16,10)
    ellipsoid('nose_bridge',(.007,.011,.026),(0,.108,1.695),5,'head',12,8)
    for side in (-1,1):
        ellipsoid('ear',(.012,.020,.027),(side*.087,.008,1.674),5,'head',10,6)
        if DETAIL_LEVEL==1:
            xx=side*.037
            authored_mesh('orbital_shadow',[(xx-.0125,.1055,1.696),(xx+.0125,.1055,1.696),(xx+.0125,.1055,1.702),(xx-.0125,.1055,1.702)],[(0,1,2,3)],4,'head')
        if DETAIL_LEVEL==0:
            box('orbital_shadow',(.025,.0015,.006),(side*.037,.105,1.699),4,'head',.001)
            ellipsoid('pupil',(.0035,.001,.0025),(side*.037,.106,1.699),11,'head',8,4)
            rigid_curve('upper_lid',[(side*.037+x,.1054+y,1.702+z) for x,y,z in [(-.014,0,0),(0,.0007,.002),(.014,0,0)]],.0015,.0015,5,'head')
            box('brow',(.030,.003,.003),(side*.037,.104,1.711),11,'head',.001)
    if DETAIL_LEVEL<2:box('mouth',(.033,.003,.0025),(0,.107,1.626),4,'head',.001)
    if style in ('helmet','heavy','radio','rolled'):
        ring_shell('helmet_shell',[(1.732,.120,.144,.132),(1.739,.119,.142,.132),
            (1.766,.114,.135,.126),(1.799,.097,.113,.106),
            (1.828,.069,.078,.076),(1.842,.018,.022,.022)],
            (20,12,8)[DETAIL_LEVEL],3 if cloth==13 else 0,'head',False)
        for side in (-1,1):tube('chin_strap',(side*.099,.005,1.737),(side*.043,.067,1.588),.004,.004,4,'head',6,1,0)
        if style=='rolled':box('helmet_band',(.185,.012,.017),(0,.139,1.742),9,'head',.003)


def continuous_limb(name,points,radii,bones,tile,anchor,terminal):
    sides,rings=resolution(14,9);a,j,b=map(Vector,points)
    first=(j-a).normalized();last=(b-j).normalized();vertices=[];faces=[];weights=[]
    for row in range(rings*2+1):
        segment=min(row//rings,1);t=(row-segment*rings)/rings
        center=(a.lerp(j,t) if segment==0 else j.lerp(b,t))
        tangent=(first+last).normalized() if row==rings else first if segment==0 else last
        if row==0 and name.startswith('upper_arm'):
            tangent=(Vector((1 if a.x>0 else -1,0,0))+first).normalized()
        reference=Vector((0,1,0)) if name.startswith('upper_arm') else Vector((1,0,0))
        x=reference-tangent*tangent.dot(reference);x.normalize();y=tangent.cross(x).normalized()
        radius=radii[segment]*(1-t)+radii[segment+1]*t
        lower=max(0,(t-.7)/.3)*.5 if segment==0 else min(1,.5+t/.6)
        influences={bones[0]:1-lower,bones[1]:lower}
        if segment==0 and t<.15:
            w=.4*(1-t/.15);influences={bones[0]:1-w,anchor:w}
        if segment==1 and t>.8:
            w=.65*(t-.8)/.2;influences={bones[1]:1-w,terminal:w}
        for i in range(sides):
            angle=math.tau*i/sides;fold=.002*math.sin(t*math.pi)*math.sin(t*19+angle*3)
            vertices.append(center+(x*math.cos(angle)+y*math.sin(angle))*(radius+fold));weights.append(influences)
    rows=rings*2+1
    if name.startswith('upper_arm'):
        # Continue the sleeve inside the jacket instead of leaving an exposed
        # flat shoulder cap. Both rings share the existing chest/clavicle skin.
        side=1 if a.x>0 else -1;extra=[];extra_weights=[]
        for xx,radius,influences in [(side*.14,.042,{'chest':1}),
                                      (side*.175,.058,{'chest':.4,anchor:.6})]:
            tangent=Vector((side,0,0)) if abs(xx)<.15 else (Vector((side,0,0))+first).normalized()
            x=Vector((0,1,0))-tangent*tangent.y;x.normalize();y=tangent.cross(x).normalized()
            center=Vector((xx,0,a.z))
            for i in range(sides):
                angle=math.tau*i/sides;extra.append(center+(x*math.cos(angle)+y*math.sin(angle))*radius);extra_weights.append(influences)
        vertices=extra+vertices;weights=extra_weights+weights;rows+=2
    for row in range(rows-1):
        for i in range(sides):
            p=row*sides+i;q=row*sides+(i+1)%sides;faces.append((p,q,q+sides,p+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((rows-1)*sides,rows*sides))])
    obj=authored_mesh(name,vertices,faces,tile)
    groups={n:obj.vertex_groups.new(name=n) for n in dict.fromkeys([*bones,anchor,terminal]+(['chest'] if name.startswith('upper_arm') else []))}
    for i,influences in enumerate(weights):
        for n,w in influences.items():
            if w>0:groups[n].add([i],w,'REPLACE')
    for face in obj.data.polygons:face.use_smooth=len(face.vertices)==4


def rigid_curve(name,points,minor,width,tile,bone):
    points=list(map(Vector,points));sides=8 if DETAIL_LEVEL==0 else 6;vertices=[];faces=[]
    for row,p in enumerate(points):
        direction=(points[min(row+1,len(points)-1)]-points[max(row-1,0)]).normalized()
        x=Vector((0,1,0))-direction*direction.y
        if x.length<.1:x=Vector((1,0,0))-direction*direction.x
        x.normalize();y=direction.cross(x).normalized()
        for i in range(sides):
            a=math.tau*i/sides;vertices.append(p+x*(width*math.cos(a))+y*(minor*math.sin(a)))
    for row in range(len(points)-1):
        for i in range(sides):
            p=row*sides+i;q=row*sides+(i+1)%sides;faces.append((p,q,q+sides,p+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    obj=authored_mesh(name,vertices,faces,tile,bone)
    for face in obj.data.polygons:face.use_smooth=len(face.vertices)==4


def rifle_glove(suffix,joints):
    hx,hy,hz=joints['hand.'+suffix][0];bone='hand.'+suffix
    if suffix=='R':
        box('palm',(.028,.063,.041),(hx+.028,hy+.035,hz-.022),4,bone,.008)
        contour=[(.040,-.012),(.042,-.037),(.009,-.055),(-.022,-.034)]
        thumb=[(.021,.017,-.014),(.035,-.010,.004),(.018,-.040,.015),(-.015,-.042,.004)]
    else:
        box('palm',(.073,.062,.031),(hx,hy+.035,hz-.027),4,bone,.008)
        contour=[(.028,-.022),(.043,-.013),(.039,.015),(.018,.025)]
        thumb=[(-.020,.030,-.028),(-.040,.030,-.010),(-.038,.030,.012),(-.014,.030,.024)]
    count=(4,2,1)[DETAIL_LEVEL]
    for i in range(count):
        offset=.013+i*.015 if count==4 else .020+i*.027 if count==2 else .035
        finger_contour=contour
        if suffix=='R' and DETAIL_LEVEL<2 and i==count-1:
            offset=.049;finger_contour=[(.040,-.012),(.028,-.030),(.008,-.037)]
        rigid_curve('curled_fingers',[(hx+x,hy+offset,hz+z) for x,z in finger_contour],.0075 if count==4 else .011,.0075 if count==4 else .012 if count==2 else .031,4,bone)
    rigid_curve('thumb',[(hx+x,hy+y,hz+z) for x,y,z in thumb],.010,.012,4,bone)
    tube('glove_cuff',(hx,hy-.012,hz),(hx,hy+.022,hz),.029,.032,4,bone,8,1,0)


def boot_upper(x,bone):
    # A closed lasted upper meets the sole along its entire outline. An
    # ellipsoid toe reveals a visible gap when the foot rolls onto its heel.
    sections=[(-.065,.048,.102),(-.028,.057,.136),(.040,.060,.115),
              (.115,.056,.093),(.195,.047,.069),(.210,.026,.050)]
    sides=max(6,round(12*(.8,.5,.3)[DETAIL_LEVEL]));vertices=[];faces=[]
    for y,width,top in sections:
        for i in range(sides):
            angle=math.tau*i/sides
            vertices.append((x+width*math.cos(angle),y,.022+(top-.022)*max(0,math.sin(angle))))
    for row in range(len(sections)-1):
        for i in range(sides):
            p=row*sides+i;q=row*sides+(i+1)%sides;faces.append((p,q,q+sides,p+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(sections)-1)*sides,len(sections)*sides))])
    obj=authored_mesh('boot_upper',vertices,faces,4,bone)
    for face in obj.data.polygons:face.use_smooth=len(face.vertices)==4


def character(asset,cloth,style,rig=None,joints=None):
    kit.CURRENT=asset
    # Slightly tapered, folded jacket, with overlapping panels at the waist.
    ellipsoid('trousers_seat',(.19,.125,.20),(0,-.007,.98),cloth,'pelvis')
    jacket(cloth)
    tube('neck',(0,0,1.47),(0,0,1.60),.061,.06,5,'neck',12,3,0)
    face_and_helmet(cloth,style)
    # Headgear gives distinguishable silhouettes from every side.
    if style=='hood':
        segments,rings=resolution(20,12)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,
                                           location=(0,-.012,1.705))
        hood=bpy.context.object
        bm=bmesh.new(); bm.from_mesh(hood.data)
        # Genuine face aperture, rather than an opaque cap over the face.
        opening=[f for f in bm.faces if f.calc_center_median().y>.48 and f.calc_center_median().z<.72]
        bmesh.ops.delete(bm,geom=opening,context='FACES')
        bm.to_mesh(hood.data); bm.free()
        hood.scale=(.128,.135,.161); finish(hood,'hood',cloth,'head')
        for side in (-1,1): tube('hood_edge',(side*.099,.080,1.62),(side*.094,.086,1.78),.011,.012,cloth,'head',8,2,0)
    elif style=='beret':
        ellipsoid('soft_beret',(.124,.12,.053),(-.02,0,1.785),2,'head',20,8)
        box('unit_tab',(.025,.006,.027),(.05,.107,1.775),10,'head',.002)
    elif style not in ('helmet','heavy','radio','rolled'):
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
    if DETAIL_LEVEL==0:
        for z in (1.19,1.27,1.35,1.42): ellipsoid('button',(.005,.004,.005),(0,.153,z),8,'chest',8,4)
    ellipsoid('belt',(.207,.146,.025),(0,0,1.041),4,'pelvis',20,6)
    box('buckle',(.043,.013,.033),(0,.15,1.041),8,'pelvis',.003)
    if asset=='enemy_patrol':
        tube('bedroll',(-.15,-.175,1.20),(.15,-.175,1.20),.060,.060,cloth,'chest',12,3,0)
        for x in (-.09,.09):box('bedroll_strap',(.023,.141,.129),(x,-.175,1.20),4,'chest',.004)
        box('breadbag',(.145,.095,.15),(.105,-.13,1.055),9,'pelvis',.012)
    else:
        if style!='radio':box('pack',(.255,.135,.27),(0,-.159,1.282),9,'chest',.025)
        for x in (-.078,.078):box('pack_strap',(.022,.014,.25),(x,-.235,1.282),4,'chest',.004)
    ellipsoid('canteen',(.065,.057,.093),(.205,-.068,1.012),3,'pelvis')
    if style in ('heavy','rolled') and DETAIL_LEVEL<2:
        for i in range(10): tube('cartridge',(-.13+i*.028,.16,1.29),(-.13+i*.028,.16,1.35),.010,.008,8,'chest',6,1,0)
    if style=='radio':
        box('radio_pack',(.29,.14,.37),(0,-.18,1.32),2,'chest',.013)
        tube('radio_aerial',(.105,-.22,1.49),(.105,-.22,2.15),.005,.003,3,'chest',6,1,0)
    # Anatomy and clothing follow the exact bind skeleton.
    if rig is None: rig,joints=skeleton()
    for suffix in ('L','R'):
        for first,last,radii,anchor,terminal in [('upper_arm','forearm',(.063,.048,.033),'clavicle','hand'),('thigh','shin',(.098,.071,.050),'pelvis','foot')]:
            upper=first+'.'+suffix;lower=last+'.'+suffix
            continuous_limb(first+'_continuous',[joints[upper][0],joints[upper][1],joints[lower][1]],radii,[upper,lower],cloth,anchor+'.'+suffix if anchor=='clavicle' else anchor,terminal+'.'+suffix)
        rifle_glove(suffix,joints)
        x=joints['foot.'+suffix][0][0]
        box('boot_sole',(.125,.273,.027),(x,.067,.0135),7,'foot.'+suffix,.010)
        boot_upper(x,'foot.'+suffix)
        shaft=tube('boot_shaft',(x,-.02,.08),(x,-.009,.26),.064,.057,4,'shin.'+suffix,12,4,.002)
        shin=shaft.vertex_groups['shin.'+suffix];foot=shaft.vertex_groups.new(name='foot.'+suffix)
        for v in shaft.data.vertices:
            w=max(0,min(1,(.20-v.co.z)/.10));shin.add([v.index],1-w,'REPLACE')
            if w>0:foot.add([v.index],w,'REPLACE')
        if DETAIL_LEVEL==0:
            for z in (.11,.145,.18,.215):
                lace=box('boot_lace',(.069,.005,.004),(x,.043,z),2,'shin.'+suffix,.001)
                shin=lace.vertex_groups['shin.'+suffix];foot=lace.vertex_groups.new(name='foot.'+suffix)
                for v in lace.data.vertices:
                    w=max(0,min(1,(.20-(lace.matrix_world@v.co).z)/.10));shin.add([v.index],1-w,'REPLACE')
                    if w>0:foot.add([v.index],w,'REPLACE')
    return rig,joints


def animation(rig,joints):
    rig.animation_data_create()
    foot_points={}
    for suffix in ('L','R'):
        name='foot.'+suffix
        foot_points[suffix]=[obj.matrix_world@v.co-Vector(joints[name][0]) for obj in PARTS for v in obj.data.vertices
                            if any(obj.vertex_groups[g.group].name==name and g.weight>.999 for g in v.groups)]
    for clip_name,(duration,loop) in CLIPS.items():
        spec=firearms.SPECS.get(clip_name)
        clip='fire' if spec and spec['stage']=='fire' else 'aim' if spec else clip_name
        action=bpy.data.actions.get(clip_name)
        if action:
            continue
        action=bpy.data.actions.new(clip_name); action.use_fake_user=True
        rig.animation_data.action=action
        frames=round(duration*30)
        for frame in range(frames+1):
            t=frame/frames; phase=math.tau*t
            targets={n:[Vector(a),Vector(b)] for n,(a,b,_) in joints.items()}
            crouch=clip in ('crouch','crouch_walk','deploy')
            moving=clip in ('walk','run','crouch_walk','haul')
            bend=math.sin(math.pi*t) if clip in ('pickup','deploy') else 0
            recoil=math.exp(-t*12)*math.sin(t*math.pi*4) if clip=='fire' else 0
            if spec:recoil*=firearms.POSE[spec['group']]['recoil_gain']
            hit=math.sin(math.pi*t)*.12 if clip=='hit' else 0
            drop=.44 if clip=='deploy' else .36 if crouch else .13 if clip=='run' else .06 if moving else 0
            bob=(.028 if clip=='run' else .014)*math.cos(phase*2) if moving else .004*(math.sin(phase)-1)
            shift=Vector((.014*math.sin(phase) if moving else 0,-bend*.10-recoil*.03, -drop-bend*(.65 if clip=='pickup' else .21)+bob))
            for name in targets:
                if name!='root': targets[name]=[p+shift for p in targets[name]]
            # Torso lean about the pelvis; legs are recomputed with foot contacts.
            lean=(.35 if crouch else .1 if clip=='run' else .035)+bend*(.915 if clip=='pickup' else .65)-hit
            pivot=targets['pelvis'][0]
            rotation=Matrix.Rotation(-lean,3,'X')
            for name in targets:
                if name=='root' or name.startswith(('thigh','shin','foot')): continue
                targets[name]=[pivot+rotation@(p-pivot) for p in targets[name]]
            aiming=clip in ('aim','fire')
            holding=clip in ('idle','walk','run','aim','fire','crouch','crouch_walk','hit')
            lift=firearms.raised(spec['stage'],t) if spec else float(aiming)
            if holding:
                # Protract the support shoulder while keeping the clavicle
                # length. Tilt the head toward the stock's sight line.
                left_angle=(-22*(1-lift)+firearms.POSE[spec['group']]['support_shoulder_deg']*lift) if spec else -15 if aiming else -22
                for suffix,angle in [('L',left_angle),('R',-8)]:
                    name='clavicle.'+suffix;a,b=targets[name]
                    targets[name]=[a,a+Matrix.Rotation(math.radians(angle),3,'Z')@(b-a)]
                    targets['upper_arm.'+suffix][0]=targets[name][1].copy()
                if aiming:
                    neck=targets['neck'][0]
                    cant=firearms.POSE[spec['group']]['head_cant'] if spec else .37
                    tilt=Matrix.Rotation(cant*lift,3,'Y')@Matrix.Rotation(-.24*lift,3,'X')
                    for name in ('neck','head'):targets[name]=[neck+tilt@(p-neck) for p in targets[name]]
            firearm_hands={}
            if spec:
                profile=firearms.POSE[spec['group']]
                representative=spec.get('gun') or next(g for g in firearms.GROUPS if firearms.GROUPS[g]==spec['group'])
                yaw=math.radians(20);down=math.radians(10)
                low_direction=rotation@Vector((-math.sin(yaw)*math.cos(down),math.cos(yaw)*math.cos(down),-math.sin(down)))
                low=pivot+rotation@(Vector((.17,.30,1.34))+shift-pivot)
                head_a,head_b=targets['head'];rest=rig.data.bones['head'].matrix_local
                head_q=(Vector(joints['head'][1])-Vector(joints['head'][0])).normalized().rotation_difference((head_b-head_a).normalized())@rest.to_quaternion()
                eye=Matrix.LocRotScale(head_a,head_q,Vector((1,1,1)))@Vector((.037,.139,-.106))
                # Match the actual head-local eye height; horizontal sight line
                # allows the eye to remain behind the gun along the barrel axis.
                high=Vector((eye.x,profile['forward']+shift.y,eye.z-profile['sight_height']))
                right=low.lerp(high,lift);direction=low_direction.lerp(Vector((0,1,0)),lift).normalized()
                orient=Vector((0,1,0)).rotation_difference(direction)
                support=firearms.SUPPORT[representative]
                left=right+orient@Vector((support[0],-support[2],support[1]))
                if spec['stage']=='reload':
                    point=firearms.RELOAD[representative]
                    reach=right+orient@Vector((point[0],-point[2],point[1]))
                    left=left.lerp(reach,firearms.contact(t))
                firearm_hands={'R':(right,direction),'L':(left,direction)}
            for suffix,side in [('L',-1),('R',1)]:
                thigh='thigh.'+suffix; shin='shin.'+suffix; foot='foot.'+suffix
                hip=Vector(joints[thigh][0])+shift
                leg_phase=(phase+(0 if side==1 else math.pi))%math.tau
                wave=math.sin(leg_phase)
                stride=(.28 if clip=='walk' else .40 if clip=='run' else .18) if moving else 0
                ankle=Vector((side*.135,wave*stride,.14+max(0,math.cos(phase+(0 if side==1 else math.pi)))*(.13 if clip=='run' else .065))) if moving else Vector(joints[shin][1])
                pitch=0
                if moving:
                    if math.pi/2<=leg_phase<=math.pi*1.5:
                        stance=(leg_phase-math.pi/2)/math.pi
                        pitch=math.radians(12)*max(0,1-stance/.25)-math.radians(18)*max(0,(stance-.70)/.30)
                    else:
                        swing=((leg_phase-math.pi*1.5)%math.tau)/math.pi
                        degrees=-18+26*swing/.25 if swing<.25 else 8+4*(swing-.75)/.25 if swing>.75 else 8
                        pitch=math.radians(degrees)
                    ankle.z+=max(0,-(.14+min((Matrix.Rotation(pitch,3,'X')@p).z for p in foot_points[suffix])))
                # Analytic two-bone knee solve with fixed segment lengths.
                upper=(Vector(joints[thigh][1])-Vector(joints[thigh][0])).length
                lower=(Vector(joints[shin][1])-Vector(joints[shin][0])).length
                knee=solve_joint(hip,ankle,upper,lower,Vector((0,1,0)))
                targets[thigh]=[hip,knee]; targets[shin]=[knee,ankle]
                targets[foot]=[ankle,ankle+Matrix.Rotation(pitch,3,'X')@Vector((0,.18,-.06))]
                shoulder=targets['upper_arm.'+suffix][0]
                # Both palms lie on the rifle grip axis, 0.26 m apart.
                hand=Vector((.12 if aiming else .035, (.28 if side==1 else .54) if aiming else (.24 if side==1 else .50),1.56 if aiming else 1.22))+shift
                hand_direction=Vector((0,1,0))
                if holding and not aiming:
                    yaw=math.radians(20);pitch=math.radians(10)
                    direction=Vector((-math.sin(yaw)*math.cos(pitch),math.cos(yaw)*math.cos(pitch),-math.sin(pitch)))
                    base=Vector((.17,.30,1.34))+shift
                    if side==-1:base+=direction*.26
                    hand=pivot+rotation@(base-pivot);hand_direction=rotation@direction
                if aiming: hand.y-=recoil*.07
                if clip in ('pickup','deploy'):hand=hand.lerp(Vector((side*.10,.57,.065 if clip=='pickup' else .075)),bend)
                if clip=='haul': hand=Vector((side*.06,.35,1.06))+shift
                if clip=='run': hand.z+=.035*math.sin(phase)
                if clip=='death':
                    tuck=min(t/.75,1)
                    hand=hand.lerp(Vector((side*.23,.025,1.12))+shift,tuck)
                if spec:hand,hand_direction=firearm_hands[suffix]
                upper=(Vector(joints['upper_arm.'+suffix][1])-Vector(joints['upper_arm.'+suffix][0])).length
                lower=(Vector(joints['forearm.'+suffix][1])-Vector(joints['forearm.'+suffix][0])).length
                delta=hand-shoulder
                if delta.length>upper+lower-.001: hand=shoulder+delta.normalized()*(upper+lower-.001)
                elbow=solve_joint(shoulder,hand,upper,lower,Vector((side*.65,-.15,-1)))
                targets['upper_arm.'+suffix]=[shoulder,elbow]
                targets['forearm.'+suffix]=[elbow,hand]
                targets['hand.'+suffix]=[hand,hand+hand_direction*.09]
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
                skin={name:matrices[name]@rig.data.bones[name].matrix_local.inverted() for name in joints}
                bottom=min(sum(g.weight*(skin[obj.vertex_groups[g.group].name]@obj.matrix_world@v.co).z
                               for g in v.groups) for obj in PARTS for v in obj.data.vertices)
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
    pistol=family=='pistol'; rifle=family in ('rifle','scout');end=length-(.07 if pistol else .275 if rifle else .32)
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
            stock=box('shoulder_stock',(.053,.185 if rifle else .245,.110),(0,-.175 if rifle else -.21,-.012),stock_tile,None,.012); stock.rotation_euler.x=-.10
            box('buttplate',(.058,.014,.114),(0,-.274 if rifle else -.332,-.002),3,None,.004)
            if rifle:box('stock_wrist',(.043,.13,.044),(0,-.028,-.022),stock_tile,None,.005)
            elif family in ('smg','mg'):
                grip=box('pistol_grip',(.039,.058,.11),(0,-.032,-.055),stock_tile,None,.005);grip.rotation_euler.x=-.20
        box('receiver',(.052,.20,.062) if rifle else (.056,.25,.066),(0,.035,.040) if rifle else (0,.025,.035),3,None,.007)
        box('fore_stock',(.052,.28,.042),(0,.257,.012),stock_tile,None,.008)
        tube('barrel',(0,.21,.045),(0,end,.045),.018,.011,3,None,12,2,0)
        box('front_sight',(.018,.011,.038),(0,end-.025,.073),3,None,.002)
        box('rear_sight',(.031,.025,.021),(0,.055,.077),3,None,.003)
        if asset in ('kar98k','kar98k_zf','springfield'):
            tube('bolt',(0,.046,.053),(.065,.046,.053),.006,.006,3,None,8,1,0)
            ellipsoid('bolt_knob',(.012,.012,.012),(.07,.046,.053),3,None,10,6)
        if asset=='m1_garand':
            box('operating_rod_handle',(.020,.055,.018),(.038,.045,.048),3,None,.002)
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
        # Hangers connect to the actual stock surface. The old front box was
        # 22 mm below the wood and visibly floated in grip close-ups.
        for y,z in [(-.20,-.058 if asset=='mp40' else -.069),(.33,-.011)]:
            box('sling_base',(.066 if asset=='mp40' and y<0 else .032,.016,.007),(0,y,z),3,None,.001)
            for x in (-.020,.020):box('sling_loop_side',(.004,.010,.020),(x,y,z-.014),3,None,.001)
            box('sling_loop_bridge',(.044,.010,.004),(0,y,z-.024),3,None,.001)
    # Open trigger guard is a four-sided hoop rather than an opaque rectangle.
    for x in (-.014,.014): box('trigger_guard',(.005,.060,.007),(x,.015,-.046),3,None,.002)
    for y in (-.017,.047): box('trigger_guard_end',(.033,.006,.030),(0,y,-.033),3,None,.002)
    box('trigger',(.005,.011,.025),(0,.008,-.029),3,None,.001)
    return {'grip':[0,0,0],'muzzle':[0,.035 if pistol else .045,-end],
            'support_hand':[0,0,-.26] if not pistol else None,
            'pose_support':firearms.SUPPORT[asset],'sight':firearms.SIGHT[asset],
            'reload_contact':firearms.RELOAD[asset]}


def tool(asset):
    kit.CURRENT=asset
    if asset=='knife':
        box('grip',(.030,.105,.023),(0,-.02,0),4,None,.005)
        box('guard',(.072,.012,.009),(0,.035,0),3,None,.002)
        outline=[(-.0135,.041),(.0135,.041),(.0135,.178),(0,.238),(-.0135,.178)]
        verts=[(x,y,z) for z in (-.0015,.0015) for x,y in outline]
        faces=[tuple(reversed(range(5))),tuple(range(5,10))]+[(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)]
        data=bpy.data.meshes.new('blade');data.from_pydata(verts,[],faces);data.update()
        obj=bpy.data.objects.new('blade',data);bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
        finish(obj,'blade',3)
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
        for x in (-.04,.04):box('handle_riser',(.014,.02,.045),(x,-.06,.138),4,None,.002)
        box('handle',(.095,.025,.015),(0,-.06,.165),4,None,.002)
    elif asset=='ammo_pack':
        box('satchel',(.33,.20,.22),(0,0,.13),9,None,.025)
        for x in (-.105,.105): box('strap',(.034,.211,.018),(x,0,.248),4,None,.003)
        for x in (-.06,.06):box('handle_riser',(.02,.022,.052),(x,0,.27),4,None,.003)
        box('handle',(.14,.025,.018),(0,0,.30),4,None,.003)
    return {'knife':{'grip':[0,0,0],'tip':[0,0,-.238]},
            'grenade':{'grip':[0,.064,0],'fuse':[0,.145,0]},
            'mine':{'grip':[.115,.085,0],'pressure_plate':[0,.085,0]},
            'decoy':{'grip':[0,.165,.06],'speaker':[0,.122,-.02]},
            'ammo_pack':{'grip':[.06,.30,0],'support_hand':[-.06,.30,0]}}[asset]


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
    return {'path':f'art/v2/models/{path.name}','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'triangles':tris,'surfaces':surfaces}


def clean_mesh(obj):
    # Decimate on n-gons can collapse opposite faces into duplicate polygons.
    # Triangulate first and validate the *result*, including corner/UV arrays.
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=list(bm.faces),quad_method='FIXED',ngon_method='EAR_CLIP')
    bmesh.ops.dissolve_degenerate(bm, dist=1e-7, edges=list(bm.edges))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data); bm.free()
    changed=obj.data.validate(clean_customdata=False)
    obj.data.update()
    assert not obj.data.validate(clean_customdata=False), obj.name
    if changed: print('MESH_REPAIRED',obj.name,flush=True)


def prepare_mesh(obj, budget):
    clean_mesh(obj)
    obj.data.calc_loop_triangles()
    count=len(obj.data.loop_triangles)
    obj.data.calc_loop_triangles()
    assert len(obj.data.loop_triangles)<=budget, (obj.name,len(obj.data.loop_triangles),budget)
    # Preserve each corner's atlas tile and deterministically project
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
    global PARTS,DETAIL_LEVEL,DETAIL_KIND
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.context.scene.render.fps=30
    bpy.context.scene.unit_settings.system='METRIC'
    atlas(); entries=[]
    # Retire only the misidentified WIP candidate; the game has no heavy enemy.
    for level in range(3): (OUT/'models'/f'enemy_heavy_lod{level}.glb').unlink(missing_ok=True)
    for asset in [*CHARACTERS,*GUNS,'knife','grenade','mine','decoy','ammo_pack']:
        PARTS=[]; rig=None; sockets={};DETAIL_LEVEL=0 if asset in CHARACTERS else None
        DETAIL_KIND='character' if asset in CHARACTERS else 'equipment'
        if asset in CHARACTERS:
            rig,joints=character(asset,*CHARACTERS[asset]); category='character'
            animation(rig,joints)
            sockets={'weapon_hand':{'bone':'hand.R','position_bone_local_m':[0,.035,0],
                       'rotation_bone_local_deg':[90,0,0]},
                     'support_hand':{'bone':'hand.L','position_bone_local_m':[0,.035,0],
                       'rotation_bone_local_deg':[90,0,0]},
                     'sight_eye':{'bone':'head','position_bone_local_m':[.037,.139,-.106]}}
        elif asset in GUNS:
            sockets=weapon(asset,*GUNS[asset]); category='weapon'
        else: sockets=tool(asset); category='tool'
        mesh=kit.join_parts(PARTS,asset+'_body')
        if category=='tool' and asset!='knife':
            floor=min(v.co.z for v in mesh.data.vertices)
            mesh.data.transform(Matrix.Translation((0,0,-floor)))
            mesh.data.update()
            for point in sockets.values():point[1]-=floor
        prepare_mesh(mesh,LOD_BUDGET[category][0])
        if rig:
            mesh.parent=rig; modifier=mesh.modifiers.new('SharedSkin','ARMATURE'); modifier.object=rig
        collection=bpy.data.collections.new(asset); bpy.context.scene.collection.children.link(collection)
        originals=[mesh]+([rig] if rig else [])
        if category in ('weapon','tool'):
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
        mesh['lod']=0
        for level,budget in enumerate(LOD_BUDGET[category][1:],1):
            if rig:
                PARTS=[];DETAIL_LEVEL=level
                character(asset,*CHARACTERS[asset],rig,joints)
                copy=kit.join_parts(PARTS,asset+f'_body_lod{level}')
                for old in list(copy.users_collection):old.objects.unlink(copy)
                collection.objects.link(copy)
                copy.parent=rig;modifier=copy.modifiers.new('SharedSkin','ARMATURE');modifier.object=rig
                copy['lod']=level
            else:
                PARTS=[];DETAIL_LEVEL=level
                if asset in GUNS:weapon(asset,*GUNS[asset])
                else:tool(asset)
                copy=kit.join_parts(PARTS,asset+f'_body_lod{level}')
                if category=='tool' and asset!='knife':
                    copy.data.transform(Matrix.Translation((0,0,-floor)));copy.data.update()
                for old in list(copy.users_collection):old.objects.unlink(copy)
                collection.objects.link(copy)
            bpy.context.view_layer.objects.active=copy
            # Every LOD is generated directly; no symmetric collapse ties.
            prepare_mesh(copy,budget)
            lods.append(export(asset,[copy]+[o for o in originals if o!=mesh],level,rig is not None))
            if rig:copy.hide_render=True;copy.hide_set(True)
            else:bpy.data.objects.remove(copy,do_unlink=True)
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
            'lod_generation':'Constructive tessellation and feature tiers; no Decimate',
            'validation_scene':'res://ArtSource/v2/actor_acceptance/review.gd','status':'repaired candidate; acceptance report required'})
        # Hide other collections in Blender viewport; exports use selection only.
        for obj in originals: obj.hide_set(True)
        print('ACTOR_ASSET',asset,[(x['triangles'],x['surfaces']) for x in lods],flush=True)
    manifest={'schema':2,'seed':SEED,'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'firearm_contract_sha256':hashlib.sha256((HERE/'actor_acceptance/firearm_contract.py').read_bytes()).hexdigest(),
              'canonicalizer_sha256':hashlib.sha256((HERE/'actor_acceptance/canonicalize.py').read_bytes()).hexdigest(),'assets':entries,
              'textures':[{'path':f'art/v2/textures/{p.name}','sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted((OUT/'textures').glob('actor_*.png'))]}
    CATALOG.write_text(json.dumps(manifest,indent=2)+'\n')
    (CATALOG.parent/'firearm_profiles_candidate.json').write_text(json.dumps(firearms.candidate(),indent=2)+'\n')
    for img in bpy.data.images:
        if img.filepath: img.pack()
    for obj in bpy.data.objects: obj.hide_set(obj.get('lod',0)>0)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_SOURCE))
    print('ACTOR_KIT_EXPORTED',len(entries),flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--output-root',type=Path,required=True,help='Independent project root; no shared manifest is written')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    OUT=args.output_root.resolve()/'art/v2';OUT.joinpath('models').mkdir(parents=True,exist_ok=True)
    kit.TEX=OUT/'textures';kit.TEX.mkdir(parents=True,exist_ok=True)
    CATALOG=args.output_root.resolve()/'catalog_candidate.json'
    BLEND_SOURCE=args.output_root.resolve()/'actors.blend'
    build()
