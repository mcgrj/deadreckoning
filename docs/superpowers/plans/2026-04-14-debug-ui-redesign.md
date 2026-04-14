# Debug UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three debug/run screens (RunScene, IncidentResolutionScene, ContentDebugScene) with a cohesive, scannable UI using shared StatsBar + LogPanel components and a custom Slay-the-Spire-style route map.

**Architecture:** Two shared components (StatsBar, LogPanel) are extracted as reusable scenes. RunScene uses a "right slot" pattern: RouteMapNode and IncidentResolutionScene swap in/out. ContentDebugScene is a standalone dev tool with a sidebar + custom tab system. All UI is built programmatically in `_ready()` — no @onready refs to .tscn node paths.

**Tech Stack:** Godot 4.6 GDScript, `Control._draw()` for custom rendering, cubic bezier formula for route paths, headless GDScript test runner.

---

## File Map

**Create:**
- `game/src/ui/StatsBar.gd` — persistent top bar; `refresh(state: ExpeditionState)`
- `game/src/ui/StatsBar.tscn` — minimal scene (root Control + script)
- `game/src/ui/WorldClock.gd` — horizon-arc Control child of StatsBar; `refresh(tick: int)`
- `game/src/ui/LogPanel.gd` — append-only log feed; `append_tick_entries()`, `append_latest()`
- `game/src/ui/LogPanel.tscn` — minimal scene (root Control + script)
- `game/src/ui/RouteMapNode.gd` — vertical bezier node map; `setup()`, `refresh()`; emits `node_selected`
- `game/src/ui/RouteMapNode.tscn` — minimal scene (root Control + script)
- `game/test/Stage7UITest.gd` — headless tests for pure logic in StatsBar, LogPanel, RouteMapNode
- `game/test/Stage7UITest.tscn` — minimal scene (root Node + script)

**Modify/Replace:**
- `game/src/ui/RunScene.gd` — full rewrite: uses StatsBar + LogPanel + RouteMapNode, right-slot swap
- `game/src/ui/RunScene.tscn` — stripped to root Control + script
- `game/src/ui/IncidentResolutionScene.gd` — full rewrite: programmatic cards, signal-only coupling
- `game/src/ui/IncidentResolutionScene.tscn` — stripped to root Control + script
- `game/test/ContentDebugScene.gd` — full rewrite: sidebar + custom tabs
- `game/test/ContentDebugScene.tscn` — stripped to root HBoxContainer + script

---

## Task 1: StatsBar — tests, then implementation

**Files:**
- Create: `game/test/Stage7UITest.gd`
- Create: `game/test/Stage7UITest.tscn`
- Create: `game/src/ui/StatsBar.gd`
- Create: `game/src/ui/WorldClock.gd`
- Create: `game/src/ui/StatsBar.tscn`

### Step 1.1 — Write the failing test

Create `game/test/Stage7UITest.gd`:

```gdscript
# Stage7UITest.gd
# Headless test suite for Stage 7: Debug UI Redesign.
# Tests pure-logic helpers extracted from StatsBar, LogPanel, RouteMapNode.
# Run: godot --headless --path game res://test/Stage7UITest.tscn
extends Node

var _pass := 0
var _fail := 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
		_pass += 1
	else:
		push_error("  FAIL: " + label)
		_fail += 1


func _ready() -> void:
	print("=== Stage7UITest ===\n")
	_test_stats_bar_clock()
	# LogPanel and RouteMapNode tests added in later tasks
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# ── StatsBar ─────────────────────────────────────────────────────────────────

func _test_stats_bar_clock() -> void:
	print("-- StatsBar clock helpers --")
	check(StatsBar._day_from_tick(0) == 1,  "tick 0 → day 1")
	check(StatsBar._day_from_tick(1) == 1,  "tick 1 → day 1")
	check(StatsBar._day_from_tick(2) == 2,  "tick 2 → day 2")
	check(StatsBar._day_from_tick(3) == 2,  "tick 3 → day 2")
	check(StatsBar._day_from_tick(9) == 5,  "tick 9 → day 5")
	check(StatsBar._period_from_tick(0) == "DAWN", "tick 0 → DAWN")
	check(StatsBar._period_from_tick(1) == "DUSK", "tick 1 → DUSK")
	check(StatsBar._period_from_tick(2) == "DAWN", "tick 2 → DAWN")
	check(StatsBar._period_from_tick(7) == "DUSK", "tick 7 → DUSK")
```

Create `game/test/Stage7UITest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/Stage7UITest.gd" id="1"]

[node name="Stage7UITest" type="Node"]
script = ExtResource("1")
```

### Step 1.2 — Run the test to verify it fails

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -20
```

Expected: error about `StatsBar` class not found (parse error or "Identifier not declared").

### Step 1.3 — Implement StatsBar

Create `game/src/ui/StatsBar.gd`:

```gdscript
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
```

Create `game/src/ui/WorldClock.gd`:

```gdscript
# WorldClock.gd
# Horizon-arc Control child of StatsBar.
# Draws a sun arc showing DAWN/DUSK based on tick_count.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name WorldClock
extends Control

var _tick_count: int = 0


func refresh(tick: int) -> void:
	_tick_count = tick
	queue_redraw()


func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.75
	var r := minf(size.x * 0.4, size.y * 0.65)

	# Horizon line
	draw_line(Vector2(4, cy), Vector2(size.x - 4, cy), Color(0.15, 0.22, 0.35), 1.0)

	# Sky arc (upper half-circle)
	draw_arc(Vector2(cx, cy), r, PI, 2 * PI, 32, Color(0.1, 0.2, 0.35), 1.5)

	# Sun position: dawn = left (angle ~135°), dusk = right (angle ~45°)
	var is_dawn := _tick_count % 2 == 0
	var sun_color := Color(1.0, 0.72, 0.3) if is_dawn else Color(1.0, 0.35, 0.1)
	var sun_angle_deg := 135.0 if is_dawn else 45.0
	var sun_angle := deg_to_rad(sun_angle_deg)
	var sun_pos := Vector2(cx + r * cos(sun_angle), cy - r * sin(sun_angle))
	draw_circle(sun_pos, 5.0, sun_color)
```

Create `game/src/ui/StatsBar.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/StatsBar.gd" id="1"]

[node name="StatsBar" type="Control"]
script = ExtResource("1")
```

### Step 1.4 — Run the test to verify it passes

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -10
```

Expected output:
```
  PASS: tick 0 → day 1
  PASS: tick 1 → day 1
  ...
  PASS: tick 7 → DUSK

--- Results: 9 passed, 0 failed ---
ALL PASS
```

### Step 1.5 — Commit

```bash
git add game/src/ui/StatsBar.gd game/src/ui/WorldClock.gd game/src/ui/StatsBar.tscn \
        game/test/Stage7UITest.gd game/test/Stage7UITest.tscn
git commit -m "$(cat <<'EOF'
feat: add StatsBar + WorldClock components with tests

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: LogPanel — tests, then implementation

**Files:**
- Modify: `game/test/Stage7UITest.gd`
- Create: `game/src/ui/LogPanel.gd`
- Create: `game/src/ui/LogPanel.tscn`

### Step 2.1 — Add failing tests to Stage7UITest.gd

Add a call to `_test_log_panel_colors()` in `_ready()` and add the function body. Edit `game/test/Stage7UITest.gd`:

Change the `_ready()` body:
```gdscript
func _ready() -> void:
	print("=== Stage7UITest ===\n")
	_test_stats_bar_clock()
	_test_log_panel_colors()
	_finish()
```

Append the new test function at the end of the file:

```gdscript
# ── LogPanel ─────────────────────────────────────────────────────────────────

func _test_log_panel_colors() -> void:
	print("-- LogPanel entry colors --")
	var c := LogPanel._entry_colors("IncidentResolution")
	check(c.size() == 2, "entry_colors returns 2 elements")
	# "resolved" type → source color is greenish (#3a6040)
	check(c[0].g > c[0].r, "resolved source color is green-dominant")

	var c2 := LogPanel._entry_colors("RumRules")
	# "warn" type → message color is yellowish (#cc9944)
	check(c2[1].r > c2[1].b, "warn message color is warm")

	var c3 := LogPanel._entry_colors("TravelSimulator")
	# "event" type → source color is blue-grey (#4a6a8a)
	check(c3[0].b > c3[0].r, "event source color is blue-dominant")

	var c4 := LogPanel._entry_colors("EffectProcessor")
	# "effect" type → both colors are dark blue
	check(c4[0].b >= c4[0].r, "effect source color has blue >= red")
```

### Step 2.2 — Run to verify it fails

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -10
```

Expected: parse/identifier error on `LogPanel`.

### Step 2.3 — Implement LogPanel

Create `game/src/ui/LogPanel.gd`:

```gdscript
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
```

Create `game/src/ui/LogPanel.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/LogPanel.gd" id="1"]

[node name="LogPanel" type="Control"]
script = ExtResource("1")
```

### Step 2.4 — Run tests to verify all pass

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -12
```

Expected output:
```
  PASS: tick 0 → day 1
  ...
  PASS: event source color is blue-dominant
  PASS: effect source color has blue >= red

--- Results: 13 passed, 0 failed ---
ALL PASS
```

### Step 2.5 — Commit

```bash
git add game/src/ui/LogPanel.gd game/src/ui/LogPanel.tscn game/test/Stage7UITest.gd
git commit -m "$(cat <<'EOF'
feat: add LogPanel component with tests

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: RouteMapNode — tests, then implementation

**Files:**
- Modify: `game/test/Stage7UITest.gd`
- Create: `game/src/ui/RouteMapNode.gd`
- Create: `game/src/ui/RouteMapNode.tscn`

### Step 3.1 — Add failing tests

Change `_ready()` in `game/test/Stage7UITest.gd`:
```gdscript
func _ready() -> void:
	print("=== Stage7UITest ===\n")
	_test_stats_bar_clock()
	_test_log_panel_colors()
	_test_route_map_node_geometry()
	_finish()
```

Append the new test function:

```gdscript
# ── RouteMapNode ─────────────────────────────────────────────────────────────

func _test_route_map_node_geometry() -> void:
	print("-- RouteMapNode geometry --")

	# _stage_y: with 4 stages, step = 410/5 = 82 → stage 0 = 408, stage 3 = 162
	var step4 := 410.0 / 5.0
	check(is_equal_approx(RouteMapNode._stage_y(0, 4), 490.0 - step4 * 1), "stage_y(0,4)")
	check(is_equal_approx(RouteMapNode._stage_y(3, 4), 490.0 - step4 * 4), "stage_y(3,4)")

	# _stage_y: with 1 stage, step = 410/2 = 205 → y = 285
	check(is_equal_approx(RouteMapNode._stage_y(0, 1), 285.0), "stage_y(0,1)")

	# _node_x: 1 node → centred at 150
	check(is_equal_approx(RouteMapNode._node_x(0, 1), 150.0), "node_x single centred")

	# _node_x: 2 nodes → 65, 235
	check(is_equal_approx(RouteMapNode._node_x(0, 2), 65.0),  "node_x 2-node left")
	check(is_equal_approx(RouteMapNode._node_x(1, 2), 235.0), "node_x 2-node right")

	# _node_x: 3 nodes → 65, 150, 235
	check(is_equal_approx(RouteMapNode._node_x(0, 3), 65.0),  "node_x 3-node left")
	check(is_equal_approx(RouteMapNode._node_x(1, 3), 150.0), "node_x 3-node centre")
	check(is_equal_approx(RouteMapNode._node_x(2, 3), 235.0), "node_x 3-node right")

	# _bezier_point: t=0 → p0, t=1 → p3
	var p0 := Vector2(0, 0)
	var p1 := Vector2(0, 50)
	var p2 := Vector2(100, 50)
	var p3 := Vector2(100, 100)
	check(RouteMapNode._bezier_point(p0, p1, p2, p3, 0.0).is_equal_approx(p0), "bezier t=0 → p0")
	check(RouteMapNode._bezier_point(p0, p1, p2, p3, 1.0).is_equal_approx(p3), "bezier t=1 → p3")
	var mid := RouteMapNode._bezier_point(p0, p1, p2, p3, 0.5)
	check(mid.x > 0.0 and mid.x < 100.0, "bezier midpoint x in (0,100)")
	check(mid.y > 0.0 and mid.y < 100.0, "bezier midpoint y in (0,100)")
```

### Step 3.2 — Run to verify it fails

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -10
```

Expected: error on `RouteMapNode` identifier not found.

### Step 3.3 — Implement RouteMapNode

Create `game/src/ui/RouteMapNode.gd`:

```gdscript
# RouteMapNode.gd
# Vertical Slay-the-Spire-style node map. Renders via _draw().
# setup(route, state, log) — initialises. refresh() — call after each tick.
# Emits node_selected(node: RouteNode) when a reachable node is clicked.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name RouteMapNode
extends Control

# Canvas dimensions
const CANVAS_W := 300.0
const CANVAS_H := 520.0
const DEPART_Y := 490.0
const ARRIVAL_Y := 80.0
const NODE_RADIUS := 26.0
const BEZIER_SEGMENTS := 20
const TICK_DOT_RADIUS := 4.5
const NODE_MARGIN := 65.0

# Category colours: [background Color, stroke Color]
const CATEGORY_COLORS: Dictionary = {
	"crisis":    ["#2a1200", "#ff9966"],
	"landfall":  ["#001800", "#88ff88"],
	"social":    ["#1a1400", "#ffdd66"],
	"omen":      ["#180a28", "#cc88ff"],
	"boon":      ["#001a05", "#aaffaa"],
	"admiralty": ["#1a0f00", "#ffccaa"],
	"start":     ["#0a1a2a", "#4a7aaa"],
	"arrival":   ["#1a1a00", "#ffffaa"],
	"unknown":   ["#0c0c18", "#7a7aaa"],
}

signal node_selected(node: RouteNode)

var _route: RouteMap = null
var _state: ExpeditionState = null
var _log: SimulationLog = null
var _offset: Vector2 = Vector2.ZERO
var _hovered_node: RouteNode = null
var _glow_phase: float = 0.0


func setup(route: RouteMap, state: ExpeditionState, log: SimulationLog) -> void:
	_route = route
	_state = state
	_log = log
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0 / 30.0
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		_glow_phase = fmod(_glow_phase + 0.1, TAU)
		queue_redraw()
	)
	add_child(timer)
	set_process(true)
	set_process_unhandled_input(true)


func _process(_delta: float) -> void:
	if _route == null:
		return
	var mouse := get_global_mouse_position() - global_position - _offset
	var new_hover: RouteNode = null
	for node: RouteNode in _all_nodes():
		if _node_canvas_pos(node).distance_to(mouse) < NODE_RADIUS:
			new_hover = node
			break
	if new_hover != _hovered_node:
		_hovered_node = new_hover
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _route == null or _route.is_travelling():
		return
	var mouse := mb.global_position - global_position - _offset
	for node: RouteNode in _route.get_current_stage():
		if _node_canvas_pos(node).distance_to(mouse) < NODE_RADIUS:
			node_selected.emit(node)
			return


func _draw() -> void:
	if _route == null:
		return
	_offset = Vector2((size.x - CANVAS_W) * 0.5, (size.y - CANVAS_H) * 0.5)
	_draw_paths()
	_draw_tick_dots()
	_draw_boat()
	_draw_nodes()
	_draw_stage_labels()


# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_paths() -> void:
	if _route.stages.is_empty():
		return
	var depart := Vector2(CANVAS_W * 0.5, DEPART_Y) + _offset
	var arrival := Vector2(CANVAS_W * 0.5, ARRIVAL_Y) + _offset

	# Depart → stage 0
	for node: RouteNode in _route.stages[0]:
		var to := _node_canvas_pos(node) + _offset
		var col := _path_color(node)
		_draw_bezier(depart, depart + Vector2(0, -80), to + Vector2(0, 80), to, col, 1.5)

	# Stage i → stage i+1
	for si in range(_route.stages.size() - 1):
		for from_node: RouteNode in _route.stages[si]:
			var fp := _node_canvas_pos(from_node) + _offset
			for to_node: RouteNode in _route.stages[si + 1]:
				var tp := _node_canvas_pos(to_node) + _offset
				var col := _path_color(to_node)
				_draw_bezier(fp, fp + Vector2(0, -80), tp + Vector2(0, 80), tp, col, 1.5)

	# Last stage → arrival
	for node: RouteNode in _route.stages[-1]:
		var fp := _node_canvas_pos(node) + _offset
		var col := _path_color(node)
		_draw_bezier(fp, fp + Vector2(0, -80), arrival + Vector2(0, 80), arrival, col, 1.5)


func _path_color(node: RouteNode) -> Color:
	var stroke := _stroke_color(node.category)
	match _node_state(node):
		"visited":   return Color(stroke.r, stroke.g, stroke.b, 0.4)
		"current":   return Color(stroke.r, stroke.g, stroke.b, 0.5)
		"reachable": return Color(stroke.r, stroke.g, stroke.b, 0.25)
		_:           return Color(0.6, 0.6, 0.7, 0.06)


func _draw_tick_dots() -> void:
	if _route.active_node == null:
		return
	var node := _route.active_node
	var tick_dist := node.tick_distance
	if tick_dist <= 0:
		return

	var from_pos := _active_leg_from_pos()
	var to_pos := _node_canvas_pos(node) + _offset
	var ticks_done := tick_dist - _route.ticks_remaining

	var stroke := _stroke_color(node.category)
	for i in range(tick_dist):
		var t := (float(i) + 0.5) / float(tick_dist)
		var p := _bezier_point(from_pos, from_pos + Vector2(0, -80),
		                       to_pos + Vector2(0, 80), to_pos, t)
		var is_done := i < ticks_done
		if is_done:
			draw_circle(p, TICK_DOT_RADIUS, Color(stroke.r, stroke.g, stroke.b, 0.9))
		else:
			draw_arc(p, TICK_DOT_RADIUS, 0.0, TAU, 16,
			         Color(stroke.r, stroke.g, stroke.b, 0.5), 1.5)


func _draw_boat() -> void:
	if _route.active_node == null:
		return
	var node := _route.active_node
	var tick_dist := node.tick_distance
	if tick_dist <= 0:
		return
	var ticks_done := tick_dist - _route.ticks_remaining
	var t := clampf((float(ticks_done) - 0.5) / float(tick_dist), 0.0, 1.0)

	var from_pos := _active_leg_from_pos()
	var to_pos := _node_canvas_pos(node) + _offset
	var boat_pos := _bezier_point(from_pos, from_pos + Vector2(0, -80),
	                              to_pos + Vector2(0, 80), to_pos, t)

	var glow_a := 0.35 + 0.15 * sin(_glow_phase)
	draw_arc(boat_pos, 9.0, 0.0, TAU, 24, Color(0.67, 0.83, 1.0, glow_a), 1.5)
	draw_string(ThemeDB.fallback_font, boat_pos + Vector2(-8, 6), "⛵",
	            HORIZONTAL_ALIGNMENT_LEFT, -1, 16)


func _draw_nodes() -> void:
	var depart := Vector2(CANVAS_W * 0.5, DEPART_Y) + _offset
	draw_circle(depart, 10.0, Color(0.1, 0.2, 0.3))
	draw_arc(depart, 10.0, 0.0, TAU, 24, Color(0.4, 0.6, 0.8), 2.0)

	var arrival := Vector2(CANVAS_W * 0.5, ARRIVAL_Y) + _offset
	draw_circle(arrival, 10.0, Color(0.1, 0.1, 0.05))
	draw_arc(arrival, 10.0, 0.0, TAU, 24, Color(0.8, 0.8, 0.4), 2.0)

	for stage: Array in _route.stages:
		for node: RouteNode in stage:
			_draw_node(node)


func _draw_node(node: RouteNode) -> void:
	var pos := _node_canvas_pos(node) + _offset
	var bg := _bg_color(node.category)
	var stroke := _stroke_color(node.category)
	var state := _node_state(node)

	var opacity: float
	var stroke_w: float
	match state:
		"visited":   opacity = 0.22; stroke_w = 2.0
		"current":   opacity = 1.0;  stroke_w = 3.0
		"reachable": opacity = 1.0;  stroke_w = 2.0
		_:           opacity = 0.13; stroke_w = 2.0

	if state == "current":
		var ga := 0.15 + 0.10 * sin(_glow_phase)
		draw_circle(pos, NODE_RADIUS + 8.0, Color(stroke.r, stroke.g, stroke.b, ga))
	elif state == "reachable":
		var ga := 0.08 + 0.06 * sin(_glow_phase * 0.7)
		draw_circle(pos, NODE_RADIUS + 5.0, Color(stroke.r, stroke.g, stroke.b, ga))

	draw_circle(pos, NODE_RADIUS, Color(bg.r, bg.g, bg.b, opacity))
	draw_arc(pos, NODE_RADIUS, 0.0, TAU, 32,
	         Color(stroke.r, stroke.g, stroke.b, opacity), stroke_w)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-10, 4),
	            node.category.substr(0, 3).to_upper(),
	            HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
	            Color(stroke.r, stroke.g, stroke.b, opacity * 0.8))


func _draw_stage_labels() -> void:
	for si in range(_route.stages.size()):
		var y := _stage_y(si, _route.stages.size())
		draw_string(ThemeDB.fallback_font,
		            Vector2(CANVAS_W - 2, y + 4) + _offset,
		            "S%d" % (si + 1),
		            HORIZONTAL_ALIGNMENT_RIGHT, -1, 9,
		            Color(0.2, 0.35, 0.5))


# ── Helpers ───────────────────────────────────────────────────────────────────

func _all_nodes() -> Array[RouteNode]:
	var result: Array[RouteNode] = []
	if _route == null:
		return result
	for stage: Array in _route.stages:
		for n: RouteNode in stage:
			result.append(n)
	return result


func _node_state(node: RouteNode) -> String:
	if node in _route.selected_path:
		return "visited"
	if _route.active_node == node:
		return "current"
	if not _route.is_travelling() and node in _route.get_current_stage():
		return "reachable"
	return "locked"


func _node_canvas_pos(node: RouteNode) -> Vector2:
	for si in range(_route.stages.size()):
		var stage: Array = _route.stages[si]
		for ni in range(stage.size()):
			if stage[ni] == node:
				return Vector2(_node_x(ni, stage.size()), _stage_y(si, _route.stages.size()))
	return Vector2.ZERO


func _active_leg_from_pos() -> Vector2:
	if _route.selected_path.is_empty():
		return Vector2(CANVAS_W * 0.5, DEPART_Y) + _offset
	return _node_canvas_pos(_route.selected_path[-1]) + _offset


func _bg_color(category: String) -> Color:
	var entry: Array = CATEGORY_COLORS.get(category, CATEGORY_COLORS["unknown"])
	return Color.html(entry[0])


func _stroke_color(category: String) -> Color:
	var entry: Array = CATEGORY_COLORS.get(category, CATEGORY_COLORS["unknown"])
	return Color.html(entry[1])


func _draw_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
                  color: Color, width: float) -> void:
	var prev := p0
	for i in range(1, BEZIER_SEGMENTS + 1):
		var t := float(i) / float(BEZIER_SEGMENTS)
		var q := _bezier_point(p0, p1, p2, p3, t)
		draw_line(prev, q, color, width)
		prev = q


# ── Pure geometry — tested in Stage7UITest ────────────────────────────────────

static func _stage_y(stage_index: int, total_stages: int) -> float:
	var usable := DEPART_Y - ARRIVAL_Y
	var step := usable / float(total_stages + 1)
	return DEPART_Y - step * float(stage_index + 1)


static func _node_x(node_index: int, node_count: int) -> float:
	if node_count == 1:
		return CANVAS_W * 0.5
	var spacing := (CANVAS_W - 2.0 * NODE_MARGIN) / float(node_count - 1)
	return NODE_MARGIN + spacing * float(node_index)


static func _bezier_point(p0: Vector2, p1: Vector2,
                           p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var mt := 1.0 - t
	return mt*mt*mt*p0 + 3.0*mt*mt*t*p1 + 3.0*mt*t*t*p2 + t*t*t*p3
```

Create `game/src/ui/RouteMapNode.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/RouteMapNode.gd" id="1"]

[node name="RouteMapNode" type="Control"]
script = ExtResource("1")
```

### Step 3.4 — Run tests to verify all pass

```bash
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -15
```

Expected output:
```
  PASS: stage_y(0,4)
  ...
  PASS: bezier midpoint y in (0,100)

--- Results: 25 passed, 0 failed ---
ALL PASS
```

### Step 3.5 — Commit

```bash
git add game/src/ui/RouteMapNode.gd game/src/ui/RouteMapNode.tscn game/test/Stage7UITest.gd
git commit -m "$(cat <<'EOF'
feat: add RouteMapNode component with geometry tests

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: RunScene refactor

**Files:**
- Modify: `game/src/ui/RunScene.gd`
- Modify: `game/src/ui/RunScene.tscn`

No new unit tests — integration only. Smoke test by running the scene.

### Step 4.1 — Strip RunScene.tscn to root

Replace the entire contents of `game/src/ui/RunScene.tscn` with:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/RunScene.gd" id="1"]

[node name="RunScene" type="Control"]
script = ExtResource("1")
```

### Step 4.2 — Rewrite RunScene.gd

Replace the entire contents of `game/src/ui/RunScene.gd`:

```gdscript
# RunScene.gd
# Hosts the expedition tick loop. Top: StatsBar. Left: LogPanel. Right slot:
# RouteMapNode (swapped out for IncidentResolutionScene while incident is pending).
# Delegates movement to RouteMapNode.node_selected signal.
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
	# Auto-advance: selecting a node immediately processes the first tick
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
	_log_panel.append_tick_entries(_log, _state.tick_count)
	_route_map.refresh()
	_refresh_breadcrumb()

	if _state.pending_incident_id != "" and _state.run_end_reason == "":
		_show_incident()
		return
	if _state.run_end_reason != "":
		_transition_to_run_end()


func _show_incident() -> void:
	_route_map.hide()
	var scene := load("res://src/ui/IncidentResolutionScene.tscn").instantiate() as IncidentResolutionScene
	scene.setup(_state, _log)
	scene.resolved.connect(_on_incident_resolved)
	_right_slot.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_incident_resolved() -> void:
	for child in _right_slot.get_children():
		if child != _route_map:
			child.queue_free()
	_route_map.show()
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
```

### Step 4.3 — Smoke test

Open Godot, start a new run from PreparationScene. Verify:
- Stats bar shows ship condition, food, water, rum + burden/command bars
- Log panel on the left fills with entries after each tick
- Route map shows node graph with bezier paths
- Pressing Space or clicking a node triggers tick/travel
- Breadcrumb updates with stage and days remaining

### Step 4.4 — Commit

```bash
git add game/src/ui/RunScene.gd game/src/ui/RunScene.tscn
git commit -m "$(cat <<'EOF'
feat: refactor RunScene to use StatsBar, LogPanel, RouteMapNode

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: IncidentResolutionScene refactor

**Files:**
- Modify: `game/src/ui/IncidentResolutionScene.gd`
- Modify: `game/src/ui/IncidentResolutionScene.tscn`

### Step 5.1 — Strip IncidentResolutionScene.tscn

Replace the entire contents of `game/src/ui/IncidentResolutionScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/IncidentResolutionScene.gd" id="1"]

[node name="IncidentResolutionScene" type="Control"]
script = ExtResource("1")
```

### Step 5.2 — Rewrite IncidentResolutionScene.gd

Replace the entire contents of `game/src/ui/IncidentResolutionScene.gd`:

```gdscript
# IncidentResolutionScene.gd
# Fills the right slot in RunScene while an incident is pending.
# Call setup(state, log) before adding to scene tree. Emits resolved when done.
# Does NOT instantiate StatsBar or LogPanel — relies on RunScene shell.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name IncidentResolutionScene
extends Control

signal resolved

var _state: ExpeditionState = null
var _log: SimulationLog = null
var _incident: IncidentDef = null
var _proposals: Array = []
var _selected_index: int = -1


func setup(state: ExpeditionState, log: SimulationLog) -> void:
	_state = state
	_log = log
	_incident = ContentRegistry.get_by_id("incidents", state.pending_incident_id) as IncidentDef
	if _incident == null:
		push_error("IncidentResolutionScene: incident not found: " + state.pending_incident_id)


func _ready() -> void:
	if _incident == null or _state == null:
		return
	_build_ui()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# Category + category colour from map
	var cat_colors: Dictionary = {
		"crisis": Color.html("#ff9966"), "social": Color.html("#ffdd66"),
		"omen": Color.html("#cc88ff"), "boon": Color.html("#aaffaa"),
		"admiralty": Color.html("#ffccaa"), "landfall": Color.html("#88ff88"),
	}
	var cat_color: Color = cat_colors.get(_incident.category, Color(0.6, 0.7, 0.8))

	var title_lbl := Label.new()
	title_lbl.text = _incident.display_name.to_upper()
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", cat_color)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_lbl)

	var flavour := Label.new()
	flavour.text = _incident.log_text_template
	flavour.autowrap_mode = TextServer.AUTOWRAP_WORD
	flavour.add_theme_font_size_override("font_size", 12)
	flavour.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(flavour)

	var advice_lbl := Label.new()
	advice_lbl.text = "THE OFFICERS ADVISE"
	advice_lbl.add_theme_font_size_override("font_size", 9)
	advice_lbl.add_theme_color_override("font_color", Color(0.3, 0.45, 0.55))
	vbox.add_child(advice_lbl)

	# Build proposals
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)
	_proposals = OfficerCouncil.get_proposals(_state, _incident, officer_defs)
	_selected_index = -1

	var confirm_btn := Button.new()
	confirm_btn.text = "CONFIRM"
	confirm_btn.visible = false

	for i in range(_proposals.size()):
		var proposal: Dictionary = _proposals[i]
		match proposal["type"]:
			"officer":
				var card := _build_officer_card(i, proposal, confirm_btn)
				vbox.add_child(card)
			"silence":
				# Silence proposals shown as muted italic text, not clickable
				var sil := Label.new()
				var officer_def: OfficerDef = proposal["officer_def"]
				sil.text = "%s: \"%s\"" % [officer_def.display_name, proposal["silence_line"]]
				sil.add_theme_font_size_override("font_size", 10)
				sil.add_theme_color_override("font_color", Color(0.35, 0.4, 0.45))
				sil.autowrap_mode = TextServer.AUTOWRAP_WORD
				vbox.add_child(sil)
			"direct_order":
				var card := _build_direct_order_card(i, confirm_btn)
				vbox.add_child(card)

	confirm_btn.pressed.connect(_on_confirm)
	vbox.add_child(confirm_btn)


func _build_officer_card(index: int, proposal: Dictionary, confirm_btn: Button) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var officer_def: OfficerDef = proposal["officer_def"]
	var choice: IncidentChoiceDef = proposal["choice"]

	# Officer name column (fixed 80px)
	var name_vbox := VBoxContainer.new()
	name_vbox.custom_minimum_size.x = 80
	name_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(name_vbox)

	var name_lbl := Label.new()
	name_lbl.text = officer_def.display_name.to_upper()
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.67, 1.0, 0.67))
	name_vbox.add_child(name_lbl)

	var dots_lbl := Label.new()
	dots_lbl.text = _competence_dots(officer_def.competence)
	dots_lbl.add_theme_font_size_override("font_size", 9)
	dots_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	name_vbox.add_child(dots_lbl)

	# Choice text + effects
	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(content_vbox)

	var choice_lbl := Label.new()
	choice_lbl.text = choice.choice_text
	choice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	choice_lbl.add_theme_font_size_override("font_size", 11)
	content_vbox.add_child(choice_lbl)

	if choice.effects_preview != "":
		var preview_lbl := Label.new()
		preview_lbl.text = choice.effects_preview
		preview_lbl.add_theme_font_size_override("font_size", 9)
		preview_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.7))
		content_vbox.add_child(preview_lbl)

	if choice.risk_text != "" and officer_def.competence >= 3:
		var risk_lbl := Label.new()
		risk_lbl.text = "Risk: " + choice.risk_text
		risk_lbl.add_theme_font_size_override("font_size", 9)
		risk_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
		content_vbox.add_child(risk_lbl)

	# Select button (arrow)
	var arrow := Button.new()
	arrow.text = "›"
	arrow.flat = true
	arrow.add_theme_color_override("font_color", Color(0.35, 0.5, 0.6))
	arrow.pressed.connect(_on_proposal_selected.bind(index, confirm_btn))
	hbox.add_child(arrow)

	return panel


func _build_direct_order_card(index: int, confirm_btn: Button) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	panel.add_child(hbox)

	var lbl := Label.new()
	lbl.text = "DIRECT ORDER — This does not leave the cabin."
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(lbl)

	var arrow := Button.new()
	arrow.text = "›"
	arrow.flat = true
	arrow.pressed.connect(_on_proposal_selected.bind(index, confirm_btn))
	hbox.add_child(arrow)

	return panel


func _on_proposal_selected(index: int, confirm_btn: Button) -> void:
	_selected_index = index
	confirm_btn.visible = true
	confirm_btn.text = "CONFIRM — %s" % _proposals[index].get("type", "").to_upper()


func _on_confirm() -> void:
	if _selected_index < 0 or _selected_index >= _proposals.size():
		return
	var proposal: Dictionary = _proposals[_selected_index]
	match proposal["type"]:
		"officer":
			var choice: IncidentChoiceDef = proposal["choice"]
			EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
			for flag: String in choice.memory_flags_set:
				_state.add_memory_flag(flag)
			if choice.leadership_tag != "":
				_state.nudge_leadership_tag(choice.leadership_tag)
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] %s" % [_incident.display_name, choice.log_text],
				{"incident_id": _incident.id, "choice": choice.choice_text})
		"direct_order":
			_state.nudge_leadership_tag("authoritarian")
			_state.add_memory_flag("direct_order_used")
			_log.log_event(_state.tick_count, "IncidentResolution",
				"[%s] Captain issued direct order." % _incident.display_name,
				{"incident_id": _incident.id, "type": "direct_order"})
	_state.pending_incident_id = ""
	resolved.emit()


func _competence_dots(competence: int) -> String:
	return "●".repeat(competence) + "○".repeat(5 - competence)
```

### Step 5.3 — Smoke test

Trigger an incident in RunScene (start a run, tick until `drunk_purser_store_error` fires — the rum_aboard trait is always present on default state). Verify:
- Right slot is replaced by incident card
- Incident title, flavour text, and officer proposals display
- Selecting "›" on a proposal enables CONFIRM
- Confirming resolves and restores route map
- Log panel shows the IncidentResolution entry

### Step 5.4 — Commit

```bash
git add game/src/ui/IncidentResolutionScene.gd game/src/ui/IncidentResolutionScene.tscn
git commit -m "$(cat <<'EOF'
feat: refactor IncidentResolutionScene to programmatic card layout

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: ContentDebugScene rebuild

**Files:**
- Modify: `game/test/ContentDebugScene.gd`
- Modify: `game/test/ContentDebugScene.tscn`

### Step 6.1 — Strip ContentDebugScene.tscn

Replace the entire contents of `game/test/ContentDebugScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/ContentDebugScene.gd" id="1"]

[node name="ContentDebugScene" type="HBoxContainer"]
script = ExtResource("1")
```

### Step 6.2 — Rewrite ContentDebugScene.gd

Replace the entire contents of `game/test/ContentDebugScene.gd`:

```gdscript
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
	lbl_src.add_theme_font_size_override("font_size", 10 if is_header else 10)
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


# ── Sidebar button actions (unchanged logic from previous implementation) ──────

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
```

### Step 6.3 — Smoke test

Open ContentDebugScene directly in Godot. Verify:
- Sidebar renders with all grouped buttons
- "New Expedition" populates State tab with 2×2 grid
- Tags & Flags block shows empty placeholders, not errors
- "Validate All" tab shows PASS or FAIL with error count
- "Incidents" tab shows a table with ID, Name, Category columns
- "Show Route" populates Route tab with the RouteMapNode map
- "Advance Day" advances the route and refreshes the Route tab
- Log tab populates after ticking

### Step 6.4 — Commit

```bash
git add game/test/ContentDebugScene.gd game/test/ContentDebugScene.tscn
git commit -m "$(cat <<'EOF'
feat: rebuild ContentDebugScene with sidebar + tab system

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Verification Checklist

After all tasks are complete, run the full test suite to confirm no regressions:

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -5
godot --headless --path game res://test/ExpeditionStateTest.tscn 2>&1 | tail -5
godot --headless --path game res://test/RouteMapTest.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -5
godot --headless --path game res://test/Stage7UITest.tscn 2>&1 | tail -5
```

All suites must print `ALL PASS`.
