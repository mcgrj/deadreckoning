# ObjectiveDef.gd
# Content definition for an Admiralty run objective.
# Stored as a .tres file under res://content/objectives/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
# See also: docs/superpowers/specs/2026-04-12-run-objectives-design.md
class_name ObjectiveDef
extends ContentBase

## Objective type: "survey", "condition", or "recover".
@export var objective_type: String = ""

## Difficulty tier 1–3. Feeds Admiralty difficulty synthesis in Stage 6.
@export var difficulty_tier: int = 0

## Route node category that must appear on the route for survey and recover objectives.
@export var required_node_category: String = ""

## Condition evaluated at run end to determine success. Null = always succeeds.
@export var success_condition: ConditionDef = null

## Content id unlocked when this objective is completed successfully.
@export var unlock_on_success_id: String = ""

## Admiralty briefing text shown to the player in the preparation screen.
@export var description: String = ""
