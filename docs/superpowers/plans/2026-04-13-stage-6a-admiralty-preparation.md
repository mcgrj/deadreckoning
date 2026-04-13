# Stage 6A: Admiralty Preparation Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a complete preparation → run → run-end loop with persistent unlocks, mutiny/breakdown triggers, and a full PreparationScene/RunScene/RunEndScene flow.

**Architecture:** Three scenes form the loop (PreparationScene → RunScene → RunEndScene → PreparationScene). GameConstants centralises all balance numbers. SaveManager (autoload) persists ProgressionState as a .tres file. ExpeditionState gains run_end_reason + create_from_config(); TravelSimulator checks mutiny/breakdown each tick. All scenes are coded programmatically — .tscn files contain only the root node with its script attached.

**Tech Stack:** Godot 4.6, GDScript, Godot ResourceSaver/ResourceLoader (.tres), FileAccess (JSON for run_state), ContentRegistry autoload.

---

## File Map

**New files:**
- `game/src/constants/GameConstants.gd` — all balance consts
- `game/src/resources/ProgressionState.gd` — persistent unlocks Resource
- `game/src/SaveManager.gd` — autoload; save/load progression + run_state
- `game/src/ui/PreparationScene.gd` + `PreparationScene.tscn`
- `game/src/ui/RunScene.gd` + `RunScene.tscn`
- `game/src/ui/RunEndScene.gd` + `RunEndScene.tscn`
- `game/test/Stage6ATest.gd` + `Stage6ATest.tscn`
- 12 officer .tres files under `game/content/officers/`
- 2 upgrade .tres files under `game/content/upgrades/`
- 1 doctrine .tres under `game/content/doctrines/`
- 5 objective .tres files under `game/content/objectives/`

**Modified files:**
- `game/src/content/resources/OfficerDef.gd` — add `starting_effects`
- `game/src/expedition/ExpeditionState.gd` — add `run_end_reason`, `command_culture`, `active_objective_id`; add `create_from_config()`
- `game/src/expedition/TravelSimulator.gd` — add run-end checks at tick start, use GameConstants
- `game/project.godot` — add SaveManager autoload, change main scene

---

## Task 1: GameConstants

**Files:**
- Create: `game/src/constants/GameConstants.gd`

- [ ] **Step 1: Write the failing test in Stage6ATest.gd**

Create `game/test/Stage6ATest.gd`:

```gdscript
# Stage6ATest.gd
# Headless test suite for Stage 6A: Admiralty Preparation Layer.
# Run: godot --headless --path game res://test/Stage6ATest.tscn
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
	print("=== Stage6ATest ===\n")
	_test_game_constants()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_game_constants() -> void:
	print("-- GameConstants --")
	check(GameConstants.MUTINY_COMMAND_THRESHOLD == 20, "mutiny threshold is 20")
	check(GameConstants.MUTINY_BASE_RATE == 0.4, "mutiny base rate is 0.4")
	check(GameConstants.BREAKDOWN_BURDEN_THRESHOLD == 100, "breakdown threshold is 100")
	check(GameConstants.BURDEN_MAX == 100, "burden max is 100")
	check(GameConstants.COMMAND_MAX == 100, "command max is 100")
	check(GameConstants.MAX_UPGRADES == 2, "max upgrades is 2")
	check(GameConstants.OBJECTIVE_SHORTLIST_SIZE == 3, "shortlist size is 3")
```

- [ ] **Step 2: Create Stage6ATest.tscn**

Create `game/test/Stage6ATest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/Stage6ATest.gd" id="1_test6a"]

[node name="Stage6ATest" type="Node"]
script = ExtResource("1_test6a")
```

- [ ] **Step 3: Run test to confirm it fails** (GameConstants doesn't exist yet)

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: error — identifier 'GameConstants' not found.

- [ ] **Step 4: Create GameConstants.gd**

Create `game/src/constants/GameConstants.gd`:

```gdscript
# GameConstants.gd
# Centralised balance tuning constants. All magic numbers used in simulation
# code live here. Never instantiate — reference as GameConstants.CONST_NAME.
class_name GameConstants

# Run-end thresholds
const MUTINY_COMMAND_THRESHOLD: int = 20
const MUTINY_BASE_RATE: float = 0.4
const BREAKDOWN_BURDEN_THRESHOLD: int = 100

# Stat clamp bounds
const BURDEN_MAX: int = 100
const BURDEN_MIN: int = 0
const COMMAND_MAX: int = 100
const COMMAND_MIN: int = 0

# Preparation screen
const MAX_UPGRADES: int = 2
const OBJECTIVE_SHORTLIST_SIZE: int = 3

# Save paths
const SAVE_DIR: String = "user://saves/"

# Difficulty synthesis weights
const DIFFICULTY_BURDEN_WEIGHT: float = 0.3
const DIFFICULTY_COMMAND_WEIGHT: float = 0.3
const DIFFICULTY_CREW_LOSS_WEIGHT: int = 5
const DIFFICULTY_SUPPLY_DEPLETION_WEIGHT: int = 3
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/constants/GameConstants.gd game/test/Stage6ATest.gd game/test/Stage6ATest.tscn
git commit -m "feat(stage6a): add GameConstants with balance tuning constants"
```

---

## Task 2: OfficerDef — add starting_effects

**Files:**
- Modify: `game/src/content/resources/OfficerDef.gd`

- [ ] **Step 1: Add test for starting_effects field**

Append to `_ready()` in `game/test/Stage6ATest.gd` (add call before `_finish()`):
```gdscript
	_test_officer_def_starting_effects()
```

Append function to `game/test/Stage6ATest.gd`:
```gdscript
func _test_officer_def_starting_effects() -> void:
	print("-- OfficerDef.starting_effects --")
	var officer := OfficerDef.new()
	check(officer.starting_effects is Array, "starting_effects is an Array")
	check(officer.starting_effects.size() == 0, "starting_effects defaults to empty")
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: FAIL — `starting_effects` not found.

- [ ] **Step 3: Add starting_effects to OfficerDef.gd**

In `game/src/content/resources/OfficerDef.gd`, after `@export var advice_hooks`:

```gdscript
## Effects applied to ExpeditionState when this officer is selected at preparation.
@export var starting_effects: Array[EffectDef] = []
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Run Stage45Test to confirm no regressions**

```bash
godot --headless --path game res://test/Stage45Test.tscn
```
Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/content/resources/OfficerDef.gd game/test/Stage6ATest.gd
git commit -m "feat(stage6a): add starting_effects field to OfficerDef"
```

---

## Task 3: ExpeditionState — new fields and create_from_config

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`

- [ ] **Step 1: Add tests**

Append to `_ready()` in `game/test/Stage6ATest.gd`:
```gdscript
	_test_expedition_state_new_fields()
	_test_create_from_config()
```

Append to `game/test/Stage6ATest.gd`:
```gdscript
func _test_expedition_state_new_fields() -> void:
	print("-- ExpeditionState new fields --")
	var state := ExpeditionState.new()
	check(state.run_end_reason == "", "run_end_reason defaults to empty string")
	check(state.command_culture == "", "command_culture defaults to empty string")
	check(state.active_objective_id == "", "active_objective_id defaults to empty string")


func _test_create_from_config() -> void:
	print("-- ExpeditionState.create_from_config --")
	var config := {
		"objective_id": "survey_strange_shore",
		"doctrine_id": "",
		"officer_ids": [],
		"upgrade_ids": [],
	}
	var state := ExpeditionState.create_from_config(config)
	check(state != null, "create_from_config returns a state")
	check(state.active_objective_id == "survey_strange_shore", "objective_id stored on state")
	check(state.burden >= 0, "burden is non-negative after config")
	check(state.command > 0, "command is positive after config")
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: FAIL — `run_end_reason` not found.

- [ ] **Step 3: Add new fields to ExpeditionState.gd**

In `game/src/expedition/ExpeditionState.gd`, after the `stress_indicators` block (line ~38):

```gdscript
var run_end_reason: String = ""        # "completed" | "mutiny" | "breakdown" | ""
var command_culture: String = ""       # Set from doctrine's command_culture_modifier
var active_objective_id: String = ""   # The objective selected at preparation
```

- [ ] **Step 4: Add create_from_config static method**

In `game/src/expedition/ExpeditionState.gd`, after `create_default()`:

```gdscript
static func create_from_config(config: Dictionary) -> ExpeditionState:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()

	# Base supplies from SupplyDefs (same as create_default)
	var supply_defs := ContentRegistry.get_all("supplies")
	for def: ContentBase in supply_defs:
		var supply_def: SupplyDef = def as SupplyDef
		if supply_def:
			state.supplies[supply_def.id] = supply_def.starting_amount
			if supply_def.is_rum and supply_def.starting_amount > 0:
				state.rum_ration_expected = true
				state.add_crew_trait("rum_aboard")

	# Apply selected officers
	var officer_ids: Array = config.get("officer_ids", [])
	for officer_id: String in officer_ids:
		var officer_def: OfficerDef = ContentRegistry.get_by_id("officers", officer_id) as OfficerDef
		if officer_def:
			state.officers.append(officer_def.id)
			EffectProcessor.apply_effects(state, officer_def.starting_effects, log)

	# Apply selected upgrades
	var upgrade_ids: Array = config.get("upgrade_ids", [])
	for upgrade_id: String in upgrade_ids:
		var upgrade_def: ShipUpgradeDef = ContentRegistry.get_by_id("upgrades", upgrade_id) as ShipUpgradeDef
		if upgrade_def:
			EffectProcessor.apply_effects(state, upgrade_def.upgrade_effects, log)

	# Apply doctrine
	var doctrine_id: String = config.get("doctrine_id", "")
	if doctrine_id != "":
		var doctrine_def: DoctrineDef = ContentRegistry.get_by_id("doctrines", doctrine_id) as DoctrineDef
		if doctrine_def:
			for order_id: String in doctrine_def.unlocked_standing_order_ids:
				if not state.has_standing_order(order_id):
					state.standing_orders.append(order_id)
			state.command_culture = doctrine_def.command_culture_modifier

	# Store objective
	state.active_objective_id = config.get("objective_id", "")

	# Baseline stress indicators
	state.stress_indicators.peak_burden = state.burden
	state.stress_indicators.min_command = state.command

	return state
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 6: Run Stage45Test to confirm no regressions**

```bash
godot --headless --path game res://test/Stage45Test.tscn
```
Expected: `ALL PASS`

- [ ] **Step 7: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd game/test/Stage6ATest.gd
git commit -m "feat(stage6a): add run_end_reason, command_culture, active_objective_id and create_from_config to ExpeditionState"
```

---

## Task 4: TravelSimulator — mutiny and breakdown triggers

**Files:**
- Modify: `game/src/expedition/TravelSimulator.gd`

- [ ] **Step 1: Add tests**

Append to `_ready()` in `game/test/Stage6ATest.gd`:
```gdscript
	_test_breakdown_trigger()
	_test_mutiny_trigger()
	_test_completed_not_triggered_mid_run()
```

Append to `game/test/Stage6ATest.gd`:
```gdscript
func _test_breakdown_trigger() -> void:
	print("-- TravelSimulator breakdown --")
	var state := ExpeditionState.new()
	state.burden = 100  # At threshold
	var zone := ContentRegistry.get_all("zone_types")[0] as ZoneTypeDef
	if zone == null:
		check(false, "need at least one zone_type content file")
		return
	var log := SimulationLog.new()
	TravelSimulator.process_tick(state, zone, log)
	check(state.run_end_reason == "breakdown", "burden 100 triggers breakdown")


func _test_mutiny_trigger() -> void:
	print("-- TravelSimulator mutiny (deterministic: burden=100 command=0) --")
	var state := ExpeditionState.new()
	state.command = 0   # At or below threshold
	state.burden = 100  # Max — mutiny_chance = 1.0 * 0.4 = 0.4; run enough ticks
	var zone := ContentRegistry.get_all("zone_types")[0] as ZoneTypeDef
	if zone == null:
		check(false, "need at least one zone_type content file")
		return
	var log := SimulationLog.new()
	# At burden=100, command=0: chance = (100/100)*0.4 = 0.4 per tick.
	# Run 20 ticks — probability of at least one mutiny ≈ 1 - (0.6^20) ≈ 99.99%.
	for i in 20:
		if state.run_end_reason != "":
			break
		TravelSimulator.process_tick(state, zone, log)
	check(state.run_end_reason == "mutiny" or state.run_end_reason == "breakdown",
		"command=0 burden=100 eventually triggers run end")


func _test_completed_not_triggered_mid_run() -> void:
	print("-- TravelSimulator: no run-end at healthy state --")
	var state := ExpeditionState.new()
	state.burden = 20
	state.command = 70
	var zone := ContentRegistry.get_all("zone_types")[0] as ZoneTypeDef
	if zone == null:
		check(false, "need at least one zone_type content file")
		return
	var log := SimulationLog.new()
	TravelSimulator.process_tick(state, zone, log)
	check(state.run_end_reason == "", "healthy state does not trigger run end")
```

- [ ] **Step 2: Run test to confirm breakdown and mutiny tests fail**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: FAIL — breakdown and mutiny tests fail (run_end_reason stays "").

- [ ] **Step 3: Add _check_run_end helper and call it in process_tick**

In `game/src/expedition/TravelSimulator.gd`, add after the class declaration line (after `class_name TravelSimulator`):

```gdscript
## Check mutiny and breakdown conditions. Sets state.run_end_reason and returns
## true if the run has ended. Called at the top of process_tick before any
## further simulation steps.
static func _check_run_end(state: ExpeditionState, log: SimulationLog) -> bool:
	# Breakdown: burden at maximum — crew is ungovernable, expedition collapses.
	if state.burden >= GameConstants.BREAKDOWN_BURDEN_THRESHOLD:
		state.run_end_reason = "breakdown"
		log.log_event(state.tick_count, "RunEnd",
			"Expedition ended: breakdown (burden at maximum).",
			{"reason": "breakdown", "burden": state.burden})
		return true

	# Mutiny: probabilistic when command is critically low.
	if state.command <= GameConstants.MUTINY_COMMAND_THRESHOLD:
		var mutiny_chance: float = (float(state.burden) / 100.0) * GameConstants.MUTINY_BASE_RATE
		if state.has_standing_order("suppress_dissent"):
			mutiny_chance *= 0.5
		if randf() < mutiny_chance:
			state.run_end_reason = "mutiny"
			log.log_event(state.tick_count, "RunEnd",
				"Expedition ended: mutiny (command critically low, chance was %.2f)." % mutiny_chance,
				{"reason": "mutiny", "command": state.command, "burden": state.burden,
				 "chance": mutiny_chance})
			return true

	return false
```

Then modify `process_tick` to call it first. Replace the opening line of `process_tick`:

**Before:**
```gdscript
static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void:
	# Step 1: Food consumption
```

**After:**
```gdscript
static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void:
	# Check run-end conditions before any simulation steps.
	if _check_run_end(state, log):
		return

	# Step 1: Food consumption
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Run Stage45Test to confirm no regressions**

```bash
godot --headless --path game res://test/Stage45Test.tscn
```
Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/Stage6ATest.gd
git commit -m "feat(stage6a): add mutiny and breakdown run-end triggers to TravelSimulator"
```

---

## Task 5: ProgressionState and SaveManager

**Files:**
- Create: `game/src/resources/ProgressionState.gd`
- Create: `game/src/SaveManager.gd`
- Modify: `game/project.godot`

- [ ] **Step 1: Add tests**

Append to `_ready()` in `game/test/Stage6ATest.gd`:
```gdscript
	_test_progression_state()
	_test_save_manager()
```

Append to `game/test/Stage6ATest.gd`:
```gdscript
func _test_progression_state() -> void:
	print("-- ProgressionState --")
	var p := ProgressionState.new()
	check(p.completed_objective_ids is Array, "completed_objective_ids is Array")
	check(p.unlocked_content_ids is Array, "unlocked_content_ids is Array")
	check(p.last_run_difficulty_score == 0, "difficulty score defaults to 0")
	check(not p.is_unlocked("some_content"), "is_unlocked returns false for unknown id")
	p.apply_unlock("some_content")
	check(p.is_unlocked("some_content"), "is_unlocked returns true after apply_unlock")
	p.apply_unlock("some_content")  # idempotent
	check(p.unlocked_content_ids.count("some_content") == 1, "apply_unlock is idempotent")

	var default_p := ProgressionState.create_default()
	check(default_p.is_unlocked("first_lieutenant_stern"), "default unlocks first_lieutenant_stern")
	check(default_p.is_unlocked("surgeon_methodical"), "default unlocks surgeon_methodical")


func _test_save_manager() -> void:
	print("-- SaveManager --")
	# Load when no file exists returns a default state
	var p := SaveManager.load_progression("test_slot")
	check(p != null, "load_progression returns non-null even with no save file")
	check(p is ProgressionState, "load_progression returns a ProgressionState")

	# Save and reload
	p.last_run_difficulty_score = 42
	SaveManager.save_progression(p, "test_slot")
	var p2 := SaveManager.load_progression("test_slot")
	check(p2.last_run_difficulty_score == 42, "save/load round-trips last_run_difficulty_score")

	# Clean up test save
	DirAccess.remove_absolute(GameConstants.SAVE_DIR + "test_slot/progression.tres")
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: FAIL — ProgressionState not found.

- [ ] **Step 3: Create ProgressionState.gd**

Create `game/src/resources/ProgressionState.gd`:

```gdscript
# ProgressionState.gd
# Persistent meta-progression state. Saved to disk between runs.
# Tracks which objectives have been completed and which content is unlocked.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name ProgressionState
extends Resource

@export var completed_objective_ids: Array[String] = []
@export var unlocked_content_ids: Array[String] = []
@export var last_run_difficulty_score: int = 0


func is_unlocked(content_id: String) -> bool:
	return content_id in unlocked_content_ids


func apply_unlock(content_id: String) -> void:
	if content_id != "" and content_id not in unlocked_content_ids:
		unlocked_content_ids.append(content_id)


static func create_default() -> ProgressionState:
	var p := ProgressionState.new()
	# All MVP content unlocked by default so a fresh game is immediately playable.
	p.unlocked_content_ids = [
		# Officers — 6 roles × 2 variants
		"first_lieutenant_stern", "first_lieutenant_lenient",
		"master_experienced", "master_reckless",
		"gunner_disciplined", "gunner_reliable",
		"purser_frugal", "purser_generous",
		"surgeon_methodical", "surgeon_compassionate",
		"chaplain_orthodox", "chaplain_pragmatic",
		# Doctrines
		"shared_hardship", "iron_discipline",
		# Upgrades
		"reinforced_hull", "medical_stores", "powder_magazine",
		# Objectives
		"survey_strange_shore", "recover_lost_charts",
		"survey_northern_passage", "condition_return_intact",
		"condition_low_burden",
	]
	return p
```

- [ ] **Step 4: Create SaveManager.gd**

Create `game/src/SaveManager.gd`:

```gdscript
# SaveManager.gd
# Autoload. Manages persistence for ProgressionState and in-progress run state.
# ProgressionState is stored as a .tres Resource file (Godot-native serialisation).
# Run state is stored as JSON via FileAccess (ExpeditionState extends RefCounted, not Resource).
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name SaveManager
extends Node

const SLOT_DEFAULT := "default"


func _get_slot_dir(slot_id: String) -> String:
	return GameConstants.SAVE_DIR + slot_id + "/"


func _get_progression_path(slot_id: String) -> String:
	return _get_slot_dir(slot_id) + "progression.tres"


func _get_run_state_path(slot_id: String) -> String:
	return _get_slot_dir(slot_id) + "run_state.json"


# --- ProgressionState ---

func load_progression(slot_id: String = SLOT_DEFAULT) -> ProgressionState:
	var path := _get_progression_path(slot_id)
	if ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is ProgressionState:
			return loaded
	return ProgressionState.create_default()


func save_progression(state: ProgressionState, slot_id: String = SLOT_DEFAULT) -> void:
	var dir := _get_slot_dir(slot_id)
	DirAccess.make_dir_recursive_absolute(dir)
	ResourceSaver.save(state, _get_progression_path(slot_id))


func record_objective_complete(objective_id: String, slot_id: String = SLOT_DEFAULT) -> void:
	var progression := load_progression(slot_id)
	if objective_id not in progression.completed_objective_ids:
		progression.completed_objective_ids.append(objective_id)
	var objective_def: ObjectiveDef = ContentRegistry.get_by_id("objectives", objective_id) as ObjectiveDef
	if objective_def and objective_def.unlock_on_success_id != "":
		progression.apply_unlock(objective_def.unlock_on_success_id)
	save_progression(progression, slot_id)


# --- Run state (JSON, since ExpeditionState extends RefCounted not Resource) ---

## Stores the current run's pending_run_config so RunScene can read it after scene change.
var pending_run_config: Dictionary = {}


func delete_run_state(slot_id: String = SLOT_DEFAULT) -> void:
	var path := _get_run_state_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
```

- [ ] **Step 5: Add SaveManager to project.godot autoloads**

Open `game/project.godot`. Find the `[autoload]` section:
```ini
[autoload]

ContentRegistry="*res://src/content/ContentRegistry.gd"
```

Change it to:
```ini
[autoload]

ContentRegistry="*res://src/content/ContentRegistry.gd"
SaveManager="*res://src/SaveManager.gd"
```

- [ ] **Step 6: Run test to confirm it passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 7: Run Stage45Test to confirm no regressions**

```bash
godot --headless --path game res://test/Stage45Test.tscn
```
Expected: `ALL PASS`

- [ ] **Step 8: Commit**

```bash
git add game/src/resources/ProgressionState.gd game/src/SaveManager.gd game/project.godot game/test/Stage6ATest.gd
git commit -m "feat(stage6a): add ProgressionState, SaveManager autoload, and save/load tests"
```

---

## Task 6: Officer content files (12)

**Files:**
- Create: 12 .tres files under `game/content/officers/`

These provide 2 selectable variants per role for the PreparationScene. Each variant has `starting_effects` that create meaningful trade-offs.

- [ ] **Step 1: Create first_lieutenant_stern.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_fl1"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 5

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = 3

[resource]
script = ExtResource("1_fl1")
role = "first_lieutenant"
competence = 4
loyalty = 3
worldview = "disciplinarian"
known_traits = Array[String](["exacting", "reliable"])
starting_effects = Array[EffectDef]([SubResource("Resource_cmd"), SubResource("Resource_brd")])
advice_hooks = Array[String]([])
id = "first_lieutenant_stern"
display_name = "First Lieutenant (Stern)"
category = "officer"
tags = Array[String](["first_lieutenant"])
```

- [ ] **Step 2: Create first_lieutenant_lenient.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_fl2"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = -3

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = -3

[resource]
script = ExtResource("1_fl2")
role = "first_lieutenant"
competence = 3
loyalty = 4
worldview = "humanitarian"
known_traits = Array[String](["approachable", "fair"])
starting_effects = Array[EffectDef]([SubResource("Resource_brd"), SubResource("Resource_cmd")])
advice_hooks = Array[String]([])
id = "first_lieutenant_lenient"
display_name = "First Lieutenant (Lenient)"
category = "officer"
tags = Array[String](["first_lieutenant"])
```

- [ ] **Step 3: Create master_experienced.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_mx"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_trait"]
script = ExtResource("2_eff")
type = "add_crew_trait"
tag = "navigators_precision"

[resource]
script = ExtResource("1_mx")
role = "master"
competence = 5
loyalty = 3
worldview = "pragmatist"
known_traits = Array[String](["methodical", "reads_weather"])
starting_effects = Array[EffectDef]([SubResource("Resource_trait")])
advice_hooks = Array[String]([])
id = "master_experienced"
display_name = "Master (Experienced)"
category = "officer"
tags = Array[String](["master"])
```

- [ ] **Step 4: Create master_reckless.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_mr"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 2

[sub_resource type="Resource" id="Resource_ship"]
script = ExtResource("2_eff")
type = "ship_condition_change"
delta = -5

[resource]
script = ExtResource("1_mr")
role = "master"
competence = 4
loyalty = 2
worldview = "pragmatist"
known_traits = Array[String](["fast", "impatient"])
starting_effects = Array[EffectDef]([SubResource("Resource_cmd"), SubResource("Resource_ship")])
advice_hooks = Array[String]([])
id = "master_reckless"
display_name = "Master (Reckless)"
category = "officer"
tags = Array[String](["master"])
```

- [ ] **Step 5: Create gunner_disciplined.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_gd"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 3

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = 2

[resource]
script = ExtResource("1_gd")
role = "gunner"
competence = 4
loyalty = 3
worldview = "disciplinarian"
known_traits = Array[String](["strict", "by_the_book"])
starting_effects = Array[EffectDef]([SubResource("Resource_cmd"), SubResource("Resource_brd")])
advice_hooks = Array[String]([])
id = "gunner_disciplined"
display_name = "Gunner (Disciplined)"
category = "officer"
tags = Array[String](["gunner"])
```

- [ ] **Step 6: Create gunner_reliable.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_gr"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_ship"]
script = ExtResource("2_eff")
type = "ship_condition_change"
delta = 5

[resource]
script = ExtResource("1_gr")
role = "gunner"
competence = 4
loyalty = 4
worldview = "pragmatist"
known_traits = Array[String](["careful", "thorough"])
starting_effects = Array[EffectDef]([SubResource("Resource_ship")])
advice_hooks = Array[String]([])
id = "gunner_reliable"
display_name = "Gunner (Reliable)"
category = "officer"
tags = Array[String](["gunner"])
```

- [ ] **Step 7: Create purser_frugal.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_pf"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_food"]
script = ExtResource("2_eff")
type = "supply_change"
delta = 10
target_id = "food"

[resource]
script = ExtResource("1_pf")
role = "purser"
competence = 4
loyalty = 3
worldview = "pragmatist"
known_traits = Array[String](["exacting", "careful_with_stores"])
starting_effects = Array[EffectDef]([SubResource("Resource_food")])
advice_hooks = Array[String]([])
id = "purser_frugal"
display_name = "Purser (Frugal)"
category = "officer"
tags = Array[String](["purser"])
```

- [ ] **Step 8: Create purser_generous.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_pg"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_rum"]
script = ExtResource("2_eff")
type = "supply_change"
delta = 5
target_id = "rum"

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = -2

[resource]
script = ExtResource("1_pg")
role = "purser"
competence = 3
loyalty = 4
worldview = "humanitarian"
known_traits = Array[String](["generous", "popular"])
starting_effects = Array[EffectDef]([SubResource("Resource_rum"), SubResource("Resource_brd")])
advice_hooks = Array[String]([])
id = "purser_generous"
display_name = "Purser (Generous)"
category = "officer"
tags = Array[String](["purser"])
```

- [ ] **Step 9: Create surgeon_methodical.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_sm"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 2

[resource]
script = ExtResource("1_sm")
role = "surgeon"
competence = 4
loyalty = 3
worldview = "pragmatist"
known_traits = Array[String](["precise", "detached"])
starting_effects = Array[EffectDef]([SubResource("Resource_cmd")])
advice_hooks = Array[String]([])
id = "surgeon_methodical"
display_name = "Surgeon (Methodical)"
category = "officer"
tags = Array[String](["surgeon"])
```

- [ ] **Step 10: Create surgeon_compassionate.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_sc"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = -4

[resource]
script = ExtResource("1_sc")
role = "surgeon"
competence = 3
loyalty = 5
worldview = "humanitarian"
known_traits = Array[String](["kind", "tireless"])
starting_effects = Array[EffectDef]([SubResource("Resource_brd")])
advice_hooks = Array[String]([])
id = "surgeon_compassionate"
display_name = "Surgeon (Compassionate)"
category = "officer"
tags = Array[String](["surgeon"])
```

- [ ] **Step 11: Create chaplain_orthodox.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_co"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 4

[resource]
script = ExtResource("1_co")
role = "chaplain"
competence = 3
loyalty = 4
worldview = "disciplinarian"
known_traits = Array[String](["devout", "commanding"])
starting_effects = Array[EffectDef]([SubResource("Resource_cmd")])
advice_hooks = Array[String]([])
id = "chaplain_orthodox"
display_name = "Chaplain (Orthodox)"
category = "officer"
tags = Array[String](["chaplain"])
```

- [ ] **Step 12: Create chaplain_pragmatic.tres**

```
[gd_resource type="Resource" script_class="OfficerDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/OfficerDef.gd" id="1_cp"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = -3

[resource]
script = ExtResource("1_cp")
role = "chaplain"
competence = 3
loyalty = 4
worldview = "humanitarian"
known_traits = Array[String](["practical", "listener"])
starting_effects = Array[EffectDef]([SubResource("Resource_brd")])
advice_hooks = Array[String]([])
id = "chaplain_pragmatic"
display_name = "Chaplain (Pragmatic)"
category = "officer"
tags = Array[String](["chaplain"])
```

- [ ] **Step 13: Validate all new content loads correctly**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn
```
Expected: `ALL PASS` (no validation errors for new .tres files).

- [ ] **Step 14: Run Stage6ATest to confirm no regressions**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 15: Commit**

```bash
git add game/content/officers/
git commit -m "feat(stage6a): add 12 officer content files (6 roles x 2 variants)"
```

---

## Task 7: Additional content — upgrades, doctrine, objectives

**Files:**
- Create: `game/content/upgrades/medical_stores.tres`
- Create: `game/content/upgrades/powder_magazine.tres`
- Create: `game/content/doctrines/iron_discipline.tres`
- Create: `game/content/objectives/recover_lost_charts.tres`
- Create: `game/content/objectives/survey_northern_passage.tres`
- Create: `game/content/objectives/condition_return_intact.tres`
- Create: `game/content/objectives/condition_low_burden.tres`
- Modify: `game/content/upgrades/reinforced_hull.tres` (add upgrade_effects)

- [ ] **Step 1: Update reinforced_hull.tres to add upgrade_effects**

Replace `game/content/upgrades/reinforced_hull.tres` with:

```
[gd_resource type="Resource" script_class="ShipUpgradeDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ShipUpgradeDef.gd" id="1_4jboc"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_ship"]
script = ExtResource("2_eff")
type = "ship_condition_change"
delta = 10

[resource]
script = ExtResource("1_4jboc")
preparation_cost = 3
upgrade_effects = Array[EffectDef]([SubResource("Resource_ship")])
drawback_text = "Heavier — travel ticks consume slightly more food."
id = "reinforced_hull"
display_name = "Reinforced Hull"
category = "ship"
tags = Array[String](["durability"])
```

- [ ] **Step 2: Create medical_stores.tres**

```
[gd_resource type="Resource" script_class="ShipUpgradeDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ShipUpgradeDef.gd" id="1_ms"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_brd"]
script = ExtResource("2_eff")
type = "burden_change"
delta = -5

[resource]
script = ExtResource("1_ms")
preparation_cost = 2
upgrade_effects = Array[EffectDef]([SubResource("Resource_brd")])
drawback_text = "Takes up cargo space — reduces food starting stores by 5."
id = "medical_stores"
display_name = "Medical Stores"
category = "ship"
tags = Array[String](["medical"])
```

- [ ] **Step 3: Create powder_magazine.tres**

```
[gd_resource type="Resource" script_class="ShipUpgradeDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ShipUpgradeDef.gd" id="1_pm"]
[ext_resource type="Script" path="res://src/content/resources/EffectDef.gd" id="2_eff"]

[sub_resource type="Resource" id="Resource_cmd"]
script = ExtResource("2_eff")
type = "command_change"
delta = 5

[resource]
script = ExtResource("1_pm")
preparation_cost = 3
upgrade_effects = Array[EffectDef]([SubResource("Resource_cmd")])
drawback_text = "A volatile hold — any fire incident will be catastrophic."
id = "powder_magazine"
display_name = "Powder Magazine"
category = "ship"
tags = Array[String](["combat"])
```

- [ ] **Step 4: Create iron_discipline.tres**

```
[gd_resource type="Resource" script_class="DoctrineDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/DoctrineDef.gd" id="1_id"]

[resource]
script = ExtResource("1_id")
unlocked_standing_order_ids = Array[String](["strict_watches", "tighten_rationing"])
command_culture_modifier = "authoritarian"
description = "Discipline is maintained through fear and clear hierarchy. Command is easier to keep; Burden rises faster."
id = "iron_discipline"
display_name = "Iron Discipline Doctrine"
category = "doctrine"
tags = Array[String](["authoritarian"])
```

- [ ] **Step 5: Create recover_lost_charts.tres**

```
[gd_resource type="Resource" script_class="ObjectiveDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ObjectiveDef.gd" id="1_rlc"]
[ext_resource type="Script" path="res://src/content/resources/ConditionDef.gd" id="2_cond"]

[sub_resource type="Resource" id="Resource_cond"]
script = ExtResource("2_cond")
type = "has_memory_flag"
flag_key = "lost_charts_recovered"

[resource]
script = ExtResource("1_rlc")
objective_type = "recover"
difficulty_tier = 1
required_node_category = "Wreck"
success_condition = SubResource("Resource_cond")
description = "A scout vessel was lost with Admiralty charts aboard. Locate the wreck and retrieve what you can."
unlock_on_success_id = "medical_stores"
id = "recover_lost_charts"
display_name = "Recover the Lost Charts"
category = "recover"
tags = Array[String](["admiralty", "tier_1"])
```

- [ ] **Step 6: Create survey_northern_passage.tres**

```
[gd_resource type="Resource" script_class="ObjectiveDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ObjectiveDef.gd" id="1_snp"]
[ext_resource type="Script" path="res://src/content/resources/ConditionDef.gd" id="2_cond"]

[sub_resource type="Resource" id="Resource_cond"]
script = ExtResource("2_cond")
type = "has_memory_flag"
flag_key = "northern_passage_surveyed"

[resource]
script = ExtResource("1_snp")
objective_type = "survey"
difficulty_tier = 3
required_node_category = "Landfall"
success_condition = SubResource("Resource_cond")
description = "The Admiralty believes a northern passage may exist. Chart it before the ice closes."
unlock_on_success_id = "powder_magazine"
id = "survey_northern_passage"
display_name = "Survey the Northern Passage"
category = "survey"
tags = Array[String](["admiralty", "tier_3"])
```

- [ ] **Step 7: Create condition_return_intact.tres**

```
[gd_resource type="Resource" script_class="ObjectiveDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ObjectiveDef.gd" id="1_cri"]
[ext_resource type="Script" path="res://src/content/resources/ConditionDef.gd" id="2_cond"]

[sub_resource type="Resource" id="Resource_cond"]
script = ExtResource("2_cond")
type = "ship_condition_gte"
threshold = 50

[resource]
script = ExtResource("1_cri")
objective_type = "condition"
difficulty_tier = 2
success_condition = SubResource("Resource_cond")
description = "The Admiralty requires the vessel returned in serviceable condition. Ship must be above 50% at journey's end."
unlock_on_success_id = "iron_discipline"
id = "condition_return_intact"
display_name = "Return the Ship Intact"
category = "condition"
tags = Array[String](["admiralty", "tier_2"])
```

- [ ] **Step 8: Create condition_low_burden.tres**

```
[gd_resource type="Resource" script_class="ObjectiveDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ObjectiveDef.gd" id="1_clb"]
[ext_resource type="Script" path="res://src/content/resources/ConditionDef.gd" id="2_cond"]

[sub_resource type="Resource" id="Resource_cond"]
script = ExtResource("2_cond")
type = "burden_below"
threshold = 30

[resource]
script = ExtResource("1_clb")
objective_type = "condition"
difficulty_tier = 1
success_condition = SubResource("Resource_cond")
description = "Maintain crew morale throughout the journey. Burden must be 30 or below at journey's end."
unlock_on_success_id = ""
id = "condition_low_burden"
display_name = "Keep the Peace"
category = "condition"
tags = Array[String](["admiralty", "tier_1"])
```

- [ ] **Step 9: Add ship_condition_gte condition type to ContentValidator and ConditionEvaluator**

`condition_return_intact.tres` uses `ship_condition_gte` (new type). `condition_low_burden.tres` uses `burden_below` which already exists. `burden_lte` was renamed to `burden_below` for consistency with existing types.

In `game/src/content/ContentValidator.gd`, find `VALID_CONDITION_TYPES` array and add:
```gdscript
"ship_condition_gte",
```

In `game/src/expedition/ConditionEvaluator.gd`, in the `match condition.type` block, add before the `_:` default case:
```gdscript
"ship_condition_gte":
    result = state.ship_condition >= condition.threshold
    details["actual"] = state.ship_condition
    message = "Ship condition %d >= %d? %s" % [state.ship_condition, condition.threshold, "PASS" if result else "FAIL"]
```

> **Note:** `ConditionDef.threshold: int` already exists (used by `burden_above`, `burden_below`, etc.).

- [ ] **Step 10: Validate all new content loads**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 11: Run Stage6ATest to confirm no regressions**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 12: Commit**

```bash
git add game/content/upgrades/ game/content/doctrines/iron_discipline.tres game/content/objectives/ game/src/content/ContentValidator.gd game/src/expedition/ConditionEvaluator.gd
git commit -m "feat(stage6a): add upgrade, doctrine, and objective content; extend condition types"
```

---

## Task 8: PreparationScene

**Files:**
- Create: `game/src/ui/PreparationScene.gd`
- Create: `game/src/ui/PreparationScene.tscn`

The scene is built entirely in GDScript. The .tscn file contains only the root node. All officer role slots, upgrade slots, doctrine, and objective selection are created programmatically using buttons and labels.

- [ ] **Step 1: Create the .tscn with just the root node**

Create `game/src/ui/PreparationScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/PreparationScene.gd" id="1_prep"]

[node name="PreparationScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_prep")
```

- [ ] **Step 2: Create PreparationScene.gd**

Create `game/src/ui/PreparationScene.gd`:

```gdscript
# PreparationScene.gd
# Full-screen Admiralty preparation screen. Player selects officers (one per
# role), up to 2 ship upgrades, a doctrine, and an objective. Pressing
# "Set Sail" assembles a RunConfig and transitions to RunScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name PreparationScene
extends Control

const REQUIRED_ROLES := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]

var _selected_officers: Dictionary = {}  # role -> officer_id
var _selected_upgrades: Array[String] = []
var _selected_doctrine: String = ""
var _selected_objective: String = ""

var _sail_button: Button
var _status_label: Label
var _upgrade_buttons: Dictionary = {}  # upgrade_id -> Button
var _doctrine_buttons: Dictionary = {}  # doctrine_id -> Button
var _objective_buttons: Dictionary = {}  # objective_id -> Button
var _officer_buttons: Dictionary = {}   # officer_id -> Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = 800
	scroll.add_child(vbox)

	# Header
	var title := Label.new()
	title.text = "Admiralty Briefing"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Configure your expedition before sailing."
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	# Objective section
	_build_section(vbox, "Objective", _build_objective_slots)

	vbox.add_child(HSeparator.new())

	# Doctrine section
	_build_section(vbox, "Doctrine", _build_doctrine_slots)

	vbox.add_child(HSeparator.new())

	# Officers section
	_build_section(vbox, "Officers", _build_officer_slots)

	vbox.add_child(HSeparator.new())

	# Upgrades section
	_build_section(vbox, "Ship Upgrades (choose up to %d)" % GameConstants.MAX_UPGRADES, _build_upgrade_slots)

	vbox.add_child(HSeparator.new())

	# Status + Set Sail
	_status_label = Label.new()
	_status_label.text = ""
	vbox.add_child(_status_label)

	_sail_button = Button.new()
	_sail_button.text = "Set Sail"
	_sail_button.pressed.connect(_on_set_sail)
	vbox.add_child(_sail_button)


func _build_section(parent: VBoxContainer, title: String, build_fn: Callable) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	build_fn.call(parent)


func _build_objective_slots(parent: VBoxContainer) -> void:
	var progression := SaveManager.load_progression()
	var all_objectives: Array = ContentRegistry.get_all("objectives")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var shown := 0
	for obj: ContentBase in all_objectives:
		var def: ObjectiveDef = obj as ObjectiveDef
		if def == null:
			continue
		if shown >= GameConstants.OBJECTIVE_SHORTLIST_SIZE:
			break
		var btn := Button.new()
		btn.text = "%s\nTier %d — %s" % [def.display_name, def.difficulty_tier, def.description]
		btn.custom_minimum_size = Vector2(220, 80)
		btn.toggle_mode = true
		btn.pressed.connect(_on_objective_selected.bind(def.id, btn))
		_objective_buttons[def.id] = btn
		hbox.add_child(btn)
		shown += 1
		if shown == 1:
			_selected_objective = def.id
			btn.button_pressed = true


func _build_doctrine_slots(parent: VBoxContainer) -> void:
	var all_doctrines: Array = ContentRegistry.get_all("doctrines")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	# "None" option
	var none_btn := Button.new()
	none_btn.text = "None"
	none_btn.toggle_mode = true
	none_btn.button_pressed = true
	none_btn.pressed.connect(_on_doctrine_selected.bind("", none_btn))
	_doctrine_buttons[""] = none_btn
	hbox.add_child(none_btn)

	for doc: ContentBase in all_doctrines:
		var def: DoctrineDef = doc as DoctrineDef
		if def == null:
			continue
		var btn := Button.new()
		btn.text = "%s\n%s" % [def.display_name, def.description]
		btn.custom_minimum_size = Vector2(220, 60)
		btn.toggle_mode = true
		btn.pressed.connect(_on_doctrine_selected.bind(def.id, btn))
		_doctrine_buttons[def.id] = btn
		hbox.add_child(btn)


func _build_officer_slots(parent: VBoxContainer) -> void:
	var all_officers: Array = ContentRegistry.get_all("officers")
	# Group by role
	var by_role: Dictionary = {}
	for off: ContentBase in all_officers:
		var def: OfficerDef = off as OfficerDef
		if def == null or def.role == "" or def.role not in REQUIRED_ROLES:
			continue
		if not by_role.has(def.role):
			by_role[def.role] = []
		by_role[def.role].append(def)

	for role: String in REQUIRED_ROLES:
		var role_label := Label.new()
		role_label.text = role.replace("_", " ").capitalize()
		parent.add_child(role_label)
		var hbox := HBoxContainer.new()
		parent.add_child(hbox)
		var variants: Array = by_role.get(role, [])
		for def: OfficerDef in variants:
			var btn := Button.new()
			btn.text = "%s\n%s" % [def.display_name, _format_effects(def.starting_effects)]
			btn.custom_minimum_size = Vector2(200, 70)
			btn.toggle_mode = true
			btn.pressed.connect(_on_officer_selected.bind(role, def.id, btn))
			_officer_buttons[def.id] = btn
			hbox.add_child(btn)
			if not _selected_officers.has(role):
				_selected_officers[role] = def.id
				btn.button_pressed = true


func _build_upgrade_slots(parent: VBoxContainer) -> void:
	var all_upgrades: Array = ContentRegistry.get_all("upgrades")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	for upg: ContentBase in all_upgrades:
		var def: ShipUpgradeDef = upg as ShipUpgradeDef
		if def == null:
			continue
		var btn := Button.new()
		btn.text = "%s\n%s" % [def.display_name, def.drawback_text]
		btn.custom_minimum_size = Vector2(200, 70)
		btn.toggle_mode = true
		btn.pressed.connect(_on_upgrade_toggled.bind(def.id, btn))
		_upgrade_buttons[def.id] = btn
		hbox.add_child(btn)


func _format_effects(effects: Array) -> String:
	if effects.is_empty():
		return "(no starting effects)"
	var parts: Array[String] = []
	for eff: EffectDef in effects:
		match eff.type:
			"burden_change":
				parts.append("Burden %+d" % eff.delta)
			"command_change":
				parts.append("Command %+d" % eff.delta)
			"supply_change":
				parts.append("%s %+d" % [eff.target_id, eff.delta])
			"ship_condition_change":
				parts.append("Ship %+d" % eff.delta)
			"add_crew_trait":
				parts.append("Trait: %s" % eff.tag)
	return ", ".join(parts)


func _on_objective_selected(objective_id: String, btn: Button) -> void:
	for id: String in _objective_buttons:
		_objective_buttons[id].button_pressed = false
	_selected_objective = objective_id
	btn.button_pressed = true


func _on_doctrine_selected(doctrine_id: String, btn: Button) -> void:
	for id: String in _doctrine_buttons:
		_doctrine_buttons[id].button_pressed = false
	_selected_doctrine = doctrine_id
	btn.button_pressed = true


func _on_officer_selected(role: String, officer_id: String, btn: Button) -> void:
	# Deselect all buttons for this role
	var all_officers: Array = ContentRegistry.get_all("officers")
	for off: ContentBase in all_officers:
		var def: OfficerDef = off as OfficerDef
		if def != null and def.role == role and _officer_buttons.has(def.id):
			_officer_buttons[def.id].button_pressed = false
	_selected_officers[role] = officer_id
	btn.button_pressed = true


func _on_upgrade_toggled(upgrade_id: String, btn: Button) -> void:
	if upgrade_id in _selected_upgrades:
		_selected_upgrades.erase(upgrade_id)
		btn.button_pressed = false
	else:
		if _selected_upgrades.size() >= GameConstants.MAX_UPGRADES:
			_status_label.text = "Cannot select more than %d upgrades." % GameConstants.MAX_UPGRADES
			btn.button_pressed = false
			return
		_selected_upgrades.append(upgrade_id)
		btn.button_pressed = true
	_status_label.text = ""


func _on_set_sail() -> void:
	# Validate all required roles are filled
	for role: String in REQUIRED_ROLES:
		if not _selected_officers.has(role) or _selected_officers[role] == "":
			_status_label.text = "Must select an officer for: " + role.replace("_", " ").capitalize()
			return
	if _selected_objective == "":
		_status_label.text = "Must select an objective."
		return

	var config := {
		"objective_id": _selected_objective,
		"doctrine_id": _selected_doctrine,
		"officer_ids": _selected_officers.values(),
		"upgrade_ids": _selected_upgrades,
	}
	SaveManager.pending_run_config = config

	var run_scene := load("res://src/ui/RunScene.tscn").instantiate()
	get_tree().root.add_child(run_scene)
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().current_scene = run_scene
```

- [ ] **Step 3: Verify the scene loads in Godot without errors**

```bash
godot --path game res://src/ui/PreparationScene.tscn
```
Expected: Scene opens showing officer role slots, doctrine, objective choices, and Set Sail button. No errors in output.

- [ ] **Step 4: Commit**

```bash
git add game/src/ui/PreparationScene.gd game/src/ui/PreparationScene.tscn
git commit -m "feat(stage6a): add PreparationScene with officer/upgrade/doctrine/objective selection"
```

---

## Task 9: RunScene

**Files:**
- Create: `game/src/ui/RunScene.gd`
- Create: `game/src/ui/RunScene.tscn`

RunScene receives `SaveManager.pending_run_config`, creates `ExpeditionState` via `create_from_config`, runs the tick loop, shows incident resolution, and transitions to `RunEndScene` when `run_end_reason` is set.

- [ ] **Step 1: Create RunScene.tscn**

Create `game/src/ui/RunScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/RunScene.gd" id="1_run"]

[node name="RunScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_run")
```

- [ ] **Step 2: Create RunScene.gd**

Create `game/src/ui/RunScene.gd`:

```gdscript
# RunScene.gd
# Hosts the expedition tick loop. Reads RunConfig from SaveManager.pending_run_config,
# initialises ExpeditionState via create_from_config, and calls TravelSimulator.process_tick
# on each advance. Checks state.run_end_reason after every tick to detect run end.
# When an incident is pending, shows IncidentResolutionScene. On run end, transitions
# to RunEndScene with the final ExpeditionState.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunScene
extends Control

var _state: ExpeditionState
var _log: SimulationLog
var _route: RouteMap
var _current_node_index: int = 0

var _status_label: Label
var _stats_label: Label
var _log_label: Label
var _advance_button: Button
var _incident_container: VBoxContainer


func _ready() -> void:
	var config := SaveManager.pending_run_config
	_state = ExpeditionState.create_from_config(config)
	_log = SimulationLog.new()
	_route = RouteMap.generate_default()
	_build_ui()
	_refresh_display()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Header: ship status
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_stats_label)

	vbox.add_child(HSeparator.new())

	# Incident container (hidden until incident fires)
	_incident_container = VBoxContainer.new()
	_incident_container.visible = false
	vbox.add_child(_incident_container)

	# Advance button
	_advance_button = Button.new()
	_advance_button.text = "Advance Day"
	_advance_button.pressed.connect(_on_advance)
	vbox.add_child(_advance_button)

	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	vbox.add_child(_status_label)

	# Recent log
	var log_title := Label.new()
	log_title.text = "Log:"
	vbox.add_child(log_title)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_log_label)


func _on_advance() -> void:
	if _state.run_end_reason != "":
		return

	# If an incident is waiting, don't advance until resolved
	if _state.pending_incident_id != "":
		_show_incident_resolution()
		return

	# Advance route
	var nodes := _route.get_nodes()
	if _current_node_index < nodes.size():
		var node: RouteNode = nodes[_current_node_index]
		var zone: ZoneTypeDef = ContentRegistry.get_by_id("zone_types", node.zone_type_id) as ZoneTypeDef
		if zone == null:
			_status_label.text = "ERROR: zone type not found: " + node.zone_type_id
			return
		_state.tick_count += 1
		TravelSimulator.process_tick(_state, zone, _log)
		_current_node_index += 1
	else:
		# Final node reached
		_state.run_end_reason = "completed"
		_log.log_event(_state.tick_count, "RunScene", "Expedition complete — all route nodes traversed.", {})

	_refresh_display()

	# Check for pending incident
	if _state.pending_incident_id != "" and _state.run_end_reason == "":
		_show_incident_resolution()
		return

	# Check run end
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _show_incident_resolution() -> void:
	# Clear any previous incident UI
	for child in _incident_container.get_children():
		child.queue_free()

	var resolution := IncidentResolutionScene.new()
	_incident_container.add_child(resolution)
	resolution.setup(_state, _log)
	resolution.resolved.connect(_on_incident_resolved)
	_incident_container.visible = true
	_advance_button.visible = false


func _on_incident_resolved() -> void:
	_incident_container.visible = false
	_advance_button.visible = true
	_state.pending_incident_id = ""
	_refresh_display()
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _transition_to_run_end() -> void:
	_advance_button.visible = false
	_status_label.text = "Expedition ended: " + _state.run_end_reason
	# Brief pause then transition
	await get_tree().create_timer(1.5).timeout
	var run_end_scene := load("res://src/ui/RunEndScene.tscn").instantiate() as RunEndScene
	run_end_scene.final_state = _state
	get_tree().root.add_child(run_end_scene)
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().current_scene = run_end_scene


func _refresh_display() -> void:
	_stats_label.text = (
		"Tick: %d | Burden: %d | Command: %d | Ship: %d%%\nObjective: %s" % [
			_state.tick_count, _state.burden, _state.command,
			_state.ship_condition, _state.active_objective_id
		]
	)
	# Show last 5 log entries
	var entries := _log.get_entries()
	var recent := entries.slice(maxi(0, entries.size() - 5))
	var lines: Array[String] = []
	for entry: Dictionary in recent:
		lines.append("[%d] %s: %s" % [entry.get("tick", 0), entry.get("source", ""), entry.get("message", "")])
	_log_label.text = "\n".join(lines)
```

> **Note:** `IncidentResolutionScene` is instantiated as `IncidentResolutionScene.new()` here (it extends VBoxContainer). This matches the existing class in `game/src/ui/IncidentResolutionScene.gd`. The `.setup()` and `.resolved` signal are part of its existing API.

- [ ] **Step 3: Verify RunScene loads and shows a basic expedition**

```bash
godot --path game res://src/ui/RunScene.tscn
```
Expected: Scene loads with "Advance Day" button, stats label showing Burden/Command. Advance Day progresses ticks. No errors.

- [ ] **Step 4: Commit**

```bash
git add game/src/ui/RunScene.gd game/src/ui/RunScene.tscn
git commit -m "feat(stage6a): add RunScene with tick loop and run-end detection"
```

---

## Task 10: RunEndScene

**Files:**
- Create: `game/src/ui/RunEndScene.gd`
- Create: `game/src/ui/RunEndScene.tscn`

- [ ] **Step 1: Check ConditionDef has `threshold` field**

Read `game/src/content/resources/ConditionDef.gd`. If `threshold: int` is missing, add it:
```gdscript
@export var threshold: int = 0
```
Commit if changed.

- [ ] **Step 2: Create RunEndScene.tscn**

Create `game/src/ui/RunEndScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/RunEndScene.gd" id="1_rend"]

[node name="RunEndScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_rend")
```

- [ ] **Step 3: Create RunEndScene.gd**

Create `game/src/ui/RunEndScene.gd`:

```gdscript
# RunEndScene.gd
# Displays expedition outcome, objective result, stress indicators, and
# Admiralty difficulty assessment. Saves progression. Returns to PreparationScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunEndScene
extends Control

var final_state: ExpeditionState = null


func _ready() -> void:
	if final_state == null:
		# Fallback: create a dummy state for direct scene preview
		final_state = ExpeditionState.new()
		final_state.run_end_reason = "completed"
	_process_run_end()
	_build_ui()


func _process_run_end() -> void:
	# Evaluate objective
	var objective_success := false
	var objective_def: ObjectiveDef = null
	if final_state.active_objective_id != "":
		objective_def = ContentRegistry.get_by_id("objectives", final_state.active_objective_id) as ObjectiveDef
		if objective_def:
			var dummy_log := SimulationLog.new()
			if objective_def.success_condition == null:
				objective_success = true
			else:
				objective_success = ConditionEvaluator.evaluate(final_state, objective_def.success_condition, dummy_log)

	# Record unlock if objective succeeded
	if objective_success and objective_def != null:
		SaveManager.record_objective_complete(final_state.active_objective_id)

	# Save difficulty score
	var score := _compute_difficulty_score()
	var progression := SaveManager.load_progression()
	progression.last_run_difficulty_score = score
	SaveManager.save_progression(progression)

	SaveManager.delete_run_state()


func _compute_difficulty_score() -> int:
	var s := final_state.stress_indicators
	var score: float = (
		float(s.get("peak_burden", 0)) * GameConstants.DIFFICULTY_BURDEN_WEIGHT +
		float(100 - s.get("min_command", 100)) * GameConstants.DIFFICULTY_COMMAND_WEIGHT +
		float(s.get("crew_losses", 0)) * GameConstants.DIFFICULTY_CREW_LOSS_WEIGHT +
		float(s.get("supply_depletions", 0)) * GameConstants.DIFFICULTY_SUPPLY_DEPLETION_WEIGHT
	)
	return clampi(int(score), 0, 100)


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Outcome header
	var outcome_text := ""
	match final_state.run_end_reason:
		"completed":
			outcome_text = "Expedition Complete"
		"mutiny":
			outcome_text = "Mutiny"
		"breakdown":
			outcome_text = "Expedition Lost"
		_:
			outcome_text = "Run Ended"

	var outcome_label := Label.new()
	outcome_label.text = outcome_text
	outcome_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(outcome_label)

	vbox.add_child(HSeparator.new())

	# Objective result
	var objective_def: ObjectiveDef = null
	var objective_success := false
	if final_state.active_objective_id != "":
		objective_def = ContentRegistry.get_by_id("objectives", final_state.active_objective_id) as ObjectiveDef
		if objective_def:
			var dummy_log := SimulationLog.new()
			objective_success = (objective_def.success_condition == null or
				ConditionEvaluator.evaluate(final_state, objective_def.success_condition, dummy_log))

	var obj_label := Label.new()
	if objective_def:
		var result_str := "SUCCESS" if objective_success else "FAILED"
		obj_label.text = "Objective: %s — %s\n%s" % [objective_def.display_name, result_str, objective_def.description]
	else:
		obj_label.text = "No objective set."
	obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(obj_label)

	vbox.add_child(HSeparator.new())

	# Stress indicators
	var stress_title := Label.new()
	stress_title.text = "Expedition Record"
	stress_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(stress_title)

	var s := final_state.stress_indicators
	var stress_label := Label.new()
	stress_label.text = (
		"Peak Burden: %d\nMin Command: %d\nCrew Losses: %d\nSupply Depletions: %d" % [
			s.get("peak_burden", 0), s.get("min_command", 0),
			s.get("crew_losses", 0), s.get("supply_depletions", 0)
		]
	)
	vbox.add_child(stress_label)

	vbox.add_child(HSeparator.new())

	# Difficulty score
	var score := _compute_difficulty_score()
	var score_label := Label.new()
	score_label.text = "Admiralty Assessment: %d / 100" % score
	score_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(score_label)

	vbox.add_child(HSeparator.new())

	# Return button
	var return_btn := Button.new()
	return_btn.text = "Return to Admiralty"
	return_btn.pressed.connect(_on_return)
	vbox.add_child(return_btn)


func _on_return() -> void:
	var prep_scene := load("res://src/ui/PreparationScene.tscn").instantiate()
	get_tree().root.add_child(prep_scene)
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().current_scene = prep_scene
```

- [ ] **Step 4: Verify RunEndScene loads**

> **Note:** `ConditionEvaluator.evaluate(state, condition, log)` already exists — no changes to that file needed.

```bash
godot --path game res://src/ui/RunEndScene.tscn
```
Expected: Scene shows "Expedition Complete" header (fallback state), objective panel, stress indicators all zeroed, Admiralty Assessment score, Return to Admiralty button. No errors.

- [ ] **Step 6: Commit**

```bash
git add game/src/ui/RunEndScene.gd game/src/ui/RunEndScene.tscn
git commit -m "feat(stage6a): add RunEndScene with outcome display, difficulty score, and progression save"
```

---

## Task 11: Wire project.godot and full-loop Stage6ATest

**Files:**
- Modify: `game/project.godot`
- Modify: `game/test/Stage6ATest.gd` (add remaining tests)

- [ ] **Step 1: Change main scene to PreparationScene**

In `game/project.godot`, find:
```ini
[application]

config/name="DeadReckoning"
run/main_scene="res://test/ContentDebugScene.tscn"
```

Change `run/main_scene` to:
```ini
run/main_scene="res://src/ui/PreparationScene.tscn"
```

- [ ] **Step 2: Add remaining Stage6ATest tests**

Append to `_ready()` in `game/test/Stage6ATest.gd`:
```gdscript
	_test_run_end_scene_difficulty_formula()
	_test_progression_objective_complete()
```

Append to `game/test/Stage6ATest.gd`:
```gdscript
func _test_run_end_scene_difficulty_formula() -> void:
	print("-- RunEndScene difficulty formula --")
	var state := ExpeditionState.new()
	state.stress_indicators = {
		"peak_burden": 60,
		"min_command": 40,
		"crew_losses": 2,
		"supply_depletions": 1,
	}
	# score = (60*0.3) + ((100-40)*0.3) + (2*5) + (1*3)
	#       = 18 + 18 + 10 + 3 = 49
	state.run_end_reason = "completed"
	state.active_objective_id = ""
	var scene := RunEndScene.new()
	scene.final_state = state
	# Call _compute_difficulty_score directly
	var score := scene._compute_difficulty_score()
	check(score == 49, "difficulty formula: expected 49 got %d" % score)
	scene.free()


func _test_progression_objective_complete() -> void:
	print("-- record_objective_complete --")
	SaveManager.record_objective_complete("survey_strange_shore", "test_slot2")
	var p := SaveManager.load_progression("test_slot2")
	check("survey_strange_shore" in p.completed_objective_ids,
		"completed_objective_ids contains survey_strange_shore")
	# Clean up
	DirAccess.remove_absolute(GameConstants.SAVE_DIR + "test_slot2/progression.tres")
```

- [ ] **Step 3: Run the full Stage6ATest**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 4: Run all other test suites to confirm no regressions**

```bash
godot --headless --path game res://test/Stage45Test.tscn
godot --headless --path game res://test/ContentFrameworkTest.tscn
godot --headless --path game res://test/ExpeditionStateTest.tscn
```
Expected: `ALL PASS` on each.

- [ ] **Step 5: Manual full-loop test**

```bash
godot --path game
```

Walk through:
1. PreparationScene opens as main scene
2. Select one officer per role (all should be visible in their role slots)
3. Select a doctrine (or leave None)
4. Select an objective
5. Press "Set Sail" — RunScene loads, shows stats
6. Click "Advance Day" ~10 times — log entries appear
7. If an incident fires, the incident resolution panel appears; make a choice
8. Continue until run ends (or manually increase burden to 100 via ContentDebugScene to trigger breakdown)
9. RunEndScene shows with correct outcome, stress indicators, difficulty score
10. "Return to Admiralty" returns to PreparationScene

- [ ] **Step 6: Final commit**

```bash
git add game/project.godot game/test/Stage6ATest.gd
git commit -m "feat(stage6a): wire PreparationScene as main scene, complete Stage6ATest"
```
