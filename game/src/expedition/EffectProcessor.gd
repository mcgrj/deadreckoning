# EffectProcessor.gd
# Stateless utility for applying EffectDefs to an ExpeditionState.
# Every application writes an explanation entry to SimulationLog.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name EffectProcessor


static func apply(state: ExpeditionState, effect: EffectDef, log: SimulationLog) -> void:
	match effect.type:
		"burden_change":
			var before := state.burden
			state.burden = clampi(state.burden + effect.delta, 0, 100)
			if state.burden > state.stress_indicators.peak_burden:
				state.stress_indicators.peak_burden = state.burden
			log.log_effect(state.tick_count, "EffectProcessor",
				"Burden %+d (%d → %d)" % [effect.delta, before, state.burden],
				{"type": "burden_change", "delta": effect.delta, "before": before, "after": state.burden})

		"command_change":
			var before := state.command
			state.command = clampi(state.command + effect.delta, 0, 100)
			if state.command < state.stress_indicators.min_command:
				state.stress_indicators.min_command = state.command
			log.log_effect(state.tick_count, "EffectProcessor",
				"Command %+d (%d → %d)" % [effect.delta, before, state.command],
				{"type": "command_change", "delta": effect.delta, "before": before, "after": state.command})

		"supply_change":
			var before := state.get_supply(effect.target_id)
			state.set_supply(effect.target_id, before + effect.delta)
			var after := state.get_supply(effect.target_id)
			if after == 0 and before > 0:
				state.stress_indicators.supply_depletions += 1
			log.log_effect(state.tick_count, "EffectProcessor",
				"%s %+d (%d → %d)" % [effect.target_id, effect.delta, before, after],
				{"type": "supply_change", "target": effect.target_id, "delta": effect.delta, "before": before, "after": after})

		"ship_condition_change":
			var before := state.ship_condition
			state.ship_condition = clampi(state.ship_condition + effect.delta, 0, 100)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Ship condition %+d (%d → %d)" % [effect.delta, before, state.ship_condition],
				{"type": "ship_condition_change", "delta": effect.delta, "before": before, "after": state.ship_condition})

		"add_damage_tag":
			state.add_damage_tag(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Added damage tag: %s" % effect.tag,
				{"type": "add_damage_tag", "tag": effect.tag})

		"remove_damage_tag":
			state.remove_damage_tag(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Removed damage tag: %s" % effect.tag,
				{"type": "remove_damage_tag", "tag": effect.tag})

		"set_memory_flag":
			state.add_memory_flag(effect.flag_key)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Set memory flag: %s" % effect.flag_key,
				{"type": "set_memory_flag", "flag": effect.flag_key})

		"add_crew_trait":
			state.add_crew_trait(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Added crew trait: %s" % effect.tag,
				{"type": "add_crew_trait", "tag": effect.tag})

		"remove_crew_trait":
			state.remove_crew_trait(effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Removed crew trait: %s" % effect.tag,
				{"type": "remove_crew_trait", "tag": effect.tag})

		"add_officer_scar":
			state.add_officer_scar(effect.target_id, effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Officer scar '%s' added to role '%s'" % [effect.tag, effect.target_id],
				{"type": "add_officer_scar", "role": effect.target_id, "scar": effect.tag})

		_:
			push_warning("EffectProcessor: unknown effect type '%s'" % effect.type)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Unknown effect type: %s (skipped)" % effect.type,
				{"type": effect.type, "error": "unknown_type"})


static func apply_effects(state: ExpeditionState, effects: Array, log: SimulationLog) -> void:
	for effect: EffectDef in effects:
		apply(state, effect, log)
