# WeightModifierDef.gd
# Inline Resource that adjusts an incident's selection weight when a condition is met.
# Embedded in IncidentDef.weight_modifiers.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
class_name WeightModifierDef
extends Resource

## Condition type to evaluate. Currently supports: "has_standing_order"
@export var condition_type: String = ""

## Value to check: for has_standing_order, this is the standing order id.
@export var condition_value: String = ""

## Multiplier applied to the incident's base weight (1.0) when condition is met.
## Values < 1.0 suppress the incident; values > 1.0 boost it.
@export var multiplier: float = 1.0
