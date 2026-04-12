# Run Objectives Design

## Purpose

This document defines the run objectives system for Dead Reckoning — a formalization of the "Admiralty objective or political constraint" already present in the implementation roadmap as a preparation budget element. It expands that into a load-bearing mechanic with a typed content framework, Admiralty shortlist selection, and a tradeoff-based unlock reward for success.

## Summary

At the start of each run, the Admiralty presents the player with a shortlist of 2–3 objectives filtered by run history, political priorities, and current unlock state. The player picks one. Completing it is hard. Success unlocks a new content item — a new officer archetype, ship upgrade, crew background, or doctrine — that expands the possibility space of future runs. Every unlock follows the existing design rule: it creates a new problem alongside its new capability.

## Where It Lives In The Run Flow

Objective selection happens at the preparation screen, before the run begins — the same moment the player chooses ship upgrades, officers, supplies, and doctrine. It is not a separate screen; it is part of the existing preparation budget flow.

The Admiralty presents a shortlist of 2–3 objectives. The player picks one. This is not negotiation from a blank slate — the Admiralty has priorities, and the player chooses within what the institution is willing to sanction. The framing is deliberate: the player has limited room to push back.

The active objective is visible throughout the run alongside Burden, Command, supplies, and active promises. It is not hidden. Players can see at all times whether they are on track.

Objective state is tracked through the existing run memory flag system:

- `objective_accepted`
- `objective_succeeded`
- `objective_failed`

Later incidents, officer advice, and ship log entries can reference these flags exactly as they reference any other memory. If a mid-run incident puts the objective at risk, officers may comment on it. If it fails, the ship log records it. If it succeeds, it becomes a claim in the Admiralty report.

At run end, the objective outcome feeds the Admiralty report layer: success shapes what the player can credibly claim; failure shapes what must be explained, concealed, or blamed on circumstances.

## Objective Types (MVP Taxonomy)

Three types for the MVP. Each has a distinct mechanical signature and a distinct relationship to route planning.

### Survey

Reach a specific node category and complete what happens there.

> "Chart the northern approach." "Document the settlement at the island's eastern shore."

The route map already has node categories. A survey objective adds a required stop or endpoint. It shapes which path the player chooses without dictating an exact route — the player still decides how to get there and what risk they take along the way.

Survey objectives pressure route selection. A safer but longer path may be incompatible with reaching the required node before supplies run out.

### Condition

Arrive at the run's end with a specific state intact.

> "Return with no fewer than two-thirds of the crew." "Deliver the sealed orders without opening them." "Keep Command from breaking."

These create tension with how the player would otherwise resolve incidents. A player who would normally spend Command to suppress a mutiny must consider whether the objective punishes that. A player who would abandon the sick to move faster must weigh crew count against speed.

Condition objectives pressure judgment across the whole run, not just at one moment.

### Recover

Acquire something from a specific location and return with it.

> "Recover the charts from the wreck." "Bring back evidence of the rival vessel's conduct."

A destination objective with a second leg. The player must reach a place, acquire the objective item through whatever the node demands, and return. This naturally extends run pressure and strains supplies across both halves of the voyage.

Recover objectives pressure logistics and return planning.

## Content Framework

Objectives are defined as Godot custom Resources (`ObjectiveDef`) under `res://content/objectives/*.tres`. Adding a new objective requires authoring one `.tres` file. No core code changes are required.

### ObjectiveDef Contract

| Field | Type | Purpose |
|---|---|---|
| `id` | String | Unique identifier |
| `category` | Enum | `survey` / `condition` / `recover` |
| `display_name` | String | Shown on preparation screen |
| `admiralty_briefing` | String | Short in-world text — the Admiralty's framing |
| `requirements` | Array[ConditionDef] | Filters shortlist eligibility: unlock state, run history, memory flags |
| `route_hook` | NodeCategoryRef | Survey and recover: required node category or destination marker |
| `success_condition` | ConditionDef | What must be true at resolution |
| `failure_condition` | ConditionDef | What triggers failure (default: run ends without success) |
| `on_accept_effects` | Array[EffectDef] | Immediate effects when player accepts the objective |
| `on_success_effects` | Array[EffectDef] | State changes on success, plus unlock reference |
| `on_failure_effects` | Array[EffectDef] | State changes on failure |
| `unlock` | ResourceRef | Reference to the content item unlocked on success |
| `log_hooks` | Array[LogHookDef] | Ship log entries at accept, success, and failure |
| `admiralty_report_hooks` | Array[ReportHookDef] | What success or failure makes available to claim or conceal |
| `weighting` | float | Shortlist appearance weight |

`ObjectiveDef` uses `ConditionDef` and `EffectDef` — the same types used across incidents, standing orders, and other content families. The unlock field references an existing content item rather than defining a new unlock type.

### Shortlist Generation

The Admiralty shortlist presents 2–3 objectives filtered by:

- Current unlock state (already-unlocked objectives do not appear)
- Run history and active memory flags
- Admiralty political bias (deferred to Stage 6B)
- Objective weighting

The shortlist is generated at the start of the preparation screen and does not change during preparation.

## Reward Structure

Each objective has exactly one unlock attached to it. The unlock is always a tradeoff-based content addition consistent with the existing design rule:

> Every unlock asks: what new problem does this new tool create?

No unlock is a net positive. If playtesting produces an unlock that feels like a free upgrade, it needs a sharper drawback or it is cut.

Unlock type follows objective category:

- **Survey → route intel or navigator-class officer.** You proved you can reach difficult places. A navigator expands route visibility but creates a politically observant officer who may report back to the Admiralty. Better charts reveal more of the route but introduce false confidence from outdated information.
- **Condition → doctrine or crew background.** You demonstrated a specific command discipline. A shared hardship doctrine reduces Burden but weakens hierarchy. A veteran crew background lowers Burden spikes but raises demands for captain competence.
- **Recover → ship upgrade or logistics package.** You proved logistical capability under pressure. An expanded spirit locker gives more Rum but raises theft and drunkenness risk. Better boats improve Landfall survival odds but reduce repair stock.

### MVP Content Cap

Consistent with the vertical slice content cap in the implementation roadmap:

- 2–3 authored objectives per type
- 6–9 total objectives at MVP
- One unlock per objective

These are not final limits. The framework supports expansion without code changes.

## Integration With Existing Systems

### Preparation Budget

Objective selection is part of the preparation budget flow (Stage 6A). It does not cost budget points — it is a commission, not a purchase. The player accepts it as a condition of the expedition.

### Route Map

Survey and recover objectives may add a required node marker to the generated route. The route generator must be able to place a required-category node when an objective demands it. This is a Stage 3 / Stage 6A integration point.

### Incident System

Incidents can reference objective state via memory flags. An officer may comment on an objective at risk. A social incident may offer a shortcut that invalidates a condition objective. A recover objective's target may be damaged or stolen by an earlier crisis. These interactions are authored in incident and officer templates, not in objective code.

### Ship Log

Objective accept, success, and failure each produce a ship log entry via `log_hooks`. The log records the commission, the outcome, and the Admiralty's likely interpretation.

### Admiralty Report

Objective success or failure shapes the post-run report framing. Success makes heroic or competent claims available. Failure may need to be explained, concealed, or blamed on crew, weather, or circumstances. `admiralty_report_hooks` on `ObjectiveDef` define what becomes available in the report framing choices.

## Implementation Staging

| Stage | Work |
|---|---|
| Stage 1 | Define `ObjectiveDef` Resource class and add to content framework alongside other content families |
| Stage 2 | Add objective state (accepted / succeeded / failed) to expedition state; add objective memory flags |
| Stage 3 | Route generator supports required-node placement for survey and recover objectives |
| Stage 6A | Preparation screen includes Admiralty shortlist and objective selection; unlock delivery on success |
| Stage 6B | Admiralty political bias shapes shortlist weighting; report hooks active |

## What To Avoid

Do not make any unlock a pure upgrade. The unlock economy must stay tradeoff-based across all objectives or the design pillar erodes.

Do not build a complex shortlist political simulation at MVP. The shortlist filter uses unlock state and run history. Admiralty political bias is a Stage 6B concern.

Do not let objectives override route agency. A required node constrains the route but does not eliminate player choice. The player still chooses how to get there and what risk to accept.
