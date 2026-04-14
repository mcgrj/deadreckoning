# Stage 6B: Admiralty Reporting and Political Memory — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add end-of-run report framing, accumulated political memory, and visible Admiralty consequences in PreparationScene, completing the preparation → run → run-end → report → preparation loop.

**Architecture:** RunEndScene gains a factual account section (RichTextLabel with BBCode highlights) and a report framing step before "Return to Admiralty". ProgressionState gains two accumulating arrays (`admiralty_bias`, `scandal_flags`). PreparationScene reads bias on load to generate an Admiralty letter, grey unavailable options, highlight recommendations with rewards, and show a live allocation panel. Framing definitions are a static Dictionary in RunEndScene. Scandal flags are injected into `ExpeditionState.memory_flags` at run start via the run config so existing `has_memory_flag` conditions work without touching ConditionEvaluator.

**Tech Stack:** Godot 4.6, GDScript, RichTextLabel BBCode, ProgressionState Resource (.tres), SaveManager autoload, ContentRegistry autoload.

---

## File Map

**New files:**
- `game/test/Stage6BTest.gd` — headless test suite
- `game/test/Stage6BTest.tscn` — test scene

**Modified files:**
- `game/src/constants/GameConstants.gd` — add `RECOMMENDATION_SUPPLY_BONUS`, `RECOMMENDATION_COMMAND_BONUS`
- `game/src/resources/ProgressionState.gd` — add `admiralty_bias: Array[String]`, `scandal_flags: Array[String]`
- `game/src/SaveManager.gd` — add `record_report_framing(bias_string, scandal_flag, slot_id)`
- `game/src/ui/RunEndScene.gd` — add `FRAMING_OPTIONS` const, `_selected_framing`, `_get_available_framings()`, gate helpers, `_build_log_narrative_text()`, `_build_report_section()`, updated `_on_return()`
- `game/src/expedition/ExpeditionState.gd` — add `officer_starting_traits: Dictionary`; update `create_from_config()` to apply supply bonus, command bonus, officer traits, and seed scandal flags into memory_flags
- `game/src/ui/PreparationScene.gd` — add bias loading, `_compute_bias_effects()`, Admiralty letter, greyed/recommended rendering, allocation panel, updated `_on_set_sail()`

---

## Task 1: Test Skeleton and GameConstants

**Files:**
- Create: `game/test/Stage6BTest.gd`
- Create: `game/test/Stage6BTest.tscn`
- Modify: `game/src/constants/GameConstants.gd`

- [ ] **Step 1: Write the failing test**

Create `game/test/Stage6BTest.gd`:

```gdscript
# Stage6BTest.gd
# Headless test suite for Stage 6B: Admiralty Reporting and Political Memory.
# Run: godot --headless --path game res://test/Stage6BTest.tscn
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
	print("=== Stage6BTest ===\n")
	_test_game_constants()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_game_constants() -> void:
	print("-- GameConstants recommendation rewards --")
	check(GameConstants.RECOMMENDATION_SUPPLY_BONUS == 10, "supply bonus is 10")
	check(GameConstants.RECOMMENDATION_COMMAND_BONUS == 5, "command bonus is 5")
```

- [ ] **Step 2: Create Stage6BTest.tscn**

Create `game/test/Stage6BTest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/Stage6BTest.gd" id="1_test6b"]

[node name="Stage6BTest" type="Node"]
script = ExtResource("1_test6b")
```

- [ ] **Step 3: Run test — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -20
```

Expected: FAIL — `RECOMMENDATION_SUPPLY_BONUS` not defined.

- [ ] **Step 4: Add constants to GameConstants.gd**

Add after the `DIFFICULTY_SUPPLY_DEPLETION_WEIGHT` line:

```gdscript
# Admiralty recommendation rewards
const RECOMMENDATION_SUPPLY_BONUS: int = 10   # Extra food granted for accepting recommended objective
const RECOMMENDATION_COMMAND_BONUS: int = 5   # Command granted for accepting recommended doctrine
```

- [ ] **Step 5: Run test — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/test/Stage6BTest.gd game/test/Stage6BTest.tscn game/src/constants/GameConstants.gd
git commit -m "feat: Stage6BTest skeleton and recommendation reward constants"
```

---

## Task 2: ProgressionState New Fields

**Files:**
- Modify: `game/src/resources/ProgressionState.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test method**

Add to `Stage6BTest.gd` — call `_test_progression_state_new_fields()` in `_ready()` and add:

```gdscript
func _test_progression_state_new_fields() -> void:
	print("-- ProgressionState new fields --")
	var p := ProgressionState.new()
	check(p.admiralty_bias is Array, "admiralty_bias is Array")
	check(p.admiralty_bias.size() == 0, "admiralty_bias defaults empty")
	check(p.scandal_flags is Array, "scandal_flags is Array")
	check(p.scandal_flags.size() == 0, "scandal_flags defaults empty")

	# Verify accumulation — same string can appear multiple times
	p.admiralty_bias.append("blamed_crew")
	p.admiralty_bias.append("blamed_crew")
	check(p.admiralty_bias.size() == 2, "admiralty_bias accumulates duplicates")
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `admiralty_bias` not defined.

- [ ] **Step 3: Add fields to ProgressionState.gd**

Add after `@export var last_run_difficulty_score: int = 0`:

```gdscript
@export var admiralty_bias: Array[String] = []   # Pattern of report framings across runs
@export var scandal_flags: Array[String] = []    # Specific things on record; seed incident eligibility
```

- [ ] **Step 4: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/resources/ProgressionState.gd game/test/Stage6BTest.gd
git commit -m "feat: ProgressionState gains admiralty_bias and scandal_flags arrays"
```

---

## Task 3: SaveManager — record_report_framing()

**Files:**
- Modify: `game/src/SaveManager.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test method**

Add to `_ready()` and implement:

```gdscript
func _test_record_report_framing() -> void:
	print("-- SaveManager.record_report_framing --")
	var slot := "test_slot_6b"

	# First framing
	SaveManager.record_report_framing("blamed_crew", "scandal_blamed_crew", slot)
	var p := SaveManager.load_progression(slot)
	check("blamed_crew" in p.admiralty_bias, "bias appended after first call")
	check("scandal_blamed_crew" in p.scandal_flags, "scandal flag appended after first call")

	# Second framing — same bias, different flag
	SaveManager.record_report_framing("blamed_crew", "scandal_blamed_crew", slot)
	p = SaveManager.load_progression(slot)
	check(p.admiralty_bias.size() == 2, "admiralty_bias accumulates across calls")
	check(p.scandal_flags.size() == 2, "scandal_flags accumulates across calls")

	# Empty flag — no panic
	SaveManager.record_report_framing("discipline_on_record", "", slot)
	p = SaveManager.load_progression(slot)
	check(p.scandal_flags.size() == 2, "empty scandal_flag not appended")

	# Clean up
	DirAccess.remove_absolute(GameConstants.SAVE_DIR + slot + "/progression.tres")
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `record_report_framing` not defined.

- [ ] **Step 3: Add method to SaveManager.gd**

Add after `record_objective_complete`:

```gdscript
func record_report_framing(bias_string: String, scandal_flag: String, slot_id: String = SLOT_DEFAULT) -> void:
	var progression := load_progression(slot_id)
	if bias_string != "":
		progression.admiralty_bias.append(bias_string)
	if scandal_flag != "":
		progression.scandal_flags.append(scandal_flag)
	save_progression(progression, slot_id)
```

- [ ] **Step 4: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/SaveManager.gd game/test/Stage6BTest.gd
git commit -m "feat: SaveManager.record_report_framing accumulates bias and scandal flags"
```

---

## Task 4: RunEndScene — Framing Definitions and Gating

**Files:**
- Modify: `game/src/ui/RunEndScene.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test methods**

Add to `_ready()` and implement:

```gdscript
func _test_framing_gate_mutiny() -> void:
	print("-- Framing gate: mutiny --")
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()
	var state := ExpeditionState.new()
	state.run_end_reason = "mutiny"
	state.stress_indicators = {"crew_losses": 0, "peak_burden": 80, "min_command": 10, "supply_depletions": 0}
	scene.set("final_state", state)
	scene.set("_objective_success", false)
	var available: Array = scene.call("_get_available_framings")
	check("suppress_mutiny" in available, "suppress_mutiny available on mutiny")
	check("blame_crew" in available, "blame_crew available on mutiny (any_failure)")
	check("admit_failure" in available, "admit_failure available on mutiny (any_failure)")
	scene.free()


func _test_framing_gate_breakdown() -> void:
	print("-- Framing gate: breakdown --")
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()
	var state := ExpeditionState.new()
	state.run_end_reason = "breakdown"
	state.stress_indicators = {"crew_losses": 0, "peak_burden": 100, "min_command": 30, "supply_depletions": 0}
	scene.set("final_state", state)
	scene.set("_objective_success", false)
	var available: Array = scene.call("_get_available_framings")
	check("suppress_mutiny" not in available, "suppress_mutiny NOT available on breakdown")
	check("blame_crew" in available, "blame_crew available on breakdown")
	check("admit_failure" in available, "admit_failure available on breakdown")
	scene.free()


func _test_framing_gate_losses() -> void:
	print("-- Framing gate: glorify_sacrifice requires losses --")
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()
	var state := ExpeditionState.new()
	state.run_end_reason = "breakdown"
	state.stress_indicators = {"crew_losses": 2, "peak_burden": 80, "min_command": 30, "supply_depletions": 0}
	scene.set("final_state", state)
	scene.set("_objective_success", false)
	var available: Array = scene.call("_get_available_framings")
	check("glorify_sacrifice" in available, "glorify_sacrifice available when crew_losses > 0")

	# No losses — not available
	var scene2: Node = RunEndSceneClass.new()
	var state2 := ExpeditionState.new()
	state2.run_end_reason = "breakdown"
	state2.stress_indicators = {"crew_losses": 0, "peak_burden": 80, "min_command": 30, "supply_depletions": 0}
	scene2.set("final_state", state2)
	scene2.set("_objective_success", false)
	var available2: Array = scene2.call("_get_available_framings")
	check("glorify_sacrifice" not in available2, "glorify_sacrifice NOT available when no losses")
	scene2.free()
	scene.free()
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `_get_available_framings` not defined.

- [ ] **Step 3: Add FRAMING_OPTIONS constant and gating methods to RunEndScene.gd**

Add after the class-level variable declarations (before `_ready()`):

```gdscript
var _selected_framing: String = ""

# Each entry: id -> { title, spin_text, consequence_text, bias_string, scandal_flag, gate }
# gate values:
#   "mutiny"                   — run_end_reason == "mutiny"
#   "any_failure"              — run_end_reason in ["mutiny", "breakdown"]
#   "failure_with_hazard"      — failed + storm/hazard memory flag
#   "failure_with_misconduct"  — failed + misconduct memory flag
#   "failure_with_officer"     — failed + objective failed + officer incident flag
#   "any_with_losses"          — crew_losses > 0 (any outcome)
#   "success_with_discipline"  — completed + discipline standing order active
const FRAMING_OPTIONS: Dictionary = {
	"suppress_mutiny": {
		"title": "Suppress the Mutiny",
		"spin_text": "You report a disciplinary incident. The mutiny goes unrecorded. The Admiralty will not know the crew took the ship — unless someone talks.",
		"consequence_text": "The Board grants you authority to manage discipline privately on your next commission. They will be watching for further irregularities.",
		"bias_string": "suppressed_mutiny",
		"scandal_flag": "scandal_suppressed_mutiny",
		"gate": "mutiny",
	},
	"blame_crew": {
		"title": "Blame the Crew",
		"spin_text": "The men were unfit. Pressed sailors with no loyalty and no discipline. You held command as long as any officer could have.",
		"consequence_text": "The Admiralty will not provision pressed men for your next voyage. You will receive volunteers — fewer of them, and they will expect better conditions.",
		"bias_string": "blamed_crew",
		"scandal_flag": "scandal_blamed_crew",
		"gate": "any_failure",
	},
	"admit_failure": {
		"title": "Admit Command Failure",
		"spin_text": "The breakdown of authority was yours to prevent. You did not. The record should say so.",
		"consequence_text": "The Admiralty respects the candour. They assign you a reformist first lieutenant for the next expedition — an officer who believes authority is earned, not assumed.",
		"bias_string": "admitted_failure",
		"scandal_flag": "scandal_admitted_failure",
		"gate": "any_failure",
	},
	"blame_weather": {
		"title": "Blame the Weather",
		"spin_text": "The conditions were beyond any officer's ability to manage. Storms, spoiled stores, a passage the charts did not adequately warn of.",
		"consequence_text": "The Admiralty notes the conditions. They add a supply buffer to your next commission — and will select a more demanding route to test your claim.",
		"bias_string": "weather_blamed",
		"scandal_flag": "scandal_weather_blamed",
		"gate": "failure_with_hazard",
	},
	"conceal_misconduct": {
		"title": "Conceal Misconduct",
		"spin_text": "Certain incidents on the lower deck need not concern the Admiralty. What happened was managed. The record will reflect a disciplined ship.",
		"consequence_text": "The Board accepts the account. They will be paying closer attention to your next commission's ship log.",
		"bias_string": "concealed_misconduct",
		"scandal_flag": "scandal_concealed_misconduct",
		"gate": "failure_with_misconduct",
	},
	"accuse_officer": {
		"title": "Accuse a Rival Officer",
		"spin_text": "The expedition's failure traces to an officer whose conduct was unsuitable for command. The objective was never attempted because of their interference.",
		"consequence_text": "The Board investigates. The accused officer's role will not be filled by their usual contacts on your next commission.",
		"bias_string": "officer_accused",
		"scandal_flag": "scandal_officer_accused",
		"gate": "failure_with_officer",
	},
	"glorify_sacrifice": {
		"title": "Glorify the Sacrifice",
		"spin_text": "Men died holding this expedition together. The Admiralty should know what this crew endured before judging the outcome.",
		"consequence_text": "The Admiralty commends the effort. They add an additional supply allocation to your next commission — and expect results to match the hardship you describe.",
		"bias_string": "sacrifice_on_record",
		"scandal_flag": "scandal_glorified_sacrifice",
		"gate": "any_with_losses",
	},
	"emphasise_discipline": {
		"title": "Emphasise Discipline",
		"spin_text": "The expedition maintained order throughout. Standards were upheld. The crew performed as directed.",
		"consequence_text": "The Admiralty notes the command culture. Iron Discipline doctrine is commended for your next commission.",
		"bias_string": "discipline_on_record",
		"scandal_flag": "",
		"gate": "success_with_discipline",
	},
}
```

Then add the gating methods before `_ready()`:

```gdscript
func _get_available_framings() -> Array[String]:
	var available: Array[String] = []
	var failed: bool = final_state.run_end_reason in ["mutiny", "breakdown"]
	for id: String in FRAMING_OPTIONS:
		var opt: Dictionary = FRAMING_OPTIONS[id]
		var include := false
		match opt.get("gate", ""):
			"mutiny":
				include = (final_state.run_end_reason == "mutiny")
			"any_failure":
				include = failed
			"failure_with_hazard":
				include = failed and _has_hazard_flag()
			"failure_with_misconduct":
				include = failed and _has_misconduct_flag()
			"failure_with_officer":
				include = failed and not _objective_success and _has_officer_incident_flag()
			"any_with_losses":
				include = (final_state.stress_indicators.get("crew_losses", 0) > 0)
			"success_with_discipline":
				include = (final_state.run_end_reason == "completed") and _has_discipline_order()
		if include:
			available.append(id)
	return available


func _has_hazard_flag() -> bool:
	return ("storm_survived" in final_state.memory_flags or
			"hazard_encountered" in final_state.memory_flags)


func _has_misconduct_flag() -> bool:
	for flag: String in ["rum_theft_unresolved", "botched_hanging", "burial_denied", "officer_misconduct"]:
		if flag in final_state.memory_flags:
			return true
	return false


func _has_officer_incident_flag() -> bool:
	for flag: String in ["purser_exposed", "surgeon_publicly_overruled", "officer_dispute"]:
		if flag in final_state.memory_flags:
			return true
	return false


func _has_discipline_order() -> bool:
	return ("suppress_dissent" in final_state.standing_orders or
			"strict_watches" in final_state.standing_orders)
```

- [ ] **Step 4: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/ui/RunEndScene.gd game/test/Stage6BTest.gd
git commit -m "feat: RunEndScene framing option definitions and gate logic"
```

---

## Task 5: RunEndScene — Factual Narrative Builder

**Files:**
- Modify: `game/src/ui/RunEndScene.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test method**

```gdscript
func _test_log_narrative_text() -> void:
	print("-- RunEndScene._build_log_narrative_text --")
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()

	var state := ExpeditionState.new()
	state.run_end_reason = "mutiny"
	state.stress_indicators = {"crew_losses": 3, "peak_burden": 87, "min_command": 14, "supply_depletions": 1}
	state.active_objective_id = "survey_strange_shore"
	scene.set("final_state", state)
	scene.set("_objective_success", false)

	var text: String = scene.call("_build_log_narrative_text")
	check(text.contains("3"), "crew loss count appears in narrative")
	check(text.contains("[color="), "scrutiny facts are BBCode-highlighted")
	check(text.contains("14"), "min command appears highlighted")
	check(text.contains("mutiny") or text.contains("refused"), "mutiny fact appears in narrative")

	# No losses — no death sentence
	var scene2: Node = RunEndSceneClass.new()
	var state2 := ExpeditionState.new()
	state2.run_end_reason = "breakdown"
	state2.stress_indicators = {"crew_losses": 0, "peak_burden": 100, "min_command": 30, "supply_depletions": 0}
	scene2.set("final_state", state2)
	scene2.set("_objective_success", true)
	var text2: String = scene2.call("_build_log_narrative_text")
	check(not text2.contains("dead"), "no death sentence when crew_losses == 0")
	scene2.free()
	scene.free()
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `_build_log_narrative_text` not defined.

- [ ] **Step 3: Add method to RunEndScene.gd**

Add before `_ready()`:

```gdscript
# Returns a BBCode string for the factual account section.
# Highlighted sentences are facts the Admiralty will scrutinise.
func _build_log_narrative_text() -> String:
	var text := ""
	var s := final_state.stress_indicators

	# Opening context
	text += "The expedition departed"
	if _objective_def != null:
		text += " with orders to %s" % _objective_def.display_name.to_lower()
	text += ". "

	# Memory flag context sentences
	if "rum_theft_unresolved" in final_state.memory_flags:
		text += "A rum ration dispute went unresolved. "
	if "storm_survived" in final_state.memory_flags:
		text += "The ship endured a storm. "

	# Burden context
	var peak: int = s.get("peak_burden", 0)
	if peak >= 70:
		text += "Burden reached %d before the end. " % peak

	# Scrutiny facts — highlighted in Admiralty gold
	var losses: int = s.get("crew_losses", 0)
	if losses == 1:
		text += "[color=#c8b89a]One man is dead.[/color] "
	elif losses > 1:
		text += "[color=#c8b89a]%d men are dead.[/color] " % losses

	var min_cmd: int = s.get("min_command", 100)
	if min_cmd < GameConstants.MUTINY_COMMAND_THRESHOLD:
		text += "[color=#c8b89a]Command fell to %d.[/color] " % min_cmd

	if final_state.run_end_reason == "mutiny":
		text += "[color=#c8b89a]The crew refused orders.[/color] "

	if not _objective_success and _objective_def != null:
		text += "[color=#c8b89a]The objective was never completed.[/color] "

	return text.strip_edges()
```

Note: `_build_log_narrative_text()` reads `_objective_def` and `_objective_success` which are set by `_evaluate_outcome()`. In the UI flow, `_evaluate_outcome()` is called before `_build_ui()`. In tests, set both via `scene.set()`.

- [ ] **Step 4: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/ui/RunEndScene.gd game/test/Stage6BTest.gd
git commit -m "feat: RunEndScene factual narrative builder with BBCode highlights"
```

---

## Task 6: RunEndScene — Report Section UI and Submission

**Files:**
- Modify: `game/src/ui/RunEndScene.gd`

This task wires the framing UI into `_build_ui()`. No new testable logic — UI rendering is verified by playing the game. Ensure the existing Stage6ATest still passes after changes.

- [ ] **Step 1: Update `_build_ui()` in RunEndScene.gd**

Replace the `_build_ui()` method entirely:

```gdscript
func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Outcome header
	var outcome_text := ""
	match final_state.run_end_reason:
		"completed": outcome_text = "Expedition Complete"
		"mutiny":    outcome_text = "Mutiny"
		"breakdown": outcome_text = "Expedition Lost"
		_:           outcome_text = "Run Ended"

	var outcome_label := Label.new()
	outcome_label.text = outcome_text
	outcome_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(outcome_label)

	vbox.add_child(HSeparator.new())

	# Objective result
	var obj_label := Label.new()
	if _objective_def:
		var result_str := "SUCCESS" if _objective_success else "FAILED"
		obj_label.text = "Objective: %s — %s\n%s" % [_objective_def.display_name, result_str, _objective_def.description]
	else:
		obj_label.text = "No objective set."
	obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(obj_label)

	vbox.add_child(HSeparator.new())

	# Factual account
	var log_title := Label.new()
	log_title.text = "What the Log Shows"
	log_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(log_title)

	var narrative := RichTextLabel.new()
	narrative.bbcode_enabled = true
	narrative.fit_content = true
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD
	narrative.text = _build_log_narrative_text()
	vbox.add_child(narrative)

	# Stress stats
	var s := final_state.stress_indicators
	var stress_label := Label.new()
	stress_label.text = "Peak Burden: %d  |  Min Command: %d  |  Crew Lost: %d  |  Admiralty Assessment: %d / 100" % [
		s.get("peak_burden", 0), s.get("min_command", 0),
		s.get("crew_losses", 0), _difficulty_score
	]
	vbox.add_child(stress_label)

	vbox.add_child(HSeparator.new())

	# Report framing
	_build_report_section(vbox)
```

- [ ] **Step 2: Add `_build_report_section()` to RunEndScene.gd**

```gdscript
func _build_report_section(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Your Report to the Admiralty"
	title.add_theme_font_size_override("font_size", 18)
	parent.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose how the expedition is recorded. The Admiralty will remember."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(subtitle)

	var available := _get_available_framings()

	# Return button — enabled only after a framing is selected
	var return_btn := Button.new()
	return_btn.text = "Return to Admiralty"
	return_btn.disabled = true

	for id: String in available:
		var opt: Dictionary = FRAMING_OPTIONS[id]
		var card := _build_framing_card(id, opt, return_btn)
		parent.add_child(card)

	parent.add_child(return_btn)
	return_btn.pressed.connect(_on_return)


func _build_framing_card(framing_id: String, opt: Dictionary, return_btn: Button) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = opt.get("title", "")
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var spin := Label.new()
	spin.text = opt.get("spin_text", "")
	spin.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(spin)

	var consequence := Label.new()
	consequence.text = opt.get("consequence_text", "")
	consequence.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(consequence)

	var select_btn := Button.new()
	select_btn.text = "Select"
	select_btn.pressed.connect(_on_framing_selected.bind(framing_id, select_btn, return_btn))
	vbox.add_child(select_btn)

	return panel


func _on_framing_selected(framing_id: String, btn: Button, return_btn: Button) -> void:
	_selected_framing = framing_id
	return_btn.disabled = false
```

- [ ] **Step 3: Update `_on_return()` to record the framing**

Replace the existing `_on_return()`:

```gdscript
func _on_return() -> void:
	if _selected_framing != "":
		var opt: Dictionary = FRAMING_OPTIONS.get(_selected_framing, {})
		SaveManager.record_report_framing(
			opt.get("bias_string", ""),
			opt.get("scandal_flag", "")
		)
	var prep_scene: Node = load("res://src/ui/PreparationScene.tscn").instantiate()
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(prep_scene)
	get_tree().current_scene = prep_scene
	old_scene.queue_free()
```

- [ ] **Step 4: Verify Stage6ATest still passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Run Stage6BTest**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/ui/RunEndScene.gd
git commit -m "feat: RunEndScene report framing UI, selection, and submission"
```

---

## Task 7: ExpeditionState — Officer Starting Traits and Config Rewards

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test method**

```gdscript
func _test_expedition_state_officer_traits() -> void:
	print("-- ExpeditionState officer_starting_traits --")
	var state := ExpeditionState.new()
	check(state.officer_starting_traits is Dictionary, "officer_starting_traits is Dictionary")
	check(state.officer_starting_traits.is_empty(), "officer_starting_traits defaults empty")


func _test_create_from_config_rewards() -> void:
	print("-- create_from_config reward application --")
	var config := {
		"objective_id": "survey_strange_shore",
		"doctrine_id": "",
		"officer_ids": [],
		"upgrade_ids": [],
		"officer_starting_traits": {"first_lieutenant": "loyal"},
		"starting_supply_bonus": 10,
		"starting_command_bonus": 5,
		"scandal_flags": ["scandal_blamed_crew"],
	}
	var state := ExpeditionState.create_from_config(config)
	check(state.officer_starting_traits.get("first_lieutenant", "") == "loyal",
		"officer trait stored on state")
	check(state.get_supply("food") > 0, "supply bonus applied (food > base)")
	check(state.command > 70, "command bonus applied above default")
	check("scandal_blamed_crew" in state.memory_flags, "scandal flag seeded into memory_flags")
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `officer_starting_traits` not defined.

- [ ] **Step 3: Add field to ExpeditionState.gd**

Add after `var active_objective_id: String = ""`:

```gdscript
var officer_starting_traits: Dictionary = {}  # role -> trait e.g. {"first_lieutenant": "loyal"}
```

- [ ] **Step 4: Update `create_from_config()` in ExpeditionState.gd**

Add these lines before `return state` in `create_from_config()`:

```gdscript
	# Officer starting traits (from Admiralty recommendations)
	state.officer_starting_traits = config.get("officer_starting_traits", {})

	# Supply bonus from accepted objective recommendation
	var supply_bonus: int = config.get("starting_supply_bonus", 0)
	if supply_bonus > 0:
		state.supplies["food"] = state.supplies.get("food", 0) + supply_bonus

	# Command bonus from accepted doctrine recommendation
	var command_bonus: int = config.get("starting_command_bonus", 0)
	if command_bonus > 0:
		state.command = clampi(state.command + command_bonus, GameConstants.COMMAND_MIN, GameConstants.COMMAND_MAX)

	# Seed scandal flags from ProgressionState into memory_flags
	# so existing has_memory_flag conditions can gate on them
	for flag: String in config.get("scandal_flags", []):
		state.add_memory_flag(flag)

	# Recalculate stress baseline after bonuses
	state.stress_indicators["peak_burden"] = state.burden
	state.stress_indicators["min_command"] = state.command
```

- [ ] **Step 5: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 6: Verify Stage6ATest still passes**

```bash
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 7: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd game/test/Stage6BTest.gd
git commit -m "feat: ExpeditionState officer_starting_traits, supply/command bonuses, scandal flag seeding"
```

---

## Task 8: PreparationScene — Bias Computation and Admiralty Letter

**Files:**
- Modify: `game/src/ui/PreparationScene.gd`
- Modify: `game/test/Stage6BTest.gd`

- [ ] **Step 1: Add test method**

```gdscript
func _test_compute_bias_effects() -> void:
	print("-- PreparationScene._compute_bias_effects --")
	var PrepClass: GDScript = load("res://src/ui/PreparationScene.gd")
	var scene: Node = PrepClass.new()

	# blamed_crew → first_lieutenant_lenient unavailable, iron_discipline recommended
	var effects: Dictionary = scene.call("_compute_bias_effects", ["blamed_crew"])
	check("first_lieutenant_lenient" in effects.get("unavailable_ids", []),
		"blamed_crew makes lenient lieutenant unavailable")
	check(effects.get("recommended", {}).has("iron_discipline"),
		"blamed_crew recommends iron_discipline doctrine")

	# admitted_failure → reformist officer surfaced
	var effects2: Dictionary = scene.call("_compute_bias_effects", ["admitted_failure"])
	check(effects2.get("recommended", {}).has("first_lieutenant_lenient"),
		"admitted_failure surfaces lenient lieutenant as recommended")

	scene.free()


func _test_admiralty_letter_text() -> void:
	print("-- PreparationScene._build_letter_text --")
	var PrepClass: GDScript = load("res://src/ui/PreparationScene.gd")
	var scene: Node = PrepClass.new()

	var text: String = scene.call("_build_letter_text", ["blamed_crew"])
	check(text.length() > 10, "letter text non-empty for blamed_crew bias")
	check(text.contains("crew") or text.contains("men"), "blamed_crew letter mentions crew")

	var empty_text: String = scene.call("_build_letter_text", [])
	check(empty_text == "", "no bias produces empty letter text")
	scene.free()
```

- [ ] **Step 2: Run — verify it fails**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: FAIL — `_compute_bias_effects` not defined.

- [ ] **Step 3: Add bias fields and methods to PreparationScene.gd**

Add new instance variables after the existing `_officer_buttons_by_role` declaration:

```gdscript
var _admiralty_bias: Array[String] = []
var _scandal_flags: Array[String] = []
var _unavailable_ids: Array[String] = []   # content ids greyed out this prep
var _recommended: Dictionary = {}          # content_id -> { reward_text, type, trait? }
var _free_upgrade_id: String = ""          # recommended upgrade that doesn't use a slot
var _allocation_panel: VBoxContainer       # reference for live updates
```

Add these methods before `_ready()`:

```gdscript
# Returns { "unavailable_ids": Array[String], "recommended": Dictionary }
# recommended maps content_id -> { "reward_text": String, "type": String, "trait": String }
func _compute_bias_effects(bias: Array[String]) -> Dictionary:
	var unavailable: Array[String] = []
	var recommended: Dictionary = {}

	for b: String in bias:
		match b:
			"blamed_crew":
				unavailable.append("first_lieutenant_lenient")
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"suppressed_mutiny":
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"admitted_failure":
				recommended["first_lieutenant_lenient"] = {
					"reward_text": "First Lieutenant starts Loyal",
					"type": "officer",
					"trait": "loyal",
				}
			"sacrifice_on_record":
				recommended["medical_stores"] = {
					"reward_text": "Medical Stores free — no slot used",
					"type": "upgrade",
				}
			"discipline_on_record":
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"weather_blamed":
				# No specific content recommendation — letter handles explanation
				pass
			"officer_accused":
				unavailable.append("first_lieutenant_lenient")
				unavailable.append("first_lieutenant_stern")

	return {"unavailable_ids": unavailable, "recommended": recommended}


func _build_letter_text(bias: Array[String]) -> String:
	if bias.is_empty():
		return ""
	var sentences: Array[String] = []
	for b: String in bias:
		match b:
			"blamed_crew":
				sentences.append("Your account of the crew's insubordination during the previous commission was noted. The Board expects firmer authority on this voyage. Officers of a lenient temperament have not been made available to you.")
			"suppressed_mutiny":
				sentences.append("The Board has reviewed your disciplinary report. Iron Discipline doctrine is commended for this commission. They will be watching for further irregularities.")
			"admitted_failure":
				sentences.append("Your candour regarding the previous commission was noted. A reformist first lieutenant has been assigned to this voyage — an officer who believes authority is earned, not assumed.")
			"sacrifice_on_record":
				sentences.append("The Board commends the effort of the previous expedition. Medical stores have been allocated without charge in recognition of the hardship endured.")
			"discipline_on_record":
				sentences.append("The Board notes the disciplined conduct of the previous commission. Iron Discipline doctrine is commended for this voyage.")
			"weather_blamed":
				sentences.append("Your account of the conditions encountered during the previous commission was received. The Board has assigned a more demanding route for this voyage.")
			"officer_accused":
				sentences.append("The Board is investigating the officer conduct you reported. The accused officer's role has not been filled through the usual channels for this commission.")
			"concealed_misconduct":
				sentences.append("The Board accepted your previous account. They will be paying closer attention to the ship log on your next commission.")
			"compliant":
				sentences.append("Full compliance with the Board's recommendations has been noted. Expectations for the next commission will reflect this record.")
	# Deduplicate while preserving order
	var seen: Array[String] = []
	var unique: Array[String] = []
	for s: String in sentences:
		if s not in seen:
			seen.append(s)
			unique.append(s)
	return "\n\n".join(unique)
```

- [ ] **Step 4: Run — verify it passes**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/ui/PreparationScene.gd game/test/Stage6BTest.gd
git commit -m "feat: PreparationScene bias computation and Admiralty letter text builder"
```

---

## Task 9: PreparationScene — Greyed and Recommended Rendering

**Files:**
- Modify: `game/src/ui/PreparationScene.gd`

Wire `_unavailable_ids` and `_recommended` into the `_ready()` flow and each `_build_*` method. No new testable logic — verified by playing.

- [ ] **Step 1: Update `_ready()` to load bias before building UI**

Replace the existing `_ready()`:

```gdscript
func _ready() -> void:
	var progression := SaveManager.load_progression()
	_admiralty_bias = progression.admiralty_bias
	_scandal_flags = progression.scandal_flags
	var effects := _compute_bias_effects(_admiralty_bias)
	_unavailable_ids = effects.get("unavailable_ids", [])
	_recommended = effects.get("recommended", {})
	# Identify free upgrade (type == "upgrade" in recommended)
	for content_id: String in _recommended:
		if _recommended[content_id].get("type", "") == "upgrade":
			_free_upgrade_id = content_id
	_build_ui()
```

- [ ] **Step 2: Add Admiralty letter to `_build_ui()`**

After the subtitle label and before the first `HSeparator`, add:

```gdscript
	# Admiralty letter (only if bias exists)
	var letter_text := _build_letter_text(_admiralty_bias)
	if letter_text != "":
		var letter_panel := PanelContainer.new()
		var letter_vbox := VBoxContainer.new()
		letter_panel.add_child(letter_vbox)

		var letter_heading := Label.new()
		letter_heading.text = "Correspondence from the Admiralty Board"
		letter_vbox.add_child(letter_heading)

		var letter_body := Label.new()
		letter_body.text = letter_text
		letter_body.autowrap_mode = TextServer.AUTOWRAP_WORD
		letter_vbox.add_child(letter_body)

		vbox.add_child(letter_panel)
		vbox.add_child(HSeparator.new())
```

- [ ] **Step 3: Update `_build_objective_slots()` to show greyed/recommended options**

Replace the existing `_build_objective_slots()`:

```gdscript
func _build_objective_slots(parent: VBoxContainer) -> void:
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
		var unavailable: bool = def.id in _unavailable_ids
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\nTier %d — %s" % [def.display_name, def.difficulty_tier, def.description]
		if is_recommended:
			label += "\n▲ " + reward_text
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(220, 80)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_objective_selected.bind(def.id, btn))
		_objective_buttons[def.id] = btn
		hbox.add_child(btn)
		shown += 1
		if shown == 1 and not unavailable:
			_selected_objective = def.id
			btn.button_pressed = true
```

- [ ] **Step 4: Update `_build_doctrine_slots()` similarly**

Replace `_build_doctrine_slots()`:

```gdscript
func _build_doctrine_slots(parent: VBoxContainer) -> void:
	var all_doctrines: Array = ContentRegistry.get_all("doctrines")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

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
		var unavailable: bool = def.id in _unavailable_ids
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\n%s" % [def.display_name, def.description]
		if is_recommended:
			label += "\n▲ " + reward_text + " — Admiralty recommended"
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(220, 60)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_doctrine_selected.bind(def.id, btn))
		_doctrine_buttons[def.id] = btn
		hbox.add_child(btn)
```

- [ ] **Step 5: Update `_build_officer_slots()` to show unavailable variants**

In the inner loop where each officer button is created, add after `btn.custom_minimum_size = Vector2(200, 70)`:

```gdscript
			var unavailable: bool = def.id in _unavailable_ids
			var is_recommended: bool = def.id in _recommended
			var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")
			var extra := ""
			if is_recommended:
				extra = "\n▲ " + reward_text
			if unavailable:
				extra = "\n— Not available this commission"
			btn.text = "%s\n%s%s" % [def.display_name, _format_effects(def.starting_effects), extra]
			btn.disabled = unavailable
			btn.modulate.a = 0.4 if unavailable else 1.0
```

Remove the old `btn.text = ...` line that was there before.

- [ ] **Step 6: Update `_build_upgrade_slots()` to show free/recommended upgrades**

Replace `_build_upgrade_slots()`:

```gdscript
func _build_upgrade_slots(parent: VBoxContainer) -> void:
	var all_upgrades: Array = ContentRegistry.get_all("upgrades")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	for upg: ContentBase in all_upgrades:
		var def: ShipUpgradeDef = upg as ShipUpgradeDef
		if def == null:
			continue
		var unavailable: bool = def.id in _unavailable_ids
		var is_free: bool = (def.id == _free_upgrade_id)
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\n%s" % [def.display_name, def.drawback_text]
		if is_recommended:
			label += "\n▲ " + reward_text + " — Admiralty recommended"
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(200, 70)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_upgrade_toggled.bind(def.id, btn))
		_upgrade_buttons[def.id] = btn
		hbox.add_child(btn)

		# Pre-select free upgrade without consuming a slot
		if is_free and not unavailable:
			_selected_upgrades.append(def.id)
			btn.button_pressed = true
```

- [ ] **Step 7: Update `_on_upgrade_toggled()` to not count free upgrade against cap**

Find and replace the existing `_on_upgrade_toggled` method:

```gdscript
func _on_upgrade_toggled(upgrade_id: String, btn: Button) -> void:
	if upgrade_id in _selected_upgrades:
		if upgrade_id != _free_upgrade_id:  # free upgrade cannot be deselected
			_selected_upgrades.erase(upgrade_id)
			btn.button_pressed = false
	else:
		# Count non-free upgrades against the cap
		var non_free_count := _selected_upgrades.filter(func(id): return id != _free_upgrade_id).size()
		if non_free_count >= GameConstants.MAX_UPGRADES:
			btn.button_pressed = false
			_status_label.text = "Maximum %d upgrades selected." % GameConstants.MAX_UPGRADES
			return
		_selected_upgrades.append(upgrade_id)
	_update_allocation_panel()
	_update_sail_button()
```

- [ ] **Step 8: Verify Stage6ATest and Stage6BTest both pass**

```bash
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS` for both.

- [ ] **Step 9: Commit**

```bash
git add game/src/ui/PreparationScene.gd
git commit -m "feat: PreparationScene greyed unavailable options and recommended highlighting"
```

---

## Task 10: PreparationScene — Allocation Panel and Sail Config

**Files:**
- Modify: `game/src/ui/PreparationScene.gd`

- [ ] **Step 1: Add `_build_allocation_panel()` and wire into `_build_ui()`**

Add this method:

```gdscript
func _build_allocation_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()

	var heading := Label.new()
	heading.text = "Admiralty Allocation"
	heading.add_theme_font_size_override("font_size", 16)
	panel.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Bonuses granted for following Admiralty recommendations."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(subtitle)

	_allocation_panel = VBoxContainer.new()
	panel.add_child(_allocation_panel)
	_update_allocation_panel()
	return panel
```

Add `_update_allocation_panel()`:

```gdscript
func _update_allocation_panel() -> void:
	if _allocation_panel == null:
		return
	for child in _allocation_panel.get_children():
		child.queue_free()

	var accepted_rewards: Array[String] = []

	# Objective recommendation
	if _selected_objective in _recommended and _recommended[_selected_objective].get("type") == "objective":
		accepted_rewards.append("Objective: " + _recommended[_selected_objective].get("reward_text", ""))

	# Doctrine recommendation
	if _selected_doctrine in _recommended and _recommended[_selected_doctrine].get("type") == "doctrine":
		accepted_rewards.append("Doctrine: " + _recommended[_selected_doctrine].get("reward_text", ""))

	# Officer recommendation (auto-applied via trait — show if recommended officer role has no unavailable conflict)
	for content_id: String in _recommended:
		if _recommended[content_id].get("type") == "officer":
			# Check if the recommended officer is actually selected
			for role: String in _selected_officers:
				if _selected_officers[role] == content_id:
					accepted_rewards.append("Officer: " + _recommended[content_id].get("reward_text", ""))

	# Upgrade recommendation
	if _free_upgrade_id != "" and _free_upgrade_id in _selected_upgrades:
		accepted_rewards.append("Upgrade: " + _recommended.get(_free_upgrade_id, {}).get("reward_text", ""))

	if accepted_rewards.is_empty():
		var none_label := Label.new()
		none_label.text = "No recommendations accepted."
		_allocation_panel.add_child(none_label)
	else:
		for reward: String in accepted_rewards:
			var label := Label.new()
			label.text = "▲ " + reward
			_allocation_panel.add_child(label)

		# Full compliance warning
		if accepted_rewards.size() >= _recommended.size() and _recommended.size() > 0:
			var warning := Label.new()
			warning.text = "Full compliance noted. The Board's expectations for the next commission will reflect this."
			warning.autowrap_mode = TextServer.AUTOWRAP_WORD
			_allocation_panel.add_child(warning)
```

In `_build_ui()`, after the upgrades section separator, before the status label, add:

```gdscript
	# Allocation panel
	_build_section(vbox, "", func(p): p.add_child(_build_allocation_panel()))
	vbox.add_child(HSeparator.new())
```

- [ ] **Step 2: Call `_update_allocation_panel()` from selection callbacks**

In each of `_on_objective_selected()`, `_on_doctrine_selected()`, `_on_officer_selected()`, add at the end of the method body:

```gdscript
	_update_allocation_panel()
```

- [ ] **Step 3: Update `_on_set_sail()` to include reward fields in run config**

Find `_on_set_sail()` and update the config dictionary it builds. Replace the existing config construction with:

```gdscript
func _on_set_sail() -> void:
	if not _can_sail():
		_status_label.text = "Select one officer per role before sailing."
		return

	# Compute accepted rewards
	var supply_bonus := 0
	var command_bonus := 0
	var officer_traits: Dictionary = {}
	var free_upgrades: Array[String] = []

	if _selected_objective in _recommended:
		supply_bonus = GameConstants.RECOMMENDATION_SUPPLY_BONUS
	if _selected_doctrine in _recommended:
		command_bonus = GameConstants.RECOMMENDATION_COMMAND_BONUS
	if _free_upgrade_id != "" and _free_upgrade_id in _selected_upgrades:
		free_upgrades.append(_free_upgrade_id)
	for content_id: String in _recommended:
		if _recommended[content_id].get("type") == "officer":
			for role: String in _selected_officers:
				if _selected_officers[role] == content_id:
					var trait: String = _recommended[content_id].get("trait", "")
					if trait != "":
						officer_traits[role] = trait

	var config := {
		"objective_id": _selected_objective,
		"doctrine_id": _selected_doctrine,
		"officer_ids": _selected_officers.values(),
		"upgrade_ids": _selected_upgrades,
		"starting_supply_bonus": supply_bonus,
		"starting_command_bonus": command_bonus,
		"officer_starting_traits": officer_traits,
		"scandal_flags": _scandal_flags,
	}

	SaveManager.pending_run_config = config
	var run_scene: Node = load("res://src/ui/RunScene.tscn").instantiate()
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(run_scene)
	get_tree().current_scene = run_scene
	old_scene.queue_free()
```

- [ ] **Step 4: Add `_can_sail()` helper (if not already present)**

```gdscript
func _can_sail() -> bool:
	for role: String in REQUIRED_ROLES:
		if not _selected_officers.has(role):
			return false
	return _selected_objective != ""
```

- [ ] **Step 5: Verify both test suites pass**

```bash
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS` for both.

- [ ] **Step 6: Commit**

```bash
git add game/src/ui/PreparationScene.gd
git commit -m "feat: PreparationScene allocation panel and reward-aware run config"
```

---

## Task 11: Self-Review and Final Test Run

- [ ] **Step 1: Run Stage6ATest to verify no regressions**

```bash
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 2: Run Stage6BTest for full coverage**

```bash
godot --headless --path game res://test/Stage6BTest.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 3: Run earlier test suites**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -5
```

Expected: `ALL PASS`

- [ ] **Step 4: Commit if any final fixes were needed**

```bash
git add -u
git commit -m "fix: Stage 6B integration cleanup"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ Report framing step in RunEndScene — Task 4–6
- ✅ Factual account with BBCode highlights — Task 5
- ✅ Eight framing options with outcome-first gating — Task 4
- ✅ `admiralty_bias` + `scandal_flags` accumulate in ProgressionState — Task 2–3
- ✅ Admiralty letter from accumulated bias — Task 8
- ✅ Greyed unavailable options with in-world text — Task 9
- ✅ Recommended options highlighted with reward — Task 9
- ✅ Allocation panel, live updates — Task 10
- ✅ Rewards in run config (supply bonus, command bonus, officer trait, free upgrade) — Task 10
- ✅ `officer_starting_traits` flows into ExpeditionState — Task 7
- ✅ Scandal flags seeded into memory_flags at run start — Task 7
- ✅ Full compliance warning in allocation panel — Task 10

**Deferred (per spec):**
- Scandal flag incident weight tuning — existing `has_memory_flag` conditions cover eligibility; trigger weight adjustment is a future content pass
- Frequency-weighted bias effects — presence check is MVP; count-based tuning available without model changes
