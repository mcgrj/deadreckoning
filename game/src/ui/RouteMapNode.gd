# RouteMapNode.gd
# Vertical Slay-the-Spire-style node map. Renders via _draw().
# setup(route, state, log) — initialises. refresh() — call after each tick.
# Emits node_selected(node: RouteNode) when a reachable node is clicked.
# Canvas fills the full control size; pos_cache rebuilt on resize.
#
# Spec: docs/superpowers/specs/2026-04-14-debug-ui-redesign.md
class_name RouteMapNode
extends Control

# Fixed geometry constants — kept for Stage7UITest compatibility.
# Live rendering uses _draw_stage_y / _draw_node_x which scale to size.
const CANVAS_W := 300.0
const CANVAS_H := 520.0
const DEPART_Y := 490.0
const ARRIVAL_Y := 80.0
const NODE_RADIUS := 26.0
const BEZIER_SEGMENTS := 20
const TICK_DOT_RADIUS := 4.5
const NODE_MARGIN := 65.0

# Padding for the live canvas (not used by the static test methods)
const PAD_X := 40.0
const PAD_TOP := 40.0
const PAD_BOT := 40.0

# Category colours: [background hex, stroke hex]
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
# _offset is always ZERO — canvas fills the full control. Kept as a field
# so drawing helpers can read it without extra parameters.
var _offset: Vector2 = Vector2.ZERO
var _hovered_node: RouteNode = null
var _glow_phase: float = 0.0
var _pos_cache: Dictionary = {}  # RouteNode -> Vector2 (screen-local)
var _last_size: Vector2 = Vector2.ZERO  # detects resize for cache rebuild


func setup(route: RouteMap, state: ExpeditionState, log: SimulationLog) -> void:
	_route = route
	_state = state
	_log = log
	# pos_cache rebuilt on first _draw() once the layout size is known
	queue_redraw()


func _rebuild_pos_cache() -> void:
	_pos_cache.clear()
	if _route == null:
		return
	for si in range(_route.stages.size()):
		var stage: Array = _route.stages[si]
		for ni in range(stage.size()):
			_pos_cache[stage[ni]] = Vector2(
				_draw_node_x(ni, stage.size()),
				_draw_stage_y(si, _route.stages.size()))


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


func _process(_delta: float) -> void:
	if _route == null:
		return
	var mouse := get_local_mouse_position()
	var new_hover: RouteNode = null
	for node: RouteNode in _all_nodes():
		if _node_canvas_pos(node).distance_to(mouse) < NODE_RADIUS:
			new_hover = node
			break
	if new_hover != _hovered_node:
		_hovered_node = new_hover
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# _unhandled_input is not used because Control (MOUSE_FILTER_STOP default)
	# consumes mouse button events before they reach _unhandled_input.
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _route == null:
		return
	# While travelling, just arrived, or after final completion: any click
	# triggers _do_advance() in RunScene without selecting a new node.
	if _route.is_travelling() or _route.is_complete() or _route.arrived_at_node != null:
		node_selected.emit(null)
		get_viewport().set_input_as_handled()
		return
	# mb.position is local to this Control (no offset adjustment needed)
	for node: RouteNode in _route.get_current_stage():
		if _node_canvas_pos(node).distance_to(mb.position) < NODE_RADIUS:
			node_selected.emit(node)
			get_viewport().set_input_as_handled()
			return


func _draw() -> void:
	if _route == null:
		return
	_offset = Vector2.ZERO
	# Rebuild pos cache when the control is first laid out or resized
	if size != _last_size:
		_last_size = size
		_rebuild_pos_cache()
	_draw_paths()
	_draw_tick_dots()
	_draw_boat()
	_draw_nodes()
	_draw_stage_labels()


# ── Layout helpers (dynamic — use actual control size) ────────────────────────

func _depart_pos() -> Vector2:
	return Vector2(size.x * 0.5, size.y - PAD_BOT)

func _arrival_pos() -> Vector2:
	return Vector2(size.x * 0.5, PAD_TOP)

func _draw_stage_y(stage_index: int, total_stages: int) -> float:
	var depart_y := size.y - PAD_BOT
	var arrival_y := PAD_TOP
	var usable := depart_y - arrival_y
	var step := usable / float(total_stages + 1)
	return depart_y - step * float(stage_index + 1)

func _draw_node_x(node_index: int, node_count: int) -> float:
	var margin := maxf(NODE_RADIUS + 12.0, size.x * 0.08)
	if node_count == 1:
		return size.x * 0.5
	var spacing := (size.x - 2.0 * margin) / float(node_count - 1)
	return margin + spacing * float(node_index)


# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw_paths() -> void:
	if _route.stages.is_empty():
		return
	var depart := _depart_pos()
	var arrival := _arrival_pos()
	var ctrl := size.y * 0.12

	# Depart → stage 0
	for node: RouteNode in _route.stages[0]:
		var to := _node_canvas_pos(node)
		_draw_bezier(depart, depart + Vector2(0, -ctrl), to + Vector2(0, ctrl), to, _path_color(node), 1.5)

	# Stage i → stage i+1 (spatially-mapped connections — no cross-paths)
	for si in range(_route.stages.size() - 1):
		for pair in _stage_connections(_route.stages[si], _route.stages[si + 1]):
			var fp := _node_canvas_pos(pair[0])
			var tp := _node_canvas_pos(pair[1])
			_draw_bezier(fp, fp + Vector2(0, -ctrl), tp + Vector2(0, ctrl), tp, _path_color(pair[1]), 1.5)

	# Last stage → arrival
	for node: RouteNode in _route.stages[-1]:
		var fp := _node_canvas_pos(node)
		_draw_bezier(fp, fp + Vector2(0, -ctrl), arrival + Vector2(0, ctrl), arrival, _path_color(node), 1.5)


# Returns Array of [from_node, to_node] pairs using spatial column mapping.
# Each node connects only to its proportionally nearest neighbour(s) in the
# next stage — never draws impossible cross-stage paths.
func _stage_connections(from_stage: Array, to_stage: Array) -> Array:
	var n := from_stage.size()
	var m := to_stage.size()
	var seen: Dictionary = {}
	var result: Array = []
	for j in range(n):
		var ratio := float(j) / float(max(n - 1, 1))
		var target := ratio * float(max(m - 1, 1))
		var lo := floori(target)
		var hi := mini(ceili(target), m - 1)
		var key_lo := "%d_%d" % [j, lo]
		if not seen.has(key_lo):
			seen[key_lo] = true
			result.append([from_stage[j], to_stage[lo]])
		if hi != lo:
			var key_hi := "%d_%d" % [j, hi]
			if not seen.has(key_hi):
				seen[key_hi] = true
				result.append([from_stage[j], to_stage[hi]])
	return result


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
	var node: RouteNode = _route.active_node as RouteNode
	var tick_dist: int = node.tick_distance
	if tick_dist <= 0:
		return

	var from_pos := _active_leg_from_pos()
	var to_pos := _node_canvas_pos(node)
	var ticks_done: int = tick_dist - _route.ticks_remaining
	var ctrl := size.y * 0.12

	var stroke := _stroke_color(node.category)
	for i in range(tick_dist):
		var t := (float(i) + 0.5) / float(tick_dist)
		var p := _bezier_point(from_pos, from_pos + Vector2(0, -ctrl),
		                       to_pos + Vector2(0, ctrl), to_pos, t)
		var is_done: bool = i < ticks_done
		if is_done:
			draw_circle(p, TICK_DOT_RADIUS, Color(stroke.r, stroke.g, stroke.b, 0.9))
		else:
			draw_arc(p, TICK_DOT_RADIUS, 0.0, TAU, 16,
			         Color(stroke.r, stroke.g, stroke.b, 0.5), 1.5)


func _draw_boat() -> void:
	if _route.active_node == null:
		return
	var node: RouteNode = _route.active_node as RouteNode
	var tick_dist: int = node.tick_distance
	if tick_dist <= 0:
		return
	var ticks_done: int = tick_dist - _route.ticks_remaining
	var t := clampf((float(ticks_done) - 0.5) / float(tick_dist), 0.0, 1.0)
	var ctrl := size.y * 0.12

	var from_pos := _active_leg_from_pos()
	var to_pos := _node_canvas_pos(node)
	var boat_pos := _bezier_point(from_pos, from_pos + Vector2(0, -ctrl),
	                              to_pos + Vector2(0, ctrl), to_pos, t)

	var glow_a := 0.35 + 0.15 * sin(_glow_phase)
	draw_arc(boat_pos, 9.0, 0.0, TAU, 24, Color(0.67, 0.83, 1.0, glow_a), 1.5)
	draw_string(ThemeDB.fallback_font, boat_pos + Vector2(-8, 6), "⛵",
	            HORIZONTAL_ALIGNMENT_LEFT, -1, 16)


func _draw_nodes() -> void:
	var depart := _depart_pos()
	draw_circle(depart, 10.0, Color(0.1, 0.2, 0.3))
	draw_arc(depart, 10.0, 0.0, TAU, 24, Color(0.4, 0.6, 0.8), 2.0)

	var arrival := _arrival_pos()
	draw_circle(arrival, 10.0, Color(0.1, 0.1, 0.05))
	draw_arc(arrival, 10.0, 0.0, TAU, 24, Color(0.8, 0.8, 0.4), 2.0)

	for stage: Array in _route.stages:
		for node: RouteNode in stage:
			_draw_node(node)


func _draw_node(node: RouteNode) -> void:
	var pos := _node_canvas_pos(node)
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
	elif node == _hovered_node and state != "locked":
		draw_arc(pos, NODE_RADIUS + 2.0, 0.0, TAU, 32,
		         Color(stroke.r, stroke.g, stroke.b, 0.6), 1.0)

	draw_circle(pos, NODE_RADIUS, Color(bg.r, bg.g, bg.b, opacity))
	draw_arc(pos, NODE_RADIUS, 0.0, TAU, 32,
	         Color(stroke.r, stroke.g, stroke.b, opacity), stroke_w)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-10, 4),
	            node.category.substr(0, 3).to_upper(),
	            HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
	            Color(stroke.r, stroke.g, stroke.b, opacity * 0.9))


func _draw_stage_labels() -> void:
	for si in range(_route.stages.size()):
		var y := _draw_stage_y(si, _route.stages.size())
		draw_string(ThemeDB.fallback_font,
		            Vector2(size.x - 4.0, y + 4.0),
		            "S%d" % (si + 1),
		            HORIZONTAL_ALIGNMENT_RIGHT, -1, 10,
		            Color(0.25, 0.4, 0.55))


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
	return _pos_cache.get(node, Vector2.ZERO)


func _active_leg_from_pos() -> Vector2:
	if _route.selected_path.is_empty():
		return _depart_pos()
	return _node_canvas_pos(_route.selected_path[-1])


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


# ── Pure geometry — tested in Stage7UITest (fixed canvas constants) ───────────

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
