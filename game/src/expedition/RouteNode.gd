# RouteNode.gd
# Single route node in a RouteMap. RefCounted data class — not a Resource.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name RouteNode
extends RefCounted

var id: String = ""
var category: String = ""
var tick_distance: int = 0
var zone_type_id: String = ""
var hints: Array[String] = []
var is_objective_node: bool = false
var required_node_category: String = ""


static func make(
	id: String,
	category: String,
	tick_distance: int,
	zone_type_id: String,
	hints: Array[String] = [],
	is_objective_node: bool = false,
	required_node_category: String = ""
) -> RouteNode:
	var node = RouteNode.new()
	node.id = id
	node.category = category
	node.tick_distance = tick_distance
	node.zone_type_id = zone_type_id
	node.hints = hints
	node.is_objective_node = is_objective_node
	node.required_node_category = required_node_category
	return node
