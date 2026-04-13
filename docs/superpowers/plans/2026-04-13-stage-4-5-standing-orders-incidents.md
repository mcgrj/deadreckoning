# Stage 4+5: Standing Orders, Officer Council & Incident Resolution — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The player resolves incidents through an officer council whose proposals reflect each officer's worldview, and standing orders shape the incident probability landscape by weight-modifying the selection pool.

**Architecture:** Vertical slice first — extend the existing `drunk_purser_store_error` incident with officer proposals, add `WeightModifierDef` + `has_standing_order` condition type, change `TravelSimulator` incident scan to weighted random, build `OfficerCouncil` stateless class, then wire an `IncidentResolutionScene` into the debug scene as a panel swap.

**Tech Stack:** Godot 4.6, GDScript, headless test runner (`godot --headless --path game`), existing `EffectProcessor` / `ConditionEvaluator` / `ContentRegistry` singletons.

---

## Codebase orientation

Read these before starting any task:

- `game/src/expedition/ExpeditionState.gd` — state bag. `standing_orders: Array[String]` already exists. `leadership_tags: Dictionary` pre-initialized with harsh/merciful/honest/deceptive/shared_hardship/privilege.
- `game/src/expedition/ConditionEvaluator.gd` — `evaluate(state, condition, log)` match on `condition.type`.
- `game/src/expedition/TravelSimulator.gd` — Step 8 scans incidents with first-eligible-match. This changes to weighted random.
- `game/src/content/ContentValidator.gd` — `VALID_CONDITION_TYPES` array. Must include `has_standing_order`.
- `game/src/content/resources/IncidentDef.gd` — incident schema. Gains `weight_modifiers` + `art_path`.
- `game/src/content/resources/IncidentChoiceDef.gd` — choice schema. Gains `leadership_tag`, `effects_preview`, `risk_text`.
- `game/content/incidents/drunk_purser_store_error.tres` — the vertical slice incident. Has one bosun choice (officer_id = "bosun"), one captain choice (officer_id = ""). Needs surgeon choice added.
- `game/content/officers/bosun.tres` — `advice_hooks = ["drunk_purser_store_error"]` already set.
- `game/content/officers/surgeon.tres` — `advice_hooks = ["drunk_purser_store_error"]` already set.
- `game/test/ContentDebugScene.gd` — `_on_force_incident()` at line 398. This gets replaced in Task 8.

Run tests: `godot --headless --path game res://test/ContentFrameworkTest.tscn`, `res://test/ExpeditionStateTest.tscn`, `res://test/RouteMapTest.tscn`

---

## File map

**Create:**
- `game/src/content/resources/WeightModifierDef.gd` — new Resource: condition_type, condition_value, multiplier
- `game/src/expedition/OfficerCouncil.gd` — stateless, generates proposals from state + incident
- `game/src/ui/IncidentResolutionScene.gd` — UI controller for incident resolution
- `game/src/ui/IncidentResolutionScene.tscn` — scene nodes
- `game/content/incidents/food_dispute.tres` — new incident for weight_modifier testing
- `game/content/incidents/crew_fight.tres` — new incident for weight_modifier testing
- `game/test/Stage45Test.gd` — headless test suite
- `game/test/Stage45Test.tscn` — test scene

**Modify:**
- `game/src/content/resources/IncidentDef.gd` — add weight_modifiers, art_path
- `game/src/content/resources/IncidentChoiceDef.gd` — add leadership_tag, effects_preview, risk_text
- `game/src/content/ContentValidator.gd` — add has_standing_order to VALID_CONDITION_TYPES
- `game/src/expedition/ConditionEvaluator.gd` — add has_standing_order case
- `game/src/expedition/ExpeditionState.gd` — add has_standing_order(), nudge_leadership_tag()
- `game/src/expedition/TravelSimulator.gd` — change Step 8 to weighted random selection
- `game/content/incidents/drunk_purser_store_error.tres` — add surgeon choice, add leadership_tag/effects_preview/risk_text to bosun choice
- `game/content/standing_orders/tighten_rationing.tres` — update forecast_text
- `game/test/ContentDebugScene.gd` — wire IncidentResolutionScene panel swap, add ToggleRationing button
- `game/test/ContentDebugScene.tscn` — add IncidentResolutionContainer node + ToggleRationing button

---

## Task 1: ExpeditionState — has_standing_order + nudge_leadership_tag

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`
- Test: `game/test/Stage45Test.gd` (created in this task, extended in Task 9)

- [ ] **Step 1: Create the test file**

Create `game/test/Stage45Test.gd`:

```gdscript
# Stage45Test.gd
# Headless test suite for Stage 4+5: Standing Orders + Officer Council + Incident Resolution.
# Run: godot --headless --path game res://test/Stage45Test.tscn
extends Node

var _pass := 0
var _fail := 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
		_pass += 1
	else:
		push_error("  FAIL: " + label)
		_fail += 1


func _ready() -> void:
	print("=== Stage45Test ===\n")
	_test_expedition_state_standing_orders()
	_test_expedition_state_leadership_tags()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_expedition_state_standing_orders() -> void:
	print("-- ExpeditionState.has_standing_order --")
	var state := ExpeditionState.new()
	check(not state.has_standing_order("tighten_rationing"), "has_standing_order returns false when empty")
	state.standing_orders.append("tighten_rationing")
	check(state.has_standing_order("tighten_rationing"), "has_standing_order returns true when present")
	check(not state.has_standing_order("double_watch"), "has_standing_order returns false for absent order")


func _test_expedition_state_leadership_tags() -> void:
	print("-- ExpeditionState.nudge_leadership_tag --")
	var state := ExpeditionState.new()
	check(state.leadership_tags.get("harsh", 0) == 0, "harsh tag starts at 0")
	state.nudge_leadership_tag("harsh")
	check(state.leadership_tags.get("harsh", 0) == 1, "harsh tag increments to 1")
	state.nudge_leadership_tag("harsh")
	check(state.leadership_tags.get("harsh", 0) == 2, "harsh tag increments to 2")
	state.nudge_leadership_tag("authoritarian")
	check(state.leadership_tags.get("authoritarian", 0) == 1, "authoritarian tag works even if not pre-initialized")
```

- [ ] **Step 2: Create the test scene file**

Create `game/test/Stage45Test.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/Stage45Test.gd" id="1_stage45"]

[node name="Stage45Test" type="Node"]
script = ExtResource("1_stage45")
```

- [ ] **Step 3: Run the test to confirm it fails**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -20
```

Expected: FAIL on `has_standing_order` — method does not exist yet.

- [ ] **Step 4: Add methods to ExpeditionState**

In `game/src/expedition/ExpeditionState.gd`, add after the `has_officer` method (around line 119):

```gdscript
# --- Standing order accessor ---

func has_standing_order(order_id: String) -> bool:
	return order_id in standing_orders


# --- Leadership tag nudge ---

func nudge_leadership_tag(tag: String) -> void:
	if not leadership_tags.has(tag):
		leadership_tags[tag] = 0
	leadership_tags[tag] += 1
```

- [ ] **Step 5: Run the test to confirm it passes**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 6: Confirm existing tests still pass**

```bash
godot --headless --path game res://test/ExpeditionStateTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 7: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd game/test/Stage45Test.gd game/test/Stage45Test.tscn
git commit -m "feat(stage-4): add has_standing_order + nudge_leadership_tag to ExpeditionState"
```

---

## Task 2: WeightModifierDef + has_standing_order condition type

**Files:**
- Create: `game/src/content/resources/WeightModifierDef.gd`
- Modify: `game/src/content/ContentValidator.gd`
- Modify: `game/src/expedition/ConditionEvaluator.gd`
- Modify: `game/src/content/resources/ConditionDef.gd` (comment only)
- Modify: `game/test/Stage45Test.gd`

- [ ] **Step 1: Add has_standing_order test to Stage45Test.gd**

Append to `_ready()` call list in `game/test/Stage45Test.gd`:

```gdscript
	_test_condition_evaluator_has_standing_order()
```

Add the test function:

```gdscript
func _test_condition_evaluator_has_standing_order() -> void:
	print("-- ConditionEvaluator has_standing_order --")
	var log := SimulationLog.new()
	var state := ExpeditionState.new()

	var cond := ConditionDef.new()
	cond.type = "has_standing_order"
	cond.tag = "tighten_rationing"

	check(not ConditionEvaluator.evaluate(state, cond, log), "has_standing_order false when order not active")

	state.standing_orders.append("tighten_rationing")
	check(ConditionEvaluator.evaluate(state, cond, log), "has_standing_order true when order active")
```

- [ ] **Step 2: Run to confirm test fails**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: FAIL on `has_standing_order` condition type — unknown type warning.

- [ ] **Step 3: Create WeightModifierDef**

Create `game/src/content/resources/WeightModifierDef.gd`:

```gdscript
# WeightModifierDef.gd
# Inline Resource that adjusts an incident's selection weight when a condition is met.
# Embedded in IncidentDef.weight_modifiers.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
class_name WeightModifierDef
extends Resource

## Condition type to evaluate. Currently supports: "has_standing_order"
@export var condition_type: String = ""

## Value to check: for has_standing_order, this is the standing order id.
@export var condition_value: String = ""

## Multiplier applied to the incident's base weight (1.0) when condition is met.
## Values < 1.0 suppress the incident; values > 1.0 boost it.
@export var multiplier: float = 1.0
```

- [ ] **Step 4: Update ConditionDef comment**

In `game/src/content/resources/ConditionDef.gd`, update the comment block at the top:

```gdscript
# Valid types: burden_above, burden_below, command_above, command_below, supply_below,
#              has_damage_tag, has_memory_flag, has_crew_trait, officer_present, zone_type_is,
#              has_standing_order
```

- [ ] **Step 5: Add has_standing_order to ContentValidator**

In `game/src/content/ContentValidator.gd`, add to `VALID_CONDITION_TYPES`:

```gdscript
const VALID_CONDITION_TYPES: Array[String] = [
	"burden_above",
	"burden_below",
	"command_above",
	"command_below",
	"supply_below",
	"has_damage_tag",
	"has_memory_flag",
	"has_crew_trait",
	"officer_present",
	"zone_type_is",
	"has_standing_order",
]
```

- [ ] **Step 6: Add has_standing_order case to ConditionEvaluator**

In `game/src/expedition/ConditionEvaluator.gd`, add a new case inside the `match condition.type:` block, before the `_:` default case:

```gdscript
		"has_standing_order":
			result = state.has_standing_order(condition.tag)
			details["tag"] = condition.tag
			message = "Has standing order '%s'? %s" % [condition.tag, "PASS" if result else "FAIL"]
```

- [ ] **Step 7: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 8: Confirm ContentFrameworkTest still passes**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 9: Commit**

Note: Godot auto-generates `.uid` files when the project is opened — include any `.uid` files that appeared alongside new `.gd` files.

```bash
git add game/src/content/resources/WeightModifierDef.gd \
        game/src/content/resources/ConditionDef.gd \
        game/src/content/ContentValidator.gd \
        game/src/expedition/ConditionEvaluator.gd \
        game/test/Stage45Test.gd
git commit -m "feat(stage-4): add WeightModifierDef + has_standing_order condition type"
```

---

## Task 3: IncidentDef + IncidentChoiceDef new fields

**Files:**
- Modify: `game/src/content/resources/IncidentDef.gd`
- Modify: `game/src/content/resources/IncidentChoiceDef.gd`
- Modify: `game/test/Stage45Test.gd`

- [ ] **Step 1: Add field default tests**

Append to `_ready()` call list in `game/test/Stage45Test.gd`:

```gdscript
	_test_incident_def_new_fields()
	_test_incident_choice_def_new_fields()
```

Add test functions:

```gdscript
func _test_incident_def_new_fields() -> void:
	print("-- IncidentDef new fields --")
	var def := IncidentDef.new()
	check(def.weight_modifiers.is_empty(), "weight_modifiers defaults to empty array")
	check(def.art_path == "", "art_path defaults to empty string")


func _test_incident_choice_def_new_fields() -> void:
	print("-- IncidentChoiceDef new fields --")
	var choice := IncidentChoiceDef.new()
	check(choice.leadership_tag == "", "leadership_tag defaults to empty string")
	check(choice.effects_preview == "", "effects_preview defaults to empty string")
	check(choice.risk_text == "", "risk_text defaults to empty string")
```

- [ ] **Step 2: Run to confirm test fails**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: FAIL — `weight_modifiers` property does not exist.

- [ ] **Step 3: Add new fields to IncidentDef**

In `game/src/content/resources/IncidentDef.gd`, add after the `choices` field:

```gdscript
## Probability weight modifiers applied during incident selection. Each entry is a
## WeightModifierDef. Default weight is 1.0; modifiers multiply it.
@export var weight_modifiers: Array[WeightModifierDef] = []

## Path to scene art texture for this incident. Empty = placeholder colour panel.
@export var art_path: String = ""
```

- [ ] **Step 4: Add new fields to IncidentChoiceDef**

In `game/src/content/resources/IncidentChoiceDef.gd`, add after the `log_text` field:

```gdscript
## Leadership tag nudged when player follows this officer's advice.
## One of: harsh, merciful, honest, deceptive, shared_hardship, privilege, authoritarian, patient.
@export var leadership_tag: String = ""

## Short mechanical summary shown to the player before confirming. E.g. "Burden −4, Command +2".
@export var effects_preview: String = ""

## Downside or risk text. Clarity is scaled by officer competence in the UI.
@export var risk_text: String = ""
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 6: Confirm ContentFrameworkTest still passes**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 7: Commit**

```bash
git add game/src/content/resources/IncidentDef.gd \
        game/src/content/resources/IncidentChoiceDef.gd \
        game/test/Stage45Test.gd
git commit -m "feat(stage-4): add weight_modifiers/art_path to IncidentDef, leadership fields to IncidentChoiceDef"
```

---

## Task 4: OfficerCouncil — proposal generation

**Files:**
- Create: `game/src/expedition/OfficerCouncil.gd`
- Modify: `game/test/Stage45Test.gd`

The council produces a list of proposal Dictionaries from present officers + the current incident. Each Dictionary has:
- `"type"`: `"officer"`, `"silence"`, or `"direct_order"`
- `"officer_id"`: String (empty for direct_order)
- `"officer_def"`: OfficerDef or null
- `"choice"`: IncidentChoiceDef or null (null for silence + direct_order)
- `"choice_index"`: int (index into incident.choices, -1 for silence + direct_order)
- `"silence_line"`: String (populated for silence proposals)

- [ ] **Step 1: Add OfficerCouncil tests**

Append to `_ready()` call list in `game/test/Stage45Test.gd`:

```gdscript
	_test_officer_council_proposals()
```

Add the test function:

```gdscript
func _test_officer_council_proposals() -> void:
	print("-- OfficerCouncil.get_proposals --")

	# Build a minimal incident with one officer choice and one captain choice
	var incident := IncidentDef.new()
	incident.id = "test_incident"

	var bosun_choice := IncidentChoiceDef.new()
	bosun_choice.officer_id = "bosun"
	bosun_choice.choice_text = "Confine the purser."
	bosun_choice.leadership_tag = "harsh"

	var captain_choice := IncidentChoiceDef.new()
	captain_choice.officer_id = ""
	captain_choice.choice_text = "Cover it up."

	incident.choices = [bosun_choice, captain_choice]

	# State with bosun present but no surgeon
	var state := ExpeditionState.new()
	state.officers = ["bosun"]

	# Build officer defs manually (not via ContentRegistry)
	var bosun_def := OfficerDef.new()
	bosun_def.id = "bosun"
	bosun_def.worldview = "disciplinarian"
	bosun_def.competence = 4
	bosun_def.advice_hooks = ["test_incident"]

	var surgeon_def := OfficerDef.new()
	surgeon_def.id = "surgeon"
	surgeon_def.worldview = "humanitarian"
	surgeon_def.competence = 3
	surgeon_def.advice_hooks = []

	var officer_defs := [bosun_def, surgeon_def]

	var proposals := OfficerCouncil.get_proposals(state, incident, officer_defs)

	# Should have: bosun proposal + direct order (surgeon not present, so no silence needed)
	var officer_proposals := proposals.filter(func(p): return p["type"] == "officer")
	var silence_proposals := proposals.filter(func(p): return p["type"] == "silence")
	var direct_order := proposals.filter(func(p): return p["type"] == "direct_order")

	check(officer_proposals.size() == 1, "one officer proposal for present bosun")
	check(officer_proposals[0]["officer_id"] == "bosun", "bosun proposal has correct officer_id")
	check(officer_proposals[0]["choice"] == bosun_choice, "bosun proposal links to correct choice")
	check(silence_proposals.size() == 0, "no silence proposals when surgeon not present")
	check(direct_order.size() == 1, "always one direct order proposal")

	# Now add surgeon to state (no matching hook for test_incident)
	state.officers = ["bosun", "surgeon"]
	var proposals2 := OfficerCouncil.get_proposals(state, incident, officer_defs)
	var silence2 := proposals2.filter(func(p): return p["type"] == "silence")
	check(silence2.size() == 1, "silence proposal for surgeon who has no hook for this incident")
	check(silence2[0]["officer_id"] == "surgeon", "silence proposal is for surgeon")
	check(silence2[0]["silence_line"] != "", "silence line is not empty")
```

- [ ] **Step 2: Run to confirm test fails**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: FAIL — `OfficerCouncil` class does not exist.

- [ ] **Step 3: Create OfficerCouncil**

Create `game/src/expedition/OfficerCouncil.gd`:

```gdscript
# OfficerCouncil.gd
# Stateless utility that generates proposal Dictionaries for an incident from present officers.
# Each proposal has: type, officer_id, officer_def, choice, choice_index, silence_line.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
class_name OfficerCouncil

const SILENCE_LINES: Dictionary = {
	"disciplinarian": "Not my place to speak to this, sir. Your call.",
	"humanitarian": "I have no counsel here. I trust your judgement, Captain.",
	"pragmatist": "Nothing useful to offer, sir.",
}
const DEFAULT_SILENCE_LINE := "I have nothing to offer on this matter."


## Generate proposals for all officers present in state.
## officer_defs: Array of OfficerDef — caller provides these (typically from ContentRegistry).
## Returns Array of proposal Dictionaries. Always ends with one direct_order proposal.
static func get_proposals(
	state: ExpeditionState,
	incident: IncidentDef,
	officer_defs: Array
) -> Array:
	var proposals: Array = []

	# Build a lookup from officer_id → choice_index for this incident
	var officer_choice_map: Dictionary = {}
	for i: int in range(incident.choices.size()):
		var choice: IncidentChoiceDef = incident.choices[i]
		if choice.officer_id != "":
			officer_choice_map[choice.officer_id] = i

	# For each officer present in state, generate a proposal or silence
	for def: OfficerDef in officer_defs:
		if not state.has_officer(def.id):
			continue
		if def.advice_hooks.has(incident.id) and officer_choice_map.has(def.id):
			var choice_idx: int = officer_choice_map[def.id]
			proposals.append({
				"type": "officer",
				"officer_id": def.id,
				"officer_def": def,
				"choice": incident.choices[choice_idx],
				"choice_index": choice_idx,
				"silence_line": "",
			})
		else:
			proposals.append({
				"type": "silence",
				"officer_id": def.id,
				"officer_def": def,
				"choice": null,
				"choice_index": -1,
				"silence_line": SILENCE_LINES.get(def.worldview, DEFAULT_SILENCE_LINE),
			})

	# Always append a direct order proposal
	proposals.append({
		"type": "direct_order",
		"officer_id": "",
		"officer_def": null,
		"choice": null,
		"choice_index": -1,
		"silence_line": "",
	})

	return proposals
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/OfficerCouncil.gd \
        game/src/expedition/OfficerCouncil.gd.uid \
        game/test/Stage45Test.gd
git commit -m "feat(stage-4): add OfficerCouncil stateless proposal generator"
```

---

## Task 5: TravelSimulator — weighted incident selection

**Files:**
- Modify: `game/src/expedition/TravelSimulator.gd`
- Modify: `game/test/Stage45Test.gd`

The incident scan in Step 8 of `process_tick` changes from first-eligible-match to weighted random selection from the eligible pool.

- [ ] **Step 1: Add weighted selection test**

Append to `_ready()` call list in `game/test/Stage45Test.gd`:

```gdscript
	_test_incident_weight_calculation()
```

Add the test function:

```gdscript
func _test_incident_weight_calculation() -> void:
	print("-- TravelSimulator incident weight calculation --")
	var state := ExpeditionState.new()

	# Build two incidents with weight modifiers
	var fight := IncidentDef.new()
	fight.id = "crew_fight"
	fight.trigger_band = "tick"
	fight.required_conditions = []
	var fight_mod := WeightModifierDef.new()
	fight_mod.condition_type = "has_standing_order"
	fight_mod.condition_value = "tighten_rationing"
	fight_mod.multiplier = 2.0
	fight.weight_modifiers = [fight_mod]

	var food := IncidentDef.new()
	food.id = "food_dispute"
	food.trigger_band = "tick"
	food.required_conditions = []
	var food_mod := WeightModifierDef.new()
	food_mod.condition_type = "has_standing_order"
	food_mod.condition_value = "tighten_rationing"
	food_mod.multiplier = 0.3
	food.weight_modifiers = [food_mod]

	var log := SimulationLog.new()

	# Without tighten_rationing: both incidents weight 1.0
	var weight_fight_no_order := TravelSimulator.compute_incident_weight(state, fight, log)
	var weight_food_no_order := TravelSimulator.compute_incident_weight(state, food, log)
	check(absf(weight_fight_no_order - 1.0) < 0.001, "crew_fight weight is 1.0 without order")
	check(absf(weight_food_no_order - 1.0) < 0.001, "food_dispute weight is 1.0 without order")

	# With tighten_rationing active
	state.standing_orders.append("tighten_rationing")
	var weight_fight_with_order := TravelSimulator.compute_incident_weight(state, fight, log)
	var weight_food_with_order := TravelSimulator.compute_incident_weight(state, food, log)
	check(absf(weight_fight_with_order - 2.0) < 0.001, "crew_fight weight is 2.0 with tighten_rationing")
	check(absf(weight_food_with_order - 0.3) < 0.001, "food_dispute weight is 0.3 with tighten_rationing")
```

- [ ] **Step 2: Run to confirm test fails**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: FAIL — `compute_incident_weight` does not exist.

- [ ] **Step 3: Update TravelSimulator**

Replace Step 8 in `game/src/expedition/TravelSimulator.gd` and add the helper method. The full updated file from line 86 onwards:

```gdscript
	# Step 8: Incident trigger check — weighted random selection from eligible pool
	if state.pending_incident_id.is_empty():
		var incidents := ContentRegistry.get_all("incidents")
		var eligible: Array = []
		var weights: Array = []
		var total_weight: float = 0.0

		for item: ContentBase in incidents:
			var incident := item as IncidentDef
			if incident == null or incident.trigger_band != "tick":
				continue
			if not ConditionEvaluator.all_met(state, incident.required_conditions, log):
				continue
			var w := compute_incident_weight(state, incident, log)
			eligible.append(incident)
			weights.append(w)
			total_weight += w

		if not eligible.is_empty():
			var roll := randf() * total_weight
			var cumulative: float = 0.0
			for i: int in range(eligible.size()):
				cumulative += weights[i]
				if roll <= cumulative:
					state.pending_incident_id = eligible[i].id
					log.log_event(state.tick_count, "TravelSimulator",
						"Incident triggered: %s (weight %.2f)" % [eligible[i].id, weights[i]],
						{"incident_id": eligible[i].id, "weight": weights[i]})
					break
```

Add after `process_tick`, still inside the class:

```gdscript
## Compute the selection weight for an incident given current state.
## Applies all weight_modifiers; returns 1.0 if none match.
static func compute_incident_weight(
	state: ExpeditionState,
	incident: IncidentDef,
	log: SimulationLog
) -> float:
	var weight: float = 1.0
	for mod: WeightModifierDef in incident.weight_modifiers:
		var condition_met: bool = false
		match mod.condition_type:
			"has_standing_order":
				condition_met = state.has_standing_order(mod.condition_value)
		if condition_met:
			weight *= mod.multiplier
			log.log_event(state.tick_count, "TravelSimulator",
				"Weight modifier applied to %s: x%.2f (total %.2f)" % [incident.id, mod.multiplier, weight],
				{"incident_id": incident.id, "modifier": mod.multiplier, "weight": weight})
	return weight
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 5: Confirm RouteMapTest still passes**

```bash
godot --headless --path game res://test/RouteMapTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/Stage45Test.gd
git commit -m "feat(stage-4): weighted incident selection in TravelSimulator + compute_incident_weight"
```

---

## Task 6: Vertical slice content

**Files:**
- Modify: `game/content/incidents/drunk_purser_store_error.tres`
- Modify: `game/content/standing_orders/tighten_rationing.tres`
- Create: `game/content/incidents/food_dispute.tres`
- Create: `game/content/incidents/crew_fight.tres`

This task authors the .tres content files for the vertical slice. No tests needed — the existing `ContentFrameworkTest` validates catalog integrity.

- [ ] **Step 1: Update drunk_purser_store_error.tres**

Replace the entire file with the updated version that adds surgeon choice and leadership/preview/risk fields:

```
[gd_resource type="Resource" script_class="IncidentDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ConditionDef.gd" id="1_coyvt"]
[ext_resource type="Script" path="res://src/content/resources/IncidentChoiceDef.gd" id="2_b38pm"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="3_o1431"]
[ext_resource type="Script" path="res://src/content/resources/IncidentDef.gd" id="4_fm3pj"]

[sub_resource type="Resource" id="Resource_cmd3"]
script = ExtResource("3_o1431")
type = "command_change"
delta = 3

[sub_resource type="Resource" id="Resource_brd2"]
script = ExtResource("3_o1431")
type = "burden_change"
delta = -2

[sub_resource type="Resource" id="Resource_bosun_choice"]
script = ExtResource("2_b38pm")
choice_text = "Hold the purser accountable. Order a public audit."
officer_id = "bosun"
immediate_effects = Array[ExtResource("3_o1431")]([SubResource("Resource_cmd3"), SubResource("Resource_brd2")])
memory_flags_set = Array[String](["purser_exposed"])
log_text = "The purser's error is announced. Command steadies, but the humiliation will not be forgotten."
leadership_tag = "harsh"
effects_preview = "Command +3, Burden −2"
risk_text = "Purser resentment if innocent. Public humiliation is hard to undo."

[sub_resource type="Resource" id="Resource_brd1"]
script = ExtResource("3_o1431")
type = "burden_change"
delta = -1

[sub_resource type="Resource" id="Resource_surgeon_choice"]
script = ExtResource("2_b38pm")
choice_text = "Hear the purser privately. A quiet restitution is possible."
officer_id = "surgeon"
immediate_effects = Array[ExtResource("3_o1431")]([SubResource("Resource_brd1")])
memory_flags_set = Array[String](["purser_error_concealed"])
log_text = "The captain hears the purser privately. The crew suspects nothing — for now."
leadership_tag = "merciful"
effects_preview = "Burden −1"
risk_text = "Theft may continue if this was not an error."

[sub_resource type="Resource" id="Resource_flag"]
script = ExtResource("3_o1431")
type = "set_memory_flag"
flag_key = "purser_incident_ignored"

[sub_resource type="Resource" id="Resource_direct_placeholder"]
script = ExtResource("2_b38pm")
choice_text = "It is noted."
officer_id = ""
immediate_effects = Array[ExtResource("3_o1431")]([SubResource("Resource_flag")])
memory_flags_set = Array[String](["purser_incident_ignored"])
log_text = "The captain closes the matter without comment."

[sub_resource type="Resource" id="Resource_3nyub"]
script = ExtResource("1_coyvt")
type = "has_crew_trait"
tag = "rum_aboard"

[resource]
script = ExtResource("4_fm3pj")
trigger_band = "tick"
required_conditions = Array[ExtResource("1_coyvt")]([SubResource("Resource_3nyub")])
cast_roles = Array[String](["purser", "bosun"])
standing_order_interactions = Array[String](["audit_stores"])
choices = Array[ExtResource("2_b38pm")]([SubResource("Resource_bosun_choice"), SubResource("Resource_surgeon_choice"), SubResource("Resource_direct_placeholder")])
log_text_template = "The purser's count is short. Rum has gone missing from the spirit locker."
id = "drunk_purser_store_error"
display_name = "The Purser's Error"
category = "social"
tags = Array[String](["purser", "rum", "supply"])
```

- [ ] **Step 2: Create food_dispute.tres**

```
[gd_resource type="Resource" script_class="IncidentDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/IncidentDef.gd" id="1_incident"]
[ext_resource type="Script" path="res://src/content/resources/IncidentChoiceDef.gd" id="2_choice"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="3_effect"]
[ext_resource type="Script" path="res://src/content/resources/WeightModifierDef.gd" id="4_wmod"]

[sub_resource type="Resource" id="Resource_brd3"]
script = ExtResource("3_effect")
type = "burden_change"
delta = -3

[sub_resource type="Resource" id="Resource_choice1"]
script = ExtResource("2_choice")
choice_text = "Hear the complaints. Adjust the ration distribution."
officer_id = ""
immediate_effects = Array[ExtResource("3_effect")]([SubResource("Resource_brd3")])
memory_flags_set = Array[String]([])
log_text = "The captain hears the men out. Rations are redistributed fairly."

[sub_resource type="Resource" id="Resource_wmod1"]
script = ExtResource("4_wmod")
condition_type = "has_standing_order"
condition_value = "tighten_rationing"
multiplier = 0.3

[resource]
script = ExtResource("1_incident")
trigger_band = "tick"
choices = Array[ExtResource("2_choice")]([SubResource("Resource_choice1")])
weight_modifiers = Array[ExtResource("4_wmod")]([SubResource("Resource_wmod1")])
log_text_template = "The men are grumbling about the rations. A dispute breaks out at the stores."
id = "food_dispute"
display_name = "Food Dispute"
category = "social"
tags = Array[String](["crew", "supply", "morale"])
```

- [ ] **Step 3: Create crew_fight.tres**

```
[gd_resource type="Resource" script_class="IncidentDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/IncidentDef.gd" id="1_incident"]
[ext_resource type="Script" path="res://src/content/resources/IncidentChoiceDef.gd" id="2_choice"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="3_effect"]
[ext_resource type="Script" path="res://src/content/resources/WeightModifierDef.gd" id="4_wmod"]

[sub_resource type="Resource" id="Resource_brd5"]
script = ExtResource("3_effect")
type = "burden_change"
delta = 5

[sub_resource type="Resource" id="Resource_choice1"]
script = ExtResource("2_choice")
choice_text = "Separate them. Log it and move on."
officer_id = ""
immediate_effects = Array[ExtResource("3_effect")]([SubResource("Resource_brd5")])
memory_flags_set = Array[String](["crew_fight_occurred"])
log_text = "Two men are separated. The mood is foul."

[sub_resource type="Resource" id="Resource_wmod1"]
script = ExtResource("4_wmod")
condition_type = "has_standing_order"
condition_value = "tighten_rationing"
multiplier = 2.0

[resource]
script = ExtResource("1_incident")
trigger_band = "tick"
choices = Array[ExtResource("2_choice")]([SubResource("Resource_choice1")])
weight_modifiers = Array[ExtResource("4_wmod")]([SubResource("Resource_wmod1")])
log_text_template = "A fight breaks out between two members of the crew."
id = "crew_fight"
display_name = "Crew Fight"
category = "social"
tags = Array[String](["crew", "morale", "violence"])
```

- [ ] **Step 4: Update tighten_rationing.tres forecast_text**

In `game/content/standing_orders/tighten_rationing.tres`, update `forecast_text`:

```
forecast_text = "Food disputes become less likely. Tempers run shorter — fights more so."
```

- [ ] **Step 5: Confirm catalog validates**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/content/incidents/drunk_purser_store_error.tres \
        game/content/incidents/food_dispute.tres \
        game/content/incidents/crew_fight.tres \
        game/content/standing_orders/tighten_rationing.tres
git commit -m "feat(stage-4): author vertical slice content — purser incident, food_dispute, crew_fight"
```

---

## Task 7: IncidentResolutionScene UI

**Files:**
- Create: `game/src/ui/IncidentResolutionScene.gd`
- Create: `game/src/ui/IncidentResolutionScene.tscn`

The scene is a VBoxContainer that displays the incident, the officer council, and handles player selection. It is controlled by the debug scene (Task 8). It emits `resolved` when the player confirms a choice.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /home/joe/repos/deadreckoning/game/src/ui
```

- [ ] **Step 2: Create IncidentResolutionScene.gd**

Create `game/src/ui/IncidentResolutionScene.gd`:

```gdscript
# IncidentResolutionScene.gd
# UI scene for resolving an incident through the officer council.
# Call setup(state, log) to populate. Emits resolved when the player confirms.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
extends VBoxContainer

signal resolved

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _incident: IncidentDef = null
var _proposals: Array = []
var _selected_index: int = -1

@onready var _category_label: Label = $IncidentHeader/HeaderContent/CategoryLabel
@onready var _title_label: Label = $IncidentHeader/HeaderContent/TitleLabel
@onready var _flavour_label: Label = $IncidentHeader/HeaderContent/FlavourLabel
@onready var _state_label: Label = $IncidentHeader/HeaderContent/StateLabel
@onready var _art_panel: ColorRect = $MainArea/ArtPanel
@onready var _proposal_list: VBoxContainer = $MainArea/CouncilPanel/ProposalList
@onready var _confirm_button: Button = $MainArea/CouncilPanel/ConfirmButton
@onready var _silence_footer: Label = $MainArea/CouncilPanel/SilenceFooter


func setup(state: ExpeditionState, log: SimulationLog) -> void:
	_state = state
	_log = log
	_incident = ContentRegistry.get_by_id("incidents", state.pending_incident_id) as IncidentDef
	if _incident == null:
		push_error("IncidentResolutionScene: incident not found: " + state.pending_incident_id)
		return


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm)
	_confirm_button.visible = false


func populate() -> void:
	if _incident == null or _state == null:
		return

	# Header
	_category_label.text = _incident.category.to_upper() + " — " + _incident.id.to_upper()
	_title_label.text = _incident.display_name.to_upper()
	_flavour_label.text = _incident.log_text_template
	_state_label.text = "Day %d  ·  Burden %d  ·  Command %d  ·  Ship %d" % [
		_state.tick_count, _state.burden, _state.command, _state.ship_condition]

	# Art panel — placeholder colour; future: load texture from _incident.art_path
	_art_panel.color = Color(0.08, 0.08, 0.1, 1.0)

	# Build proposals from present officers
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)

	_proposals = OfficerCouncil.get_proposals(_state, _incident, officer_defs)

	# Clear previous cards
	for child in _proposal_list.get_children():
		child.queue_free()

	_selected_index = -1
	_confirm_button.visible = false

	# Build silence footer text
	var silence_lines: Array[String] = []

	# Create a card button per proposal
	for i: int in range(_proposals.size()):
		var proposal: Dictionary = _proposals[i]
		var btn := Button.new()
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD

		match proposal["type"]:
			"officer":
				var officer_def: OfficerDef = proposal["officer_def"]
				var choice: IncidentChoiceDef = proposal["choice"]
				var dots := _competence_dots(officer_def.competence)
				var preview := choice.effects_preview if choice.effects_preview != "" else "(no preview)"
				var risk := ""
				if choice.risk_text != "" and officer_def.competence >= 3:
					risk = "\nRisk: " + choice.risk_text
				btn.text = "[%s  %s]\n%s\n%s%s" % [
					officer_def.display_name.to_upper(), dots,
					choice.choice_text, preview, risk]
				btn.tooltip_text = "→ " + choice.leadership_tag if choice.leadership_tag != "" else ""
				_proposal_list.add_child(btn)
				btn.pressed.connect(_on_proposal_selected.bind(i))

			"silence":
				# Add to footer, not as a button
				var officer_def: OfficerDef = proposal["officer_def"]
				silence_lines.append("%s: \"%s\"" % [officer_def.display_name, proposal["silence_line"]])

			"direct_order":
				btn.text = "[DIRECT ORDER]\nThis does not leave my cabin.\n→ authoritarian"
				_proposal_list.add_child(btn)
				btn.pressed.connect(_on_proposal_selected.bind(i))

	_silence_footer.text = "\n".join(silence_lines)


func _on_proposal_selected(index: int) -> void:
	_selected_index = index
	_confirm_button.visible = true
	_confirm_button.text = "CONFIRM — " + _proposals[index].get("type", "").to_upper()

	# Highlight selected button (deselect others)
	var btns := _proposal_list.get_children()
	var btn_idx := 0
	for i: int in range(_proposals.size()):
		if _proposals[i]["type"] == "silence":
			continue
		if btn_idx < btns.size():
			var btn := btns[btn_idx] as Button
			if btn != null:
				btn.modulate = Color(0.6, 1.0, 0.6, 1.0) if i == index else Color(1, 1, 1, 1)
			btn_idx += 1


func _on_confirm() -> void:
	if _selected_index < 0 or _selected_index >= _proposals.size():
		return

	var proposal: Dictionary = _proposals[_selected_index]

	match proposal["type"]:
		"officer":
			var choice: IncidentChoiceDef = proposal["choice"]
			EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
			for flag: String in choice.memory_flags_set:
				_state.add_memory_flag(flag)
			if choice.leadership_tag != "":
				_state.nudge_leadership_tag(choice.leadership_tag)
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] %s" % [_incident.display_name, choice.log_text],
				{"incident_id": _incident.id, "choice": choice.choice_text, "leadership_tag": choice.leadership_tag})

		"direct_order":
			_state.nudge_leadership_tag("authoritarian")
			_state.add_memory_flag("direct_order_used")
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] Captain issued direct order." % _incident.display_name,
				{"incident_id": _incident.id, "type": "direct_order"})

	_state.pending_incident_id = ""
	resolved.emit()


func _competence_dots(competence: int) -> String:
	var filled := "●".repeat(competence)
	var empty := "○".repeat(5 - competence)
	return filled + empty
```

- [ ] **Step 3: Create IncidentResolutionScene.tscn**

Create `game/src/ui/IncidentResolutionScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/IncidentResolutionScene.gd" id="1_irscene"]

[node name="IncidentResolutionScene" type="VBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
script = ExtResource("1_irscene")

[node name="IncidentHeader" type="PanelContainer" parent="."]
layout_mode = 2

[node name="HeaderContent" type="VBoxContainer" parent="IncidentHeader"]
layout_mode = 2

[node name="CategoryLabel" type="Label" parent="IncidentHeader/HeaderContent"]
layout_mode = 2
text = "INCIDENT"

[node name="TitleLabel" type="Label" parent="IncidentHeader/HeaderContent"]
layout_mode = 2
text = "Title"

[node name="FlavourLabel" type="Label" parent="IncidentHeader/HeaderContent"]
layout_mode = 2
text = "Flavour"
autowrap_mode = 3

[node name="StateLabel" type="Label" parent="IncidentHeader/HeaderContent"]
layout_mode = 2
text = "State"

[node name="MainArea" type="HBoxContainer" parent="."]
layout_mode = 2
size_flags_vertical = 3

[node name="ArtPanel" type="ColorRect" parent="MainArea"]
layout_mode = 2
size_flags_horizontal = 2
size_flags_stretch_ratio = 2.0
color = Color(0.08, 0.08, 0.1, 1)

[node name="CouncilPanel" type="VBoxContainer" parent="MainArea"]
layout_mode = 2
size_flags_horizontal = 3

[node name="CouncilLabel" type="Label" parent="MainArea/CouncilPanel"]
layout_mode = 2
text = "OFFICER COUNCIL"

[node name="ProposalList" type="VBoxContainer" parent="MainArea/CouncilPanel"]
layout_mode = 2
size_flags_vertical = 3

[node name="ConfirmButton" type="Button" parent="MainArea/CouncilPanel"]
layout_mode = 2
text = "CONFIRM"
visible = false

[node name="SilenceFooter" type="Label" parent="MainArea/CouncilPanel"]
layout_mode = 2
text = ""
autowrap_mode = 3
```

- [ ] **Step 4: Commit**

```bash
git add game/src/ui/IncidentResolutionScene.gd \
        game/src/ui/IncidentResolutionScene.gd.uid \
        game/src/ui/IncidentResolutionScene.tscn
git commit -m "feat(stage-4): IncidentResolutionScene UI — officer council card layout"
```

---

## Task 8: Debug scene integration

**Files:**
- Modify: `game/test/ContentDebugScene.tscn`
- Modify: `game/test/ContentDebugScene.gd`

Wire `IncidentResolutionScene` as a panel swap in the debug scene output area. Add a "Toggle Rationing" button to test standing order effects.

- [ ] **Step 1: Add nodes to ContentDebugScene.tscn**

In `game/test/ContentDebugScene.tscn`, add two nodes:

First, add a `ToggleRationing` button to the sidebar after `ForceIncident`:

```
[node name="ToggleRationing" type="Button" parent="SidebarScroll/Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Toggle Rationing"
```

Second, add the incident resolution container as a sibling to `OutputContainer`:

```
[node name="IncidentContainer" type="PanelContainer" parent="."]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
visible = false
```

- [ ] **Step 2: Update ContentDebugScene.gd**

Add to the top of the class (after the existing instance variables):

```gdscript
var _incident_scene: Node = null
```

In `_ready()`, add after the existing Stage 3 connections:

```gdscript
	# Stage 4 — incident resolution + standing orders
	$SidebarScroll/Sidebar/ToggleRationing.pressed.connect(_on_toggle_rationing)
```

Add the `_on_toggle_rationing` handler:

```gdscript
func _on_toggle_rationing() -> void:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active.[/color]\n")
		return
	if _state.has_standing_order("tighten_rationing"):
		_state.standing_orders.erase("tighten_rationing")
		_clear_output()
		_output.append_text("[color=#ff9966]Standing order cancelled: Tighten Rationing[/color]\n")
	else:
		_state.standing_orders.append("tighten_rationing")
		_clear_output()
		_output.append_text("[color=#88ff88]Standing order active: Tighten Rationing[/color]\n")
	_show_state_summary()
```

Replace `_on_force_incident()` entirely:

```gdscript
func _on_force_incident() -> void:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active. Press 'Show Route' first.[/color]\n")
		return

	# If already showing the resolution scene, do nothing
	if $IncidentContainer.visible:
		return

	# Ensure a pending incident exists — scan if none
	if _state.pending_incident_id.is_empty():
		var incidents := ContentRegistry.get_all("incidents")
		var eligible: Array = []
		var weights: Array = []
		var total_weight: float = 0.0
		for item: ContentBase in incidents:
			var incident := item as IncidentDef
			if incident == null or incident.trigger_band != "tick":
				continue
			if not ConditionEvaluator.all_met(_state, incident.required_conditions, _log):
				continue
			var w := TravelSimulator.compute_incident_weight(_state, incident, _log)
			eligible.append(incident)
			weights.append(w)
			total_weight += w

		if eligible.is_empty():
			# Fallback squall
			var b := EffectDef.new()
			b.type = "burden_change"
			b.delta = 5
			EffectProcessor.apply(_state, b, _log)
			var d := EffectDef.new()
			d.type = "add_damage_tag"
			d.tag = "storm_damage"
			EffectProcessor.apply(_state, d, _log)
			_clear_output()
			_output.append_text("[color=#ff9966]A squall strikes without warning. (Burden +5, storm_damage)[/color]\n")
			_show_state_summary()
			return

		# Weighted random pick
		var roll := randf() * total_weight
		var cumulative: float = 0.0
		for i: int in range(eligible.size()):
			cumulative += weights[i]
			if roll <= cumulative:
				_state.pending_incident_id = eligible[i].id
				break

	# Show the resolution scene
	_show_incident_resolution()


func _show_incident_resolution() -> void:
	if _incident_scene != null:
		_incident_scene.queue_free()
		_incident_scene = null

	var scene_res := preload("res://src/ui/IncidentResolutionScene.tscn")
	_incident_scene = scene_res.instantiate()
	_incident_scene.setup(_state, _log)
	_incident_scene.resolved.connect(_on_incident_resolved)
	$IncidentContainer.add_child(_incident_scene)
	_incident_scene.populate()

	$OutputContainer.visible = false
	$IncidentContainer.visible = true


func _on_incident_resolved() -> void:
	$IncidentContainer.visible = false
	$OutputContainer.visible = true
	if _incident_scene != null:
		_incident_scene.queue_free()
		_incident_scene = null
	_clear_output()
	_output.append_text("[color=#88ff88]Incident resolved.[/color]\n\n")
	_show_state_summary()
```

- [ ] **Step 3: Launch Godot and test manually**

Run the game:

```bash
godot --path game 2>&1 &
```

Manual test steps:
1. Press **New Expedition** — state initialises
2. Press **Show Route** — route map appears
3. Press **Toggle Rationing** — output shows "Standing order active: Tighten Rationing"
4. Press **Force Incident** — incident resolution scene appears with officer cards
5. Click bosun card — card highlights, CONFIRM appears
6. Click CONFIRM — scene dismisses, state summary shows, leadership_tags includes harsh: 1
7. Press **Force Incident** again — another incident or squall fallback
8. Press **Toggle Rationing** again — cancels the order

- [ ] **Step 4: Commit**

```bash
git add game/test/ContentDebugScene.gd game/test/ContentDebugScene.tscn
git commit -m "feat(stage-4): integrate IncidentResolutionScene into debug scene with Toggle Rationing"
```

---

## Task 9: Stage 4+5 test suite — complete + headless run

**Files:**
- Modify: `game/test/Stage45Test.gd`

Extend the test suite with officer council integration tests and confirm all suites pass.

- [ ] **Step 1: Add integration tests using real content**

Append to `_ready()` in `game/test/Stage45Test.gd`:

```gdscript
	_test_officer_council_with_registry()
	_test_leadership_tag_nudge_via_choice()
```

Add the test functions:

```gdscript
func _test_officer_council_with_registry() -> void:
	print("-- OfficerCouncil with ContentRegistry --")
	var state := ExpeditionState.new()
	# Both bosun and surgeon are loaded by ContentRegistry autoload
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)

	var incident := ContentRegistry.get_by_id("incidents", "drunk_purser_store_error") as IncidentDef
	check(incident != null, "drunk_purser_store_error loads from registry")

	state.officers = ["bosun", "surgeon"]
	var proposals := OfficerCouncil.get_proposals(state, incident, officer_defs)

	var officer_proposals := proposals.filter(func(p): return p["type"] == "officer")
	var direct_orders := proposals.filter(func(p): return p["type"] == "direct_order")

	check(officer_proposals.size() == 2, "bosun and surgeon both generate proposals")
	check(direct_orders.size() == 1, "always one direct order")

	var bosun_prop := officer_proposals.filter(func(p): return p["officer_id"] == "bosun")
	var surgeon_prop := officer_proposals.filter(func(p): return p["officer_id"] == "surgeon")
	check(bosun_prop.size() == 1, "bosun has a proposal for drunk_purser_store_error")
	check(surgeon_prop.size() == 1, "surgeon has a proposal for drunk_purser_store_error")

	var bosun_choice: IncidentChoiceDef = bosun_prop[0]["choice"]
	var surgeon_choice: IncidentChoiceDef = surgeon_prop[0]["choice"]
	check(bosun_choice.leadership_tag == "harsh", "bosun choice has harsh leadership_tag")
	check(surgeon_choice.leadership_tag == "merciful", "surgeon choice has merciful leadership_tag")


func _test_leadership_tag_nudge_via_choice() -> void:
	print("-- leadership_tag nudge via choice --")
	var state := ExpeditionState.new()
	check(state.leadership_tags.get("harsh", 0) == 0, "harsh starts at 0")
	check(state.leadership_tags.get("authoritarian", 0) == 0, "authoritarian starts at 0")

	state.nudge_leadership_tag("harsh")
	check(state.leadership_tags.get("harsh", 0) == 1, "harsh increments to 1 after bosun choice")

	state.nudge_leadership_tag("authoritarian")
	check(state.leadership_tags.get("authoritarian", 0) == 1, "authoritarian increments after direct order")
```

- [ ] **Step 2: Run Stage45Test to confirm all pass**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -15
```

Expected: `ALL PASS` with a count showing all tests passing.

- [ ] **Step 3: Run all three existing test suites**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5 && \
godot --headless --path game res://test/ExpeditionStateTest.tscn 2>&1 | tail -5 && \
godot --headless --path game res://test/RouteMapTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS` for all three.

- [ ] **Step 4: Final commit**

```bash
git add game/test/Stage45Test.gd
git commit -m "feat(stage-4): complete Stage 4+5 test suite — all suites passing"
```

---

## Validation checklist

After all tasks complete, verify against the spec:

- [ ] `has_standing_order` condition evaluates correctly
- [ ] `nudge_leadership_tag` works for any tag including `authoritarian`
- [ ] `compute_incident_weight` returns 1.0 by default, applies multipliers when conditions met
- [ ] `TravelSimulator` uses weighted random selection (not first-eligible)
- [ ] `OfficerCouncil.get_proposals` returns officer proposals, silence proposals, and always one direct_order
- [ ] `drunk_purser_store_error` has bosun choice (harsh), surgeon choice (merciful)
- [ ] `food_dispute` has weight_modifier ×0.3 when tighten_rationing active
- [ ] `crew_fight` has weight_modifier ×2.0 when tighten_rationing active
- [ ] Incident resolution scene shows: incident header, officer cards, direct order card, silent officer footer
- [ ] Selecting a card shows inline CONFIRM button
- [ ] Confirming applies effects + nudges leadership_tag + clears pending_incident_id
- [ ] Direct Order nudges authoritarian
- [ ] Toggle Rationing adds/removes tighten_rationing from standing_orders
- [ ] After resolution, debug scene returns to output view and shows state summary
- [ ] All four test suites pass headlessly
