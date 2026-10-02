#!/usr/bin/env python3
"""Join actual exports with candidate-only original-use and exhibition recipes."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent; P=H.parents[1]; O=P/'art/environment_v2'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def place(a,p=(0,0,0),yaw=0,**kw):return {'asset_id':a,'position_m':list(p),'yaw_degrees':yaw,**kw}
ex=json.loads((O/'exports.json').read_text()); base=json.loads((P/'art/v2/manifest.json').read_text()); old={a['asset_id']:a for a in base['assets']}
reuse={'oil_drum':'oil_drum','sandbag':'sandbag_stack','field_radio':'field_radio','lamp_post':'yard_lamp'}
uses={'ammo_can':'decorative ammo container at courtyard crate edge; game loot identity external','barbed_wire':'original unreferenced 3D study; no legacy PNG runtime reference; decorative wire only','fence_section':'west alley overlay; no added logical blocker','field_radio':'NE courtyard window decoration; not a new alarm owner','gun_case':'rifle case decoration; empty container, no R2 gun/tool duplication','handcart':'east yard overlay outside walk spine; no blocking','jerry_can':'SW lip decoration; no new explosive behavior','lamp_post':'existing warm-light landmark; no baked lights','oil_drum':'yard crate SE edge decoration; warehouse explosive identity only if assigned by integrator','rations_crate':'courtyard ration decoration; inventory remains external','sandbag':'west wall overlay; selected logical cover must be assigned externally','spare_tire':'bike wreck overlay; no collision','wooden_barrel':'west lip decoration; not warehouse explosive barrel','yard_crate':'supply crate display and external loot container mapping; hinged lid candidate'}
rows=[]
for name,use in uses.items():
    src=P/'ArtSource'/('build_'+name+'.py'); glb=P/'ArtSource'/(name+'.glb')
    rows.append({'original_class':name,'legacy_source':str(src.relative_to(P)),'legacy_source_sha256':sha(src),'legacy_glb':str(glb.relative_to(P)),'legacy_glb_sha256':sha(glb),'legacy_runtime_reference':'not referenced (audit exception)' if name=='barbed_wire' else 'scripts/map_draw.gd fixed-angle overlay','asset_id':reuse.get(name,'env_'+name),'mode':'reuse_baseline_bytes' if name in reuse else 'new_environment_candidate','purpose_candidate':use,'interaction':'visual moving node and anchor present; game command wiring NOT implemented' if name in ('ammo_can','gun_case','rations_crate','yard_crate') else 'decorative or reused visual; logic mapping belongs to integrator'})
reused=[old[id] for id in reuse.values()]
# These small dioramas prove modular composition, not the 40x22 authored level layout.
common=[place('env_low_wall_2m',(-4,0,2),90),place('env_wall_brick_2m',(-4,0,-1),90),place('env_window_bay',(4,0,-1),-90),place('env_wall_lamp',(3.85,1.90,-1),-90)]
yard=[place('env_warehouse_shell',(0,0,-2.8),180),place('env_warehouse_roof',(0,0,-2.8),180,occlusion_group='roof'),place('env_loading_leaf',(-.7,0,-.70),180,motion_range_override=[0,1.4]),place('env_loading_leaf',(.7,0,-.70),180),place('env_yard_crate',(-1.7,0,1)),place('env_ammo_can',(-.7,0,1.45)),place('env_fence_section',(3,0,1.8),90),place('env_barbed_wire',(3.15,0,1.7),90),place('sandbag_stack',(-2.8,0,2.1)),place('oil_drum',(1.65,0,1.5)),place('yard_lamp',(3.6,0,3)),place('field_radio',(-1.7,.72,1)),place('env_handcart',(1.8,0,3)),place('env_seam_debris',(-3.4,0,-1)),place('env_jerry_can',(2.7,0,2.3)),place('env_spare_tire',(2.7,0,3.1)),place('env_wooden_barrel',(-3.6,0,3.5)),place('env_rations_crate',(-2.8,0,3.6)),place('env_gun_case',(-1.3,0,3.7))]
recipes={
'yard':{'landmark':'env_warehouse_shell','grounds':['env_ground_concrete_2m','env_ground_earth_2m'],'placements':yard,'identity':'complete four-sided loading warehouse with separate roof, sliding leaves, reuse four baseline props and all ten gap props'},
'warehouse':{'landmark':'env_warehouse_gantry','grounds':['env_ground_concrete_2m','env_ground_cobble_2m'],'placements':common+[place('env_warehouse_gantry',(0,0,-1)),place('env_yard_crate',(-1.4,0,-1)),place('env_rations_crate',(1.3,0,-1)),place('env_handcart',(0,0,3)),place('env_drain_2m',(2.7,0,0),90),place('oil_drum',(2.8,0,2))],'identity':'open braced canopy, cargo lane, grated drain; roof can be removed'},
'pump':{'landmark':'env_pump_skid','grounds':['env_ground_concrete_2m','env_ground_steel_2m'],'placements':common+[place('env_pump_skid',(0,0,0)),place('env_pipe_elbow',(1.8,0,-1.9),90),place('env_pipe_elbow',(-1.8,0,-1.9),-90),place('env_door_frame',(0,0,-3.1)),place('env_door_leaf',(0,0,-3.1)),place('env_wall_plaster_2m',(2,0,-3.1)),place('env_drain_2m',(0,0,2.4))],'identity':'twin motor pump skid, control gauges, paired rising pipes, separate operational-door display'},
'railcut':{'landmark':'env_signal_mast','grounds':['env_ground_gravel_2m','env_ground_earth_2m'],'placements':common+[place('env_signal_mast',(-1.8,0,-.8))]+[place('env_rail_2m',(1.5,0,z)) for z in (-3,-1,1,3)]+[place('env_fence_section',(-3.2,0,2),90),place('env_wall_corner',(3,0,-3))],'identity':'braced signal mast with two-sided lenses, track sleepers/ballast, fence corridor'},
'depot':{'landmark':'env_depot_tank_pair','grounds':['env_ground_concrete_2m','env_ground_gravel_2m'],'placements':common+[place('env_depot_tank_pair',(0,0,-.5)),place('env_pipe_elbow',(0,0,2)),place('env_jerry_can',(2.5,0,2.5)),place('env_curb_2m',(-1.8,0,2.1)),place('env_curb_2m',(1.8,0,2.1))],'identity':'paired vertical storage tanks, access ladders, vents and front manifold; no barrel-explosion semantics'},
'radio':{'landmark':'env_radio_antenna','grounds':['env_ground_cobble_2m','env_ground_concrete_2m'],'placements':common+[place('env_radio_antenna',(0,0,-.7)),place('env_fence_section',(-2.8,0,2.2)),place('env_gate_leaf',(0,0,2.2)),place('env_fence_section',(2.8,0,2.2)),place('field_radio',(2.6,0,.4)),place('env_roof_flat_4m',(-2,0,-3.1),occlusion_group='roof'),place('env_wall_plaster_2m',(-3,0,-3))],'identity':'directional dish with rear ribs, yagi crown and maintenance cabinet, separate gated boundary'}
}
for k,v in recipes.items():v.update({'status':'exhibition composition candidate, NOT authored game placement','world_units':'metres','root_origin':'ground centre','sample_size_m':[12,12],'logic':'visual_only; does not introduce grid occupancy, LOS, selection, navigation or high ground'})
deps=[]
for a in reused:
    for l in a['lods']:deps.append({'path':l['path'],'sha256':l['sha256']})
for t in base['textures']:deps.append(t)
cat={'schema':1,'status':'candidate, not shared runtime manifest','baseline':ex['baseline'],'source_sha256':ex['generator_sha256'],'new_exports_manifest':'art/environment_v2/exports.json','new_assets':ex['assets'],'reuse_assets':reused,'reuse_dependencies':deps,'original_14_mapping':rows,'themes':recipes,'material_contract':{'new_slot':'environment_v2_atlas','new_textures':ex['textures'],'baseline_slots':['v2_shared_atlas','v2_lamp_emission'],'baseline_textures':'unchanged art/v2/textures/yard_atlas_*','orm_channels':ex['orm_channels'],'normal_convention':ex['normal'],'candidate_material_resources':['art/environment_v2/materials/environment_v2_atlas.tres','art/environment_v2/materials/environment_v2_emission.tres'],'binding_example':'art/environment_v2/sample/review.gd; sample only, integrator must extend runtime loader'},'acceptance':'sample import/render review distinct from integrated six-level play and device performance'}
(H/'catalog_candidate.json').write_text(json.dumps(cat,indent=2,ensure_ascii=False)+'\n'); (O/'catalog_sample.json').write_text(json.dumps(cat,indent=2,ensure_ascii=False)+'\n')
print('CATALOG',len(rows),'original categories',len(ex['assets']),'new assets',len(reused),'reused assets',len(recipes),'distinct themes')

semantics={}
for record in ex['assets']+reused:
    id=record['asset_id']; category=record['category']; kind='decorative_prop'
    if 'ground_' in id:kind='ground_tile_top_y0'
    elif id=='env_rail_2m':kind='ballast_top_y0_with_visual_railhead_above_ground'
    elif id=='env_drain_2m':kind='inset_grate; visual ground cutout recommended; logical ground unchanged'
    elif id=='env_curb_2m':kind='ground_edging; raised display only'
    elif 'roof' in id:kind='roof_at_authored_assembled_height; instance_y0'
    elif id in ('env_door_leaf','env_loading_leaf','env_gate_leaf'):kind='independent_visual_leaf; align jamb socket; root at ground centre'
    elif 'frame' in id:kind='fixed_jamb_and_lintel; pair independent leaf; never animate frame'
    elif id=='env_wall_lamp':kind='wall_mount; placement_y is mount height; warm_light socket owned by integrator'
    elif category=='landmark':kind='theme_landmark; visual_only; avoid obscuring routes/selection'
    elif category=='building':kind='modular_shell_or_wall; pair visual edges; independent observation occlusion'
    semantics[id]={'placement_kind':kind,'local_ground_y':0,'grid_unit_m':1,'front':'-Z','snap_candidate':'module root to intended visual origin; exact logical cell map comes from existing level','visual_dimensions_m':record['dimensions_m'],'logical_occupancy':'NOT ASSIGNED; retain existing 40x22 blockers','collision':'visual_only; do not derive physical/LOS blockers from AABB','selection':'candidate anchor only; integrator assigns allowed existing commands','sockets':record.get('sockets',{}),'moving_nodes':record.get('moving_nodes',{})}
(H/'placement_semantics_candidate.json').write_text(json.dumps({'schema':1,'status':'candidate','assets':semantics},indent=2,ensure_ascii=False)+'\n')
