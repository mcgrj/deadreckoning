# TravelSimulator.gd
# Stateless tick processor for expedition travel.
# Applies food/water consumption, ship wear, zone burden, fatigue,
# sickness risk, rum rules, and incident trigger checks each day.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name TravelSimulator


## Check mutiny and breakdown conditions. Sets state.run_end_reason and returns
## true if the run has ended. Called at the top of process_tick.
static func _check_run_end(state: ExpeditionState, log: SimulationLog) -> bool:
	# Already ended — don't overwrite the reason.
	if state.run_end_reason != "":
		return false

	# Breakdown: burden at maximum — crew is ungovernable.
	if state.burden >= GameConstants.BREAKDOWN_BURDEN_THRESHOLD:
		state.run_end_reason = "breakdown"
		log.log_event(state.tick_count, "RunEnd",
			"Expedition ended: breakdown (burden at maximum).",
			{"reason": "breakdown", "burden": state.burden})
		return true

	# Mutiny: probabilistic when command is critically low.
	if state.command <= GameConstants.MUTINY_COMMAND_THRESHOLD:
		var mutiny_chance: float = (float(state.burden) / 100.0) * GameConstants.MUTINY_BASE_RATE
		if state.has_standing_order("suppress_dissent"):
			mutiny_chance *= 0.5
		if randf() < mutiny_chance:
			state.run_end_reason = "mutiny"
			log.log_event(state.tick_count, "RunEnd",
				"Expedition ended: mutiny (command critically low, chance was %.2f)." % mutiny_chance,
				{"reason": "mutiny", "command": state.command, "burden": state.burden,
				 "chance": mutiny_chance})
			return true

	return false


static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void:
	# Check run-end conditions before any simulation steps.
	if _check_run_end(state, log):
		return

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
	var food_critical: int = food_def.critical_threshold if food_def != null else 0
	var water_critical: int = water_def.critical_threshold if water_def != null else 0
	if food_amount < food_critical or water_amount < water_critical:
		state.sickness_risk = clampi(state.sickness_risk + 3, 0, 100)
	else:
		state.sickness_risk = clampi(state.sickness_risk - 1, 0, 100)
	log.log_event(state.tick_count, "TravelSimulator",
		"Sickness risk: %d" % state.sickness_risk,
		{"sickness_risk": state.sickness_risk})

	# Step 7: Rum tick
	RumRules.update_on_tick(state, log)

	# Step 8: Incident trigger check — weighted random selection from eligible pool
	if state.pending_incident_id.is_empty():
		var incidents := ContentRegistry.get_all("incidents")
		var eligible: Array = []
		var weights: Array = []
		var total_weight: float = 0.0

		for item: ContentBase in incidents:
			var incident := item as IncidentDef
			if incident == null or incident.trigger_band != "tick":
				continue
			if not ConditionEvaluator.all_met(state, incident.required_conditions, log):
				continue
			var w := compute_incident_weight(state, incident, log)
			eligible.append(incident)
			weights.append(w)
			total_weight += w

		if not eligible.is_empty():
			var roll := randf() * total_weight
			var cumulative: float = 0.0
			for i: int in range(eligible.size()):
				cumulative += weights[i]
				if roll <= cumulative:
					state.pending_incident_id = eligible[i].id
					log.log_event(state.tick_count, "TravelSimulator",
						"Incident triggered: %s (weight %.2f)" % [eligible[i].id, weights[i]],
						{"incident_id": eligible[i].id, "weight": weights[i]})
					break


## Compute the selection weight for an incident given current state.
## Applies all weight_modifiers; returns 1.0 if none match.
static func compute_incident_weight(
	state: ExpeditionState,
	incident: IncidentDef,
	log: SimulationLog
) -> float:
	var weight: float = 1.0
	for mod: WeightModifierDef in incident.weight_modifiers:
		var condition_met: bool = false
		match mod.condition_type:
			"has_standing_order":
				condition_met = state.has_standing_order(mod.condition_value)
		if condition_met:
			weight *= mod.multiplier
			log.log_event(state.tick_count, "TravelSimulator",
				"Weight modifier applied to %s: x%.2f (total %.2f)" % [incident.id, mod.multiplier, weight],
				{"incident_id": incident.id, "modifier": mod.multiplier, "weight": weight})
	return weight
