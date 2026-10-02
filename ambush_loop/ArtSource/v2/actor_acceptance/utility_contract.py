"""Optional asset clips and interaction metadata; no simulation/event mutation."""
import math

ADDED_CLIPS = {
    'utility_ready': (2.4, True), 'knife_stab': (.8, False),
    'grenade_throw': (1., False), 'decoy_place': (1.2, False),
    'corpse_grab': (1., False), 'corpse_drag': (1.2, True),
    'corpse_release': (.7, False), 'corpse_prone': (1.2, True),
    'corpse_dragged': (1.2, True), 'death_prone': (1.2, False),
    'corpse_lift': (1., False), 'corpse_lower': (.7, False),
}
CORPSE = {'corpse_prone', 'corpse_dragged', 'death_prone', 'corpse_lift', 'corpse_lower'}
DRAG = {'corpse_grab', 'corpse_drag', 'corpse_release'}

def smooth(t):
    t = max(0., min(1., t)); return t*t*(3-2*t)

def reach(t):
    return smooth(t/.4) if t < .4 else 1. if t <= .6 else 1-smooth((t-.6)/.4)

def drag_blend(clip, t):
    return smooth(t) if clip == 'corpse_grab' else 1-smooth(t) if clip == 'corpse_release' else 1.

def throw_hand(t):
    keys = [(0., (.18,.24,1.15)), (.25,(.18,-.10,1.62)),
            (.50,(.18,.52,1.62)), (.75,(.18,.52,1.20)), (1.,(.18,.24,1.15))]
    for (a,p),(b,q) in zip(keys,keys[1:]):
        if t <= b:
            f=smooth((t-a)/(b-a)); return tuple(x*(1-f)+y*f for x,y in zip(p,q))
    return keys[-1][1]

def candidate():
    return {
        'schema': 1, 'coordinates': 'metres; +Y up/-Z forward; ground origin; WorldSpace once only',
        'clips': {name:{'duration_s':round(d*30)/30,'loop':loop,'root_motion':False} for name,(d,loop) in ADDED_CLIPS.items()},
        'roles': ['operator_rifle','operator_mg','operator_scout'],
        'export_scope': 'all seven actors x three LODs; old52 clips, 20 bones and all existing sockets unchanged',
        'tool_attachment': {'bone':'hand.R','translation_bone_local_m':[0,.035,0],
            'rotation_bone_local_xyz_deg':[90,0,0],
            'offset':'subtract rotated actual tool __socket_grip; no new grip coordinates'},
        'knife': {'clip':'knife_stab','strike_window_phase':[.40,.60],
            'interaction_marker':'knife__socket_tip (existing actual GLB node)',
            'intent':'single forward torso-height stab/lunge; does not represent a throat-cut choreography',
            'timing':'candidate may be aligned to recorded melee impact; fired_shot signal also emitted for melee; sentry skill has no equivalent animation event in frozen baseline'},
        'grenade': {'clip':'grenade_throw','release_phase':.5,
            'release_marker':'grenade__socket_grip world transform immediately before detach',
            'intent':'overhand preparation, release and follow-through; frozen projectile starts immediately, so authored .5s anticipation must not delay simulation',
            'variant_limit':'existing GLB is a generic oval charge; frozen simulation also selects stiel/mills/mk2; variant-specific meshes and finger/pin operation remain unverified'},
        'decoy': {'clip':'decoy_place','ground_contact_window_phase':[.40,.60], 'release_phase':.5,
            'release_marker':'decoy__socket_grip; full model origin/basis becomes the grounded world transform',
            'intent':'local placement candidate only; frozen decoy appears immediately at selected world point with no flight or range guard; do not require walking/reach as new gameplay'},
        'corpse': {'actor_clips':['corpse_grab','corpse_drag','corpse_release'],
            'body_clips':{'ground':'corpse_prone','held':'corpse_dragged','death':'death_prone','lift':'corpse_lift','lower':'corpse_lower'},
            'interaction_markers':{'shoulder.L':{'bone':'upper_arm.L','translation_bone_local_m':[0,0,0]},
                                  'shoulder.R':{'bone':'upper_arm.R','translation_bone_local_m':[0,0,0]}},
            'marker_type':'optional BoneAttachment3D definitions, not extra exported bones or replacement sockets',
            'alignment':'hold body at corpse_dragged phase0; preserve common facing basis; translate body so midpoint of two actual shoulder markers equals midpoint of actor hand.L/R existing palm sockets; shoulder separation .410m',
            'ground_pose_local_backshift_m':.20,
            'ground_shift_scope':'embedded in new prone/lift/lower/death skeleton poses to clear actor boots; root bone and actor origin unchanged; do not apply an additional runtime20cm correction',
            'grounding':'isolated drag pairing floor tolerance -15mm; no root motion, ragdoll or collision; runtime must retain historical authoritative loot position',
            'transition_limit':'grab/release and separate prone-to-inclined lift/lower have authored endpoints; pairing during actual pickup and interrupts needs integration; no ragdoll or physics approval',
            'baseline_limit':'haul follows LootPickup at screen-axis Vector2(0,14), no corpse identity/pose/facing record; pair scene only demonstrates optional visual contract'},
        'transitions': {'knife_stab':['utility_ready','utility_ready'],
            'grenade_throw':['utility_ready','utility_ready'], 'decoy_place':['utility_ready','utility_ready'],
            'corpse_grab':['utility_ready','corpse_drag'], 'corpse_release':['corpse_drag','utility_ready'],
            'death_prone':['utility_ready','corpse_prone'],
            'corpse_lift':['corpse_prone','corpse_dragged'],'corpse_lower':['corpse_dragged','corpse_prone']},
        'thresholds': {'held_grip_m':.0001,'paired_shoulder_m':.015,'ground_min_y_m':-.015,
            'knife_forward_excursion_m':.20,'grenade_prepare_to_release_m':.45,'endpoint_transform_error':.0001,
            'death_import_endpoint_translation_m':.001},
        'runtime_owner':'Main PR15 author owns actual historical triggers/clocks, masks, interrupts/cancellation, projectile placement and body-state transitions. Metadata never adds gameplay, damage, ammo or inferred replay history.',
        'quality_limits':['static closed fingers, no finger rig/pin pulling','procedural near faces and clothing',
            'contact markers do not prove natural grasp or historical weapon/tool accuracy','isolated review is not six-level combat/device acceptance'],
    }
