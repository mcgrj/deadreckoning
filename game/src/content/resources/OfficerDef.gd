# OfficerDef.gd
# Content definition for an officer or notable crew member.
# Stored as a .tres file under res://content/officers/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name OfficerDef
extends ContentBase

## Officer role: "bosun", "surgeon", "purser", "chaplain", "first_mate", "lieutenant", etc.
@export var role: String = ""

## Advice accuracy, 1–5.
@export var competence: int = 0

## Proposal reliability, 1–5.
@export var loyalty: int = 0

## Personality worldview: "disciplinarian", "humanitarian", "pragmatist", etc.
@export var worldview: String = ""

## Traits visible to the player from expedition start.
@export var known_traits: Array[String] = []

## Traits revealed through incidents.
@export var hidden_traits: Array[String] = []

## Incident ids for which this officer has authored proposal choices.
@export var advice_hooks: Array[String] = []

## Effects applied to ExpeditionState when this officer is selected at preparation.
@export var starting_effects: Array[EffectDef] = []
