# SupplyDef.gd
# Content definition for an expedition supply type.
# Stored as a .tres file under res://content/supplies/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name SupplyDef
extends ContentBase

## True for Rum only — enables special-case Rum handling in Stage 2+.
@export var is_rum: bool = false

## Default quantity loaded at expedition start.
@export var starting_amount: int = 0

## Units consumed per travel tick.
@export var daily_consumption: int = 0

## Amount below which scarcity incidents can trigger.
@export var low_threshold: int = 0

## Amount below which critical incidents trigger.
@export var critical_threshold: int = 0
