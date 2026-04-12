# IncidentDef.gd
# Content definition for a triggered incident (crisis, omen, social, etc.).
# Stored as a .tres file under res://content/incidents/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name IncidentDef
extends ContentBase

## When this incident can fire: "tick", "node", "aftermath", or "threshold".
@export var trigger_band: String = ""

## All conditions must pass for this incident to be eligible to fire.
@export var required_conditions: Array[ConditionDef] = []

## Optional conditions that modify weight or narrative text when met.
@export var amplifier_conditions: Array[ConditionDef] = []

## Officer or notable ids that must be present in the roster for this incident.
@export var cast_roles: Array[String] = []

## Zone tags that allow this incident. Empty = eligible in any zone.
@export var eligible_zone_tags: Array[String] = []

## Zone tags that suppress this incident from firing.
@export var suppressed_zone_tags: Array[String] = []

## Standing order ids that interact with this incident's resolution.
@export var standing_order_interactions: Array[String] = []

## Player-facing options for resolving this incident.
@export var choices: Array[IncidentChoiceDef] = []

## Ship log entry template written when this incident fires.
@export var log_text_template: String = ""
