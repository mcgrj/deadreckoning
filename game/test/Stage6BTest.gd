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
