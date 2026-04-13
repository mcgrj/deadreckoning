# Stage 3: Route Map and Travel Ticks — Design Spec

**Goal:** Create the run skeleton — a branching route map, node selection, and travel tick simulation. The player chooses a path through a hand-authored test map, advances through daily ticks, and watches supplies, ship condition, Burden, and Command change under zone pressure.

**Architecture:** Pure data structures for route (`RouteNode`, `RouteMap`) with a separate factory method so procedural generation can be swapped in later without touching the rest of the system. `TravelSimulator` is a stateless tick processor that extends the Stage 2 simulation. Debug scene extended with a Route Map section rendered as BBCode in the existing output pane.

**Prerequisite:** Stage 2 expedition state and simulation rules (ExpeditionState, EffectProcessor, ConditionEvaluator, RumRules, SimulationLog).

---

## Future Route Generation Note

Stage 3 uses a hand-authored test route defined in a static factory method. The intended long-term approach is procedurally generated routes with authored constraints: each run generates a fresh route from rules (node count per stage, zone type weights, required-category guarantees for Admiralty objectives). When that arrives, `RouteMap.create_test_map()` becomes `RouteMap.generate(params)` returning the same `RouteMap` type — nothing else changes. The `required_node_category` field on `RouteNode` is the hook procedural generation will use to guarantee objective-required nodes appear.

---

## File Structure

```
res://
  src/
    expedition/
      (Stage 2 files unchanged)
      ExpeditionState.gd    ← add travel_fatigue, sickness_risk fields
      RouteNode.gd          ← single route node data class
      RouteMap.gd           ← full map: stages, position, factory, navigation
      TravelSimulator.gd    ← stateless tick processor
  content/
    zone_types/
      coastal.tres          ← exists
      open_ocean.tres       ← exists
      lee_shore.tres        ← new
      unknown_zone.tres     ← new
  test/
    ContentDebugScene.tscn  ← add Route Map sidebar section
    ContentDebugScene.gd    ← add route map rendering + tick UI logic
    RouteMapTest.tscn       ← new headless test scene
    RouteMapTest.gd         ← new headless test script
```

---

## ExpeditionState Additions

Two new fields added to `ExpeditionState.gd`:

| Field | Type | Default | Notes |
|---|---|---|---|
| `travel_fatigue` | int | 0 | 0–100, clamped. Accumulates each tick from travel. Feeds incident conditions in Stage 5. |
| `sickness_risk` | int | 0 | 0–100, clamped. Rises when food or water is critically low. Feeds incident conditions in Stage 5. |

Both are incremented by `TravelSimulator.process_tick()` and reset to 0 by `RouteMap` on arrival at a node (fatigue eases at landfall; sickness risk resets only if supplies recover).

---

## RouteNode

`RefCounted` data class. Not a Resource — route structure is a graph, not standalone content.

| Field | Type | Notes |
|---|---|---|
| `id` | String | Unique within the map. Snake_case. |
| `category` | String | One of: `crisis`, `landfall`, `social`, `omen`, `boon`, `admiralty`, `unknown` |
| `tick_distance` | int | Days of travel to reach this node from the previous stage. |
| `zone_type_id` | String | Id of a ZoneTypeDef. Applied during the ticks travelling to this node. |
| `hints` | Array[String] | Player-visible text: weather, hazard, supply opportunity, known risk. Shown in route display. |
| `is_objective_node` | bool | True if this node satisfies a survey/recover objective requirement. |
| `required_node_category` | String | Empty in Stage 3. Future hook: procedural generation sets this to guarantee a node of the given category appears in the stage. |

### Static factory helper

```gdscript
static func make(id: String, category: String, tick_distance: int, zone_type_id: String, hints: Array[String] = [], is_objective_node: bool = false, required_node_category: String = "") -> RouteNode
```

---

## RouteMap

`RefCounted`. Holds the full route structure and tracks position during a run.

### Fields

| Field | Type | Notes |
|---|---|---|
| `stages` | Array | Array of Array[RouteNode] — each inner array is one stage's choices |
| `current_stage_index` | int | Which stage the expedition is currently choosing from |
| `selected_path` | Array[RouteNode] | Nodes chosen so far (one per completed stage) |
| `active_node` | RouteNode | The node currently being travelled to (null if at a choice point) |
| `ticks_remaining` | int | Days of travel remaining to reach `active_node` |

### Methods

```gdscript
static func create_test_map() -> RouteMap
func get_current_stage() -> Array          # nodes available to choose from
func select_node(node: RouteNode) -> void  # begin travelling to a node
func is_travelling() -> bool               # true when ticks_remaining > 0
func is_complete() -> bool                 # true when all stages done
func advance_tick() -> void                # decrement ticks_remaining; if 0, arrive
func get_active_zone(registry: Node) -> ZoneTypeDef  # looks up active_node.zone_type_id
```

### Hand-authored test map

4 stages before arrival, covering all 7 node categories and all 4 MVP zone types:

| Stage | Node | Category | Days | Zone |
|---|---|---|---|---|
| 1 | `stage1_crisis` | crisis | 3 | coastal |
| 1 | `stage1_landfall` | landfall | 4 | coastal |
| 1 | `stage1_omen` | omen | 2 | coastal |
| 2 | `stage2_social` | social | 2 | open_ocean |
| 2 | `stage2_unknown` | unknown | 3 | open_ocean |
| 3 | `stage3_boon` | boon | 2 | lee_shore |
| 3 | `stage3_admiralty` | admiralty | 4 | open_ocean |
| 4 | `stage4_crisis` | crisis | 2 | unknown_zone |
| 4 | `stage4_landfall` | landfall | 3 | unknown_zone |
| Arrival | `arrival` | — | — | — |

Each node has 1–2 hint strings (e.g. `"Fog reported on the approach."`, `"Supply opportunity: fresh water."`, `"Hazard: reef shelf."`).

---

## TravelSimulator

Stateless utility. Single method:

```gdscript
static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void
```

### Tick sequence (order matters)

1. **Food consumption** — find the food supply via ContentRegistry (supply with category `"food"` or id `"food"`). Deduct `ceil(supply_def.daily_consumption * zone.consumption_modifier)` via EffectProcessor `supply_change`. If food hits 0: Burden +6, set memory flag `food_exhausted`.

2. **Water consumption** — same pattern as food, using `daily_consumption` and `zone.consumption_modifier`. If water hits 0: Burden +8, set memory flag `water_exhausted`.

3. **Ship wear** — apply `ship_condition_change` with delta `floor(-1 * zone.ship_wear_modifier)`. Minimum delta is -1 (always some wear at sea).

4. **Zone Burden delta** — apply `burden_change` with `zone.burden_delta_per_tick` if non-zero.

5. **Travel fatigue** — `state.travel_fatigue = clampi(state.travel_fatigue + 1, 0, 100)`. Log it.

6. **Sickness risk** — if food supply < food SupplyDef's `critical_threshold` or water supply < water SupplyDef's `critical_threshold`: `state.sickness_risk = clampi(state.sickness_risk + 3, 0, 100)`. Otherwise decay by 1 (minimum 0).

7. **Rum tick** — `RumRules.update_on_tick(state, log)`.

8. **Incident trigger check** — scan all IncidentDefs from ContentRegistry where `trigger_band == "tick"`. For each, run `ConditionEvaluator.all_met()` against required_conditions. If any pass and `state.pending_incident_id` is empty, set `state.pending_incident_id` to that incident's id and log a trigger event. First eligible match wins.

### ExpeditionState addition for incident trigger

One new field: `pending_incident_id: String = ""`. Set by TravelSimulator when a tick-band incident becomes eligible. Cleared by incident resolution (Stage 5). In Stage 3, the debug scene reads this field and shows a "Force Incident" button when it's non-empty.

---

## Zone Type Content

### `lee_shore.tres`

| Field | Value |
|---|---|
| id | `lee_shore` |
| display_name | `Lee Shore` |
| category | `hazard` |
| consumption_modifier | `1.0` |
| ship_wear_modifier | `1.8` |
| burden_delta_per_tick | `1` |
| incident_weight_modifier | `1.4` |
| eligible_incident_tags | `["storm", "navigation", "crisis"]` |
| suppressed_incident_tags | `[]` |

### `unknown_zone.tres`

| Field | Value |
|---|---|
| id | `unknown_zone` |
| display_name | `Unknown Waters` |
| category | `unknown` |
| consumption_modifier | `1.1` |
| ship_wear_modifier | `1.3` |
| burden_delta_per_tick | `2` |
| incident_weight_modifier | `2.0` |
| eligible_incident_tags | `[]` |
| suppressed_incident_tags | `[]` |

---

## Debug Scene — Route Map Section

New sidebar section below the existing Expedition Sim buttons: HSeparator, "Route Map" Label, then buttons.

### Sidebar additions

- **Show Route** — renders the full route map in the output pane
- **Advance Day** — processes one tick if actively travelling; re-renders route map after
- **Force Incident** — triggers a debug incident (see below)

The "Take [category] (N days)" selection buttons are rendered inline in the output pane as part of the route map display, not as permanent sidebar buttons. When the map renders, if the expedition is at a choice point (not travelling), the output pane includes action buttons at the bottom for each available node in the current stage.

### Route map rendering (BBCode)

The output pane shows:

**Header block:**
```
SHIP'S LOG
Day 11

ZONE              STATE
Open Ocean        Burden 34   Command 62
1.2× wear         Food 47     Water 38
```

**Vertical stage diagram:**
- Current stage: full brightness, node cards with category name (colour-coded), proportional `█` bar (1 `█` per tick_distance), days label, hint text
- Future stages: faded (using `[color=#333333]`)
- Arrival: very faded
- Arrow spacers between stages scale with tick count (1 `↓` per 2 days of the shortest node in the upcoming stage; minimum 1 arrow)

**Category colours (BBCode):**
| Category | Colour |
|---|---|
| crisis | `#ff9966` |
| landfall | `#88ff88` |
| social | `#ffdd66` |
| omen | `#cc88ff` |
| boon | `#aaffaa` |
| admiralty | `#ffccaa` |
| unknown | `#88ccff` |

**When at a choice point** — action buttons below the diagram:
```
[Take SOCIAL — 2 days]   [Take UNKNOWN — 3 days]
```

**When travelling** — progress indicator:
```
Travelling to SOCIAL (Open Ocean)
Day 2 of 2  ██░  arrival tomorrow
```

### Force Incident button

Behaviour:
1. If `state.pending_incident_id` is non-empty: load that IncidentDef from ContentRegistry, apply the first choice's `immediate_effects` via EffectProcessor, set `memory_flags_set` flags, log the `log_text`, clear `pending_incident_id`.
2. If `state.pending_incident_id` is empty: scan tick-band incidents for any eligible one and trigger it. If still none: apply a hardcoded fallback — Burden +5, `add_damage_tag "storm_damage"`, log "A squall strikes without warning."

---

## Headless Test Suite

`RouteMapTest.gd` — same pattern as Stage 2 tests.

### Test groups

1. **RouteNode** — field defaults, `make()` factory, all fields round-trip.
2. **RouteMap factory** — `create_test_map()` returns 4 stages, correct node counts, correct categories and zone ids, all 4 zone types present.
3. **RouteMap navigation** — `select_node()` sets `active_node` and `ticks_remaining`, `advance_tick()` decrements, arrival when `ticks_remaining == 0`, `is_complete()` after all stages done.
4. **TravelSimulator food/water consumption** — supplies decrease each tick, scaled by zone modifier.
5. **TravelSimulator ship wear** — ship condition decreases, scaled by zone wear modifier.
6. **TravelSimulator Burden delta** — zone burden_delta_per_tick applied correctly.
7. **TravelSimulator fatigue** — travel_fatigue increments each tick.
8. **TravelSimulator sickness risk** — rises when food below critical threshold, decays otherwise.
9. **TravelSimulator food exhaustion** — Burden spike and memory flag when food hits 0.
10. **TravelSimulator incident trigger check** — eligible tick-band incident sets pending_incident_id.
11. **Zone types** — lee_shore and unknown_zone load from ContentRegistry with correct fields.

---

## Testable Outcome

- The player can choose a path through the hand-authored test map, advance through daily ticks, and see supplies, ship condition, Burden, and Command change under zone pressure.
- All 4 MVP zone types are present in the test map and apply correctly.
- The debug scene shows the route map as a vertical stage diagram with the ship's log header, colour-coded nodes, proportional distance bars, and "Take X" selection buttons.
- The Force Incident button triggers a debug incident (or fallback) and shows the result.
- All headless tests pass. Stage 1 and Stage 2 tests continue to pass.

---

## What This Stage Excludes

- Procedural route generation.
- Full incident resolution UI (Stage 5).
- Admiralty preparation budget (Stage 6A).
- Polished visuals or final game UI.
- Standing order tick application (Stage 4).
- Officer council (Stage 4).
