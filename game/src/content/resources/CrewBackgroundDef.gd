# CrewBackgroundDef.gd
# Content definition for a crew background selected in the Admiralty preparation phase.
# Stored as a .tres file under res://content/crew_backgrounds/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name CrewBackgroundDef
extends ContentBase

## Crew trait tags applied to the expedition at start.
@export var starting_traits: Array[String] = []

## Command adjustment (positive or negative) applied at expedition start.
@export var starting_command_modifier: int = 0

## Burden adjustment (positive or negative) applied at expedition start.
@export var starting_burden_modifier: int = 0

## Flavour and mechanical summary shown in the Admiralty preparation screen.
@export var description: String = ""
