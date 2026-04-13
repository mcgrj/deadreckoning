# ExpeditionState.gd
# Mutable state bag for a single expedition run.
# Holds Burden, Command, supplies, ship condition, damage tags, crew traits,
# officers, promises, leadership tags, memory flags, rum state, and stress indicators.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-2-expedition-state-design.md
class_name ExpeditionState
extends RefCounted

var burden: int = 20
var command: int = 70
var supplies: Dictionary = {}  # { supply_id: int }
var ship_condition: int = 100
var damage_tags: Array[String] = []
var crew_traits: Array[String] = []
var officers: Array[String] = []
var standing_orders: Array[String] = []
var active_promise: Dictionary = {}  # { id, text, deadline_ticks, ticks_remaining } or empty
var leadership_tags: Dictionary = {
	"harsh": 0, "merciful": 0,
	"honest": 0, "deceptive": 0,
	"shared_hardship": 0, "privilege": 0,
}
var memory_flags: Array[String] = []
var rum_ration_expected: bool = false
var spirit_store_locked: bool = false
var rum_theft_risk: int = 0
var rum_drunkenness_risk: int = 0
var tick_count: int = 0
var stress_indicators: Dictionary = {
	"peak_burden": 20,
	"min_command": 70,
	"crew_losses": 0,
	"supply_depletions": 0,
}


static func create_default() -> ExpeditionState:
	var state := ExpeditionState.new()

	# Populate supplies from SupplyDefs
	var supply_defs := ContentRegistry.get_all("supplies")
	for def: ContentBase in supply_defs:
		var supply_def: SupplyDef = def as SupplyDef
		if supply_def:
			state.supplies[supply_def.id] = supply_def.starting_amount
			if supply_def.is_rum and supply_def.starting_amount > 0:
				state.rum_ration_expected = true

	# Populate officers from OfficerDefs
	var officer_defs := ContentRegistry.get_all("officers")
	for def: ContentBase in officer_defs:
		var officer_def: OfficerDef = def as OfficerDef
		if officer_def:
			state.officers.append(officer_def.id)

	return state


# --- Supply accessors ---

func get_supply(supply_id: String) -> int:
	if not supplies.has(supply_id):
		return 0
	return supplies[supply_id]


func set_supply(supply_id: String, amount: int) -> void:
	supplies[supply_id] = maxi(amount, 0)


# --- Damage tag accessors ---

func has_damage_tag(tag: String) -> bool:
	return tag in damage_tags


func add_damage_tag(tag: String) -> void:
	if tag not in damage_tags:
		damage_tags.append(tag)


func remove_damage_tag(tag: String) -> void:
	damage_tags.erase(tag)


# --- Memory flag accessors ---

func has_memory_flag(flag: String) -> bool:
	return flag in memory_flags


func add_memory_flag(flag: String) -> void:
	if flag not in memory_flags:
		memory_flags.append(flag)


# --- Crew trait accessors ---

func has_crew_trait(trait_tag: String) -> bool:
	return trait_tag in crew_traits


func add_crew_trait(trait_tag: String) -> void:
	if trait_tag not in crew_traits:
		crew_traits.append(trait_tag)


func remove_crew_trait(trait_tag: String) -> void:
	crew_traits.erase(trait_tag)


# --- Officer accessor ---

func has_officer(officer_id: String) -> bool:
	return officer_id in officers


# --- Promise methods ---

func make_promise(id: String, text: String, deadline_ticks: int, log: SimulationLog) -> bool:
	if not active_promise.is_empty():
		log.log_event(tick_count, "Promise", "Cannot make promise — one already active.", {"attempted_id": id})
		return false
	active_promise = {
		"id": id,
		"text": text,
		"deadline_ticks": deadline_ticks,
		"ticks_remaining": deadline_ticks,
	}
	command = clampi(command + 3, 0, 100)
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	log.log_event(tick_count, "Promise", "Promise made: %s (Command +3)" % text, {"id": id, "deadline": deadline_ticks})
	return true


func tick_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	active_promise.ticks_remaining -= 1
	if active_promise.ticks_remaining <= 0:
		log.log_event(tick_count, "Promise", "Promise deadline expired — auto-breaking.", {"id": active_promise.id})
		break_promise(log)


func keep_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	var promise_id: String = active_promise.id
	var promise_text: String = active_promise.text
	command = clampi(command + 5, 0, 100)
	burden = clampi(burden - 3, 0, 100)
	if burden > stress_indicators.peak_burden:
		stress_indicators.peak_burden = burden
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	add_memory_flag("promise_kept_" + promise_id)
	log.log_event(tick_count, "Promise", "Promise kept: %s (Command +5, Burden -3)" % promise_text, {"id": promise_id})
	active_promise = {}


func break_promise(log: SimulationLog) -> void:
	if active_promise.is_empty():
		return
	var promise_id: String = active_promise.id
	var promise_text: String = active_promise.text
	command = clampi(command - 5, 0, 100)
	burden = clampi(burden + 5, 0, 100)
	if burden > stress_indicators.peak_burden:
		stress_indicators.peak_burden = burden
	if command < stress_indicators.min_command:
		stress_indicators.min_command = command
	add_memory_flag("promise_broken_" + promise_id)
	log.log_event(tick_count, "Promise", "Promise broken: %s (Command -5, Burden +5)" % promise_text, {"id": promise_id})
	active_promise = {}
