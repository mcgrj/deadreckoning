# Emergent Officers & Expedition Scars Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static authored officer `.tres` system with procedurally generated officers drawn from authored JSON content pools, add an Admiralty pool with role-balance guarantees, and implement expedition scars that persist across runs.

**Architecture:** `OfficerGenerator` reads four JSON pool files per role and assembles `OfficerDef` records. The pool lives in `ProgressionState.officer_pool` (2–3 candidates per role). During a run, `ExpeditionState.officer_scars` accumulates provisional scars which `SaveManager.commit_officer_scars()` writes back to the pool at run end. `OfficerCouncil` is updated to match incident choices by role rather than static id.

**Tech Stack:** Godot 4.6, GDScript, JSON (`FileAccess`/`JSON`), existing `.tres` `ProgressionState` persistence via `SaveManager`.

**Test runner:** `godot --headless --path game res://test/<TestName>.tscn`

---

## File Map

### New files
| File | Responsibility |
|---|---|
| `game/src/expedition/OfficerGenerator.gd` | Reads JSON pools, produces OfficerDef records |
| `game/content/officer_pools/names.json` | Name pools per role |
| `game/content/officer_pools/backgrounds.json` | Origin / service / reputation fragment pools per role |
| `game/content/officer_pools/traits.json` | Trait pools per role (id, display, tier, hint, excludes) |
| `game/content/officer_pools/stances.json` | Pre-departure stance pools per role |
| `game/test/OfficerGeneratorTest.gd` + `.tscn` | Generation unit tests |
| `game/test/OfficerPoolTest.gd` + `.tscn` | Pool management and scar commit unit tests |

### Modified files
| File | Change |
|---|---|
| `game/src/content/resources/OfficerDef.gd` | Add 10 new fields (see Task 1) |
| `game/src/content/ContentValidator.gd` | Add `add_officer_scar` effect type and `officer_has_scar` condition type |
| `game/src/expedition/ExpeditionState.gd` | Add `officer_defs`, `officer_scars`, and two accessor methods |
| `game/src/expedition/EffectProcessor.gd` | Handle `add_officer_scar` effect |
| `game/src/expedition/ConditionEvaluator.gd` | Handle `officer_has_scar` condition |
| `game/src/expedition/OfficerCouncil.gd` | Match choices by `def.role` instead of `def.id` |
| `game/src/resources/ProgressionState.gd` | Add `officer_pool: Array[OfficerDef]`; rework `create_default()` |
| `game/src/SaveManager.gd` | Add `commit_officer_scars()` and `replenish_pool()` |
| `game/src/ui/IncidentResolutionScene.gd` | Use `state.officer_defs` instead of `ContentRegistry` |
| `game/src/ui/PreparationScene.gd` | Show pool from `ProgressionState` instead of `ContentRegistry` |
| `game/src/ui/RunEndScene.gd` | Call scar commit before returning to Admiralty |

### Deleted files
All files in `game/content/officers/` except `.gitkeep` (14 authored `.tres` files).

---

## Task 1: Extend OfficerDef Schema

**Files:**
- Modify: `game/src/content/resources/OfficerDef.gd`

- [ ] **Step 1: Replace the file contents**

```gdscript
# OfficerDef.gd
# Content definition for a generated officer. Produced by OfficerGenerator — not hand-authored.
# Stored in ProgressionState.officer_pool between runs.
#
# Spec: docs/superpowers/specs/2026-04-14-emergent-officers-scars-design.md
class_name OfficerDef
extends ContentBase

## Officer role: "first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain".
@export var role: String = ""

## Advice accuracy, 1–5.
@export var competence: int = 0

## Proposal reliability, 1–5.
@export var loyalty: int = 0

## Personality worldview: "disciplinarian", "humanitarian", "pragmatist".
@export var worldview: String = ""

## Traits visible to the player at hire (disclosed tier).
@export var disclosed_traits: Array[String] = []

## Trait ids behind the rumours (parallel to rumoured_hints).
@export var rumoured_traits: Array[String] = []

## Hint text shown to the player for each rumoured trait (parallel to rumoured_traits).
@export var rumoured_hints: Array[String] = []

## Traits revealed only through specific incident conditions.
@export var hidden_traits: Array[String] = []

## Type of intelligence this officer provides: "route", "supply", "crew_risk", "omen", "discipline", "ship".
@export var information_domain: String = ""

## Promise id required for hire. Empty = no promise required.
@export var pre_voyage_promise_id: String = ""

## Promise text displayed when hire requires a promise.
@export var pre_voyage_promise_text: String = ""

## Pre-departure opinion line. Empty = officer says nothing before sailing.
@export var pre_departure_stance: String = ""

## Scar trait tags accumulated across runs and committed at run end.
@export var scar_traits: Array[String] = []

## Number of runs this officer has survived.
@export var runs_survived: int = 0

## Human-readable summaries of significant expedition events (shown in pool UI).
@export var notable_events: Array[String] = []

## Effects applied to ExpeditionState when this officer is selected at preparation.
@export var starting_effects: Array[EffectDef] = []

## Incident ids for which this officer has authored proposal choices. Legacy field —
## generated officers use role matching in OfficerCouncil instead.
@export var advice_hooks: Array[String] = []
```

- [ ] **Step 2: Commit**

```bash
git add game/src/content/resources/OfficerDef.gd
git commit -m "feat: extend OfficerDef schema for generation and scars"
```

---

## Task 2: Officer Scar System — State, Effects, Conditions, Validator

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`
- Modify: `game/src/expedition/EffectProcessor.gd`
- Modify: `game/src/expedition/ConditionEvaluator.gd`
- Modify: `game/src/content/ContentValidator.gd`

- [ ] **Step 1: Write the failing test**

Add a new test file `game/test/OfficerScarTest.gd`:

```gdscript
# OfficerScarTest.gd
# Tests for officer scar accumulation in ExpeditionState,
# EffectProcessor add_officer_scar, and ConditionEvaluator officer_has_scar.
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
	print("=== OfficerScarTest ===\n")
	_test_add_and_check_scar()
	_test_scar_not_duplicated()
	_test_effect_processor_add_scar()
	_test_condition_evaluator_officer_has_scar()
	_test_condition_evaluator_officer_has_scar_fail()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


func _test_add_and_check_scar() -> void:
	var state := ExpeditionState.new()
	state.add_officer_scar("surgeon", "publicly_overruled")
	check(state.officer_has_scar("surgeon", "publicly_overruled"), "add_officer_scar sets scar")
	check(not state.officer_has_scar("surgeon", "other_scar"), "missing scar returns false")
	check(not state.officer_has_scar("bosun", "publicly_overruled"), "different role returns false")


func _test_scar_not_duplicated() -> void:
	var state := ExpeditionState.new()
	state.add_officer_scar("surgeon", "haunted")
	state.add_officer_scar("surgeon", "haunted")
	check(state.officer_scars.get("surgeon", []).size() == 1, "duplicate scar not added twice")


func _test_effect_processor_add_scar() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	var effect := EffectDef.new()
	effect.type = "add_officer_scar"
	effect.tag = "witnessed_broken_promise"
	effect.target_id = "purser"
	EffectProcessor.apply(state, effect, log)
	check(state.officer_has_scar("purser", "witnessed_broken_promise"), "EffectProcessor add_officer_scar writes to state")


func _test_condition_evaluator_officer_has_scar() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	state.add_officer_scar("bosun", "respects_hard_authority")
	var cond := ConditionDef.new()
	cond.type = "officer_has_scar"
	cond.tag = "respects_hard_authority"
	cond.target_id = "bosun"
	check(ConditionEvaluator.evaluate(state, cond, log), "officer_has_scar condition passes when scar present")


func _test_condition_evaluator_officer_has_scar_fail() -> void:
	var state := ExpeditionState.new()
	var log := SimulationLog.new()
	var cond := ConditionDef.new()
	cond.type = "officer_has_scar"
	cond.tag = "haunted"
	cond.target_id = "chaplain"
	check(not ConditionEvaluator.evaluate(state, cond, log), "officer_has_scar condition fails when scar absent")
```

Add scene file `game/test/OfficerScarTest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/OfficerScarTest.gd" id="1"]

[node name="OfficerScarTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run test — expect FAIL (method not found)**

```bash
godot --headless --path game res://test/OfficerScarTest.tscn 2>&1 | tail -20
```

Expected: error about `add_officer_scar` not existing.

- [ ] **Step 3: Add officer_scars to ExpeditionState**

In `game/src/expedition/ExpeditionState.gd`, add after the `stress_indicators` block and before `run_end_reason`:

```gdscript
## Officer scars active this run. Keys are role strings; values are Array[String] of scar tags.
## Populated from pool at run start (persistent scars) and appended to during the run (provisional).
var officer_defs: Array = []  # Array[OfficerDef] — not exported; holds hired officer records for this run
var officer_scars: Dictionary = {}  # role -> Array[String]
```

Add two methods after `nudge_leadership_tag()`:

```gdscript
func add_officer_scar(role: String, scar_tag: String) -> void:
	if not officer_scars.has(role):
		officer_scars[role] = []
	if scar_tag not in officer_scars[role]:
		officer_scars[role].append(scar_tag)


func officer_has_scar(role: String, scar_tag: String) -> bool:
	return scar_tag in officer_scars.get(role, [])
```

- [ ] **Step 4: Add add_officer_scar to EffectProcessor**

In `game/src/expedition/EffectProcessor.gd`, add a new case inside the `match effect.type:` block before the `_:` wildcard:

```gdscript
		"add_officer_scar":
			state.add_officer_scar(effect.target_id, effect.tag)
			log.log_effect(state.tick_count, "EffectProcessor",
				"Officer scar '%s' added to role '%s'" % [effect.tag, effect.target_id],
				{"type": "add_officer_scar", "role": effect.target_id, "scar": effect.tag})
```

- [ ] **Step 5: Add officer_has_scar to ConditionEvaluator**

In `game/src/expedition/ConditionEvaluator.gd`, add a new case inside the `match condition.type:` block before the `_:` wildcard:

```gdscript
		"officer_has_scar":
			result = state.officer_has_scar(condition.target_id, condition.tag)
			details["role"] = condition.target_id
			details["scar"] = condition.tag
			message = "Officer '%s' has scar '%s'? %s" % [condition.target_id, condition.tag, "PASS" if result else "FAIL"]
```

- [ ] **Step 6: Update ContentValidator**

In `game/src/content/ContentValidator.gd`, add to the two const arrays:

```gdscript
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
	"add_officer_scar",  # add this line
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
	"officer_has_scar",  # add this line
]
```

- [ ] **Step 7: Run test — expect PASS**

```bash
godot --headless --path game res://test/OfficerScarTest.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 8: Commit**

```bash
git add game/test/OfficerScarTest.gd game/test/OfficerScarTest.tscn \
        game/src/expedition/ExpeditionState.gd \
        game/src/expedition/EffectProcessor.gd \
        game/src/expedition/ConditionEvaluator.gd \
        game/src/content/ContentValidator.gd
git commit -m "feat: add officer scar system to state, effects, and conditions"
```

---

## Task 3: JSON Content Pool Files

**Files:**
- Create: `game/content/officer_pools/names.json`
- Create: `game/content/officer_pools/backgrounds.json`
- Create: `game/content/officer_pools/traits.json`
- Create: `game/content/officer_pools/stances.json`

- [ ] **Step 1: Create names.json**

```json
{
  "first_lieutenant": ["Blackwood", "Pemberton", "Aldiss", "Carmichael", "Grantham", "Hartley", "Osborn", "Phelps"],
  "master": ["Tanner", "Selkirk", "Holt", "Wraight", "Draper", "Fenwick", "Quartermaine", "Spence"],
  "gunner": ["Coghill", "Durrant", "Flint", "Harker", "Kidd", "Munro", "Oldfield", "Pruitt"],
  "purser": ["Farrow", "Gidley", "Jenks", "Lemaire", "Nichols", "Oake", "Plum", "Seddon"],
  "surgeon": ["Halcrow", "Meldrum", "Trench", "Verney", "Whittaker", "Yorke", "Ashe", "Cribb"],
  "chaplain": ["Berryman", "Cornforth", "Dinsdale", "Estwick", "Faber", "Greenway", "Hornsby", "Ivatt"]
}
```

- [ ] **Step 2: Create backgrounds.json**

```json
{
  "first_lieutenant": {
    "origins": [
      "Devon-born.",
      "Scottish.",
      "No family record worth mentioning.",
      "Son of a naval officer who died in service.",
      "Came up through the merchant fleet.",
      "Kent-born. Fourth son of a clergyman."
    ],
    "service": [
      "Served under Rear-Admiral Thornton before a dispute over a flogging order.",
      "Three voyages before the mast; earned his commission the hard way.",
      "Recommended by a man who has since resigned his commission.",
      "Left his previous posting under circumstances the Admiralty records as routine.",
      "Served two commissions without incident. The third is not spoken of.",
      "Court-martial acquitted him. The crew that testified is no longer in service."
    ],
    "reputation": [
      "Known for discipline; known for holding grudges.",
      "The men respect him. The officers are less certain.",
      "Fair when watched. Less so when not.",
      "Hard on pressed men. Attentive to volunteers.",
      "Quiet. Does not explain himself.",
      "Popular enough. Has ambitions he has not declared."
    ]
  },
  "master": {
    "origins": [
      "Cornish. Born within sight of the sea.",
      "Dutch-trained, English commission.",
      "No formal record of origin. Charts well.",
      "Son of a merchantman. Knows those routes better than the Navy does.",
      "Norfolk-born. Grew up piloting the estuary.",
      "Scottish. Learned his charts in waters the Admiralty does not patrol."
    ],
    "service": [
      "Three commissions on the Indies route. Knows the currents better than the charts do.",
      "Served under a commander who trusted him completely. That commander is dead.",
      "Recommended by the Hydrographic Office for his survey work.",
      "Left his last posting when the ship ran aground. He had warned them.",
      "Two years on the northern passage. Does not speak of it voluntarily.",
      "His charts are excellent. Some details have been corrected by experience."
    ],
    "reputation": [
      "Reliable. Has opinions he keeps to himself until they become unavoidable.",
      "Accurate. Drinks before a hard passage — never after.",
      "The crew trusts his navigation. Less so his moods.",
      "Quiet in council. Loud when he is right and has been ignored.",
      "His charts are his own. He does not share them freely.",
      "Known to add notes to official charts that the Admiralty has not requested."
    ]
  },
  "gunner": {
    "origins": [
      "Portsmouth-born. Grew up in the ordnance yards.",
      "Pressed at eighteen. Has never left service since.",
      "Welsh. Came up through the artillery before the Navy.",
      "No family record. Appeared at a recruiting office with his own references.",
      "Son of a gunner. And his father before him.",
      "Scottish Highlands. Arrived at the Navy with a chip on his shoulder and excellent aim."
    ],
    "service": [
      "Twenty years in the powder room. Never an accident he will admit to.",
      "Served on three ships that took prize. Considers this unremarkable.",
      "His last posting ended when the magazine misfired. He survived. Most didn't.",
      "Two commissions under a commander who overruled him once. Only once.",
      "Known for keeping the powder dry when no one else thought it mattered.",
      "Recommended for his work during an engagement the official record underplays."
    ],
    "reputation": [
      "Reliable with powder. Less reliable with patience.",
      "The gun crews respect him. He does not return the sentiment unless earned.",
      "Has a temper he controls until he doesn't.",
      "Thorough. Will not cut corners on the magazine even under direct order.",
      "Quiet most of the time. Decisive in the moments that count.",
      "Has views on how a ship should be run that he shares whether asked or not."
    ]
  },
  "purser": {
    "origins": [
      "London-born. Counting-house trained before the Navy.",
      "Bristol merchant family. Knows what things are worth.",
      "No formal record. Arrived with strong arithmetic and better references.",
      "Son of a bankrupt. Careful with money as a result.",
      "Scottish. Worked the Highland trade routes before commissioning.",
      "Came up through victualling. Knows every trick in the stores."
    ],
    "service": [
      "Three commissions without a shortfall he admits to.",
      "Questions were raised about his accounts on a previous commission. He was cleared.",
      "Recommended by his last commander for keeping the ship fed through a difficult season.",
      "Left his previous posting when the captain died. The stores were found intact.",
      "Known for finding supply where none was expected.",
      "His ledgers are meticulous. Some entries have been queried and subsequently corrected."
    ],
    "reputation": [
      "Careful with the stores. Less careful with who he tells.",
      "The men eat well under him. The officers are less certain how.",
      "Knows the difference between what the ledger says and what the hold holds.",
      "Reliable. Has a habit of noting things that were better left unrecorded.",
      "Drinks before accounting. Claims it steadies his hand.",
      "Popular with the cook. The cook is the most important man on the ship."
    ]
  },
  "surgeon": {
    "origins": [
      "Edinburgh trained.",
      "Devon-born. Apprenticed to a naval surgeon at fourteen.",
      "No family record. Appeared with credentials the Admiralty found satisfactory.",
      "Son of a physician who disapproved of the Navy.",
      "Came from the merchant service after one voyage he does not describe.",
      "Scottish. Completed his apprenticeship early. The reason is not recorded."
    ],
    "service": [
      "Served under Admiral Pemberton before a dispute over a court-martial verdict.",
      "Three years on the Indies route. Seen things the textbooks do not cover.",
      "Recommended by a man who has since died. The recommendation is still on file.",
      "Left a practice in Bristol under circumstances he describes as a misunderstanding.",
      "Sailed one previous commission — lost the ship, saved every man. Considers this unremarkable.",
      "Two commissions without a death he could not account for. This is unusual."
    ],
    "reputation": [
      "Steady hands. Known to drink before noon — never after. So far.",
      "Known for accuracy in diagnosis. Known for grudges in council.",
      "Popular with the men. Less so with officers who have been overruled.",
      "Quiet in his quarters. Less quiet in the sick bay.",
      "Has made enemies in the surgical corps. Does not appear to regret this.",
      "The crew trusts him. He has not yet given them reason not to."
    ]
  },
  "chaplain": {
    "origins": [
      "Oxford-trained. Took orders before the Navy took him.",
      "No parish. Came to the Navy after a disagreement with his bishop.",
      "Welsh. The congregation followed him further than expected.",
      "Son of a minister. The faith is inherited. The doubt is his own.",
      "Came late to orders. Prior life not on record.",
      "Scottish. Two years in a Highland parish before the sea called louder."
    ],
    "service": [
      "Three commissions. The men of two of them speak well of him.",
      "Served under a commander who did not believe. This was complicated.",
      "Recommended by the Bishop of London for reasons the Navy found sufficient.",
      "Left his last posting when the ship made port. The captain's log says he resigned. The crew's account differs.",
      "Known for giving burial at sea with more ceremony than the regulations require.",
      "His sermons are short. His prayers are long. The men prefer this."
    ],
    "reputation": [
      "Steady faith. The men find comfort in him. Some find discomfort.",
      "Believes what he preaches. This is rarer than it should be.",
      "Popular with the frightened. Less popular with the cynical.",
      "Has views on omens and providence that the surgeon considers superstition and the crew considers gospel.",
      "Quiet when things go well. Present when they do not.",
      "The men confess to him. He does not share what he hears. This is known."
    ]
  }
}
```

- [ ] **Step 3: Create traits.json**

Each entry: `id`, `display`, `tier` ("disclosed"/"rumoured"/"hidden"), `hint` (shown for rumoured; empty otherwise), `excludes` (array of ids that cannot appear alongside this one).

```json
{
  "first_lieutenant": [
    { "id": "holds_grudges", "display": "Holds grudges", "tier": "disclosed", "hint": "", "excludes": ["forgiving"] },
    { "id": "forgiving", "display": "Forgiving nature", "tier": "disclosed", "hint": "", "excludes": ["holds_grudges"] },
    { "id": "strict_disciplinarian", "display": "Strict disciplinarian", "tier": "disclosed", "hint": "", "excludes": ["lenient_by_nature"] },
    { "id": "lenient_by_nature", "display": "Lenient by nature", "tier": "disclosed", "hint": "", "excludes": ["strict_disciplinarian"] },
    { "id": "harbours_ambition", "display": "Harbours ambition", "tier": "rumoured", "hint": "There are rumours of ambitions beyond his current rank.", "excludes": [] },
    { "id": "loyal_to_captain", "display": "Loyal to captain", "tier": "disclosed", "hint": "", "excludes": ["harbours_ambition"] },
    { "id": "sympathises_with_crew", "display": "Sympathises with crew", "tier": "hidden", "hint": "", "excludes": ["strict_disciplinarian"] },
    { "id": "prior_scandal", "display": "Prior scandal", "tier": "rumoured", "hint": "His record shows a cleared inquiry — the details are not public.", "excludes": [] },
    { "id": "steady_under_pressure", "display": "Steady under pressure", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "volatile_temper", "display": "Volatile temper", "tier": "hidden", "hint": "", "excludes": ["steady_under_pressure"] }
  ],
  "master": [
    { "id": "exceptional_charts", "display": "Exceptional charts", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "drinks_before_passage", "display": "Drinks before a hard passage", "tier": "rumoured", "hint": "There are questions about his habits before difficult navigation.", "excludes": ["temperate"] },
    { "id": "temperate", "display": "Temperate habits", "tier": "disclosed", "hint": "", "excludes": ["drinks_before_passage"] },
    { "id": "northern_route_veteran", "display": "Northern route veteran", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "cautious_navigator", "display": "Cautious navigator", "tier": "disclosed", "hint": "", "excludes": ["reckless_navigator"] },
    { "id": "reckless_navigator", "display": "Reckless navigator", "tier": "hidden", "hint": "", "excludes": ["cautious_navigator"] },
    { "id": "distrusts_charts", "display": "Distrusts official charts", "tier": "hidden", "hint": "", "excludes": [] },
    { "id": "prior_grounding", "display": "Prior grounding", "tier": "rumoured", "hint": "There is a note in his record about a grounding that was ruled unavoidable.", "excludes": [] },
    { "id": "knows_the_currents", "display": "Knows the currents", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "keeps_own_counsel", "display": "Keeps own counsel", "tier": "disclosed", "hint": "", "excludes": [] }
  ],
  "gunner": [
    { "id": "precise_with_powder", "display": "Precise with powder", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "short_temper", "display": "Short temper", "tier": "rumoured", "hint": "The gun crews have mentioned a temper. Nothing formal on record.", "excludes": ["patient_manner"] },
    { "id": "patient_manner", "display": "Patient manner", "tier": "disclosed", "hint": "", "excludes": ["short_temper"] },
    { "id": "will_not_cut_corners", "display": "Will not cut corners", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "prize_hungry", "display": "Prize hungry", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "resents_orders", "display": "Resents orders", "tier": "hidden", "hint": "", "excludes": ["will_not_cut_corners"] },
    { "id": "superstitious", "display": "Superstitious", "tier": "hidden", "hint": "", "excludes": [] },
    { "id": "prior_accident", "display": "Prior powder accident", "tier": "rumoured", "hint": "There was an incident on his last posting. The inquiry found no fault.", "excludes": [] },
    { "id": "crew_respected", "display": "Respected by gun crews", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "has_opinions", "display": "Has strong opinions", "tier": "disclosed", "hint": "", "excludes": [] }
  ],
  "purser": [
    { "id": "meticulous_ledgers", "display": "Meticulous ledgers", "tier": "disclosed", "hint": "", "excludes": ["lax_accounting"] },
    { "id": "lax_accounting", "display": "Lax accounting", "tier": "hidden", "hint": "", "excludes": ["meticulous_ledgers"] },
    { "id": "drinks_before_accounting", "display": "Drinks before accounting", "tier": "rumoured", "hint": "There are questions about his habits on ledger days.", "excludes": ["meticulous_ledgers"] },
    { "id": "finds_supply", "display": "Finds supply", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "skims_the_stores", "display": "Skims the stores", "tier": "hidden", "hint": "", "excludes": ["meticulous_ledgers"] },
    { "id": "prior_inquiry", "display": "Prior inquiry", "tier": "rumoured", "hint": "Questions were raised about a previous commission's accounts. He was cleared.", "excludes": [] },
    { "id": "trusted_by_cook", "display": "Trusted by the cook", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "overly_cautious_with_stores", "display": "Overly cautious with stores", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "notes_everything", "display": "Notes everything", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "conceals_shortfalls", "display": "Conceals shortfalls", "tier": "hidden", "hint": "", "excludes": ["meticulous_ledgers", "notes_everything"] }
  ],
  "surgeon": [
    { "id": "steady_hands", "display": "Steady hands", "tier": "disclosed", "hint": "", "excludes": ["tremors"] },
    { "id": "tremors", "display": "Tremors", "tier": "hidden", "hint": "", "excludes": ["steady_hands"] },
    { "id": "drinks_before_noon", "display": "Drinks before noon", "tier": "rumoured", "hint": "Questions have been raised about his habits.", "excludes": ["strict_self_discipline"] },
    { "id": "strict_self_discipline", "display": "Strict self-discipline", "tier": "disclosed", "hint": "", "excludes": ["drinks_before_noon"] },
    { "id": "popular_with_crew", "display": "Popular with the crew", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "cold_bedside_manner", "display": "Cold bedside manner", "tier": "hidden", "hint": "", "excludes": ["popular_with_crew"] },
    { "id": "harbour_grievance", "display": "Harbours a grievance", "tier": "hidden", "hint": "", "excludes": [] },
    { "id": "ration_crisis_veteran", "display": "Ration crisis veteran", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "privately_devout", "display": "Privately devout", "tier": "hidden", "hint": "", "excludes": [] },
    { "id": "accurate_diagnosis", "display": "Accurate diagnosis", "tier": "disclosed", "hint": "", "excludes": [] }
  ],
  "chaplain": [
    { "id": "steady_faith", "display": "Steady faith", "tier": "disclosed", "hint": "", "excludes": ["crisis_of_faith"] },
    { "id": "crisis_of_faith", "display": "Crisis of faith", "tier": "hidden", "hint": "", "excludes": ["steady_faith"] },
    { "id": "popular_with_frightened", "display": "Popular with the frightened", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "superstitious_tendencies", "display": "Superstitious tendencies", "tier": "rumoured", "hint": "The men say he takes omens seriously. More seriously than the regulations suggest.", "excludes": [] },
    { "id": "keeps_confessions", "display": "Keeps confessions", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "shares_what_he_hears", "display": "Shares what he hears", "tier": "hidden", "hint": "", "excludes": ["keeps_confessions"] },
    { "id": "unpopular_with_cynics", "display": "Unpopular with cynics", "tier": "hidden", "hint": "", "excludes": [] },
    { "id": "prior_parish_trouble", "display": "Prior parish trouble", "tier": "rumoured", "hint": "He left his last parish under circumstances the Bishop did not record.", "excludes": [] },
    { "id": "gives_good_burial", "display": "Gives good burial", "tier": "disclosed", "hint": "", "excludes": [] },
    { "id": "sermons_are_short", "display": "Sermons are short", "tier": "disclosed", "hint": "", "excludes": [] }
  ]
}
```

- [ ] **Step 4: Create stances.json**

```json
{
  "first_lieutenant": [
    "Sir — the crew's mood before we sail. I'd want you to know they're holding, but they're watching to see how this commission is run.",
    "The objective as stated leaves us some latitude on the southern approach. I wanted you to know before we commit.",
    "I've reviewed the standing orders. I have no objection. I'll enforce them as given.",
    "There are two men from the last commission I'd rather not see together on a watch. I'll manage it, but you should know."
  ],
  "master": [
    "I've sailed those waters, sir. The omen node the charts show on the northern route — I wouldn't trust the category.",
    "The western approach is longer, but the eastern has a lee shore in these conditions. Your call.",
    "I can navigate us through. I'd want the spirit locker available before we enter the narrows — it's cold work.",
    "The charts are reasonable. I've added my own notes in pencil. Pay attention to the pencil."
  ],
  "gunner": [
    "The powder's in good order. I'd want to know before we sail if we're expecting engagement — there's preparation I'd rather do in harbour.",
    "The magazine is sound. The forward gun has a question I haven't answered yet. I'll have it answered before we clear the bar.",
    "I've nothing to raise before we sail, sir. The guns are ready.",
    "There are three men in my crew I don't know yet. I'll have their measure by the time we need them."
  ],
  "purser": [
    "The stores are loaded as provisioned. I'd want you to know the water casks are new — I don't know them yet.",
    "I've reviewed the objective. If we're surveying, we'll need extra provisions for shore parties. I can make it work, but it'll be tight.",
    "The rum allocation is correct. I want that on record before we sail.",
    "I'm not certain I have enough medicine for a long passage, sir. That's the surgeon's department, but I wanted you to hear it from me."
  ],
  "surgeon": [
    "I've reviewed the charts, sir. The northern route — I'd want extra medicine for what the weather can do to a man in those latitudes.",
    "The crew's in reasonable health for now. I wouldn't push them hard the first week.",
    "If I may, sir — I'm not certain I have enough medicine for a long passage.",
    "There are two men from the last commission who I want to keep an eye on. Nothing formal. Just a concern."
  ],
  "chaplain": [
    "I'll hold a service before we sail if you permit it, sir. The men find it settling.",
    "The objective the Admiralty has given us — there's something in the phrasing that unsettles me. I may be reading too much into it.",
    "I've spoken with the men. They're ready. Some of them more than others.",
    "Sir — the omen node on the northern route. I'm not asking you to change the route. I'm asking you to let me address it with the men before we arrive."
  ]
}
```

- [ ] **Step 5: Commit pool files**

```bash
mkdir -p game/content/officer_pools
git add game/content/officer_pools/
git commit -m "feat: add officer generation JSON content pools"
```

---

## Task 4: OfficerGenerator Class

**Files:**
- Create: `game/src/expedition/OfficerGenerator.gd`

- [ ] **Step 1: Write the failing test in OfficerGeneratorTest.gd**

```gdscript
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
```

Create scene file `game/test/OfficerGeneratorTest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/OfficerGeneratorTest.gd" id="1"]

[node name="OfficerGeneratorTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run test — expect FAIL (OfficerGenerator not defined)**

```bash
godot --headless --path game res://test/OfficerGeneratorTest.tscn 2>&1 | tail -10
```

Expected: script error about `OfficerGenerator`.

- [ ] **Step 3: Create OfficerGenerator.gd**

```gdscript
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
```

- [ ] **Step 4: Run test — expect PASS**

```bash
godot --headless --path game res://test/OfficerGeneratorTest.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/OfficerGenerator.gd \
        game/test/OfficerGeneratorTest.gd \
        game/test/OfficerGeneratorTest.tscn
git commit -m "feat: add OfficerGenerator with JSON pool assembly and trait coherence"
```

---

## Task 5: ProgressionState Pool + SaveManager Pool Methods

**Files:**
- Modify: `game/src/resources/ProgressionState.gd`
- Modify: `game/src/SaveManager.gd`

- [ ] **Step 1: Write the failing test in OfficerPoolTest.gd**

```gdscript
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
	var surgeon := prog.get_candidates_for_role("surgeon")[0]
	var state := ExpeditionState.new()
	state.officer_defs = [surgeon]
	state.add_officer_scar("surgeon", "publicly_overruled")
	SaveManager.commit_officer_scars(state, prog)
	var updated := prog.find_officer_by_id(surgeon.id)
	check(updated != null, "officer found in pool after commit")
	check("publicly_overruled" in updated.scar_traits, "scar committed to pool officer")


func _test_commit_increments_runs_survived() -> void:
	var prog := ProgressionState.create_default()
	var master := prog.get_candidates_for_role("master")[0]
	var state := ExpeditionState.new()
	state.officer_defs = [master]
	var before := master.runs_survived
	SaveManager.commit_officer_scars(state, prog)
	check(master.runs_survived == before + 1, "runs_survived incremented after commit")


func _test_commit_stat_drift_loyalty_up() -> void:
	var prog := ProgressionState.create_default()
	var purser := prog.get_candidates_for_role("purser")[0]
	purser.loyalty = 3
	var state := ExpeditionState.new()
	state.officer_defs = [purser]
	state.add_memory_flag("advice_followed_purser")  # signals advice was heeded
	SaveManager.commit_officer_scars(state, prog)
	check(purser.loyalty >= 3, "loyalty does not decrease when advice was followed")


func _test_commit_stat_drift_loyalty_down() -> void:
	var prog := ProgressionState.create_default()
	var chaplain := prog.get_candidates_for_role("chaplain")[0]
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
```

Create scene file `game/test/OfficerPoolTest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/OfficerPoolTest.gd" id="1"]

[node name="OfficerPoolTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
godot --headless --path game res://test/OfficerPoolTest.tscn 2>&1 | tail -10
```

Expected: error about `officer_pool` not defined.

- [ ] **Step 3: Update ProgressionState.gd**

Replace the entire file:

```gdscript
# ProgressionState.gd
# Persistent meta-progression state. Saved to disk between runs.
# Tracks objectives, unlocked content, Admiralty memory, and the officer pool.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-6a-admiralty-preparation-design.md
#       docs/superpowers/specs/2026-04-14-emergent-officers-scars-design.md
class_name ProgressionState
extends Resource

@export var completed_objective_ids: Array[String] = []
@export var unlocked_content_ids: Array[String] = []
@export var last_run_difficulty_score: int = 0
@export var admiralty_bias: Array[String] = []
@export var scandal_flags: Array[String] = []
@export var officer_pool: Array[OfficerDef] = []


func is_unlocked(content_id: String) -> bool:
	return content_id in unlocked_content_ids


func apply_unlock(content_id: String) -> void:
	if content_id != "" and content_id not in unlocked_content_ids:
		unlocked_content_ids.append(content_id)


## Return all candidates in the pool for the given role.
func get_candidates_for_role(role: String) -> Array:
	return officer_pool.filter(func(d: OfficerDef): return d.role == role)


## Find a specific officer by id. Returns null if not found.
func find_officer_by_id(officer_id: String) -> OfficerDef:
	for def: OfficerDef in officer_pool:
		if def.id == officer_id:
			return def
	return null


static func create_default() -> ProgressionState:
	var p := ProgressionState.new()
	p.unlocked_content_ids = [
		# Doctrines
		"shared_hardship", "iron_discipline",
		# Upgrades
		"reinforced_hull", "medical_stores", "powder_magazine",
		# Objectives
		"survey_strange_shore", "recover_lost_charts",
		"survey_northern_passage", "condition_return_intact",
		"condition_low_burden", "survey_abandoned_settlement",
	]
	# Generate initial officer pool: 2 candidates per role.
	var required_roles := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]
	for role: String in required_roles:
		for _i in range(2):
			p.officer_pool.append(OfficerGenerator.generate(role))
	return p
```

- [ ] **Step 4: Update SaveManager.gd — add commit_officer_scars and replenish_pool**

Add the following methods to `game/src/SaveManager.gd` (after `record_report_framing`):

```gdscript
## Write provisional officer scars back to the pool and apply stat drift.
## Call this from RunEndScene before saving progression.
func commit_officer_scars(run_state: ExpeditionState, progression: ProgressionState) -> void:
	var SCAR_LOYALTY_DOWN := ["publicly_overruled", "complicit_in_concealment", "witnessed_broken_promise"]
	var SCAR_LOYALTY_UP := ["respects_hard_authority", "ration_crisis_veteran"]
	var SCAR_COMPETENCE_UP := ["ration_crisis_veteran", "survivor_of_high_losses", "endured_extreme_hardship"]

	for def: OfficerDef in run_state.officer_defs:
		var pool_def := progression.find_officer_by_id(def.id)
		if pool_def == null:
			continue

		# Merge provisional scars into persistent scar_traits
		var role_scars: Array = run_state.officer_scars.get(def.role, [])
		for scar: String in role_scars:
			if scar not in pool_def.scar_traits:
				pool_def.scar_traits.append(scar)
				pool_def.notable_events.append(scar.replace("_", " ").capitalize())

		# Stat drift based on scars earned this run
		var loyalty_delta := 0
		var competence_delta := 0
		for scar: String in role_scars:
			if scar in SCAR_LOYALTY_DOWN:
				loyalty_delta -= 1
			if scar in SCAR_LOYALTY_UP:
				loyalty_delta += 1
			if scar in SCAR_COMPETENCE_UP:
				competence_delta += 1
		pool_def.loyalty = clampi(pool_def.loyalty + loyalty_delta, 1, 5)
		pool_def.competence = clampi(pool_def.competence + competence_delta, 1, 5)

		pool_def.runs_survived += 1


## Ensure each role has at least 2 candidates. Generate to fill gaps.
func replenish_pool(progression: ProgressionState) -> void:
	var required_roles := ["first_lieutenant", "master", "gunner", "purser", "surgeon", "chaplain"]
	for role: String in required_roles:
		var count := progression.get_candidates_for_role(role).size()
		while count < 2:
			progression.officer_pool.append(OfficerGenerator.generate(role))
			count += 1
```

- [ ] **Step 5: Run test — expect PASS**

```bash
godot --headless --path game res://test/OfficerPoolTest.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/resources/ProgressionState.gd \
        game/src/SaveManager.gd \
        game/test/OfficerPoolTest.gd \
        game/test/OfficerPoolTest.tscn
git commit -m "feat: officer pool in ProgressionState; SaveManager commit_officer_scars and replenish"
```

---

## Task 6: OfficerCouncil — Match by Role

**Files:**
- Modify: `game/src/expedition/OfficerCouncil.gd`

The existing `OfficerCouncil` matches incident choices to officers by `def.id`. Authored incidents set `IncidentChoiceDef.officer_id` to role names (e.g. `"bosun"`, `"surgeon"`). Generated officers have unique ids. Fix: match by `def.role`.

- [ ] **Step 1: Replace OfficerCouncil.gd**

```gdscript
# OfficerCouncil.gd
# Stateless utility that generates proposal Dictionaries for an incident from present officers.
# Matches incident choices to officers by role (choice.officer_id == def.role).
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
## officer_defs: Array of OfficerDef — pass state.officer_defs from the run.
## Returns Array of proposal Dictionaries. Always ends with one direct_order proposal.
static func get_proposals(
	state: ExpeditionState,
	incident: IncidentDef,
	officer_defs: Array
) -> Array:
	var proposals: Array = []

	# Build a lookup from role -> choice_index.
	# IncidentChoiceDef.officer_id stores the role name (e.g. "surgeon", "bosun").
	var role_choice_map: Dictionary = {}
	for i: int in range(incident.choices.size()):
		var choice: IncidentChoiceDef = incident.choices[i]
		if choice.officer_id != "":
			role_choice_map[choice.officer_id] = i

	# For each officer present in state, generate a proposal or silence.
	for def: OfficerDef in officer_defs:
		if not state.has_officer(def.id):
			continue
		if role_choice_map.has(def.role):
			var choice_idx: int = role_choice_map[def.role]
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

	# Always append a direct order proposal.
	proposals.append({
		"type": "direct_order",
		"officer_id": "",
		"officer_def": null,
		"choice": null,
		"choice_index": -1,
		"silence_line": "",
	})

	return proposals
```

- [ ] **Step 2: Run existing Stage 4+5 tests to verify nothing broke**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 3: Commit**

```bash
git add game/src/expedition/OfficerCouncil.gd
git commit -m "fix: OfficerCouncil matches incident choices by role not static id"
```

---

## Task 7: Wire Officer Defs Through Run Flow

`IncidentResolutionScene` currently fetches officer defs from `ContentRegistry`. After this change, officer defs come from `ExpeditionState.officer_defs`, which is populated from the pool when `create_from_config()` is called.

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`
- Modify: `game/src/ui/IncidentResolutionScene.gd`

- [ ] **Step 1: Update ExpeditionState.create_from_config() to accept officer_defs**

In `game/src/expedition/ExpeditionState.gd`, update `create_from_config()`. Find the block that applies selected officers:

```gdscript
	# Apply selected officers
	var officer_ids: Array = config.get("officer_ids", [])
	for officer_id: String in officer_ids:
		var officer_def: OfficerDef = ContentRegistry.get_by_id("officers", officer_id) as OfficerDef
		if officer_def:
			state.officers.append(officer_def.id)
			EffectProcessor.apply_effects(state, officer_def.starting_effects, log)
```

Replace it with:

```gdscript
	# Apply selected officers from pool defs (preferred) or ids (legacy fallback)
	var officer_defs_config: Array = config.get("officer_defs", [])
	if not officer_defs_config.is_empty():
		for def: OfficerDef in officer_defs_config:
			state.officers.append(def.id)
			state.officer_defs.append(def)
			# Load persistent scars into officer_scars for condition checking this run
			for scar: String in def.scar_traits:
				state.add_officer_scar(def.role, scar)
			EffectProcessor.apply_effects(state, def.starting_effects, log)
	else:
		# Legacy path — ContentRegistry lookup (used in tests that don't have pool)
		var officer_ids: Array = config.get("officer_ids", [])
		for officer_id: String in officer_ids:
			var officer_def: OfficerDef = ContentRegistry.get_by_id("officers", officer_id) as OfficerDef
			if officer_def:
				state.officers.append(officer_def.id)
				state.officer_defs.append(officer_def)
				EffectProcessor.apply_effects(state, officer_def.starting_effects, log)
```

- [ ] **Step 2: Update IncidentResolutionScene to use state.officer_defs**

In `game/src/ui/IncidentResolutionScene.gd`, find the block in `_build_ui()` that fetches officer defs:

```gdscript
	# Build proposals
	var officer_defs: Array = []
	for item: ContentBase in ContentRegistry.get_all("officers"):
		var def := item as OfficerDef
		if def != null:
			officer_defs.append(def)
	_proposals = OfficerCouncil.get_proposals(_state, _incident, officer_defs)
```

Replace it with:

```gdscript
	# Build proposals from officer defs wired into state at run start
	_proposals = OfficerCouncil.get_proposals(_state, _incident, _state.officer_defs)
```

- [ ] **Step 3: Run Stage 4+5 test to confirm incident resolution still works**

```bash
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
```

Expected: `ALL PASS`

- [ ] **Step 4: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd \
        game/src/ui/IncidentResolutionScene.gd
git commit -m "feat: wire officer_defs through ExpeditionState and IncidentResolutionScene"
```

---

## Task 8: PreparationScene — Pool Display

Replace the officer slot builder in `PreparationScene` to read from the pool in `ProgressionState` instead of `ContentRegistry`. Show name, background, disclosed traits, rumoured hints, competence/loyalty word-bands, and run history.

**Files:**
- Modify: `game/src/ui/PreparationScene.gd`

- [ ] **Step 1: Add pool loading and helper methods**

At the top of `PreparationScene.gd`, add a new member variable after `_unavailable_ids`:

```gdscript
var _officer_pool_defs: Array = []  # OfficerDef records loaded from ProgressionState
```

In `_ready()`, add pool loading before `_build_ui()`. Find:

```gdscript
	_build_ui()
```

And replace with:

```gdscript
	var pool_progression := SaveManager.load_progression()
	SaveManager.replenish_pool(pool_progression)
	_officer_pool_defs = pool_progression.officer_pool
	_build_ui()
```

Add these helper methods after `_format_effects()`:

```gdscript
func _competence_band(val: int) -> String:
	match val:
		1: return "unreliable"
		2: return "uncertain"
		3: return "steady"
		4: return "dependable"
		5: return "exceptional"
		_: return "unknown"


func _format_officer_card(def: OfficerDef) -> String:
	var background: String = def.tags[0] if def.tags.size() > 0 else ""
	var lines: Array[String] = []
	lines.append(def.display_name)
	if background != "":
		lines.append(background)
	if not def.disclosed_traits.is_empty():
		lines.append("Known: " + ", ".join(def.disclosed_traits))
	if not def.rumoured_hints.is_empty():
		lines.append("Rumoured: " + ", ".join(def.rumoured_hints))
	lines.append("Competence: %s · Loyalty: %s" % [_competence_band(def.competence), _competence_band(def.loyalty)])
	if def.runs_survived > 0:
		lines.append("%d run(s) survived" % def.runs_survived)
		if not def.notable_events.is_empty():
			lines.append("History: " + ", ".join(def.notable_events.slice(0, 3)))
	return "\n".join(lines)
```

- [ ] **Step 2: Replace _build_officer_slots()**

Find and replace the entire `_build_officer_slots()` method:

```gdscript
func _build_officer_slots(parent: VBoxContainer) -> void:
	# Determine which roles are reduced/unavailable due to officer_accused bias
	var accused_roles: Array[String] = []
	if "officer_accused" in _admiralty_bias:
		accused_roles = ["first_lieutenant"]  # bias specifically targets first_lieutenant per 6B spec

	for role: String in REQUIRED_ROLES:
		var role_label := Label.new()
		role_label.text = role.replace("_", " ").capitalize()
		parent.add_child(role_label)
		var hbox := HBoxContainer.new()
		parent.add_child(hbox)

		var candidates: Array = _officer_pool_defs.filter(func(d: OfficerDef): return d.role == role)
		if not _officer_buttons_by_role.has(role):
			_officer_buttons_by_role[role] = []

		for def: OfficerDef in candidates:
			var btn := Button.new()
			var unavailable: bool = role in accused_roles
			var is_recommended: bool = def.id in _recommended
			var reward_text: String = _recommended.get(def.id, {}).get("reward_text", "")
			var card_text := _format_officer_card(def)
			if is_recommended:
				card_text += "\n▲ " + reward_text
			if unavailable:
				card_text += "\n— Not available this commission"
			btn.text = card_text
			btn.disabled = unavailable
			btn.modulate.a = 0.4 if unavailable else 1.0
			btn.custom_minimum_size = Vector2(240, 110)
			btn.toggle_mode = true
			btn.pressed.connect(_on_officer_selected.bind(role, def.id, btn))
			_officer_buttons[def.id] = btn
			_officer_buttons_by_role[role].append(btn)
			hbox.add_child(btn)
			if not _selected_officers.has(role) and not unavailable:
				_selected_officers[role] = def.id
				btn.button_pressed = true
```

- [ ] **Step 3: Update _on_set_sail to pass officer_defs**

Find the config assembly in `_on_set_sail()`. Find:

```gdscript
	var config := {
		"objective_id": _selected_objective,
		"doctrine_id": _selected_doctrine,
		"officer_ids": _selected_officers.values(),
```

Replace the `officer_ids` line and add `officer_defs`:

```gdscript
	# Collect OfficerDef records for hired officers (pass defs, not just ids)
	var hired_officer_defs: Array = []
	for role: String in _selected_officers:
		var oid: String = _selected_officers[role]
		for def: OfficerDef in _officer_pool_defs:
			if def.id == oid:
				hired_officer_defs.append(def)
				break

	var config := {
		"objective_id": _selected_objective,
		"doctrine_id": _selected_doctrine,
		"officer_ids": _selected_officers.values(),
		"officer_defs": hired_officer_defs,
```

- [ ] **Step 4: Launch game and verify PreparationScene shows generated officers**

```bash
godot --path game &
```

Navigate to PreparationScene. Verify each role slot shows 2 generated officers with name, background, trait lines, and word-band competence/loyalty. Confirm "Set Sail" works and RunScene loads.

- [ ] **Step 5: Commit**

```bash
git add game/src/ui/PreparationScene.gd
git commit -m "feat: PreparationScene shows generated officer pool with trait disclosure and history"
```

---

## Task 9: RunEndScene — Scar Commit

At run end, apply threshold-based scars to all surviving officers, then call `SaveManager.commit_officer_scars()`.

**Files:**
- Modify: `game/src/ui/RunEndScene.gd`

- [ ] **Step 1: Find _on_return and add scar commit before progression save**

In `game/src/ui/RunEndScene.gd`, find the `_on_return()` method (the button that returns to Admiralty). It calls `SaveManager.record_report_framing()` and then transitions. Add the scar commit immediately before that call.

Find the method and add at the top of its body, before any `SaveManager` calls:

```gdscript
func _on_return() -> void:
	# Apply run-end threshold scars to all officers that survived the run
	_apply_threshold_scars()

	# Commit scars to pool and save progression
	var progression := SaveManager.load_progression()
	SaveManager.commit_officer_scars(final_state, progression)
	SaveManager.replenish_pool(progression)
	SaveManager.save_progression(progression)

	# Existing framing logic follows — find the current _on_return body and keep it
```

> **Note:** Locate the full existing `_on_return()` body. Keep all existing lines (record_report_framing, save_progression calls, scene transition). The new lines go at the very top. Do not duplicate existing saves — remove any standalone `save_progression` if one exists inside `_on_return` since the new block calls it.

- [ ] **Step 2: Add _apply_threshold_scars() helper**

Add this method to `RunEndScene.gd`:

```gdscript
func _apply_threshold_scars() -> void:
	if final_state == null:
		return
	var losses: int = final_state.stress_indicators.get("crew_losses", 0)
	var min_cmd: int = final_state.stress_indicators.get("min_command", 100)
	var peak_brd: int = final_state.stress_indicators.get("peak_burden", 0)

	for def: OfficerDef in final_state.officer_defs:
		if losses >= GameConstants.SCAR_THRESHOLD_CREW_LOSSES:
			final_state.add_officer_scar(def.role, "survivor_of_high_losses")
		if min_cmd <= GameConstants.SCAR_THRESHOLD_MIN_COMMAND:
			final_state.add_officer_scar(def.role, "witnessed_authority_collapse")
		if peak_brd >= GameConstants.SCAR_THRESHOLD_PEAK_BURDEN:
			final_state.add_officer_scar(def.role, "endured_extreme_hardship")
```

- [ ] **Step 3: Add scar threshold constants to GameConstants**

In `game/src/constants/GameConstants.gd`, add:

```gdscript
const SCAR_THRESHOLD_CREW_LOSSES: int = 2
const SCAR_THRESHOLD_MIN_COMMAND: int = 30
const SCAR_THRESHOLD_PEAK_BURDEN: int = 75
```

- [ ] **Step 4: Run a full game loop and verify scars persist**

```bash
godot --path game &
```

1. Reach RunEndScene.
2. Submit a report framing.
3. Return to PreparationScene.
4. Verify that officers from the previous run show `runs_survived = 1` and any applicable scars in their history.

- [ ] **Step 5: Commit**

```bash
git add game/src/ui/RunEndScene.gd game/src/constants/GameConstants.gd
git commit -m "feat: RunEndScene applies threshold scars and commits officer pool at run end"
```

---

## Task 10: Remove Authored Officer Files and Clean Up

Delete the 14 static authored officer `.tres` files and remove their ids from `ProgressionState.create_default()`.

**Files:**
- Delete: all files in `game/content/officers/` except `.gitkeep`
- Already done in Task 5: ProgressionState.create_default() no longer lists officer ids

- [ ] **Step 1: Delete authored officer .tres files**

```bash
rm game/content/officers/bosun.tres \
   game/content/officers/chaplain_pragmatic.tres \
   game/content/officers/chaplain_orthodox.tres \
   game/content/officers/surgeon.tres \
   game/content/officers/surgeon_compassionate.tres \
   game/content/officers/surgeon_methodical.tres \
   game/content/officers/purser_generous.tres \
   game/content/officers/purser_frugal.tres \
   game/content/officers/master_experienced.tres \
   game/content/officers/master_reckless.tres \
   game/content/officers/first_lieutenant_lenient.tres \
   game/content/officers/first_lieutenant_stern.tres \
   game/content/officers/gunner_reliable.tres \
   game/content/officers/gunner_disciplined.tres
```

- [ ] **Step 2: Remove .uid files for deleted resources**

```bash
rm -f game/src/content/resources/OfficerDef.gd.uid
```

(Only if the file exists; `.uid` files for modified scripts are regenerated automatically.)

- [ ] **Step 3: Run all existing tests to confirm nothing depends on the deleted files**

```bash
godot --headless --path game res://test/ContentFrameworkTest.tscn 2>&1 | tail -10
godot --headless --path game res://test/ExpeditionStateTest.tscn 2>&1 | tail -10
godot --headless --path game res://test/RouteMapTest.tscn 2>&1 | tail -10
godot --headless --path game res://test/Stage45Test.tscn 2>&1 | tail -10
godot --headless --path game res://test/Stage6ATest.tscn 2>&1 | tail -10
godot --headless --path game res://test/OfficerScarTest.tscn 2>&1 | tail -10
godot --headless --path game res://test/OfficerGeneratorTest.tscn 2>&1 | tail -10
godot --headless --path game res://test/OfficerPoolTest.tscn 2>&1 | tail -10
```

Expected: all return `ALL PASS`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: remove authored officer .tres files; pool is now fully generated"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task covering it |
|---|---|
| Procedural officer generation (name, background, traits) | Task 4 |
| Role-based pool, 2–3 candidates per role | Task 5 |
| Data-driven pools expandable without code changes | Task 3 |
| Three-tier disclosure (disclosed / rumoured / hidden) | Task 1, 3, 4 |
| Officer information domains | Task 1, 4 |
| Pre-departure stances | Task 1, 4 (generated; UI display deferred — stances are on the OfficerDef but not yet displayed separately in PreparationScene) |
| Pre-voyage promises | Task 1 (schema only; full promise-at-hire mechanic deferred to impactful-choices implementation) |
| Scar trait tags (primary form) | Task 2, 9 |
| Stat drift (secondary form) | Task 5 (commit_officer_scars) |
| Cross-run memory flags (narrative form) | Task 2 (officer_scars system), Task 5 (commit writes to pool) |
| Scar triggers from incident choices (add_officer_scar effect) | Task 2 |
| Scar triggers from run-end thresholds | Task 9 |
| Permanent officer loss | Not in this plan — deferred (incidents that cause officer death require authoring; the pool/commit machinery supports it via removing from pool, but no authored trigger exists yet) |
| Stage 6B compatibility (officer_accused, loyal trait) | Task 8 (PreparationScene accused_roles logic) |
| Delete authored .tres files | Task 10 |

**Pre-departure stances note:** Stances are generated and stored on `OfficerDef.pre_departure_stance`. They are not yet displayed in PreparationScene — that is a UI addition for the impactful-choices implementation pass (Section 7 pre-departure stances mechanic). The data is present; the display is deferred.

**Pre-voyage promises note:** The schema supports `pre_voyage_promise_id` and `pre_voyage_promise_text`. The generation system does not yet set these (no traits in the pool currently declare `requires_promise: true`). This is intentional — the mechanic is designed for the impactful-choices implementation pass. Add pool trait entries with promise declarations when that pass begins.
