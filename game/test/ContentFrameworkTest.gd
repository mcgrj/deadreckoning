# ContentFrameworkTest.gd
# Test scene for Stage 1: Content Framework Vertical Slice.
# Run headlessly: godot --headless --path game res://test/ContentFrameworkTest.tscn
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
	print("=== ContentFrameworkTest ===\n")
	_test_content_base()
	_test_effect_def()
	_test_condition_def()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_effect_def() -> void:
	print("-- EffectDef --")
	var e := EffectDef.new()
	check(e != null, "EffectDef instantiates")
	check(e.type == "", "EffectDef.type defaults to empty string")
	check(e.delta == 0, "EffectDef.delta defaults to 0")
	check(e.flag_key == "", "EffectDef.flag_key defaults to empty string")
	check(e.tag == "", "EffectDef.tag defaults to empty string")

	e.type = "burden_change"
	e.delta = -5
	check(e.type == "burden_change", "EffectDef.type round-trips")
	check(e.delta == -5, "EffectDef.delta round-trips")
	e.flag_key = "some_flag"
	e.tag = "some_tag"
	check(e.flag_key == "some_flag", "EffectDef.flag_key round-trips")
	check(e.tag == "some_tag", "EffectDef.tag round-trips")


func _test_condition_def() -> void:
	print("-- ConditionDef --")
	var c := ConditionDef.new()
	check(c != null, "ConditionDef instantiates")
	check(c.type == "", "ConditionDef.type defaults to empty string")
	check(c.threshold == 0, "ConditionDef.threshold defaults to 0")
	check(c.flag_key == "", "ConditionDef.flag_key defaults to empty string")
	check(c.tag == "", "ConditionDef.tag defaults to empty string")

	c.type = "burden_above"
	c.threshold = 60
	c.flag_key = "some_flag"
	c.tag = "some_tag"
	check(c.type == "burden_above", "ConditionDef.type round-trips")
	check(c.threshold == 60, "ConditionDef.threshold round-trips")
	check(c.flag_key == "some_flag", "ConditionDef.flag_key round-trips")
	check(c.tag == "some_tag", "ConditionDef.tag round-trips")


func _test_content_base() -> void:
	print("-- ContentBase --")
	var cb := ContentBase.new()
	check(cb != null, "ContentBase instantiates")
	check(cb.id == "", "ContentBase.id defaults to empty string")
	check(cb.display_name == "", "ContentBase.display_name defaults to empty string")
	check(cb.category == "", "ContentBase.category defaults to empty string")
	check(cb.tags.is_empty(), "ContentBase.tags defaults to empty array")
	check(cb.visibility_rules.is_empty(), "ContentBase.visibility_rules defaults to empty array")
	check(cb.unlock_source == "", "ContentBase.unlock_source defaults to empty string")
	check(is_equal_approx(cb.rarity_weight, 1.0), "ContentBase.rarity_weight defaults to 1.0")

	cb.id = "test_id"
	cb.display_name = "Test Item"
	cb.category = "test"
	cb.tags = ["a", "b"]
	cb.unlock_source = "some_unlock"
	cb.visibility_rules = ["rule_a", "rule_b"]
	cb.rarity_weight = 0.5
	check(cb.id == "test_id", "ContentBase.id round-trips")
	check(cb.display_name == "Test Item", "ContentBase.display_name round-trips")
	check(cb.category == "test", "ContentBase.category round-trips")
	check(cb.tags == ["a", "b"], "ContentBase.tags round-trips")
	check(cb.unlock_source == "some_unlock", "ContentBase.unlock_source round-trips")
	check(cb.visibility_rules == ["rule_a", "rule_b"], "ContentBase.visibility_rules round-trips")
	check(is_equal_approx(cb.rarity_weight, 0.5), "ContentBase.rarity_weight round-trips")
