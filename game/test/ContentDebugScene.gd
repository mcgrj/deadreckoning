# ContentDebugScene.gd
# Standalone dev tool. Sidebar of grouped buttons + custom tab system.
# Owns its own ExpeditionState, RouteMap, and SimulationLog.
# Does not interact with SaveManager.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
extends HBoxContainer

const SIDEBAR_WIDTH := 150.0

# --- State ---
var _state: ExpeditionState = null
var _log: SimulationLog = null
var _route: RouteMap = null
var _effect_index: int = 0
var _condition_index: int = 0

# --- UI refs ---
var _tab_buttons: Dictionary = {}   # tab_name -> Button
var _tab_panes: Dictionary = {}     # tab_name -> Control
var _active_tab: String = ""

# Pane-internal refs updated on refresh
var _state_pane: Control = null
var _route_map_node: RouteMapNode = null
var _log_table: VBoxContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_sidebar()
	_build_main_area()
	_activate_tab("state")


# ── Sidebar ────────────────────────────────────────────────────────────────────

func _build_sidebar() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = SIDEBAR_WIDTH
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = SIDEBAR_WIDTH
	sidebar.add_theme_constant_override("separation", 2)
	scroll.add_child(sidebar)

	_sidebar_section(sidebar, "EXPEDITION")
	_sidebar_button(sidebar, "New Expedition", _on_new_expedition)
	_sidebar_button(sidebar, "Show State",     func() -> void: _activate_tab("state"))
	_sidebar_button(sidebar, "Tick",           _on_tick)
	_sidebar_button(sidebar, "Show Log",       func() -> void: _activate_tab("log"))

	_sidebar_section(sidebar, "EFFECTS")
	_sidebar_button(sidebar, "Apply Effect",   _on_apply_effect)
	_sidebar_button(sidebar, "Check Condition",_on_check_condition)

	_sidebar_section(sidebar, "PROMISES")
	_sidebar_button(sidebar, "Make Promise",   _on_make_promise)
	_sidebar_button(sidebar, "Keep Promise",   _on_keep_promise)
	_sidebar_button(sidebar, "Break Promise",  _on_break_promise)

	_sidebar_section(sidebar, "FLAGS")
	_sidebar_button(sidebar, "Toggle Damage Tag", _on_toggle_damage_tag)
	_sidebar_button(sidebar, "Set Memory Flag",   _on_set_memory_flag)

	_sidebar_section(sidebar, "ORDERS")
	_sidebar_button(sidebar, "Toggle Rationing",  _on_toggle_rationing)
	_sidebar_button(sidebar, "Toggle Spirit Store",_on_toggle_spirit_store)

	_sidebar_section(sidebar, "ROUTE")
	_sidebar_button(sidebar, "Show Route",        _on_show_route)
	_sidebar_button(sidebar, "Advance Day",        _on_advance_day)
	_sidebar_button(sidebar, "Force Incident",     _on_force_incident)

	_sidebar_section(sidebar, "CONTENT")
	_sidebar_button(sidebar, "Validate All",       func() -> void: _activate_tab("validate"))


func _sidebar_section(parent: VBoxContainer, title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.18, 0.25, 0.35))
	lbl.custom_minimum_size.y = 20
	parent.add_child(lbl)


func _sidebar_button(parent: VBoxContainer, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


# ── Main area: tab bar + content ───────────────────────────────────────────────

func _build_main_area() -> void:
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Tab bar (custom HBoxContainer of buttons)
	var tab_bar := HBoxContainer.new()
	tab_bar.custom_minimum_size.y = 34
	tab_bar.add_theme_constant_override("separation", 0)
	main_vbox.add_child(tab_bar)
	main_vbox.add_child(HSeparator.new())

	# Content area
	var content_area := Control.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_area)

	# Build tabs
	var tab_names := ["state", "route", "log", "incidents", "officers",
	                  "supplies", "standing_orders", "validate"]
	var tab_labels := {
		"state": "State", "route": "Route", "log": "Log",
		"incidents": "Incidents", "officers": "Officers",
		"supplies": "Supplies", "standing_orders": "Orders",
		"validate": "Validate"
	}

	for tab_name: String in tab_names:
		var btn := Button.new()
		btn.text = tab_labels.get(tab_name, tab_name)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_activate_tab.bind(tab_name))
		tab_bar.add_child(btn)
		_tab_buttons[tab_name] = btn

		# Build pane
		var pane := _build_tab_pane(tab_name)
		pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pane.visible = false
		content_area.add_child(pane)
		_tab_panes[tab_name] = pane


func _build_tab_pane(tab_name: String) -> Control:
	var scroll := ScrollContainer.new()
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)

	match tab_name:
		"state":
			_state_pane = inner
			# Populated by _refresh_state_pane()
		"route":
			_route_map_node = RouteMapNode.new()
			_route_map_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_route_map_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_route_map_node.custom_minimum_size = Vector2(300, 520)
			inner.add_child(_route_map_node)
		"log":
			_log_table = inner
			# Populated by _refresh_log_pane()
		"validate":
			# Populated by _refresh_validate_pane()
			inner.name = "validate_inner"
		_:
			# Content family tabs populated by _refresh_content_pane()
			inner.name = tab_name + "_inner"

	return scroll


func _activate_tab(tab_name: String) -> void:
	if not _tab_panes.has(tab_name):
		return
	for name: String in _tab_panes:
		_tab_panes[name].visible = (name == tab_name)
	for name: String in _tab_buttons:
		var btn := _tab_buttons[name] as Button
		btn.add_theme_color_override("font_color",
			Color(0.67, 0.83, 1.0) if name == tab_name else Color(0.25, 0.4, 0.55))
	_active_tab = tab_name
	_refresh_active_tab()


func _refresh_active_tab() -> void:
	match _active_tab:
		"state":    _refresh_state_pane()
		"log":      _refresh_log_pane()
		"validate": _refresh_validate_pane()
		"route":
			if _route != null and _route_map_node != null:
				_route_map_node.setup(_route, _state, _log)
		_:
			_refresh_content_pane(_active_tab)


# ── State pane ─────────────────────────────────────────────────────────────────

func _refresh_state_pane() -> void:
	if _state_pane == null:
		return
	for child in _state_pane.get_children():
		child.queue_free()
	await get_tree().process_frame  # let queue_free flush

	if _state == null:
		var placeholder := Label.new()
		placeholder.text = "(no expedition — click New Expedition)"
		placeholder.add_theme_color_override("font_color", Color(0.3, 0.4, 0.5))
		_state_pane.add_child(placeholder)
		return

	# 2×2 grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_state_pane.add_child(grid)

	grid.add_child(_state_block_core())
	grid.add_child(_state_block_supplies())
	grid.add_child(_state_block_tags())
	grid.add_child(_state_block_rum())

	# Promise
	if not _state.active_promise.is_empty():
		var promise_panel := PanelContainer.new()
		var promise_vbox := VBoxContainer.new()
		promise_panel.add_child(promise_vbox)
		var pt := Label.new()
		pt.text = "\"%s\"" % _state.active_promise.get("text", "")
		pt.add_theme_font_size_override("font_size", 10)
		promise_vbox.add_child(pt)
		var ps := Label.new()
		ps.text = "%d ticks remaining · type: %s" % [
			_state.active_promise.get("ticks_remaining", 0),
			_state.active_promise.get("id", "")]
		ps.add_theme_font_size_override("font_size", 9)
		ps.add_theme_color_override("font_color", Color(0.3, 0.55, 0.75))
		promise_vbox.add_child(ps)
		_state_pane.add_child(promise_panel)

	# Progression panel (Stage 6B data from SaveManager)
	var prog := SaveManager.load_progression()
	var prog_panel := PanelContainer.new()
	var prog_vbox := VBoxContainer.new()
	prog_panel.add_child(prog_vbox)

	var prog_title := Label.new()
	prog_title.text = "ADMIRALTY RECORD"
	prog_title.add_theme_font_size_override("font_size", 9)
	prog_title.add_theme_color_override("font_color", Color(0.3, 0.4, 0.5))
	prog_vbox.add_child(prog_title)

	if prog.admiralty_bias.is_empty() and prog.scandal_flags.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "(no Admiralty record)"
		empty_lbl.add_theme_font_size_override("font_size", 10)
		empty_lbl.add_theme_color_override("font_color", Color(0.25, 0.35, 0.4))
		prog_vbox.add_child(empty_lbl)
	else:
		if not prog.admiralty_bias.is_empty():
			prog_vbox.add_child(_tag_row(prog.admiralty_bias, Color.html("#ffccaa"), Color.html("#1a0f00")))
		if not prog.scandal_flags.is_empty():
			prog_vbox.add_child(_tag_row(prog.scandal_flags, Color.html("#ffdd66"), Color.html("#1a1400")))
		var score_lbl := Label.new()
		score_lbl.text = "Last difficulty: %d" % prog.last_run_difficulty_score
		score_lbl.add_theme_font_size_override("font_size", 10)
		prog_vbox.add_child(score_lbl)

	_state_pane.add_child(prog_panel)


func _state_block_core() -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_block_title(vbox, "CORE")
	_state_row(vbox, "Burden",         str(_state.burden),         Color.html("#ff9966"))
	_mini_bar(vbox, float(_state.burden) / 100.0, Color.html("#ff9966"))
	_state_row(vbox, "Command",        str(_state.command),        Color.html("#88ccff"))
	_mini_bar(vbox, float(_state.command) / 100.0, Color.html("#88ccff"))
	_state_row(vbox, "Ship condition", "%d%%" % _state.ship_condition, Color.html("#ffdd88"))
	_state_row(vbox, "Tick",           str(_state.tick_count),     Color(0.7, 0.7, 0.7))
	return panel


func _state_block_supplies() -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_block_title(vbox, "SUPPLIES")
	for supply_id: String in _state.supplies:
		_state_row(vbox, supply_id, str(_state.get_supply(supply_id)), Color(0.7, 0.85, 0.7))
	return panel


func _state_block_tags() -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_block_title(vbox, "TAGS & FLAGS")

	_block_subtitle(vbox, "Damage tags")
	vbox.add_child(_tag_row(_state.damage_tags,    Color.html("#ffaa44"), Color.html("#1a0a00")))
	_block_subtitle(vbox, "Memory flags")
	vbox.add_child(_tag_row(_state.memory_flags,   Color.html("#88ccff"), Color.html("#0a1520")))
	_block_subtitle(vbox, "Standing orders")
	vbox.add_child(_tag_row(_state.standing_orders,Color.html("#ffdd66"), Color.html("#1a1400")))
	_block_subtitle(vbox, "Officers")
	vbox.add_child(_tag_row(_state.officers,       Color.html("#aaffaa"), Color.html("#0a1a10")))
	return panel


func _state_block_rum() -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_block_title(vbox, "RUM STATE")
	_state_row(vbox, "ration expected", str(_state.rum_ration_expected),  Color.html("#ffaaaa"))
	_state_row(vbox, "store locked",    str(_state.spirit_store_locked),   Color(0.7, 0.7, 0.7))
	_state_row(vbox, "theft risk",      str(_state.rum_theft_risk),        Color.html("#ff9966"))
	_state_row(vbox, "drunkenness risk",str(_state.rum_drunkenness_risk),  Color.html("#ff9966"))
	_block_title(vbox, "LEADERSHIP")
	for tag: String in _state.leadership_tags:
		var val: int = _state.leadership_tags[tag]
		_state_row(vbox, tag, "+%d" % val if val >= 0 else str(val), Color(0.7, 0.75, 0.8))
	return panel


func _block_title(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.38, 0.5))
	parent.add_child(lbl)


func _block_subtitle(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.44, 0.5))
	parent.add_child(lbl)


func _state_row(parent: VBoxContainer, key: String, value: String, val_color: Color) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 10)
	k.add_theme_color_override("font_color", Color(0.35, 0.44, 0.5))
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(k)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 11)
	v.add_theme_color_override("font_color", val_color)
	hbox.add_child(v)


func _mini_bar(parent: VBoxContainer, fill: float, color: Color) -> void:
	var bg := ColorRect.new()
	bg.custom_minimum_size = Vector2(0, 3)
	bg.color = Color(0.07, 0.1, 0.16)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(bg)
	var fg := ColorRect.new()
	fg.color = color
	fg.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fg.size.x = clampf(fill, 0.0, 1.0)  # will be relative in final layout — best-effort here
	bg.add_child(fg)


func _tag_row(tags: Array, fg: Color, bg: Color) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	if tags.is_empty():
		var empty := Label.new()
		empty.text = "(none)"
		empty.add_theme_font_size_override("font_size", 9)
		empty.add_theme_color_override("font_color", Color(0.25, 0.35, 0.4))
		hbox.add_child(empty)
		return hbox
	for tag: String in tags:
		var lbl := Label.new()
		lbl.text = tag
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", fg)
		# StyleBox background
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 4; sb.content_margin_right = 4
		sb.content_margin_top = 1; sb.content_margin_bottom = 1
		lbl.add_theme_stylebox_override("normal", sb)
		hbox.add_child(lbl)
	return hbox


# ── Log pane ───────────────────────────────────────────────────────────────────

func _refresh_log_pane() -> void:
	if _log_table == null:
		return
	for child in _log_table.get_children():
		child.queue_free()
	await get_tree().process_frame

	if _log == null:
		return

	# Header row
	var header := _log_row("TICK", "SOURCE", "MESSAGE", true)
	_log_table.add_child(header)
	_log_table.add_child(HSeparator.new())

	for entry: Dictionary in _log.get_entries():
		_log_table.add_child(_log_row(
			str(entry.get("tick", 0)),
			entry.get("source", ""),
			entry.get("message", ""),
			false
		))


func _log_row(tick: String, source: String, message: String, is_header: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var lbl_tick := Label.new()
	lbl_tick.text = tick
	lbl_tick.custom_minimum_size.x = 28
	lbl_tick.add_theme_font_size_override("font_size", 10 if is_header else 11)
	lbl_tick.add_theme_color_override("font_color",
		Color(0.3, 0.45, 0.55) if is_header else Color(0.2, 0.3, 0.45))
	hbox.add_child(lbl_tick)

	var lbl_src := Label.new()
	lbl_src.text = source
	lbl_src.custom_minimum_size.x = 110
	lbl_src.add_theme_font_size_override("font_size", 10)
	lbl_src.add_theme_color_override("font_color",
		Color(0.3, 0.45, 0.55) if is_header else Color(0.29, 0.42, 0.54))
	hbox.add_child(lbl_src)

	var lbl_msg := Label.new()
	lbl_msg.text = message
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_msg.add_theme_font_size_override("font_size", 10 if is_header else 11)
	lbl_msg.add_theme_color_override("font_color",
		Color(0.3, 0.45, 0.55) if is_header else Color(0.4, 0.5, 0.55))
	hbox.add_child(lbl_msg)

	return hbox


# ── Validate pane ──────────────────────────────────────────────────────────────

func _refresh_validate_pane() -> void:
	var pane_scroll := _tab_panes.get("validate") as ScrollContainer
	if pane_scroll == null:
		return
	var inner := pane_scroll.get_child(0) as VBoxContainer
	if inner == null:
		return
	for child in inner.get_children():
		child.queue_free()
	await get_tree().process_frame

	var errors := ContentRegistry.get_validation_errors()
	var summary := Label.new()
	if errors.is_empty():
		summary.text = "PASS — no validation errors"
		summary.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		summary.text = "FAIL — %d error(s)" % errors.size()
		summary.add_theme_color_override("font_color", Color(1.0, 0.4, 0.27))
	inner.add_child(summary)

	for err: String in errors:
		var lbl := Label.new()
		lbl.text = "· " + err
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.5, 0.4))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		inner.add_child(lbl)

	# Also show family counts
	inner.add_child(HSeparator.new())
	for family: String in ContentRegistry.get_families():
		var items := ContentRegistry.get_all(family)
		var row := Label.new()
		row.text = "%s: %d item(s)" % [family, items.size()]
		row.add_theme_font_size_override("font_size", 10)
		row.add_theme_color_override("font_color", Color(0.4, 0.55, 0.6))
		inner.add_child(row)


# ── Content family pane ────────────────────────────────────────────────────────

func _refresh_content_pane(family: String) -> void:
	var pane_scroll := _tab_panes.get(family) as ScrollContainer
	if pane_scroll == null:
		return
	var inner := pane_scroll.get_child(0) as VBoxContainer
	if inner == null:
		return
	for child in inner.get_children():
		child.queue_free()
	await get_tree().process_frame

	var items := ContentRegistry.get_all(family)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	inner.add_child(header)
	for col_text: String in ["ID", "DISPLAY NAME", "CATEGORY", "TAGS"]:
		var h := Label.new()
		h.text = col_text
		h.add_theme_font_size_override("font_size", 9)
		h.add_theme_color_override("font_color", Color(0.25, 0.38, 0.5))
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(h)
	inner.add_child(HSeparator.new())

	for item: ContentBase in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		inner.add_child(row)

		var id_lbl := Label.new()
		id_lbl.text = item.id
		id_lbl.add_theme_font_size_override("font_size", 10)
		id_lbl.add_theme_color_override("font_color", Color(0.35, 0.5, 0.6))
		id_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(id_lbl)

		var name_lbl := Label.new()
		name_lbl.text = item.display_name if "display_name" in item else ""
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.6, 0.73, 0.8))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var cat_lbl := Label.new()
		cat_lbl.text = item.category if "category" in item else ""
		cat_lbl.add_theme_font_size_override("font_size", 10)
		cat_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.6))
		cat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cat_lbl)

		var tags_lbl := Label.new()
		tags_lbl.text = ", ".join(Array(item.tags)) if "tags" in item else ""
		tags_lbl.add_theme_font_size_override("font_size", 9)
		tags_lbl.add_theme_color_override("font_color", Color(0.35, 0.44, 0.5))
		tags_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tags_lbl)


# ── Sidebar button actions ─────────────────────────────────────────────────────

func _on_new_expedition() -> void:
	_state = ExpeditionState.create_default()
	_log = SimulationLog.new()
	_route = null
	_activate_tab("state")


func _on_tick() -> void:
	if _state == null:
		return
	var zone: ZoneTypeDef = null
	if _route != null and _route.is_travelling():
		zone = _route.get_active_zone()
	if zone == null:
		var all_zones := ContentRegistry.get_all("zone_types")
		if not all_zones.is_empty():
			zone = all_zones[0] as ZoneTypeDef
	if zone == null:
		return
	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	if _route != null and _route.is_travelling():
		_route.advance_tick()
	_refresh_active_tab()


func _on_apply_effect() -> void:
	if _state == null or _log == null:
		return
	var all_effects: Array = []
	for item: ContentBase in ContentRegistry.get_all("incidents"):
		var incident := item as IncidentDef
		if incident == null:
			continue
		for choice: IncidentChoiceDef in incident.choices:
			for eff: EffectDef in choice.immediate_effects:
				all_effects.append(eff)
	if all_effects.is_empty():
		return
	var eff: EffectDef = all_effects[_effect_index % all_effects.size()]
	_effect_index += 1
	EffectProcessor.apply_effects(_state, [eff], _log)
	_refresh_active_tab()


func _on_check_condition() -> void:
	if _state == null or _log == null:
		return
	var all_conditions: Array = []
	for item: ContentBase in ContentRegistry.get_all("incidents"):
		var incident := item as IncidentDef
		if incident == null or incident.trigger_condition == null:
			continue
		all_conditions.append(incident.trigger_condition)
	if all_conditions.is_empty():
		return
	var cond: ConditionDef = all_conditions[_condition_index % all_conditions.size()]
	_condition_index += 1
	var result := ConditionEvaluator.evaluate(_state, cond, _log)
	_log.log_event(_state.tick_count, "Debug", "Condition check result: %s" % str(result), {})
	_refresh_active_tab()


func _on_make_promise() -> void:
	if _state == null:
		return
	_state.active_promise = {
		"id": "debug_promise", "text": "We will make landfall within five days.",
		"deadline_ticks": _state.tick_count + 10, "ticks_remaining": 10
	}
	_refresh_active_tab()


func _on_keep_promise() -> void:
	if _state == null or _state.active_promise.is_empty():
		return
	_state.burden = maxi(0, _state.burden - 5)
	_state.command = mini(100, _state.command + 5)
	_state.active_promise = {}
	_refresh_active_tab()


func _on_break_promise() -> void:
	if _state == null or _state.active_promise.is_empty():
		return
	_state.burden = mini(100, _state.burden + 10)
	_state.command = maxi(0, _state.command - 10)
	_state.active_promise = {}
	_refresh_active_tab()


func _on_toggle_damage_tag() -> void:
	if _state == null:
		return
	var tag := "hull_strained"
	if tag in _state.damage_tags:
		_state.damage_tags.erase(tag)
	else:
		_state.damage_tags.append(tag)
	_refresh_active_tab()


func _on_set_memory_flag() -> void:
	if _state == null:
		return
	var flag := "test_event_occurred"
	if flag not in _state.memory_flags:
		_state.add_memory_flag(flag)
	_refresh_active_tab()


func _on_toggle_rationing() -> void:
	if _state == null:
		return
	var order := "tighten_rationing"
	if order in _state.standing_orders:
		_state.standing_orders.erase(order)
	else:
		_state.standing_orders.append(order)
	_refresh_active_tab()


func _on_toggle_spirit_store() -> void:
	if _state == null:
		return
	_state.spirit_store_locked = not _state.spirit_store_locked
	_refresh_active_tab()


func _on_show_route() -> void:
	if _state == null:
		_state = ExpeditionState.create_default()
		_log = SimulationLog.new()
	if _route == null:
		_route = RouteMap.create_test_map()
	if _route_map_node != null:
		_route_map_node.setup(_route, _state, _log)
	_activate_tab("route")


func _on_advance_day() -> void:
	if _state == null or _route == null:
		return
	if not _route.is_travelling():
		var stage := _route.get_current_stage()
		if not stage.is_empty():
			_route.select_node(stage[0])
	var zone := _route.get_active_zone()
	if zone == null:
		return
	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	_route.advance_tick()
	if _route_map_node != null:
		_route_map_node.refresh()
	_refresh_active_tab()


func _on_force_incident() -> void:
	if _state == null:
		return
	var incidents := ContentRegistry.get_all("incidents")
	if not incidents.is_empty():
		_state.pending_incident_id = (incidents[0] as IncidentDef).id
	_refresh_active_tab()
