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
