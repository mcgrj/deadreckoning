# ContentRegistry.gd
# Autoload singleton. Scans all content family folders on startup, loads every
# .tres file, validates the catalog, and exposes a query API to game code.
#
# Usage: ContentRegistry.get_all("incidents"), ContentRegistry.get_by_id("supplies", "rum")
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
extends Node

# Each entry: { "name": String, "folder": String, "class": GDScript }
var _families: Array[Dictionary] = []

# { family_name: { id: ContentBase } }
var _catalog: Dictionary = {}

var _validation_errors: Array[String] = []


func _ready() -> void:
	_register_families()
	_load_all()
	_validate()
	if not _validation_errors.is_empty():
		push_warning("ContentRegistry: %d validation error(s):" % _validation_errors.size())
		for err: String in _validation_errors:
			push_warning("  " + err)


func _register_families() -> void:
	_families = [
		{"name": "supplies",         "folder": "res://content/supplies/",         "class": SupplyDef},
		{"name": "officers",         "folder": "res://content/officers/",         "class": OfficerDef},
		{"name": "standing_orders",  "folder": "res://content/standing_orders/",  "class": StandingOrderDef},
		{"name": "upgrades",         "folder": "res://content/upgrades/",         "class": ShipUpgradeDef},
		{"name": "doctrines",        "folder": "res://content/doctrines/",        "class": DoctrineDef},
		{"name": "crew_backgrounds", "folder": "res://content/crew_backgrounds/", "class": CrewBackgroundDef},
		{"name": "zone_types",       "folder": "res://content/zone_types/",       "class": ZoneTypeDef},
		{"name": "objectives",       "folder": "res://content/objectives/",       "class": ObjectiveDef},
		{"name": "incidents",        "folder": "res://content/incidents/",        "class": IncidentDef},
	]


func _load_all() -> void:
	for family: Dictionary in _families:
		_catalog[family.name] = {}
		var dir := DirAccess.open(family.folder)
		if dir == null:
			push_error("ContentRegistry: cannot open folder: " + family.folder)
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var path: String = family.folder + file_name
				var res := ResourceLoader.load(path)
				if res == null:
					push_error("ContentRegistry: failed to load: " + path)
				elif not (res is ContentBase):
					push_error("ContentRegistry: loaded resource is not ContentBase: " + path)
				else:
					var item: ContentBase = res
					_catalog[family.name][item.id] = item
			file_name = dir.get_next()
		dir.list_dir_end()


func _validate() -> void:
	var flat_catalog: Dictionary = {}
	for family: String in _catalog:
		flat_catalog[family] = _catalog[family].values()
	_validation_errors = ContentValidator.validate(flat_catalog)


## Returns all loaded items for the given family as an Array.
func get_all(family: String) -> Array:
	if not _catalog.has(family):
		return []
	return _catalog[family].values()


## Returns the item with the given id in the given family, or null if not found.
func get_by_id(family: String, id: String) -> ContentBase:
	if not _catalog.has(family) or not _catalog[family].has(id):
		return null
	return _catalog[family][id]


## Returns the list of registered family names.
func get_families() -> Array[String]:
	var names: Array[String] = []
	for family: Dictionary in _families:
		names.append(family.name)
	return names


## Returns all validation errors from the last load. Empty = catalog is valid.
func get_validation_errors() -> Array[String]:
	return _validation_errors


## True if the catalog loaded with no validation errors.
func is_valid() -> bool:
	return _validation_errors.is_empty()
