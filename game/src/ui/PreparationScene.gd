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
var _officer_buttons: Dictionary = {}   # officer_id -> Button


func _ready() -> void:
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
	var progression := SaveManager.load_progression()
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
		var btn := Button.new()
		btn.text = "%s\nTier %d — %s" % [def.display_name, def.difficulty_tier, def.description]
		btn.custom_minimum_size = Vector2(220, 80)
		btn.toggle_mode = true
		btn.pressed.connect(_on_objective_selected.bind(def.id, btn))
		_objective_buttons[def.id] = btn
		hbox.add_child(btn)
		shown += 1
		if shown == 1:
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
		var btn := Button.new()
		btn.text = "%s\n%s" % [def.display_name, def.description]
		btn.custom_minimum_size = Vector2(220, 60)
		btn.toggle_mode = true
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
		for def: OfficerDef in variants:
			var btn := Button.new()
			btn.text = "%s\n%s" % [def.display_name, _format_effects(def.starting_effects)]
			btn.custom_minimum_size = Vector2(200, 70)
			btn.toggle_mode = true
			btn.pressed.connect(_on_officer_selected.bind(role, def.id, btn))
			_officer_buttons[def.id] = btn
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
		var btn := Button.new()
		btn.text = "%s\n%s" % [def.display_name, def.drawback_text]
		btn.custom_minimum_size = Vector2(200, 70)
		btn.toggle_mode = true
		btn.pressed.connect(_on_upgrade_toggled.bind(def.id, btn))
		_upgrade_buttons[def.id] = btn
		hbox.add_child(btn)


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
	# Deselect all buttons for this role
	var all_officers: Array = ContentRegistry.get_all("officers")
	for off: ContentBase in all_officers:
		var def: OfficerDef = off as OfficerDef
		if def != null and def.role == role and _officer_buttons.has(def.id):
			_officer_buttons[def.id].button_pressed = false
	_selected_officers[role] = officer_id
	btn.button_pressed = true


func _on_upgrade_toggled(upgrade_id: String, btn: Button) -> void:
	if upgrade_id in _selected_upgrades:
		_selected_upgrades.erase(upgrade_id)
		btn.button_pressed = false
	else:
		if _selected_upgrades.size() >= GameConstants.MAX_UPGRADES:
			_status_label.text = "Cannot select more than %d upgrades." % GameConstants.MAX_UPGRADES
			btn.button_pressed = false
			return
		_selected_upgrades.append(upgrade_id)
		btn.button_pressed = true
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

	var run_scene := load("res://src/ui/RunScene.tscn").instantiate()
	get_tree().root.add_child(run_scene)
	get_tree().root.remove_child(get_tree().current_scene)
	get_tree().current_scene = run_scene
