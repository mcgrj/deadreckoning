# RouteMapTest.gd
# Headless test suite for Stage 3: Route Map and Travel Ticks.
# Run: godot --headless --path game res://test/RouteMapTest.tscn
extends Node

var _pass = 0
var _fail = 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
		_pass += 1
	else:
		push_error("  FAIL: " + label)
		_fail += 1


func _ready() -> void:
	print("=== RouteMapTest ===\n")
	_test_route_node()
	_test_route_map_factory()
	_test_route_map_navigation()
	_test_zone_types()
	_test_expedition_state_additions()
	_test_travel_simulator_food_water()
	_test_travel_simulator_ship_wear()
	_test_travel_simulator_burden_fatigue()
	_test_travel_simulator_sickness_risk()
	_test_travel_simulator_exhaustion()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# --- Helpers ---

func _make_zone(consumption: float = 1.0, wear: float = 1.0, burden_delta: int = 0) -> ZoneTypeDef:
	var z = ZoneTypeDef.new()
	z.consumption_modifier = consumption
	z.ship_wear_modifier = wear
	z.burden_delta_per_tick = burden_delta
	return z


func _make_state():
	return ExpeditionState.create_default()


func _make_log():
	return SimulationLog.new()


# --- RouteNode ---

func _test_route_node() -> void:
	print("-- RouteNode --")

	var n = RouteNode.new()
	check(n.id == "", "id default empty")
	check(n.category == "", "category default empty")
	check(n.tick_distance == 0, "tick_distance default 0")
	check(n.zone_type_id == "", "zone_type_id default empty")
	check(n.hints.is_empty(), "hints default empty")
	check(n.is_objective_node == false, "is_objective_node default false")
	check(n.required_node_category == "", "required_node_category default empty")

	var node = RouteNode.make("stage1_crisis", "crisis", 3, "coastal")
	check(node.id == "stage1_crisis", "make() sets id")
	check(node.category == "crisis", "make() sets category")
	check(node.tick_distance == 3, "make() sets tick_distance")
	check(node.zone_type_id == "coastal", "make() sets zone_type_id")
	check(node.hints.is_empty(), "make() hints default empty")
	check(node.is_objective_node == false, "make() is_objective_node default false")
	check(node.required_node_category == "", "make() required_node_category default empty")

	var node2 = RouteNode.make(
		"stage3_admiralty", "admiralty", 4, "open_ocean",
		["Survey coordinates confirmed."], true, "admiralty"
	)
	check(node2.hints.size() == 1, "make() hints populated")
	check(node2.hints[0] == "Survey coordinates confirmed.", "make() hint content correct")
	check(node2.is_objective_node == true, "make() is_objective_node set")
	check(node2.required_node_category == "admiralty", "make() required_node_category set")


# --- RouteMap factory ---

func _test_route_map_factory() -> void:
	print("-- RouteMap factory --")

	var map = RouteMap.create_test_map()
	check(map.stages.size() == 4, "test map has 4 stages")
	check(map.current_stage_index == 0, "starts at stage 0")
	check(map.selected_path.is_empty(), "selected_path starts empty")
	check(map.active_node == null, "active_node starts null")
	check(map.ticks_remaining == 0, "ticks_remaining starts 0")

	# Stage 1 — 3 nodes, all coastal
	var s1: Array = map.stages[0]
	check(s1.size() == 3, "stage 1 has 3 nodes")
	check(s1[0].id == "stage1_crisis",   "stage1 node 0 id")
	check(s1[0].category == "crisis",    "stage1 node 0 category")
	check(s1[0].tick_distance == 3,      "stage1 node 0 tick_distance")
	check(s1[0].zone_type_id == "coastal", "stage1 node 0 zone")
	check(s1[1].id == "stage1_landfall", "stage1 node 1 id")
	check(s1[2].id == "stage1_omen",     "stage1 node 2 id")

	# Stage 2 — 2 nodes, open_ocean
	var s2: Array = map.stages[1]
	check(s2.size() == 2, "stage 2 has 2 nodes")
	check(s2[0].zone_type_id == "open_ocean", "stage2 node 0 zone")
	check(s2[1].zone_type_id == "open_ocean", "stage2 node 1 zone")

	# Stage 3 — boon (lee_shore) + admiralty (open_ocean), admiralty is objective
	var s3: Array = map.stages[2]
	check(s3.size() == 2, "stage 3 has 2 nodes")
	check(s3[0].zone_type_id == "lee_shore",  "stage3 boon zone is lee_shore")
	check(s3[1].zone_type_id == "open_ocean", "stage3 admiralty zone is open_ocean")
	check(s3[1].is_objective_node == true,     "stage3 admiralty is objective node")

	# Stage 4 — 2 nodes, unknown_zone
	var s4: Array = map.stages[3]
	check(s4.size() == 2, "stage 4 has 2 nodes")
	check(s4[0].zone_type_id == "unknown_zone", "stage4 node 0 zone")
	check(s4[1].zone_type_id == "unknown_zone", "stage4 node 1 zone")

	# All 7 categories present
	var all_categories: Array = []
	for stage in map.stages:
		for node in stage:
			if node.category not in all_categories:
				all_categories.append(node.category)
	for cat in ["crisis", "landfall", "omen", "social", "unknown", "boon", "admiralty"]:
		check(cat in all_categories, "category present: %s" % cat)

	# All 4 zone types present
	var all_zones: Array = []
	for stage in map.stages:
		for node in stage:
			if node.zone_type_id not in all_zones:
				all_zones.append(node.zone_type_id)
	for zone in ["coastal", "open_ocean", "lee_shore", "unknown_zone"]:
		check(zone in all_zones, "zone type present: %s" % zone)


# --- RouteMap navigation ---

func _test_route_map_navigation() -> void:
	print("-- RouteMap navigation --")

	var map = RouteMap.create_test_map()

	# get_current_stage returns stage 0 nodes
	var stage = map.get_current_stage()
	check(stage.size() == 3, "get_current_stage returns 3 nodes at start")

	# Not travelling, not complete at start
	check(map.is_travelling() == false, "not travelling at start")
	check(map.is_complete() == false, "not complete at start")

	# select_node sets active_node and ticks_remaining
	var node = stage[0]  # stage1_crisis, 3 days
	map.select_node(node)
	check(map.active_node == node, "select_node sets active_node")
	check(map.ticks_remaining == 3, "select_node sets ticks_remaining to 3")
	check(map.is_travelling() == true, "is_travelling true after select_node")

	# advance_tick decrements ticks_remaining
	map.advance_tick()
	check(map.ticks_remaining == 2, "advance_tick decrements to 2")
	check(map.is_travelling() == true, "still travelling at 2")

	map.advance_tick()
	check(map.ticks_remaining == 1, "advance_tick decrements to 1")

	# Final tick: arrive
	map.advance_tick()
	check(map.ticks_remaining == 0, "ticks_remaining 0 after arrival")
	check(map.active_node == null, "active_node null after arrival")
	check(map.selected_path.size() == 1, "selected_path has 1 entry after first arrival")
	check(map.selected_path[0].id == "stage1_crisis", "selected_path[0] is stage1_crisis")
	check(map.current_stage_index == 1, "current_stage_index advanced to 1")
	check(map.is_travelling() == false, "not travelling after arrival")
	check(map.is_complete() == false, "not complete after stage 1")

	# get_current_stage now returns stage 1 (index 1)
	var stage2 = map.get_current_stage()
	check(stage2.size() == 2, "stage 2 has 2 nodes")

	# get_active_zone returns null when not travelling
	var zone = map.get_active_zone()
	check(zone == null, "get_active_zone null when not travelling")

	# Travel through all remaining stages to reach completion
	for i in range(3):
		var s = map.get_current_stage()
		map.select_node(s[0])
		for _t in range(s[0].tick_distance):
			map.advance_tick()

	check(map.is_complete() == true, "is_complete after all 4 stages")
	check(map.selected_path.size() == 4, "selected_path has 4 entries")
	check(map.get_current_stage().is_empty(), "get_current_stage empty when complete")

	# advance_tick is a no-op when not travelling
	map.advance_tick()
	check(map.ticks_remaining == 0, "advance_tick no-op when not travelling")


# --- Zone types ---

func _test_zone_types() -> void:
	print("-- Zone types --")

	var lee = ContentRegistry.get_by_id("zone_types", "lee_shore") as ZoneTypeDef
	check(lee != null, "lee_shore loads from ContentRegistry")
	check(lee.id == "lee_shore", "lee_shore id correct")
	check(lee.display_name == "Lee Shore", "lee_shore display_name correct")
	check(lee.category == "hazard", "lee_shore category is hazard")
	check(is_equal_approx(lee.consumption_modifier, 1.0), "lee_shore consumption_modifier 1.0")
	check(is_equal_approx(lee.ship_wear_modifier, 1.8), "lee_shore ship_wear_modifier 1.8")
	check(lee.burden_delta_per_tick == 1, "lee_shore burden_delta_per_tick 1")
	check(is_equal_approx(lee.incident_weight_modifier, 1.4), "lee_shore incident_weight_modifier 1.4")
	check("storm" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has storm")
	check("navigation" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has navigation")
	check("crisis" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has crisis")

	var unk = ContentRegistry.get_by_id("zone_types", "unknown_zone") as ZoneTypeDef
	check(unk != null, "unknown_zone loads from ContentRegistry")
	check(unk.id == "unknown_zone", "unknown_zone id correct")
	check(unk.display_name == "Unknown Waters", "unknown_zone display_name correct")
	check(unk.category == "unknown", "unknown_zone category is unknown")
	check(is_equal_approx(unk.consumption_modifier, 1.1), "unknown_zone consumption_modifier 1.1")
	check(is_equal_approx(unk.ship_wear_modifier, 1.3), "unknown_zone ship_wear_modifier 1.3")
	check(unk.burden_delta_per_tick == 2, "unknown_zone burden_delta_per_tick 2")
	check(is_equal_approx(unk.incident_weight_modifier, 2.0), "unknown_zone incident_weight_modifier 2.0")

	var water = ContentRegistry.get_by_id("supplies", "water") as SupplyDef
	check(water != null, "water supply loads from ContentRegistry")
	check(water.id == "water", "water id correct")
	check(water.daily_consumption > 0, "water daily_consumption > 0")
	check(water.critical_threshold > 0, "water critical_threshold > 0")


# --- ExpeditionState additions ---

func _test_expedition_state_additions() -> void:
	print("-- ExpeditionState additions --")

	var state = _make_state()
	check(state.travel_fatigue == 0, "travel_fatigue default 0")
	check(state.sickness_risk == 0, "sickness_risk default 0")
	check(state.pending_incident_id == "", "pending_incident_id default empty")

	# Clamping
	state.travel_fatigue = 200
	state.travel_fatigue = clampi(state.travel_fatigue, 0, 100)
	check(state.travel_fatigue == 100, "travel_fatigue clamped to 100")

	state.sickness_risk = -5
	state.sickness_risk = clampi(state.sickness_risk, 0, 100)
	check(state.sickness_risk == 0, "sickness_risk clamped to 0")


# --- TravelSimulator: food/water consumption ---

func _test_travel_simulator_food_water() -> void:
	print("-- TravelSimulator food/water consumption --")

	var state = _make_state()
	var log = _make_log()
	var zone = _make_zone(1.0)  # consumption_modifier = 1.0

	var food_before := state.get_supply("food")   # 200
	var water_before := state.get_supply("water")  # 150

	TravelSimulator.process_tick(state, zone, log)

	# food: daily_consumption=5, modifier=1.0 → -ceil(5*1.0)=-5
	check(state.get_supply("food") == food_before - 5, "food decreases by 5 with 1.0 modifier")
	# water: daily_consumption=3, modifier=1.0 → -ceil(3*1.0)=-3
	check(state.get_supply("water") == water_before - 3, "water decreases by 3 with 1.0 modifier")

	# Test with consumption_modifier = 1.2 (open_ocean style)
	var state2 = _make_state()
	var log2 = _make_log()
	var zone2 = _make_zone(1.2)  # open_ocean

	var food2_before := state2.get_supply("food")
	var water2_before := state2.get_supply("water")
	TravelSimulator.process_tick(state2, zone2, log2)

	# food: ceil(5*1.2) = ceil(6.0) = 6
	check(state2.get_supply("food") == food2_before - 6, "food decreases by 6 with 1.2 modifier")
	# water: ceil(3*1.2) = ceil(3.6) = 4
	check(state2.get_supply("water") == water2_before - 4, "water decreases by 4 with 1.2 modifier")


# --- TravelSimulator: ship wear ---

func _test_travel_simulator_ship_wear() -> void:
	print("-- TravelSimulator ship wear --")

	# wear_modifier=1.0 → floor(-1*1.0)=-1
	var state = _make_state()
	var log = _make_log()
	TravelSimulator.process_tick(state, _make_zone(1.0, 1.0), log)
	check(state.ship_condition == 99, "ship condition -1 with 1.0 wear modifier")

	# wear_modifier=1.8 → floor(-1*1.8)=floor(-1.8)=-2
	var state2 = _make_state()
	var log2 = _make_log()
	TravelSimulator.process_tick(state2, _make_zone(1.0, 1.8), log2)
	check(state2.ship_condition == 98, "ship condition -2 with 1.8 wear modifier")

	# wear_modifier=0.5 → floor(-0.5)=-1 (minimum -1 applies)
	var state3 = _make_state()
	var log3 = _make_log()
	TravelSimulator.process_tick(state3, _make_zone(1.0, 0.5), log3)
	check(state3.ship_condition == 99, "ship condition -1 with 0.5 wear modifier (minimum)")

	# wear_modifier=0.0 → floor(0)=0, but minimum -1 applies
	var state4 = _make_state()
	var log4 = _make_log()
	TravelSimulator.process_tick(state4, _make_zone(1.0, 0.0), log4)
	check(state4.ship_condition == 99, "ship condition -1 with 0.0 wear modifier (minimum enforced)")


# --- TravelSimulator: burden delta + travel fatigue ---

func _test_travel_simulator_burden_fatigue() -> void:
	print("-- TravelSimulator burden delta + fatigue --")

	# burden_delta_per_tick=2 → burden increases by 2
	var state = _make_state()
	var log = _make_log()
	var burden_before: int = state.burden  # 20
	TravelSimulator.process_tick(state, _make_zone(1.0, 1.0, 2), log)
	check(state.burden == burden_before + 2, "burden increases by zone burden_delta_per_tick")

	# burden_delta_per_tick=0 → burden unchanged by zone
	var state2 = _make_state()
	var log2 = _make_log()
	var burden2_before: int = state2.burden
	TravelSimulator.process_tick(state2, _make_zone(1.0, 1.0, 0), log2)
	check(state2.burden == burden2_before, "burden unchanged when burden_delta_per_tick is 0")

	# travel_fatigue increments each tick, clamped to 100
	var state3 = _make_state()
	var log3 = _make_log()
	check(state3.travel_fatigue == 0, "fatigue starts at 0")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 1, "fatigue increments to 1 after first tick")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 2, "fatigue increments to 2 after second tick")

	# Fatigue clamped at 100
	state3.travel_fatigue = 99
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 100, "fatigue reaches 100")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 100, "fatigue stays at 100 (clamped)")


# --- TravelSimulator: sickness risk ---

func _test_travel_simulator_sickness_risk() -> void:
	print("-- TravelSimulator sickness risk --")

	# Supplies above critical → sickness_risk decays (0 stays 0)
	var state = _make_state()  # food=200 (>15 critical), water=150 (>15 critical)
	var log = _make_log()
	check(state.sickness_risk == 0, "sickness_risk starts 0")
	TravelSimulator.process_tick(state, _make_zone(), log)
	check(state.sickness_risk == 0, "sickness_risk stays 0 when supplies healthy")

	# Set sickness_risk to 5, decay by 1 when supplies healthy
	state.sickness_risk = 5
	TravelSimulator.process_tick(state, _make_zone(), log)
	check(state.sickness_risk == 4, "sickness_risk decays by 1 when supplies healthy")

	# Set food below critical_threshold (15) → sickness rises
	var state2 = _make_state()
	var log2 = _make_log()
	state2.set_supply("food", 5)  # below critical_threshold=15
	TravelSimulator.process_tick(state2, _make_zone(), log2)
	check(state2.sickness_risk == 3, "sickness_risk rises by 3 when food below critical")

	# Set water below critical_threshold (15) → sickness rises
	var state3 = _make_state()
	var log3 = _make_log()
	state3.set_supply("water", 5)  # below critical_threshold=15
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.sickness_risk == 3, "sickness_risk rises by 3 when water below critical")

	# Sickness risk clamped at 100
	var state4 = _make_state()
	var log4 = _make_log()
	state4.sickness_risk = 99
	state4.set_supply("food", 5)
	TravelSimulator.process_tick(state4, _make_zone(), log4)
	check(state4.sickness_risk == 100, "sickness_risk clamped to 100")


# --- TravelSimulator: supply exhaustion ---

func _test_travel_simulator_exhaustion() -> void:
	print("-- TravelSimulator supply exhaustion --")

	# Food hits 0 → Burden +6, memory flag food_exhausted
	var state = _make_state()
	var log = _make_log()
	state.set_supply("food", 1)  # ceil(5 * 1.0) = 5 consumed, so 1 → clamped to 0
	var burden_before: int = state.burden
	TravelSimulator.process_tick(state, _make_zone(1.0), log)
	check(state.get_supply("food") == 0, "food hits 0")
	check(state.burden == burden_before + 6, "food exhaustion adds Burden +6")
	check(state.has_memory_flag("food_exhausted"), "food_exhausted memory flag set")

	# Food already at 0 before tick → no extra exhaustion spike
	var state2 = _make_state()
	var log2 = _make_log()
	state2.set_supply("food", 0)
	var burden2_before: int = state2.burden
	TravelSimulator.process_tick(state2, _make_zone(1.0), log2)
	check(not state2.has_memory_flag("food_exhausted"), "no exhaustion flag when food was already 0")
	check(state2.burden == burden2_before, "no Burden spike when food was already 0")

	# Water hits 0 → Burden +8, memory flag water_exhausted
	var state3 = _make_state()
	var log3 = _make_log()
	state3.set_supply("water", 1)  # ceil(3 * 1.0) = 3 consumed, 1 → 0
	var burden3_before: int = state3.burden
	TravelSimulator.process_tick(state3, _make_zone(1.0), log3)
	check(state3.get_supply("water") == 0, "water hits 0")
	check(state3.burden == burden3_before + 8, "water exhaustion adds Burden +8")
	check(state3.has_memory_flag("water_exhausted"), "water_exhausted memory flag set")
