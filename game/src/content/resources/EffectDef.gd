# EffectDef.gd
# Inline Resource representing one discrete effect applied to expedition state.
# Embedded inside IncidentChoiceDef, StandingOrderDef, ShipUpgradeDef — not stored standalone.
#
# Valid types: burden_change, command_change, supply_change, ship_condition_change,
#              add_damage_tag, remove_damage_tag, set_memory_flag,
#              add_crew_trait, remove_crew_trait
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name EffectDef
extends Resource

## Effect type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric change for burden_change, command_change, supply_change, ship_condition_change.
@export var delta: int = 0

## Memory flag key for set_memory_flag effects.
@export var flag_key: String = ""

## Damage or crew trait tag for add/remove_damage_tag and add/remove_crew_trait effects.
@export var tag: String = ""
