# ConditionDef.gd
# Inline Resource representing one condition check against expedition state.
# Embedded inside IncidentDef and IncidentChoiceDef — not stored standalone.
#
# Valid types: burden_above, burden_below, command_above, command_below, supply_below,
#              has_damage_tag, has_memory_flag, has_crew_trait, officer_present, zone_type_is,
#              has_standing_order, officer_has_scar
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ConditionDef
extends Resource

## Condition type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric threshold for burden_above/below, command_above/below, supply_below.
@export var threshold: int = 0

## Memory flag key for has_memory_flag conditions.
@export var flag_key: String = ""

## Tag string for has_damage_tag, has_crew_trait, officer_present, zone_type_is, officer_has_scar.
@export var tag: String = ""

## Target id for supply_below (supply id), officer_present (officer id), officer_has_scar (officer id), etc.
@export var target_id: String = ""
