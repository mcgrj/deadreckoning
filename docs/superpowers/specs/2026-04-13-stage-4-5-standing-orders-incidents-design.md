# Stage 4+5: Standing Orders, Officer Council & Incident Resolution — Design Spec

## Overview

Stages 4 and 5 are combined into a single implementation pass. They are not cleanly isolated: standing orders shape which incidents fire, and the officer council is the primary incident resolution interface. Building them separately would require scaffolding that gets thrown away.

**Goal:** The player can issue standing orders that shape the incident probability landscape, and resolves incidents through an officer council whose proposals reflect each officer's worldview.

**Approach:** Vertical slice first — one incident, two officers with authored proposals, one standing order that affects it — before generalising to the full content set.

---

## 1. Standing Orders

### Command-as-pool

Standing orders are maintained using the existing `command` stat as a resource pool. Each order has a `command_cost`; the player can hold as many orders as their current Command supports.

When Command drops below the total cost of active orders, the player is presented with a prompt to choose which order to cancel. This is a decision moment, not an automatic drop — the player must declare which doctrine to abandon under pressure.

Command costs are not uniform:

| Tier | Cost range | Examples |
|------|-----------|---------|
| Light | 5–8 | Hold Prayer, Maintain Log |
| Medium | 10–15 | Tighten Rationing, Double Watch |
| Heavy | 18–25 | Spirit Store Lockdown, Flogging Standing Order |

With Command starting at ~50, the player naturally holds 3–4 orders early and faces triage as Command erodes under burden.

### Tick effects (primary mechanical weight)

Standing orders do their main work in the simulation tick layer via `tick_effects[]` on `StandingOrderDef`. This is where the mechanical cost and benefit lives: supply adjustments, burden modifiers, command drain, fatigue effects. An order that isn't costing something every tick isn't a real commitment.

### Incident probability shaping (secondary layer)

Active standing orders shift the probability landscape of which incidents fire. They do not hard-gate incidents — fights can still break out without tightened rations, food disputes can still occur under a rationing regime. The standing order makes certain incidents more or less likely, not impossible.

This is implemented through a new field on `IncidentDef`:

```
weight_modifiers: Array  # [{ condition_type, condition_value, multiplier }]
```

The incident scanner collects all eligible incidents, applies weight modifiers against current `ExpeditionState`, then does **weighted random selection** from the eligible pool. Default weight is 1.0.

Example — `crew_fight`:
```
weight_modifiers = [
  { condition_type: "has_standing_order", condition_value: "tighten_rationing", multiplier: 2.0 }
]
```

Example — `food_dispute`:
```
weight_modifiers = [
  { condition_type: "has_standing_order", condition_value: "tighten_rationing", multiplier: 0.3 }
]
```

This requires a new `has_standing_order` condition type in `ConditionDef`, and `active_standing_orders: Array[String]` in `ExpeditionState`.

### Forecast text

`StandingOrderDef.forecast_text` surfaces both effects to the player before they commit: *"Tighten Rationing: food disputes become less likely. Tempers run shorter."* Not a guarantee — a tendency. The player authors the conditions; the simulation authors the incidents.

### incident_interactions field

`StandingOrderDef.incident_interactions[]` is retained as metadata only — it documents which incidents this order affects and is used to populate `forecast_text`. It is not executable logic; the actual interaction lives in `IncidentDef.weight_modifiers[]`.

---

## 2. Officer Council

### Proposal generation

When an incident fires, `OfficerCouncil` reads `ExpeditionState.officers[]` and the current incident id. Each officer whose `advice_hooks[]` contains the incident id generates a proposal. Officers with no matching hook appear in the council with a silence line — they are always visible, never absent.

Proposal structure:
```gdscript
{
  officer_id: String,
  proposal_text: String,    # in the officer's voice
  effects_preview: String,  # mechanical summary
  leadership_tag: String,   # which tag following this nudges
  risk_text: String         # downside; clarity scaled by competence
}
```

### Competence and advice clarity

Officer `competence` (1–5) controls how clearly the risk information is communicated. A competence 5 officer gives a sharp, accurate risk read. A competence 2 officer gives vague or incomplete risk text — they may omit the downside entirely. Players learn over time which officers to trust for accurate counsel.

### Silence lines

Officers with no matching advice hook appear with a short flavour line authored per officer worldview — not per incident. These are reused across all no-hook situations:

- Bosun (disciplinarian): *"Not my place to speak to this, sir. Your call."*
- Surgeon (humanitarian): *"I have no counsel here. I trust your judgement, Captain."*

No leadership tag nudge from silence lines.

### Direct Order

Direct Order is always present as a council option. It bypasses officer proposals, applies a default effect (typically no immediate mechanical change), and nudges `authoritarian` in `leadership_tags`. Used once it is a captain exercising prerogative; used repeatedly it builds a profile that later incidents can condition on.

### Leadership tag nudging

Following an officer's advice nudges the corresponding tag in `ExpeditionState.leadership_tags`:

| Source | Tag nudged |
|--------|-----------|
| Bosun (disciplinarian) | `harsh` |
| Surgeon (humanitarian) | `merciful` |
| Navigator (pragmatic) | `patient` |
| Direct Order | `authoritarian` |

Tags accumulate silently — no meter displayed. They feed into incident conditions and epilogue framing. Nudging means incrementing the tag's count by 1 in the `leadership_tags: Dictionary` on `ExpeditionState` (e.g. `leadership_tags["harsh"] += 1`). Tags that have never been nudged are absent from the dictionary; presence with count ≥ 1 is sufficient for condition checks.

---

## 3. Incident Resolution UI

### Scene: `IncidentResolutionScene`

Presented when `ExpeditionState.pending_incident_id` is set. The scene reads state from `ExpeditionState`, applies the chosen effect through `EffectProcessor`, then clears `pending_incident_id` and returns to the expedition view.

Wired into the existing debug scene for the vertical slice: when a pending incident exists, the output area is replaced by the resolution UI.

### Layout

```
┌─────────────────────────────────────────────────────────┐
│ INCIDENT HEADER (full width)                            │
│ Category label · Title · Flavour text · State snapshot  │
├──────────────────────────────┬──────────────────────────┤
│                              │ OFFICER COUNCIL          │
│  SCENE ART                   │ [Officer card — selectable] │
│  (TextureRect, ~2/3 width)   │ [Officer card — selectable] │
│                              │ [Direct Order card]      │
│                              │ ─────────────────────    │
│                              │ Silent officers (italic) │
└──────────────────────────────┴──────────────────────────┘
```

### Interaction model

There is no separate response bar. Officer cards are directly selectable:

1. Player clicks a card → card highlights, inline **CONFIRM** button appears
2. Player clicks CONFIRM → effect applied, scene dismissed
3. Clicking a different card deselects the previous one
4. Direct Order card follows the same select/confirm pattern

### Officer card states

| State | Visual |
|-------|--------|
| Unselected (has advice) | Normal border in officer colour |
| Selected | Green highlight, CONFIRM visible |
| Silent (no advice) | De-emphasised, italic flavour line, no confirm |
| Direct Order | Red-tinted, always present at bottom of council |

### Art panel

`IncidentDef` gains an `art_path: String` field. For the vertical slice this is empty — a placeholder colour fills the panel. A small set of category illustrations (crew conflict, storm, discovery, landfall) covers most incidents thematically until bespoke art is commissioned.

---

## 4. Data model changes

### New fields

**`IncidentDef`:**
- `weight_modifiers: Array` — `[{ condition_type: String, condition_value: String, multiplier: float }]`
- `art_path: String` — texture resource path, empty string for placeholder

**`ConditionDef`:**
- New condition type: `has_standing_order` — true if `condition_value` is in `ExpeditionState.active_standing_orders`

**`ExpeditionState`:**
- `active_standing_orders: Array[String]` — ids of currently enabled orders

### New classes

**`OfficerCouncil` (stateless):**
```gdscript
static func get_proposals(state: ExpeditionState, incident: IncidentDef) -> Array
# Returns Array of proposal Dictionaries for all present officers.
# Officers with no matching hook return a silence proposal.
```

### Modified systems

**`TravelSimulator.process_tick`** — incident trigger step changes from first-eligible-match to weighted random selection from eligible pool, using `IncidentDef.weight_modifiers` evaluated against current state.

---

## 5. Vertical slice content

The slice validates the full loop before generalising.

**Incident:** `purser_audit` — the purser's figures don't add up. Trigger band: `tick`. Required conditions: `burden_below: 60` plus one additional condition to prevent early-game firing — exact condition type confirmed against available `ConditionDef` types during implementation (e.g. a memory flag set after day 8, or `travel_fatigue_above: 5`).

**Officers with advice hooks:**
- Bosun → `purser_audit`: confine publicly, harsh leadership tag
- Surgeon → `purser_audit`: quiet private inquiry, merciful leadership tag

**Standing order:** `tighten_rationing` (already authored). Gains `weight_modifiers` on `food_dispute` (×0.3) and `crew_fight` (×2.0).

**Validation criteria:**
- `tighten_rationing` active → `food_dispute` fires less frequently over 20 ticks
- `tighten_rationing` active → `crew_fight` fires more frequently over 20 ticks
- `purser_audit` presents bosun and surgeon proposals
- Following bosun nudges `harsh` in leadership_tags
- Following surgeon nudges `merciful`
- Direct Order nudges `authoritarian`
- Command drops below order total → player sees cancel prompt
- Silent officers (carpenter, chaplain) appear with flavour lines

---

## 6. Out of scope for this stage

- Standing order management UI (player sets orders between incidents) — debug buttons suffice for the slice
- Full officer roster beyond bosun and surgeon
- Art assets — placeholder panel only
- Leadership tag downstream effects (incident conditions on tags, epilogue framing) — tags accumulate but are not yet consumed
- Multiple simultaneous incidents
