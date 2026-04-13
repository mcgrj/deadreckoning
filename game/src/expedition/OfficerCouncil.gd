# OfficerCouncil.gd
# Stateless utility that generates proposal Dictionaries for an incident from present officers.
# Each proposal has: type, officer_id, officer_def, choice, choice_index, silence_line.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-4-5-standing-orders-incidents-design.md
class_name OfficerCouncil

const SILENCE_LINES: Dictionary = {
	"disciplinarian": "Not my place to speak to this, sir. Your call.",
	"humanitarian": "I have no counsel here. I trust your judgement, Captain.",
	"pragmatist": "Nothing useful to offer, sir.",
}
const DEFAULT_SILENCE_LINE := "I have nothing to offer on this matter."


## Generate proposals for all officers present in state.
## officer_defs: Array of OfficerDef — caller provides these (typically from ContentRegistry).
## Returns Array of proposal Dictionaries. Always ends with one direct_order proposal.
static func get_proposals(
	state: ExpeditionState,
	incident: IncidentDef,
	officer_defs: Array
) -> Array:
	var proposals: Array = []

	# Build a lookup from officer_id → choice_index for this incident
	var officer_choice_map: Dictionary = {}
	for i: int in range(incident.choices.size()):
		var choice: IncidentChoiceDef = incident.choices[i]
		if choice.officer_id != "":
			officer_choice_map[choice.officer_id] = i

	# For each officer present in state, generate a proposal or silence
	for def: OfficerDef in officer_defs:
		if not state.has_officer(def.id):
			continue
		if def.advice_hooks.has(incident.id) and officer_choice_map.has(def.id):
			var choice_idx: int = officer_choice_map[def.id]
			proposals.append({
				"type": "officer",
				"officer_id": def.id,
				"officer_def": def,
				"choice": incident.choices[choice_idx],
				"choice_index": choice_idx,
				"silence_line": "",
			})
		else:
			proposals.append({
				"type": "silence",
				"officer_id": def.id,
				"officer_def": def,
				"choice": null,
				"choice_index": -1,
				"silence_line": SILENCE_LINES.get(def.worldview, DEFAULT_SILENCE_LINE),
			})

	# Always append a direct order proposal
	proposals.append({
		"type": "direct_order",
		"officer_id": "",
		"officer_def": null,
		"choice": null,
		"choice_index": -1,
		"silence_line": "",
	})

	return proposals
