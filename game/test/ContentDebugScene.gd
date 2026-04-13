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


func _ready() -> void:
	# Stage 1 — content catalog buttons
	$Sidebar/ValidateAll.pressed.connect(_on_validate_all_pressed)
	$Sidebar/Incidents.pressed.connect(_on_family_pressed.bind("incidents"))
	$Sidebar/Officers.pressed.connect(_on_family_pressed.bind("officers"))
	$Sidebar/Supplies.pressed.connect(_on_family_pressed.bind("supplies"))
	$Sidebar/StandingOrders.pressed.connect(_on_family_pressed.bind("standing_orders"))
	$Sidebar/Upgrades.pressed.connect(_on_family_pressed.bind("upgrades"))
	$Sidebar/Doctrines.pressed.connect(_on_family_pressed.bind("doctrines"))
	$Sidebar/CrewBackgrounds.pressed.connect(_on_family_pressed.bind("crew_backgrounds"))
	$Sidebar/ZoneTypes.pressed.connect(_on_family_pressed.bind("zone_types"))
	$Sidebar/Objectives.pressed.connect(_on_family_pressed.bind("objectives"))

	# Stage 2 — expedition sim buttons
	$Sidebar/NewExpedition.pressed.connect(_on_new_expedition)
	$Sidebar/ShowState.pressed.connect(_on_show_state)
	$Sidebar/ApplyEffect.pressed.connect(_on_apply_effect)
	$Sidebar/CheckCondition.pressed.connect(_on_check_condition)
	$Sidebar/Tick.pressed.connect(_on_tick)
	$Sidebar/MakePromise.pressed.connect(_on_make_promise)
	$Sidebar/KeepPromise.pressed.connect(_on_keep_promise)
	$Sidebar/BreakPromise.pressed.connect(_on_break_promise)
	$Sidebar/ToggleDamageTag.pressed.connect(_on_toggle_damage_tag)
	$Sidebar/SetMemoryFlag.pressed.connect(_on_set_memory_flag)
	$Sidebar/ToggleSpiritStore.pressed.connect(_on_toggle_spirit_store)
	$Sidebar/ShowLog.pressed.connect(_on_show_log)

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
