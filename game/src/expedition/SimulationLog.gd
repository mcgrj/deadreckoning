# SimulationLog.gd
# Append-only explanation log for expedition state changes.
# Records why effects were applied, why conditions passed/failed, and general events.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name SimulationLog
extends RefCounted

var _entries: Array[Dictionary] = []


func log_effect(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func log_condition(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func log_event(tick: int, source: String, message: String, details: Dictionary = {}) -> void:
	_entries.append({"tick": tick, "source": source, "message": message, "details": details})


func get_entries() -> Array[Dictionary]:
	return _entries


func get_entries_since(tick: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _entries:
		if entry.tick >= tick:
			result.append(entry)
	return result


func clear() -> void:
	_entries.clear()
