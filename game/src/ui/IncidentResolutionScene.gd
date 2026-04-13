# IncidentResolutionScene.gd
# UI scene for resolving an incident through the officer council.
# Call setup(state, log) to populate. Emits resolved when the player confirms.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
class_name IncidentResolutionScene
extends VBoxContainer

signal resolved

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _incident: IncidentDef = null
var _proposals: Array = []
var _selected_index: int = -1

@onready var _category_label: Label = $IncidentHeader/HeaderContent/CategoryLabel
@onready var _title_label: Label = $IncidentHeader/HeaderContent/TitleLabel
@onready var _flavour_label: Label = $IncidentHeader/HeaderContent/FlavourLabel
@onready var _state_label: Label = $IncidentHeader/HeaderContent/StateLabel
@onready var _art_panel: ColorRect = $MainArea/ArtPanel
@onready var _proposal_list: VBoxContainer = $MainArea/CouncilPanel/ProposalList
@onready var _confirm_button: Button = $MainArea/CouncilPanel/ConfirmButton
@onready var _silence_footer: Label = $MainArea/CouncilPanel/SilenceFooter


func setup(state: ExpeditionState, log: SimulationLog) -> void:
	_state = state
	_log = log
	_incident = ContentRegistry.get_by_id("incidents", state.pending_incident_id) as IncidentDef
	if _incident == null:
		push_error("IncidentResolutionScene: incident not found: " + state.pending_incident_id)
		return


func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm)
	_confirm_button.visible = false


func populate() -> void:
	if _incident == null or _state == null:
		return

	# Header
	_category_label.text = _incident.category.to_upper() + " — " + _incident.id.to_upper()
	_title_label.text = _incident.display_name.to_upper()
	_flavour_label.text = _incident.log_text_template
	_state_label.text = "Day %d  ·  Burden %d  ·  Command %d  ·  Ship %d" % [
		_state.tick_count, _state.burden, _state.command, _state.ship_condition]

	# Art panel — placeholder colour; future: load texture from _incident.art_path
	_art_panel.color = Color(0.08, 0.08, 0.1, 1.0)

	# Build proposals from present officers
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)

	_proposals = OfficerCouncil.get_proposals(_state, _incident, officer_defs)

	# Clear previous cards
	for child in _proposal_list.get_children():
		child.queue_free()

	_selected_index = -1
	_confirm_button.visible = false

	# Build silence footer text
	var silence_lines: Array[String] = []

	# Create a card button per proposal
	for i: int in range(_proposals.size()):
		var proposal: Dictionary = _proposals[i]
		var btn := Button.new()
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD

		match proposal["type"]:
			"officer":
				var officer_def: OfficerDef = proposal["officer_def"]
				var choice: IncidentChoiceDef = proposal["choice"]
				var dots := _competence_dots(officer_def.competence)
				var preview := choice.effects_preview if choice.effects_preview != "" else "(no preview)"
				var risk := ""
				if choice.risk_text != "" and officer_def.competence >= 3:
					risk = "\nRisk: " + choice.risk_text
				btn.text = "[%s  %s]\n%s\n%s%s" % [
					officer_def.display_name.to_upper(), dots,
					choice.choice_text, preview, risk]
				btn.tooltip_text = "→ " + choice.leadership_tag if choice.leadership_tag != "" else ""
				_proposal_list.add_child(btn)
				btn.pressed.connect(_on_proposal_selected.bind(i))

			"silence":
				# Add to footer, not as a button
				var officer_def: OfficerDef = proposal["officer_def"]
				silence_lines.append("%s: \"%s\"" % [officer_def.display_name, proposal["silence_line"]])

			"direct_order":
				btn.text = "[DIRECT ORDER]\nThis does not leave my cabin.\n→ authoritarian"
				_proposal_list.add_child(btn)
				btn.pressed.connect(_on_proposal_selected.bind(i))

	_silence_footer.text = "\n".join(silence_lines)


func _on_proposal_selected(index: int) -> void:
	_selected_index = index
	_confirm_button.visible = true
	_confirm_button.text = "CONFIRM — " + _proposals[index].get("type", "").to_upper()

	# Highlight selected button (deselect others)
	var btns := _proposal_list.get_children()
	var btn_idx := 0
	for i: int in range(_proposals.size()):
		if _proposals[i]["type"] == "silence":
			continue
		if btn_idx < btns.size():
			var btn := btns[btn_idx] as Button
			if btn != null:
				btn.modulate = Color(0.6, 1.0, 0.6, 1.0) if i == index else Color(1, 1, 1, 1)
			btn_idx += 1


func _on_confirm() -> void:
	if _selected_index < 0 or _selected_index >= _proposals.size():
		return

	var proposal: Dictionary = _proposals[_selected_index]

	match proposal["type"]:
		"officer":
			var choice: IncidentChoiceDef = proposal["choice"]
			EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
			for flag: String in choice.memory_flags_set:
				_state.add_memory_flag(flag)
			if choice.leadership_tag != "":
				_state.nudge_leadership_tag(choice.leadership_tag)
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] %s" % [_incident.display_name, choice.log_text],
				{"incident_id": _incident.id, "choice": choice.choice_text, "leadership_tag": choice.leadership_tag})

		"direct_order":
			_state.nudge_leadership_tag("authoritarian")
			_state.add_memory_flag("direct_order_used")
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] Captain issued direct order." % _incident.display_name,
				{"incident_id": _incident.id, "type": "direct_order"})

	_state.pending_incident_id = ""
	resolved.emit()


func _competence_dots(competence: int) -> String:
	var filled := "●".repeat(competence)
	var empty := "○".repeat(5 - competence)
	return filled + empty
