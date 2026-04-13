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
	_test_officer_def_starting_effects()
	_test_expedition_state_new_fields()
	_test_create_from_config()
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
	check(GameConstants.BURDEN_MIN == 0, "burden min is 0")
	check(GameConstants.COMMAND_MIN == 0, "command min is 0")
	check(GameConstants.SAVE_DIR == "user://saves/", "save dir is user://saves/")
	check(GameConstants.DIFFICULTY_BURDEN_WEIGHT == 0.3, "difficulty burden weight is 0.3")
	check(GameConstants.DIFFICULTY_COMMAND_WEIGHT == 0.3, "difficulty command weight is 0.3")
	check(GameConstants.DIFFICULTY_CREW_LOSS_WEIGHT == 5, "difficulty crew loss weight is 5")
	check(GameConstants.DIFFICULTY_SUPPLY_DEPLETION_WEIGHT == 3, "difficulty supply depletion weight is 3")


func _test_officer_def_starting_effects() -> void:
	print("-- OfficerDef.starting_effects --")
	var officer := OfficerDef.new()
	check(officer.starting_effects is Array, "starting_effects is an Array")
	check(officer.starting_effects.size() == 0, "starting_effects defaults to empty")


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
