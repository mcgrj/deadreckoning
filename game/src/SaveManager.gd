# SaveManager.gd
# Autoload. Manages persistence for ProgressionState between runs.
# ProgressionState is stored as a .tres Resource file (Godot-native serialisation).
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
extends Node

const SLOT_DEFAULT := "default"

## Pending run config passed from PreparationScene to RunScene across scene changes.
var pending_run_config: Dictionary = {}


func _get_slot_dir(slot_id: String) -> String:
	return GameConstants.SAVE_DIR + slot_id + "/"


func _get_progression_path(slot_id: String) -> String:
	return _get_slot_dir(slot_id) + "progression.tres"


func _get_run_state_path(slot_id: String) -> String:
	return _get_slot_dir(slot_id) + "run_state.json"


# --- ProgressionState ---

func load_progression(slot_id: String = SLOT_DEFAULT) -> ProgressionState:
	var path := _get_progression_path(slot_id)
	if ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is ProgressionState:
			return loaded
	return ProgressionState.create_default()


func save_progression(state: ProgressionState, slot_id: String = SLOT_DEFAULT) -> void:
	var dir := _get_slot_dir(slot_id)
	DirAccess.make_dir_recursive_absolute(dir)
	state.resource_path = ""  # force write to explicit path, not cached resource_path
	var err := ResourceSaver.save(state, _get_progression_path(slot_id))
	if err != OK:
		push_error("SaveManager: failed to save progression to %s (err %d)" % [_get_progression_path(slot_id), err])


func record_objective_complete(objective_id: String, slot_id: String = SLOT_DEFAULT) -> void:
	var progression := load_progression(slot_id)
	if objective_id not in progression.completed_objective_ids:
		progression.completed_objective_ids.append(objective_id)
	var objective_def: ObjectiveDef = ContentRegistry.get_by_id("objectives", objective_id) as ObjectiveDef
	if objective_def and objective_def.unlock_on_success_id != "":
		progression.apply_unlock(objective_def.unlock_on_success_id)
	save_progression(progression, slot_id)


func record_report_framing(bias_string: String, scandal_flag: String, slot_id: String = SLOT_DEFAULT) -> void:
	var progression := load_progression(slot_id)
	if bias_string != "":
		progression.admiralty_bias.append(bias_string)
	if scandal_flag != "":
		progression.scandal_flags.append(scandal_flag)
	save_progression(progression, slot_id)


func save_run_state(state: ExpeditionState, slot_id: String = SLOT_DEFAULT) -> void:
	# Stub: full implementation in RunScene (Task 9).
	# ExpeditionState is RefCounted, not Resource — serialised as JSON.
	pass


func load_run_state(slot_id: String = SLOT_DEFAULT) -> ExpeditionState:
	# Stub: full implementation in RunScene (Task 9).
	return null


func delete_run_state(slot_id: String = SLOT_DEFAULT) -> void:
	var path := _get_run_state_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
