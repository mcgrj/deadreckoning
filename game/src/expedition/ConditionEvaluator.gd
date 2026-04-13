# ConditionEvaluator.gd
# Stateless utility for evaluating ConditionDefs against an ExpeditionState.
# Every evaluation logs whether it passed or failed and why.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ConditionEvaluator


static func evaluate(state: ExpeditionState, condition: ConditionDef, log: SimulationLog) -> bool:
	var result: bool = false
	var message: String = ""
	var details: Dictionary = {"condition": condition.type, "threshold": condition.threshold}

	match condition.type:
		"burden_above":
			result = state.burden >= condition.threshold
			details["actual"] = state.burden
			message = "Burden %d >= %d? %s" % [state.burden, condition.threshold, "PASS" if result else "FAIL"]

		"burden_below":
			result = state.burden <= condition.threshold
			details["actual"] = state.burden
			message = "Burden %d <= %d? %s" % [state.burden, condition.threshold, "PASS" if result else "FAIL"]

		"command_above":
			result = state.command >= condition.threshold
			details["actual"] = state.command
			message = "Command %d >= %d? %s" % [state.command, condition.threshold, "PASS" if result else "FAIL"]

		"command_below":
			result = state.command <= condition.threshold
			details["actual"] = state.command
			message = "Command %d <= %d? %s" % [state.command, condition.threshold, "PASS" if result else "FAIL"]

		"supply_below":
			var amount := state.get_supply(condition.target_id)
			result = amount <= condition.threshold
			details["actual"] = amount
			details["target"] = condition.target_id
			message = "%s %d <= %d? %s" % [condition.target_id, amount, condition.threshold, "PASS" if result else "FAIL"]

		"has_damage_tag":
			result = state.has_damage_tag(condition.tag)
			details["tag"] = condition.tag
			message = "Has damage tag '%s'? %s" % [condition.tag, "PASS" if result else "FAIL"]

		"has_memory_flag":
			result = state.has_memory_flag(condition.flag_key)
			details["flag"] = condition.flag_key
			message = "Has memory flag '%s'? %s" % [condition.flag_key, "PASS" if result else "FAIL"]

		"has_crew_trait":
			result = state.has_crew_trait(condition.tag)
			details["tag"] = condition.tag
			message = "Has crew trait '%s'? %s" % [condition.tag, "PASS" if result else "FAIL"]

		"officer_present":
			result = state.has_officer(condition.target_id)
			details["target"] = condition.target_id
			message = "Officer '%s' present? %s" % [condition.target_id, "PASS" if result else "FAIL"]

		"zone_type_is":
			# Deferred to Stage 3 — always passes for now
			result = true
			details["tag"] = condition.tag
			message = "Zone type is '%s'? PASS (deferred — always true)" % condition.tag

		_:
			push_warning("ConditionEvaluator: unknown condition type '%s'" % condition.type)
			result = false
			message = "Unknown condition type: %s (FAIL)" % condition.type
			details["error"] = "unknown_type"

	details["passed"] = result
	log.log_condition(state.tick_count, "ConditionEvaluator", message, details)
	return result


static func all_met(state: ExpeditionState, conditions: Array, log: SimulationLog) -> bool:
	var all_passed := true
	for condition: ConditionDef in conditions:
		if not evaluate(state, condition, log):
			all_passed = false
	return all_passed
