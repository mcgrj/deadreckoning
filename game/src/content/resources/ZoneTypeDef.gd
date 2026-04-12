# ZoneTypeDef.gd
# Content definition for a route zone type (e.g. Coastal, Open Ocean).
# Stored as a .tres file under res://content/zone_types/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
# See also: docs/superpowers/specs/2026-04-12-difficulty-stack-design.md
class_name ZoneTypeDef
extends ContentBase

## Multiplier on food and water consumption per tick. Default 1.0.
@export var consumption_modifier: float = 1.0

## Multiplier on ship wear per tick. Default 1.0.
@export var ship_wear_modifier: float = 1.0

## Flat Burden change applied each tick in this zone.
@export var burden_delta_per_tick: int = 0

## Multiplier on incident trigger weight while in this zone. Default 1.0.
@export var incident_weight_modifier: float = 1.0

## Incident tags allowed in this zone. Empty = all tags allowed.
@export var eligible_incident_tags: Array[String] = []

## Incident tags suppressed (blocked) in this zone.
@export var suppressed_incident_tags: Array[String] = []
