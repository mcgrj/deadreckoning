# RumRules.gd
# Special-case Rum tick logic. Handles ration consumption, ration-withheld fallout,
# rum exhaustion, theft risk, and drunkenness risk.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name RumRules

static var _rum_id: String = ""
static var _rum_id_cached: bool = false


static func _get_rum_id() -> String:
	if _rum_id_cached:
		return _rum_id
	_rum_id_cached = true
	var supply_defs := ContentRegistry.get_all("supplies")
	for def: ContentBase in supply_defs:
		var supply_def: SupplyDef = def as SupplyDef
		if supply_def and supply_def.is_rum:
			_rum_id = supply_def.id
			return _rum_id
	return ""


static func update_on_tick(state: ExpeditionState, log: SimulationLog) -> void:
	var rum_id := _get_rum_id()
	if rum_id.is_empty():
		return

	var rum_amount := state.get_supply(rum_id)

	# Ration consumption
	if rum_amount > 0 and state.rum_ration_expected and not state.spirit_store_locked:
		state.set_supply(rum_id, rum_amount - 1)
		state.burden = clampi(state.burden - 1, 0, 100)
		log.log_event(state.tick_count, "RumRules",
			"Rum ration issued. Crew morale steadied. (Rum -1, Burden -1)",
			{"rum_before": rum_amount, "rum_after": state.get_supply(rum_id), "burden": state.burden})

	# Ration withheld (store locked but crew expects it)
	elif rum_amount > 0 and state.rum_ration_expected and state.spirit_store_locked:
		state.burden = clampi(state.burden + 2, 0, 100)
		if state.burden > state.stress_indicators.peak_burden:
			state.stress_indicators.peak_burden = state.burden
		log.log_event(state.tick_count, "RumRules",
			"Rum ration withheld. The crew grumbles. (Burden +2)",
			{"rum_amount": rum_amount, "burden": state.burden})

	# Rum ran out
	elif rum_amount == 0 and state.rum_ration_expected:
		state.burden = clampi(state.burden + 4, 0, 100)
		if state.burden > state.stress_indicators.peak_burden:
			state.stress_indicators.peak_burden = state.burden
		state.rum_ration_expected = false
		state.add_memory_flag("rum_ration_ended")
		log.log_event(state.tick_count, "RumRules",
			"Rum stores exhausted. The crew expected their ration. (Burden +4)",
			{"burden": state.burden})

	# Refresh rum_amount after potential consumption
	rum_amount = state.get_supply(rum_id)

	# Theft risk
	if rum_amount > 0 and not state.spirit_store_locked:
		state.rum_theft_risk = clampi(30 + (100 - state.command) / 2, 0, 100)
	else:
		state.rum_theft_risk = clampi(state.rum_theft_risk - 10, 0, 100)

	# Drunkenness risk
	if rum_amount > 20 and not state.spirit_store_locked:
		state.rum_drunkenness_risk = clampi(20 + rum_amount / 5, 0, 100)
	else:
		state.rum_drunkenness_risk = clampi(state.rum_drunkenness_risk - 10, 0, 100)
