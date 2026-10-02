"""Asset presentation profiles; no simulation state or weapon stat mutation."""
FAMILIES = {
    'm1911': 'pistol', 'luger': 'pistol', 'm1_garand': 'rifle', 'kar98k': 'rifle',
    'thompson': 'smg', 'mp40': 'smg', 'bar': 'mg', 'mg42': 'mg',
    'springfield': 'scout', 'kar98k_zf': 'scout',
}
GROUPS = {gun: ('thompson' if gun == 'thompson' else family) for gun, family in FAMILIES.items()}
# Exported weapon-local +Y up/-Z forward. Existing sockets remain unchanged.
SUPPORT = {gun: [0, 0, -.26] for gun in FAMILIES}
SUPPORT.update(m1911=[-.035, -.035, 0], luger=[-.035, -.035, 0], thompson=[0, -.050, -.290])
SIGHT = {gun: [0, .077, -.055] for gun in FAMILIES}
SIGHT.update(m1911=[0, .046, -.040], luger=[0, .054, -.025],
             springfield=[0, .12, .048], kar98k_zf=[0, .12, .048])
RELOAD = {
    'm1911': [0, -.112, .015], 'luger': [0, -.112, .015],
    'm1_garand': [0, .074, -.035], 'kar98k': [0, .074, -.035],
    'thompson': [-.045, -.072, -.09], 'mp40': [0, -.158, -.09],
    'bar': [0, -.158, -.09], 'mg42': [-.029, .045, -.06],
    'springfield': [.070, .053, -.046], 'kar98k_zf': [.070, .053, -.046],
}
# One pistol pose uses a conservative 50mm sight height; each model's exact
# sight error is measured in the engine. Other group members share sight height.
POSE = {
    'pistol': {'forward': .38, 'sight_height': .050, 'head_cant': 0, 'support_shoulder_deg': -22, 'recoil_gain': .7},
    'rifle': {'forward': .28, 'sight_height': .077, 'head_cant': .37, 'support_shoulder_deg': -15, 'recoil_gain': 1},
    'smg': {'forward': .30, 'sight_height': .077, 'head_cant': .37, 'support_shoulder_deg': -25, 'recoil_gain': .6},
    'thompson': {'forward': .28, 'sight_height': .077, 'head_cant': .37, 'support_shoulder_deg': -25, 'recoil_gain': .6},
    'mg': {'forward': .30, 'sight_height': .077, 'head_cant': .37, 'support_shoulder_deg': -25, 'recoil_gain': .5},
    'scout': {'forward': .28, 'sight_height': .12, 'head_cant': .37, 'support_shoulder_deg': -15, 'recoil_gain': 1.15},
}
ADDED_CLIPS = {}
SPECS = {}
for group in POSE:
    for stage, seconds, loop in [('ready', 2.4, True), ('aim', 1.8, True), ('fire', .24, False), ('raise', .3, False), ('lower', .3, False)]:
        name = stage + '_' + group
        ADDED_CLIPS[name] = (seconds, loop)
        SPECS[name] = {'group': group, 'stage': stage}
for gun in FAMILIES:
    name = 'reload_contact_' + gun
    ADDED_CLIPS[name] = (1., False)
    SPECS[name] = {'group': GROUPS[gun], 'stage': 'reload', 'gun': gun}

def smooth(value):
    value = max(0., min(1., value))
    return value * value * (3 - 2 * value)

def raised(stage, phase):
    if stage == 'ready': return 0.
    if stage == 'raise': return smooth(phase)
    if stage == 'lower': return 1 - smooth(phase)
    if stage == 'reload':
        return 1 - smooth(phase / .25) if phase < .25 else smooth((phase - .75) / .25) if phase > .75 else 0.
    return 1.

def contact(phase):
    return smooth((phase - .20) / .20) if phase < .40 else 1. if phase <= .60 else 1 - smooth((phase - .60) / .20)

def candidate():
    profiles = []
    for gun, family in FAMILIES.items():
        group = GROUPS[gun]
        profiles.append({'weapon_id': gun, 'family': family, 'pose_group': group,
                         'roles': ['operator_rifle', 'operator_mg', 'operator_scout'],
                         'clips': {stage: stage + '_' + group for stage in ['ready', 'aim', 'fire', 'raise', 'lower']} |
                                  {'reload_contact': 'reload_contact_' + gun},
                         'sockets': {'pose_support': SUPPORT[gun], 'sight': SIGHT[gun], 'reload_contact': RELOAD[gun]},
                         'reload_contact_window_phase': [.40, .60],
                         'reload_timing': 'authored 1s normalized reach/return; runtime may scale to recorded reload duration; never modify simulation reload_s',
                         'reload_scope': 'closed-hand reach to existing gun contact; no magazine/bolt/belt mechanism, ammo changes or inferred historical event'})
    return {'schema': 1, 'coordinates': 'metre; +Y up; -Z forward; existing hand mounts unchanged',
            'profiles': profiles,
            'upper_body_mask': ['spine', 'chest', 'neck', 'head', 'clavicle.L', 'clavicle.R', 'upper_arm.L', 'upper_arm.R', 'forearm.L', 'forearm.R', 'hand.L', 'hand.R'],
            'transitions': {'ready_to_aim': {'clip_key': 'raise', 'entry': {'clip_key': 'ready', 'phase': 0}, 'exit': {'clip_key': 'aim', 'phase': 0}, 'seconds': .3},
                            'aim_to_ready': {'clip_key': 'lower', 'entry': {'clip_key': 'aim', 'phase': 0}, 'exit': {'clip_key': 'ready', 'phase': 0}, 'seconds': .3},
                            'aim_fire_aim': {'clip_key': 'fire', 'entry': {'clip_key': 'aim', 'phase': 0}, 'exit': {'clip_key': 'aim', 'phase': 0}},
                            'aim_reload_aim': {'clip_key': 'reload_contact', 'entry': {'clip_key': 'aim', 'phase': 0}, 'exit': {'clip_key': 'aim', 'phase': 0}}},
            'integration': 'Optional candidates only. Runtime selects clips from copied historical weapon ID/events. Do not infer reload from current live ammo or block simulation on animation. Arbitrary seek/cancel/weapon-switch and locomotion masking require main author integration validation.'}
