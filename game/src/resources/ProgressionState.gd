# ProgressionState.gd
# Persistent meta-progression state. Saved to disk between runs.
# Tracks which objectives have been completed and which content is unlocked.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
class_name ProgressionState
extends Resource

@export var completed_objective_ids: Array[String] = []
@export var unlocked_content_ids: Array[String] = []
@export var last_run_difficulty_score: int = 0


func is_unlocked(content_id: String) -> bool:
	return content_id in unlocked_content_ids


func apply_unlock(content_id: String) -> void:
	if content_id != "" and content_id not in unlocked_content_ids:
		unlocked_content_ids.append(content_id)


static func create_default() -> ProgressionState:
	var p := ProgressionState.new()
	# All MVP content unlocked by default so a fresh game is immediately playable.
	p.unlocked_content_ids = [
		# Officers — 6 roles × 2 variants
		"first_lieutenant_stern", "first_lieutenant_lenient",
		"master_experienced", "master_reckless",
		"gunner_disciplined", "gunner_reliable",
		"purser_frugal", "purser_generous",
		"surgeon_methodical", "surgeon_compassionate",
		"chaplain_orthodox", "chaplain_pragmatic",
		# Doctrines
		"shared_hardship", "iron_discipline",
		# Upgrades
		"reinforced_hull", "medical_stores", "powder_magazine",
		# Objectives
		"survey_strange_shore", "recover_lost_charts",
		"survey_northern_passage", "condition_return_intact",
		"condition_low_burden", "survey_abandoned_settlement",
	]
	return p
