# LogPanel.gd
# Left panel, fixed width ~270px. Append-only log feed. Never cleared mid-run.
# append_tick_entries(log, tick) — adds entries from that tick onward.
# append_latest(log) — catches up to any new entries since last append.
# get_all_entries() — exposes full history for ContentDebugScene log tab.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name LogPanel
extends Control

const MAX_RENDERED_ENTRIES := 200

var _all_entries: Array[Dictionary] = []
var _entry_container: VBoxContainer
var _scroll: ScrollContainer
var _user_scrolled: bool = false


func _ready() -> void:
	custom_minimum_size.x = 270

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 26
	header.add_theme_constant_override("separation", 4)
	vbox.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "SHIP'S LOG"
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", Color(0.29, 0.48, 0.67))
	header.add_child(title_lbl)

	var live_lbl := Label.new()
	live_lbl.text = "● LIVE"
	live_lbl.add_theme_font_size_override("font_size", 9)
	live_lbl.add_theme_color_override("font_color", Color(0.25, 0.6, 0.25))
	header.add_child(live_lbl)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

	_entry_container = VBoxContainer.new()
	_entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_container.add_theme_constant_override("separation", 3)
	_scroll.add_child(_entry_container)


func append_tick_entries(log: SimulationLog, tick: int) -> void:
	for entry: Dictionary in log.get_entries_since(tick):
		_all_entries.append(entry)
		_add_entry_node(entry)
	_trim_rendered()
	_auto_scroll()


func append_latest(log: SimulationLog) -> void:
	var all := log.get_entries()
	var start := _all_entries.size()
	for i in range(start, all.size()):
		_all_entries.append(all[i])
		_add_entry_node(all[i])
	_trim_rendered()
	_auto_scroll()


func get_all_entries() -> Array[Dictionary]:
	return _all_entries


func _add_entry_node(entry: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	_entry_container.add_child(hbox)

	var tick_lbl := Label.new()
	tick_lbl.text = str(entry.get("tick", 0))
	tick_lbl.custom_minimum_size.x = 28
	tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tick_lbl.add_theme_font_size_override("font_size", 10)
	tick_lbl.add_theme_color_override("font_color", Color(0.2, 0.3, 0.45))
	hbox.add_child(tick_lbl)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(content_vbox)

	var source := entry.get("source", "event") as String
	var colors := _entry_colors(source)

	var src_lbl := Label.new()
	src_lbl.text = source.to_upper()
	src_lbl.add_theme_font_size_override("font_size", 9)
	src_lbl.add_theme_color_override("font_color", colors[0])
	content_vbox.add_child(src_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = entry.get("message", "")
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.add_theme_font_size_override("font_size", 11)
	msg_lbl.add_theme_color_override("font_color", colors[1])
	content_vbox.add_child(msg_lbl)


func _trim_rendered() -> void:
	var children := _entry_container.get_children()
	var excess := children.size() - MAX_RENDERED_ENTRIES
	for i in range(excess):
		children[i].queue_free()


func _on_scroll_changed(value: float) -> void:
	var sb := _scroll.get_v_scroll_bar()
	_user_scrolled = value < sb.max_value - sb.page - 4.0


func _auto_scroll() -> void:
	if _user_scrolled:
		return
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value


# Tested in Stage7UITest
static func _entry_colors(source: String) -> Array[Color]:
	var s := source.to_upper()
	if s.contains("RESOLUTION") or s.contains("RESOLVED"):
		return [Color.html("#3a6040"), Color.html("#66aa66")]  # resolved
	if s.contains("INCIDENT"):
		return [Color.html("#804020"), Color.html("#ffaa66")]  # incident
	if s.contains("RUM") or s.contains("SUPPLY"):
		return [Color.html("#806040"), Color.html("#cc9944")]  # warn
	if s.contains("EFFECT"):
		return [Color.html("#2a3a4a"), Color.html("#4a7080")]  # effect
	return [Color.html("#4a6a8a"), Color.html("#7a9aaa")]      # event
