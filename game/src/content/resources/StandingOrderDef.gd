# StandingOrderDef.gd
# Content definition for a standing order the player can issue before route segments.
# Stored as a .tres file under res://content/standing_orders/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name StandingOrderDef
extends ContentBase

## Command bandwidth consumed while this order is active.
@export var command_cost: int = 0

## Crew labor consumed per tick while this order is active.
@export var labor_cost: int = 0

## Supply id consumed per tick, if any (e.g. "medicine"). Empty = no supply cost.
@export var supply_cost_type: String = ""

## Units of supply_cost_type consumed per tick.
@export var supply_cost_amount: int = 0

## Evocative risk-language forecast shown to the player before selection.
@export var forecast_text: String = ""

## Effects applied each tick while this order is active.
@export var tick_effects: Array[EffectDef] = []

## Incident ids whose resolution this order modifies when active.
@export var incident_interactions: Array[String] = []
