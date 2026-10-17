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

## Range band cutoffs (meters = cells). Shots-needed from weapons.csv.
const RANGE_NEAR_MAX := 5.0
const RANGE_MID_MAX := 10.0
const RANGE_FAR_MAX := 16.0
