# Dead Reckoning — Game Design Document
**Date:** 2026-04-14  
**Status:** Current state analysis — not an implementation plan  
**Source:** Full codebase and design spec review

---

## High Concept

*Dead Reckoning* is a simulation-driven maritime roguelike about commanding an age-of-sail expedition as authority collapses under hardship.

The player is the captain, not an avatar. They choose routes, set standing orders, rely on officers, ration supplies, make promises, conceal failures, and decide what the crew must endure. Each run is a finite expedition arc (~30 minutes) ending in success, mutiny, or breakdown. The run is then filed as a report to the Admiralty, shaping what resources, officers, and pressures the next expedition inherits.

---

## Design Pillars

| Pillar | Expression |
|---|---|
| **Human conflict first** | No combat. The enemy is hunger, fear, exhaustion, authority erosion. |
| **Emergent story through systems** | Authored incident templates triggered by simulation state, not a story generator. |
| **Authority as a resource** | Command is the captain's legitimacy. Every method of preserving it changes how it is understood. |
| **You cannot solve problems, only transform them** | Every positive choice takes a loan against a named future vulnerability. No choice is safe. |
| **Loss is story** | Mutiny, abandonment, and scandal feed the Admiralty layer and become retellable. |
| **Framework-driven content** | Data-driven resources (.tres, .json) so new incidents/officers/objectives require no code changes. |

---

## Gameplay Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    BETWEEN RUNS (Meta Layer)                │
│   ProgressionState: officer_pool, admiralty_bias,           │
│   scandal_flags, completed_objectives, unlocked_content     │
└────────────────────────┬────────────────────────────────────┘
                         │ persists to
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               PREPARATION SCENE                             │
│                                                             │
│  1. Admiralty Letter (bias → recommendations, greyed items) │
│  2. Select Objective  (6 options, tier 1–3 difficulty)      │
│  3. Select Doctrine   (unlocks standing orders)             │
│  4. Select Officers   (6 roles, one each from pool)         │
│     └─ See: traits, rumours, scars, promise requirements,   │
│            pre-departure stances                            │
│  5. Select Upgrades   (up to 2 + possible 1 free)           │
│                                                             │
│  → RunConfig assembled → SaveManager.pending_run_config     │
└────────────────────────┬────────────────────────────────────┘
                         │ Set Sail
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               RUN SCENE  (main loop)                        │
│                                                             │
│  ExpeditionState created:                                   │
│  • burden=0, command=100, supplies, ship=100                │
│  • officers loaded, scars active, promise seeded            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  NODE SELECTION (player clicks reachable node)       │  │
│  │  Route map: 4 stages × 2–3 nodes per stage           │  │
│  │  Node categories: crisis / landfall / social /       │  │
│  │  omen / boon / admiralty / unknown                    │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │ travel begins                         │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  TRAVEL TICK  (per day of travel; 2–4 ticks/leg)     │  │
│  │                                                       │  │
│  │  Each tick:                                           │  │
│  │  1. Check run-end (mutiny if cmd≤20, breakdown        │  │
│  │     if burden≥100)                                    │  │
│  │  2. Consume food/water (zone modifier)                │  │
│  │  3. Apply ship wear (zone modifier)                   │  │
│  │  4. Add zone burden_delta                             │  │
│  │  5. Increase travel_fatigue                           │  │
│  │  6. Update sickness_risk                              │  │
│  │  7. Apply rum rules (ration/theft/drunkenness)        │  │
│  │  8. Check incident trigger (weighted random)          │  │
│  └──────────────────┬───────────────────────────────────┘  │
│          if incident │ fires                                │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  INCIDENT RESOLUTION                                  │  │
│  │                                                       │  │
│  │  OfficerCouncil generates proposals:                  │  │
│  │  • Role-matched officer → choice card (effects,       │  │
│  │    risk text scaled by competence)                    │  │
│  │  • Unmatched officer → silence line (worldview)       │  │
│  │  • Always: "DIRECT ORDER" (captain acts alone)        │  │
│  │                                                       │  │
│  │  On confirm:                                          │  │
│  │  • Apply immediate effects (burden/command/supply)    │  │
│  │  • Set memory flags                                   │  │
│  │  • Nudge leadership tags                              │  │
│  │  • Write to ship log                                  │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │ continue travel                       │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  NODE ARRIVAL                                         │  │
│  │  • Optional node-arrival incident                     │  │
│  │  • Advance to next stage                              │  │
│  │  • Loop back to NODE SELECTION                        │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │ after stage 4 arrival                 │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │  RUN END (mutiny / breakdown / completion)            │  │
│  └──────────────────┬───────────────────────────────────┘  │
└─────────────────────┼───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│               RUN END SCENE                                 │
│                                                             │
│  1. Evaluate objective (memory flag check)                  │
│  2. Difficulty score = (peak_burden × 0.3) +               │
│     ((100 - min_command) × 0.3) + (crew_losses × 5) +      │
│     (supply_depletions × 3)  [clamped 0–100]                │
│  3. Apply run-end scars to all officers                     │
│     • crew_losses ≥ 2 → survivor_of_high_losses             │
│     • min_command ≤ 30 → witnessed_authority_collapse       │
│     • peak_burden ≥ 75 → endured_extreme_hardship           │
│  4. REPORT FRAMING (player selects how voyage is recorded)  │
│     → Writes bias string to admiralty_bias[]                │
│     → May write scandal_flag                                │
│  5. Commit officer scars + stat drift to pool               │
│  6. Replenish pool (≥2 candidates per role)                 │
│  7. Save ProgressionState                                   │
└────────────────────────┬────────────────────────────────────┘
                         │ return to
                         ▼
                  PREPARATION SCENE
                  (next run begins)
```

---

## Core Systems

### 1. The Two-Meter Model: Burden & Command

The entire simulation converges on two numbers.

**Burden** (0–100) — accumulated breaking load
- Rises from: hunger/thirst, zone hardship, fatigue, sickness, broken promises, omen incidents, supply exhaustion, failed punishments
- Falls from: rum rations, good landfall, rest, fair distribution, successful officer interventions
- At 100: immediate breakdown (run ends)

**Command** (0–100) — crew belief the captain's orders should be obeyed
- Rises from: kept promises, standing firm in crisis, decisiveness, sharing hardship
- Falls from: broken promises, officer dissent, concealed truth discovered, public incompetence, direct-order overuse
- At ≤20: probabilistic mutiny. Chance = (burden/100) × 0.4. Suppress Dissent halves it.

**Interaction:**

| State | Dynamic |
|---|---|
| High Burden + High Command | Grim endurance — the crew suffers but holds |
| Low Burden + High Command | Stable — most dangerous for complacency |
| Low Burden + Low Command | Political instability without immediate crisis |
| High Burden + Low Command | Mutiny zone — each tick is a coin flip |

### 2. Supply Economy

Three supplies active, each with mechanical depth:

| Supply | Starting | Consumption/tick | Critical threshold | Exhaustion penalty |
|---|---|---|---|---|
| Food | 200 | 5 × zone_modifier | 10 | Burden +6, flag: food_exhausted |
| Water | 200 | 3 × zone_modifier | 10 | Burden +8, flag: water_exhausted |
| Rum | 60 (if aboard) | Special (rum rules) | 0 | Burden +4, flag: rum_ration_ended |

**Rum is a first-class system** (RumRules.gd):
- Active ration: −1 burden/tick (morale valve)
- Store locked but expected: +2 burden/tick (grumbling)
- Ration exhausted after expectation: +4 burst + memory flag
- Theft risk = 30 + (100 − command)/2 → triggers incidents
- Drunkenness risk = 20 + rum_amount/5 → triggers incidents

**Key design tension:** Rum solves short-term burden but creates an expectation debt. The longer you run it, the worse running out feels.

### 3. Travel Simulation

Each route leg is 2–4 ticks. Zone type multiplies all passive drains:

| Zone | Burden Δ/tick | Consumption | Ship Wear | Incident Weight |
|---|---|---|---|---|
| Coastal | +0 | ×1.0 | ×0.8 | ×0.8 |
| Open Ocean | +1 | ×1.1 | ×1.0 | ×1.0 |
| Lee Shore | +0 | ×0.8 | ×0.2 | — |
| Unknown | +2 | ×1.2 | ×1.2 | ×1.2 |

**Incident trigger chance** per tick:
```
base (0.25)
+ (burden/100) × 0.30
+ ((100 − command)/100) × 0.20
+ (fatigue/100) × 0.15
+ (sickness/100) × 0.10
= max 0.85
```
Cooldown: same incident cannot re-fire within 5 ticks.

**Secondary meters** (feed incident chance but not run-end conditions):
- `travel_fatigue` — +1/tick, no cap mechanism currently
- `sickness_risk` — +3/tick when food/water critical, −1/tick when healthy
- `ship_condition` — decreases by zone wear modifier/tick; no current run-end threshold

### 4. Route Map

4 fixed stages, 2–3 node choices per stage. Node categories are visible before selection (color-coded), distance shown in ticks.

**Current test route:**

| Stage | Nodes | Zone |
|---|---|---|
| 1 | Crisis (3t), Landfall (4t), Omen (2t) | Coastal |
| 2 | Social (2t), Unknown (3t) | Open Ocean |
| 3 | Boon (2t, lee_shore), Admiralty (4t, open_ocean) | Mixed |
| 4 | Crisis (2t), Landfall (3t) | Unknown |

**Design intention:** Node category tells you what *kind* of problem, not *how bad*. The route tradeoff is never "safe vs dangerous" — it's "which kind of problem do I want?" The longer path bleeds you slowly; the shorter path hits hard.

### 5. Incident System

**Trigger bands:** tick (random per day), node (on arrival)
**Implemented:** 3 incidents (food_dispute, crew_fight, drunk_purser_store_error)
**Designed target:** 12+ for vertical slice

Each incident contains:
- Required conditions (burden_above, supply_below, has_memory_flag, officer_present, etc.)
- Weighted choices authored per officer role
- Immediate effects (burden/command/supply Δ)
- Memory flags set (persistent within run)
- Leadership tag nudge (harsh / merciful / honest / deceptive / etc.)
- Risk text scaled by officer competence

**Officer Council logic:**
1. Match incident choices to hired officer roles
2. Matched officer → proposal card with effects preview + risk text
3. Unmatched officer → silence line (worldview-specific)
4. Always append → DIRECT ORDER (captain bypasses council; −1 Command if repeated)

### 6. Standing Orders

Doctrines unlock standing orders. Orders are persistent tick-by-tick modifiers, not one-time choices.

| Order | Benefit | Cost | Debt type |
|---|---|---|---|
| Tighten Rationing | Food preserved | — | Expectation: future food incidents hit harder |
| Suppress Dissent | Mutiny chance ×0.5 | Burden +2/tick | Resentment: deferred, releases in burst |
| Share Officer Comforts | Burden reduction | — | Trust: later favoritism doubles Command loss |
| Hold Prayer | Burden −X (pious crew) | — | Exposure: cynical officer dissent banks |
| Rotate Sick Off Duty | Sickness reduction | Labor cost | — |
| Strict Watches | Incident suppression | Fatigue increase | Resentment: fatigue incident more likely |

**Design intent:** Standing orders are expectation debt machines. Every order that helps plants the seed of its own counter-incident.

### 7. Officer System

**6 mandatory roles per run:** first_lieutenant, master, gunner, purser, surgeon, chaplain

Each role has an information domain (what they reveal about the route):

| Officer | Information domain |
|---|---|
| Master | Route hazard accuracy, tick distances |
| Purser | Supply opportunity visibility at nodes |
| Surgeon | Crew risk / Burden trajectory forecasting |
| Chaplain | Omen node partial reveal |
| First Lieutenant | Discipline risk signals |
| Gunner | (not yet fully defined) |

**Procedural generation** (OfficerGenerator from JSON pools):
- Name, background fragments, competence/loyalty (1–5), worldview (disciplinarian / humanitarian / pragmatist)
- Traits in 3 tiers: **disclosed** (known at hire), **rumoured** (hinted at hire), **hidden** (surfaces mid-voyage under specific conditions)
- 50% chance of pre-departure stance
- 30% chance of pre-voyage promise (if competence ≥ 3)

**Scar system (cross-run persistence):**
- Provisional scars earned during run → committed to pool at run end via `SaveManager.commit_officer_scars()`
- Stat drift: loyalty/competence ±1 based on what happened to them
- Scars change incident eligibility and behavior in future runs (e.g., `ration_crisis_veteran` reads supply incidents more accurately; `publicly_overruled` reduces proposal willingness)
- Creates the **known-devil dynamic**: familiar officers have revealed hidden traits through shared history; new officers are unknown risks

**Officer selection tradeoff:**
- High competence officer → better intelligence, better proposals → carries a named hidden flaw, likely requires pre-voyage promise
- Low competence officer → worse information, worse proposals → no planted debt

### 8. Promise System

Tracks formal captain commitments. One promise active at a time.

**Lifecycle:**
1. Officer with `pre_voyage_promise_id` hired → promise seeded at run start (+3 Command on activation)
2. `tick_promise()` called each tick (auto-break at deadline; default deadline=999, effectively permanent)
3. Standing order or incident outcome calls `keep_promise()` or `break_promise()`

**Effects:**
- Keep: Command +5, Burden −3, memory flag `promise_kept_<id>`
- Break: Command −5, Burden +5, memory flag `promise_broken_<id>`

**Design intent:** The debt is real from the first screen. The player hired the officer knowing the promise. Breaking it is a choice, not a surprise.

### 9. Admiralty Meta-Progression

**Report framing** (post-run): player selects a narrative framing of the voyage.

| Framing | Bias string written | Scandal flag | Next-run effect |
|---|---|---|---|
| Suppress the Mutiny | suppressed_mutiny | — | Recommends iron_discipline doctrine |
| Blame the Crew | blamed_crew | — | first_lieutenant_lenient unavailable |
| Admit Command Failure | admitted_failure | — | Recommends loyal officer trait |

`admiralty_bias[]` and `scandal_flags[]` persist in ProgressionState. In PreparationScene:
- Some options greyed (unavailable) based on scandal
- Admiralty-recommended items carry bonus rewards (+supply or +command at run start)
- Possible free upgrade slot

**Unlock system:** Completing objectives marks `completed_objective_ids` → feeds `unlocked_content_ids`. Newly unlocked doctrines, upgrades, and officer types become available in next prep screen.

### 10. Debt Taxonomy

Every choice is designed against four named debt types. Authors must name the debt at authoring time and design the counter-incident that collects it within the same run.

| Debt type | Mechanism |
|---|---|
| **Expectation debt** | An action establishes a crew expectation. Violating it later triggers a sharper incident. |
| **Trust debt** | A promise or pattern is established. Breaking it damages Command non-linearly. |
| **Resentment debt** | Suppressed Burden banks behind a threshold. A single later provocation releases it all at once. |
| **Exposure debt** | A concealed truth is stored as a memory flag. A later incident can surface it, compounding damage. |

### 11. Six Value Collision Pairs

Every choice across all layers maps to at least one of these:

| Tension | What the player sacrifices either way |
|---|---|
| **Command vs Burden** | Enforce authority → crew resentment rises. Ease up → discipline erodes. |
| **Individual vs collective** | Save one officer's reputation → crew loses trust in fairness. Sacrifice them → loyalty risk. |
| **Honesty vs stability** | Tell the crew the truth about supplies → Burden spikes. Conceal it → Command risk when it surfaces. |
| **Mercy vs order** | Pardon the offender → precedent set, discipline weakens. Punish harshly → Burden rises, resentment deepens. |
| **Short-term survival vs long-term trust** | Ration cut now → food preserved, Burden spikes. Don't cut → food runs out later, crisis is worse. |
| **Speed vs endurance** | Push hard → reach the node faster, crew exhausted. Go slow → crew recovers, supplies drain further. |

---

## Balance Analysis

### Supply Pressure Curve

With starting food=200 at 5/tick, a ~20-tick run consumes 100 food — half the supply. Water at 3/tick consumes 60 of 200. **Supply pressure is currently very low.** The design calls for scarcity as a central tension, but current quantities mean neither food nor water is likely to exhaust in a normal run. Open Ocean's ×1.1 modifier only shaves a few extra ticks of buffer.

The rum system is better balanced: 60 units at 1/tick = 60-tick buffer, longer than any run, but the expectation debt created by distributing it is the real mechanic, not physical exhaustion.

### Burden/Command Pressure

Base burden delta from Open Ocean = +1/tick × ~20 ticks = +20 burden from zones alone — a meaningful 20% of the breakdown threshold. Combined with incident effects (+3 to +8 per incident) and supply exhaustion penalties (+6/+8), the player can realistically approach 100. This feels appropriately tuned.

Command at 100 starting is forgiving. Mutiny at ≤20 with 40% base rate means the player needs to lose 80 Command before mutiny is even possible — hard to do without catastrophically bad play. **The mutiny threat is not currently scary enough in a well-played run.**

### Incident Trigger Rate

At moderate burden/command, trigger chance ≈ 0.25 + 0.15 + 0.05 + 0.075 ≈ 0.525/tick. In a 3-tick leg that's ~86% chance of at least one incident. With only 3 authored incidents and a 5-tick cooldown per incident, **players will see the same 3 incidents repeatedly within a single run.** Content thinness is the biggest current gameplay issue.

### Three-Act Pacing Target

| Act | Target duration | Design intent |
|---|---|---|
| Act 1 — Control | ~8 min | Investment phase. Seeds planted, debts taken. 1–2 low-pressure incidents. |
| Act 2 — Fracture | ~14 min | Resources bite. Standing orders create counter-pressures. 2–3 harder incidents. |
| Act 3 — Collapse | ~8 min | 1–2 high-weight decisions carrying accumulated consequence. Memory flags surface. |

Current content (3 incidents, fixed route) cannot sustain this pacing arc. The framework is ready; the content is not.

---

## Design Decisions & Intentions

**Why no combat?**
Naval combat is a separate game. Dead Reckoning's thesis is that the hardest part of command is keeping your own crew functional under scarcity and fear. Combat would pull focus toward external threats and dilute the internal authority drama.

**Why Slay the Spire-style routing over freeform sailing?**
Freeform sailing risks traversal grind and content sprawl. The node map creates legible strategic decisions (which kind of problem?) without requiring the world to be filled with content at every coordinate.

**Why procedural officers instead of hand-authored?**
Hand-authored officer files would need to be written by the dozens to avoid repetition. Procedural generation from authored JSON fragments produces varied characters while keeping authoring tractable for a solo developer. Scars give procedural officers emotional weight over time — a character with three runs of shared history is not replaceable.

**Why data-driven content (.tres + .json)?**
New incidents, objectives, and standing orders must be addable without code changes. A game that lives on a growing incident library cannot have each incident be a code branch.

**Why report framing as a meta-mechanic?**
The Admiralty layer turns loss into authored material. A failed run that ends in mutiny should not feel like wasted time — the player chooses how the mutiny is remembered, and that choice shapes the next expedition's political context.

**Why a 30-minute run target?**
Cognitive research indicates high-stakes decision-making degrades after 20–25 minutes. A 30-minute run allows the debt-callback loop (plant in Act 1 → collect in Act 2/3) to complete satisfyingly within one session.

**Why name debt types at authoring time?**
Naming debt forces writers to design the counter-incident alongside the choice. This prevents "filler" choices that feel impactful but have no mechanical consequences. The gun on the mantle must fire before the run ends.

**Why group-level crew simulation?**
Full individual simulation produces too much noise for a 30-minute run where every decision must matter. Group Burden and Command with individual officers as catalysts keeps the model legible while still producing personal narrative.

---

## Gaps & Issues

### Critical (blocking good play)

**1. Incident library is too thin (3 of 12+ target)**
With trigger rates near 50% per tick and a ~20-tick run, players see the same 3 incidents within a single run. This is the single biggest gap between current state and a playable vertical slice. The system is fully capable; content is just unwritten.

**2. Route map is hardcoded, not procedurally generated**
`RouteMap.create_test_map()` creates one fixed route. Every run sees the same sequence of nodes. The design calls for a generated route per run (varying node types, stage lengths, zone assignments). Without this, meta-progression is the only source of run-to-run variety.

**3. Starting supplies are too generous**
200 food at 5/tick for a ~20-tick run means food almost never exhausts. Supply scarcity — intended as central tension — doesn't bite. Halving starting quantities (food ~80–100, water ~60) would create meaningful pressure without changing any systems.

**4. Ship condition has no run-end consequence**
Ship condition decreases each tick but reaching 0 has no effect. The design calls for damage tags (hull_strained, rigging_damaged, etc.) feeding into incidents and a potential shipwreck end state. Currently a display metric only.

**5. Officer information domains aren't surfaced at prep time**
The design intention is that officer quality changes what the player *knows* about the route before sailing (master reveals tick distances, purser reveals supply opportunities, surgeon gives Burden trajectory forecasts, etc.). This intelligence layer is designed but not implemented — officer selection is trait-inspection only, not intelligence purchasing.

### Significant (reducing depth)

**6. Crew loss mechanic not implemented**
`crew_losses` is tracked as a stress indicator and feeds scar thresholds, but officers cannot actually die or be removed during a run. Officer dismissal, court-martial, and death are designed as meaningful irreversible decisions but are not yet wired in.

**7. Mid-voyage promises are underutilized**
Only one promise can be active (from hire condition). The design envisions recurring mid-voyage promises as a core mechanic — "we will make landfall in three days," "no man goes without water." These would give Command-boosting moves that create Trust debt if missed.

**8. Standing orders aren't configured per route segment**
The design calls for standing orders to be set before each leg (per-segment tactical configuration). Currently they appear to be run-persistent. Per-segment orders would create more tactical decisions about when to spend costs and which leg needs which preparation.

**9. Leadership tags have no UI feedback**
`leadership_tags` accumulate (harsh/merciful/honest/deceptive) but are invisible to the player. The design intends these to influence officer proposals, unlock report framing options, and subtly shift incident text. Without visibility the player cannot sense their pattern forming.

**10. Mutiny threat is too weak**
Starting Command at 100 requires losing 80 points before mutiny is possible. With competent play this almost never happens. Raising the mutiny threshold (e.g., ≤30 instead of ≤20) or lowering starting Command (e.g., 75) would make the threat present in well-played runs.

### Minor / Polish

**11. Objective variety is shallow**
6 objectives but effectively 3 types: survey a node type (set memory flag), meet a condition at run end, recover something at a specific node. No objectives that require maintaining a state across multiple stages or responding to what happened during the run.

**12. Doctrine system is minimal**
2 doctrines implemented (Iron Discipline, Shared Hardship). Design specifies 5+ as content expansion targets. Each doctrine should change the character of standing orders available and shift incident-council dynamics.

**13. Admiralty bias effects are shallow**
Current bias effects: one item recommended, one greyed. The design envisions richer political memory — repeated framings shifting the Admiralty's personality, scandal flags compounding across runs, narrative callbacks in the Admiralty letter text.

**14. Crew backgrounds not implemented**
`CrewBackgroundDef` resource class exists and is designed, but no backgrounds are authored or selectable in prep. Pressed crew vs veteran crew vs mixed-nationality crew should meaningfully change starting conditions and incident availability.

**15. Officer information fidelity not wired to incident risk text**
A surgeon should give more accurate Burden forecasts. A compromised purser should give less accurate supply readings. This fidelity-from-competence interaction is designed but not connected through to the choice UI.

**16. RouteMapNode.gd has an uncommitted fix**
Boat positioning formula fix (`ticks_done` → `ticks_done + 0.5`) is staged in the working tree but uncommitted. Minor visual bug where the boat icon is offset during tick animation.

---

## Content Inventory (Current State)

| Category | Designed target | Implemented |
|---|---|---|
| Incidents | 12+ | 3 |
| Standing orders | 6 | 6 |
| Doctrines | 5+ | 2 |
| Ship upgrades | 6 | 3 |
| Objectives | 6 | 6 |
| Officer roles | 6 | 6 |
| Zone types | 4–5 | 4 |
| Crew backgrounds | 3+ | 0 (resource class exists) |
| Supply types | 6 | 3 (food, water, rum) |
| Promises (hire) | 6+ | ~8 authored in JSON |
| Report framings | 4–6 | 3 |
| Officer scars | 10+ | ~9 |

---

## Priority Order for Next Work

Ordered by impact on play quality:

1. **Incident content expansion** — most impactful for immediate play quality; system is fully capable
2. **Procedural route generation** — removes run-from-run sameness; RouteMap architecture exists
3. **Supply rebalance** — lower starting quantities to create scarcity tension in a 20-tick run; no system changes needed
4. **Ship condition failure state** — damage tags as incident conditions, potential shipwreck end condition
5. **Crew loss mechanics** — officer dismissal/death; feeds into scar system and council dynamics
6. **Leadership tag UI** — even a subtle visual signal creates the feedback loop the player needs to feel their pattern
7. **Crew backgrounds** — authored content only; resource structure exists
8. **Doctrine expansion** — each new doctrine expands the standing order menu; well-scoped authoring work
9. **Mid-voyage promises** — extends the promise system beyond hire conditions into the run itself
10. **Officer information domain display at prep** — the intelligence-purchasing layer that gives officer selection strategic depth
