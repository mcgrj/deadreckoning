# ShipUpgradeDef.gd
# Content definition for a ship upgrade available in the Admiralty preparation phase.
# Stored as a .tres file under res://content/upgrades/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ShipUpgradeDef
extends ContentBase

## Budget cost in the Admiralty preparation phase.
@export var preparation_cost: int = 0

## Passive effects applied to expedition state for the duration of the run.
@export var upgrade_effects: Array[EffectDef] = []

## Plain-language description of the tradeoff this upgrade creates.
@export var drawback_text: String = ""
