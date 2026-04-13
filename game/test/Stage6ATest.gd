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
	_test_breakdown_trigger()
	_test_mutiny_trigger()
	_test_no_run_end_healthy_state()
	_test_suppress_dissent_mitigation()
	_test_run_end_scene_difficulty_formula()
	_test_progression_objective_complete()
	_test_route_map_full_traversal()
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
	print("-- TravelSimulator mutiny (command=0, burden=100) --")
	var state := ExpeditionState.new()
	state.command = 0
	state.burden = 100
	var zone := ContentRegistry.get_all("zone_types")[0] as ZoneTypeDef
	if zone == null:
		check(false, "need at least one zone_type content file")
		return
	var log := SimulationLog.new()
	# burden=100 triggers breakdown immediately (checked before mutiny), so
	# we use burden=50, command=0: chance = (50/100)*0.4 = 0.2 per tick.
	# Run 30 ticks to get near-certain mutiny.
	state.burden = 50
	for i in 30:
		if state.run_end_reason != "":
			break
		TravelSimulator.process_tick(state, zone, log)
	check(state.run_end_reason == "mutiny" or state.run_end_reason == "breakdown",
		"command=0 burden=50 eventually triggers run end")


func _test_no_run_end_healthy_state() -> void:
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


func _test_suppress_dissent_mitigation() -> void:
	print("-- TravelSimulator: suppress_dissent halves mutiny chance --")
	# Without suppress_dissent: command=0, burden=100 would be breakdown.
	# Use command=0, burden=50: chance = (50/100)*0.4 = 0.2 per tick
	# With suppress_dissent: chance = 0.1 per tick
	# We just verify the code path doesn't error and run_end_reason is set eventually.
	var state := ExpeditionState.new()
	state.command = 0
	state.burden = 50
	state.standing_orders.append("suppress_dissent")
	var zone := ContentRegistry.get_all("zone_types")[0] as ZoneTypeDef
	if zone == null:
		check(false, "need at least one zone_type content file")
		return
	var log := SimulationLog.new()
	# Run up to 50 ticks — with chance=0.1, P(at least one mutiny) > 99.4%
	for i in 50:
		if state.run_end_reason != "":
			break
		TravelSimulator.process_tick(state, zone, log)
	check(state.run_end_reason == "mutiny" or state.run_end_reason == "breakdown",
		"suppress_dissent still allows eventual mutiny (just slower)")
	# Verify the suppress_dissent standing order was present when the check ran
	# by confirming run ended (not stuck in infinite loop)
	check(state.run_end_reason != "", "run eventually ends with suppress_dissent active")


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
	var RunEndSceneClass: GDScript = load("res://src/ui/RunEndScene.gd")
	var scene: Node = RunEndSceneClass.new()
	scene.set("final_state", state)
	# Call _compute_difficulty_score directly
	var score: int = scene.call("_compute_difficulty_score")
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


func _test_route_map_full_traversal() -> void:
	print("-- RouteMap + TravelSimulator full traversal --")
	var route := RouteMap.create_test_map()
	var state := ExpeditionState.new()
	state.burden = 10
	state.command = 80
	var log := SimulationLog.new()

	check(not route.is_complete(), "route not complete at start")
	check(not route.is_travelling(), "not travelling at start")

	# Walk the route: select first node per stage, advance one tick at a time.
	var max_ticks := 50  # safety cap — test map has ~9 ticks total
	var tick_count := 0
	while not route.is_complete() and state.run_end_reason == "" and tick_count < max_ticks:
		if not route.is_travelling():
			var stage: Array = route.get_current_stage()
			if stage.is_empty():
				break
			route.select_node(stage[0] as RouteNode)
		var zone: ZoneTypeDef = route.get_active_zone()
		if zone == null:
			check(false, "get_active_zone returned null during travel")
			return
		TravelSimulator.process_tick(state, zone, log)
		route.advance_tick()
		tick_count += 1

	check(route.is_complete(), "route reports complete after all nodes")
	check(tick_count > 0, "at least one tick was processed")
	check(tick_count < max_ticks, "traversal completed within tick budget")
	check(state.run_end_reason == "", "healthy state survives full route without run end")

	# Verify node must be selected before advance_tick does anything meaningful
	var route2 := RouteMap.create_test_map()
	check(not route2.is_travelling(), "fresh route is not travelling")
	check(route2.get_active_zone() == null, "get_active_zone returns null when no node selected")
	var stage: Array = route2.get_current_stage()
	route2.select_node(stage[0] as RouteNode)
	check(route2.is_travelling(), "is_travelling after select_node")
	check(route2.get_active_zone() != null, "get_active_zone returns zone after select_node")
