# ProgressionState.gd
# Persistent meta-progression state. Saved to disk between runs.
# Tracks objectives, unlocked content, Admiralty memory, and the officer pool.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
#       docs/superpowers/specs/2026-04-14-emergent-officers-scars-design.md
class_name ProgressionState
extends Resource

const OfficerGenerator := preload("res://src/expedition/OfficerGenerator.gd")

@export var completed_objective_ids: Array[String] = []
@export var unlocked_content_ids: Array[String] = []
@export var last_run_difficulty_score: int = 0
@export var admiralty_bias: Array[String] = []
@export var scandal_flags: Array[String] = []
@export var officer_pool: Array[OfficerDef] = []


func is_unlocked(content_id: String) -> bool:
	return content_id in unlocked_content_ids


func apply_unlock(content_id: String) -> void:
	if content_id != "" and content_id not in unlocked_content_ids:
		unlocked_content_ids.append(content_id)


## Return all candidates in the pool for the given role.
func get_candidates_for_role(role: String) -> Array:
	return officer_pool.filter(func(d: OfficerDef): return d.role == role)


## Find a specific officer by id. Returns null if not found.
func find_officer_by_id(officer_id: String) -> OfficerDef:
	for def: OfficerDef in officer_pool:
		if def.id == officer_id:
			return def
	return null


static func create_default() -> ProgressionState:
	var p := ProgressionState.new()
	p.unlocked_content_ids = [
		# Doctrines
		"shared_hardship", "iron_discipline",
		# Upgrades
		"reinforced_hull", "medical_stores", "powder_magazine",
		# Objectives
		"survey_strange_shore", "recover_lost_charts",
		"survey_northern_passage", "condition_return_intact",
		"condition_low_burden", "survey_abandoned_settlement",
	]
	# Generate initial officer pool: 2 candidates per role.
	var required_roles := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]
	for role: String in required_roles:
		for _i in range(2):
			p.officer_pool.append(OfficerGenerator.generate(role))
	return p
