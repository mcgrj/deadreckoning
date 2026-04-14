# OfficerDef.gd
# Content definition for a generated officer. Produced by OfficerGenerator — not hand-authored.
# Stored in ProgressionState.officer_pool between runs.
#
# Spec: docs/superpowers/specs/2026-04-14-emergent-officers-scars-design.md
class_name OfficerDef
extends ContentBase

## Officer role: "first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain".
@export var role: String = ""

## Advice accuracy, 1–5.
@export var competence: int = 0

## Proposal reliability, 1–5.
@export var loyalty: int = 0

## Personality worldview: "disciplinarian", "humanitarian", "pragmatist".
@export var worldview: String = ""

## Traits visible to the player at hire (disclosed tier).
@export var disclosed_traits: Array[String] = []

## Trait ids behind the rumours (parallel to rumoured_hints).
@export var rumoured_traits: Array[String] = []

## Hint text shown to the player for each rumoured trait (parallel to rumoured_traits).
@export var rumoured_hints: Array[String] = []

## Traits revealed only through specific incident conditions.
@export var hidden_traits: Array[String] = []

## Type of intelligence this officer provides: "route", "supply", "crew_risk", "omen", "discipline", "ship".
@export var information_domain: String = ""

## Promise id required for hire. Empty = no promise required.
@export var pre_voyage_promise_id: String = ""

## Promise text displayed when hire requires a promise.
@export var pre_voyage_promise_text: String = ""

## Pre-departure opinion line. Empty = officer says nothing before sailing.
@export var pre_departure_stance: String = ""

## Scar trait tags accumulated across runs and committed at run end.
@export var scar_traits: Array[String] = []

## Number of runs this officer has survived.
@export var runs_survived: int = 0

## Human-readable summaries of significant expedition events (shown in pool UI).
@export var notable_events: Array[String] = []

## Effects applied to ExpeditionState when this officer is selected at preparation.
@export var starting_effects: Array[EffectDef] = []

## Incident ids for which this officer has authored proposal choices. Legacy field —
## generated officers use role matching in OfficerCouncil instead.
@export var advice_hooks: Array[String] = []
