# Stage 2: Core Expedition State and Simulation Rules — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core expedition state model, effect/condition processors, Rum special-case rules, promise system, simulation log, headless tests, and an interactive debug scene extension.

**Architecture:** Single `ExpeditionState` RefCounted + stateless `EffectProcessor`/`ConditionEvaluator` utilities + `RumRules` handler + `SimulationLog`. All driven by content-defined `EffectDef`/`ConditionDef` from Stage 1. Debug scene extended with Expedition Sim buttons.

**Tech Stack:** Godot 4.6, GDScript, Stage 1 content framework (ContentRegistry autoload, typed Resource definitions)

**Spec:** `docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md`

**Existing code context:**
- Content framework: `src/content/ContentBase.gd`, `ContentRegistry.gd`, `ContentValidator.gd`
- Resource defs: `src/content/resources/EffectDef.gd`, `ConditionDef.gd`, `SupplyDef.gd`, etc.
- Debug scene: `test/ContentDebugScene.tscn` + `.gd`
- Headless tests: `test/ContentFrameworkTest.tscn` + `.gd`
- Run headless tests: `godot --headless --path game res://test/ContentFrameworkTest.tscn`
- All paths below are relative to `game/` (the Godot project root at `/home/joe/repos/deadreckoning/game/`)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `src/content/resources/EffectDef.gd` | Modify | Add `target_id` field |
| `src/content/resources/ConditionDef.gd` | Modify | Add `target_id` field |
| `src/expedition/SimulationLog.gd` | Create | Append-only explanation log |
| `src/expedition/ExpeditionState.gd` | Create | Mutable run state bag + factory + promise methods |
| `src/expedition/EffectProcessor.gd` | Create | Stateless effect applicator |
| `src/expedition/ConditionEvaluator.gd` | Create | Stateless condition checker |
| `src/expedition/RumRules.gd` | Create | Rum special-case tick logic |
| `test/ExpeditionStateTest.tscn` | Create | Headless test scene |
| `test/ExpeditionStateTest.gd` | Create | Headless test script |
| `test/ContentDebugScene.tscn` | Modify | Add Expedition Sim sidebar buttons |
| `test/ContentDebugScene.gd` | Modify | Add expedition sim UI logic |

---

## Task 1: Add `target_id` to EffectDef and ConditionDef

**Files:**
- Modify: `src/content/resources/EffectDef.gd`
- Modify: `src/content/resources/ConditionDef.gd`

- [ ] **Step 1: Add `target_id` to EffectDef**

Open `src/content/resources/EffectDef.gd` and add after the `tag` field:

```gdscript
## Target id for supply_change (supply id), officer-targeting effects, etc.
@export var target_id: String = ""
```

Full file should be:

```gdscript
# EffectDef.gd
# Inline Resource representing one discrete effect applied to expedition state.
# Embedded inside IncidentChoiceDef, StandingOrderDef, ShipUpgradeDef — not stored standalone.
#
# Valid types: burden_change, command_change, supply_change, ship_condition_change,
#              add_damage_tag, remove_damage_tag, set_memory_flag,
#              add_crew_trait, remove_crew_trait
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name EffectDef
extends Resource

## Effect type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric change for burden_change, command_change, supply_change, ship_condition_change.
@export var delta: int = 0

## Memory flag key for set_memory_flag effects.
@export var flag_key: String = ""

## Damage or crew trait tag for add/remove_damage_tag and add/remove_crew_trait effects.
@export var tag: String = ""

## Target id for supply_change (supply id), officer-targeting effects, etc.
@export var target_id: String = ""
```

- [ ] **Step 2: Add `target_id` to ConditionDef**

Open `src/content/resources/ConditionDef.gd` and add after the `tag` field:

```gdscript
## Target id for supply_below (supply id), officer_present (officer id), etc.
@export var target_id: String = ""
```

Full file should be:

```gdscript
# ConditionDef.gd
# Inline Resource representing one condition check against expedition state.
# Embedded inside IncidentDef and IncidentChoiceDef — not stored standalone.
#
# Valid types: burden_above, burden_below, command_above, command_below, supply_below,
#              has_damage_tag, has_memory_flag, has_crew_trait, officer_present, zone_type_is
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ConditionDef
extends Resource

## Condition type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric threshold for burden_above/below, command_above/below, supply_below.
@export var threshold: int = 0

## Memory flag key for has_memory_flag conditions.
@export var flag_key: String = ""

## Tag string for has_damage_tag, has_crew_trait conditions.
@export var tag: String = ""

## Target id for supply_below (supply id), officer_present (officer id), etc.
@export var target_id: String = ""
```

- [ ] **Step 3: Run existing tests to verify no regression**

Run: `godot --headless --path game res://test/ContentFrameworkTest.tscn`
Expected: ALL PASS — adding a new default-empty field should not break any existing tests or .tres files.

- [ ] **Step 4: Commit**

```bash
git add src/content/resources/EffectDef.gd src/content/resources/ConditionDef.gd
git commit -m "feat(stage-2): add target_id field to EffectDef and ConditionDef"
```

---

## Task 2: Create SimulationLog

**Files:**
- Create: `src/expedition/SimulationLog.gd`

- [ ] **Step 1: Write SimulationLog test cases**

Add these test methods to the test file we'll create in Task 6. For now, write `SimulationLog.gd` first since it has no dependencies and is needed by everything else.

- [ ] **Step 2: Create `src/expedition/SimulationLog.gd`**

```gdscript
# SimulationLog.gd
# Append-only explanation log for expedition state changes.
# Records why effects were applied, why conditions passed/failed, and general events.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name SimulationLog
extends RefCounted

var _entries: Array[Dictionary] = []


func log_effect(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func log_condition(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func log_event(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func get_entries() -> Array[Dictionary]:
	return _entries


func get_entries_since(tick: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		if entry.tick >= tick:
			result.append(entry)
	return result


func clear() -> void:
	_entries.clear()
```

- [ ] **Step 3: Commit**

```bash
git add src/expedition/SimulationLog.gd
git commit -m "feat(stage-2): add SimulationLog for expedition state explanation tracking"
```

---

## Task 3: Create ExpeditionState

**Files:**
- Create: `src/expedition/ExpeditionState.gd`

- [ ] **Step 1: Create `src/expedition/ExpeditionState.gd`**

```gdscript
# ExpeditionState.gd
# Mutable state bag for a single expedition run.
# Holds Burden, Command, supplies, ship condition, damage tags, crew traits,
# officers, promises, leadership tags, memory flags, rum state, and stress indicators.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ExpeditionState
extends RefCounted

var burden: int = 20
var command: int = 70
var supplies: Dictionary = {}  # { supply_id: int }
var ship_condition: int = 100
var damage_tags: Array[String] = []
var crew_traits: Array[String] = []
var officers: Array[String] = []
var standing_orders: Array[String] = []
var active_promise: Dictionary = {}  # { id, text, deadline_ticks, ticks_remaining } or empty
var leadership_tags: Dictionary = {
	"harsh": 0, "merciful": 0,
	"honest": 0, "deceptive": 0,
	"shared_hardship": 0, "privilege": 0,
}
var memory_flags: Array[String] = []
var rum_ration_expected: bool = false
var spirit_store_locked: bool = false
var rum_theft_risk: int = 0
var rum_drunkenness_risk: int = 0
var tick_count: int = 0
var stress_indicators: Dictionary = {
	"peak_burden": 20,
	"min_command": 70,
	"crew_losses": 0,
	"supply_depletions": 0,
}


static func create_default() -> ExpeditionState:
	var state := ExpeditionState.new()

	# Populate supplies from SupplyDefs
	var supply_defs := ContentRegistry.get_all("supplies")
	for def: ContentBase in supply_defs:
		var supply_def: SupplyDef = def as SupplyDef
		if supply_def:
			state.supplies[supply_def.id] = supply_def.starting_amount
			if supply_def.is_rum and supply_def.starting_amount > 0:
				state.rum_ration_expected = true

	# Populate officers from OfficerDefs
	var officer_defs := ContentRegistry.get_all("officers")
	for def: ContentBase in officer_defs:
		var officer_def: OfficerDef = def as OfficerDef
		if officer_def:
			state.officers.append(officer_def.id)

	return state


# --- Supply accessors ---

func get_supply(supply_id: String) -> int:
	if not supplies.has(supply_id):
		return 0
	return supplies[supply_id]


func set_supply(supply_id: String, amount: int) -> void:
	supplies[supply_id] = maxi(amount, 0)


# --- Damage tag accessors ---

func has_damage_tag(tag: String) -> bool:
	return tag in damage_tags


func add_damage_tag(tag: String) -> void:
	if tag not in damage_tags:
		damage_tags.append(tag)


func remove_damage_tag(tag: String) -> void:
	damage_tags.erase(tag)


# --- Memory flag accessors ---

func has_memory_flag(flag: String) -> bool:
	return flag in memory_flags


func add_memory_flag(flag: String) -> void:
	if flag not in memory_flags:
		memory_flags.append(flag)


# --- Crew trait accessors ---

func has_crew_trait(trait_tag: String) -> bool:
	return trait_tag in crew_traits


func add_crew_trait(trait_tag: String) -> void:
	if trait_tag not in crew_traits:
		crew_traits.append(trait_tag)


func remove_crew_trait(trait_tag: String) -> void:
	crew_traits.erase(trait_tag)


# --- Officer accessor ---

func has_officer(officer_id: String) -> bool:
	return officer_id in officers


# --- Promise methods ---

func make_promise(id: String, text: String, deadline_ticks: int, log: SimulationLog) -> bool:
	if not active_promise.is_empty():
		log.log_event(tick_count, "Promise", "Cannot make promise — one already active.", {"attempted_id": id})
		return false
	active_promise = {
		"id": id,
		"text": text,
		"deadline_ticks": deadline_ticks,
		"ticks_remaining": deadline_ticks,
	}
	command = clampi(command + 3, 0, 100)
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	log.log_event(tick_count, "Promise", "Promise made: %s (Command +3)" % text, {"id": id, "deadline": deadline_ticks})
	return true


func tick_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	active_promise.ticks_remaining -= 1
	if active_promise.ticks_remaining <= 0:
		log.log_event(tick_count, "Promise", "Promise deadline expired — auto-breaking.", {"id": active_promise.id})
		break_promise(log)


func keep_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	var promise_id: String = active_promise.id
	var promise_text: String = active_promise.text
	command = clampi(command + 5, 0, 100)
	burden = clampi(burden - 3, 0, 100)
	if burden > stress_indicators.peak_burden:
		stress_indicators.peak_burden = burden
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	add_memory_flag("promise_kept_" + promise_id)
	log.log_event(tick_count, "Promise", "Promise kept: %s (Command +5, Burden -3)" % promise_text, {"id": promise_id})
	active_promise = {}


func break_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	var promise_id: String = active_promise.id
	var promise_text: String = active_promise.text
	command = clampi(command - 5, 0, 100)
	burden = clampi(burden + 5, 0, 100)
	if burden > stress_indicators.peak_burden:
		stress_indicators.peak_burden = burden
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	add_memory_flag("promise_broken_" + promise_id)
	log.log_event(tick_count, "Promise", "Promise broken: %s (Command -5, Burden +5)" % promise_text, {"id": promise_id})
	active_promise = {}
```

- [ ] **Step 2: Commit**

```bash
git add src/expedition/ExpeditionState.gd
git commit -m "feat(stage-2): add ExpeditionState with factory, accessors, and promise system"
```

---

## Task 4: Create EffectProcessor

**Files:**
- Create: `src/expedition/EffectProcessor.gd`

- [ ] **Step 1: Create `src/expedition/EffectProcessor.gd`**

```gdscript
# EffectProcessor.gd
# Stateless utility for applying EffectDefs to an ExpeditionState.
# Every application writes an explanation entry to SimulationLog.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name EffectProcessor


static func apply(state: ExpeditionState, effect: EffectDef, log: SimulationLog) -> void:
	match effect.type:
		"burden_change":
			var before := state.burden
			state.burden = clampi(state.burden + effect.delta, 0, 100)
			if state.burden > state.stress_indicators.peak_burden:
				state.stress_indicators.peak_burden = state.burden
			log.log_effect(state.tick_count, "EffectProcessor",
				"Burden %+d (%d → %d)" % [effect.delta, before, state.burden],
				{"type": "burden_change", "delta": effect.delta, "before": before, "after": state.burden})

		"command_change":
			var before := state.command
			state.command = clampi(state.command + effect.delta, 0, 100)
			if state.command < state.stress_indicators.min_command:
				state.stress_indicators.min_command = state.command
			log.log_effect(state.tick_count, "EffectProcessor",
				"Command %+d (%d → %d)" % [effect.delta, before, state.command],
				{"type": "command_change", "delta": effect.delta, "before": before, "after": state.command})

		"supply_change":
			var before := state.get_supply(effect.target_id)
			state.set_supply(effect.target_id, before + effect.delta)
			var after := state.get_supply(effect.target_id)
			if after == 0 and before > 0:
				state.stress_indicators.supply_depletions += 1
			log.log_effect(state.tick_count, "EffectProcessor",
				"%s %+d (%d → %d)" % [effect.target_id, effect.delta, before, after],
				{"type": "supply_change", "target": effect.target_id, "delta": effect.delta, "before": before, "after": after})

		"ship_condition_change":
			var before := state.ship_condition
			state.ship_condition = clampi(state.ship_condition + effect.delta, 0, 100)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Ship condition %+d (%d → %d)" % [effect.delta, before, state.ship_condition],
				{"type": "ship_condition_change", "delta": effect.delta, "before": before, "after": state.ship_condition})

		"add_damage_tag":
			state.add_damage_tag(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Added damage tag: %s" % effect.tag,
				{"type": "add_damage_tag", "tag": effect.tag})

		"remove_damage_tag":
			state.remove_damage_tag(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Removed damage tag: %s" % effect.tag,
				{"type": "remove_damage_tag", "tag": effect.tag})

		"set_memory_flag":
			state.add_memory_flag(effect.flag_key)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Set memory flag: %s" % effect.flag_key,
				{"type": "set_memory_flag", "flag": effect.flag_key})

		"add_crew_trait":
			state.add_crew_trait(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Added crew trait: %s" % effect.tag,
				{"type": "add_crew_trait", "tag": effect.tag})

		"remove_crew_trait":
			state.remove_crew_trait(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Removed crew trait: %s" % effect.tag,
				{"type": "remove_crew_trait", "tag": effect.tag})

		_:
			push_warning("EffectProcessor: unknown effect type '%s'" % effect.type)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Unknown effect type: %s (skipped)" % effect.type,
				{"type": effect.type, "error": "unknown_type"})


static func apply_effects(state: ExpeditionState, effects: Array, log: SimulationLog) -> void:
	for effect: EffectDef in effects:
		apply(state, effect, log)
```

- [ ] **Step 2: Commit**

```bash
git add src/expedition/EffectProcessor.gd
git commit -m "feat(stage-2): add EffectProcessor for content-driven state changes"
```

---

## Task 5: Create ConditionEvaluator

**Files:**
- Create: `src/expedition/ConditionEvaluator.gd`

- [ ] **Step 1: Create `src/expedition/ConditionEvaluator.gd`**

```gdscript
# ConditionEvaluator.gd
# Stateless utility for evaluating ConditionDefs against an ExpeditionState.
# Every evaluation logs whether it passed or failed and why.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ConditionEvaluator


static func evaluate(state: ExpeditionState, condition: ConditionDef, log: SimulationLog) -> bool:
	var result: bool = false
	var message: String = ""
	var details: Dictionary = {"condition": condition.type, "threshold": condition.threshold}

	match condition.type:
		"burden_above":
			result = state.burden >= condition.threshold
			details["actual"] = state.burden
			message = "Burden %d >= %d? %s" % [state.burden, condition.threshold, "PASS" if result else "FAIL"]

		"burden_below":
			result = state.burden <= condition.threshold
			details["actual"] = state.burden
			message = "Burden %d <= %d? %s" % [state.burden, condition.threshold, "PASS" if result else "FAIL"]

		"command_above":
			result = state.command >= condition.threshold
			details["actual"] = state.command
			message = "Command %d >= %d? %s" % [state.command, condition.threshold, "PASS" if result else "FAIL"]

		"command_below":
			result = state.command <= condition.threshold
			details["actual"] = state.command
			message = "Command %d <= %d? %s" % [state.command, condition.threshold, "PASS" if result else "FAIL"]

		"supply_below":
			var amount := state.get_supply(condition.target_id)
			result = amount <= condition.threshold
			details["actual"] = amount
			details["target"] = condition.target_id
			message = "%s %d <= %d? %s" % [condition.target_id, amount, condition.threshold, "PASS" if result else "FAIL"]

		"has_damage_tag":
			result = state.has_damage_tag(condition.tag)
			details["tag"] = condition.tag
			message = "Has damage tag '%s'? %s" % [condition.tag, "PASS" if result else "FAIL"]

		"has_memory_flag":
			result = state.has_memory_flag(condition.flag_key)
			details["flag"] = condition.flag_key
			message = "Has memory flag '%s'? %s" % [condition.flag_key, "PASS" if result else "FAIL"]

		"has_crew_trait":
			result = state.has_crew_trait(condition.tag)
			details["tag"] = condition.tag
			message = "Has crew trait '%s'? %s" % [condition.tag, "PASS" if result else "FAIL"]

		"officer_present":
			result = state.has_officer(condition.target_id)
			details["target"] = condition.target_id
			message = "Officer '%s' present? %s" % [condition.target_id, "PASS" if result else "FAIL"]

		"zone_type_is":
			# Deferred to Stage 3 — always passes for now
			result = true
			details["tag"] = condition.tag
			message = "Zone type is '%s'? PASS (deferred — always true)" % condition.tag

		_:
			push_warning("ConditionEvaluator: unknown condition type '%s'" % condition.type)
			result = false
			message = "Unknown condition type: %s (FAIL)" % condition.type
			details["error"] = "unknown_type"

	details["passed"] = result
	log.log_condition(state.tick_count, "ConditionEvaluator", message, details)
	return result


static func all_met(state: ExpeditionState, conditions: Array, log: SimulationLog) -> bool:
	var all_passed := true
	for condition: ConditionDef in conditions:
		if not evaluate(state, condition, log):
			all_passed = false
	return all_passed
```

- [ ] **Step 2: Commit**

```bash
git add src/expedition/ConditionEvaluator.gd
git commit -m "feat(stage-2): add ConditionEvaluator for content-driven state checks"
```

---

## Task 6: Create RumRules

**Files:**
- Create: `src/expedition/RumRules.gd`

- [ ] **Step 1: Create `src/expedition/RumRules.gd`**

```gdscript
# RumRules.gd
# Special-case Rum tick logic. Handles ration consumption, ration-withheld fallout,
# rum exhaustion, theft risk, and drunkenness risk.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name RumRules

static var _rum_id: String = ""
static var _rum_id_cached: bool = false


static func _get_rum_id() -> String:
	if _rum_id_cached:
		return _rum_id
	_rum_id_cached = true
	var supply_defs := ContentRegistry.get_all("supplies")
	for def: ContentBase in supply_defs:
		var supply_def: SupplyDef = def as SupplyDef
		if supply_def and supply_def.is_rum:
			_rum_id = supply_def.id
			return _rum_id
	return ""


static func update_on_tick(state: ExpeditionState, log: SimulationLog) -> void:
	var rum_id := _get_rum_id()
	if rum_id.is_empty():
		return

	var rum_amount := state.get_supply(rum_id)

	# Ration consumption
	if rum_amount > 0 and state.rum_ration_expected and not state.spirit_store_locked:
		state.set_supply(rum_id, rum_amount - 1)
		state.burden = clampi(state.burden - 1, 0, 100)
		log.log_event(state.tick_count, "RumRules",
			"Rum ration issued. Crew morale steadied. (Rum -1, Burden -1)",
			{"rum_before": rum_amount, "rum_after": state.get_supply(rum_id), "burden": state.burden})

	# Ration withheld (store locked but crew expects it)
	elif rum_amount > 0 and state.rum_ration_expected and state.spirit_store_locked:
		state.burden = clampi(state.burden + 2, 0, 100)
		if state.burden > state.stress_indicators.peak_burden:
			state.stress_indicators.peak_burden = state.burden
		log.log_event(state.tick_count, "RumRules",
			"Rum ration withheld. The crew grumbles. (Burden +2)",
			{"rum_amount": rum_amount, "burden": state.burden})

	# Rum ran out
	elif rum_amount == 0 and state.rum_ration_expected:
		state.burden = clampi(state.burden + 4, 0, 100)
		if state.burden > state.stress_indicators.peak_burden:
			state.stress_indicators.peak_burden = state.burden
		state.rum_ration_expected = false
		state.add_memory_flag("rum_ration_ended")
		log.log_event(state.tick_count, "RumRules",
			"Rum stores exhausted. The crew expected their ration. (Burden +4)",
			{"burden": state.burden})

	# Refresh rum_amount after potential consumption
	rum_amount = state.get_supply(rum_id)

	# Theft risk
	if rum_amount > 0 and not state.spirit_store_locked:
		state.rum_theft_risk = clampi(30 + (100 - state.command) / 2, 0, 100)
	else:
		state.rum_theft_risk = clampi(state.rum_theft_risk - 10, 0, 100)

	# Drunkenness risk
	if rum_amount > 20 and not state.spirit_store_locked:
		state.rum_drunkenness_risk = clampi(20 + rum_amount / 5, 0, 100)
	else:
		state.rum_drunkenness_risk = clampi(state.rum_drunkenness_risk - 10, 0, 100)
```

- [ ] **Step 2: Commit**

```bash
git add src/expedition/RumRules.gd
git commit -m "feat(stage-2): add RumRules for Rum special-case tick logic"
```

---

## Task 7: Create Headless Test Suite

**Files:**
- Create: `test/ExpeditionStateTest.tscn`
- Create: `test/ExpeditionStateTest.gd`

- [ ] **Step 1: Create `test/ExpeditionStateTest.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/ExpeditionStateTest.gd" id="1"]

[node name="ExpeditionStateTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Create `test/ExpeditionStateTest.gd`**

```gdscript
# ExpeditionStateTest.gd
# Headless test suite for Stage 2: Expedition State and Simulation Rules.
# Run: godot --headless --path game res://test/ExpeditionStateTest.tscn
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
	print("=== ExpeditionStateTest ===\n")
	_test_simulation_log()
	_test_expedition_state_defaults()
	_test_expedition_state_accessors()
	_test_effect_processor_burden()
	_test_effect_processor_command()
	_test_effect_processor_supply()
	_test_effect_processor_ship_condition()
	_test_effect_processor_tags_and_flags()
	_test_effect_processor_crew_traits()
	_test_effect_processor_batch()
	_test_effect_processor_clamping()
	_test_effect_processor_stress_indicators()
	_test_condition_evaluator_burden_command()
	_test_condition_evaluator_supply()
	_test_condition_evaluator_tags_flags_traits()
	_test_condition_evaluator_officer()
	_test_condition_evaluator_zone_deferred()
	_test_condition_evaluator_all_met()
	_test_rum_rules_ration_consumed()
	_test_rum_rules_ration_withheld()
	_test_rum_rules_rum_ran_out()
	_test_rum_rules_theft_and_drunkenness_risk()
	_test_promise_lifecycle_keep()
	_test_promise_lifecycle_break_on_expiry()
	_test_promise_cannot_double()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# --- Helpers ---

func _make_state() -> ExpeditionState:
	return ExpeditionState.create_default()

func _make_log() -> SimulationLog:
	return SimulationLog.new()

func _make_effect(type: String, delta: int = 0, target_id: String = "", flag_key: String = "", tag: String = "") -> EffectDef:
	var e := EffectDef.new()
	e.type = type
	e.delta = delta
	e.target_id = target_id
	e.flag_key = flag_key
	e.tag = tag
	return e

func _make_condition(type: String, threshold: int = 0, target_id: String = "", flag_key: String = "", tag: String = "") -> ConditionDef:
	var c := ConditionDef.new()
	c.type = type
	c.threshold = threshold
	c.target_id = target_id
	c.flag_key = flag_key
	c.tag = tag
	return c


# --- SimulationLog ---

func _test_simulation_log() -> void:
	print("-- SimulationLog --")
	var log := _make_log()
	check(log.get_entries().is_empty(), "Log starts empty")

	log.log_effect(0, "Test", "test effect", {"a": 1})
	check(log.get_entries().size() == 1, "Log has 1 entry after log_effect")
	check(log.get_entries()[0].message == "test effect", "Log entry message correct")
	check(log.get_entries()[0].source == "Test", "Log entry source correct")
	check(log.get_entries()[0].tick == 0, "Log entry tick correct")

	log.log_condition(1, "Test", "test condition", {"b": 2})
	log.log_event(2, "Test", "test event", {"c": 3})
	check(log.get_entries().size() == 3, "Log has 3 entries total")

	var since := log.get_entries_since(1)
	check(since.size() == 2, "get_entries_since(1) returns 2 entries")

	log.clear()
	check(log.get_entries().is_empty(), "Log empty after clear()")


# --- ExpeditionState defaults ---

func _test_expedition_state_defaults() -> void:
	print("-- ExpeditionState defaults --")
	var state := _make_state()
	check(state.burden == 20, "Default burden is 20")
	check(state.command == 70, "Default command is 70")
	check(state.ship_condition == 100, "Default ship condition is 100")
	check(state.tick_count == 0, "Default tick count is 0")
	check(state.damage_tags.is_empty(), "Default damage tags empty")
	check(state.memory_flags.is_empty(), "Default memory flags empty")
	check(state.active_promise.is_empty(), "Default promise empty")

	# Supplies populated from ContentRegistry
	check(state.supplies.has("rum"), "Supplies include rum")
	check(state.supplies.has("food"), "Supplies include food")
	check(state.supplies["rum"] == 100, "Rum starting amount is 100")

	# Officers populated from ContentRegistry
	check(state.officers.has("bosun"), "Officers include bosun")
	check(state.officers.has("surgeon"), "Officers include surgeon")

	# Rum ration expected when rum starts > 0
	check(state.rum_ration_expected == true, "Rum ration expected when rum > 0")
	check(state.spirit_store_locked == false, "Spirit store unlocked by default")

	# Stress indicators
	check(state.stress_indicators.peak_burden == 20, "peak_burden starts at initial burden")
	check(state.stress_indicators.min_command == 70, "min_command starts at initial command")
	check(state.stress_indicators.crew_losses == 0, "crew_losses starts at 0")
	check(state.stress_indicators.supply_depletions == 0, "supply_depletions starts at 0")


# --- ExpeditionState accessors ---

func _test_expedition_state_accessors() -> void:
	print("-- ExpeditionState accessors --")
	var state := _make_state()

	# Supply get/set with clamping
	state.set_supply("food", 50)
	check(state.get_supply("food") == 50, "set_supply/get_supply works")
	state.set_supply("food", -10)
	check(state.get_supply("food") == 0, "set_supply clamps to 0")
	check(state.get_supply("nonexistent") == 0, "get_supply returns 0 for unknown id")

	# Damage tags idempotency
	state.add_damage_tag("hull_strained")
	check(state.has_damage_tag("hull_strained"), "add/has_damage_tag works")
	state.add_damage_tag("hull_strained")
	check(state.damage_tags.count("hull_strained") == 1, "add_damage_tag is idempotent")
	state.remove_damage_tag("hull_strained")
	check(not state.has_damage_tag("hull_strained"), "remove_damage_tag works")
	state.remove_damage_tag("hull_strained")  # no-op, should not error

	# Memory flags idempotency
	state.add_memory_flag("test_flag")
	check(state.has_memory_flag("test_flag"), "add/has_memory_flag works")
	state.add_memory_flag("test_flag")
	check(state.memory_flags.count("test_flag") == 1, "add_memory_flag is idempotent")

	# Crew traits
	state.add_crew_trait("superstitious")
	check(state.has_crew_trait("superstitious"), "add/has_crew_trait works")
	state.add_crew_trait("superstitious")
	check(state.crew_traits.count("superstitious") == 1, "add_crew_trait is idempotent")
	state.remove_crew_trait("superstitious")
	check(not state.has_crew_trait("superstitious"), "remove_crew_trait works")

	# Officer check
	check(state.has_officer("bosun"), "has_officer works for present officer")
	check(not state.has_officer("navigator"), "has_officer returns false for absent officer")


# --- EffectProcessor ---

func _test_effect_processor_burden() -> void:
	print("-- EffectProcessor: burden_change --")
	var state := _make_state()
	var log := _make_log()
	var e := _make_effect("burden_change", 10)
	EffectProcessor.apply(state, e, log)
	check(state.burden == 30, "Burden increased by 10 (20 → 30)")
	check(log.get_entries().size() == 1, "Log entry written")
	check(log.get_entries()[0].details.before == 20, "Log records before value")
	check(log.get_entries()[0].details.after == 30, "Log records after value")


func _test_effect_processor_command() -> void:
	print("-- EffectProcessor: command_change --")
	var state := _make_state()
	var log := _make_log()
	var e := _make_effect("command_change", -15)
	EffectProcessor.apply(state, e, log)
	check(state.command == 55, "Command decreased by 15 (70 → 55)")
	check(state.stress_indicators.min_command == 55, "min_command updated")


func _test_effect_processor_supply() -> void:
	print("-- EffectProcessor: supply_change --")
	var state := _make_state()
	var log := _make_log()
	var e := _make_effect("supply_change", -3, "food")
	EffectProcessor.apply(state, e, log)
	var food_after := state.get_supply("food")
	# Food starting amount from .tres is expected; verify it decreased by 3
	check(log.get_entries()[0].details.target == "food", "Log records target supply")
	check(log.get_entries()[0].details.delta == -3, "Log records delta")


func _test_effect_processor_ship_condition() -> void:
	print("-- EffectProcessor: ship_condition_change --")
	var state := _make_state()
	var log := _make_log()
	var e := _make_effect("ship_condition_change", -20)
	EffectProcessor.apply(state, e, log)
	check(state.ship_condition == 80, "Ship condition decreased by 20 (100 → 80)")


func _test_effect_processor_tags_and_flags() -> void:
	print("-- EffectProcessor: damage tags and memory flags --")
	var state := _make_state()
	var log := _make_log()

	var add_tag := _make_effect("add_damage_tag", 0, "", "", "hull_strained")
	EffectProcessor.apply(state, add_tag, log)
	check(state.has_damage_tag("hull_strained"), "add_damage_tag effect works")

	var remove_tag := _make_effect("remove_damage_tag", 0, "", "", "hull_strained")
	EffectProcessor.apply(state, remove_tag, log)
	check(not state.has_damage_tag("hull_strained"), "remove_damage_tag effect works")

	var set_flag := EffectDef.new()
	set_flag.type = "set_memory_flag"
	set_flag.flag_key = "test_event"
	EffectProcessor.apply(state, set_flag, log)
	check(state.has_memory_flag("test_event"), "set_memory_flag effect works")


func _test_effect_processor_crew_traits() -> void:
	print("-- EffectProcessor: crew traits --")
	var state := _make_state()
	var log := _make_log()

	var add_trait := _make_effect("add_crew_trait", 0, "", "", "superstitious")
	EffectProcessor.apply(state, add_trait, log)
	check(state.has_crew_trait("superstitious"), "add_crew_trait effect works")

	var remove_trait := _make_effect("remove_crew_trait", 0, "", "", "superstitious")
	EffectProcessor.apply(state, remove_trait, log)
	check(not state.has_crew_trait("superstitious"), "remove_crew_trait effect works")


func _test_effect_processor_batch() -> void:
	print("-- EffectProcessor: batch --")
	var state := _make_state()
	var log := _make_log()
	var effects: Array = [
		_make_effect("burden_change", 5),
		_make_effect("command_change", -10),
		_make_effect("ship_condition_change", -5),
	]
	EffectProcessor.apply_effects(state, effects, log)
	check(state.burden == 25, "Batch: burden 20+5=25")
	check(state.command == 60, "Batch: command 70-10=60")
	check(state.ship_condition == 95, "Batch: ship condition 100-5=95")
	check(log.get_entries().size() == 3, "Batch: 3 log entries")


func _test_effect_processor_clamping() -> void:
	print("-- EffectProcessor: clamping --")
	var state := _make_state()
	var log := _make_log()

	# Burden can't exceed 100
	EffectProcessor.apply(state, _make_effect("burden_change", 200), log)
	check(state.burden == 100, "Burden clamped to 100")

	# Burden can't go below 0
	EffectProcessor.apply(state, _make_effect("burden_change", -200), log)
	check(state.burden == 0, "Burden clamped to 0")

	# Command can't exceed 100
	EffectProcessor.apply(state, _make_effect("command_change", 200), log)
	check(state.command == 100, "Command clamped to 100")

	# Command can't go below 0
	EffectProcessor.apply(state, _make_effect("command_change", -200), log)
	check(state.command == 0, "Command clamped to 0")

	# Ship condition clamping
	EffectProcessor.apply(state, _make_effect("ship_condition_change", -200), log)
	check(state.ship_condition == 0, "Ship condition clamped to 0")

	# Supply can't go below 0
	state.set_supply("food", 5)
	EffectProcessor.apply(state, _make_effect("supply_change", -100, "food"), log)
	check(state.get_supply("food") == 0, "Supply clamped to 0")


func _test_effect_processor_stress_indicators() -> void:
	print("-- EffectProcessor: stress indicators --")
	var state := _make_state()
	var log := _make_log()

	# peak_burden tracks highest burden
	EffectProcessor.apply(state, _make_effect("burden_change", 30), log)
	check(state.stress_indicators.peak_burden == 50, "peak_burden updated to 50")
	EffectProcessor.apply(state, _make_effect("burden_change", -10), log)
	check(state.stress_indicators.peak_burden == 50, "peak_burden stays at 50 after decrease")

	# min_command tracks lowest command
	EffectProcessor.apply(state, _make_effect("command_change", -20), log)
	check(state.stress_indicators.min_command == 50, "min_command updated to 50")
	EffectProcessor.apply(state, _make_effect("command_change", 10), log)
	check(state.stress_indicators.min_command == 50, "min_command stays at 50 after increase")

	# supply_depletions tracks supplies hitting 0
	state.set_supply("food", 1)
	EffectProcessor.apply(state, _make_effect("supply_change", -1, "food"), log)
	check(state.stress_indicators.supply_depletions == 1, "supply_depletions incremented when food hits 0")


# --- ConditionEvaluator ---

func _test_condition_evaluator_burden_command() -> void:
	print("-- ConditionEvaluator: burden/command --")
	var state := _make_state()
	var log := _make_log()

	# burden starts at 20
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_above", 10), log) == true, "burden_above 10: PASS (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_above", 30), log) == false, "burden_above 30: FAIL (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_below", 30), log) == true, "burden_below 30: PASS (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_below", 10), log) == false, "burden_below 10: FAIL (burden=20)")

	# command starts at 70
	check(ConditionEvaluator.evaluate(state, _make_condition("command_above", 50), log) == true, "command_above 50: PASS (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_above", 80), log) == false, "command_above 80: FAIL (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_below", 80), log) == true, "command_below 80: PASS (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_below", 50), log) == false, "command_below 50: FAIL (command=70)")


func _test_condition_evaluator_supply() -> void:
	print("-- ConditionEvaluator: supply_below --")
	var state := _make_state()
	var log := _make_log()
	state.set_supply("food", 5)
	check(ConditionEvaluator.evaluate(state, _make_condition("supply_below", 10, "food"), log) == true, "supply_below 10 food=5: PASS")
	check(ConditionEvaluator.evaluate(state, _make_condition("supply_below", 3, "food"), log) == false, "supply_below 3 food=5: FAIL")


func _test_condition_evaluator_tags_flags_traits() -> void:
	print("-- ConditionEvaluator: tags, flags, traits --")
	var state := _make_state()
	var log := _make_log()

	# has_damage_tag
	check(ConditionEvaluator.evaluate(state, _make_condition("has_damage_tag", 0, "", "", "hull_strained"), log) == false, "has_damage_tag: FAIL (absent)")
	state.add_damage_tag("hull_strained")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_damage_tag", 0, "", "", "hull_strained"), log) == true, "has_damage_tag: PASS (present)")

	# has_memory_flag
	check(ConditionEvaluator.evaluate(state, _make_condition("has_memory_flag", 0, "", "test_flag"), log) == false, "has_memory_flag: FAIL (absent)")
	state.add_memory_flag("test_flag")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_memory_flag", 0, "", "test_flag"), log) == true, "has_memory_flag: PASS (present)")

	# has_crew_trait
	check(ConditionEvaluator.evaluate(state, _make_condition("has_crew_trait", 0, "", "", "superstitious"), log) == false, "has_crew_trait: FAIL (absent)")
	state.add_crew_trait("superstitious")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_crew_trait", 0, "", "", "superstitious"), log) == true, "has_crew_trait: PASS (present)")


func _test_condition_evaluator_officer() -> void:
	print("-- ConditionEvaluator: officer_present --")
	var state := _make_state()
	var log := _make_log()
	check(ConditionEvaluator.evaluate(state, _make_condition("officer_present", 0, "bosun"), log) == true, "officer_present bosun: PASS")
	check(ConditionEvaluator.evaluate(state, _make_condition("officer_present", 0, "navigator"), log) == false, "officer_present navigator: FAIL")


func _test_condition_evaluator_zone_deferred() -> void:
	print("-- ConditionEvaluator: zone_type_is (deferred) --")
	var state := _make_state()
	var log := _make_log()
	check(ConditionEvaluator.evaluate(state, _make_condition("zone_type_is", 0, "", "", "coastal"), log) == true, "zone_type_is always PASS (deferred)")


func _test_condition_evaluator_all_met() -> void:
	print("-- ConditionEvaluator: all_met --")
	var state := _make_state()
	var log := _make_log()

	# All pass
	var passing: Array = [
		_make_condition("burden_above", 10),
		_make_condition("command_above", 50),
	]
	check(ConditionEvaluator.all_met(state, passing, log) == true, "all_met: all passing → true")

	# One fails
	var mixed: Array = [
		_make_condition("burden_above", 10),
		_make_condition("burden_above", 50),  # fails — burden is 20
	]
	check(ConditionEvaluator.all_met(state, mixed, log) == false, "all_met: one failing → false")


# --- RumRules ---

func _test_rum_rules_ration_consumed() -> void:
	print("-- RumRules: ration consumed --")
	var state := _make_state()
	var log := _make_log()
	var rum_before := state.get_supply("rum")
	var burden_before := state.burden
	RumRules.update_on_tick(state, log)
	check(state.get_supply("rum") == rum_before - 1, "Rum decreased by 1")
	check(state.burden == burden_before - 1, "Burden decreased by 1")


func _test_rum_rules_ration_withheld() -> void:
	print("-- RumRules: ration withheld --")
	var state := _make_state()
	var log := _make_log()
	state.spirit_store_locked = true
	var burden_before := state.burden
	var rum_before := state.get_supply("rum")
	RumRules.update_on_tick(state, log)
	check(state.get_supply("rum") == rum_before, "Rum not consumed when store locked")
	check(state.burden == burden_before + 2, "Burden increased by 2 when ration withheld")


func _test_rum_rules_rum_ran_out() -> void:
	print("-- RumRules: rum ran out --")
	var state := _make_state()
	var log := _make_log()
	state.set_supply("rum", 0)
	var burden_before := state.burden
	RumRules.update_on_tick(state, log)
	check(state.burden == burden_before + 4, "Burden spiked by 4 when rum exhausted")
	check(state.rum_ration_expected == false, "rum_ration_expected set to false")
	check(state.has_memory_flag("rum_ration_ended"), "rum_ration_ended memory flag set")

	# Second tick should not spike again
	var burden_after_first := state.burden
	RumRules.update_on_tick(state, log)
	check(state.burden == burden_after_first, "No burden change on second tick after rum ended")


func _test_rum_rules_theft_and_drunkenness_risk() -> void:
	print("-- RumRules: theft and drunkenness risk --")
	var state := _make_state()
	var log := _make_log()

	# With rum > 20 and store unlocked, both risks should be set
	state.set_supply("rum", 50)
	state.command = 60
	RumRules.update_on_tick(state, log)
	check(state.rum_theft_risk > 0, "Theft risk > 0 with rum and unlocked store")
	check(state.rum_drunkenness_risk > 0, "Drunkenness risk > 0 with rum > 20")

	# With store locked, theft risk decays
	state.spirit_store_locked = true
	state.rum_ration_expected = false  # prevent ration-withheld branch from changing burden
	var theft_before := state.rum_theft_risk
	RumRules.update_on_tick(state, log)
	check(state.rum_theft_risk < theft_before, "Theft risk decays when store locked")


# --- Promise system ---

func _test_promise_lifecycle_keep() -> void:
	print("-- Promise: make → keep --")
	var state := _make_state()
	var log := _make_log()

	var command_before := state.command
	var result := state.make_promise("landfall", "We will make landfall within five days", 5, log)
	check(result == true, "make_promise returns true")
	check(not state.active_promise.is_empty(), "Promise is active")
	check(state.active_promise.id == "landfall", "Promise id correct")
	check(state.active_promise.ticks_remaining == 5, "Promise ticks_remaining correct")
	check(state.command == command_before + 3, "Command +3 on promise made")

	# Tick it a couple times
	state.tick_promise(log)
	check(state.active_promise.ticks_remaining == 4, "ticks_remaining decremented")

	# Keep it
	var command_before_keep := state.command
	var burden_before_keep := state.burden
	state.keep_promise(log)
	check(state.active_promise.is_empty(), "Promise cleared after keeping")
	check(state.command == command_before_keep + 5, "Command +5 on promise kept")
	check(state.burden == burden_before_keep - 3, "Burden -3 on promise kept")
	check(state.has_memory_flag("promise_kept_landfall"), "Memory flag set for kept promise")


func _test_promise_lifecycle_break_on_expiry() -> void:
	print("-- Promise: make → auto-break on expiry --")
	var state := _make_state()
	var log := _make_log()
	state.make_promise("water", "No man will go without water", 2, log)

	state.tick_promise(log)
	check(state.active_promise.ticks_remaining == 1, "1 tick remaining")

	var command_before := state.command
	var burden_before := state.burden
	state.tick_promise(log)  # hits 0 → auto-break
	check(state.active_promise.is_empty(), "Promise auto-broken at expiry")
	check(state.command == command_before - 5, "Command -5 on broken promise")
	check(state.burden == burden_before + 5, "Burden +5 on broken promise")
	check(state.has_memory_flag("promise_broken_water"), "Memory flag set for broken promise")


func _test_promise_cannot_double() -> void:
	print("-- Promise: cannot make while one active --")
	var state := _make_state()
	var log := _make_log()
	state.make_promise("first", "First promise", 5, log)
	var result := state.make_promise("second", "Second promise", 3, log)
	check(result == false, "make_promise returns false when one active")
	check(state.active_promise.id == "first", "Original promise unchanged")
```

- [ ] **Step 3: Run the headless tests**

Run: `godot --headless --path game res://test/ExpeditionStateTest.tscn`
Expected: ALL PASS

- [ ] **Step 4: Also run Stage 1 tests to verify no regression**

Run: `godot --headless --path game res://test/ContentFrameworkTest.tscn`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add test/ExpeditionStateTest.tscn test/ExpeditionStateTest.gd
git commit -m "test(stage-2): add headless test suite for expedition state, effects, conditions, rum, promises"
```

---

## Task 8: Extend Debug Scene with Expedition Sim UI

**Files:**
- Modify: `test/ContentDebugScene.tscn`
- Modify: `test/ContentDebugScene.gd`

- [ ] **Step 1: Add Expedition Sim buttons to `test/ContentDebugScene.tscn`**

Add the following nodes to the Sidebar after the Objectives button. Insert them in the `.tscn` file as new `[node]` entries:

```
[node name="SimSeparator" type="HSeparator" parent="Sidebar"]
layout_mode = 2

[node name="SimLabel" type="Label" parent="Sidebar"]
layout_mode = 2
text = "Expedition Sim"

[node name="NewExpedition" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "New Expedition"

[node name="ShowState" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Show State"

[node name="ApplyEffect" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Apply Effect"

[node name="CheckCondition" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Check Condition"

[node name="Tick" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Tick"

[node name="MakePromise" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Make Promise"

[node name="KeepPromise" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Keep Promise"

[node name="BreakPromise" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Break Promise"

[node name="ToggleDamageTag" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Toggle Damage Tag"

[node name="SetMemoryFlag" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Set Memory Flag"

[node name="ToggleSpiritStore" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Toggle Spirit Store"

[node name="ShowLog" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Show Log"
```

- [ ] **Step 2: Update `test/ContentDebugScene.gd` with expedition sim logic**

Replace the full file:

```gdscript
# ContentDebugScene.gd
# Interactive debug scene for Dead Reckoning.
# Left sidebar: content family buttons + expedition sim controls.
# Right pane: scrollable output.
#
# Stage 1: Content catalog browsing and validation.
# Stage 2: Expedition state simulation.
extends HBoxContainer

@onready var _output: RichTextLabel = $OutputContainer/Output

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _effect_index: int = 0
var _condition_index: int = 0


func _ready() -> void:
	# Stage 1 — content catalog buttons
	$Sidebar/ValidateAll.pressed.connect(_on_validate_all_pressed)
	$Sidebar/Incidents.pressed.connect(_on_family_pressed.bind("incidents"))
	$Sidebar/Officers.pressed.connect(_on_family_pressed.bind("officers"))
	$Sidebar/Supplies.pressed.connect(_on_family_pressed.bind("supplies"))
	$Sidebar/StandingOrders.pressed.connect(_on_family_pressed.bind("standing_orders"))
	$Sidebar/Upgrades.pressed.connect(_on_family_pressed.bind("upgrades"))
	$Sidebar/Doctrines.pressed.connect(_on_family_pressed.bind("doctrines"))
	$Sidebar/CrewBackgrounds.pressed.connect(_on_family_pressed.bind("crew_backgrounds"))
	$Sidebar/ZoneTypes.pressed.connect(_on_family_pressed.bind("zone_types"))
	$Sidebar/Objectives.pressed.connect(_on_family_pressed.bind("objectives"))

	# Stage 2 — expedition sim buttons
	$Sidebar/NewExpedition.pressed.connect(_on_new_expedition)
	$Sidebar/ShowState.pressed.connect(_on_show_state)
	$Sidebar/ApplyEffect.pressed.connect(_on_apply_effect)
	$Sidebar/CheckCondition.pressed.connect(_on_check_condition)
	$Sidebar/Tick.pressed.connect(_on_tick)
	$Sidebar/MakePromise.pressed.connect(_on_make_promise)
	$Sidebar/KeepPromise.pressed.connect(_on_keep_promise)
	$Sidebar/BreakPromise.pressed.connect(_on_break_promise)
	$Sidebar/ToggleDamageTag.pressed.connect(_on_toggle_damage_tag)
	$Sidebar/SetMemoryFlag.pressed.connect(_on_set_memory_flag)
	$Sidebar/ToggleSpiritStore.pressed.connect(_on_toggle_spirit_store)
	$Sidebar/ShowLog.pressed.connect(_on_show_log)

	_show_validate_all()


# --- Stage 1: Content catalog ---

func _on_validate_all_pressed() -> void:
	_show_validate_all()


func _on_family_pressed(family: String) -> void:
	_show_family(family)


func _show_validate_all() -> void:
	_clear_output()
	_output.append_text("[b]Content Catalog — Validate All[/b]\n\n")
	for family: String in ContentRegistry.get_families():
		var items := ContentRegistry.get_all(family)
		_output.append_text("[b]%s[/b]: %d item(s)\n" % [family, items.size()])
	var errors := ContentRegistry.get_validation_errors()
	if errors.is_empty():
		_output.append_text("\n[color=green]PASS — no validation errors[/color]\n")
		_output.append_text("\nOverall: [color=green]VALID[/color]\n")
	else:
		_output.append_text("\n[color=red]FAIL — %d error(s):[/color]\n" % errors.size())
		for err: String in errors:
			_output.append_text("  • %s\n" % err)
		_output.append_text("\nOverall: [color=red]INVALID[/color]\n")


func _show_family(family: String) -> void:
	_clear_output()
	_output.append_text("[b]%s[/b]\n\n" % family)
	var items := ContentRegistry.get_all(family)
	if items.is_empty():
		_output.append_text("(no items loaded)\n")
		return
	for item: ContentBase in items:
		_output.append_text("• [b]%s[/b]  %s\n" % [item.id, item.display_name])
		if not item.category.is_empty():
			_output.append_text("  category: %s\n" % item.category)
		if not item.tags.is_empty():
			_output.append_text("  tags: %s\n" % ", ".join(item.tags))
		_output.append_text("\n")


# --- Stage 2: Expedition sim ---

func _ensure_expedition() -> bool:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active. Press 'New Expedition' first.[/color]\n")
		return false
	return true


func _on_new_expedition() -> void:
	_state = ExpeditionState.create_default()
	_log = SimulationLog.new()
	_effect_index = 0
	_condition_index = 0
	_clear_output()
	_output.append_text("[b]New Expedition Created[/b]\n\n")
	_show_state_summary()


func _on_show_state() -> void:
	if not _ensure_expedition():
		return
	_clear_output()
	_output.append_text("[b]Expedition State[/b]\n\n")
	_show_state_summary()


func _on_apply_effect() -> void:
	if not _ensure_expedition():
		return

	var effects: Array[Dictionary] = [
		{"type": "burden_change", "delta": 10, "label": "Burden +10"},
		{"type": "command_change", "delta": -5, "label": "Command -5"},
		{"type": "supply_change", "delta": -3, "target_id": "food", "label": "Food -3"},
		{"type": "add_damage_tag", "tag": "hull_strained", "label": "Add hull_strained"},
		{"type": "set_memory_flag", "flag_key": "test_flag", "label": "Set test_flag"},
		{"type": "ship_condition_change", "delta": -10, "label": "Ship condition -10"},
	]

	var def := effects[_effect_index % effects.size()]
	_effect_index += 1

	var e := EffectDef.new()
	e.type = def.type
	e.delta = def.get("delta", 0)
	e.target_id = def.get("target_id", "")
	e.flag_key = def.get("flag_key", "")
	e.tag = def.get("tag", "")

	EffectProcessor.apply(_state, e, _log)

	_clear_output()
	_output.append_text("[b]Applied Effect: %s[/b]\n\n" % def.label)
	_show_last_log_entry()
	_output.append_text("\n")
	_show_state_summary()


func _on_check_condition() -> void:
	if not _ensure_expedition():
		return

	var conditions: Array[Dictionary] = [
		{"type": "burden_above", "threshold": 50, "label": "Burden >= 50?"},
		{"type": "command_below", "threshold": 50, "label": "Command <= 50?"},
		{"type": "supply_below", "threshold": 10, "target_id": "food", "label": "Food <= 10?"},
		{"type": "has_damage_tag", "tag": "hull_strained", "label": "Has hull_strained?"},
		{"type": "has_memory_flag", "flag_key": "test_flag", "label": "Has test_flag?"},
		{"type": "officer_present", "target_id": "bosun", "label": "Bosun present?"},
	]

	var def := conditions[_condition_index % conditions.size()]
	_condition_index += 1

	var c := ConditionDef.new()
	c.type = def.type
	c.threshold = def.get("threshold", 0)
	c.target_id = def.get("target_id", "")
	c.flag_key = def.get("flag_key", "")
	c.tag = def.get("tag", "")

	var result := ConditionEvaluator.evaluate(_state, c, _log)

	_clear_output()
	_output.append_text("[b]Check Condition: %s[/b]\n\n" % def.label)
	if result:
		_output.append_text("[color=green]PASS[/color]\n\n")
	else:
		_output.append_text("[color=red]FAIL[/color]\n\n")
	_show_last_log_entry()


func _on_tick() -> void:
	if not _ensure_expedition():
		return
	_state.tick_count += 1
	RumRules.update_on_tick(_state, _log)
	_state.tick_promise(_log)
	_clear_output()
	_output.append_text("[b]Tick %d[/b]\n\n" % _state.tick_count)
	_show_state_summary()


func _on_make_promise() -> void:
	if not _ensure_expedition():
		return
	var result := _state.make_promise("landfall", "We will make landfall within five days", 5, _log)
	_clear_output()
	if result:
		_output.append_text("[b]Promise Made[/b]\n\n")
	else:
		_output.append_text("[color=yellow]Cannot make promise — one already active.[/color]\n\n")
	_show_state_summary()


func _on_keep_promise() -> void:
	if not _ensure_expedition():
		return
	if _state.active_promise.is_empty():
		_clear_output()
		_output.append_text("[color=yellow]No active promise to keep.[/color]\n")
		return
	_state.keep_promise(_log)
	_clear_output()
	_output.append_text("[b]Promise Kept[/b]\n\n")
	_show_state_summary()


func _on_break_promise() -> void:
	if not _ensure_expedition():
		return
	if _state.active_promise.is_empty():
		_clear_output()
		_output.append_text("[color=yellow]No active promise to break.[/color]\n")
		return
	_state.break_promise(_log)
	_clear_output()
	_output.append_text("[b]Promise Broken[/b]\n\n")
	_show_state_summary()


func _on_toggle_damage_tag() -> void:
	if not _ensure_expedition():
		return
	if _state.has_damage_tag("hull_strained"):
		_state.remove_damage_tag("hull_strained")
		_clear_output()
		_output.append_text("[b]Removed damage tag: hull_strained[/b]\n\n")
	else:
		_state.add_damage_tag("hull_strained")
		_clear_output()
		_output.append_text("[b]Added damage tag: hull_strained[/b]\n\n")
	_show_state_summary()


func _on_set_memory_flag() -> void:
	if not _ensure_expedition():
		return
	_state.add_memory_flag("test_event_occurred")
	_clear_output()
	_output.append_text("[b]Set memory flag: test_event_occurred[/b]\n\n")
	_show_state_summary()


func _on_toggle_spirit_store() -> void:
	if not _ensure_expedition():
		return
	_state.spirit_store_locked = not _state.spirit_store_locked
	_clear_output()
	var status := "LOCKED" if _state.spirit_store_locked else "UNLOCKED"
	_output.append_text("[b]Spirit Store: %s[/b]\n\n" % status)
	_show_state_summary()


func _on_show_log() -> void:
	if not _ensure_expedition():
		return
	_clear_output()
	_output.append_text("[b]Simulation Log[/b]\n\n")
	var entries := _log.get_entries()
	if entries.is_empty():
		_output.append_text("(no entries)\n")
		return
	# Reverse chronological
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		_output.append_text("[b]Tick %d[/b] [%s] %s\n" % [e.tick, e.source, e.message])


# --- Display helpers ---

func _clear_output() -> void:
	_output.clear()
	$OutputContainer.scroll_vertical = 0


func _show_state_summary() -> void:
	_output.append_text("[b]Burden:[/b] %d   [b]Command:[/b] %d   [b]Ship:[/b] %d   [b]Tick:[/b] %d\n\n" % [
		_state.burden, _state.command, _state.ship_condition, _state.tick_count])

	_output.append_text("[b]Supplies:[/b]\n")
	for supply_id: String in _state.supplies:
		_output.append_text("  %s: %d\n" % [supply_id, _state.supplies[supply_id]])

	if not _state.damage_tags.is_empty():
		_output.append_text("\n[b]Damage Tags:[/b] %s\n" % ", ".join(_state.damage_tags))

	if not _state.crew_traits.is_empty():
		_output.append_text("\n[b]Crew Traits:[/b] %s\n" % ", ".join(_state.crew_traits))

	_output.append_text("\n[b]Officers:[/b] %s\n" % ", ".join(_state.officers))

	if not _state.active_promise.is_empty():
		_output.append_text("\n[b]Promise:[/b] %s (%d ticks remaining)\n" % [
			_state.active_promise.text, _state.active_promise.ticks_remaining])
	else:
		_output.append_text("\n[b]Promise:[/b] (none)\n")

	if not _state.memory_flags.is_empty():
		_output.append_text("\n[b]Memory Flags:[/b] %s\n" % ", ".join(_state.memory_flags))

	_output.append_text("\n[b]Rum State:[/b] ration_expected=%s  store_locked=%s  theft_risk=%d  drunkenness_risk=%d\n" % [
		str(_state.rum_ration_expected), str(_state.spirit_store_locked),
		_state.rum_theft_risk, _state.rum_drunkenness_risk])

	_output.append_text("\n[b]Leadership:[/b] ")
	var tags: Array[String] = []
	for key: String in _state.leadership_tags:
		if _state.leadership_tags[key] != 0:
			tags.append("%s=%d" % [key, _state.leadership_tags[key]])
	if tags.is_empty():
		_output.append_text("(all neutral)\n")
	else:
		_output.append_text("%s\n" % ", ".join(tags))

	_output.append_text("\n[b]Stress:[/b] peak_burden=%d  min_command=%d  crew_losses=%d  supply_depletions=%d\n" % [
		_state.stress_indicators.peak_burden, _state.stress_indicators.min_command,
		_state.stress_indicators.crew_losses, _state.stress_indicators.supply_depletions])


func _show_last_log_entry() -> void:
	var entries := _log.get_entries()
	if entries.is_empty():
		return
	var e: Dictionary = entries[entries.size() - 1]
	_output.append_text("[b]Log:[/b] [%s] %s\n" % [e.source, e.message])
```

- [ ] **Step 3: Verify the debug scene loads**

Run: `godot --headless --path game --quit` (loads the main scene, which is ContentDebugScene)
Expected: Exits cleanly with no errors about missing nodes.

- [ ] **Step 4: Run both test suites**

Run: `godot --headless --path game res://test/ContentFrameworkTest.tscn`
Run: `godot --headless --path game res://test/ExpeditionStateTest.tscn`
Expected: Both ALL PASS

- [ ] **Step 5: Commit**

```bash
git add test/ContentDebugScene.tscn test/ContentDebugScene.gd
git commit -m "feat(stage-2): extend debug scene with expedition sim UI"
```

---

## Summary

| Task | What | Commit Message |
|---|---|---|
| 1 | Add `target_id` to EffectDef/ConditionDef | `feat(stage-2): add target_id field to EffectDef and ConditionDef` |
| 2 | Create SimulationLog | `feat(stage-2): add SimulationLog for expedition state explanation tracking` |
| 3 | Create ExpeditionState | `feat(stage-2): add ExpeditionState with factory, accessors, and promise system` |
| 4 | Create EffectProcessor | `feat(stage-2): add EffectProcessor for content-driven state changes` |
| 5 | Create ConditionEvaluator | `feat(stage-2): add ConditionEvaluator for content-driven state checks` |
| 6 | Create RumRules | `feat(stage-2): add RumRules for Rum special-case tick logic` |
| 7 | Create headless test suite | `test(stage-2): add headless test suite for expedition state, effects, conditions, rum, promises` |
| 8 | Extend debug scene | `feat(stage-2): extend debug scene with expedition sim UI` |
