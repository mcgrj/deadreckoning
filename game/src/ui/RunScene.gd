# RunScene.gd
# Hosts the expedition tick loop. Reads RunConfig from SaveManager.pending_run_config,
# initialises ExpeditionState via create_from_config, and calls TravelSimulator.process_tick
# on each advance. Checks state.run_end_reason after every tick to detect run end.
# When an incident is pending, shows IncidentResolutionScene. On run end, transitions
# to RunEndScene with the final ExpeditionState.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name RunScene
extends Control

var _state: ExpeditionState
var _log: SimulationLog
var _route: RouteMap
var _current_node_index: int = 0

var _status_label: Label
var _stats_label: Label
var _log_label: Label
var _advance_button: Button
var _incident_container: VBoxContainer


func _ready() -> void:
	var config := SaveManager.pending_run_config
	SaveManager.pending_run_config = {}
	_state = ExpeditionState.create_from_config(config)
	_log = SimulationLog.new()
	_route = RouteMap.generate_default()
	_build_ui()
	_refresh_display()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Header: ship status
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_stats_label)

	vbox.add_child(HSeparator.new())

	# Incident container (hidden until incident fires)
	_incident_container = VBoxContainer.new()
	_incident_container.visible = false
	vbox.add_child(_incident_container)

	# Advance button
	_advance_button = Button.new()
	_advance_button.text = "Advance Day"
	_advance_button.pressed.connect(_on_advance)
	vbox.add_child(_advance_button)

	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	vbox.add_child(_status_label)

	# Recent log
	var log_title := Label.new()
	log_title.text = "Log:"
	vbox.add_child(log_title)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_log_label)


func _on_advance() -> void:
	if _state.run_end_reason != "":
		return

	# If an incident is waiting, don't advance until resolved
	if _state.pending_incident_id != "":
		_show_incident_resolution()
		return

	# Advance route
	var nodes := _route.get_nodes()
	if _current_node_index < nodes.size():
		var node: RouteNode = nodes[_current_node_index]
		var zone: ZoneTypeDef = ContentRegistry.get_by_id("zone_types", node.zone_type_id) as ZoneTypeDef
		if zone == null:
			_status_label.text = "ERROR: zone type not found: " + node.zone_type_id
			return
		_state.tick_count += 1
		TravelSimulator.process_tick(_state, zone, _log)
		_current_node_index += 1
	else:
		# Final node reached
		_state.run_end_reason = "completed"
		_log.log_event(_state.tick_count, "RunScene", "Expedition complete — all route nodes traversed.", {})

	_refresh_display()

	# Check for pending incident
	if _state.pending_incident_id != "" and _state.run_end_reason == "":
		_show_incident_resolution()
		return

	# Check run end
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _show_incident_resolution() -> void:
	# Clear any previous incident UI
	for child in _incident_container.get_children():
		child.queue_free()

	var resolution := IncidentResolutionScene.new()
	_incident_container.add_child(resolution)
	resolution.setup(_state, _log)
	resolution.resolved.connect(_on_incident_resolved)
	_incident_container.visible = true
	_advance_button.visible = false


func _on_incident_resolved() -> void:
	_incident_container.visible = false
	_advance_button.visible = true
	_state.pending_incident_id = ""
	_refresh_display()
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _transition_to_run_end() -> void:
	_advance_button.visible = false
	_status_label.text = "Expedition ended: " + _state.run_end_reason
	# Brief pause then transition
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
	# Show last 5 log entries
	var entries := _log.get_entries()
	var recent := entries.slice(maxi(0, entries.size() - 5))
	var lines: Array[String] = []
	for entry: Dictionary in recent:
		lines.append("[%d] %s: %s" % [entry.get("tick", 0), entry.get("source", ""), entry.get("message", "")])
	_log_label.text = "\n".join(lines)
