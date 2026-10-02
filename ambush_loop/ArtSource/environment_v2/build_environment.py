#!/usr/bin/env python3
"""Original deterministic environment candidates. Blender 4.3.2, no external assets.
Run blender -b -t 2 --python .../build_environment.py -- --output /tmp/env-a
Default output is ONLY art/environment_v2. No modifications to shared assets.
"""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy, bmesh, numpy as np
from mathutils import Vector
HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
args = argparse.ArgumentParser()
args.add_argument('--output', type=Path, default=PROJECT/'art/environment_v2')
args.add_argument('--only', default='')
OPT = args.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
OUT = OPT.output.resolve()
SEED = 2601002
PARTS=[]; SOCKETS={}; MOVING={}; CURRENT=''; LOD=0; GROUP='shell'
ATLAS=None; GLOW=None

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def image(name, values, cs):
    h,w=values.shape[:2]; rgba=np.ones((h,w,4),np.float32); rgba[:,:,:3]=values
    im=bpy.data.images.new(name,width=w,height=h,alpha=False); im.colorspace_settings.name=cs
    im.pixels.foreach_set(rgba.ravel()); im.filepath_raw=str(OUT/'textures'/(name+'.png')); im.file_format='PNG'; im.save()
    return im

def materials():
    global ATLAS,GLOW
    rng=np.random.default_rng(SEED); n=256; y,x=np.mgrid[:n,:n]/n
    rgb=np.zeros((1024,1024,3),np.float32); norm=np.zeros_like(rgb); orm=np.zeros_like(rgb)
    # pine, steel, olive enamel, brick, plaster, concrete, rubber, rust,
    # brass, gauge, cobble, earth, ballast, corrugated zinc, stencil, tar.
    palette=[(.28,.235,.175),(.19,.205,.215),(.22,.265,.215),(.36,.235,.185),(.47,.465,.42),(.34,.365,.365),(.045,.048,.05),(.29,.14,.065),(.38,.30,.14),(.66,.63,.51),(.255,.26,.245),(.24,.215,.17),(.245,.26,.275),(.27,.30,.32),(.61,.59,.49),(.13,.145,.155)]
    for k,col in enumerate(palette):
        fine=rng.random((n,n))-.5
        broad=.4*np.sin(x*21+np.sin(y*11)*2)+.3*np.cos(x*49-y*23)
        v=broad*.025+fine*.07; h=fine*.001; rough=np.full_like(x,.82)+fine*.05; metal=np.zeros_like(x)
        if k==0:
            grain=np.sin(y*190+np.sin(x*15)*3); v+=grain*.05; h+=grain*.002; rough+=grain*.02
        if k in (1,8,13):
            # Subtle oxidised metal response; broad metallic islands create
            # false camouflage and are not directional lighting or decals.
            metal[:]=.55; rough[:]=.74+broad*.025+fine*.025
            h=fine*.0005
        if k==2:
            # Enamel is painted metal: retain mostly dielectric, matte response.
            # Strong metallic/roughness islands read as camouflage under Godot.
            metal[:]=.10; rough[:]=.78+broad*.02+fine*.015
            h=fine*.0005
        if k==7:
            metal[:]=0.0; rough[:]=.94+fine*.02; h=fine*.001
        if k==3:
            row=np.floor(y*24); seam=((x*8+(row%2)*.5)%1<.045)|((y*24)%1<.10)
            v+=np.sin(row*17+np.floor(x*8)*13)*.085; h+=np.where(seam,-.035,.002)
        if k==10:
            # Rounded, closely spaced paving stones; real height in normal only.
            xx=(x*14)%1-.5; yy=(y*14)%1-.5
            edge=np.maximum(abs(xx),abs(yy))
            stonecolors=np.random.default_rng(SEED+310).uniform(-.075,.075,(14,14))
            v+=stonecolors[(y*14).astype(int),(x*14).astype(int)]
            v[edge>.48]-=.08
            h+=np.clip(.48-edge,0,.055)*.22
        if k==12:
            # Periodic jittered Voronoi aggregate, not a square cobble grid.
            ncell=24; best=np.full_like(x,1e9); second=best.copy(); color_id=np.zeros_like(x)
            weights=rng.random(ncell*ncell)*.14-.07
            for i in range(ncell*ncell):
                px=(i%ncell)+.5+rng.uniform(-.37,.37); py=(i//ncell)+.5+rng.uniform(-.37,.37)
                dx=(x*ncell-px+ncell/2)%ncell-ncell/2; dy=(y*ncell-py+ncell/2)%ncell-ncell/2
                dist=np.sqrt(dx*dx+dy*dy); nearer=dist<best
                second=np.where(nearer,best,np.minimum(second,dist)); best=np.minimum(best,dist); color_id=np.where(nearer,weights[i],color_id)
            border=second-best<.06
            v=color_id+fine*.075; v[border]-=.10
            h=np.maximum(0,.60-best)*.016; h[border]=-.001
        if k==11:
            h=fine*.012+broad*.002; v=fine*.11+broad*.035
        if k==9:
            rad=np.sqrt((x-.5)**2+(y-.5)**2); ang=np.arctan2(y-.5,x-.5)
            scale=(rad>.31)&(rad<.39)&(np.sin(ang*24)>.5)
            needle=(abs(x-.5-(y-.5)*.35)<.007)&(y>.30)&(y<.73)
            v[scale|needle]=-.90; rough[:]=.65
        color=np.clip(np.array(col)[None,None,:]*(1+v[:,:,None]),.012,.90)
        if k==3: color[seam]=(.30,.31,.29)
        dy,dx=np.gradient(h); vec=np.stack((-dx*8,-dy*8,np.ones_like(h)),axis=2); vec/=np.linalg.norm(vec,axis=2)[:,:,None]
        packed=np.stack((np.ones_like(x),np.clip(rough,.15,1),metal),axis=2)
        idx=np.clip(np.arange(n),5,n-6); r,c=divmod(k,4); sl=np.s_[r*n:(r+1)*n,c*n:(c+1)*n]
        rgb[sl]=color[idx[:,None],idx[None,:]]; norm[sl]=(vec*.5+.5)[idx[:,None],idx[None,:]]; orm[sl]=packed[idx[:,None],idx[None,:]]
    al=image('environment_v2_albedo',rgb,'sRGB'); no=image('environment_v2_normal',norm,'Non-Color'); oc=image('environment_v2_orm',orm,'Non-Color')
    ATLAS=bpy.data.materials.new('environment_v2_atlas'); ATLAS.use_nodes=True; ATLAS.use_backface_culling=True
    nodes,links=ATLAS.node_tree.nodes,ATLAS.node_tree.links; bs=nodes.get('Principled BSDF')
    for im,typ in [(al,'base'),(no,'normal'),(oc,'orm')]:
        t=nodes.new('ShaderNodeTexImage'); t.image=im
        if typ=='base': links.new(t.outputs['Color'],bs.inputs['Base Color'])
        elif typ=='normal':
            n=nodes.new('ShaderNodeNormalMap'); links.new(t.outputs['Color'],n.inputs['Color']); links.new(n.outputs['Normal'],bs.inputs['Normal'])
        else:
            n=nodes.new('ShaderNodeSeparateColor'); links.new(t.outputs['Color'],n.inputs['Color']); links.new(n.outputs['Green'],bs.inputs['Roughness']); links.new(n.outputs['Blue'],bs.inputs['Metallic'])
    GLOW=bpy.data.materials.new('environment_v2_emission'); GLOW.use_nodes=True; GLOW.use_backface_culling=True
    bs=GLOW.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(1,.68,.27,1); bs.inputs['Emission Color'].default_value=(1,.45,.12,1); bs.inputs['Emission Strength'].default_value=1.4

def finish(o,name,tile,bevel=0):
    o.name=CURRENT+'__'+name; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel and LOD==0:
        m=o.modifiers.new('edge','BEVEL'); m.width=bevel; m.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=m.name)
    bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(o.data); bm.free()
    if not o.data.uv_layers:
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.smart_project(island_margin=.01); bpy.ops.object.mode_set(mode='OBJECT')
    o.data.materials.clear(); o.data.materials.append(GLOW if tile==-1 else ATLAS)
    if tile>=0:
        r,c=divmod(tile,4)
        for u in o.data.uv_layers.active.data: u.uv=((c+.035+u.uv.x*.93)/4,(r+.035+u.uv.y*.93)/4)
    o['group']=GROUP; PARTS.append(o); return o

def box(name,size,at,tile=1,bevel=.005):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at); o=bpy.context.object; o.dimensions=size
    for p in o.data.polygons:
        ax=max(range(3),key=lambda i:abs(p.normal[i])); a,b=((1,2),(0,2),(0,1))[ax]
        for li in p.loop_indices:
            co=o.data.vertices[o.data.loops[li].vertex_index].co; o.data.uv_layers.active.data[li].uv=(co[a]+.5,co[b]+.5)
    return finish(o,name,tile,bevel)

def cyl(name,r,d,at,tile=1,sides=16,axis=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=max(6,sides//(2 if LOD else 1)),radius=r,depth=d,location=at); o=bpy.context.object
    if axis is not None: o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return finish(o,name,tile)

def rod(name,a,b,r=.02,tile=1,sides=8):
    a,b=Vector(a),Vector(b); return cyl(name,r,(b-a).length,(a+b)/2,tile,sides,b-a)

def ring(name,major,minor,at,tile=1,axis=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=16 if LOD else 20,minor_segments=4 if LOD else 6,location=at,major_radius=major,minor_radius=minor); o=bpy.context.object
    if axis: o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return finish(o,name,tile)

def group(name):
    global GROUP; GROUP=name

def socket(name,at,semantic):
    parent='leaf_pivot' if name=='handle_anchor' and 'leaf_pivot' in MOVING else None
    origin=MOVING[parent]['author_at'] if parent else (0,0,0)
    local=[at[i]-origin[i] for i in range(3)]
    SOCKETS[name]={'parent_node':CURRENT+'__'+parent if parent else CURRENT,'position_m':[local[0],local[2],-local[1]],'rotation_degrees':[0,0,0],'asset_closed_position_m':[at[0],at[2],-at[1]],'semantic':semantic+('; follows actual moving leaf' if parent else '; static asset-root reference')}
def pivot(name,at,kind,axis,value): MOVING[name]={'author_at':at,'position_m':[at[0],at[2],-at[1]],'rotation_degrees':[0,0,0],'motion':kind,'axis':axis,'range':value}
def bolts(y,z,w=.5):
    if LOD: return
    for x in (-w/2,w/2): cyl('bolt',.013,.014,(x,y,z),1,8,(0,1,0))

def crate(w=.9,d=.65,h=.65,ration=False):
    group('shell'); box('floor',(w,d,.08),(0,0,.04),0)
    for y in (-d/2,d/2):
        for j in range(3): box('plank',(w,.065,(h-.08)/3-.014),(0,y,.10+j*(h-.08)/3+(h-.08)/6),0)
    for x in (-w/2,w/2):
        for j in range(3): box('end_plank',(.065,d,(h-.08)/3-.014),(x,0,.10+j*(h-.08)/3+(h-.08)/6),0)
    for x in (-w*.35,w*.35):
        for y in (-d/2-.04,d/2+.04): box('iron_strap',(.045,.012,h),(x,y,h/2),1,.001)
    box('front_stencil',(.26,.008,.12),(0,d/2+.038,h*.55),14,.001)
    # Stencil is neutral non-branded bar pattern, not gameplay text.
    for i in range(3 if ration else 2): box('stencil_mark',(.012,.010,.075),(-.075+i*.065,d/2+.045,h*.55),2,.001)
    pivot('lid_pivot',(0,-d/2,h),'rotate','X',[0,105]); group('lid_pivot')
    for i in range(4): box('lid_plank',(w,d/4-.012,.06),(0,-d/2+(i+.5)*d/4,h+.025),0)
    for x in (-w*.35,w*.35): box('lid_strap',(.045,d,.012),(x,0,h+.063),1,.001)
    group('shell')
    for x in (-w*.3,w*.3): cyl('hinge',.022,.11,(x,-d/2-.018,h),1,12,(1,0,0))
    box('latch',(.06,.025,.12),(0,d/2+.048,h-.07),1)
    socket('loot_anchor',(0,0,h+.12),'display pickup point, game loot identity remains external')

def ammo_can():
    group('shell'); box('can_floor',(.48,.26,.02),(0,0,.01),2,.004)
    for y in (-.12,.12): box('can_wall',(.48,.02,.30),(0,y,.17),2,.005)
    for x in (-.23,.23): box('can_end',(.02,.22,.30),(x,0,.17),2,.005)
    for x in (-.22,.22): box('folded_seam',(.015,.27,.31),(x,0,.16),1,.002)
    box('latch',(.055,.024,.08),(0,.145,.28),1)
    pivot('lid_pivot',(0,-.13,.32),'rotate','X',[0,100]); group('lid_pivot'); box('lid',(.5,.28,.025),(0,0,.334),2)
    for x in (-.09,.09): rod('handle_foot',(x,0,.35),(x,0,.4),.01)
    rod('handle',(-.09,0,.4),(.09,0,.4),.012)
    group('shell'); bolts(.145,.13,.32); socket('loot_anchor',(0,0,.44),'ammo container pickup anchor')

def gun_case(): crate(1.35,.34,.26)
def handcart():
    box('tray',(1.05,.7,.09),(0,0,.49),0)
    for x in (-.5,.5): box('side',(.07,.72,.28),(x,0,.67),0)
    for y in (-.33,.33): box('end',(1.08,.055,.28),(0,y,.67),0)
    rod('axle',(-.68,0,.32),(.68,0,.32),.04)
    for x in (-.63,.63):
        ring('wheel',.255,.052,(x,0,.31),6,(1,0,0)); cyl('hub',.08,.12,(x,0,.31),1,12,(1,0,0))
        for a in range(4 if LOD else 8):
            t=a*math.tau/(4 if LOD else 8); rod('spoke',(x,0,.31),(x,math.sin(t)*.23,.31+math.cos(t)*.23),.012)
    for x in (-.4,.4): rod('handle',(x,-.26,.5),(x,-1.35,.6),.035,0)
    rod('grip',(-.4,-1.35,.6),(.4,-1.35,.6),.027,0)
    for x in (-.4,.4): rod('leg',(x,-.26,.47),(x,-.42,.02),.025)
    socket('cargo_anchor',(0,0,.81),'decorative cargo only; no new inventory logic')

def jerry_can():
    box('pressed_can',(.36,.2,.47),(0,0,.235),2,.026)
    for y in (-.105,.105):
        rod('pressed_rib',(-.12,y,.08),(.12,y,.36),.012,2); rod('pressed_rib',(.12,y,.08),(-.12,y,.36),.012,2)
    for x in (-.11,.11): rod('handle',(x,0,.45),(x,0,.54),.021,2)
    rod('grip',(-.11,0,.54),(.11,0,.54),.022,2)
    cyl('filler_cap',.04,.025,(.10,.052,.48),1,12); socket('pickup_anchor',(0,0,.55),'ground decoration or external pickup mapping')

def spare_tire():
    ring('rubber_tire',.31,.105,(0,0,.415),6,(0,1,0)); cyl('steel_wheel',.205,.11,(0,0,.415),1,24,(0,1,0))
    cyl('hub',.06,.14,(0,.012,.415),1,12,(0,1,0))
    for i in range(12 if LOD else 24):
        a=i*math.tau/(12 if LOD else 24); o=box('tread',(.055,.185,.025),(math.sin(a)*.408,0,.415+math.cos(a)*.408),6,.002); o.rotation_euler.y=a

def wooden_barrel():
    count=12 if LOD else 18
    zs=[.04,.29,.59,.83] if LOD else [.04,.20,.36,.53,.70,.83]
    rs=[.245,.30,.30,.245] if LOD else [.245,.28,.30,.30,.275,.245]
    for i in range(count):
        a=i*math.tau/count; delta=math.pi/count*.975
        verts=[]; faces=[]
        for z,r in zip(zs,rs):
            for radius,t in [(r,a-delta),(r,a+delta),(r-.028,a-delta),(r-.028,a+delta)]:
                verts.append((math.cos(t)*radius,math.sin(t)*radius,z))
        for j in range(len(zs)-1):
            b=j*4; c=b+4
            faces.extend([(b,b+1,c+1,c),(b+3,b+2,c+2,c+3),(b+2,b,c,c+2),(b+1,b+3,c+3,c+1)])
        faces.extend([(0,2,3,1),tuple((len(zs)-1)*4+x for x in (0,1,3,2))])
        mesh=bpy.data.meshes.new('coopered_stave');mesh.from_pydata(verts,[],faces);mesh.update()
        o=bpy.data.objects.new('stave',mesh);bpy.context.collection.objects.link(o);bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;finish(o,'stave',0)
    for z in (.12,.28,.62,.76):
        r=float(np.interp(z,zs,rs));ring('hoop',r+.010,.009,(0,0,z),1)
    cyl('barrel_top',.242,.035,(0,0,.837),0,20)
    cyl('bottom',.242,.05,(0,0,.025),0,20)
    cyl('bung',.032,.01,(.07,.06,.86),0,12)

def fence():
    for x in (-1,1): box('post',(.07,.08,2),(x,0,1),1)
    for z in (.35,1.70): box('rail',(2.06,.05,.05),(0,0,z),1)
    # Physical wire thickness survives medium view; lower LOD retains silhouette.
    step=.23 if LOD else .145
    for i in range(int(2/step)+1):
        x=-1+i*step; rod('mesh_vertical',(x,0,.38),(x,0,1.69),.006 if not LOD else .009,1,6)
    for z in np.arange(.43,1.69,step): rod('mesh_horizontal',(-.98,0,z),(.98,0,z),.006 if not LOD else .009,1,6)

def wire():
    points=[]; count=45 if LOD else 90
    for i in range(count+1):
        t=i/count; points.append((-1+t*2,math.sin(t*math.tau*5)*.22,.26+math.cos(t*math.tau*5)*.22))
    for a,b in zip(points,points[1:]): rod('concertina',a,b,.009,1,6)
    if not LOD:
        for i in range(8,count,12):
            x,y,z=points[i]; rod('barb',(x-.03,y-.035,z-.03),(x+.03,y+.035,z+.03),.009,1,6)

def wall(w=2,plaster=False):
    box('masonry',(w,.24,3),(0,0,1.5),3,.009)
    box('interior_finish',(w-.025,.018,2.62),(0,-.13,1.54),4,.002)
    for z in (.13,2.92): box('concrete_course',(w,.30,.16),(0,0,z),5)
    if plaster: box('exterior_finish',(w-.06,.02,2.62),(0,.132,1.54),4)
    if not LOD:
        for x in (-w/2+.10,w/2-.10): box('pier',(.18,.29,2.70),(x,0,1.54),3)

def corner():
    wall(); ostart=len(PARTS); wall()
    for o in PARTS[ostart:]:
        o.location=Vector((0,0,0))+Vector((-o.location.y-.88,o.location.x+.88,o.location.z)); o.rotation_euler.z+=math.pi/2

def window():
    box('sill_wall',(2,.24,.96),(0,0,.48),3)
    for x in (-.86,.86): box('pier',(.28,.24,3),(x,0,1.5),3)
    box('header',(1.44,.24,.58),(0,0,2.71),3)
    for z in (.92,2.42): box('frame',(1.52,.32,.08),(0,0,z),1)
    for x in (-.73,.73,0): box('mullion',(.06,.12,1.50),(x,.09,1.67),1)
    box('crossbar',(1.5,.11,.05),(0,.09,1.67),1)
    # Open glazing: no transparency cost, no fake view-blocking pane.
    box('stone_sill',(1.66,.40,.10),(0,0,.89),5)
    box('inside_header',(1.4,.018,.48),(0,-.131,2.70),4)

def door_frame(w=2,opening=1.2,height=2.4):
    pier=(w-opening)/2
    for x in (-w/2+pier/2,w/2-pier/2): box('jamb',(pier,.30,3),(x,0,1.5),3)
    group('lintel'); box('lintel',(opening,.3,3-height),(0,0,height+(3-height)/2),3)
    box('steel_lintel',(opening+.12,.36,.09),(0,0,height+.01),1)
    group('shell'); socket('door_hinge',(-opening/2,0,0),'hinge alignment for separate door leaf, no navigation change')
    socket('door_clearance',(0,0,0),'clear visual opening; logical door cell assigned by integrator')

def door_leaf(w=1.2,h=2.35,sliding=False):
    pivot('leaf_pivot',(-w/2,0,0),'translate' if sliding else 'rotate','X' if sliding else 'Y',[0,-w] if sliding else [0,100]); group('leaf_pivot')
    box('leaf',(w,.075,h),(0,0,h/2),2)
    for z in (.12,h-.12): box('crossbrace',(w,.025,.08),(0,.052,z),1)
    for x in (-w/2+.045,w/2-.045): box('edging',(.08,.035,h),(x,.048,h/2),1)
    box('handle',(.025,.085,.18),(w*.32,.080,h*.48),1)
    if not LOD:
        for x in np.arange(-w/2+.12,w/2,.16): box('panel_rib',(.025,.015,h-.30),(x,.047,h/2),2,.001)
    socket('handle_anchor',(w*.32,.12,h*.48),'visual interaction point; command authority is external')

def roof(flat=False):
    group('roof')
    if flat:
        box('deck',(4.2,4.2,.12),(0,0,3.1),15)
        for x in (-2,2): box('parapet',(.16,4.2,.25),(x,0,3.25),5)
        for y in (-2,2): box('parapet',(4.2,.16,.25),(0,y,3.25),5)
    else:
        for side in (-1,1):
            o=box('roof_plane',(2.20,4.35,.06),(side*1.045,0,3.40),13); o.rotation_euler.y=side*math.atan(.30)
            for i in range(5 if LOD else 14):
                x=side*(.08+i*2.08/(5 if LOD else 14)); rod('corrugation',(x,-2.17,3.72-abs(x)*.30),(x,2.17,3.72-abs(x)*.30),.018,13,6)
        rod('ridge',(0,-2.2,3.74),(0,2.2,3.74),.05,1)
    socket('roof_anchor',(0,0,3),'removable display roof anchor')

def low_wall():
    box('low_masonry',(2,.38,.9),(0,0,.45),3)
    box('cap',(2.10,.47,.10),(0,0,.94),5)
    for x in (-.94,.94): box('pier',(.24,.45,1.04),(x,0,.52),3)

def gate():
    pivot('leaf_pivot',(-1,0,0),'rotate','Y',[0,110]); group('leaf_pivot')
    for x in (-.96,.96): box('edge',(.08,.07,1.9),(x,0,.95),1)
    for z in (.1,1.84): box('rail',(2,.07,.08),(0,0,z),1)
    for x in np.arange(-.8,.9,.20): box('bar',(.025,.035,1.75),(x,0,.95),1,.002)
    rod('brace',(-.94,0,.16),(.94,0,1.78),.025); socket('handle_anchor',(.80,.09,.95),'gate interaction anchor')

def floor(tile):
    box('tile',(2,2,.10),(0,0,-.05),tile,0)
    if tile==5:
        for x in (-.99,.99): box('joint',(.018,2,.004),(x,0,-.002),15,0)
        for y in (-.99,.99): box('joint',(2,.018,.004),(0,y,-.002),15,0)
    if tile==13:
        for x in np.arange(-.9,1,.15): box('plate_rib',(.012,1.95,.004),(x,0,-.002),1,0)

def drain():
    box('channel',(2,.25,.065),(0,0,-.04),15)
    for i in range(10 if LOD else 20): box('grating',(.03,.28,.025),(-.95+i*1.9/(9 if LOD else 19),0,-.003),1,0)

def curb(): box('curb',(2,.20,.18),(0,0,.09),5)
def debris():
    for i in range(5 if LOD else 9):
        o=box('loose_brick',(.19,.09,.065),(-.8+i*.19,math.sin(i*17)*.13,.034),3); o.rotation_euler.z=i*1.61
    box('loose_board',(1.1,.13,.035),(0,.22,.03),0)

def gable(y):
    verts=[(x,y+dy,z) for dy in (-.12,.12) for x,z in [(-3,3),(3,3),(0,3.9)]]
    mesh=bpy.data.meshes.new('gable');mesh.from_pydata(verts,[],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)]);mesh.update()
    o=bpy.data.objects.new('gable',mesh);bpy.context.collection.objects.link(o);bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;finish(o,'gable',3)

def warehouse_shell():
    # Full 6x4 shell, each elevation independent; 2.8m loading opening, no fake wall behind it.
    group('wall_back'); gable(-2); box('back',(6,.24,3),(0,-2,1.5),3); box('back_finish',(5.95,.018,2.65),(0,-1.87,1.52),4)
    for side,label in [(-1,'wall_left'),(1,'wall_right')]:
        group(label); box('side',(.24,4,3),(side*3,0,1.5),3); box('inside',(.018,3.95,2.65),(side*2.87,0,1.52),4)
        rod('downpipe',(side*3.15,-1.8,.05),(side*3.15,-1.8,2.9),.04)
    group('wall_front'); gable(2)
    for x in (-2.2,2.2): box('front_pier',(1.6,.24,3),(x,2,1.5),3)
    group('lintel'); box('loading_lintel',(2.8,.30,.45),(0,2,2.775),3); box('track',(3.25,.12,.1),(0,2.23,2.59),1)
    for x in (-1.42,1.42): box('jamb',(.08,.30,2.6),(x,2,1.3),1)
    # Standalone roof and sliding leaves are assembled by placement recipes.
    group('interior'); box('floor',(6,4,.12),(0,0,-.06),5,0)
    for x in (-2.4,2.4):
        rod('roof_truss',(x,-1.88,2.9),(x,1.88,2.9),.06)
    socket('loading_left',(-.70,2.10,0),'env_loading_leaf root; slide outward negative X')
    socket('loading_right',(.70,2.10,0),'env_loading_leaf root; slide outward positive X')
    socket('warm_light',(2.1,2.28,2.6),'warm light anchor, integrator owns light budget')
    socket('roof_anchor',(0,0,3),'separate warehouse roof; wall groups remain recoverable')

def warehouse_roof():
    group('roof')
    for side in (-1,1):
        o=box('roof_plane',(3.25,4.40,.06),(side*1.57,0,3.47),13); o.rotation_euler.y=side*math.atan(.28)
        for i in range(8 if LOD else 18):
            x=side*(.09+i*3.1/(8 if LOD else 18)); rod('corrugation',(x,-2.2,3.95-abs(x)*.28),(x,2.2,3.95-abs(x)*.28),.017,13,6)
    rod('ridge',(0,-2.22,3.97),(0,2.22,3.97),.055)
    for y in (-2,2):
        rod('gable_beam',(-3.03,y,3.04),(0,y,3.9),.055); rod('gable_beam',(3.03,y,3.04),(0,y,3.9),.055)

def gantry():
    for x in (-2.0,2.0):
        for y in (-1.5,1.5):
            box('foot',(.5,.5,.12),(x,y,.06),5)
            box('column',(.14,.14,3.3),(x,y,1.71),1)
        box('beam',(.16,3.25,.24),(x,0,3.35),1)
        rod('diagonal',(x,-1.4,2.25),(x,-.5,3.28),.033)
        rod('diagonal',(x,1.4,2.25),(x,.5,3.28),.033)
    for y in (-1.5,1.5): box('crossbeam',(4.25,.16,.22),(0,y,3.40),1)
    for x in np.arange(-1.8,2,.6): box('purlin',(.07,3.2,.1),(x,0,3.59),1)
    group('roof'); box('canopy',(4.5,3.65,.06),(0,0,3.68),13)
    for x in np.arange(-2.1,2.2,.25 if LOD else .12): rod('corrugation',(x,-1.8,3.72),(x,1.8,3.72),.013,13,6)
    group('shell'); socket('cargo_anchor',(0,0,.02),'warehouse canopy undercroft decorative storage zone')

def pump():
    box('plinth',(2.6,1.8,.24),(0,0,.12),5)
    for x in (-.64,.64):
        cyl('motor',.29,.86,(x,0,.59),2,24,(0,1,0)); cyl('endcap',.25,.09,(x,.48,.59),1,24,(0,1,0))
        box('motor_foot',(.5,.7,.10),(x,0,.30),1)
        for y in np.arange(-.3,.32,.22 if LOD else .14): ring('cooling_fin',.296,.012,(x,y,.59),1,(0,1,0))
        cyl('pipe',.095,.75,(x,-.8,.65),1,16,(0,1,0)); cyl('flange',.17,.07,(x,-.65,.65),1,16,(0,1,0))
        rod('upriser',(x,-1.18,.65),(x,-1.18,1.65),.095)
        ring('valve_wheel',.20,.020,(x,-1.18,1.45),7,(0,1,0))
    box('control_panel',(.48,.25,.65),(0,.56,1.05),2)
    for x in (-.13,.13): cyl('gauge',.075,.016,(x,.70,1.18),9,16,(0,1,0))
    for x in (-.15,0,.15): cyl('switch',.025,.035,(x,.72,.91),1,8,(0,1,0))
    socket('valve_anchor',(-.64,-1.23,1.45),'visual maintenance anchor, not a new interaction')

def pipe_elbow():
    rod('horizontal',(-.9,0,.6),(.2,0,.6),.12)
    rod('vertical',(.2,0,.6),(.2,0,1.9),.12)
    for p,ax in [((-.9,0,.6),(1,0,0)),((.2,0,1.90),(0,0,1))]: cyl('flange',.20,.08,p,1,20,ax)
    for x in (-.6,.2): box('support',(.18,.4,.5),(x,0,.25),5)

def lattice(h=5,r=.55,antenna=False):
    for i in range(4):
        a=i*math.pi/2+math.pi/4; x,y=math.cos(a)*r,math.sin(a)*r
        rod('leg',(x,y,.15),(x*.35,y*.35,h),.045)
        box('foot',(.32,.32,.15),(x,y,.075),5)
    tiers=4 if LOD else 7
    for t in range(tiers):
        z0=.2+t*(h-.3)/tiers; z1=.2+(t+1)*(h-.3)/tiers; r0=r*(1-.65*z0/h); r1=r*(1-.65*z1/h)
        for i in range(4):
            a=i*math.pi/2+math.pi/4; b=a+math.pi/2
            rod('brace',(math.cos(a)*r0,math.sin(a)*r0,z0),(math.cos(b)*r1,math.sin(b)*r1,z1),.022)
            rod('rail',(math.cos(a)*r0,math.sin(a)*r0,z0),(math.cos(b)*r0,math.sin(b)*r0,z0),.022)
    rod('aerial',(0,0,h-.2),(0,0,h+1.05),.026)
    if antenna:
        for z in (h-.30,h,h+.30): rod('yagi',(-.9,0,z),(.9,0,z),.022)
    else:
        for y in (-.23,.23): box('signal_face',(.42,.13,.48),(0,y,h-.25),15)
        for y in (-.31,.31): cyl('signal_lens',.10,.025,(0,y,h-.22),-1,16,(0,1,0))
    socket('signal_anchor',(0,0,h-.25),'signal lens visual cue; not a game alarm owner')

def tanks():
    for x in (-1.35,1.35):
        box('foundation',(2.15,2.15,.22),(x,0,.11),5)
        cyl('tank',.94,2.45,(x,0,1.445),13,40)
        for z in (.32,1.33,2.54): ring('tank_seam',.945,.015,(x,0,z),1)
        cyl('top',.96,.055,(x,0,2.69),13,40)
        cyl('hatch',.27,.09,(x,.13,2.76),1,24)
        rod('vent',(x,-.28,2.73),(x,-.28,3.12),.07)
        for side in (-1,1): rod('ladder_rail',(x+side*.18,1,.30),(x+side*.18,1,2.85),.022)
        for z in np.arange(.42,2.82,.40 if LOD else .23): rod('rung',(x-.18,1,z),(x+.18,1,z),.017)
    rod('manifold',(-1.35,1.20,.45),(1.35,1.20,.45),.10)
    socket('maintenance_anchor',(0,1.25,.45),'depot manifold visual landmark; no explosive-barrel behavior')

def antenna():
    # Braced radio lattice plus directional broadside antenna; rear ribs visible.
    lattice(4.6,.66,True)
    cyl('dish_mount',.13,.48,(0,.30,3.65),1,12,(0,1,0))
    seg=12 if LOD else 24; verts=[(0,.49,3.65)]; faces=[]
    for i in range(seg):
        a=i*math.tau/seg; verts.append((math.cos(a)*.95,.18,3.65+math.sin(a)*.95))
    for i in range(seg): faces.append((0,i+1,(i+1)%seg+1))
    mesh=bpy.data.meshes.new('dish'); mesh.from_pydata(verts,[],faces); mesh.update(); o=bpy.data.objects.new('dish',mesh); bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
    m=o.modifiers.new('dish_thickness','SOLIDIFY'); m.thickness=.035; bpy.ops.object.modifier_apply(modifier=m.name); finish(o,'dish',13)
    for i in range(6):
        a=i*math.tau/6; rod('rear_rib',(0,.46,3.65),(math.cos(a)*.89,.12,3.65+math.sin(a)*.89),.026)
    rod('feed',(0,.49,3.65),(0,1.15,3.65),.03); cyl('receiver',.10,.14,(0,1.17,3.65),2,12,(0,1,0))
    box('cabinet',(.8,.6,1.15),(1.2,0,.575),2)
    socket('radio_anchor',(1.2,.36,.8),'radio cabinet decorative maintenance point')

def rail():
    box('ballast',(2,2,.12),(0,0,-.06),12,0)
    for y in (-.78,-.26,.26,.78): box('sleeper',(1.8,.18,.08),(0,y,.02),0)
    for x in (-.60,.60):
        box('rail_web',(.045,2,.10),(x,0,.10),1,0); box('rail_head',(.08,2,.035),(x,0,.16),1,.002)
        for y in (-.78,-.26,.26,.78): box('plate',(.18,.2,.015),(x,y,.065),1,0)

def wall_lamp():
    box('wall_plate',(.20,.07,.30),(0,-.04,.15),1)
    rod('bracket',(0,0,.18),(0,.35,.18),.025)
    cyl('shade',.18,.08,(0,.36,.2),1,16); cyl('bulb',.10,.10,(0,.36,.1),-1,16)
    for a in range(4):
        t=a*math.tau/4; rod('cage',(math.cos(t)*.115,.36+math.sin(t)*.115,.03),(math.cos(t)*.16,.36+math.sin(t)*.16,.17),.010)
    socket('warm_light',(0,.36,.09),'warm omni anchor; no light object in GLB')

BUILDERS={
'env_ammo_can':(ammo_can,'prop'), 'env_barbed_wire':(wire,'prop'),'env_fence_section':(fence,'prop'),'env_gun_case':(gun_case,'prop'),'env_handcart':(handcart,'prop'),'env_jerry_can':(jerry_can,'prop'),'env_rations_crate':(lambda:crate(.75,.55,.5,True),'prop'),'env_spare_tire':(spare_tire,'prop'),'env_wooden_barrel':(wooden_barrel,'prop'),'env_yard_crate':(crate,'prop'),
'env_wall_brick_2m':(wall,'building'),'env_wall_plaster_2m':(lambda:wall(plaster=True),'building'),'env_wall_corner':(corner,'building'),'env_window_bay':(window,'building'),'env_door_frame':(door_frame,'building'),'env_door_leaf':(door_leaf,'building'),'env_loading_frame':(lambda:door_frame(4,2.8,2.6),'building'),'env_loading_leaf':(lambda:door_leaf(1.4,2.55,True),'building'),'env_roof_gable_4m':(roof,'building'),'env_roof_flat_4m':(lambda:roof(True),'building'),'env_low_wall_2m':(low_wall,'building'),'env_gate_leaf':(gate,'building'),
'env_ground_concrete_2m':(lambda:floor(5),'ground'),'env_ground_earth_2m':(lambda:floor(11),'ground'),'env_ground_cobble_2m':(lambda:floor(10),'ground'),'env_ground_steel_2m':(lambda:floor(13),'ground'),'env_ground_gravel_2m':(lambda:floor(12),'ground'),'env_drain_2m':(drain,'ground'),'env_curb_2m':(curb,'ground'),'env_seam_debris':(debris,'prop'),
'env_warehouse_shell':(warehouse_shell,'building'),'env_warehouse_roof':(warehouse_roof,'building'),'env_warehouse_gantry':(gantry,'landmark'),'env_pump_skid':(pump,'landmark'),'env_pipe_elbow':(pipe_elbow,'building'),'env_signal_mast':(lattice,'landmark'),'env_depot_tank_pair':(tanks,'landmark'),'env_radio_antenna':(antenna,'landmark'),'env_rail_2m':(rail,'ground'),'env_wall_lamp':(wall_lamp,'prop')}

def join(parts,name,origin):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); o=bpy.context.object; o.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True); bpy.context.scene.cursor.location=origin; bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    mats=[o.data.materials[p.material_index] for p in o.data.polygons]; o.data.materials.clear(); o.data.materials.append(ATLAS)
    if GLOW in mats: o.data.materials.append(GLOW)
    for p,m in zip(o.data.polygons,mats):p.material_index=1 if m==GLOW else 0
    return o

def build_one(asset,builder,kind,lod):
    global CURRENT,PARTS,SOCKETS,MOVING,LOD,GROUP
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    CURRENT=asset;PARTS=[];SOCKETS={};MOVING={};LOD=lod;GROUP='shell';builder()
    bpy.context.view_layer.update()
    pts=[o.matrix_world@Vector(v) for o in PARTS for v in o.bound_box]
    low=[min(p[i] for p in pts) for i in range(3)]; high=[max(p[i] for p in pts) for i in range(3)]
    groups={}
    for o in PARTS: groups.setdefault(o['group'],[]).append(o)
    root=bpy.data.objects.new(asset,None);bpy.context.collection.objects.link(root);root['asset_id']=asset;root['collision_class']='visual_only';root['unit']='metre'
    meshes=[]
    for tag,parts in groups.items():
        origin=MOVING[tag]['author_at'] if tag in MOVING else (0,0,0)
        o=join(parts,asset+'__'+tag+'_mesh',origin); meshes.append(o)
        if tag in MOVING:
            p=bpy.data.objects.new(asset+'__'+tag,None);bpy.context.collection.objects.link(p);p.parent=root;p.location=origin;p['motion']=MOVING[tag]['motion'];p['visual_only']=True
            o.parent=p;o.location=(0,0,0)
        else:o.parent=root
        o['collision_class']='visual_only';o['occlusion_class']='roof' if tag=='roof' else ('wall' if tag.startswith('wall_') else 'detail')
    for name,info in SOCKETS.items():
        p=bpy.data.objects.new(asset+'__socket_'+name,None);bpy.context.collection.objects.link(p);p.parent=bpy.data.objects.get(info['parent_node'],root)
        v=info['position_m'];p.location=(v[0],-v[2],v[1]);p['semantic']=info['semantic'];p['visual_only']=True
    path=OUT/'models'/f'{asset}_lod{lod}.glb'
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True,export_materials='EXPORT',export_image_format='NONE',export_extras=True,export_cameras=False,export_lights=False,export_yup=True)
    tris=0
    for o in meshes:o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    moving={k:{'node':asset+'__'+k,**{kk:vv for kk,vv in v.items() if kk!='author_at'}} for k,v in MOVING.items()}
    return {'path':f'art/environment_v2/models/{path.name}','sha256':sha(path),'triangles':tris,'surfaces':sum(len(o.data.materials) for o in meshes)},[round(high[0]-low[0],4),round(high[2]-low[2],4),round(high[1]-low[1],4)],SOCKETS.copy(),moving,groups.keys()

def main():
    (OUT/'textures').mkdir(parents=True,exist_ok=True);(OUT/'models').mkdir(parents=True,exist_ok=True);materials();entries=[]
    for asset,(builder,kind) in BUILDERS.items():
        if OPT.only and asset not in OPT.only.split(','):continue
        lods=[]
        for lod in (0,1):
            info,dims,sockets,moving,groups=build_one(asset,builder,kind,lod);lods.append(info)
            if lod==0:d0=dims;s0=sockets;m0=moving;g0=list(groups)
        entries.append({'asset_id':asset,'category':kind,'source':'ArtSource/environment_v2/build_environment.py','tool':'Blender '+bpy.app.version_string,'provenance':'Original procedural geometry and material fields created for this project; no external assets','usage':'Project-authored, for Ambush Loop and its project contributors; no external attribution or paid dependency. No separate public relicensing claim.','unit':'metre','origin':'ground centre; ground top Y=0; roof preserves assembled height','runtime_axes':'+Y up / -Z forward','dimensions_m':d0,'lods':lods,'materials':['environment_v2_atlas']+(['environment_v2_emission'] if asset in ('env_wall_lamp','env_signal_mast') else []),'collision':'visual_only; no physics, navigation, combat LOS or height benefit','logic_footprint':'NOT assigned. Integrator must map existing grid blockers; do not infer gameplay occupancy from bounds.','display_groups':g0,'sockets':s0,'moving_nodes':m0,'skeleton':None,'animations':[],'lod_policy_candidate':{'lod0_below_camera_span_m':20,'lod1_above_camera_span_m':24,'hysteresis_m':2,'status':'integrator proposal only, no shared runtime changes'},'status':'exported candidate; executed checks in evidence/validation_receipt.json; shared runtime integration not implemented'})
    textures=[{'path':'art/environment_v2/textures/'+p.name,'sha256':sha(p),'resolution':[1024,1024]} for p in sorted((OUT/'textures').glob('*.png'))]
    (OUT/'exports.json').write_text(json.dumps({'schema':1,'baseline':'744cb01439bd98d69e816d39d2584067f49043b0','seed':SEED,'generator_sha256':sha(__file__),'textures':textures,'orm_channels':'R=1 unbaked occlusion, G=roughness, B=metallic','albedo':'sRGB, no directional lighting','normal':'tangent +Y (OpenGL), linear','material_binding':'GLB named PBR material slots omit duplicate images. Bind shared environment_v2 atlas using sample/review.gd; no embedded duplicate textures.','assets':entries},indent=2)+'\n')
    print('ENVIRONMENT_EXPORTED',len(entries),'assets',len(entries)*2,'GLBs')
if __name__=='__main__':main()
