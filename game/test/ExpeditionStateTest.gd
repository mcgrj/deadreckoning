# ExpeditionStateTest.gd
# Headless test suite for Stage 2: Expedition State and Simulation Rules.
# Run: godot --headless --path game res://test/ExpeditionStateTest.tscn
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
	print("=== ExpeditionStateTest ===\n")
	_test_simulation_log()
	_test_expedition_state_defaults()
	_test_expedition_state_accessors()
	_test_effect_processor_burden()
	_test_effect_processor_command()
	_test_effect_processor_supply()
	_test_effect_processor_ship_condition()
	_test_effect_processor_tags_and_flags()
	_test_effect_processor_crew_traits()
	_test_effect_processor_batch()
	_test_effect_processor_clamping()
	_test_effect_processor_stress_indicators()
	_test_condition_evaluator_burden_command()
	_test_condition_evaluator_supply()
	_test_condition_evaluator_tags_flags_traits()
	_test_condition_evaluator_officer()
	_test_condition_evaluator_zone_deferred()
	_test_condition_evaluator_all_met()
	_test_rum_rules_ration_consumed()
	_test_rum_rules_ration_withheld()
	_test_rum_rules_rum_ran_out()
	_test_rum_rules_theft_and_drunkenness_risk()
	_test_promise_lifecycle_keep()
	_test_promise_lifecycle_break_on_expiry()
	_test_promise_cannot_double()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# --- Helpers ---

func _make_state():
	return ExpeditionState.create_default()

func _make_log():
	return SimulationLog.new()

func _make_effect(type: String, delta: int = 0, target_id: String = "", flag_key: String = "", tag: String = ""):
	var e = EffectDef.new()
	e.type = type
	e.delta = delta
	e.target_id = target_id
	e.flag_key = flag_key
	e.tag = tag
	return e

func _make_condition(type: String, threshold: int = 0, target_id: String = "", flag_key: String = "", tag: String = ""):
	var c = ConditionDef.new()
	c.type = type
	c.threshold = threshold
	c.target_id = target_id
	c.flag_key = flag_key
	c.tag = tag
	return c


# --- SimulationLog ---

func _test_simulation_log() -> void:
	print("-- SimulationLog --")
	var log = _make_log()
	check(log.get_entries().is_empty(), "Log starts empty")

	log.log_effect(0, "Test", "test effect", {"a": 1})
	check(log.get_entries().size() == 1, "Log has 1 entry after log_effect")
	check(log.get_entries()[0].message == "test effect", "Log entry message correct")
	check(log.get_entries()[0].source == "Test", "Log entry source correct")
	check(log.get_entries()[0].tick == 0, "Log entry tick correct")

	log.log_condition(1, "Test", "test condition", {"b": 2})
	log.log_event(2, "Test", "test event", {"c": 3})
	check(log.get_entries().size() == 3, "Log has 3 entries total")

	var since = log.get_entries_since(1)
	check(since.size() == 2, "get_entries_since(1) returns 2 entries")

	log.clear()
	check(log.get_entries().is_empty(), "Log empty after clear()")


# --- ExpeditionState defaults ---

func _test_expedition_state_defaults() -> void:
	print("-- ExpeditionState defaults --")
	var state = _make_state()
	check(state.burden == 20, "Default burden is 20")
	check(state.command == 70, "Default command is 70")
	check(state.ship_condition == 100, "Default ship condition is 100")
	check(state.tick_count == 0, "Default tick count is 0")
	check(state.damage_tags.is_empty(), "Default damage tags empty")
	check(state.memory_flags.is_empty(), "Default memory flags empty")
	check(state.active_promise.is_empty(), "Default promise empty")

	# Supplies populated from ContentRegistry
	check(state.supplies.has("rum"), "Supplies include rum")
	check(state.supplies.has("food"), "Supplies include food")
	check(state.supplies["rum"] == 100, "Rum starting amount is 100")

	# Officers are no longer loaded from ContentRegistry in create_default.
	# They come from the pool via create_from_config. Default state has no officers.
	check(state.officers.is_empty(), "Default state has no officers (pool-driven system)")

	# Rum ration expected when rum starts > 0
	check(state.rum_ration_expected == true, "Rum ration expected when rum > 0")
	check(state.spirit_store_locked == false, "Spirit store unlocked by default")

	# Stress indicators
	check(state.stress_indicators.peak_burden == 20, "peak_burden starts at initial burden")
	check(state.stress_indicators.min_command == 70, "min_command starts at initial command")
	check(state.stress_indicators.crew_losses == 0, "crew_losses starts at 0")
	check(state.stress_indicators.supply_depletions == 0, "supply_depletions starts at 0")


# --- ExpeditionState accessors ---

func _test_expedition_state_accessors() -> void:
	print("-- ExpeditionState accessors --")
	var state = _make_state()

	# Supply get/set with clamping
	state.set_supply("food", 50)
	check(state.get_supply("food") == 50, "set_supply/get_supply works")
	state.set_supply("food", -10)
	check(state.get_supply("food") == 0, "set_supply clamps to 0")
	check(state.get_supply("nonexistent") == 0, "get_supply returns 0 for unknown id")

	# Damage tags idempotency
	state.add_damage_tag("hull_strained")
	check(state.has_damage_tag("hull_strained"), "add/has_damage_tag works")
	state.add_damage_tag("hull_strained")
	check(state.damage_tags.count("hull_strained") == 1, "add_damage_tag is idempotent")
	state.remove_damage_tag("hull_strained")
	check(not state.has_damage_tag("hull_strained"), "remove_damage_tag works")
	state.remove_damage_tag("hull_strained")  # no-op, should not error

	# Memory flags idempotency
	state.add_memory_flag("test_flag")
	check(state.has_memory_flag("test_flag"), "add/has_memory_flag works")
	state.add_memory_flag("test_flag")
	check(state.memory_flags.count("test_flag") == 1, "add_memory_flag is idempotent")

	# Crew traits
	state.add_crew_trait("superstitious")
	check(state.has_crew_trait("superstitious"), "add/has_crew_trait works")
	state.add_crew_trait("superstitious")
	check(state.crew_traits.count("superstitious") == 1, "add_crew_trait is idempotent")
	state.remove_crew_trait("superstitious")
	check(not state.has_crew_trait("superstitious"), "remove_crew_trait works")

	# Officer check — manually add to state (officers no longer auto-loaded from ContentRegistry)
	state.officers.append("bosun")
	check(state.has_officer("bosun"), "has_officer works for present officer")
	check(not state.has_officer("navigator"), "has_officer returns false for absent officer")


# --- EffectProcessor ---

func _test_effect_processor_burden() -> void:
	print("-- EffectProcessor: burden_change --")
	var state = _make_state()
	var log = _make_log()
	var e = _make_effect("burden_change", 10)
	EffectProcessor.apply(state, e, log)
	check(state.burden == 30, "Burden increased by 10 (20 → 30)")
	check(log.get_entries().size() == 1, "Log entry written")
	check(log.get_entries()[0].details.before == 20, "Log records before value")
	check(log.get_entries()[0].details.after == 30, "Log records after value")


func _test_effect_processor_command() -> void:
	print("-- EffectProcessor: command_change --")
	var state = _make_state()
	var log = _make_log()
	var e = _make_effect("command_change", -15)
	EffectProcessor.apply(state, e, log)
	check(state.command == 55, "Command decreased by 15 (70 → 55)")
	check(state.stress_indicators.min_command == 55, "min_command updated")


func _test_effect_processor_supply() -> void:
	print("-- EffectProcessor: supply_change --")
	var state = _make_state()
	var log = _make_log()
	var e = _make_effect("supply_change", -3, "food")
	EffectProcessor.apply(state, e, log)
	var food_after = state.get_supply("food")
	# Food starting amount from .tres is expected; verify it decreased by 3
	check(log.get_entries()[0].details.target == "food", "Log records target supply")
	check(log.get_entries()[0].details.delta == -3, "Log records delta")


func _test_effect_processor_ship_condition() -> void:
	print("-- EffectProcessor: ship_condition_change --")
	var state = _make_state()
	var log = _make_log()
	var e = _make_effect("ship_condition_change", -20)
	EffectProcessor.apply(state, e, log)
	check(state.ship_condition == 80, "Ship condition decreased by 20 (100 → 80)")


func _test_effect_processor_tags_and_flags() -> void:
	print("-- EffectProcessor: damage tags and memory flags --")
	var state = _make_state()
	var log = _make_log()

	var add_tag = _make_effect("add_damage_tag", 0, "", "", "hull_strained")
	EffectProcessor.apply(state, add_tag, log)
	check(state.has_damage_tag("hull_strained"), "add_damage_tag effect works")

	var remove_tag = _make_effect("remove_damage_tag", 0, "", "", "hull_strained")
	EffectProcessor.apply(state, remove_tag, log)
	check(not state.has_damage_tag("hull_strained"), "remove_damage_tag effect works")

	var set_flag = EffectDef.new()
	set_flag.type = "set_memory_flag"
	set_flag.flag_key = "test_event"
	EffectProcessor.apply(state, set_flag, log)
	check(state.has_memory_flag("test_event"), "set_memory_flag effect works")


func _test_effect_processor_crew_traits() -> void:
	print("-- EffectProcessor: crew traits --")
	var state = _make_state()
	var log = _make_log()

	var add_trait = _make_effect("add_crew_trait", 0, "", "", "superstitious")
	EffectProcessor.apply(state, add_trait, log)
	check(state.has_crew_trait("superstitious"), "add_crew_trait effect works")

	var remove_trait = _make_effect("remove_crew_trait", 0, "", "", "superstitious")
	EffectProcessor.apply(state, remove_trait, log)
	check(not state.has_crew_trait("superstitious"), "remove_crew_trait effect works")


func _test_effect_processor_batch() -> void:
	print("-- EffectProcessor: batch --")
	var state = _make_state()
	var log = _make_log()
	var effects: Array = [
		_make_effect("burden_change", 5),
		_make_effect("command_change", -10),
		_make_effect("ship_condition_change", -5),
	]
	EffectProcessor.apply_effects(state, effects, log)
	check(state.burden == 25, "Batch: burden 20+5=25")
	check(state.command == 60, "Batch: command 70-10=60")
	check(state.ship_condition == 95, "Batch: ship condition 100-5=95")
	check(log.get_entries().size() == 3, "Batch: 3 log entries")


func _test_effect_processor_clamping() -> void:
	print("-- EffectProcessor: clamping --")
	var state = _make_state()
	var log = _make_log()

	EffectProcessor.apply(state, _make_effect("burden_change", 200), log)
	check(state.burden == 100, "Burden clamped to 100")
	EffectProcessor.apply(state, _make_effect("burden_change", -200), log)
	check(state.burden == 0, "Burden clamped to 0")
	EffectProcessor.apply(state, _make_effect("command_change", 200), log)
	check(state.command == 100, "Command clamped to 100")
	EffectProcessor.apply(state, _make_effect("command_change", -200), log)
	check(state.command == 0, "Command clamped to 0")
	EffectProcessor.apply(state, _make_effect("ship_condition_change", -200), log)
	check(state.ship_condition == 0, "Ship condition clamped to 0")
	state.set_supply("food", 5)
	EffectProcessor.apply(state, _make_effect("supply_change", -100, "food"), log)
	check(state.get_supply("food") == 0, "Supply clamped to 0")


func _test_effect_processor_stress_indicators() -> void:
	print("-- EffectProcessor: stress indicators --")
	var state = _make_state()
	var log = _make_log()

	EffectProcessor.apply(state, _make_effect("burden_change", 30), log)
	check(state.stress_indicators.peak_burden == 50, "peak_burden updated to 50")
	EffectProcessor.apply(state, _make_effect("burden_change", -10), log)
	check(state.stress_indicators.peak_burden == 50, "peak_burden stays at 50 after decrease")

	EffectProcessor.apply(state, _make_effect("command_change", -20), log)
	check(state.stress_indicators.min_command == 50, "min_command updated to 50")
	EffectProcessor.apply(state, _make_effect("command_change", 10), log)
	check(state.stress_indicators.min_command == 50, "min_command stays at 50 after increase")

	state.set_supply("food", 1)
	EffectProcessor.apply(state, _make_effect("supply_change", -1, "food"), log)
	check(state.stress_indicators.supply_depletions == 1, "supply_depletions incremented when food hits 0")


# --- ConditionEvaluator ---

func _test_condition_evaluator_burden_command() -> void:
	print("-- ConditionEvaluator: burden/command --")
	var state = _make_state()
	var log = _make_log()

	check(ConditionEvaluator.evaluate(state, _make_condition("burden_above", 10), log) == true, "burden_above 10: PASS (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_above", 30), log) == false, "burden_above 30: FAIL (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_below", 30), log) == true, "burden_below 30: PASS (burden=20)")
	check(ConditionEvaluator.evaluate(state, _make_condition("burden_below", 10), log) == false, "burden_below 10: FAIL (burden=20)")

	check(ConditionEvaluator.evaluate(state, _make_condition("command_above", 50), log) == true, "command_above 50: PASS (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_above", 80), log) == false, "command_above 80: FAIL (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_below", 80), log) == true, "command_below 80: PASS (command=70)")
	check(ConditionEvaluator.evaluate(state, _make_condition("command_below", 50), log) == false, "command_below 50: FAIL (command=70)")


func _test_condition_evaluator_supply() -> void:
	print("-- ConditionEvaluator: supply_below --")
	var state = _make_state()
	var log = _make_log()
	state.set_supply("food", 5)
	check(ConditionEvaluator.evaluate(state, _make_condition("supply_below", 10, "food"), log) == true, "supply_below 10 food=5: PASS")
	check(ConditionEvaluator.evaluate(state, _make_condition("supply_below", 3, "food"), log) == false, "supply_below 3 food=5: FAIL")


func _test_condition_evaluator_tags_flags_traits() -> void:
	print("-- ConditionEvaluator: tags, flags, traits --")
	var state = _make_state()
	var log = _make_log()

	check(ConditionEvaluator.evaluate(state, _make_condition("has_damage_tag", 0, "", "", "hull_strained"), log) == false, "has_damage_tag: FAIL (absent)")
	state.add_damage_tag("hull_strained")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_damage_tag", 0, "", "", "hull_strained"), log) == true, "has_damage_tag: PASS (present)")

	check(ConditionEvaluator.evaluate(state, _make_condition("has_memory_flag", 0, "", "test_flag"), log) == false, "has_memory_flag: FAIL (absent)")
	state.add_memory_flag("test_flag")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_memory_flag", 0, "", "test_flag"), log) == true, "has_memory_flag: PASS (present)")

	check(ConditionEvaluator.evaluate(state, _make_condition("has_crew_trait", 0, "", "", "superstitious"), log) == false, "has_crew_trait: FAIL (absent)")
	state.add_crew_trait("superstitious")
	check(ConditionEvaluator.evaluate(state, _make_condition("has_crew_trait", 0, "", "", "superstitious"), log) == true, "has_crew_trait: PASS (present)")


func _test_condition_evaluator_officer() -> void:
	print("-- ConditionEvaluator: officer_present --")
	var state = _make_state()
	var log = _make_log()
	# Officers no longer auto-loaded from ContentRegistry — add manually for this test
	state.officers.append("bosun")
	check(ConditionEvaluator.evaluate(state, _make_condition("officer_present", 0, "bosun"), log) == true, "officer_present bosun: PASS")
	check(ConditionEvaluator.evaluate(state, _make_condition("officer_present", 0, "navigator"), log) == false, "officer_present navigator: FAIL")


func _test_condition_evaluator_zone_deferred() -> void:
	print("-- ConditionEvaluator: zone_type_is (deferred) --")
	var state = _make_state()
	var log = _make_log()
	check(ConditionEvaluator.evaluate(state, _make_condition("zone_type_is", 0, "", "", "coastal"), log) == true, "zone_type_is always PASS (deferred)")


func _test_condition_evaluator_all_met() -> void:
	print("-- ConditionEvaluator: all_met --")
	var state = _make_state()
	var log = _make_log()

	var passing: Array = [
		_make_condition("burden_above", 10),
		_make_condition("command_above", 50),
	]
	check(ConditionEvaluator.all_met(state, passing, log) == true, "all_met: all passing → true")

	var mixed: Array = [
		_make_condition("burden_above", 10),
		_make_condition("burden_above", 50),
	]
	check(ConditionEvaluator.all_met(state, mixed, log) == false, "all_met: one failing → false")


# --- RumRules ---

func _test_rum_rules_ration_consumed() -> void:
	print("-- RumRules: ration consumed --")
	var state = _make_state()
	var log = _make_log()
	var rum_before = state.get_supply("rum")
	var burden_before = state.burden
	RumRules.update_on_tick(state, log)
	check(state.get_supply("rum") == rum_before - 1, "Rum decreased by 1")
	check(state.burden == burden_before - 1, "Burden decreased by 1")


func _test_rum_rules_ration_withheld() -> void:
	print("-- RumRules: ration withheld --")
	var state = _make_state()
	var log = _make_log()
	state.spirit_store_locked = true
	var burden_before = state.burden
	var rum_before = state.get_supply("rum")
	RumRules.update_on_tick(state, log)
	check(state.get_supply("rum") == rum_before, "Rum not consumed when store locked")
	check(state.burden == burden_before + 2, "Burden increased by 2 when ration withheld")


func _test_rum_rules_rum_ran_out() -> void:
	print("-- RumRules: rum ran out --")
	var state = _make_state()
	var log = _make_log()
	state.set_supply("rum", 0)
	var burden_before = state.burden
	RumRules.update_on_tick(state, log)
	check(state.burden == burden_before + 4, "Burden spiked by 4 when rum exhausted")
	check(state.rum_ration_expected == false, "rum_ration_expected set to false")
	check(state.has_memory_flag("rum_ration_ended"), "rum_ration_ended memory flag set")

	var burden_after_first = state.burden
	RumRules.update_on_tick(state, log)
	check(state.burden == burden_after_first, "No burden change on second tick after rum ended")


func _test_rum_rules_theft_and_drunkenness_risk() -> void:
	print("-- RumRules: theft and drunkenness risk --")
	var state = _make_state()
	var log = _make_log()

	state.set_supply("rum", 50)
	state.command = 60
	RumRules.update_on_tick(state, log)
	check(state.rum_theft_risk > 0, "Theft risk > 0 with rum and unlocked store")
	check(state.rum_drunkenness_risk > 0, "Drunkenness risk > 0 with rum > 20")

	state.spirit_store_locked = true
	state.rum_ration_expected = false
	var theft_before = state.rum_theft_risk
	RumRules.update_on_tick(state, log)
	check(state.rum_theft_risk < theft_before, "Theft risk decays when store locked")


# --- Promise system ---

func _test_promise_lifecycle_keep() -> void:
	print("-- Promise: make → keep --")
	var state = _make_state()
	var log = _make_log()

	var command_before = state.command
	var result = state.make_promise("landfall", "We will make landfall within five days", 5, log)
	check(result == true, "make_promise returns true")
	check(not state.active_promise.is_empty(), "Promise is active")
	check(state.active_promise.id == "landfall", "Promise id correct")
	check(state.active_promise.ticks_remaining == 5, "Promise ticks_remaining correct")
	check(state.command == command_before + 3, "Command +3 on promise made")

	state.tick_promise(log)
	check(state.active_promise.ticks_remaining == 4, "ticks_remaining decremented")

	var command_before_keep = state.command
	var burden_before_keep = state.burden
	state.keep_promise(log)
	check(state.active_promise.is_empty(), "Promise cleared after keeping")
	check(state.command == command_before_keep + 5, "Command +5 on promise kept")
	check(state.burden == burden_before_keep - 3, "Burden -3 on promise kept")
	check(state.has_memory_flag("promise_kept_landfall"), "Memory flag set for kept promise")


func _test_promise_lifecycle_break_on_expiry() -> void:
	print("-- Promise: make → auto-break on expiry --")
	var state = _make_state()
	var log = _make_log()
	state.make_promise("water", "No man will go without water", 2, log)

	state.tick_promise(log)
	check(state.active_promise.ticks_remaining == 1, "1 tick remaining")

	var command_before = state.command
	var burden_before = state.burden
	state.tick_promise(log)
	check(state.active_promise.is_empty(), "Promise auto-broken at expiry")
	check(state.command == command_before - 5, "Command -5 on broken promise")
	check(state.burden == burden_before + 5, "Burden +5 on broken promise")
	check(state.has_memory_flag("promise_broken_water"), "Memory flag set for broken promise")


func _test_promise_cannot_double() -> void:
	print("-- Promise: cannot make while one active --")
	var state = _make_state()
	var log = _make_log()
	state.make_promise("first", "First promise", 5, log)
	var result = state.make_promise("second", "Second promise", 3, log)
	check(result == false, "make_promise returns false when one active")
	check(state.active_promise.id == "first", "Original promise unchanged")
