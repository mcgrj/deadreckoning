# LogPanel.gd
# Left panel, fixed width ~270px. Prepend log feed — newest entries at top.
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
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.85))
	header.add_child(title_lbl)

	var live_lbl := Label.new()
	live_lbl.text = "● LIVE"
	live_lbl.add_theme_font_size_override("font_size", 13)
	live_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 0.35))
	header.add_child(live_lbl)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	_entry_container = VBoxContainer.new()
	_entry_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_container.add_theme_constant_override("separation", 5)
	_scroll.add_child(_entry_container)


# NOTE: Not idempotent — calling twice with the same tick will double-append entries.
# Prefer append_latest when possible (index-based, immune to repeats).
func append_tick_entries(log: SimulationLog, tick: int) -> void:
	for entry: Dictionary in log.get_entries_since(tick):
		_all_entries.append(entry)
		_add_entry_node(entry)
	_trim_rendered()


func append_latest(log: SimulationLog) -> void:
	var all := log.get_entries()
	var start := _all_entries.size()
	for i in range(start, all.size()):
		_all_entries.append(all[i])
		_add_entry_node(all[i])
	_trim_rendered()


func get_all_entries() -> Array[Dictionary]:
	return _all_entries


func _add_entry_node(entry: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	_entry_container.add_child(hbox)
	# Prepend: newest entry always appears at the top of the log
	_entry_container.move_child(hbox, 0)

	var tick_lbl := Label.new()
	tick_lbl.text = str(entry.get("tick", 0))
	tick_lbl.custom_minimum_size.x = 28
	tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tick_lbl.add_theme_font_size_override("font_size", 12)
	tick_lbl.add_theme_color_override("font_color", Color(0.38, 0.52, 0.66))
	hbox.add_child(tick_lbl)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 1)
	hbox.add_child(content_vbox)

	var source := entry.get("source", "event") as String
	var colors := _entry_colors(source)

	var src_lbl := Label.new()
	src_lbl.text = source.to_upper()
	src_lbl.add_theme_font_size_override("font_size", 11)
	src_lbl.add_theme_color_override("font_color", colors[0])
	content_vbox.add_child(src_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = entry.get("message", "")
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.add_theme_font_size_override("font_size", 14)
	msg_lbl.add_theme_color_override("font_color", colors[1])
	content_vbox.add_child(msg_lbl)


func _trim_rendered() -> void:
	var children := _entry_container.get_children()
	# Entries are prepended; trim from the BOTTOM (oldest entries are last)
	var excess := children.size() - MAX_RENDERED_ENTRIES
	for i in range(excess):
		children[children.size() - 1 - i].free()


# Tested in Stage7UITest
static func _entry_colors(source: String) -> Array[Color]:
	var s := source.to_upper()
	if s.contains("RESOLUTION") or s.contains("RESOLVED"):
		return [Color.html("#55aa66"), Color.html("#88dd88")]  # resolved
	if s.contains("INCIDENT"):
		return [Color.html("#cc6622"), Color.html("#ffcc88")]  # incident
	if s.contains("RUM") or s.contains("SUPPLY"):
		return [Color.html("#aa8833"), Color.html("#eebb55")]  # warn
	if s.contains("EFFECT"):
		return [Color.html("#5580a0"), Color.html("#88bbcc")]  # effect
	return [Color.html("#6090b0"), Color.html("#a0c8dc")]      # event
