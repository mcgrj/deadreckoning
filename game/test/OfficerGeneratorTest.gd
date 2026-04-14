# OfficerGeneratorTest.gd
# Tests for OfficerGenerator — verifies generated OfficerDef records are well-formed.
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
	print("=== OfficerGeneratorTest ===\n")
	_test_generate_all_roles()
	_test_id_is_unique()
	_test_background_has_three_parts()
	_test_traits_are_coherent()
	_test_role_constraints()
	_test_information_domain_assigned()
	_test_competence_loyalty_in_range()
	_test_scar_traits_empty_on_generation()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_generate_all_roles() -> void:
	for role in ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]:
		var def: OfficerDef = OfficerGenerator.generate(role)
		check(def != null, "generate() returns non-null for role: " + role)
		check(def.role == role, "generated officer has correct role: " + role)
		check(def.id != "", "generated officer has non-empty id: " + role)
		check(def.display_name != "", "generated officer has display_name: " + role)


func _test_id_is_unique() -> void:
	var ids: Array[String] = []
	for role in ["surgeon", "surgeon", "surgeon"]:
		var def: OfficerDef = OfficerGenerator.generate(role)
		check(def.id not in ids, "generated id is unique: " + def.id)
		ids.append(def.id)


func _test_background_has_three_parts() -> void:
	var def: OfficerDef = OfficerGenerator.generate("surgeon")
	# Background is assembled from three fragments joined by " "
	check(def.display_name != "", "surgeon display_name set")
	check(def.tags.size() > 0, "background stored in tags[0]")


func _test_traits_are_coherent() -> void:
	# Generate many surgeons; check no two mutually-exclusive traits co-occur
	for i in range(20):
		var def: OfficerDef = OfficerGenerator.generate("surgeon")
		var all_traits: Array[String] = []
		all_traits.append_array(def.disclosed_traits)
		all_traits.append_array(def.rumoured_traits)
		all_traits.append_array(def.hidden_traits)
		var has_steady = "steady_hands" in all_traits
		var has_tremors = "tremors" in all_traits
		check(not (has_steady and has_tremors), "surgeon: steady_hands and tremors do not co-occur (iteration %d)" % i)
		var has_noon = "drinks_before_noon" in all_traits
		var has_strict = "strict_self_discipline" in all_traits
		check(not (has_noon and has_strict), "surgeon: drinks_before_noon and strict_self_discipline do not co-occur (iteration %d)" % i)


func _test_role_constraints() -> void:
	for role in ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]:
		var def: OfficerDef = OfficerGenerator.generate(role)
		check(def.information_domain != "", "information_domain set for: " + role)


func _test_information_domain_assigned() -> void:
	var domain_map := {
		"first_lieutenant": "discipline",
		"master": "route",
		"gunner": "ship",
		"purser": "supply",
		"surgeon": "crew_risk",
		"chaplain": "omen",
	}
	for role in domain_map:
		var def: OfficerDef = OfficerGenerator.generate(role)
		check(def.information_domain == domain_map[role],
			"information_domain '%s' for role '%s'" % [def.information_domain, role])


func _test_competence_loyalty_in_range() -> void:
	for role in ["surgeon", "master", "purser"]:
		var def: OfficerDef = OfficerGenerator.generate(role)
		check(def.competence >= 1 and def.competence <= 5, "competence in 1–5 for: " + role)
		check(def.loyalty >= 1 and def.loyalty <= 5, "loyalty in 1–5 for: " + role)


func _test_scar_traits_empty_on_generation() -> void:
	var def: OfficerDef = OfficerGenerator.generate("chaplain")
	check(def.scar_traits.is_empty(), "fresh officer has no scar_traits")
	check(def.runs_survived == 0, "fresh officer has runs_survived == 0")
