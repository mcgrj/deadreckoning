# Stage7UITest.gd
# Headless test suite for Stage 7: Debug UI Redesign.
# Tests pure-logic helpers extracted from StatsBar, LogPanel, RouteMapNode.
# Run: godot --headless --path game res://test/Stage7UITest.tscn
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
	print("=== Stage7UITest ===\n")
	_test_stats_bar_clock()
	_test_log_panel_colors()
	_test_route_map_node_geometry()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# ── StatsBar ─────────────────────────────────────────────────────────────────

func _test_stats_bar_clock() -> void:
	print("-- StatsBar clock helpers --")
	check(StatsBar._day_from_tick(0) == 1,  "tick 0 → day 1")
	check(StatsBar._day_from_tick(1) == 1,  "tick 1 → day 1")
	check(StatsBar._day_from_tick(2) == 2,  "tick 2 → day 2")
	check(StatsBar._day_from_tick(3) == 2,  "tick 3 → day 2")
	check(StatsBar._day_from_tick(9) == 5,  "tick 9 → day 5")
	check(StatsBar._period_from_tick(0) == "DAWN", "tick 0 → DAWN")
	check(StatsBar._period_from_tick(1) == "DUSK", "tick 1 → DUSK")
	check(StatsBar._period_from_tick(2) == "DAWN", "tick 2 → DAWN")
	check(StatsBar._period_from_tick(7) == "DUSK", "tick 7 → DUSK")


# ── LogPanel ─────────────────────────────────────────────────────────────────

func _test_log_panel_colors() -> void:
	print("-- LogPanel entry colors --")
	var c := LogPanel._entry_colors("IncidentResolution")
	check(c.size() == 2, "entry_colors returns 2 elements")
	# "resolved" type → source color is greenish (#3a6040)
	check(c[0].g > c[0].r, "resolved source color is green-dominant")

	var c2 := LogPanel._entry_colors("RumRules")
	# "warn" type → message color is yellowish (#cc9944)
	check(c2[1].r > c2[1].b, "warn message color is warm")

	var c3 := LogPanel._entry_colors("TravelSimulator")
	# "event" type → source color is blue-grey (#4a6a8a)
	check(c3[0].b > c3[0].r, "event source color is blue-dominant")

	var c4 := LogPanel._entry_colors("EffectProcessor")
	# "effect" type → both colors are dark blue
	check(c4[0].b >= c4[0].r, "effect source color has blue >= red")


# ── RouteMapNode ─────────────────────────────────────────────────────────────

func _test_route_map_node_geometry() -> void:
	print("-- RouteMapNode geometry --")

	# _stage_y: with 4 stages, step = 410/5 = 82 → stage 0 = 408, stage 3 = 162
	var step4 := 410.0 / 5.0
	check(is_equal_approx(RouteMapNode._stage_y(0, 4), 490.0 - step4 * 1), "stage_y(0,4)")
	check(is_equal_approx(RouteMapNode._stage_y(3, 4), 490.0 - step4 * 4), "stage_y(3,4)")

	# _stage_y: with 1 stage, step = 410/2 = 205 → y = 285
	check(is_equal_approx(RouteMapNode._stage_y(0, 1), 285.0), "stage_y(0,1)")

	# _node_x: 1 node → centred at 150
	check(is_equal_approx(RouteMapNode._node_x(0, 1), 150.0), "node_x single centred")

	# _node_x: 2 nodes → 65, 235
	check(is_equal_approx(RouteMapNode._node_x(0, 2), 65.0),  "node_x 2-node left")
	check(is_equal_approx(RouteMapNode._node_x(1, 2), 235.0), "node_x 2-node right")

	# _node_x: 3 nodes → 65, 150, 235
	check(is_equal_approx(RouteMapNode._node_x(0, 3), 65.0),  "node_x 3-node left")
	check(is_equal_approx(RouteMapNode._node_x(1, 3), 150.0), "node_x 3-node centre")
	check(is_equal_approx(RouteMapNode._node_x(2, 3), 235.0), "node_x 3-node right")

	# _bezier_point: t=0 → p0, t=1 → p3
	var p0 := Vector2(0, 0)
	var p1 := Vector2(0, 50)
	var p2 := Vector2(100, 50)
	var p3 := Vector2(100, 100)
	check(RouteMapNode._bezier_point(p0, p1, p2, p3, 0.0).is_equal_approx(p0), "bezier t=0 → p0")
	check(RouteMapNode._bezier_point(p0, p1, p2, p3, 1.0).is_equal_approx(p3), "bezier t=1 → p3")
	var mid := RouteMapNode._bezier_point(p0, p1, p2, p3, 0.5)
	check(mid.x > 0.0 and mid.x < 100.0, "bezier midpoint x in (0,100)")
	check(mid.y > 0.0 and mid.y < 100.0, "bezier midpoint y in (0,100)")
