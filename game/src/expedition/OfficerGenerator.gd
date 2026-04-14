# OfficerGenerator.gd
# Stateless utility. Reads authored JSON pool files and assembles OfficerDef records.
# All pool files live under res://content/officer_pools/.
#
# Spec: docs/superpowers/specs/2026-04-14-emergent-officers-scars-design.md
class_name OfficerGenerator
extends RefCounted

const POOLS_DIR := "res://content/officer_pools/"

const INFORMATION_DOMAINS := {
	"first_lieutenant": "discipline",
	"master": "route",
	"gunner": "ship",
	"purser": "supply",
	"surgeon": "crew_risk",
	"chaplain": "omen",
}

const WORLDVIEWS_BY_ROLE := {
	"first_lieutenant": ["disciplinarian", "pragmatist"],
	"master": ["pragmatist"],
	"gunner": ["disciplinarian", "pragmatist"],
	"purser": ["pragmatist"],
	"surgeon": ["humanitarian", "pragmatist"],
	"chaplain": ["humanitarian", "pragmatist"],
}

# Cache loaded pools to avoid re-reading files on every generate() call.
static var _cache: Dictionary = {}


## Generate a fresh OfficerDef for the given role.
## Reads JSON pools on first call per session; uses cache thereafter.
static func generate(role: String) -> OfficerDef:
	var names := _pool("names")
	var backgrounds := _pool("backgrounds")
	var traits_pool := _pool("traits")
	var stances := _pool("stances")

	var def := OfficerDef.new()
	def.role = role
	def.id = "gen_%s_%05d" % [role, randi() % 100000]
	def.information_domain = INFORMATION_DOMAINS.get(role, "")
	def.competence = randi_range(1, 5)
	def.loyalty = randi_range(1, 5)

	var worldview_options: Array = WORLDVIEWS_BY_ROLE.get(role, ["pragmatist"])
	def.worldview = worldview_options[randi() % worldview_options.size()]

	# Name
	var role_names: Array = names.get(role, ["Unknown"])
	def.display_name = role_names[randi() % role_names.size()]

	# Background (stored as tags[0] so it survives serialisation)
	var bg: Dictionary = backgrounds.get(role, {})
	var origins: Array = bg.get("origins", ["Unknown origin."])
	var service: Array = bg.get("service", ["No service record."])
	var reputation: Array = bg.get("reputation", ["No reputation noted."])
	var background_text := "%s %s %s" % [
		origins[randi() % origins.size()],
		service[randi() % service.size()],
		reputation[randi() % reputation.size()],
	]
	def.tags = [background_text]

	# Traits
	var role_traits: Array = traits_pool.get(role, [])
	var picked := _pick_traits(role_traits)
	def.disclosed_traits = picked.disclosed
	def.rumoured_traits = picked.rumoured_ids
	def.rumoured_hints = picked.rumoured_hints
	def.hidden_traits = picked.hidden

	# Stance (optional — 50% chance)
	var role_stances: Array = stances.get(role, [])
	if not role_stances.is_empty() and randf() > 0.5:
		def.pre_departure_stance = role_stances[randi() % role_stances.size()]

	def.scar_traits = []
	def.runs_survived = 0
	def.notable_events = []
	def.starting_effects = []
	def.advice_hooks = []

	return def


## Select 2–3 traits from the pool with exclusion enforcement.
## Returns a Dictionary: { disclosed: [], rumoured_ids: [], rumoured_hints: [], hidden: [] }
static func _pick_traits(pool: Array) -> Dictionary:
	var result := { "disclosed": [], "rumoured_ids": [], "rumoured_hints": [], "hidden": [] }
	if pool.is_empty():
		return result

	var excluded: Array[String] = []
	var shuffled := pool.duplicate()
	shuffled.shuffle()
	var picked_count := 0
	var target := randi_range(2, 3)

	for entry: Dictionary in shuffled:
		if picked_count >= target:
			break
		var trait_id: String = entry.get("id", "")
		if trait_id in excluded:
			continue
		var tier: String = entry.get("tier", "disclosed")
		match tier:
			"disclosed":
				result.disclosed.append(trait_id)
			"rumoured":
				result.rumoured_ids.append(trait_id)
				result.rumoured_hints.append(entry.get("hint", ""))
			"hidden":
				result.hidden.append(trait_id)
		for excl: String in entry.get("excludes", []):
			if excl not in excluded:
				excluded.append(excl)
		picked_count += 1

	return result


## Load a JSON pool file by name (no extension). Caches result.
static func _pool(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var path := POOLS_DIR + name + ".json"
	if not FileAccess.file_exists(path):
		push_error("OfficerGenerator: pool file not found: " + path)
		_cache[name] = {}
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("OfficerGenerator: could not open pool file: " + path)
		_cache[name] = {}
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("OfficerGenerator: failed to parse pool file: " + path)
		_cache[name] = {}
		return {}
	_cache[name] = parsed
	return parsed
