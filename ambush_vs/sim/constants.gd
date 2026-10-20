extends RefCounted
class_name SimConstants

## Frozen clock and enums for Ambush VS W2 sim (TERMS_AND_TICK_ORDER).

const TICK_HZ := 20
const DT_S := 0.05

const PHASE_SETUP := "setup"
const PHASE_WAIT := "wait"
const PHASE_DETONATE := "detonate"
const PHASE_RESOLVE := "resolve" ## post-detonate resolve (events schema also allows sweep)

const ALERT_QUIET := "quiet"
const ALERT_SUSPICIOUS := "suspicious"
const ALERT_AREA := "area_alert"
const ALERT_GLOBAL := "global_alert"

const TIER_GROUND := "ground"
const TIER_HIGH := "high"

const EXPOSE_TO_SUSPICIOUS_TICKS := 30
const AREA_TO_GLOBAL_TICKS := 30
const SUSPICIOUS_RECOVER_TICKS := 80

const TURN_COST_S_PER_45 := 1.0
const CLIMB_COST_S := 2.0

const SILHOUETTE_MUL := 1.5
const CARRY_SUSPICIOUS_RANGE_MUL := 1.3 ## T4: scout-carried suspicious → sentry/patrol cone range ×1.3 for the whole night

## Range band cutoffs (meters = cells). Shots-needed from weapons.csv.
const RANGE_NEAR_MAX := 5.0
const RANGE_MID_MAX := 10.0
const RANGE_FAR_MAX := 16.0

## PLAY-6 combat reaction (ADR-TRIGGER §3.4 / DEV_PLAN W5).
const COVER_SEEK_RADIUS := 4
const FLEE_STRENGTH_RATIO := 0.34 ## flee when living/entered_at_detonate below this
const OP_MAX_HP := 3
const ENEMY_RETURN_RPM := 220.0 ## lands a wound during a ~1 s post-detonate fight
const ENEMY_RETURN_RANGE := 12.0
## T6 explicit return-fire difficulty. Default is the hard tier (no per-enemy cap).
## Assist tier keeps the old PLAY-6 soft cap; both remain tunable after blind playtests.
const RETURN_FIRE_ASSIST_DEFAULT := false ## owner-defaulted T6 recommendation A; retune after blind test
const RETURN_FIRE_ASSIST_MAX_HITS_PER_ENEMY := 1 ## wounding hits per enemy while assist is ON
const COMBAT_STEP_CELLS := 2.2 ## cells/s toward cover or exit
const WOUNDED_RPM_MUL := 0.65 ## wounded operators fire slower
const DEFAULT_AMMO := {
	"kar98k": 20,
	"mp40": 48,
	"mg42": 28,
	"grenade": 0,
	"mine": 0,
}
## Weapon → ammo pool_id (matches yard loadout_start / scout kit).
const WEAPON_AMMO_POOL := {
	"kar98k": "7.92",
	"mg42": "7.92",
	"mp40": "9mm",
}
