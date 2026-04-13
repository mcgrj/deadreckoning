# RouteMap.gd
# Full route structure for one expedition run.
# Holds stages (Array of Array[RouteNode]), tracks position, exposes navigation.
# Static factory creates hand-authored test map; swap for generate() in future.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name RouteMap
extends RefCounted

# Array of Array[RouteNode] — each inner array is one stage's node choices
var stages: Array = []
var current_stage_index: int = 0
var selected_path: Array = []  # Array[RouteNode], one per completed stage
var active_node = null          # RouteNode currently being travelled to, or null
var ticks_remaining: int = 0


static func create_test_map() -> RouteMap:
	var map = RouteMap.new()
	map.stages = [
		# Stage 1 — coastal
		[
			RouteNode.make("stage1_crisis",   "crisis",   3, "coastal",
				["Fog reported on the approach.", "Hazard: reef shelf."]),
			RouteNode.make("stage1_landfall", "landfall", 4, "coastal",
				["Supply opportunity: fresh water.", "A sheltered cove to the west."]),
			RouteNode.make("stage1_omen",     "omen",     2, "coastal",
				["Strange lights at the headland."]),
		],
		# Stage 2 — open ocean
		[
			RouteNode.make("stage2_social",  "social",  2, "open_ocean",
				["A trading vessel on the horizon."]),
			RouteNode.make("stage2_unknown", "unknown", 3, "open_ocean",
				["Uncharted waters. Proceed with caution."]),
		],
		# Stage 3 — lee shore + open ocean
		[
			RouteNode.make("stage3_boon",      "boon",      2, "lee_shore",
				["A fishing village willing to trade."]),
			RouteNode.make("stage3_admiralty", "admiralty", 4, "open_ocean",
				["Signal from an Admiralty patrol vessel.", "Survey coordinates confirmed."],
				true),
		],
		# Stage 4 — unknown waters
		[
			RouteNode.make("stage4_crisis",   "crisis",   2, "unknown_zone",
				["Strange currents. The compass spins."]),
			RouteNode.make("stage4_landfall", "landfall", 3, "unknown_zone",
				["Uncharted coast ahead.", "Hazard: shifting sandbars."]),
		],
	]
	return map


func get_current_stage() -> Array:
	if current_stage_index >= stages.size():
		return []
	return stages[current_stage_index]


func select_node(node: RouteNode) -> void:
	active_node = node
	ticks_remaining = node.tick_distance


func is_travelling() -> bool:
	return ticks_remaining > 0


func is_complete() -> bool:
	return current_stage_index >= stages.size() and not is_travelling()


func advance_tick() -> void:
	if ticks_remaining <= 0:
		return
	ticks_remaining -= 1
	if ticks_remaining == 0:
		selected_path.append(active_node)
		current_stage_index += 1
		active_node = null


func get_active_zone() -> ZoneTypeDef:
	if active_node == null:
		return null
	return ContentRegistry.get_by_id("zone_types", active_node.zone_type_id) as ZoneTypeDef
