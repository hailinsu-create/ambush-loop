"""Blender source turntable; 8 azimuths for each prop under neutral lighting.

blender -b ArtSource/v2/yard_kit.blend -t 2 --python ArtSource/v2/render_source_review.py
"""
import math
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUTPUT=ROOT/"build/asset_review/a1/blender"
OUTPUT.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=24
scene.cycles.use_denoising=False
scene.render.resolution_x=360
scene.render.resolution_y=360
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.world.use_nodes=True
scene.world.node_tree.nodes["Background"].inputs[0].default_value=(.20,.20,.20,1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value=.6
scene.view_settings.view_transform="AgX"
for name,at,energy,scale in [("key",(3,-4,6),650,4),("fill",(-3,2,4),250,3)]:
    data=bpy.data.lights.new(name,"AREA"); data.energy=energy; data.shape="DISK"; data.size=scale
    obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.location=at
    obj.rotation_euler=(-obj.location).to_track_quat("-Z","Y").to_euler()
data=bpy.data.cameras.new("review_camera"); data.type="ORTHO"
camera=bpy.data.objects.new("review_camera",data); scene.collection.objects.link(camera); scene.camera=camera
collections=[c for c in bpy.data.collections if c.name in ("supply_crate","sandbag_stack","oil_drum","field_radio","yard_lamp","warehouse_fragment","ground_concrete","ground_asphalt","ground_earth")]
for collection in collections: collection.hide_render=True
for asset,size,look in [("supply_crate",1.6,(0,0,.35)),("sandbag_stack",1.9,(0,0,.25)),("oil_drum",1.5,(0,0,.45)),("field_radio",1.3,(0,0,.46)),("yard_lamp",4.6,(0,0,1.8))]:
    col=bpy.data.collections[asset]; col.hide_render=False
    camera.data.ortho_scale=size
    for yaw in range(0,360,45):
        angle=math.radians(yaw)
        target=Vector(look)
        camera.location=target+Vector((math.sin(angle),-math.cos(angle),.9))*8
        camera.rotation_euler=(target-camera.location).to_track_quat("-Z","Y").to_euler()
        scene.render.filepath=str(OUTPUT/f"{asset}_{yaw:03}.png")
        bpy.ops.render.render(write_still=True)
    col.hide_render=True
print("BLENDER_SOURCE_REVIEW_OK",OUTPUT)
