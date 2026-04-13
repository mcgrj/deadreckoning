# ContentDebugScene.gd
# Interactive debug scene for Dead Reckoning.
# Left sidebar: content family buttons + expedition sim controls.
# Right pane: scrollable output.
#
# Stage 1: Content catalog browsing and validation.
# Stage 2: Expedition state simulation.
extends HBoxContainer

@onready var _output: RichTextLabel = $OutputContainer/Output

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _effect_index: int = 0
var _condition_index: int = 0
var _route_map: RouteMap = null


func _ready() -> void:
	# Stage 1 — content catalog buttons
	$SidebarScroll/Sidebar/ValidateAll.pressed.connect(_on_validate_all_pressed)
	$SidebarScroll/Sidebar/Incidents.pressed.connect(_on_family_pressed.bind("incidents"))
	$SidebarScroll/Sidebar/Officers.pressed.connect(_on_family_pressed.bind("officers"))
	$SidebarScroll/Sidebar/Supplies.pressed.connect(_on_family_pressed.bind("supplies"))
	$SidebarScroll/Sidebar/StandingOrders.pressed.connect(_on_family_pressed.bind("standing_orders"))
	$SidebarScroll/Sidebar/Upgrades.pressed.connect(_on_family_pressed.bind("upgrades"))
	$SidebarScroll/Sidebar/Doctrines.pressed.connect(_on_family_pressed.bind("doctrines"))
	$SidebarScroll/Sidebar/CrewBackgrounds.pressed.connect(_on_family_pressed.bind("crew_backgrounds"))
	$SidebarScroll/Sidebar/ZoneTypes.pressed.connect(_on_family_pressed.bind("zone_types"))
	$SidebarScroll/Sidebar/Objectives.pressed.connect(_on_family_pressed.bind("objectives"))

	# Stage 2 — expedition sim buttons
	$SidebarScroll/Sidebar/NewExpedition.pressed.connect(_on_new_expedition)
	$SidebarScroll/Sidebar/ShowState.pressed.connect(_on_show_state)
	$SidebarScroll/Sidebar/ApplyEffect.pressed.connect(_on_apply_effect)
	$SidebarScroll/Sidebar/CheckCondition.pressed.connect(_on_check_condition)
	$SidebarScroll/Sidebar/Tick.pressed.connect(_on_tick)
	$SidebarScroll/Sidebar/MakePromise.pressed.connect(_on_make_promise)
	$SidebarScroll/Sidebar/KeepPromise.pressed.connect(_on_keep_promise)
	$SidebarScroll/Sidebar/BreakPromise.pressed.connect(_on_break_promise)
	$SidebarScroll/Sidebar/ToggleDamageTag.pressed.connect(_on_toggle_damage_tag)
	$SidebarScroll/Sidebar/SetMemoryFlag.pressed.connect(_on_set_memory_flag)
	$SidebarScroll/Sidebar/ToggleSpiritStore.pressed.connect(_on_toggle_spirit_store)
	$SidebarScroll/Sidebar/ShowLog.pressed.connect(_on_show_log)

	# Stage 3 — route map controls
	$SidebarScroll/Sidebar/ShowRoute.pressed.connect(_on_show_route)
	$SidebarScroll/Sidebar/AdvanceDay.pressed.connect(_on_advance_day)
	$SidebarScroll/Sidebar/ForceIncident.pressed.connect(_on_force_incident)
	_output.meta_clicked.connect(_on_route_meta_clicked)

	_show_validate_all()


# --- Stage 1: Content catalog ---

func _on_validate_all_pressed() -> void:
	_show_validate_all()


func _on_family_pressed(family: String) -> void:
	_show_family(family)


func _show_validate_all() -> void:
	_clear_output()
	_output.append_text("[b]Content Catalog — Validate All[/b]\n\n")
	for family: String in ContentRegistry.get_families():
		var items := ContentRegistry.get_all(family)
		_output.append_text("[b]%s[/b]: %d item(s)\n" % [family, items.size()])
	var errors := ContentRegistry.get_validation_errors()
	if errors.is_empty():
		_output.append_text("\n[color=green]PASS — no validation errors[/color]\n")
		_output.append_text("\nOverall: [color=green]VALID[/color]\n")
	else:
		_output.append_text("\n[color=red]FAIL — %d error(s):[/color]\n" % errors.size())
		for err: String in errors:
			_output.append_text("  • %s\n" % err)
		_output.append_text("\nOverall: [color=red]INVALID[/color]\n")


func _show_family(family: String) -> void:
	_clear_output()
	_output.append_text("[b]%s[/b]\n\n" % family)
	var items := ContentRegistry.get_all(family)
	if items.is_empty():
		_output.append_text("(no items loaded)\n")
		return
	for item: ContentBase in items:
		_output.append_text("• [b]%s[/b]  %s\n" % [item.id, item.display_name])
		if not item.category.is_empty():
			_output.append_text("  category: %s\n" % item.category)
		if not item.tags.is_empty():
			_output.append_text("  tags: %s\n" % ", ".join(item.tags))
		_output.append_text("\n")


# --- Stage 2: Expedition sim ---

func _ensure_expedition() -> bool:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active. Press 'New Expedition' first.[/color]\n")
		return false
	return true


func _on_new_expedition() -> void:
	_state = ExpeditionState.create_default()
	_log = SimulationLog.new()
	_effect_index = 0
	_condition_index = 0
	_clear_output()
	_output.append_text("[b]New Expedition Created[/b]\n\n")
	_show_state_summary()


func _on_show_state() -> void:
	if not _ensure_expedition():
		return
	_clear_output()
	_output.append_text("[b]Expedition State[/b]\n\n")
	_show_state_summary()


func _on_apply_effect() -> void:
	if not _ensure_expedition():
		return

	var effects: Array[Dictionary] = [
		{"type": "burden_change", "delta": 10, "label": "Burden +10"},
		{"type": "command_change", "delta": -5, "label": "Command -5"},
		{"type": "supply_change", "delta": -3, "target_id": "food", "label": "Food -3"},
		{"type": "add_damage_tag", "tag": "hull_strained", "label": "Add hull_strained"},
		{"type": "set_memory_flag", "flag_key": "test_flag", "label": "Set test_flag"},
		{"type": "ship_condition_change", "delta": -10, "label": "Ship condition -10"},
	]

	var def := effects[_effect_index % effects.size()]
	_effect_index += 1

	var e := EffectDef.new()
	e.type = def.type
	e.delta = def.get("delta", 0)
	e.target_id = def.get("target_id", "")
	e.flag_key = def.get("flag_key", "")
	e.tag = def.get("tag", "")

	EffectProcessor.apply(_state, e, _log)

	_clear_output()
	_output.append_text("[b]Applied Effect: %s[/b]\n\n" % def.label)
	_show_last_log_entry()
	_output.append_text("\n")
	_show_state_summary()


func _on_check_condition() -> void:
	if not _ensure_expedition():
		return

	var conditions: Array[Dictionary] = [
		{"type": "burden_above", "threshold": 50, "label": "Burden >= 50?"},
		{"type": "command_below", "threshold": 50, "label": "Command <= 50?"},
		{"type": "supply_below", "threshold": 10, "target_id": "food", "label": "Food <= 10?"},
		{"type": "has_damage_tag", "tag": "hull_strained", "label": "Has hull_strained?"},
		{"type": "has_memory_flag", "flag_key": "test_flag", "label": "Has test_flag?"},
		{"type": "officer_present", "target_id": "bosun", "label": "Bosun present?"},
	]

	var def := conditions[_condition_index % conditions.size()]
	_condition_index += 1

	var c := ConditionDef.new()
	c.type = def.type
	c.threshold = def.get("threshold", 0)
	c.target_id = def.get("target_id", "")
	c.flag_key = def.get("flag_key", "")
	c.tag = def.get("tag", "")

	var result := ConditionEvaluator.evaluate(_state, c, _log)

	_clear_output()
	_output.append_text("[b]Check Condition: %s[/b]\n\n" % def.label)
	if result:
		_output.append_text("[color=green]PASS[/color]\n\n")
	else:
		_output.append_text("[color=red]FAIL[/color]\n\n")
	_show_last_log_entry()


func _on_tick() -> void:
	if not _ensure_expedition():
		return
	_state.tick_count += 1
	RumRules.update_on_tick(_state, _log)
	_state.tick_promise(_log)
	_clear_output()
	_output.append_text("[b]Tick %d[/b]\n\n" % _state.tick_count)
	_show_state_summary()


func _on_make_promise() -> void:
	if not _ensure_expedition():
		return
	var result := _state.make_promise("landfall", "We will make landfall within five days", 5, _log)
	_clear_output()
	if result:
		_output.append_text("[b]Promise Made[/b]\n\n")
	else:
		_output.append_text("[color=yellow]Cannot make promise — one already active.[/color]\n\n")
	_show_state_summary()


func _on_keep_promise() -> void:
	if not _ensure_expedition():
		return
	if _state.active_promise.is_empty():
		_clear_output()
		_output.append_text("[color=yellow]No active promise to keep.[/color]\n")
		return
	_state.keep_promise(_log)
	_clear_output()
	_output.append_text("[b]Promise Kept[/b]\n\n")
	_show_state_summary()


func _on_break_promise() -> void:
	if not _ensure_expedition():
		return
	if _state.active_promise.is_empty():
		_clear_output()
		_output.append_text("[color=yellow]No active promise to break.[/color]\n")
		return
	_state.break_promise(_log)
	_clear_output()
	_output.append_text("[b]Promise Broken[/b]\n\n")
	_show_state_summary()


func _on_toggle_damage_tag() -> void:
	if not _ensure_expedition():
		return
	if _state.has_damage_tag("hull_strained"):
		_state.remove_damage_tag("hull_strained")
		_clear_output()
		_output.append_text("[b]Removed damage tag: hull_strained[/b]\n\n")
	else:
		_state.add_damage_tag("hull_strained")
		_clear_output()
		_output.append_text("[b]Added damage tag: hull_strained[/b]\n\n")
	_show_state_summary()


func _on_set_memory_flag() -> void:
	if not _ensure_expedition():
		return
	_state.add_memory_flag("test_event_occurred")
	_clear_output()
	_output.append_text("[b]Set memory flag: test_event_occurred[/b]\n\n")
	_show_state_summary()


func _on_toggle_spirit_store() -> void:
	if not _ensure_expedition():
		return
	_state.spirit_store_locked = not _state.spirit_store_locked
	_clear_output()
	var status := "LOCKED" if _state.spirit_store_locked else "UNLOCKED"
	_output.append_text("[b]Spirit Store: %s[/b]\n\n" % status)
	_show_state_summary()


func _on_show_log() -> void:
	if not _ensure_expedition():
		return
	_clear_output()
	_output.append_text("[b]Simulation Log[/b]\n\n")
	var entries := _log.get_entries()
	if entries.is_empty():
		_output.append_text("(no entries)\n")
		return
	# Reverse chronological
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		_output.append_text("[b]Tick %d[/b] [%s] %s\n" % [e.tick, e.source, e.message])


# --- Display helpers ---

func _clear_output() -> void:
	_output.clear()
	$OutputContainer.scroll_vertical = 0


func _show_state_summary() -> void:
	_output.append_text("[b]Burden:[/b] %d   [b]Command:[/b] %d   [b]Ship:[/b] %d   [b]Tick:[/b] %d\n\n" % [
		_state.burden, _state.command, _state.ship_condition, _state.tick_count])

	_output.append_text("[b]Supplies:[/b]\n")
	for supply_id: String in _state.supplies:
		_output.append_text("  %s: %d\n" % [supply_id, _state.supplies[supply_id]])

	if not _state.damage_tags.is_empty():
		_output.append_text("\n[b]Damage Tags:[/b] %s\n" % ", ".join(_state.damage_tags))

	if not _state.crew_traits.is_empty():
		_output.append_text("\n[b]Crew Traits:[/b] %s\n" % ", ".join(_state.crew_traits))

	_output.append_text("\n[b]Officers:[/b] %s\n" % ", ".join(_state.officers))

	if not _state.active_promise.is_empty():
		_output.append_text("\n[b]Promise:[/b] %s (%d ticks remaining)\n" % [
			_state.active_promise.text, _state.active_promise.ticks_remaining])
	else:
		_output.append_text("\n[b]Promise:[/b] (none)\n")

	if not _state.memory_flags.is_empty():
		_output.append_text("\n[b]Memory Flags:[/b] %s\n" % ", ".join(_state.memory_flags))

	_output.append_text("\n[b]Rum State:[/b] ration_expected=%s  store_locked=%s  theft_risk=%d  drunkenness_risk=%d\n" % [
		str(_state.rum_ration_expected), str(_state.spirit_store_locked),
		_state.rum_theft_risk, _state.rum_drunkenness_risk])

	_output.append_text("\n[b]Leadership:[/b] ")
	var tags: Array[String] = []
	for key: String in _state.leadership_tags:
		if _state.leadership_tags[key] != 0:
			tags.append("%s=%d" % [key, _state.leadership_tags[key]])
	if tags.is_empty():
		_output.append_text("(all neutral)\n")
	else:
		_output.append_text("%s\n" % ", ".join(tags))

	_output.append_text("\n[b]Stress:[/b] peak_burden=%d  min_command=%d  crew_losses=%d  supply_depletions=%d\n" % [
		_state.stress_indicators.peak_burden, _state.stress_indicators.min_command,
		_state.stress_indicators.crew_losses, _state.stress_indicators.supply_depletions])


func _show_last_log_entry() -> void:
	var entries := _log.get_entries()
	if entries.is_empty():
		return
	var e: Dictionary = entries[entries.size() - 1]
	_output.append_text("[b]Log:[/b] [%s] %s\n" % [e.source, e.message])


# --- Stage 3: Route Map ---

func _on_show_route() -> void:
	if _route_map == null:
		_route_map = RouteMap.create_test_map()
	if _state == null:
		_state = ExpeditionState.create_default()
		_log = SimulationLog.new()
	_clear_output()
	_render_route_map()


func _on_advance_day() -> void:
	if _route_map == null or _state == null:
		_clear_output()
		_output.append_text("[color=yellow]Press 'Show Route' first.[/color]\n")
		return
	if not _route_map.is_travelling():
		_clear_output()
		_output.append_text("[color=yellow]Not travelling — select a node from the route map first.[/color]\n")
		_render_route_map()
		return
	var zone = _route_map.get_active_zone()
	if zone == null:
		_clear_output()
		_output.append_text("[color=red]Error: active zone not found.[/color]\n")
		return
	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	_route_map.advance_tick()
	_clear_output()
	_render_route_map()


func _on_route_meta_clicked(meta: String) -> void:
	if not meta.begins_with("take_"):
		return
	if _route_map == null:
		return
	var node_id := meta.substr(5)
	var stage := _route_map.get_current_stage()
	for node: RouteNode in stage:
		if node.id == node_id:
			_route_map.select_node(node)
			_clear_output()
			_render_route_map()
			return


func _on_force_incident() -> void:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active. Press 'Show Route' first.[/color]\n")
		return

	_clear_output()

	# Case 1: pending_incident_id is set — apply first choice of that incident
	if not _state.pending_incident_id.is_empty():
		var incident_id := _state.pending_incident_id
		_state.pending_incident_id = ""  # always clear, even if lookup fails
		var incident = ContentRegistry.get_by_id("incidents", incident_id) as IncidentDef
		if incident != null and not incident.choices.is_empty():
			var choice: IncidentChoiceDef = incident.choices[0]
			EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
			for flag: String in choice.memory_flags_set:
				_state.add_memory_flag(flag)
			_log.log_event(_state.tick_count, "ForceIncident",
				"[%s] %s" % [incident.display_name, choice.log_text],
				{"incident_id": incident.id})
			_output.append_text("[b]Incident resolved: %s[/b]\n[color=#88ccff]%s[/color]\n\n" % [
				incident.display_name, choice.log_text])
			_show_state_summary()
			return

	# Case 2: scan for any eligible tick-band incident
	var triggered := false
	var incidents := ContentRegistry.get_all("incidents")
	for item: ContentBase in incidents:
		var incident = item as IncidentDef
		if incident == null or incident.trigger_band != "tick":
			continue
		if ConditionEvaluator.all_met(_state, incident.required_conditions, _log):
			if not incident.choices.is_empty():
				var choice: IncidentChoiceDef = incident.choices[0]
				EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
				for flag: String in choice.memory_flags_set:
					_state.add_memory_flag(flag)
				_log.log_event(_state.tick_count, "ForceIncident",
					"[%s] %s" % [incident.display_name, choice.log_text],
					{"incident_id": incident.id})
				_output.append_text("[b]Force-triggered: %s[/b]\n[color=#88ccff]%s[/color]\n\n" % [
					incident.display_name, choice.log_text])
				triggered = true
				break

	# Case 3: fallback — hardcoded squall
	if not triggered:
		var b = EffectDef.new()
		b.type = "burden_change"
		b.delta = 5
		EffectProcessor.apply(_state, b, _log)
		var d = EffectDef.new()
		d.type = "add_damage_tag"
		d.tag = "storm_damage"
		EffectProcessor.apply(_state, d, _log)
		_log.log_event(_state.tick_count, "ForceIncident",
			"A squall strikes without warning.", {})
		_output.append_text("[b]Fallback incident:[/b]\n[color=#ff9966]A squall strikes without warning. (Burden +5, storm_damage)[/color]\n\n")

	_show_state_summary()


func _render_route_map() -> void:
	# Category colour map
	var cat_colors := {
		"crisis":    "#ff9966",
		"landfall":  "#88ff88",
		"social":    "#ffdd66",
		"omen":      "#cc88ff",
		"boon":      "#aaffaa",
		"admiralty": "#ffccaa",
		"unknown":   "#88ccff",
	}

	# Header block
	var zone = _route_map.get_active_zone()
	var zone_name: String = zone.display_name if zone != null else "(at choice)"
	var wear_str: String = "%.1f× wear" % zone.ship_wear_modifier if zone != null else ""
	_output.append_text("[b]SHIP'S LOG[/b]\nDay %d\n\n" % _state.tick_count)
	_output.append_text("ZONE              STATE\n")
	_output.append_text("%-18s[color=#ff9966]Burden[/color] %d   [color=#88ccff]Command[/color] %d\n" % [
		zone_name, _state.burden, _state.command])
	if wear_str != "":
		_output.append_text("%-18s[color=#88ff88]Food[/color] %d     [color=#88ccff]Water[/color] %d\n" % [
			wear_str, _state.get_supply("food"), _state.get_supply("water")])
	else:
		_output.append_text("%-18s[color=#88ff88]Food[/color] %d     [color=#88ccff]Water[/color] %d\n" % [
			"", _state.get_supply("food"), _state.get_supply("water")])
	_output.append_text("\n")

	if _route_map.is_complete():
		_output.append_text("[color=#ffaaff][b]ARRIVED[/b][/color]\n\nThe expedition is complete.\n")
		return

	# Travelling progress indicator
	if _route_map.is_travelling():
		var an: RouteNode = _route_map.active_node
		var cat_color: String = cat_colors.get(an.category, "#ffffff")
		var progress := an.tick_distance - _route_map.ticks_remaining
		var bar := "█".repeat(progress) + "░".repeat(_route_map.ticks_remaining)
		var arrival_str := "arrival tomorrow" if _route_map.ticks_remaining == 1 else "%d days remaining" % _route_map.ticks_remaining
		_output.append_text("Travelling to [color=%s][b]%s[/b][/color] (%s)\n" % [
			cat_color, an.category.to_upper(), zone_name])
		_output.append_text("Day %d of %d  %s  %s\n\n" % [
			progress + 1, an.tick_distance, bar, arrival_str])

	# Route diagram
	_render_route_diagram(cat_colors)


func _render_route_diagram(cat_colors: Dictionary) -> void:
	var current_idx := _route_map.current_stage_index

	for s_idx in range(_route_map.stages.size()):
		var stage: Array = _route_map.stages[s_idx]
		var is_current := s_idx == current_idx
		var is_past := s_idx < current_idx

		if is_past:
			var done_node: RouteNode = _route_map.selected_path[s_idx]
			_output.append_text("[color=#333333]  ✓ [b]%s[/b] (%d days)[/color]\n" % [
				done_node.category.to_upper(), done_node.tick_distance])
		elif is_current and not _route_map.is_travelling():
			_output.append_text("[b]CHOOSE:[/b]\n")
			for node: RouteNode in stage:
				var col: String = cat_colors.get(node.category, "#ffffff")
				var bar := "█".repeat(node.tick_distance)
				_output.append_text("  [color=%s][b]%s[/b][/color]  %s  %d days\n" % [
					col, node.category.to_upper(), bar, node.tick_distance])
				if not node.hints.is_empty():
					_output.append_text("    [color=#888888]%s[/color]\n" % node.hints[0])
		else:
			_output.append_text("[color=#333333]  Stage %d: " % (s_idx + 1))
			var labels: Array[String] = []
			for node: RouteNode in stage:
				labels.append("%s(%d)" % [node.category.to_upper(), node.tick_distance])
			_output.append_text(", ".join(labels) + "[/color]\n")

		# Arrow spacer between stages
		if s_idx < _route_map.stages.size() - 1:
			var next_stage: Array = _route_map.stages[s_idx + 1]
			var min_dist := 9999
			for node: RouteNode in next_stage:
				if node.tick_distance < min_dist:
					min_dist = node.tick_distance
			var arrows := clampi(min_dist / 2, 1, 4)
			var arrow_color := "#222222" if s_idx < current_idx else "#555555"
			for _a in range(arrows):
				_output.append_text("[color=%s]  ↓[/color]\n" % arrow_color)

	# Arrival
	_output.append_text("[color=#1a1a1a]  ARRIVAL[/color]\n")

	# Selection buttons (meta links) if at a choice point
	if not _route_map.is_travelling() and not _route_map.is_complete():
		_output.append_text("\n")
		var stage: Array = _route_map.get_current_stage()
		for node: RouteNode in stage:
			_output.append_text('[url="take_%s"][color=#88aaff][ Take %s — %d days ][/color][/url]   ' % [
				node.id, node.category.to_upper(), node.tick_distance])
		_output.append_text("\n")
