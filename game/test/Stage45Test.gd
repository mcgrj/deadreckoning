# Stage45Test.gd
# Headless test suite for Stage 4+5: Standing Orders + Officer Council + Incident Resolution.
# Run: godot --headless --path game res://test/Stage45Test.tscn
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
	print("=== Stage45Test ===\n")
	_test_expedition_state_standing_orders()
	_test_expedition_state_leadership_tags()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_expedition_state_standing_orders() -> void:
	print("-- ExpeditionState.has_standing_order --")
	var state := ExpeditionState.new()
	check(not state.has_standing_order("tighten_rationing"), "has_standing_order returns false when empty")
	state.standing_orders.append("tighten_rationing")
	check(state.has_standing_order("tighten_rationing"), "has_standing_order returns true when present")
	check(not state.has_standing_order("double_watch"), "has_standing_order returns false for absent order")


func _test_expedition_state_leadership_tags() -> void:
	print("-- ExpeditionState.nudge_leadership_tag --")
	var state := ExpeditionState.new()
	check(state.leadership_tags.get("harsh", 0) == 0, "harsh tag starts at 0")
	state.nudge_leadership_tag("harsh")
	check(state.leadership_tags.get("harsh", 0) == 1, "harsh tag increments to 1")
	state.nudge_leadership_tag("harsh")
	check(state.leadership_tags.get("harsh", 0) == 2, "harsh tag increments to 2")
	state.nudge_leadership_tag("authoritarian")
	check(state.leadership_tags.get("authoritarian", 0) == 1, "authoritarian tag works even if not pre-initialized")
