# RunScene.gd
# Hosts the expedition tick loop. Reads RunConfig from SaveManager.pending_run_config,
# initialises ExpeditionState via create_from_config, and calls TravelSimulator.process_tick
# on each advance. Shows route node choices between stages. When an incident is pending,
# shows IncidentResolutionScene. On run end, transitions to RunEndScene.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunScene
extends Control

var _state: ExpeditionState
var _log: SimulationLog
var _route: RouteMap

var _stats_label: Label
var _route_status_label: Label
var _route_container: VBoxContainer
var _advance_button: Button
var _status_label: Label
var _log_label: Label
var _incident_container: VBoxContainer


func _ready() -> void:
	var config := SaveManager.pending_run_config
	SaveManager.pending_run_config = {}
	_state = ExpeditionState.create_from_config(config)
	_log = SimulationLog.new()
	_route = RouteMap.create_test_map()
	_build_ui()
	_refresh_display()
	_refresh_route_ui()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_stats_label)

	vbox.add_child(HSeparator.new())

	# Route map area: status line + node choice buttons
	_route_container = VBoxContainer.new()
	vbox.add_child(_route_container)
	_route_status_label = Label.new()
	_route_container.add_child(_route_status_label)

	vbox.add_child(HSeparator.new())

	# Incident container (hidden until incident fires)
	_incident_container = VBoxContainer.new()
	_incident_container.visible = false
	vbox.add_child(_incident_container)

	_advance_button = Button.new()
	_advance_button.text = "Advance Day"
	_advance_button.pressed.connect(_on_advance)
	vbox.add_child(_advance_button)

	_status_label = Label.new()
	_status_label.text = ""
	vbox.add_child(_status_label)

	var log_title := Label.new()
	log_title.text = "Log:"
	vbox.add_child(log_title)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_log_label)


func _refresh_route_ui() -> void:
	# Remove all route widgets after the status label (index 0)
	var children := _route_container.get_children()
	for i: int in range(1, children.size()):
		children[i].queue_free()

	if _route.is_complete():
		_route_status_label.text = "Route complete."
		_advance_button.disabled = true
		return

	if _route.is_travelling():
		var node := _route.active_node as RouteNode
		_route_status_label.text = "Travelling → %s  [%s]  — %d day(s) remaining" % [
			node.category.to_upper(), node.zone_type_id, _route.ticks_remaining]
		_advance_button.disabled = false
		return

	# Not travelling — show stage choices
	_route_status_label.text = "Stage %d — Choose your heading:" % (_route.current_stage_index + 1)
	_advance_button.disabled = true

	for node: RouteNode in _route.get_current_stage():
		var btn := Button.new()
		var hint := node.hints[0] if not node.hints.is_empty() else ""
		btn.text = "%s  [%s  %d days]  %s" % [
			node.category.to_upper(), node.zone_type_id, node.tick_distance, hint]
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_node_selected.bind(node))
		_route_container.add_child(btn)


func _on_node_selected(node: RouteNode) -> void:
	_route.select_node(node)
	_status_label.text = ""
	_refresh_route_ui()


func _on_advance() -> void:
	if _state.run_end_reason != "":
		return

	if _state.pending_incident_id != "":
		_show_incident_resolution()
		return

	if _route.is_complete():
		_state.run_end_reason = "completed"
		_log.log_event(_state.tick_count, "RunScene", "Expedition complete — all route nodes traversed.", {})
		_refresh_display()
		_refresh_route_ui()
		_transition_to_run_end()
		return

	if not _route.is_travelling():
		_status_label.text = "Choose a heading before advancing."
		return

	var zone: ZoneTypeDef = _route.get_active_zone()
	if zone == null:
		_status_label.text = "ERROR: zone type not found for active node"
		return
	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	_route.advance_tick()

	_refresh_display()
	_refresh_route_ui()

	if _state.pending_incident_id != "" and _state.run_end_reason == "":
		_show_incident_resolution()
		return

	if _state.run_end_reason != "":
		_transition_to_run_end()


func _show_incident_resolution() -> void:
	for child in _incident_container.get_children():
		child.queue_free()

	var resolution := load("res://src/ui/IncidentResolutionScene.tscn").instantiate() as IncidentResolutionScene
	_incident_container.add_child(resolution)
	resolution.setup(_state, _log)
	resolution.populate()
	resolution.resolved.connect(_on_incident_resolved)
	_incident_container.visible = true
	_advance_button.visible = false


func _on_incident_resolved() -> void:
	_incident_container.visible = false
	_advance_button.visible = true
	_state.pending_incident_id = ""
	_refresh_display()
	_refresh_route_ui()
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _transition_to_run_end() -> void:
	_advance_button.visible = false
	_status_label.text = "Expedition ended: " + _state.run_end_reason
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	var run_end_scene := load("res://src/ui/RunEndScene.tscn").instantiate() as RunEndScene
	run_end_scene.final_state = _state
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(run_end_scene)
	get_tree().current_scene = run_end_scene
	old_scene.queue_free()


func _refresh_display() -> void:
	_stats_label.text = (
		"Tick: %d | Burden: %d | Command: %d | Ship: %d%%\nObjective: %s" % [
			_state.tick_count, _state.burden, _state.command,
			_state.ship_condition, _state.active_objective_id
		]
	)
	var entries := _log.get_entries()
	var recent := entries.slice(maxi(0, entries.size() - 5))
	var lines: Array[String] = []
	for entry: Dictionary in recent:
		lines.append("[%d] %s: %s" % [entry.get("tick", 0), entry.get("source", ""), entry.get("message", "")])
	_log_label.text = "\n".join(lines)
