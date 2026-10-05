#!/usr/bin/env python3
"""Deterministic Blender 4.3.2 source for the first 360-degree prop kit.

blender -b --python ambush_loop/ArtSource/v2/build_yard_kit.py
No downloaded geometry, textures, fonts or hidden credentials are required.
GLBs keep material slot names; Godot applies one shared PBR atlas to all props.
"""
import hashlib
import json
import math
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
OUT = PROJECT / "art/v2"
TEX = OUT / "textures"
MODELS = OUT / "models"
SEED = 194406
PARTS = []
CURRENT = ""
ATLAS = None
GLOW = None


def image(name, values, color_space):
    height, width = values.shape[:2]
    rgba = np.ones((height, width, 4), dtype=np.float32)
    rgba[:, :, :values.shape[2]] = values
    img = bpy.data.images.new(name, width=width, height=height, alpha=False)
    img.colorspace_settings.name = color_space
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = str(TEX / (name + ".png"))
    img.file_format = "PNG"
    img.save()
    return img


def make_atlas():
    """Albedo has only material variation; normal/roughness carry small detail.

    Tiles: wood, iron, canvas, olive enamel, brick, concrete, rubber, dark paint,
    brass, plaster, gauge face, asphalt, earth, rust, stencil paint, porcelain.
    Four-pixel gutters and inset UVs limit mip bleeding at distant LODs.
    """
    global ATLAS, GLOW
    rng = np.random.default_rng(SEED)
    n = 256
    yy, xx = np.mgrid[0:n, 0:n] / n
    rgb = np.zeros((1024, 1024, 3), np.float32)
    orm = np.zeros_like(rgb)
    normal = np.zeros_like(rgb)
    palette = [(0.38, .28, .16), (.20, .22, .23), (.47, .43, .31), (.25, .29, .22),
               (.40, .24, .17), (.42, .43, .41), (.065, .066, .063), (.12, .14, .14),
               (.42, .34, .19), (.57, .56, .50), (.73, .68, .51), (.18, .19, .19),
               (.28, .24, .18), (.31, .17, .09), (.72, .68, .53), (.70, .70, .64)]
    for tile, base in enumerate(palette):
        fine = rng.random((n, n)).astype(np.float32) - .5
        low = .45 * np.sin(xx * 17 + np.sin(yy * 12)) + .25 * np.cos(xx * 47 + yy * 25)
        h = fine * .015 + low * .03
        variation = low * .1 + fine * .07
        rough = np.full((n, n), .78, np.float32) + fine * .07
        metallic = np.zeros((n, n), np.float32)
        if tile == 0:
            grain = np.sin(yy * 230 + np.sin(xx * 12) * 4 + low * 5)
            variation += grain * .075 + np.sin(yy * 69 + xx * 1.2) * .06
            h += grain * .012
            rough[:] = .82 + grain * .04
        elif tile in (1, 3, 8, 13):
            corrosion = low + fine * .25 > .29
            variation += corrosion * .1
            metallic[:] = .78 if tile in (1, 8) else .2
            metallic[corrosion] = .05
            rough[:] = .65 + corrosion * .20 + fine * .06
            h += corrosion * .02
        elif tile == 2:
            weave = np.sin(xx * math.tau * 83) * np.sin(yy * math.tau * 83)
            variation += weave * .035
            h += weave * .015 + np.sin(xx * 25 + yy * 5) * .009
            rough[:] = .95
        elif tile == 4:
            rows = np.floor(yy * 8)
            bx = (xx * 3 + (rows % 2) * .5) % 1
            mortar = (bx < .045) | ((yy * 8) % 1 < .075)
            variation += np.sin(rows * 17 + np.floor(xx * 3) * 5) * .09
            h += np.where(mortar, -.12, .02)
        elif tile in (5, 9, 11, 12):
            h = fine * (.02 if tile == 12 else .006)
            variation = fine * .12 + low * .025
        elif tile == 10:
            # Generic analog scale. No brand, copyrighted markings or decals.
            radius = np.sqrt((xx - .5) ** 2 + (yy - .47) ** 2)
            angle = np.arctan2(yy - .47, xx - .5)
            ticks = (radius > .31) & (radius < .38) & (np.sin(angle * 22) > .55)
            needle = (abs(xx - .5 - (yy - .47) * .42) < .008) & (yy > .32) & (yy < .76)
            variation[ticks | needle] = -.8
            rough[:] = .5
        values = np.clip(np.array(base)[None, None, :] * (1 + variation[:, :, None]), .015, .9)
        if tile == 4:
            values[mortar] = (.36, .36, .33)
        # Compute a tangent-space normal from the same material height field.
        dy, dx = np.gradient(h)
        vectors = np.stack((-dx * 9, -dy * 9, np.ones_like(h)), axis=2)
        vectors /= np.linalg.norm(vectors, axis=2)[:, :, None]
        normal_tile = vectors * .5 + .5
        packed = np.stack((np.ones_like(h), np.clip(rough, .1, 1), metallic), axis=2)
        # Fill each gutter from the nearest inner texel (including all corners).
        index = np.clip(np.arange(n), 4, n - 5)
        y, x = divmod(tile, 4)
        dst = np.s_[y*n:(y+1)*n, x*n:(x+1)*n]
        rgb[dst] = values[index[:, None], index[None, :]]
        normal[dst] = normal_tile[index[:, None], index[None, :]]
        orm[dst] = packed[index[:, None], index[None, :]]
    albedo = image("yard_atlas_albedo", rgb, "sRGB")
    normals = image("yard_atlas_normal", normal, "Non-Color")
    packed = image("yard_atlas_orm", orm, "Non-Color")
    ATLAS = bpy.data.materials.new("v2_shared_atlas")
    ATLAS.use_nodes = True
    nodes, links = ATLAS.node_tree.nodes, ATLAS.node_tree.links
    shader = nodes.get("Principled BSDF")
    for img, target in [(albedo, "Base Color"), (normals, "normal"), (packed, "orm")]:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = img
        if target == "normal":
            convert = nodes.new("ShaderNodeNormalMap")
            links.new(tex.outputs["Color"], convert.inputs["Color"])
            links.new(convert.outputs["Normal"], shader.inputs["Normal"])
        elif target == "orm":
            split = nodes.new("ShaderNodeSeparateColor")
            links.new(tex.outputs["Color"], split.inputs["Color"])
            links.new(split.outputs["Green"], shader.inputs["Roughness"])
            links.new(split.outputs["Blue"], shader.inputs["Metallic"])
        else:
            links.new(tex.outputs["Color"], shader.inputs[target])
    GLOW = bpy.data.materials.new("v2_lamp_emission")
    GLOW.use_nodes = True
    shader = GLOW.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (1, .71, .36, 1)
    shader.inputs["Emission Color"].default_value = (1, .49, .12, 1)
    shader.inputs["Emission Strength"].default_value = 2


def finish(obj, name, tile, bevel=0.0):
    obj.name = CURRENT + "__" + name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("manufactured_edge", "BEVEL")
        modifier.width, modifier.segments = bevel, 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data); bm.free()
    if not obj.data.uv_layers:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(island_margin=.015)
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.data.materials.clear()
    obj.data.materials.append(GLOW if tile == -1 else ATLAS)
    if tile >= 0:
        row, col = divmod(tile, 4)
        # Blender primitive UVs are retained inside the inset tile.
        for uv in obj.data.uv_layers.active.data:
            uv.uv = ((col + .025 + uv.uv.x * .95) / 4, (row + .025 + uv.uv.y * .95) / 4)
    PARTS.append(obj)
    return obj


def box(name, size, at, tile, bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.dimensions = size
    for face in obj.data.polygons:
        axis=max(range(3),key=lambda i:abs(face.normal[i]))
        uv_axes=(1,2) if axis==0 else ((0,2) if axis==1 else (0,1))
        for loop in face.loop_indices:
            vertex=obj.data.vertices[obj.data.loops[loop].vertex_index].co
            obj.data.uv_layers.active.data[loop].uv=(vertex[uv_axes[0]]+.5,vertex[uv_axes[1]]+.5)
    return finish(obj, name, tile, bevel)


def cylinder(name, radius, depth, at, tile, vertices=16, axis=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=at)
    obj = bpy.context.object
    if axis:
        obj.rotation_euler = Vector(axis).to_track_quat("Z", "Y").to_euler()
    return finish(obj, name, tile)


def rod(name, a, b, radius, tile=1, sides=8):
    a, b = Vector(a), Vector(b)
    return cylinder(name, radius, (b-a).length, (a+b)/2, tile, sides, b-a)


def crate():
    # Real boards, runners, thin steel wrapping and recessed lid separation.
    for i in range(4):
        for y in (-.29, .29):
            box("side_board", (.96, .04, .145), (0, y, .14 + i*.148), 0)
    for x in (-.46, .46):
        for i in range(4):
            box("end_board", (.04, .54, .145), (x, 0, .14 + i*.148), 0)
    for i in range(5):
        box("lid_board", (.98, .119, .045), (0, -.244+i*.122, .705), 0)
    for y in (-.20, .20):
        box("foot_runner", (.89, .10, .07), (0, y, .035), 0)
    for x in (-.31, .31):
        for y in (-.317, .317):
            box("steel_band", (.045, .009, .65), (x, y, .37), 1, .001)
            for z in (.16, .58):
                cylinder("rivet", .013, .013, (x, y, z), 1, 6, (0,1,0))
        box("lid_band", (.045, .65, .009), (x,0,.733), 1, .001)
    for x in (-.494,.494):
        for y in (-.105,.105):
            rod("handle_hinge", (x,y,.45), (x*1.06,y,.49), .013)
        rod("carry_handle", (x*1.06,-.105,.49), (x*1.06,.105,.49), .018)


def sandbags():
    for bag, (at, yaw) in enumerate([((-.37,0,.135), .035), ((.37,.025,.135), -.04), ((0,.015,.39), .12)]):
        verts, faces, uvs = [], [], []
        rings, sides = 10, 16
        # Flattened superellipsoid with irregular folds and a pinched seam.
        for j in range(rings+1):
            phi = math.pi * (j+.06)/(rings+.12)
            for i in range(sides):
                theta = math.tau*i/sides
                def power(v, p): return math.copysign(abs(v)**p, v)
                x = .40*power(math.sin(phi)*math.cos(theta), .6)
                y = .205*power(math.sin(phi)*math.sin(theta), .65)
                z = .135*power(math.cos(phi), .6)
                fold = .009*math.sin(theta*6+phi*9+bag)*math.sin(phi)
                x += fold
                y += fold*.4
                verts.append((x*math.cos(yaw)-y*math.sin(yaw)+at[0], x*math.sin(yaw)+y*math.cos(yaw)+at[1], max(.0,z+at[2])))
        for j in range(rings):
            for i in range(sides):
                a=j*sides+i; b=j*sides+(i+1)%sides
                faces.append((a,b,b+sides,a+sides))
        faces.extend([tuple(range(sides-1,-1,-1)), tuple(rings*sides+i for i in range(sides))])
        mesh=bpy.data.meshes.new("bag"); mesh.from_pydata(verts,[],faces); mesh.update()
        obj=bpy.data.objects.new("bag",mesh); bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT"); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        finish(obj,"canvas_bag",2)
        for face in mesh.polygons: face.use_smooth=True
        for i in range(16):
            points=[]
            for theta in (math.tau*i/16, math.tau*(i+1)/16):
                x=.401*math.copysign(abs(math.cos(theta))**.6, math.cos(theta))
                y=.207*math.copysign(abs(math.sin(theta))**.65, math.sin(theta))
                points.append((x*math.cos(yaw)-y*math.sin(yaw)+at[0],x*math.sin(yaw)+y*math.cos(yaw)+at[1],at[2]))
            rod("stitched_seam",*points,.0035,2,4)


def drum():
    profile=[(0,.278),(.035,.296),(.065,.284),(.19,.286),(.21,.303),(.245,.303),(.26,.286),(.59,.286),(.61,.303),(.645,.303),(.66,.286),(.85,.284),(.88,.296),(.905,.296)]
    verts=[(r*math.cos(i*math.tau/24),r*math.sin(i*math.tau/24),z) for z,r in profile for i in range(24)]
    faces=[]
    for j in range(len(profile)-1):
        for i in range(24): faces.append((j*24+i,j*24+(i+1)%24,(j+1)*24+(i+1)%24,(j+1)*24+i))
    faces.extend([tuple(range(23,-1,-1)),tuple((len(profile)-1)*24+i for i in range(24))])
    mesh=bpy.data.meshes.new("drum"); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new("drum",mesh); bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT"); obj.select_set(True); bpy.context.view_layer.objects.active=obj
    finish(obj,"pressed_steel_shell",3)
    for face in mesh.polygons: face.use_smooth=len(face.vertices)==4
    cylinder("recessed_lid",.277,.018,(0,0,.897),1,24)
    cylinder("bung",.048,.025,(.14,0,.921),1,12)
    box("bung_slot",(.062,.012,.006),(.14,0,.936),7,0)
    cylinder("vent",.019,.022,(-.16,.04,.92),8,8)


def radio():
    box("pressed_case",(.55,.29,.35),(0,0,.185),3,.014)
    box("front_panel",(.51,.014,.29),(0,-.154,.19),7,.004)
    box("analog_scale",(.22,.006,.098),(-.10,-.165,.244),10,.001)
    for i in range(6):
        box("speaker_grille",(.012,.009,.14),(.07+i*.026,-.165,.24),1,.001)
    for x in (-.19,0,.19):
        cylinder("tuning_knob",.035,.025,(x,-.183,.102),6,12,(0,1,0))
        box("knob_index",(.005,.003,.027),(x,-.198,.113),14,0)
    for x in (-.21,.21):
        box("handle_upright",(.021,.035,.093),(x,0,.386),1)
    box("carry_grip",(.43,.041,.028),(0,0,.438),6)
    rod("whip_antenna",(.22,.06,.35),(.25,.07,.94),.008,1)
    for z in (.08,.22):
        box("rear_latch",(.06,.018,.045),(0,.158,z),1,.003)


def lamp():
    box("base_plate",(.35,.35,.045),(0,0,.0225),1)
    for x in (-.12,.12):
        for y in (-.12,.12): cylinder("anchor_bolt",.022,.036,(x,y,.049),1,6)
    rod("upright",(0,0,.03),(0,0,3.48),.056,7,12)
    rod("arm",(0,0,3.46),(0,-.53,3.65),.040,1,12)
    rod("downstem",(0,-.53,3.65),(0,-.53,3.42),.028,1)
    bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=.27,radius2=.085,depth=.14,location=(0,-.53,3.44))
    finish(bpy.context.object,"enamel_shade",3)
    cylinder("light_diffuser",.095,.22,(0,-.53,3.28),-1,16)
    for i in range(6):
        a=math.tau*i/6; x=.12*math.cos(a); y=-.53+.12*math.sin(a)
        rod("guard",(x,y,3.13),(x,y,3.41),.008,1,6)
    cylinder("guard_bottom",.135,.016,(0,-.53,3.12),1,16)


def warehouse():
    # Separate outer walls, roof and door are retained for runtime occlusion.
    for x in (-2.25,-.75,.75,2.25):
        box("wall_back",(1.49,.22,3),(x,2,1.5),4,.01)
        box("inside_back",(1.48,.022,2.8),(x,1.878,1.48),9,.003)
    for x in (-3,3):
        for y in (-1.25,.25,1.50):
            box("wall_side",(.22,1.49 if y<1 else .99,3),(x,y,1.5),4,.01)
    # Front door in left half, window in right half: openings are actual holes.
    for center,width in [(-2.75,.5),(-.2,1.2),(2.7,.6)]:
        box("wall_front_pier",(width,.22,3),(center,-2,1.5),4,.01)
    box("door_lintel",(1.7,.23,.6),(-1.65,-2,2.7),4)
    box("window_sill_wall",(1.8,.22,1.1),(1.5,-2,.55),4)
    box("window_header",(1.8,.22,.5),(1.5,-2,2.75),4)
    for x in (.56,2.44): box("window_frame",(.085,.27,1.4),(x,-2,1.8),1)
    for z in (1.12,2.48): box("window_frame",(1.96,.27,.085),(1.5,-2,z),1)
    box("window_mullion",(.06,.13,1.3),(1.5,-2,1.8),1)
    for z in (.15,2.85): box("concrete_course",(6.25,.29,.15),(0,-2,z),5)
    door=box("door_leaf",(1.55,.075,2.38),(-1.65,-1.96,1.19),3,.008)
    door["occlusion_class"]="door_visual_only"
    for z in (.45,1.35,2.05): box("door_brace",(1.48,.095,.046),(-1.65,-2,z),1)
    box("door_handle",(.06,.055,.14),(-1.04,-2.025,1.1),1,.004)
    for y in (-1.3,0,1.3): box("roof_beam",(6.1,.09,.17),(0,y,3.01),1)
    # Closed gables remain with the wall shell when the corrugated roof lifts.
    for y in (-2,2):
        verts=[(x,y+dy,z) for dy in (-.11,.11) for x,z in [(-3.1,3),(3.1,3),(0,3.68)]]
        mesh=bpy.data.meshes.new("gable"); mesh.from_pydata(verts,[],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)]); mesh.update()
        obj=bpy.data.objects.new("gable",mesh); bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT"); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        finish(obj,"wall_gable",4)
    for i in range(24):
        x=-3.067+i*.267
        obj=box("roof_removable",(.274,4.4,.05),(x,0,3.74-abs(x)*.20+.015*(i%2)),7,.004)
        obj.rotation_euler.y=math.atan(.20)*(1 if x>0 else -1)
        obj["occlusion_class"]="roof"
    rod("ridge_cap",(0,-2.22,3.78),(0,2.22,3.78),.07,1,8)
    rod("drain_pipe",(3.17,1.85,.05),(3.17,1.85,2.85),.045,1,10)
    for z in (.5,2.5): box("pipe_bracket",(.16,.035,.025),(3.12,1.85,z),1,.002)
    box("junction_box",(.13,.44,.6),(3.16,-.5,1.5),3,.012)
    rod("conduit",(3.18,-.5,1.8),(3.18,-.5,2.8),.012,1,6)


def floor(tile):
    box("ground_tile",(2,2,.10),(0,0,-.05),tile,.005)


BUILDERS={"supply_crate":(crate,"prop"), "sandbag_stack":(sandbags,"prop"),
          "oil_drum":(drum,"prop"), "field_radio":(radio,"prop"), "yard_lamp":(lamp,"prop"),
          "warehouse_fragment":(warehouse,"building"),
          "ground_concrete":(lambda:floor(5),"ground"), "ground_asphalt":(lambda:floor(11),"ground"),
          "ground_earth":(lambda:floor(12),"ground")}


def join_parts(parts, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts: obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    # Joining repeated slots can leave aliases: remap into two canonical slots.
    slot_for_face=[obj.data.materials[p.material_index] for p in obj.data.polygons]
    obj.data.materials.clear(); obj.data.materials.append(ATLAS)
    if GLOW in slot_for_face: obj.data.materials.append(GLOW)
    for face, mat in zip(obj.data.polygons,slot_for_face): face.material_index=1 if mat==GLOW else 0
    return obj


def export(objects, asset, suffix):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects: obj.select_set(True)
    path=MODELS/(asset+suffix+".glb")
    bpy.ops.export_scene.gltf(filepath=str(path),export_format="GLB",use_selection=True,
        export_apply=True,export_materials="PLACEHOLDER",export_extras=True,
        export_cameras=False,export_lights=False,export_yup=True)
    tris=0
    for obj in objects:
        obj.data.calc_loop_triangles(); tris+=len(obj.data.loop_triangles)
    return {"path":path.relative_to(PROJECT).as_posix(),"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"triangles":tris,
            "surfaces":sum(len(obj.data.materials) for obj in objects)}


def main():
    global CURRENT, PARTS
    for directory in (TEX,MODELS): directory.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    bpy.context.scene.unit_settings.system="METRIC"
    bpy.context.scene.unit_settings.scale_length=1.0
    make_atlas()
    entries=[]
    for asset,(builder,kind) in BUILDERS.items():
        CURRENT=asset; PARTS=[]; builder()
        groups={}
        for obj in PARTS:
            tag="roof" if "roof_removable" in obj.name or "ridge_cap" in obj.name else ("door" if "door_" in obj.name else "shell")
            if "wall_front" in obj.name or "window_" in obj.name or "concrete_course" in obj.name:
                tag="wall_front"
            elif "wall_back" in obj.name or "inside_back" in obj.name:
                tag="wall_back"
            elif "wall_side" in obj.name:
                tag="wall_left" if obj.location.x<0 else "wall_right"
            groups.setdefault(tag if kind=="building" else "mesh",[]).append(obj)
        objects=[join_parts(parts,asset+"_"+tag) for tag,parts in groups.items()]
        for obj in objects:
            obj["asset_id"]=asset; obj["collision_class"]="visual_only"
            obj["occlusion_class"]="roof" if obj.name.endswith("_roof") else ("wall" if "_wall_" in obj.name else "detail")
            # Authoring +Y maps to runtime -Z in Blender's glTF conversion.
            obj.data.transform(Matrix.Rotation(math.pi,4,"Z"))
        points=[obj.matrix_world@Vector(p) for obj in objects for p in obj.bound_box]
        low=[min(p[i] for p in points) for i in range(3)]; high=[max(p[i] for p in points) for i in range(3)]
        lod0=export(objects,asset,"_lod0")
        copies=[]
        for original in objects:
            obj=original.copy(); obj.data=original.data.copy(); bpy.context.collection.objects.link(obj)
            bpy.context.view_layer.objects.active=obj
            modifier=obj.modifiers.new("distance_simplification","DECIMATE"); modifier.ratio=.55
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            copies.append(obj)
        lod1=export(copies,asset,"_lod1")
        for obj in copies: bpy.data.objects.remove(obj,do_unlink=True)
        collection=bpy.data.collections.new(asset); bpy.context.scene.collection.children.link(collection)
        for obj in objects:
            for old in list(obj.users_collection): old.objects.unlink(obj)
            collection.objects.link(obj)
        entries.append({"asset_id":asset,"category":kind,"source":"ArtSource/v2/build_yard_kit.py",
            "editable_source":"ArtSource/v2/yard_kit.blend","tool":"Blender "+bpy.app.version_string,
            "provenance":"Original procedural geometry and material fields; no third-party source assets",
            "usage":"Project-authored sample; same repository license/terms; no external attribution required",
            "logic_id":"not_assigned_sample_only","unit":"metre","origin":"ground centre (ground tile top at 0)",
            "runtime_axes":"+Y up, -Z forward; authoring +Z up, +Y forward",
            "dimensions_m":[round(high[0]-low[0],4),round(high[2]-low[2],4),round(high[1]-low[1],4)],
            "lods":[lod0,lod1],"materials":["shared 1024px albedo/normal/ORM atlas"]+(["lamp emission"] if asset=="yard_lamp" else []),
            "collision":"visual_only; never navigation or combat LOS","animations":[],
            "sockets":{"warm_light":[0,3.28,-.53]} if asset=="yard_lamp" else {},
            "validation_scene":"res://scenes/presentation/asset_review.tscn","status":"exported; engine review pending"})
    textures=[{"path":p.relative_to(PROJECT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(TEX.glob("*.png"))]
    (OUT/"manifest.json").write_text(json.dumps({"schema":1,"seed":SEED,"generator_sha256":hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),"assets":entries,"textures":textures},indent=2)+"\n")
    # Packed PBR textures make the editable source portable to another machine.
    for img in bpy.data.images:
        if img.source=="FILE" or img.filepath: img.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/"yard_kit.blend"))
    print("YARD_KIT_EXPORTED",json.dumps([{e["asset_id"]:e["lods"]} for e in entries]))


if __name__=="__main__": main()
