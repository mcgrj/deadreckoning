# ContentValidator.gd
# Validates the full loaded content catalog after ContentRegistry finishes loading.
# Returns Array[String] of error messages — empty means catalog is valid.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ContentValidator

const VALID_EFFECT_TYPES: Array[String] = [
	"burden_change",
	"command_change",
	"supply_change",
	"ship_condition_change",
	"add_damage_tag",
	"remove_damage_tag",
	"set_memory_flag",
	"add_crew_trait",
	"remove_crew_trait",
]

const VALID_CONDITION_TYPES: Array[String] = [
	"burden_above",
	"burden_below",
	"command_above",
	"command_below",
	"supply_below",
	"has_damage_tag",
	"has_memory_flag",
	"has_crew_trait",
	"officer_present",
	"zone_type_is",
	"has_standing_order",
	"ship_condition_gte",
]


## Validate the full catalog. catalog is a Dictionary of family_name -> Array[ContentBase].
## Returns an Array[String] of error messages. Empty = valid.
static func validate(catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for family: String in catalog:
		var items: Array = catalog[family]
		var seen_ids: Dictionary = {}
		for item: ContentBase in items:
			_check_base(item, family, seen_ids, errors)
			_check_embedded(item, family, errors)
	return errors


static func _check_base(
	item: ContentBase,
	family: String,
	seen_ids: Dictionary,
	errors: Array[String]
) -> void:
	if item.id == null or item.id == "":
		errors.append("[%s/?] Missing id on item" % family)
		return
	if seen_ids.has(item.id):
		errors.append("[%s/%s] Duplicate id" % [family, item.id])
	seen_ids[item.id] = true


static func _check_embedded(item: ContentBase, family: String, errors: Array[String]) -> void:
	if item is IncidentDef:
		for cond: ConditionDef in item.required_conditions:
			_check_condition(cond, family, item.id, errors)
		for cond: ConditionDef in item.amplifier_conditions:
			_check_condition(cond, family, item.id, errors)
		for choice: IncidentChoiceDef in item.choices:
			for effect: EffectDef in choice.immediate_effects:
				_check_effect(effect, family, item.id, errors)
			for cond: ConditionDef in choice.required_conditions:
				_check_condition(cond, family, item.id, errors)

	elif item is StandingOrderDef:
		for effect: EffectDef in item.tick_effects:
			_check_effect(effect, family, item.id, errors)

	elif item is ShipUpgradeDef:
		for effect: EffectDef in item.upgrade_effects:
			_check_effect(effect, family, item.id, errors)

	elif item is ObjectiveDef:
		if item.success_condition != null:
			_check_condition(item.success_condition, family, item.id, errors)

	elif item is OfficerDef:
		for effect: EffectDef in item.starting_effects:
			_check_effect(effect, family, item.id, errors)


static func _check_effect(
	effect: EffectDef,
	family: String,
	item_id: String,
	errors: Array[String]
) -> void:
	if effect.type not in VALID_EFFECT_TYPES:
		errors.append("[%s/%s] EffectDef has unknown type: \"%s\"" % [family, item_id, effect.type])


static func _check_condition(
	cond: ConditionDef,
	family: String,
	item_id: String,
	errors: Array[String]
) -> void:
	if cond.type not in VALID_CONDITION_TYPES:
		errors.append("[%s/%s] ConditionDef has unknown type: \"%s\"" % [family, item_id, cond.type])
