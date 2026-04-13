# TravelSimulator.gd
# Stateless tick processor for expedition travel.
# Applies food/water consumption, ship wear, zone burden, fatigue,
# sickness risk, rum rules, and incident trigger checks each day.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name TravelSimulator


static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void:
	# Step 1: Food consumption
	var food_def = ContentRegistry.get_by_id("supplies", "food") as SupplyDef
	if food_def != null:
		var food_before := state.get_supply(food_def.id)
		var food_effect = EffectDef.new()
		food_effect.type = "supply_change"
		food_effect.delta = -ceili(food_def.daily_consumption * zone.consumption_modifier)
		food_effect.target_id = food_def.id
		EffectProcessor.apply(state, food_effect, log)
		if food_before > 0 and state.get_supply(food_def.id) == 0:
			var b = EffectDef.new()
			b.type = "burden_change"
			b.delta = 6
			EffectProcessor.apply(state, b, log)
			var f = EffectDef.new()
			f.type = "set_memory_flag"
			f.flag_key = "food_exhausted"
			EffectProcessor.apply(state, f, log)

	# Step 2: Water consumption
	var water_def = ContentRegistry.get_by_id("supplies", "water") as SupplyDef
	if water_def != null:
		var water_before := state.get_supply(water_def.id)
		var water_effect = EffectDef.new()
		water_effect.type = "supply_change"
		water_effect.delta = -ceili(water_def.daily_consumption * zone.consumption_modifier)
		water_effect.target_id = water_def.id
		EffectProcessor.apply(state, water_effect, log)
		if water_before > 0 and state.get_supply(water_def.id) == 0:
			var b = EffectDef.new()
			b.type = "burden_change"
			b.delta = 8
			EffectProcessor.apply(state, b, log)
			var f = EffectDef.new()
			f.type = "set_memory_flag"
			f.flag_key = "water_exhausted"
			EffectProcessor.apply(state, f, log)

	# Step 3: Ship wear
	var wear_delta := mini(floori(-1.0 * zone.ship_wear_modifier), -1)
	var wear_effect = EffectDef.new()
	wear_effect.type = "ship_condition_change"
	wear_effect.delta = wear_delta
	EffectProcessor.apply(state, wear_effect, log)

	# Step 4: Zone Burden delta
	if zone.burden_delta_per_tick != 0:
		var zone_burden = EffectDef.new()
		zone_burden.type = "burden_change"
		zone_burden.delta = zone.burden_delta_per_tick
		EffectProcessor.apply(state, zone_burden, log)

	# Step 5: Travel fatigue
	state.travel_fatigue = clampi(state.travel_fatigue + 1, 0, 100)
	log.log_event(state.tick_count, "TravelSimulator",
		"Travel fatigue: %d" % state.travel_fatigue,
		{"travel_fatigue": state.travel_fatigue})

	# Step 6: Sickness risk
	var food_amount := state.get_supply("food")
	var water_amount := state.get_supply("water")
	var food_critical := food_def.critical_threshold if food_def != null else 0
	var water_critical := water_def.critical_threshold if water_def != null else 0
	if food_amount < food_critical or water_amount < water_critical:
		state.sickness_risk = clampi(state.sickness_risk + 3, 0, 100)
	else:
		state.sickness_risk = clampi(state.sickness_risk - 1, 0, 100)
	log.log_event(state.tick_count, "TravelSimulator",
		"Sickness risk: %d" % state.sickness_risk,
		{"sickness_risk": state.sickness_risk})

	# Steps 7–8 added in Task 8
