# RunEndScene.gd
# Displays expedition outcome, objective result, stress indicators, and
# Admiralty difficulty assessment. Saves progression. Returns to PreparationScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunEndScene
extends Control

var final_state: ExpeditionState = null


func _ready() -> void:
	if final_state == null:
		# Fallback: create a dummy state for direct scene preview
		final_state = ExpeditionState.new()
		final_state.run_end_reason = "completed"
	_process_run_end()
	_build_ui()


func _process_run_end() -> void:
	# Evaluate objective
	var objective_success := false
	var objective_def: ObjectiveDef = null
	if final_state.active_objective_id != "":
		objective_def = ContentRegistry.get_by_id("objectives", final_state.active_objective_id) as ObjectiveDef
		if objective_def:
			var dummy_log := SimulationLog.new()
			if objective_def.success_condition == null:
				objective_success = true
			else:
				objective_success = ConditionEvaluator.evaluate(final_state, objective_def.success_condition, dummy_log)

	# Record unlock if objective succeeded
	if objective_success and objective_def != null:
		SaveManager.record_objective_complete(final_state.active_objective_id)

	# Save difficulty score
	var score := _compute_difficulty_score()
	var progression := SaveManager.load_progression()
	progression.last_run_difficulty_score = score
	SaveManager.save_progression(progression)

	SaveManager.delete_run_state()


func _compute_difficulty_score() -> int:
	var s := final_state.stress_indicators
	var score: float = (
		float(s.get("peak_burden", 0)) * GameConstants.DIFFICULTY_BURDEN_WEIGHT +
		float(100 - s.get("min_command", 100)) * GameConstants.DIFFICULTY_COMMAND_WEIGHT +
		float(s.get("crew_losses", 0)) * GameConstants.DIFFICULTY_CREW_LOSS_WEIGHT +
		float(s.get("supply_depletions", 0)) * GameConstants.DIFFICULTY_SUPPLY_DEPLETION_WEIGHT
	)
	return clampi(int(score), 0, 100)


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Outcome header
	var outcome_text := ""
	match final_state.run_end_reason:
		"completed":
			outcome_text = "Expedition Complete"
		"mutiny":
			outcome_text = "Mutiny"
		"breakdown":
			outcome_text = "Expedition Lost"
		_:
			outcome_text = "Run Ended"

	var outcome_label := Label.new()
	outcome_label.text = outcome_text
	outcome_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(outcome_label)

	vbox.add_child(HSeparator.new())

	# Objective result
	var objective_def: ObjectiveDef = null
	var objective_success := false
	if final_state.active_objective_id != "":
		objective_def = ContentRegistry.get_by_id("objectives", final_state.active_objective_id) as ObjectiveDef
		if objective_def:
			var dummy_log := SimulationLog.new()
			objective_success = (objective_def.success_condition == null or
				ConditionEvaluator.evaluate(final_state, objective_def.success_condition, dummy_log))

	var obj_label := Label.new()
	if objective_def:
		var result_str := "SUCCESS" if objective_success else "FAILED"
		obj_label.text = "Objective: %s — %s\n%s" % [objective_def.display_name, result_str, objective_def.description]
	else:
		obj_label.text = "No objective set."
	obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(obj_label)

	vbox.add_child(HSeparator.new())

	# Stress indicators
	var stress_title := Label.new()
	stress_title.text = "Expedition Record"
	stress_title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(stress_title)

	var s := final_state.stress_indicators
	var stress_label := Label.new()
	stress_label.text = (
		"Peak Burden: %d\nMin Command: %d\nCrew Losses: %d\nSupply Depletions: %d" % [
			s.get("peak_burden", 0), s.get("min_command", 0),
			s.get("crew_losses", 0), s.get("supply_depletions", 0)
		]
	)
	vbox.add_child(stress_label)

	vbox.add_child(HSeparator.new())

	# Difficulty score
	var score := _compute_difficulty_score()
	var score_label := Label.new()
	score_label.text = "Admiralty Assessment: %d / 100" % score
	score_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(score_label)

	vbox.add_child(HSeparator.new())

	# Return button
	var return_btn := Button.new()
	return_btn.text = "Return to Admiralty"
	return_btn.pressed.connect(_on_return)
	vbox.add_child(return_btn)


func _on_return() -> void:
	var prep_scene := load("res://src/ui/PreparationScene.tscn").instantiate()
	get_tree().root.add_child(prep_scene)
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().current_scene = prep_scene
