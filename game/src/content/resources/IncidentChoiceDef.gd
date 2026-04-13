# IncidentChoiceDef.gd
# Inline Resource representing one player-facing choice within an incident.
# Embedded in IncidentDef.choices — not stored standalone.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name IncidentChoiceDef
extends Resource

## The choice option text shown to the player.
@export var choice_text: String = ""

## Officer id who proposes this choice. Empty = captain's own option.
@export var officer_id: String = ""

## All conditions must pass for this choice to appear.
@export var required_conditions: Array[ConditionDef] = []

## Effects applied immediately when the player selects this choice.
@export var immediate_effects: Array[EffectDef] = []

## Memory flags written to run memory when this choice is selected.
@export var memory_flags_set: Array[String] = []

## Ship log entry written when this choice is selected.
@export var log_text: String = ""

## Leadership tag nudged when player follows this officer's advice.
## One of: harsh, merciful, honest, deceptive, shared_hardship, privilege, authoritarian, patient.
@export var leadership_tag: String = ""

## Short mechanical summary shown to the player before confirming. E.g. "Burden −4, Command +2".
@export var effects_preview: String = ""

## Downside or risk text. Clarity is scaled by officer competence in the UI.
@export var risk_text: String = ""
