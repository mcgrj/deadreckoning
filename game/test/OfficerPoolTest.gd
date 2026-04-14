# OfficerPoolTest.gd
# Tests for ProgressionState officer pool and SaveManager.commit_officer_scars.
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
	print("=== OfficerPoolTest ===\n")
	_test_create_default_has_pool()
	_test_pool_role_balance()
	_test_pool_candidate_counts()
	_test_get_candidates_for_role()
	_test_commit_scars_writes_to_pool()
	_test_commit_increments_runs_survived()
	_test_commit_stat_drift_loyalty_up()
	_test_commit_stat_drift_loyalty_down()
	_test_replenish_fills_depleted_role()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_create_default_has_pool() -> void:
	var prog := ProgressionState.create_default()
	check(prog.officer_pool.size() > 0, "create_default generates officer pool")


func _test_pool_role_balance() -> void:
	var prog := ProgressionState.create_default()
	var required_roles := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]
	for role in required_roles:
		var count := prog.get_candidates_for_role(role).size()
		check(count >= 1, "pool has at least 1 candidate for role: " + role)


func _test_pool_candidate_counts() -> void:
	var prog := ProgressionState.create_default()
	var required_roles := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]
	for role in required_roles:
		var count := prog.get_candidates_for_role(role).size()
		check(count >= 2, "pool has >= 2 candidates for role: " + role)


func _test_get_candidates_for_role() -> void:
	var prog := ProgressionState.create_default()
	var surgeons := prog.get_candidates_for_role("surgeon")
	check(surgeons.size() >= 2, "get_candidates_for_role returns >= 2 surgeons")
	for s: OfficerDef in surgeons:
		check(s.role == "surgeon", "returned candidate has correct role")


func _test_commit_scars_writes_to_pool() -> void:
	var prog := ProgressionState.create_default()
	var surgeon: OfficerDef = prog.get_candidates_for_role("surgeon")[0]
	var state := ExpeditionState.new()
	state.officer_defs = [surgeon]
	state.add_officer_scar("surgeon", "publicly_overruled")
	SaveManager.commit_officer_scars(state, prog)
	var updated := prog.find_officer_by_id(surgeon.id)
	check(updated != null, "officer found in pool after commit")
	check("publicly_overruled" in updated.scar_traits, "scar committed to pool officer")


func _test_commit_increments_runs_survived() -> void:
	var prog := ProgressionState.create_default()
	var master: OfficerDef = prog.get_candidates_for_role("master")[0]
	var state := ExpeditionState.new()
	state.officer_defs = [master]
	var before: int = master.runs_survived
	SaveManager.commit_officer_scars(state, prog)
	check(master.runs_survived == before + 1, "runs_survived incremented after commit")


func _test_commit_stat_drift_loyalty_up() -> void:
	var prog := ProgressionState.create_default()
	var purser: OfficerDef = prog.get_candidates_for_role("purser")[0]
	purser.loyalty = 3
	var state := ExpeditionState.new()
	state.officer_defs = [purser]
	state.add_memory_flag("advice_followed_purser")  # signals advice was heeded
	SaveManager.commit_officer_scars(state, prog)
	check(purser.loyalty >= 3, "loyalty does not decrease when advice was followed")


func _test_commit_stat_drift_loyalty_down() -> void:
	var prog := ProgressionState.create_default()
	var chaplain: OfficerDef = prog.get_candidates_for_role("chaplain")[0]
	chaplain.loyalty = 3
	var state := ExpeditionState.new()
	state.officer_defs = [chaplain]
	state.add_officer_scar("chaplain", "publicly_overruled")  # triggers loyalty drift down
	SaveManager.commit_officer_scars(state, prog)
	check(chaplain.loyalty <= 3, "loyalty does not increase when officer was overruled")


func _test_replenish_fills_depleted_role() -> void:
	var prog := ProgressionState.create_default()
	# Remove all surgeons
	prog.officer_pool = prog.officer_pool.filter(func(d: OfficerDef): return d.role != "surgeon")
	SaveManager.replenish_pool(prog)
	var surgeons := prog.get_candidates_for_role("surgeon")
	check(surgeons.size() >= 1, "replenish generates at least 1 surgeon when slot empty")
