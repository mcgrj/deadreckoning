# RunScene.gd
# Hosts the expedition tick loop. Top: StatsBar. Left: LogPanel. Right slot:
# RouteMapNode (swapped out for IncidentResolutionScene while incident is pending).
# Node selection triggers tick advancement. SPACE key also advances.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name RunScene
extends Control

var _state: ExpeditionState
var _log: SimulationLog
var _route: RouteMap

var _stats_bar: StatsBar
var _log_panel: LogPanel
var _route_map: RouteMapNode
var _right_slot: Control
var _breadcrumb: Label
var _status_label: Label


func _ready() -> void:
	var config := SaveManager.pending_run_config
	SaveManager.pending_run_config = {}
	_state = ExpeditionState.create_from_config(config)
	_log = SimulationLog.new()
	_route = RouteMap.create_test_map()
	_build_ui()
	_stats_bar.refresh(_state)


func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# Stats bar
	_stats_bar = StatsBar.new()
	_stats_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_stats_bar)

	root_vbox.add_child(HSeparator.new())

	# Main body: log + right side
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root_vbox.add_child(body)

	# Left: log panel
	_log_panel = LogPanel.new()
	_log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_log_panel)

	# Right: header strip + right slot
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 0)
	body.add_child(right_vbox)

	# Breadcrumb strip
	var header_strip := HBoxContainer.new()
	header_strip.custom_minimum_size.y = 28
	right_vbox.add_child(header_strip)

	_breadcrumb = Label.new()
	_breadcrumb.add_theme_font_size_override("font_size", 10)
	_breadcrumb.add_theme_color_override("font_color", Color(0.4, 0.6, 0.7))
	_breadcrumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_strip.add_child(_breadcrumb)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3))
	header_strip.add_child(_status_label)

	# Right slot container
	_right_slot = Control.new()
	_right_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(_right_slot)

	# Route map (permanent child; hidden during incidents)
	_route_map = RouteMapNode.new()
	_route_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_route_map.setup(_route, _state, _log)
	_route_map.node_selected.connect(_on_node_selected)
	_right_slot.add_child(_route_map)

	_refresh_breadcrumb()


func _refresh_breadcrumb() -> void:
	if _route.is_complete():
		_breadcrumb.text = "Route · Complete"
		return
	if _route.is_travelling():
		var node := _route.active_node as RouteNode
		_breadcrumb.text = "Route · Stage %d of %d · %s — %d day(s) remaining" % [
			_route.current_stage_index + 1, _route.stages.size(),
			node.category.to_upper(), _route.ticks_remaining]
	else:
		_breadcrumb.text = "Route · Stage %d of %d · Choose your heading" % [
			_route.current_stage_index + 1, _route.stages.size()]


func _on_node_selected(node: RouteNode) -> void:
	_route.select_node(node)
	_status_label.text = ""
	_refresh_breadcrumb()
	_route_map.refresh()
	_do_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_SPACE:
			_do_advance()


func _do_advance() -> void:
	if _state.run_end_reason != "":
		return
	if _state.pending_incident_id != "":
		_show_incident()
		return
	if _route.is_complete():
		_state.run_end_reason = "completed"
		_log.log_event(_state.tick_count, "RunScene", "Expedition complete.", {})
		_stats_bar.refresh(_state)
		_log_panel.append_latest(_log)
		_transition_to_run_end()
		return
	if not _route.is_travelling():
		_status_label.text = "Choose a heading first."
		return
	var zone := _route.get_active_zone()
	if zone == null:
		_status_label.text = "ERROR: zone not found"
		return

	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	_route.advance_tick()

	_stats_bar.refresh(_state)
	_log_panel.append_latest(_log)
	_route_map.refresh()
	_refresh_breadcrumb()

	if _state.pending_incident_id != "" and _state.run_end_reason == "":
		_show_incident()
		return
	if _state.run_end_reason != "":
		_log_panel.append_latest(_log)
		_transition_to_run_end()


func _show_incident() -> void:
	_route_map.hide()
	var scene := load("res://src/ui/IncidentResolutionScene.tscn").instantiate() as IncidentResolutionScene
	# setup() must come before add_child() so _state/_incident are set when _ready() fires
	scene.setup(_state, _log)
	_right_slot.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.resolved.connect(_on_incident_resolved)


func _on_incident_resolved() -> void:
	for child in _right_slot.get_children():
		if child != _route_map:
			child.queue_free()
	_route_map.show()
	_status_label.text = ""
	_stats_bar.refresh(_state)
	_log_panel.append_latest(_log)
	_route_map.refresh()
	_refresh_breadcrumb()
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _transition_to_run_end() -> void:
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	var run_end := load("res://src/ui/RunEndScene.tscn").instantiate() as RunEndScene
	run_end.final_state = _state
	var old := get_tree().current_scene
	get_tree().root.add_child(run_end)
	get_tree().current_scene = run_end
	old.queue_free()
