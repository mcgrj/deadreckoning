# Stage 8: Officer Hire Promises & Pre-Departure Stances

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the pre-voyage hire promise and pre-departure stance mechanics into the officer selection and expedition start flow, making officer selection feel like the impactful choices spec describes.

**Architecture:** Three small changes to existing systems. (1) A new `promises.json` pool + OfficerGenerator wiring generates hire-condition promises for high-competence officers. (2) `PreparationScene` displays promise requirements in officer cards and shows a "Before You Sail" stance panel that updates as officers are selected. (3) `ExpeditionState.create_from_config()` seeds the active promise from the hired officer's definition, so it tracks through the voyage like any other promise.

**Tech Stack:** Godot 4.6, GDScript. No new Resource types. Changes touch `OfficerGenerator.gd`, `PreparationScene.gd`, `ExpeditionState.gd`, and a new `promises.json` pool file.

---

## File Map

| File | Change |
|---|---|
| `game/content/officer_pools/promises.json` | **Create.** Pool of hire-condition promises per role. |
| `game/src/expedition/OfficerGenerator.gd` | **Modify.** Load promises pool; 30% chance high-competence officers carry a hire promise. |
| `game/src/ui/PreparationScene.gd` | **Modify.** Show promise requirement in officer cards; add "Before You Sail" stance panel. |
| `game/src/expedition/ExpeditionState.gd` | **Modify.** Seed active promise from hired officer at run start. |
| `game/test/Stage8Test.gd` | **Create.** Headless tests for promise seeding and officer card formatting. |
| `game/test/Stage8Test.tscn` | **Create.** Minimal scene that runs Stage8Test. |

---

## Task 1: Create promises.json pool

**Files:**
- Create: `game/content/officer_pools/promises.json`

- [ ] **Step 1: Create the file**

```json
{
  "master": [
    {
      "id": "promise_spirit_locker_open",
      "text": "The spirit locker will remain accessible to the Master throughout the voyage."
    },
    {
      "id": "promise_course_respected",
      "text": "The Master's course recommendation will be followed at each route fork."
    }
  ],
  "purser": [
    {
      "id": "promise_no_audit",
      "text": "The stores will not be formally audited without cause during the voyage."
    },
    {
      "id": "promise_purser_discretion",
      "text": "Distribution of comforts will remain at the Purser's discretion."
    }
  ],
  "surgeon": [
    {
      "id": "promise_sick_bay_intact",
      "text": "The sick bay will not be stripped of supplies or repurposed during the voyage."
    },
    {
      "id": "promise_surgeon_consulted",
      "text": "The Surgeon will be consulted before any punishment that risks serious injury."
    }
  ],
  "chaplain": [
    {
      "id": "promise_burial_rites",
      "text": "Burial rites will be observed for any man who dies on the voyage."
    },
    {
      "id": "promise_prayer_permitted",
      "text": "The men will be permitted to observe prayer before entering dangerous waters."
    }
  ],
  "first_lieutenant": [
    {
      "id": "promise_officer_consulted",
      "text": "The First Lieutenant will be consulted before major disciplinary decisions are made alone."
    }
  ],
  "gunner": []
}
```

- [ ] **Step 2: Commit**

```bash
git add game/content/officer_pools/promises.json
git commit -m "content: add officer hire-condition promises pool"
```

---

## Task 2: Wire promise generation into OfficerGenerator

**Files:**
- Modify: `game/src/expedition/OfficerGenerator.gd:89-90`

OfficerGenerator currently always sets `pre_voyage_promise_id = ""` and `pre_voyage_promise_text = ""`. Replace those two lines with logic that gives high-competence officers a 30% chance of carrying a hire condition.

- [ ] **Step 1: Replace the two blank-assignment lines in `generate()`**

Find the block at lines 89–90:
```gdscript
	def.pre_voyage_promise_id = ""
	def.pre_voyage_promise_text = ""
```

Replace with:
```gdscript
	var promises_pool := _pool("promises")
	var role_promises: Array = promises_pool.get(role, [])
	if def.competence >= 3 and not role_promises.is_empty() and randf() < 0.30:
		var chosen: Dictionary = role_promises[randi() % role_promises.size()]
		def.pre_voyage_promise_id = chosen.get("id", "")
		def.pre_voyage_promise_text = chosen.get("text", "")
	else:
		def.pre_voyage_promise_id = ""
		def.pre_voyage_promise_text = ""
```

- [ ] **Step 2: Commit**

```bash
git add game/src/expedition/OfficerGenerator.gd
git commit -m "feat: OfficerGenerator assigns hire-condition promises to competent officers"
```

---

## Task 3: Write failing tests for promise seeding

**Files:**
- Create: `game/test/Stage8Test.gd`
- Create: `game/test/Stage8Test.tscn`

- [ ] **Step 1: Create Stage8Test.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/Stage8Test.gd" id="1"]

[node name="Stage8Test" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Create Stage8Test.gd with failing tests**

```gdscript
# Stage8Test.gd
# Headless test suite for Stage 8: Officer Hire Promises & Pre-Departure Stances.
# Run: godot --headless --path game res://test/Stage8Test.tscn
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
	print("=== Stage8Test ===\n")
	_test_promise_seeded_from_officer_def()
	_test_no_promise_when_officer_has_none()
	_test_first_officer_with_promise_wins()
	_test_officer_generator_promise_assignment()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _make_minimal_officer_def(role: String, promise_id: String, promise_text: String) -> OfficerDef:
	var def := OfficerDef.new()
	def.id = "test_%s_001" % role
	def.role = role
	def.display_name = "Test Officer"
	def.competence = 3
	def.loyalty = 3
	def.pre_voyage_promise_id = promise_id
	def.pre_voyage_promise_text = promise_text
	def.disclosed_traits = []
	def.rumoured_traits = []
	def.rumoured_hints = []
	def.hidden_traits = []
	def.scar_traits = []
	def.starting_effects = []
	def.advice_hooks = []
	def.runs_survived = 0
	def.notable_events = []
	def.tags = []
	def.pre_departure_stance = ""
	return def


func _base_config(officer_defs: Array) -> Dictionary:
	return {
		"objective_id": "",
		"doctrine_id": "",
		"officer_ids": [],
		"officer_defs": officer_defs,
		"upgrade_ids": [],
		"starting_supply_bonus": 0,
		"starting_command_bonus": 0,
		"officer_starting_traits": {},
		"scandal_flags": [],
	}


func _test_promise_seeded_from_officer_def() -> void:
	print("-- promise seeded from officer def --")
	var def := _make_minimal_officer_def(
		"surgeon",
		"promise_sick_bay_intact",
		"The sick bay will not be stripped of supplies."
	)
	var state := ExpeditionState.create_from_config(_base_config([def]))
	check(not state.active_promise.is_empty(), "active_promise is set when officer has promise_id")
	check(state.active_promise.get("id", "") == "promise_sick_bay_intact", "active_promise.id matches officer promise_id")
	check(state.active_promise.get("text", "") == "The sick bay will not be stripped of supplies.", "active_promise.text matches officer promise_text")


func _test_no_promise_when_officer_has_none() -> void:
	print("-- no promise when officer has none --")
	var def := _make_minimal_officer_def("master", "", "")
	var state := ExpeditionState.create_from_config(_base_config([def]))
	check(state.active_promise.is_empty(), "active_promise is empty when officer has no promise_id")


func _test_first_officer_with_promise_wins() -> void:
	print("-- first officer with promise wins when multiple present --")
	var def_a := _make_minimal_officer_def("surgeon", "promise_sick_bay_intact", "Sick bay intact.")
	var def_b := _make_minimal_officer_def("purser", "promise_no_audit", "No audit.")
	var state := ExpeditionState.create_from_config(_base_config([def_a, def_b]))
	check(state.active_promise.get("id", "") == "promise_sick_bay_intact", "first promise wins (surgeon, then purser)")


func _test_officer_generator_promise_assignment() -> void:
	print("-- OfficerGenerator promise assignment --")
	# Run the generator 100 times for a high-competence role.
	# With 30% probability and competence >= 3, some should have promises.
	# This is probabilistic — just check that the fields are either both empty or both non-empty.
	var any_with_promise := false
	var all_valid_pairing := true
	for _i in range(100):
		var def := OfficerGenerator.generate("surgeon")
		var has_id := def.pre_voyage_promise_id != ""
		var has_text := def.pre_voyage_promise_text != ""
		if has_id != has_text:
			all_valid_pairing = false
		if has_id:
			any_with_promise = true
	check(all_valid_pairing, "promise_id and promise_text are always both set or both empty")
	# Over 100 surgeons (competence >= 3 roughly 60% of the time, then 30% promise chance)
	# Expected ~18 with promises. Asserting > 0 is robust enough.
	check(any_with_promise, "at least one surgeon in 100 has a hire promise")
```

- [ ] **Step 3: Run tests — expect failures on promise seeding tests**

```bash
godot --headless --path game res://test/Stage8Test.tscn
```

Expected: `_test_promise_seeded_from_officer_def` and `_test_first_officer_with_promise_wins` FAIL with "active_promise is set" assertions. `_test_no_promise_when_officer_has_none` and `_test_officer_generator_promise_assignment` may pass.

- [ ] **Step 4: Commit failing tests**

```bash
git add game/test/Stage8Test.gd game/test/Stage8Test.tscn
git commit -m "test: add Stage8Test with failing promise-seeding assertions"
```

---

## Task 4: Seed pre-voyage promise in ExpeditionState.create_from_config()

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`

`create_from_config()` currently has no promise seeding from officer defs. Add it after the officer loading block (after line ~95, where `EffectProcessor.apply_effects` runs for each officer).

- [ ] **Step 1: Add promise seeding block after the officer loading section**

Find the block that ends the officer loading (the `else` branch closes around line 105). After the entire `if not officer_defs_config.is_empty()` block (i.e., after line 105), add:

```gdscript
	# Seed pre-voyage hire promise from the first hired officer who requires one.
	# Only one active promise is supported at a time; the first officer encountered wins.
	# Deadline 999 is intentionally longer than any run — the promise is broken by
	# incident outcomes, not by expiry.
	var _seed_log := SimulationLog.new()
	for _officer_def: OfficerDef in state.officer_defs:
		if _officer_def.pre_voyage_promise_id != "" and state.active_promise.is_empty():
			state.make_promise(_officer_def.pre_voyage_promise_id, _officer_def.pre_voyage_promise_text, 999, _seed_log)
			break
```

- [ ] **Step 2: Run tests — all should pass**

```bash
godot --headless --path game res://test/Stage8Test.tscn
```

Expected output:
```
=== Stage8Test ===

-- promise seeded from officer def --
  PASS: active_promise is set when officer has promise_id
  PASS: active_promise.id matches officer promise_id
  PASS: active_promise.text matches officer promise_text
-- no promise when officer has none --
  PASS: active_promise is empty when officer has no promise_id
-- first officer with promise wins when multiple present --
  PASS: first promise wins (surgeon, then purser)
-- OfficerGenerator promise assignment --
  PASS: promise_id and promise_text are always both set or both empty
  PASS: at least one surgeon in 100 has a hire promise

--- Results: 7 passed, 0 failed ---
ALL PASS
```

- [ ] **Step 3: Run existing tests to confirm no regressions**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
```

Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd
git commit -m "feat: seed active promise from hired officer hire condition at run start"
```

---

## Task 5: Show hire promise in officer cards in PreparationScene

**Files:**
- Modify: `game/src/ui/PreparationScene.gd` — `_format_officer_card()` method

`_format_officer_card()` currently builds lines for name, background, disclosed/rumoured traits, competence/loyalty, and run history. Add a hire condition line when the officer has one.

- [ ] **Step 1: Add promise line to `_format_officer_card()`**

Find `_format_officer_card()` (around line 488). After the `if def.runs_survived > 0` block and before `return "\n".join(lines)`, add:

```gdscript
	if def.pre_voyage_promise_id != "":
		lines.append("Hire condition: \"%s\"" % def.pre_voyage_promise_text)
```

The full end of `_format_officer_card()` becomes:

```gdscript
	if def.runs_survived > 0:
		lines.append("%d run(s) survived" % def.runs_survived)
		if not def.notable_events.is_empty():
			lines.append("History: " + ", ".join(def.notable_events.slice(0, 3)))
	if def.pre_voyage_promise_id != "":
		lines.append("Hire condition: \"%s\"" % def.pre_voyage_promise_text)
	return "\n".join(lines)
```

- [ ] **Step 2: Run existing tests to confirm no regressions**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
godot --headless --path game res://test/Stage8Test.tscn
```

Expected: ALL PASS on both suites.

- [ ] **Step 3: Commit**

```bash
git add game/src/ui/PreparationScene.gd
git commit -m "feat: show officer hire promise requirement in PreparationScene officer cards"
```

---

## Task 6: Add pre-departure stances panel to PreparationScene

**Files:**
- Modify: `game/src/ui/PreparationScene.gd`

Add a "Before You Sail" section that collects `pre_departure_stance` from each currently selected officer and displays them. The section is hidden when no officer has a stance. It updates whenever officer selection changes.

- [ ] **Step 1: Add `_stances_container` field**

At the top of the class (near the other UI field declarations around line 22), add:

```gdscript
var _stances_container: VBoxContainer = null
```

- [ ] **Step 2: Add `_update_stances()` method**

Add this method anywhere before `_on_set_sail()`:

```gdscript
func _update_stances() -> void:
	if _stances_container == null:
		return
	for child in _stances_container.get_children():
		child.queue_free()
	for role: String in _selected_officers:
		var oid: String = _selected_officers[role]
		for def: OfficerDef in _officer_pool_defs:
			if def.id == oid and def.pre_departure_stance != "":
				var label := Label.new()
				label.text = "%s: \"%s\"" % [
					role.replace("_", " ").capitalize(),
					def.pre_departure_stance
				]
				label.autowrap_mode = TextServer.AUTOWRAP_WORD
				_stances_container.add_child(label)
				break
```

- [ ] **Step 3: Add `_build_departure_stances_section()` method**

```gdscript
func _build_departure_stances_section(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Before You Sail"
	heading.add_theme_font_size_override("font_size", 16)
	parent.add_child(heading)
	_stances_container = VBoxContainer.new()
	parent.add_child(_stances_container)
	_update_stances()
```

- [ ] **Step 4: Call `_build_departure_stances_section()` in `_build_ui()`**

In `_build_ui()`, find the block that adds `_status_label` and `_sail_button` (near line 310). Insert the stances section and a separator immediately before the status label:

```gdscript
	# Before You Sail — officer stances
	_build_section(vbox, "", func(p): _build_departure_stances_section(p))
	vbox.add_child(HSeparator.new())

	# Status + Set Sail
	_status_label = Label.new()
```

- [ ] **Step 5: Call `_update_stances()` at the end of `_on_officer_selected()`**

Find `_on_officer_selected()` (around line 530). At the end of the function, after `_update_allocation_panel()`, add:

```gdscript
	_update_stances()
```

The full `_on_officer_selected()` becomes:

```gdscript
func _on_officer_selected(role: String, officer_id: String, btn: Button) -> void:
	for role_btn: Button in _officer_buttons_by_role.get(role, []):
		role_btn.button_pressed = false
	_selected_officers[role] = officer_id
	btn.button_pressed = true
	_update_allocation_panel()
	_update_stances()
```

- [ ] **Step 6: Run tests**

```bash
godot --headless --path game res://test/Stage6ATest.tscn
godot --headless --path game res://test/Stage8Test.tscn
```

Expected: ALL PASS on both suites.

- [ ] **Step 7: Commit**

```bash
git add game/src/ui/PreparationScene.gd
git commit -m "feat: add pre-departure officer stances panel to PreparationScene"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** impactful-choices-design.md §7 defines pre-voyage promises (Task 1–4), hire promise display (Task 5), and pre-departure stances (Task 6). All three are covered.
- [x] **Placeholder scan:** No TBD/TODO. All code is complete.
- [x] **Type consistency:** `OfficerDef.pre_voyage_promise_id`, `.pre_voyage_promise_text`, `.pre_departure_stance` are the field names used in OfficerDef.gd (lines 37, 40, 43). Used identically in OfficerGenerator and ExpeditionState changes.
- [x] **Promise deadline:** 999 ticks documented as intentional — broken by incident outcome, not expiry.
- [x] **One-promise constraint:** Only one active promise at a time is the existing system rule. First hired officer with a promise wins. Documented inline.
- [x] **Regression risk:** Changes are additive only. No existing behaviour is removed. `create_from_config()` change runs after officers are loaded, which is after `EffectProcessor.apply_effects` — no ordering conflict.
