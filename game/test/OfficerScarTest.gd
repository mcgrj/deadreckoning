# OfficerScarTest.gd
# Tests for officer scar accumulation in ExpeditionState,
# EffectProcessor add_officer_scar, and ConditionEvaluator officer_has_scar.
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
	print("=== OfficerScarTest ===\n")
	_test_add_and_check_scar()
	_test_scar_not_duplicated()
	_test_effect_processor_add_scar()
	_test_condition_evaluator_officer_has_scar()
	_test_condition_evaluator_officer_has_scar_fail()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_add_and_check_scar() -> void:
	var state := ExpeditionState.new()
	state.add_officer_scar("surgeon", "publicly_overruled")
	check(state.officer_has_scar("surgeon", "publicly_overruled"), "add_officer_scar sets scar")
	check(not state.officer_has_scar("surgeon", "other_scar"), "missing scar returns false")
	check(not state.officer_has_scar("bosun", "publicly_overruled"), "different role returns false")


func _test_scar_not_duplicated() -> void:
	var state := ExpeditionState.new()
	state.add_officer_scar("surgeon", "haunted")
	state.add_officer_scar("surgeon", "haunted")
	check(state.officer_scars.get("surgeon", []).size() == 1, "duplicate scar not added twice")


func _test_effect_processor_add_scar() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	var effect := EffectDef.new()
	effect.type = "add_officer_scar"
	effect.tag = "witnessed_broken_promise"
	effect.target_id = "purser"
	EffectProcessor.apply(state, effect, log)
	check(state.officer_has_scar("purser", "witnessed_broken_promise"), "EffectProcessor add_officer_scar writes to state")


func _test_condition_evaluator_officer_has_scar() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	state.add_officer_scar("bosun", "respects_hard_authority")
	var cond := ConditionDef.new()
	cond.type = "officer_has_scar"
	cond.tag = "respects_hard_authority"
	cond.target_id = "bosun"
	check(ConditionEvaluator.evaluate(state, cond, log), "officer_has_scar condition passes when scar present")


func _test_condition_evaluator_officer_has_scar_fail() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	var cond := ConditionDef.new()
	cond.type = "officer_has_scar"
	cond.tag = "haunted"
	cond.target_id = "chaplain"
	check(not ConditionEvaluator.evaluate(state, cond, log), "officer_has_scar condition fails when scar absent")
