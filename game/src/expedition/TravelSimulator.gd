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

	# Steps 3–8 added in Tasks 6–8
