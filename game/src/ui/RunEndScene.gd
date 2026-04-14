# RunEndScene.gd
# Displays expedition outcome, objective result, stress indicators, and
# Admiralty difficulty assessment. Saves progression. Returns to PreparationScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunEndScene
extends Control

var final_state: ExpeditionState = null

# Computed once in _ready, used by both _process_run_end and _build_ui.
var _objective_def: ObjectiveDef = null
var _objective_success: bool = false
var _difficulty_score: int = 0

var _selected_framing: String = ""  # set by _on_framing_selected; consumed by _on_return

# Each entry: id -> { title, spin_text, consequence_text, bias_string, scandal_flag, gate }
# gate values:
#   "mutiny"                   — run_end_reason == "mutiny"
#   "any_failure"              — run_end_reason in ["mutiny", "breakdown"]
#   "failure_with_hazard"      — failed + storm/hazard memory flag
#   "failure_with_misconduct"  — failed + misconduct memory flag
#   "failure_with_officer"     — failed + objective failed + officer incident flag
#   "any_with_losses"          — crew_losses > 0 (any outcome)
#   "success_with_discipline"  — completed + discipline standing order active
const FRAMING_OPTIONS: Dictionary = {
	"suppress_mutiny": {
		"title": "Suppress the Mutiny",
		"spin_text": "You report a disciplinary incident. The mutiny goes unrecorded. The Admiralty will not know the crew took the ship — unless someone talks.",
		"consequence_text": "The Board grants you authority to manage discipline privately on your next commission. They will be watching for further irregularities.",
		"bias_string": "suppressed_mutiny",
		"scandal_flag": "scandal_suppressed_mutiny",
		"gate": "mutiny",
	},
	"blame_crew": {
		"title": "Blame the Crew",
		"spin_text": "The men were unfit. Pressed sailors with no loyalty and no discipline. You held command as long as any officer could have.",
		"consequence_text": "The Admiralty will not provision pressed men for your next voyage. You will receive volunteers — fewer of them, and they will expect better conditions.",
		"bias_string": "blamed_crew",
		"scandal_flag": "scandal_blamed_crew",
		"gate": "any_failure",
	},
	"admit_failure": {
		"title": "Admit Command Failure",
		"spin_text": "The breakdown of authority was yours to prevent. You did not. The record should say so.",
		"consequence_text": "The Admiralty respects the candour. They assign you a reformist first lieutenant for the next expedition — an officer who believes authority is earned, not assumed.",
		"bias_string": "admitted_failure",
		"scandal_flag": "scandal_admitted_failure",
		"gate": "any_failure",
	},
	"blame_weather": {
		"title": "Blame the Weather",
		"spin_text": "The conditions were beyond any officer's ability to manage. Storms, spoiled stores, a passage the charts did not adequately warn of.",
		"consequence_text": "The Admiralty notes the conditions. They add a supply buffer to your next commission — and will select a more demanding route to test your claim.",
		"bias_string": "weather_blamed",
		"scandal_flag": "scandal_weather_blamed",
		"gate": "failure_with_hazard",
	},
	"conceal_misconduct": {
		"title": "Conceal Misconduct",
		"spin_text": "Certain incidents on the lower deck need not concern the Admiralty. What happened was managed. The record will reflect a disciplined ship.",
		"consequence_text": "The Board accepts the account. They will be paying closer attention to your next commission's ship log.",
		"bias_string": "concealed_misconduct",
		"scandal_flag": "scandal_concealed_misconduct",
		"gate": "failure_with_misconduct",
	},
	"accuse_officer": {
		"title": "Accuse a Rival Officer",
		"spin_text": "The expedition's failure traces to an officer whose conduct was unsuitable for command. The objective was never attempted because of their interference.",
		"consequence_text": "The Board investigates. The accused officer's role will not be filled by their usual contacts on your next commission.",
		"bias_string": "officer_accused",
		"scandal_flag": "scandal_officer_accused",
		"gate": "failure_with_officer",
	},
	"glorify_sacrifice": {
		"title": "Glorify the Sacrifice",
		"spin_text": "Men died holding this expedition together. The Admiralty should know what this crew endured before judging the outcome.",
		"consequence_text": "The Admiralty commends the effort. They add an additional supply allocation to your next commission — and expect results to match the hardship you describe.",
		"bias_string": "sacrifice_on_record",
		"scandal_flag": "scandal_glorified_sacrifice",
		"gate": "any_with_losses",
	},
	"emphasise_discipline": {
		"title": "Emphasise Discipline",
		"spin_text": "The expedition maintained order throughout. Standards were upheld. The crew performed as directed.",
		"consequence_text": "The Admiralty notes the command culture. Iron Discipline doctrine is commended for your next commission.",
		"bias_string": "discipline_on_record",
		"scandal_flag": "",
		"gate": "success_with_discipline",
	},
}


func _get_available_framings() -> Array[String]:
	if final_state == null:
		return []
	var available: Array[String] = []
	var failed: bool = final_state.run_end_reason in ["mutiny", "breakdown"]
	for id: String in FRAMING_OPTIONS:
		var opt: Dictionary = FRAMING_OPTIONS[id]
		var include := false
		match opt.get("gate", ""):
			"mutiny":
				include = (final_state.run_end_reason == "mutiny")
			"any_failure":
				include = failed
			"failure_with_hazard":
				include = failed and _has_hazard_flag()
			"failure_with_misconduct":
				include = failed and _has_misconduct_flag()
			"failure_with_officer":
				include = failed and not _objective_success and _has_officer_incident_flag()
			"any_with_losses":
				include = (final_state.stress_indicators.get("crew_losses", 0) > 0)
			"success_with_discipline":
				include = (final_state.run_end_reason == "completed") and _has_discipline_order()
		if include:
			available.append(id)
	return available


func _has_hazard_flag() -> bool:
	return ("storm_survived" in final_state.memory_flags or
			"hazard_encountered" in final_state.memory_flags)


func _has_misconduct_flag() -> bool:
	for flag: String in ["rum_theft_unresolved", "botched_hanging", "burial_denied", "officer_misconduct"]:
		if flag in final_state.memory_flags:
			return true
	return false


func _has_officer_incident_flag() -> bool:
	for flag: String in ["purser_exposed", "surgeon_publicly_overruled", "officer_dispute"]:
		if flag in final_state.memory_flags:
			return true
	return false


func _has_discipline_order() -> bool:
	return ("suppress_dissent" in final_state.standing_orders or
			"strict_watches" in final_state.standing_orders)


# Returns a BBCode string for the factual account section.
# Highlighted sentences are facts the Admiralty will scrutinise.
func _build_log_narrative_text() -> String:
	var text := ""
	var s := final_state.stress_indicators

	# Opening context
	text += "The expedition departed"
	if _objective_def != null:
		text += " with orders to %s" % _objective_def.display_name.to_lower()
	text += ". "

	# Memory flag context sentences
	if "rum_theft_unresolved" in final_state.memory_flags:
		text += "A rum ration dispute went unresolved. "
	if "storm_survived" in final_state.memory_flags:
		text += "The ship endured a storm. "

	# Burden context
	var peak: int = s.get("peak_burden", 0)
	if peak >= 70:
		text += "Burden reached %d before the end. " % peak

	# Scrutiny facts — highlighted in Admiralty gold
	var losses: int = s.get("crew_losses", 0)
	if losses == 1:
		text += "[color=#c8b89a]One man is dead.[/color] "
	elif losses > 1:
		text += "[color=#c8b89a]%d men are dead.[/color] " % losses

	var min_cmd: int = s.get("min_command", 100)
	if min_cmd < GameConstants.MUTINY_COMMAND_THRESHOLD:
		text += "[color=#c8b89a]Command fell to %d.[/color] " % min_cmd

	if final_state.run_end_reason == "mutiny":
		text += "[color=#c8b89a]The crew refused orders.[/color] "

	if not _objective_success and _objective_def != null:
		text += "[color=#c8b89a]The objective was never completed.[/color] "

	return text.strip_edges()


func _ready() -> void:
	if final_state == null:
		# Fallback: create a dummy state for direct scene preview
		final_state = ExpeditionState.new()
		final_state.run_end_reason = "completed"
	_evaluate_outcome()
	_process_run_end()
	_build_ui()


func _evaluate_outcome() -> void:
	if final_state.active_objective_id != "":
		_objective_def = ContentRegistry.get_by_id("objectives", final_state.active_objective_id) as ObjectiveDef
		if _objective_def:
			var dummy_log := SimulationLog.new()
			if _objective_def.success_condition == null:
				_objective_success = true
			else:
				_objective_success = ConditionEvaluator.evaluate(final_state, _objective_def.success_condition, dummy_log)
	_difficulty_score = _compute_difficulty_score()


func _process_run_end() -> void:
	# Record unlock if objective succeeded
	if _objective_success and _objective_def != null:
		SaveManager.record_objective_complete(final_state.active_objective_id)

	# Save difficulty score
	var progression := SaveManager.load_progression()
	progression.last_run_difficulty_score = _difficulty_score
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

	# Objective result (uses pre-computed _objective_def / _objective_success)
	var obj_label := Label.new()
	if _objective_def:
		var result_str := "SUCCESS" if _objective_success else "FAILED"
		obj_label.text = "Objective: %s — %s\n%s" % [_objective_def.display_name, result_str, _objective_def.description]
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

	# Difficulty score (pre-computed in _evaluate_outcome)
	var score_label := Label.new()
	score_label.text = "Admiralty Assessment: %d / 100" % _difficulty_score
	score_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(score_label)

	vbox.add_child(HSeparator.new())

	# Return button
	var return_btn := Button.new()
	return_btn.text = "Return to Admiralty"
	return_btn.pressed.connect(_on_return)
	vbox.add_child(return_btn)


func _on_return() -> void:
	var prep_scene: Node = load("res://src/ui/PreparationScene.tscn").instantiate()
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(prep_scene)
	get_tree().current_scene = prep_scene
	old_scene.queue_free()
