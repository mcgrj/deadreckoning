# GenerateSampleContent.gd
# Temporary tool scene — generates sample .tres content files.
# Run headlessly, then delete this file.
# Do NOT ship this file.
extends Node


func _ready() -> void:
	print("GenerateSampleContent: starting...")
	_create_supplies()
	_create_officers()
	_create_standing_orders()
	_create_upgrades()
	_create_doctrines()
	_create_crew_backgrounds()
	_create_zone_types()
	_create_objectives()
	_create_incidents()
	_create_validation_test_item()
	print("GenerateSampleContent: done.")
	get_tree().quit(0)


func _save(resource: Resource, path: String) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Failed to save " + path + " (error %d)" % err)
	else:
		print("  saved: " + path)


func _create_supplies() -> void:
	var rum := SupplyDef.new()
	rum.id = "rum"
	rum.display_name = "Rum"
	rum.category = "supply"
	rum.tags = ["alcohol", "special"]
	rum.rarity_weight = 1.0
	rum.is_rum = true
	rum.starting_amount = 100
	rum.daily_consumption = 2
	rum.low_threshold = 20
	rum.critical_threshold = 5
	_save(rum, "res://content/supplies/rum.tres")

	var food := SupplyDef.new()
	food.id = "food"
	food.display_name = "Food"
	food.category = "supply"
	food.tags = ["essential"]
	food.rarity_weight = 1.0
	food.is_rum = false
	food.starting_amount = 200
	food.daily_consumption = 5
	food.low_threshold = 40
	food.critical_threshold = 10
	_save(food, "res://content/supplies/food.tres")


func _create_officers() -> void:
	var bosun := OfficerDef.new()
	bosun.id = "bosun"
	bosun.display_name = "The Bosun"
	bosun.category = "officer"
	bosun.tags = ["core_crew"]
	bosun.role = "bosun"
	bosun.competence = 4
	bosun.loyalty = 3
	bosun.worldview = "disciplinarian"
	bosun.known_traits = ["blunt", "reliable"]
	bosun.hidden_traits = []
	bosun.advice_hooks = ["drunk_purser_store_error"]
	_save(bosun, "res://content/officers/bosun.tres")

	var surgeon := OfficerDef.new()
	surgeon.id = "surgeon"
	surgeon.display_name = "The Surgeon"
	surgeon.category = "officer"
	surgeon.tags = ["core_crew"]
	surgeon.role = "surgeon"
	surgeon.competence = 3
	surgeon.loyalty = 4
	surgeon.worldview = "humanitarian"
	surgeon.known_traits = ["cautious", "observant"]
	surgeon.hidden_traits = ["drinks_in_secret"]
	surgeon.advice_hooks = ["drunk_purser_store_error"]
	_save(surgeon, "res://content/officers/surgeon.tres")


func _create_standing_orders() -> void:
	var tighten := StandingOrderDef.new()
	tighten.id = "tighten_rationing"
	tighten.display_name = "Tighten Rationing"
	tighten.category = "logistics"
	tighten.tags = ["supply", "morale_risk"]
	tighten.command_cost = 2
	tighten.labor_cost = 0
	tighten.forecast_text = "Likely reduces food consumption. Crew may resent it."
	tighten.incident_interactions = ["ration_dispute"]
	_save(tighten, "res://content/standing_orders/tighten_rationing.tres")

	var prayer := StandingOrderDef.new()
	prayer.id = "hold_prayer"
	prayer.display_name = "Hold Prayer"
	prayer.category = "morale"
	prayer.tags = ["morale", "omen"]
	prayer.command_cost = 1
	prayer.forecast_text = "Likely reduces Burden for a pious crew. May irritate cynical officers."
	prayer.incident_interactions = ["mermaid_sighting"]
	_save(prayer, "res://content/standing_orders/hold_prayer.tres")


func _create_upgrades() -> void:
	var hull := ShipUpgradeDef.new()
	hull.id = "reinforced_hull"
	hull.display_name = "Reinforced Hull"
	hull.category = "ship"
	hull.tags = ["durability"]
	hull.preparation_cost = 3
	hull.drawback_text = "Heavier — travel ticks consume slightly more food."
	hull.upgrade_effects = []
	_save(hull, "res://content/upgrades/reinforced_hull.tres")


func _create_doctrines() -> void:
	var doctrine := DoctrineDef.new()
	doctrine.id = "shared_hardship"
	doctrine.display_name = "Shared Hardship Doctrine"
	doctrine.category = "doctrine"
	doctrine.tags = ["egalitarian"]
	doctrine.unlocked_standing_order_ids = ["share_officer_comforts", "rotate_sick_off_duty"]
	doctrine.command_culture_modifier = "egalitarian"
	doctrine.description = "Officers share the crew's privations. Earns loyalty; undermines hierarchy."
	_save(doctrine, "res://content/doctrines/shared_hardship.tres")


func _create_crew_backgrounds() -> void:
	var pressed := CrewBackgroundDef.new()
	pressed.id = "pressed_crew"
	pressed.display_name = "Pressed Crew"
	pressed.category = "crew"
	pressed.tags = ["volatile", "cheap"]
	pressed.starting_traits = ["pressed", "resentful", "cheap_labor"]
	pressed.starting_command_modifier = -5
	pressed.starting_burden_modifier = 10
	pressed.description = "Impressment fills the lower deck cheaply. Starts with resentment baked in."
	_save(pressed, "res://content/crew_backgrounds/pressed_crew.tres")


func _create_zone_types() -> void:
	var coastal := ZoneTypeDef.new()
	coastal.id = "coastal"
	coastal.display_name = "Coastal Waters"
	coastal.category = "zone"
	coastal.tags = ["navigable", "safe"]
	coastal.consumption_modifier = 1.0
	coastal.ship_wear_modifier = 0.8
	coastal.burden_delta_per_tick = 0
	coastal.incident_weight_modifier = 0.8
	coastal.suppressed_incident_tags = ["deep_ocean"]
	_save(coastal, "res://content/zone_types/coastal.tres")

	var open_ocean := ZoneTypeDef.new()
	open_ocean.id = "open_ocean"
	open_ocean.display_name = "Open Ocean"
	open_ocean.category = "zone"
	open_ocean.tags = ["exposed", "demanding"]
	open_ocean.consumption_modifier = 1.2
	open_ocean.ship_wear_modifier = 1.5
	open_ocean.burden_delta_per_tick = 1
	open_ocean.incident_weight_modifier = 1.2
	open_ocean.eligible_incident_tags = ["deep_ocean", "weather"]
	_save(open_ocean, "res://content/zone_types/open_ocean.tres")


func _create_objectives() -> void:
	var survey := ObjectiveDef.new()
	survey.id = "survey_strange_shore"
	survey.display_name = "Survey the Strange Shore"
	survey.category = "survey"
	survey.tags = ["admiralty", "tier_2"]
	survey.objective_type = "survey"
	survey.difficulty_tier = 2
	survey.required_node_category = "Landfall"
	var cond := ConditionDef.new()
	cond.type = "has_memory_flag"
	cond.flag_key = "strange_shore_surveyed"
	survey.success_condition = cond
	survey.description = "The Admiralty wishes detailed charts of the uncharted landmass. Make landfall and survey it."
	_save(survey, "res://content/objectives/survey_strange_shore.tres")


func _create_incidents() -> void:
	var punish_effect_cmd := EffectDef.new()
	punish_effect_cmd.type = "command_change"
	punish_effect_cmd.delta = 3
	var punish_effect_burden := EffectDef.new()
	punish_effect_burden.type = "burden_change"
	punish_effect_burden.delta = -2

	var punish_choice := IncidentChoiceDef.new()
	punish_choice.choice_text = "Hold the purser accountable. Order a public audit."
	punish_choice.officer_id = "bosun"
	punish_choice.immediate_effects = [punish_effect_cmd, punish_effect_burden]
	punish_choice.memory_flags_set = ["purser_exposed"]
	punish_choice.log_text = "The purser's error is announced. Command steadies, but the humiliation will not be forgotten."

	var cover_effect := EffectDef.new()
	cover_effect.type = "set_memory_flag"
	cover_effect.flag_key = "purser_error_concealed"

	var cover_choice := IncidentChoiceDef.new()
	cover_choice.choice_text = "Cover the shortfall quietly. Adjust the records."
	cover_choice.immediate_effects = [cover_effect]
	cover_choice.memory_flags_set = ["purser_error_concealed"]
	cover_choice.log_text = "The captain adjusts the ledger. The crew suspects nothing — for now."

	var trigger_cond := ConditionDef.new()
	trigger_cond.type = "has_crew_trait"
	trigger_cond.tag = "rum_aboard"

	var incident := IncidentDef.new()
	incident.id = "drunk_purser_store_error"
	incident.display_name = "The Purser's Error"
	incident.category = "social"
	incident.tags = ["purser", "rum", "supply"]
	incident.trigger_band = "tick"
	incident.required_conditions = [trigger_cond]
	incident.cast_roles = ["purser", "bosun"]
	incident.standing_order_interactions = ["audit_stores"]
	incident.choices = [punish_choice, cover_choice]
	incident.log_text_template = "The purser's count is short. Rum has gone missing from the spirit locker."
	_save(incident, "res://content/incidents/drunk_purser_store_error.tres")


func _create_validation_test_item() -> void:
	# Intentionally invalid — empty id and unknown effect type.
	# Verifies ContentValidator catches errors. Remove before Stage 2.
	var bad_effect := EffectDef.new()
	bad_effect.type = "not_a_real_type"
	var bad_choice := IncidentChoiceDef.new()
	bad_choice.choice_text = "Bad choice"
	bad_choice.immediate_effects = [bad_effect]
	var bad_incident := IncidentDef.new()
	bad_incident.id = ""
	bad_incident.display_name = "Invalid Test Item"
	bad_incident.choices = [bad_choice]
	_save(bad_incident, "res://content/incidents/_test_invalid.tres")
