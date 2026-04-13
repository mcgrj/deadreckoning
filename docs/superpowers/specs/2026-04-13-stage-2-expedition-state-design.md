# Stage 2: Core Expedition State and Simulation Rules — Design Spec

**Goal:** Implement the core state model that future route ticks and incidents manipulate. All state changes are driven by content-defined EffectDefs and evaluated by content-defined ConditionDefs. A debug/explanation log answers "why did this happen?" for every state change.

**Architecture:** Single `ExpeditionState` object + stateless `EffectProcessor` and `ConditionEvaluator` utilities + `RumRules` special-case handler + `SimulationLog` explanation log. Interactive debug scene extends Stage 1's ContentDebugScene.

**Prerequisite:** Stage 1 content framework (ContentBase, ContentRegistry, ContentValidator, all typed Resource definitions, sample .tres content).

---

## File Structure

```
res://
  src/
    expedition/
      ExpeditionState.gd       ← mutable run state bag
      EffectProcessor.gd       ← stateless effect applicator
      ConditionEvaluator.gd    ← stateless condition checker
      RumRules.gd              ← Rum special-case tick logic
      SimulationLog.gd         ← append-only explanation log
    content/
      (unchanged from Stage 1)
      resources/
        EffectDef.gd           ← add target_id field
        ConditionDef.gd        ← add target_id field
  test/
    ContentDebugScene.tscn     ← extended with Expedition Sim section
    ContentDebugScene.gd       ← extended with expedition sim UI logic
    ExpeditionStateTest.tscn   ← headless test scene
    ExpeditionStateTest.gd     ← headless test script
```

---

## Schema Changes to Stage 1

### EffectDef — add `target_id`

| Field | Type | Notes |
|---|---|---|
| `target_id` | String | Supply id for `supply_change`, officer id for officer-targeting effects. Default empty. |

Existing fields (`type`, `delta`, `flag_key`, `tag`) unchanged.

### ConditionDef — add `target_id`

| Field | Type | Notes |
|---|---|---|
| `target_id` | String | Supply id for `supply_below`, officer id for `officer_present`. Default empty. |

Existing fields (`type`, `threshold`, `flag_key`, `tag`) unchanged. The `officer_present` condition type will use `target_id` instead of overloading `tag` — cleaner semantics.

---

## ExpeditionState

A `RefCounted` class holding all mutable expedition state. No signals, no autoload — instantiated directly by game code and the debug scene.

### Fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `burden` | int | 20 | 0–100, clamped |
| `command` | int | 70 | 0–100, clamped |
| `supplies` | Dictionary | {} | `{ supply_id: int }` — populated from SupplyDefs |
| `ship_condition` | int | 100 | 0–100, clamped |
| `damage_tags` | Array[String] | [] | Active damage tags on the ship |
| `crew_traits` | Array[String] | [] | Active crew-level traits |
| `officers` | Array[String] | [] | Officer def ids present on this run |
| `standing_orders` | Array[String] | [] | Active standing order ids |
| `active_promise` | Dictionary | {} | `{ id: String, text: String, deadline_ticks: int, ticks_remaining: int }` or empty |
| `leadership_tags` | Dictionary | {} | `{ "harsh": int, "merciful": int, "honest": int, "deceptive": int, "shared_hardship": int, "privilege": int }` |
| `memory_flags` | Array[String] | [] | Run memory flags |
| `rum_ration_expected` | bool | false | Crew expects a daily rum ration |
| `spirit_store_locked` | bool | false | Captain has locked the spirit store |
| `rum_theft_risk` | int | 0 | 0–100 |
| `rum_drunkenness_risk` | int | 0 | 0–100 |
| `tick_count` | int | 0 | Travel ticks elapsed |
| `stress_indicators` | Dictionary | {} | `{ peak_burden: int, min_command: int, crew_losses: int, supply_depletions: int }` |

### Factory Method

```
static func create_default() -> ExpeditionState
```

- Reads all SupplyDefs from ContentRegistry, populates `supplies` with `starting_amount` values.
- Sets `burden = 20`, `command = 70`, `ship_condition = 100`.
- Initializes `leadership_tags` with all six axes at 0.
- Initializes `stress_indicators` with `peak_burden = 20`, `min_command = 70`, `crew_losses = 0`, `supply_depletions = 0`.
- Reads all OfficerDefs from ContentRegistry, populates `officers` with their ids.
- Sets `rum_ration_expected = true` if any supply has `is_rum = true` and `starting_amount > 0`.

### Utility Methods

```
func get_supply(supply_id: String) -> int
func set_supply(supply_id: String, amount: int) -> void   # clamps to >= 0
func has_damage_tag(tag: String) -> bool
func add_damage_tag(tag: String) -> void                   # no-op if present
func remove_damage_tag(tag: String) -> void                # no-op if absent
func has_memory_flag(flag: String) -> bool
func add_memory_flag(flag: String) -> void                 # no-op if present
func has_crew_trait(trait: String) -> bool
func add_crew_trait(trait: String) -> void                 # no-op if present
func remove_crew_trait(trait: String) -> void              # no-op if absent
func has_officer(officer_id: String) -> bool
```

---

## EffectProcessor

Static utility class. No state.

### Core Method

```
static func apply(state: ExpeditionState, effect: EffectDef, log: SimulationLog) -> void
```

Dispatch on `effect.type`:

| Type | Action |
|---|---|
| `burden_change` | `state.burden += effect.delta`, clamp 0–100. Update `stress_indicators.peak_burden` if new value is higher. |
| `command_change` | `state.command += effect.delta`, clamp 0–100. Update `stress_indicators.min_command` if new value is lower. |
| `supply_change` | `state.set_supply(effect.target_id, state.get_supply(effect.target_id) + effect.delta)`. If supply reaches 0, increment `stress_indicators.supply_depletions`. |
| `ship_condition_change` | `state.ship_condition += effect.delta`, clamp 0–100. |
| `add_damage_tag` | `state.add_damage_tag(effect.tag)` |
| `remove_damage_tag` | `state.remove_damage_tag(effect.tag)` |
| `set_memory_flag` | `state.add_memory_flag(effect.flag_key)` |
| `add_crew_trait` | `state.add_crew_trait(effect.tag)` |
| `remove_crew_trait` | `state.remove_crew_trait(effect.tag)` |

Every call logs an entry to `SimulationLog` with before/after values.

Unknown effect types log a warning and are skipped (validation should catch these at load time).

### Batch Method

```
static func apply_effects(state: ExpeditionState, effects: Array, log: SimulationLog) -> void
```

Applies each effect in order.

---

## ConditionEvaluator

Static utility class. No state.

### Core Method

```
static func evaluate(state: ExpeditionState, condition: ConditionDef, log: SimulationLog) -> bool
```

Dispatch on `condition.type`:

| Type | Evaluation |
|---|---|
| `burden_above` | `state.burden >= condition.threshold` |
| `burden_below` | `state.burden <= condition.threshold` |
| `command_above` | `state.command >= condition.threshold` |
| `command_below` | `state.command <= condition.threshold` |
| `supply_below` | `state.get_supply(condition.target_id) <= condition.threshold` |
| `has_damage_tag` | `state.has_damage_tag(condition.tag)` |
| `has_memory_flag` | `state.has_memory_flag(condition.flag_key)` |
| `has_crew_trait` | `state.has_crew_trait(condition.tag)` |
| `officer_present` | `state.has_officer(condition.target_id)` |
| `zone_type_is` | Deferred to Stage 3. Always returns `true` for now. |

Each evaluation logs whether it passed or failed and why.

Unknown condition types log a warning and return `false`.

### Batch Method

```
static func all_met(state: ExpeditionState, conditions: Array, log: SimulationLog) -> bool
```

Returns `true` only if every condition evaluates to `true`. Short-circuits on first failure but logs all.

---

## RumRules

Static utility class handling Rum's special-case tick logic.

### Tick Method

```
static func update_on_tick(state: ExpeditionState, log: SimulationLog) -> void
```

Logic:

1. Find the rum supply id by scanning ContentRegistry supplies for `is_rum == true`. Cache the id on first call.
2. If no rum supply exists in the registry, return immediately.
3. Let `rum_amount = state.get_supply(rum_id)`.
4. **Ration consumption:** If `rum_amount > 0` and `state.rum_ration_expected` and not `state.spirit_store_locked`:
   - Consume 1 rum: `state.set_supply(rum_id, rum_amount - 1)`.
   - Small Burden reduction: apply `burden_change` with delta -1.
   - Log: "Rum ration issued. Crew morale steadied."
5. **Ration withheld:** If `rum_amount > 0` and `state.rum_ration_expected` and `state.spirit_store_locked`:
   - Burden increase: apply `burden_change` with delta +2.
   - Log: "Rum ration withheld. The crew grumbles."
6. **Rum ran out:** If `rum_amount == 0` and `state.rum_ration_expected`:
   - Burden spike: apply `burden_change` with delta +4.
   - Set `state.rum_ration_expected = false`.
   - Add memory flag `rum_ration_ended`.
   - Log: "Rum stores exhausted. The crew expected their ration."
7. **Theft risk:** If `rum_amount > 0` and not `state.spirit_store_locked`:
   - `state.rum_theft_risk = clampi(30 + (100 - state.command) / 2, 0, 100)`
   - Otherwise: `state.rum_theft_risk = clampi(state.rum_theft_risk - 10, 0, 100)`
8. **Drunkenness risk:** If `rum_amount > 20` and not `state.spirit_store_locked`:
   - `state.rum_drunkenness_risk = clampi(20 + rum_amount / 5, 0, 100)`
   - Otherwise: `state.rum_drunkenness_risk = clampi(state.rum_drunkenness_risk - 10, 0, 100)`

These risk values set up incident triggers for Stage 5 — they don't auto-fire events.

---

## Promise System

Methods on `ExpeditionState`:

### make_promise(id: String, text: String, deadline_ticks: int, log: SimulationLog) -> bool

- If `active_promise` is not empty, log warning and return `false`.
- Set `active_promise = { "id": id, "text": text, "deadline_ticks": deadline_ticks, "ticks_remaining": deadline_ticks }`.
- Apply `command_change` +3 (promise boosts authority).
- Log: "Promise made: [text]"
- Return `true`.

### tick_promise(log: SimulationLog) -> void

- If no active promise, return.
- Decrement `ticks_remaining`.
- If `ticks_remaining <= 0`, call `break_promise(log)`.

### keep_promise(log: SimulationLog) -> void

- If no active promise, return.
- Apply `command_change` +5.
- Apply `burden_change` -3.
- Add memory flag `promise_kept_<id>`.
- Log: "Promise kept: [text]"
- Clear `active_promise`.

### break_promise(log: SimulationLog) -> void

- If no active promise, return.
- Apply `command_change` -5.
- Apply `burden_change` +5.
- Add memory flag `promise_broken_<id>`.
- Log: "Promise broken: [text]"
- Clear `active_promise`.

---

## SimulationLog

A `RefCounted` class with an append-only entry list.

### Entry Format

```
{ "tick": int, "source": String, "message": String, "details": Dictionary }
```

- `tick` — current `state.tick_count` at time of logging.
- `source` — originator: "EffectProcessor", "ConditionEvaluator", "RumRules", "Promise".
- `message` — human-readable explanation.
- `details` — structured data: `{ "type": effect_type, "before": val, "after": val, "target": id }` or `{ "condition": type, "passed": bool, "threshold": val, "actual": val }`.

### Methods

```
func log_effect(tick: int, source: String, message: String, details: Dictionary) -> void
func log_condition(tick: int, source: String, message: String, details: Dictionary) -> void
func log_event(tick: int, source: String, message: String, details: Dictionary) -> void
func get_entries() -> Array[Dictionary]
func get_entries_since(tick: int) -> Array[Dictionary]
func clear() -> void
```

All three `log_*` methods append to the same internal array. The method name is for caller clarity; internally they all do the same thing (append an entry dict).

---

## Debug Scene — Expedition Sim Tab

Extend the existing ContentDebugScene with an "Expedition Sim" section in the sidebar. This is a separate group of buttons below a visual separator.

### Sidebar Additions

```
--- (HSeparator)
"Expedition Sim" (Label, bold)
"New Expedition" (Button)
"Show State" (Button)
"Apply Effect" (Button)
"Check Condition" (Button)
"Tick" (Button)
"Make Promise" (Button)
"Keep Promise" (Button)
"Break Promise" (Button)
"Toggle Damage Tag" (Button)
"Set Memory Flag" (Button)
"Toggle Spirit Store" (Button)
"Show Log" (Button)
```

### Behavior

**New Expedition:** Calls `ExpeditionState.create_default()`, creates a fresh `SimulationLog`. Shows the state summary in the output pane.

**Show State:** Displays current state — Burden, Command, all supply amounts, ship condition, damage tags, crew traits, officers, standing orders, active promise, leadership tags, memory flags, rum state (ration expected, store locked, theft risk, drunkenness risk), stress indicators, tick count.

**Apply Effect:** Creates a test effect and applies it. Cycles through a preset list on each press:
1. `burden_change +10`
2. `command_change -5`
3. `supply_change food -3`
4. `add_damage_tag hull_strained`
5. `set_memory_flag test_flag`
6. `ship_condition_change -10`

Shows updated state + last log entry.

**Check Condition:** Creates a test condition and evaluates it. Cycles through a preset list:
1. `burden_above 50`
2. `command_below 50`
3. `supply_below food 10`
4. `has_damage_tag hull_strained`
5. `has_memory_flag test_flag`
6. `officer_present bosun`

Shows result (PASS/FAIL) + explanation.

**Tick:** Increments `tick_count`, runs `RumRules.update_on_tick()`, runs `tick_promise()`. Shows updated state.

**Make Promise:** Makes a test promise "We will make landfall within five days" with deadline 5 ticks. Shows result.

**Keep/Break Promise:** Resolves the active promise. Shows result.

**Toggle Damage Tag:** Toggles `hull_strained` — adds if absent, removes if present. Shows result.

**Set Memory Flag:** Adds `test_event_occurred` to memory flags. Shows result.

**Toggle Spirit Store:** Toggles `spirit_store_locked`. Shows result.

**Show Log:** Displays all SimulationLog entries in reverse chronological order.

---

## Headless Test Suite

`ExpeditionStateTest.gd` — follows the same pattern as `ContentFrameworkTest.gd` (print-based, `check()` method, crash on failure).

### Test Groups

1. **ExpeditionState defaults** — verify factory method populates from ContentRegistry correctly (supplies from SupplyDefs, officers from OfficerDefs, correct initial values).
2. **ExpeditionState utility methods** — get/set supply clamping, add/remove damage tags idempotency, add/remove memory flags idempotency, crew traits.
3. **EffectProcessor** — one test per effect type, verify before/after state, verify log entry written.
4. **EffectProcessor batch** — apply multiple effects, verify cumulative state.
5. **EffectProcessor clamping** — burden can't exceed 100 or go below 0, same for command and ship_condition. Supply can't go below 0.
6. **EffectProcessor stress indicators** — verify peak_burden, min_command, supply_depletions update correctly.
7. **ConditionEvaluator** — one test per condition type, verify pass and fail cases, verify log entries.
8. **ConditionEvaluator batch** — all_met with mixed pass/fail.
9. **RumRules** — ration consumed, ration withheld (store locked), rum ran out, theft risk calculation, drunkenness risk calculation.
10. **Promise lifecycle** — make, tick, keep. Make, tick to expiry (auto-break). Cannot make while one active.

---

## Testable Outcome

- A scripted simulation can apply effects from content Resources and produce understandable state changes.
- Rum, Burden, Command, one active promise, and memory flags all work in isolation.
- The debug/explanation log can answer "why did this happen?" for state changes.
- The debug scene lets you interactively create an expedition, apply effects, check conditions, tick the simulation, manage promises, and inspect the log.
- All headless tests pass.

---

## What This Stage Excludes

- Route map UI or generation.
- Incident resolution UI or eligibility selection.
- Admiralty meta layer.
- Multiple simultaneous promises.
- Deep fatigue or medical simulation.
- Standing order tick application (standing orders exist as data from Stage 1 but are not applied during ticks until Stage 4).
