# StatsBar.gd
# Persistent top bar. Refresh via refresh(state). Never rebuilt mid-run.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name StatsBar
extends Control

const BAR_MAX_WIDTH := 120.0

var _ship_val: Label
var _food_val: Label
var _water_val: Label
var _rum_val: Label
var _clock: WorldClock
var _day_label: Label
var _burden_fill: ColorRect
var _burden_val: Label
var _command_fill: ColorRect
var _command_val: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 56)

	var root_hbox := HBoxContainer.new()
	root_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_hbox.add_theme_constant_override("separation", 16)
	add_child(root_hbox)

	# Left: secondary stats
	var left := HBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 20)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	root_hbox.add_child(left)

	_ship_val = _add_stat(left, "SHIP")
	_food_val = _add_stat(left, "FOOD")
	_water_val = _add_stat(left, "WATER")
	_rum_val = _add_stat(left, "RUM")

	# Centre: world clock
	var centre := HBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	root_hbox.add_child(centre)

	var clock_vbox := VBoxContainer.new()
	clock_vbox.add_theme_constant_override("separation", 2)
	clock_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(clock_vbox)

	_clock = WorldClock.new()
	_clock.custom_minimum_size = Vector2(80, 36)
	clock_vbox.add_child(_clock)

	_day_label = Label.new()
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.add_theme_font_size_override("font_size", 9)
	_day_label.add_theme_color_override("font_color", Color(0.29, 0.48, 0.67))
	_day_label.text = "Day 1 · DAWN"
	clock_vbox.add_child(_day_label)

	# Right: Burden + Command bars
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_theme_constant_override("separation", 6)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	root_hbox.add_child(right)

	var burden_result := _add_bar_row(right, "BURDEN", Color(1.0, 0.5, 0.1))
	_burden_val = burden_result[0]
	_burden_fill = burden_result[1]

	var command_result := _add_bar_row(right, "COMMAND", Color(0.2, 0.6, 1.0))
	_command_val = command_result[0]
	_command_fill = command_result[1]


func _add_stat(parent: HBoxContainer, key: String) -> Label:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	parent.add_child(vbox)

	var val := Label.new()
	val.text = "—"
	val.add_theme_font_size_override("font_size", 13)
	vbox.add_child(val)

	var lbl := Label.new()
	lbl.text = key
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.6))
	vbox.add_child(lbl)

	return val


func _add_bar_row(parent: VBoxContainer, label_text: String, fill_color: Color) -> Array:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	lbl.custom_minimum_size.x = 52
	hbox.add_child(lbl)

	var val := Label.new()
	val.add_theme_font_size_override("font_size", 11)
	val.custom_minimum_size.x = 24
	hbox.add_child(val)

	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(BAR_MAX_WIDTH, 6)
	bar_bg.color = Color(0.05, 0.07, 0.12)
	hbox.add_child(bar_bg)

	var fill := ColorRect.new()
	fill.color = fill_color
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_bg.add_child(fill)

	return [val, fill]


func refresh(state: ExpeditionState) -> void:
	_ship_val.text = "%d%%" % state.ship_condition
	_food_val.text = str(state.get_supply("food"))
	_water_val.text = str(state.get_supply("water"))
	_rum_val.text = str(state.get_supply("rum"))

	_day_label.text = "Day %d · %s" % [_day_from_tick(state.tick_count), _period_from_tick(state.tick_count)]
	_clock.refresh(state.tick_count)

	_burden_val.text = str(state.burden)
	_burden_fill.size.x = (float(state.burden) / 100.0) * BAR_MAX_WIDTH

	_command_val.text = str(state.command)
	_command_fill.size.x = (float(state.command) / 100.0) * BAR_MAX_WIDTH


# Tested in Stage7UITest
static func _day_from_tick(tick: int) -> int:
	return tick / 2 + 1


# Tested in Stage7UITest
static func _period_from_tick(tick: int) -> String:
	return "DAWN" if tick % 2 == 0 else "DUSK"
