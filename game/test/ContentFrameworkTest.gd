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
	_test_incident_choice_def()
	_test_incident_def()
	_test_supply_def()
	_test_officer_def()
	_test_standing_order_def()
	_test_ship_upgrade_def()
	_test_doctrine_def()
	_test_crew_background_def()
	_test_zone_type_def()
	_test_objective_def()
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


func _test_incident_choice_def() -> void:
	print("-- IncidentChoiceDef --")
	var ic := IncidentChoiceDef.new()
	check(ic != null, "IncidentChoiceDef instantiates")
	check(ic.choice_text == "", "IncidentChoiceDef.choice_text defaults to empty string")
	check(ic.officer_id == "", "IncidentChoiceDef.officer_id defaults to empty string")
	check(ic.required_conditions.is_empty(), "IncidentChoiceDef.required_conditions defaults empty")
	check(ic.immediate_effects.is_empty(), "IncidentChoiceDef.immediate_effects defaults empty")
	check(ic.memory_flags_set.is_empty(), "IncidentChoiceDef.memory_flags_set defaults empty")
	check(ic.log_text == "", "IncidentChoiceDef.log_text defaults to empty string")

	var effect := EffectDef.new()
	effect.type = "burden_change"
	effect.delta = 3
	ic.choice_text = "Make an example of the thief."
	ic.officer_id = "bosun"
	ic.immediate_effects = [effect]
	ic.memory_flags_set = ["thief_punished"]
	ic.log_text = "The bosun's lash is heard across the deck."
	check(ic.choice_text == "Make an example of the thief.", "IncidentChoiceDef.choice_text round-trips")
	check(ic.officer_id == "bosun", "IncidentChoiceDef.officer_id round-trips")
	check(ic.immediate_effects.size() == 1, "IncidentChoiceDef.immediate_effects round-trips")
	check(ic.memory_flags_set == ["thief_punished"], "IncidentChoiceDef.memory_flags_set round-trips")
	check(ic.log_text == "The bosun's lash is heard across the deck.", "IncidentChoiceDef.log_text round-trips")

	var cond := ConditionDef.new()
	cond.type = "burden_above"
	ic.required_conditions = [cond]
	check(ic.required_conditions.size() == 1, "IncidentChoiceDef.required_conditions round-trips")


func _test_incident_def() -> void:
	print("-- IncidentDef --")
	var inc := IncidentDef.new()
	check(inc != null, "IncidentDef instantiates")
	check(inc is ContentBase, "IncidentDef extends ContentBase")
	check(inc.trigger_band == "", "IncidentDef.trigger_band defaults to empty string")
	check(inc.required_conditions.is_empty(), "IncidentDef.required_conditions defaults empty")
	check(inc.amplifier_conditions.is_empty(), "IncidentDef.amplifier_conditions defaults empty")
	check(inc.cast_roles.is_empty(), "IncidentDef.cast_roles defaults empty")
	check(inc.eligible_zone_tags.is_empty(), "IncidentDef.eligible_zone_tags defaults empty")
	check(inc.suppressed_zone_tags.is_empty(), "IncidentDef.suppressed_zone_tags defaults empty")
	check(inc.standing_order_interactions.is_empty(), "IncidentDef.standing_order_interactions defaults empty")
	check(inc.choices.is_empty(), "IncidentDef.choices defaults empty")
	check(inc.log_text_template == "", "IncidentDef.log_text_template defaults to empty string")

	inc.id = "drunk_purser"
	inc.trigger_band = "tick"
	var cond := ConditionDef.new()
	cond.type = "has_crew_trait"
	cond.tag = "drunk_purser_present"
	inc.required_conditions = [cond]
	inc.cast_roles = ["purser", "bosun"]
	check(inc.id == "drunk_purser", "IncidentDef.id round-trips")
	check(inc.trigger_band == "tick", "IncidentDef.trigger_band round-trips")
	check(inc.required_conditions.size() == 1, "IncidentDef.required_conditions round-trips")
	check(inc.cast_roles == ["purser", "bosun"], "IncidentDef.cast_roles round-trips")


func _test_supply_def() -> void:
	print("-- SupplyDef --")
	var s := SupplyDef.new()
	check(s != null, "SupplyDef instantiates")
	check(s is ContentBase, "SupplyDef extends ContentBase")
	check(s.is_rum == false, "SupplyDef.is_rum defaults to false")
	check(s.starting_amount == 0, "SupplyDef.starting_amount defaults to 0")
	check(s.daily_consumption == 0, "SupplyDef.daily_consumption defaults to 0")
	check(s.low_threshold == 0, "SupplyDef.low_threshold defaults to 0")
	check(s.critical_threshold == 0, "SupplyDef.critical_threshold defaults to 0")
	s.id = "rum"
	s.is_rum = true
	s.starting_amount = 100
	s.daily_consumption = 2
	s.low_threshold = 20
	s.critical_threshold = 5
	check(s.is_rum == true, "SupplyDef.is_rum round-trips")
	check(s.starting_amount == 100, "SupplyDef.starting_amount round-trips")
	check(s.daily_consumption == 2, "SupplyDef.daily_consumption round-trips")
	check(s.low_threshold == 20, "SupplyDef.low_threshold round-trips")
	check(s.critical_threshold == 5, "SupplyDef.critical_threshold round-trips")


func _test_officer_def() -> void:
	print("-- OfficerDef --")
	var o := OfficerDef.new()
	check(o != null, "OfficerDef instantiates")
	check(o is ContentBase, "OfficerDef extends ContentBase")
	check(o.role == "", "OfficerDef.role defaults to empty string")
	check(o.competence == 0, "OfficerDef.competence defaults to 0")
	check(o.loyalty == 0, "OfficerDef.loyalty defaults to 0")
	check(o.worldview == "", "OfficerDef.worldview defaults to empty string")
	check(o.known_traits.is_empty(), "OfficerDef.known_traits defaults empty")
	check(o.hidden_traits.is_empty(), "OfficerDef.hidden_traits defaults empty")
	check(o.advice_hooks.is_empty(), "OfficerDef.advice_hooks defaults empty")
	o.id = "bosun"
	o.role = "bosun"
	o.competence = 4
	o.loyalty = 3
	o.worldview = "disciplinarian"
	o.known_traits = ["blunt", "reliable"]
	o.hidden_traits = ["brutal_in_private"]
	o.advice_hooks = ["drunk_purser_store_error"]
	check(o.role == "bosun", "OfficerDef.role round-trips")
	check(o.competence == 4, "OfficerDef.competence round-trips")
	check(o.loyalty == 3, "OfficerDef.loyalty round-trips")
	check(o.worldview == "disciplinarian", "OfficerDef.worldview round-trips")
	check(o.known_traits == ["blunt", "reliable"], "OfficerDef.known_traits round-trips")
	check(o.hidden_traits == ["brutal_in_private"], "OfficerDef.hidden_traits round-trips")
	check(o.advice_hooks == ["drunk_purser_store_error"], "OfficerDef.advice_hooks round-trips")


func _test_standing_order_def() -> void:
	print("-- StandingOrderDef --")
	var so := StandingOrderDef.new()
	check(so != null, "StandingOrderDef instantiates")
	check(so is ContentBase, "StandingOrderDef extends ContentBase")
	check(so.command_cost == 0, "StandingOrderDef.command_cost defaults to 0")
	check(so.labor_cost == 0, "StandingOrderDef.labor_cost defaults to 0")
	check(so.supply_cost_type == "", "StandingOrderDef.supply_cost_type defaults to empty string")
	check(so.supply_cost_amount == 0, "StandingOrderDef.supply_cost_amount defaults to 0")
	check(so.forecast_text == "", "StandingOrderDef.forecast_text defaults to empty string")
	check(so.tick_effects.is_empty(), "StandingOrderDef.tick_effects defaults empty")
	check(so.incident_interactions.is_empty(), "StandingOrderDef.incident_interactions defaults empty")
	so.id = "tighten_rationing"
	so.command_cost = 2
	so.labor_cost = 1
	so.supply_cost_type = "food"
	so.supply_cost_amount = 3
	so.forecast_text = "Likely reduces food consumption."
	so.incident_interactions = ["rum_theft", "ration_dispute"]
	var e := EffectDef.new()
	e.type = "burden_change"
	e.delta = 2
	so.tick_effects = [e]
	check(so.command_cost == 2, "StandingOrderDef.command_cost round-trips")
	check(so.labor_cost == 1, "StandingOrderDef.labor_cost round-trips")
	check(so.supply_cost_type == "food", "StandingOrderDef.supply_cost_type round-trips")
	check(so.supply_cost_amount == 3, "StandingOrderDef.supply_cost_amount round-trips")
	check(so.forecast_text == "Likely reduces food consumption.", "StandingOrderDef.forecast_text round-trips")
	check(so.tick_effects.size() == 1, "StandingOrderDef.tick_effects round-trips")
	check(so.incident_interactions.size() == 2, "StandingOrderDef.incident_interactions round-trips")


func _test_ship_upgrade_def() -> void:
	print("-- ShipUpgradeDef --")
	var su := ShipUpgradeDef.new()
	check(su != null, "ShipUpgradeDef instantiates")
	check(su is ContentBase, "ShipUpgradeDef extends ContentBase")
	check(su.preparation_cost == 0, "ShipUpgradeDef.preparation_cost defaults to 0")
	check(su.upgrade_effects.is_empty(), "ShipUpgradeDef.upgrade_effects defaults empty")
	check(su.drawback_text == "", "ShipUpgradeDef.drawback_text defaults to empty string")
	su.id = "reinforced_hull"
	su.preparation_cost = 3
	su.drawback_text = "Heavier — travel ticks are slower."
	var e := EffectDef.new()
	e.type = "ship_condition_change"
	e.delta = 10
	su.upgrade_effects = [e]
	check(su.preparation_cost == 3, "ShipUpgradeDef.preparation_cost round-trips")
	check(su.drawback_text == "Heavier — travel ticks are slower.", "ShipUpgradeDef.drawback_text round-trips")
	check(su.upgrade_effects.size() == 1, "ShipUpgradeDef.upgrade_effects round-trips")


func _test_doctrine_def() -> void:
	print("-- DoctrineDef --")
	var d := DoctrineDef.new()
	check(d != null, "DoctrineDef instantiates")
	check(d is ContentBase, "DoctrineDef extends ContentBase")
	check(d.unlocked_standing_order_ids.is_empty(), "DoctrineDef.unlocked_standing_order_ids defaults empty")
	check(d.command_culture_modifier == "", "DoctrineDef.command_culture_modifier defaults to empty string")
	check(d.description == "", "DoctrineDef.description defaults to empty string")
	d.id = "shared_hardship"
	d.unlocked_standing_order_ids = ["share_officer_comforts", "rotate_sick_off_duty"]
	d.command_culture_modifier = "egalitarian"
	d.description = "Officers share the crew's privations."
	check(d.unlocked_standing_order_ids.size() == 2, "DoctrineDef.unlocked_standing_order_ids round-trips")
	check(d.command_culture_modifier == "egalitarian", "DoctrineDef.command_culture_modifier round-trips")
	check(d.description == "Officers share the crew's privations.", "DoctrineDef.description round-trips")


func _test_crew_background_def() -> void:
	print("-- CrewBackgroundDef --")
	var cb := CrewBackgroundDef.new()
	check(cb != null, "CrewBackgroundDef instantiates")
	check(cb is ContentBase, "CrewBackgroundDef extends ContentBase")
	check(cb.starting_traits.is_empty(), "CrewBackgroundDef.starting_traits defaults empty")
	check(cb.starting_command_modifier == 0, "CrewBackgroundDef.starting_command_modifier defaults to 0")
	check(cb.starting_burden_modifier == 0, "CrewBackgroundDef.starting_burden_modifier defaults to 0")
	check(cb.description == "", "CrewBackgroundDef.description defaults to empty string")
	cb.id = "pressed_crew"
	cb.starting_traits = ["pressed", "resentful"]
	cb.starting_command_modifier = -5
	cb.starting_burden_modifier = 10
	cb.description = "Impressment fills the lower deck cheaply."
	check(cb.starting_traits == ["pressed", "resentful"], "CrewBackgroundDef.starting_traits round-trips")
	check(cb.starting_command_modifier == -5, "CrewBackgroundDef.starting_command_modifier round-trips")
	check(cb.starting_burden_modifier == 10, "CrewBackgroundDef.starting_burden_modifier round-trips")
	check(cb.description == "Impressment fills the lower deck cheaply.", "CrewBackgroundDef.description round-trips")


func _test_zone_type_def() -> void:
	print("-- ZoneTypeDef --")
	var z := ZoneTypeDef.new()
	check(z != null, "ZoneTypeDef instantiates")
	check(z is ContentBase, "ZoneTypeDef extends ContentBase")
	check(is_equal_approx(z.consumption_modifier, 1.0), "ZoneTypeDef.consumption_modifier defaults to 1.0")
	check(is_equal_approx(z.ship_wear_modifier, 1.0), "ZoneTypeDef.ship_wear_modifier defaults to 1.0")
	check(z.burden_delta_per_tick == 0, "ZoneTypeDef.burden_delta_per_tick defaults to 0")
	check(is_equal_approx(z.incident_weight_modifier, 1.0), "ZoneTypeDef.incident_weight_modifier defaults to 1.0")
	check(z.eligible_incident_tags.is_empty(), "ZoneTypeDef.eligible_incident_tags defaults empty")
	check(z.suppressed_incident_tags.is_empty(), "ZoneTypeDef.suppressed_incident_tags defaults empty")
	z.id = "open_ocean"
	z.consumption_modifier = 1.2
	z.ship_wear_modifier = 1.5
	z.burden_delta_per_tick = 1
	z.incident_weight_modifier = 1.2
	z.eligible_incident_tags = ["deep_ocean", "weather"]
	z.suppressed_incident_tags = ["coastal_only"]
	check(is_equal_approx(z.consumption_modifier, 1.2), "ZoneTypeDef.consumption_modifier round-trips")
	check(is_equal_approx(z.ship_wear_modifier, 1.5), "ZoneTypeDef.ship_wear_modifier round-trips")
	check(z.burden_delta_per_tick == 1, "ZoneTypeDef.burden_delta_per_tick round-trips")
	check(is_equal_approx(z.incident_weight_modifier, 1.2), "ZoneTypeDef.incident_weight_modifier round-trips")
	check(z.eligible_incident_tags == ["deep_ocean", "weather"], "ZoneTypeDef.eligible_incident_tags round-trips")
	check(z.suppressed_incident_tags == ["coastal_only"], "ZoneTypeDef.suppressed_incident_tags round-trips")


func _test_objective_def() -> void:
	print("-- ObjectiveDef --")
	var obj := ObjectiveDef.new()
	check(obj != null, "ObjectiveDef instantiates")
	check(obj is ContentBase, "ObjectiveDef extends ContentBase")
	check(obj.objective_type == "", "ObjectiveDef.objective_type defaults to empty string")
	check(obj.difficulty_tier == 0, "ObjectiveDef.difficulty_tier defaults to 0")
	check(obj.required_node_category == "", "ObjectiveDef.required_node_category defaults to empty string")
	check(obj.success_condition == null, "ObjectiveDef.success_condition defaults to null")
	check(obj.unlock_on_success_id == "", "ObjectiveDef.unlock_on_success_id defaults to empty string")
	check(obj.description == "", "ObjectiveDef.description defaults to empty string")
	obj.id = "survey_strange_shore"
	obj.objective_type = "survey"
	obj.difficulty_tier = 2
	obj.required_node_category = "Landfall"
	var cond := ConditionDef.new()
	cond.type = "has_memory_flag"
	cond.flag_key = "strange_shore_surveyed"
	obj.success_condition = cond
	obj.unlock_on_success_id = "better_charts"
	obj.description = "Survey the uncharted shore."
	check(obj.objective_type == "survey", "ObjectiveDef.objective_type round-trips")
	check(obj.difficulty_tier == 2, "ObjectiveDef.difficulty_tier round-trips")
	check(obj.required_node_category == "Landfall", "ObjectiveDef.required_node_category round-trips")
	check(obj.success_condition != null, "ObjectiveDef.success_condition round-trips")
	check(obj.unlock_on_success_id == "better_charts", "ObjectiveDef.unlock_on_success_id round-trips")
	check(obj.description == "Survey the uncharted shore.", "ObjectiveDef.description round-trips")


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
