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
