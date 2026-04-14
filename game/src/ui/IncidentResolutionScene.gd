# IncidentResolutionScene.gd
# Fills the right slot in RunScene while an incident is pending.
# Call setup(state, log) before adding to scene tree. Emits resolved when done.
# Does NOT instantiate StatsBar or LogPanel — relies on RunScene shell.
# Each choice card has its own CONFIRM button — one click resolves.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name IncidentResolutionScene
extends Control

signal resolved

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _incident: IncidentDef = null
var _proposals: Array = []


func setup(state: ExpeditionState, log: SimulationLog) -> void:
	_state = state
	_log = log
	_incident = ContentRegistry.get_by_id("incidents", state.pending_incident_id) as IncidentDef
	if _incident == null:
		push_error("IncidentResolutionScene: incident not found: " + state.pending_incident_id)


func _ready() -> void:
	if _incident == null or _state == null:
		return
	_build_ui()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(vbox)

	# Incident title
	var cat_colors: Dictionary = {
		"crisis": Color.html("#ff9966"), "social": Color.html("#ffdd66"),
		"omen": Color.html("#cc88ff"), "boon": Color.html("#aaffaa"),
		"admiralty": Color.html("#ffccaa"), "landfall": Color.html("#88ff88"),
	}
	var cat_color: Color = cat_colors.get(_incident.category, Color(0.6, 0.7, 0.8))

	var title_lbl := Label.new()
	title_lbl.text = _incident.display_name.to_upper()
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", cat_color)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_lbl)

	var flavour := Label.new()
	flavour.text = _incident.log_text_template
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavour.add_theme_font_size_override("font_size", 15)
	flavour.add_theme_color_override("font_color", Color(0.72, 0.76, 0.8))
	vbox.add_child(flavour)

	var advice_lbl := Label.new()
	advice_lbl.text = "THE OFFICERS ADVISE"
	advice_lbl.add_theme_font_size_override("font_size", 12)
	advice_lbl.add_theme_color_override("font_color", Color(0.4, 0.55, 0.65))
	vbox.add_child(advice_lbl)

	# Build proposals
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)
	_proposals = OfficerCouncil.get_proposals(_state, _incident, officer_defs)

	for i in range(_proposals.size()):
		var proposal: Dictionary = _proposals[i]
		match proposal["type"]:
			"officer":
				vbox.add_child(_build_officer_card(i, proposal))
			"silence":
				var officer_def: OfficerDef = proposal["officer_def"]
				var sil := Label.new()
				sil.text = "%s (%s): \"%s\"" % [
					officer_def.display_name,
					_competence_label(officer_def.competence),
					proposal["silence_line"]]
				sil.add_theme_font_size_override("font_size", 13)
				sil.add_theme_color_override("font_color", Color(0.45, 0.5, 0.55))
				sil.autowrap_mode = TextServer.AUTOWRAP_WORD
				vbox.add_child(sil)
			"direct_order":
				vbox.add_child(_build_direct_order_card(i))


func _build_officer_card(index: int, proposal: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var officer_def: OfficerDef = proposal["officer_def"]
	var choice: IncidentChoiceDef = proposal["choice"]

	# Officer header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	inner.add_child(header)

	var name_lbl := Label.new()
	name_lbl.text = officer_def.display_name.to_upper()
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.67, 1.0, 0.67))
	header.add_child(name_lbl)

	var dots_lbl := Label.new()
	dots_lbl.text = _competence_dots(officer_def.competence)
	dots_lbl.add_theme_font_size_override("font_size", 11)
	dots_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.5))
	header.add_child(dots_lbl)

	# Choice text
	var choice_lbl := Label.new()
	choice_lbl.text = choice.choice_text
	choice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	choice_lbl.add_theme_font_size_override("font_size", 15)
	inner.add_child(choice_lbl)

	if choice.effects_preview != "":
		var preview_lbl := Label.new()
		preview_lbl.text = choice.effects_preview
		preview_lbl.add_theme_font_size_override("font_size", 12)
		preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.78))
		inner.add_child(preview_lbl)

	if choice.risk_text != "" and officer_def.competence >= 3:
		var risk_lbl := Label.new()
		risk_lbl.text = "Risk: " + choice.risk_text
		risk_lbl.add_theme_font_size_override("font_size", 12)
		risk_lbl.add_theme_color_override("font_color", Color(0.85, 0.52, 0.28))
		inner.add_child(risk_lbl)

	# CONFIRM button — one click executes this choice
	var confirm_btn := Button.new()
	confirm_btn.text = "CONFIRM — %s" % officer_def.display_name.to_upper()
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(_on_execute.bind(index))
	inner.add_child(confirm_btn)

	return panel


func _build_direct_order_card(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var lbl := Label.new()
	lbl.text = "DIRECT ORDER — This does not leave the cabin."
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.58, 0.5))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner.add_child(lbl)

	var confirm_btn := Button.new()
	confirm_btn.text = "CONFIRM — DIRECT ORDER"
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(_on_execute.bind(index))
	inner.add_child(confirm_btn)

	return panel


func _on_execute(index: int) -> void:
	if index < 0 or index >= _proposals.size():
		return
	var proposal: Dictionary = _proposals[index]
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
				{"incident_id": _incident.id, "choice": choice.choice_text})
		"direct_order":
			_state.nudge_leadership_tag("authoritarian")
			_state.add_memory_flag("direct_order_used")
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] Captain issued direct order." % _incident.display_name,
				{"incident_id": _incident.id, "type": "direct_order"})
	_state.pending_incident_id = ""
	resolved.emit()


func _competence_dots(competence: int) -> String:
	return "●".repeat(competence) + "○".repeat(5 - competence)


func _competence_label(competence: int) -> String:
	match competence:
		1: return "Inept"
		2: return "Poor"
		3: return "Adequate"
		4: return "Skilled"
		5: return "Expert"
	return "Unknown"
