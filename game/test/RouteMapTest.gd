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
