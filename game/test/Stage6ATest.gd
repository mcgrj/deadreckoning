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
