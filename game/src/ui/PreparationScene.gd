# PreparationScene.gd
# Full-screen Admiralty preparation screen. Player selects officers (one per
# role), up to 2 ship upgrades, a doctrine, and an objective. Pressing
# "Set Sail" assembles a RunConfig and transitions to RunScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name PreparationScene
extends Control

const REQUIRED_ROLES := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]

var _selected_officers: Dictionary = {}  # role -> officer_id
var _selected_upgrades: Array[String] = []
var _selected_doctrine: String = ""
var _selected_objective: String = ""

var _sail_button: Button
var _status_label: Label
var _upgrade_buttons: Dictionary = {}  # upgrade_id -> Button
var _doctrine_buttons: Dictionary = {}  # doctrine_id -> Button
var _objective_buttons: Dictionary = {}  # objective_id -> Button
var _officer_buttons: Dictionary = {}          # officer_id -> Button
var _officer_buttons_by_role: Dictionary = {}  # role -> Array[Button] (for deselection)

var _admiralty_bias: Array[String] = []
var _scandal_flags: Array[String] = []
var _unavailable_ids: Array[String] = []   # content ids greyed out this prep
var _recommended: Dictionary = {}          # content_id -> { reward_text, type, trait? }
var _free_upgrade_id: String = ""          # recommended upgrade that doesn't use a slot
var _allocation_panel: VBoxContainer = null  # wired up in _build_ui (Task 10)


# Returns { "unavailable_ids": Array[String], "recommended": Dictionary }
# recommended maps content_id -> { "reward_text": String, "type": String, "trait": String }
func _compute_bias_effects(bias: Array[String]) -> Dictionary:
	var unavailable: Array[String] = []
	var recommended: Dictionary = {}

	for b: String in bias:
		match b:
			"blamed_crew":
				unavailable.append("first_lieutenant_lenient")
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"suppressed_mutiny":
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"admitted_failure":
				recommended["first_lieutenant_lenient"] = {
					"reward_text": "First Lieutenant starts Loyal",
					"type": "officer",
					"trait": "loyal",
				}
			"sacrifice_on_record":
				recommended["medical_stores"] = {
					"reward_text": "Medical Stores free — no slot used",
					"type": "upgrade",
				}
			"discipline_on_record":
				recommended["iron_discipline"] = {
					"reward_text": "+%d Command at run start" % GameConstants.RECOMMENDATION_COMMAND_BONUS,
					"type": "doctrine",
				}
			"weather_blamed":
				# No specific content recommendation — letter handles explanation
				pass
			"officer_accused":
				unavailable.append("first_lieutenant_lenient")
				unavailable.append("first_lieutenant_stern")

	return {"unavailable_ids": unavailable, "recommended": recommended}


func _build_letter_text(bias: Array[String]) -> String:
	if bias.is_empty():
		return ""
	# Deduplicate bias keys first — same framing filed multiple times produces one sentence.
	var seen_keys: Array[String] = []
	var unique_bias: Array[String] = []
	for b: String in bias:
		if b not in seen_keys:
			seen_keys.append(b)
			unique_bias.append(b)
	var sentences: Array[String] = []
	for b: String in unique_bias:
		match b:
			"blamed_crew":
				sentences.append("Your account of the crew's insubordination during the previous commission was noted. The Board expects firmer authority on this voyage. Officers of a lenient temperament have not been made available to you.")
			"suppressed_mutiny":
				sentences.append("The Board has reviewed your disciplinary report. Iron Discipline doctrine is commended for this commission. They will be watching for further irregularities.")
			"admitted_failure":
				sentences.append("Your candour regarding the previous commission was noted. A reformist first lieutenant has been assigned to this voyage — an officer who believes authority is earned, not assumed.")
			"sacrifice_on_record":
				sentences.append("The Board commends the effort of the previous expedition. Medical stores have been allocated without charge in recognition of the hardship endured.")
			"discipline_on_record":
				sentences.append("The Board notes the disciplined conduct of the previous commission. Iron Discipline doctrine is commended for this voyage.")
			"weather_blamed":
				sentences.append("Your account of the conditions encountered during the previous commission was received. The Board has assigned a more demanding route for this voyage.")
			"officer_accused":
				sentences.append("The Board is investigating the officer conduct you reported. The accused officer's role has not been filled through the usual channels for this commission.")
			"concealed_misconduct":
				sentences.append("The Board accepted your previous account. They will be paying closer attention to the ship log on your next commission.")
			"compliant":
				sentences.append("Full compliance with the Board's recommendations has been noted. Expectations for the next commission will reflect this record.")
	return "\n\n".join(sentences)


func _ready() -> void:
	var progression := SaveManager.load_progression()
	_admiralty_bias = progression.admiralty_bias
	_scandal_flags = progression.scandal_flags
	var effects := _compute_bias_effects(_admiralty_bias)
	_unavailable_ids = effects.get("unavailable_ids", [])
	_recommended = effects.get("recommended", {})
	# Identify free upgrade (type == "upgrade" in recommended)
	for content_id: String in _recommended:
		if _recommended[content_id].get("type", "") == "upgrade":
			_free_upgrade_id = content_id
	_build_ui()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = 800
	scroll.add_child(vbox)

	# Header
	var title := Label.new()
	title.text = "Admiralty Briefing"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Configure your expedition before sailing."
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)

	# Admiralty letter (only if bias exists)
	var letter_text := _build_letter_text(_admiralty_bias)
	if letter_text != "":
		var letter_panel := PanelContainer.new()
		var letter_vbox := VBoxContainer.new()
		letter_panel.add_child(letter_vbox)

		var letter_heading := Label.new()
		letter_heading.text = "Correspondence from the Admiralty Board"
		letter_vbox.add_child(letter_heading)

		var letter_body := Label.new()
		letter_body.text = letter_text
		letter_body.autowrap_mode = TextServer.AUTOWRAP_WORD
		letter_vbox.add_child(letter_body)

		vbox.add_child(letter_panel)

	vbox.add_child(HSeparator.new())

	# Objective section
	_build_section(vbox, "Objective", _build_objective_slots)

	vbox.add_child(HSeparator.new())

	# Doctrine section
	_build_section(vbox, "Doctrine", _build_doctrine_slots)

	vbox.add_child(HSeparator.new())

	# Officers section
	_build_section(vbox, "Officers", _build_officer_slots)

	vbox.add_child(HSeparator.new())

	# Upgrades section
	_build_section(vbox, "Ship Upgrades (choose up to %d)" % GameConstants.MAX_UPGRADES, _build_upgrade_slots)

	vbox.add_child(HSeparator.new())

	# Status + Set Sail
	_status_label = Label.new()
	_status_label.text = ""
	vbox.add_child(_status_label)

	_sail_button = Button.new()
	_sail_button.text = "Set Sail"
	_sail_button.pressed.connect(_on_set_sail)
	vbox.add_child(_sail_button)


func _build_section(parent: VBoxContainer, title: String, build_fn: Callable) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	build_fn.call(parent)


func _build_objective_slots(parent: VBoxContainer) -> void:
	var all_objectives: Array = ContentRegistry.get_all("objectives")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var shown := 0
	for obj: ContentBase in all_objectives:
		var def: ObjectiveDef = obj as ObjectiveDef
		if def == null:
			continue
		if shown >= GameConstants.OBJECTIVE_SHORTLIST_SIZE:
			break
		var unavailable: bool = def.id in _unavailable_ids
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\nTier %d — %s" % [def.display_name, def.difficulty_tier, def.description]
		if is_recommended:
			label += "\n▲ " + reward_text
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(220, 80)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_objective_selected.bind(def.id, btn))
		_objective_buttons[def.id] = btn
		hbox.add_child(btn)
		shown += 1
		if shown == 1 and not unavailable:
			_selected_objective = def.id
			btn.button_pressed = true


func _build_doctrine_slots(parent: VBoxContainer) -> void:
	var all_doctrines: Array = ContentRegistry.get_all("doctrines")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	# "None" option
	var none_btn := Button.new()
	none_btn.text = "None"
	none_btn.toggle_mode = true
	none_btn.button_pressed = true
	none_btn.pressed.connect(_on_doctrine_selected.bind("", none_btn))
	_doctrine_buttons[""] = none_btn
	hbox.add_child(none_btn)

	for doc: ContentBase in all_doctrines:
		var def: DoctrineDef = doc as DoctrineDef
		if def == null:
			continue
		var unavailable: bool = def.id in _unavailable_ids
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\n%s" % [def.display_name, def.description]
		if is_recommended:
			label += "\n▲ " + reward_text + " — Admiralty recommended"
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(220, 60)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_doctrine_selected.bind(def.id, btn))
		_doctrine_buttons[def.id] = btn
		hbox.add_child(btn)


func _build_officer_slots(parent: VBoxContainer) -> void:
	var all_officers: Array = ContentRegistry.get_all("officers")
	# Group by role
	var by_role: Dictionary = {}
	for off: ContentBase in all_officers:
		var def: OfficerDef = off as OfficerDef
		if def == null or def.role == "" or def.role not in REQUIRED_ROLES:
			continue
		if not by_role.has(def.role):
			by_role[def.role] = []
		by_role[def.role].append(def)

	for role: String in REQUIRED_ROLES:
		var role_label := Label.new()
		role_label.text = role.replace("_", " ").capitalize()
		parent.add_child(role_label)
		var hbox := HBoxContainer.new()
		parent.add_child(hbox)
		var variants: Array = by_role.get(role, [])
		if not _officer_buttons_by_role.has(role):
			_officer_buttons_by_role[role] = []
		for def: OfficerDef in variants:
			var btn := Button.new()
			var unavailable: bool = def.id in _unavailable_ids
			var is_recommended: bool = def.id in _recommended
			var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")
			var extra := ""
			if unavailable:
				extra = "\n— Not available this commission"
			elif is_recommended:
				extra = "\n▲ " + reward_text
			btn.text = "%s\n%s%s" % [def.display_name, _format_effects(def.starting_effects), extra]
			btn.disabled = unavailable
			btn.modulate.a = 0.4 if unavailable else 1.0
			btn.custom_minimum_size = Vector2(200, 70)
			btn.toggle_mode = true
			btn.pressed.connect(_on_officer_selected.bind(role, def.id, btn))
			_officer_buttons[def.id] = btn
			_officer_buttons_by_role[role].append(btn)
			hbox.add_child(btn)
			if not _selected_officers.has(role):
				_selected_officers[role] = def.id
				btn.button_pressed = true


func _build_upgrade_slots(parent: VBoxContainer) -> void:
	var all_upgrades: Array = ContentRegistry.get_all("upgrades")
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	for upg: ContentBase in all_upgrades:
		var def: ShipUpgradeDef = upg as ShipUpgradeDef
		if def == null:
			continue
		var unavailable: bool = def.id in _unavailable_ids
		var is_free: bool = (def.id == _free_upgrade_id)
		var is_recommended: bool = def.id in _recommended
		var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")

		var btn := Button.new()
		var label := "%s\n%s" % [def.display_name, def.drawback_text]
		if is_recommended:
			label += "\n▲ " + reward_text + " — Admiralty recommended"
		if unavailable:
			label += "\n— Not available this commission"
		btn.text = label
		btn.custom_minimum_size = Vector2(200, 70)
		btn.toggle_mode = true
		btn.disabled = unavailable
		btn.modulate.a = 0.4 if unavailable else 1.0
		btn.pressed.connect(_on_upgrade_toggled.bind(def.id, btn))
		_upgrade_buttons[def.id] = btn
		hbox.add_child(btn)

		# Pre-select free upgrade without consuming a slot
		if is_free and not unavailable:
			_selected_upgrades.append(def.id)
			btn.button_pressed = true


func _format_effects(effects: Array) -> String:
	if effects.is_empty():
		return "(no starting effects)"
	var parts: Array[String] = []
	for eff: EffectDef in effects:
		match eff.type:
			"burden_change":
				parts.append("Burden %+d" % eff.delta)
			"command_change":
				parts.append("Command %+d" % eff.delta)
			"supply_change":
				parts.append("%s %+d" % [eff.target_id, eff.delta])
			"ship_condition_change":
				parts.append("Ship %+d" % eff.delta)
			"add_crew_trait":
				parts.append("Trait: %s" % eff.tag)
	return ", ".join(parts)


func _on_objective_selected(objective_id: String, btn: Button) -> void:
	for id: String in _objective_buttons:
		_objective_buttons[id].button_pressed = false
	_selected_objective = objective_id
	btn.button_pressed = true


func _on_doctrine_selected(doctrine_id: String, btn: Button) -> void:
	for id: String in _doctrine_buttons:
		_doctrine_buttons[id].button_pressed = false
	_selected_doctrine = doctrine_id
	btn.button_pressed = true


func _on_officer_selected(role: String, officer_id: String, btn: Button) -> void:
	for role_btn: Button in _officer_buttons_by_role.get(role, []):
		role_btn.button_pressed = false
	_selected_officers[role] = officer_id
	btn.button_pressed = true


func _on_upgrade_toggled(upgrade_id: String, btn: Button) -> void:
	if upgrade_id in _selected_upgrades:
		if upgrade_id != _free_upgrade_id:  # free upgrade cannot be deselected
			_selected_upgrades.erase(upgrade_id)
			btn.button_pressed = false
	else:
		# Count non-free upgrades against the cap
		var non_free_count := _selected_upgrades.filter(func(id): return id != _free_upgrade_id).size()
		if non_free_count >= GameConstants.MAX_UPGRADES:
			btn.button_pressed = false
			_status_label.text = "Maximum %d upgrades selected." % GameConstants.MAX_UPGRADES
			return
		_selected_upgrades.append(upgrade_id)
	_status_label.text = ""


func _on_set_sail() -> void:
	# Validate all required roles are filled
	for role: String in REQUIRED_ROLES:
		if not _selected_officers.has(role) or _selected_officers[role] == "":
			_status_label.text = "Must select an officer for: " + role.replace("_", " ").capitalize()
			return
	if _selected_objective == "":
		_status_label.text = "Must select an objective."
		return

	var config := {
		"objective_id": _selected_objective,
		"doctrine_id": _selected_doctrine,
		"officer_ids": _selected_officers.values(),
		"upgrade_ids": _selected_upgrades,
	}
	SaveManager.pending_run_config = config

	var run_scene: Node = load("res://src/ui/RunScene.tscn").instantiate()
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(run_scene)
	get_tree().current_scene = run_scene
	old_scene.queue_free()
