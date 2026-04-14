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
	_test_progression_state_new_fields()
	_test_record_report_framing()
	_test_framing_gate_mutiny()
	_test_framing_gate_breakdown()
	_test_framing_gate_losses()
	_test_log_narrative_text()
	_test_expedition_state_officer_traits()
	_test_create_from_config_rewards()
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
	p.scandal_flags.append("scandal_suppressed_mutiny")
	p.scandal_flags.append("scandal_suppressed_mutiny")
	check(p.scandal_flags.size() == 2, "scandal_flags accumulates duplicates")

	# create_default() must leave both arrays empty — they are run-accumulated
	var d := ProgressionState.create_default()
	check(d.admiralty_bias.size() == 0, "create_default admiralty_bias is empty")
	check(d.scandal_flags.size() == 0, "create_default scandal_flags is empty")


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
	DirAccess.remove_absolute(GameConstants.SAVE_DIR + slot + "/")


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
	scene.free()
	scene2.free()


func _test_log_narrative_text() -> void:
	print("-- RunEndScene._build_log_narrative_text --")
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()

	var state := ExpeditionState.new()
	state.run_end_reason = "mutiny"
	state.stress_indicators = {"crew_losses": 3, "peak_burden": 87, "min_command": 14, "supply_depletions": 1}
	# _objective_def set directly — headless tests cannot use ContentRegistry.get_by_id
	var obj_def := ObjectiveDef.new()
	obj_def.display_name = "Survey Strange Shore"
	scene.set("final_state", state)
	scene.set("_objective_success", false)
	scene.set("_objective_def", obj_def)

	var text: String = scene.call("_build_log_narrative_text")
	check(text.contains("3"), "crew loss count appears in narrative")
	check(text.contains("[color="), "scrutiny facts are BBCode-highlighted")
	check(text.contains("14"), "min command appears highlighted")
	check(text.contains("mutiny") or text.contains("refused"), "mutiny fact appears in narrative")
	check(text.contains("survey"), "objective name appears in narrative")
	check(text.contains("never completed"), "objective failure sentence present")

	# No losses, succeeded — no death sentence; burden sentence present
	var scene2: Node = RunEndSceneClass.new()
	var state2 := ExpeditionState.new()
	state2.run_end_reason = "breakdown"
	state2.stress_indicators = {"crew_losses": 0, "peak_burden": 100, "min_command": 30, "supply_depletions": 0}
	scene2.set("final_state", state2)
	scene2.set("_objective_success", true)
	var text2: String = scene2.call("_build_log_narrative_text")
	check(not text2.contains("dead"), "no death sentence when crew_losses == 0")
	check(text2.contains("100"), "peak burden appears when >= 70")
	check(not text2.contains("refused"), "no mutiny sentence on breakdown")
	scene.free()
	scene2.free()


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
	check(state.get_supply("food") > 0, "supply bonus applied (food > 0)")
	check(state.command > 70, "command bonus applied above default")
	check("scandal_blamed_crew" in state.memory_flags, "scandal flag seeded into memory_flags")
