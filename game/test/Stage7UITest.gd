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
	# LogPanel and RouteMapNode tests added in later tasks
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
