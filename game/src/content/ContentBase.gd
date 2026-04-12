# ContentBase.gd
# Shared base Resource for all Dead Reckoning content definitions.
# Every content family Resource extends this class.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ContentBase
extends Resource

## Unique identifier within this content family. Snake_case. Required.
@export var id: String = ""

## Human-readable name shown in UI and debug output.
@export var display_name: String = ""

## Family-specific category tag (e.g. "crisis", "boon", "supply").
@export var category: String = ""

## Arbitrary searchable tags for filtering and incident eligibility.
@export var tags: Array[String] = []

## Strings evaluated by game code to gate visibility. Evaluated in Stage 5+.
@export var visibility_rules: Array[String] = []

## Id of the unlock that gates this content. Empty string = always available.
@export var unlock_source: String = ""

## Relative weight for random selection. Default 1.0.
@export var rarity_weight: float = 1.0
