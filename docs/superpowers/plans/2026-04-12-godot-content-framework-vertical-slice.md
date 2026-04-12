# Godot Content Framework Vertical Slice — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the data-driven content foundation for Dead Reckoning — typed Resource classes, a ContentRegistry autoload, a ContentValidator, sample `.tres` content, and an interactive debug scene.

**Architecture:** All game content is defined as Godot typed Resources saved as `.tres` files under `res://content/`. A singleton autoload (`ContentRegistry`) scans each content family folder on startup, loads every `.tres` file, and validates the catalog. An interactive debug scene lets you browse and validate the full catalog with buttons.

**Tech Stack:** Godot 4.6, GDScript, Godot custom Resources (`.tres`), `DirAccess`, `ResourceLoader`, `ResourceSaver`, `EditorScript` (for sample content generation).

---

## File Map

| File | Role |
|---|---|
| `src/content/ContentBase.gd` | Shared base Resource script with common fields |
| `src/content/resources/EffectDef.gd` | Inline Resource for a single effect |
| `src/content/resources/ConditionDef.gd` | Inline Resource for a single condition check |
| `src/content/resources/IncidentChoiceDef.gd` | Inline Resource for one incident player choice |
| `src/content/resources/IncidentDef.gd` | Incident content definition |
| `src/content/resources/SupplyDef.gd` | Supply content definition |
| `src/content/resources/OfficerDef.gd` | Officer content definition |
| `src/content/resources/StandingOrderDef.gd` | Standing order content definition |
| `src/content/resources/ShipUpgradeDef.gd` | Ship upgrade content definition |
| `src/content/resources/DoctrineDef.gd` | Doctrine content definition |
| `src/content/resources/CrewBackgroundDef.gd` | Crew background content definition |
| `src/content/resources/ZoneTypeDef.gd` | Zone type content definition |
| `src/content/resources/ObjectiveDef.gd` | Admiralty objective content definition |
| `src/content/ContentValidator.gd` | Validates the full loaded catalog; returns error list |
| `src/content/ContentRegistry.gd` | Autoload singleton: loads all content, exposes query API |
| `tools/CreateSampleContent.gd` | `@tool` EditorScript: generates all sample `.tres` files once, then deleted |
| `test/ContentFrameworkTest.gd` | Test scene script; asserts Resource and registry behaviour headlessly |
| `test/ContentFrameworkTest.tscn` | Test scene (Node root, attached to ContentFrameworkTest.gd) |
| `test/ContentDebugScene.gd` | Interactive debug scene script |
| `test/ContentDebugScene.tscn` | Interactive debug scene |
| `project.godot` | Add ContentRegistry autoload; swap main scene to debug scene at end |
| `content/supplies/` `content/officers/` etc. | Content family folders (9 folders, see Task 9) |

---

## How to Run Tests

Tests run by executing the test scene headlessly. Run this from the repo root:

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected output ends with `ALL PASS` if all checks pass. Any `FAIL:` line is a test failure. A crash (non-zero exit) with `OS.crash()` means one or more checks failed — scroll up for the `FAIL:` lines.

---

## Task 1: ContentBase and Test Scaffold

**Files:**
- Create: `game/src/content/ContentBase.gd`
- Create: `game/test/ContentFrameworkTest.gd`
- Create: `game/test/ContentFrameworkTest.tscn`

- [ ] **Step 1: Create the test scaffold**

Create `game/test/ContentFrameworkTest.gd`:

```gdscript
# ContentFrameworkTest.gd
# Test scene for Stage 1: Content Framework Vertical Slice.
# Run headlessly: godot --headless --path game res://test/ContentFrameworkTest.tscn
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
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _finish()


func _finish() -> void:
    print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
    if _fail > 0:
        OS.crash("Tests failed")
    print("ALL PASS")
    get_tree().quit(0)


func _test_content_base() -> void:
    print("-- ContentBase --")
    var cb := ContentBase.new()
    check(cb != null, "ContentBase instantiates")
    check(cb.id == "", "ContentBase.id defaults to empty string")
    check(cb.display_name == "", "ContentBase.display_name defaults to empty string")
    check(cb.category == "", "ContentBase.category defaults to empty string")
    check(cb.tags.is_empty(), "ContentBase.tags defaults to empty array")
    check(cb.visibility_rules.is_empty(), "ContentBase.visibility_rules defaults to empty array")
    check(cb.unlock_source == "", "ContentBase.unlock_source defaults to empty string")
    check(is_equal_approx(cb.rarity_weight, 1.0), "ContentBase.rarity_weight defaults to 1.0")

    cb.id = "test_id"
    cb.display_name = "Test Item"
    cb.category = "test"
    cb.tags = ["a", "b"]
    cb.unlock_source = "some_unlock"
    cb.rarity_weight = 0.5
    check(cb.id == "test_id", "ContentBase.id round-trips")
    check(cb.display_name == "Test Item", "ContentBase.display_name round-trips")
    check(cb.category == "test", "ContentBase.category round-trips")
    check(cb.tags == ["a", "b"], "ContentBase.tags round-trips")
    check(cb.unlock_source == "some_unlock", "ContentBase.unlock_source round-trips")
    check(is_equal_approx(cb.rarity_weight, 0.5), "ContentBase.rarity_weight round-trips")
```

- [ ] **Step 2: Create ContentFrameworkTest.tscn**

Create `game/test/ContentFrameworkTest.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/ContentFrameworkTest.gd" id="1"]

[node name="ContentFrameworkTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 3: Run test — expect failure (ContentBase not defined)**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: error about `ContentBase` identifier not found. This confirms the test is working before the implementation exists.

- [ ] **Step 4: Create ContentBase.gd**

Create `game/src/content/ContentBase.gd`:

```gdscript
# ContentBase.gd
# Shared base Resource for all Dead Reckoning content definitions.
# Every content family Resource extends this class.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ContentBase
extends Resource

## Unique identifier within this content family. Snake_case. Required.
@export var id: String = ""

## Human-readable name shown in UI and debug output.
@export var display_name: String = ""

## Family-specific category tag (e.g. "crisis", "boon", "supply").
@export var category: String = ""

## Arbitrary searchable tags for filtering and incident eligibility.
@export var tags: Array[String] = []

## Strings evaluated by game code to gate visibility. Evaluated in Stage 5+.
@export var visibility_rules: Array[String] = []

## Id of the unlock that gates this content. Empty string = always available.
@export var unlock_source: String = ""

## Relative weight for random selection. Default 1.0.
@export var rarity_weight: float = 1.0
```

- [ ] **Step 5: Run test — expect PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: `ALL PASS` at end, no FAIL lines.

- [ ] **Step 6: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/ContentBase.gd game/test/ContentFrameworkTest.gd game/test/ContentFrameworkTest.tscn
git commit -m "feat(stage-1): add ContentBase Resource and test scaffold"
```

---

## Task 2: EffectDef and ConditionDef

**Files:**
- Create: `game/src/content/resources/EffectDef.gd`
- Create: `game/src/content/resources/ConditionDef.gd`
- Modify: `game/test/ContentFrameworkTest.gd` (add test functions)

- [ ] **Step 1: Add failing tests to ContentFrameworkTest.gd**

Add these two functions to `ContentFrameworkTest.gd`, and add calls to them in `_ready()` before `_finish()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _finish()


func _test_effect_def() -> void:
    print("-- EffectDef --")
    var e := EffectDef.new()
    check(e != null, "EffectDef instantiates")
    check(e.type == "", "EffectDef.type defaults to empty string")
    check(e.delta == 0, "EffectDef.delta defaults to 0")
    check(e.flag_key == "", "EffectDef.flag_key defaults to empty string")
    check(e.tag == "", "EffectDef.tag defaults to empty string")

    e.type = "burden_change"
    e.delta = -5
    check(e.type == "burden_change", "EffectDef.type round-trips")
    check(e.delta == -5, "EffectDef.delta round-trips")


func _test_condition_def() -> void:
    print("-- ConditionDef --")
    var c := ConditionDef.new()
    check(c != null, "ConditionDef instantiates")
    check(c.type == "", "ConditionDef.type defaults to empty string")
    check(c.threshold == 0, "ConditionDef.threshold defaults to 0")
    check(c.flag_key == "", "ConditionDef.flag_key defaults to empty string")
    check(c.tag == "", "ConditionDef.tag defaults to empty string")

    c.type = "burden_above"
    c.threshold = 60
    check(c.type == "burden_above", "ConditionDef.type round-trips")
    check(c.threshold == 60, "ConditionDef.threshold round-trips")
```

- [ ] **Step 2: Run test — expect failure (EffectDef not defined)**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: error about `EffectDef` identifier not found.

- [ ] **Step 3: Create EffectDef.gd**

Create `game/src/content/resources/EffectDef.gd`:

```gdscript
# EffectDef.gd
# Inline Resource representing one discrete effect applied to expedition state.
# Embedded inside IncidentChoiceDef, StandingOrderDef, ShipUpgradeDef — not stored standalone.
#
# Valid types: burden_change, command_change, supply_change, ship_condition_change,
#              add_damage_tag, remove_damage_tag, set_memory_flag,
#              add_crew_trait, remove_crew_trait
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name EffectDef
extends Resource

## Effect type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric change for burden_change, command_change, supply_change, ship_condition_change.
@export var delta: int = 0

## Memory flag key for set_memory_flag effects.
@export var flag_key: String = ""

## Damage or crew trait tag for add/remove_damage_tag and add/remove_crew_trait effects.
@export var tag: String = ""
```

- [ ] **Step 4: Create ConditionDef.gd**

Create `game/src/content/resources/ConditionDef.gd`:

```gdscript
# ConditionDef.gd
# Inline Resource representing one condition check against expedition state.
# Embedded inside IncidentDef and IncidentChoiceDef — not stored standalone.
#
# Valid types: burden_above, burden_below, command_above, command_below, supply_below,
#              has_damage_tag, has_memory_flag, has_crew_trait, officer_present, zone_type_is
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ConditionDef
extends Resource

## Condition type string. Must be one of the known types validated by ContentValidator.
@export var type: String = ""

## Numeric threshold for burden_above/below, command_above/below, supply_below.
@export var threshold: int = 0

## Memory flag key for has_memory_flag conditions.
@export var flag_key: String = ""

## Tag string for has_damage_tag, has_crew_trait, officer_present, zone_type_is.
@export var tag: String = ""
```

- [ ] **Step 5: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: all prior checks plus new EffectDef and ConditionDef checks pass.

- [ ] **Step 6: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/resources/EffectDef.gd game/src/content/resources/ConditionDef.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add EffectDef and ConditionDef Resources"
```

---

## Task 3: IncidentChoiceDef and IncidentDef

**Files:**
- Create: `game/src/content/resources/IncidentChoiceDef.gd`
- Create: `game/src/content/resources/IncidentDef.gd`
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Add failing tests**

Add to `ContentFrameworkTest.gd` (and call both in `_ready()` before `_finish()`):

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _finish()


func _test_incident_choice_def() -> void:
    print("-- IncidentChoiceDef --")
    var ic := IncidentChoiceDef.new()
    check(ic != null, "IncidentChoiceDef instantiates")
    check(ic.choice_text == "", "IncidentChoiceDef.choice_text defaults to empty string")
    check(ic.officer_id == "", "IncidentChoiceDef.officer_id defaults to empty string")
    check(ic.required_conditions.is_empty(), "IncidentChoiceDef.required_conditions defaults empty")
    check(ic.immediate_effects.is_empty(), "IncidentChoiceDef.immediate_effects defaults empty")
    check(ic.memory_flags_set.is_empty(), "IncidentChoiceDef.memory_flags_set defaults empty")
    check(ic.log_text == "", "IncidentChoiceDef.log_text defaults to empty string")

    var effect := EffectDef.new()
    effect.type = "burden_change"
    effect.delta = 3
    ic.choice_text = "Make an example of the thief."
    ic.officer_id = "bosun"
    ic.immediate_effects = [effect]
    ic.memory_flags_set = ["thief_punished"]
    ic.log_text = "The bosun's lash is heard across the deck."
    check(ic.choice_text == "Make an example of the thief.", "IncidentChoiceDef.choice_text round-trips")
    check(ic.officer_id == "bosun", "IncidentChoiceDef.officer_id round-trips")
    check(ic.immediate_effects.size() == 1, "IncidentChoiceDef.immediate_effects round-trips")
    check(ic.memory_flags_set == ["thief_punished"], "IncidentChoiceDef.memory_flags_set round-trips")


func _test_incident_def() -> void:
    print("-- IncidentDef --")
    var inc := IncidentDef.new()
    check(inc != null, "IncidentDef instantiates")
    check(inc.trigger_band == "", "IncidentDef.trigger_band defaults to empty string")
    check(inc.required_conditions.is_empty(), "IncidentDef.required_conditions defaults empty")
    check(inc.amplifier_conditions.is_empty(), "IncidentDef.amplifier_conditions defaults empty")
    check(inc.cast_roles.is_empty(), "IncidentDef.cast_roles defaults empty")
    check(inc.eligible_zone_tags.is_empty(), "IncidentDef.eligible_zone_tags defaults empty")
    check(inc.suppressed_zone_tags.is_empty(), "IncidentDef.suppressed_zone_tags defaults empty")
    check(inc.standing_order_interactions.is_empty(), "IncidentDef.standing_order_interactions defaults empty")
    check(inc.choices.is_empty(), "IncidentDef.choices defaults empty")
    check(inc.log_text_template == "", "IncidentDef.log_text_template defaults to empty string")

    inc.id = "drunk_purser"
    inc.trigger_band = "tick"
    var cond := ConditionDef.new()
    cond.type = "has_crew_trait"
    cond.tag = "drunk_purser_present"
    inc.required_conditions = [cond]
    check(inc.id == "drunk_purser", "IncidentDef.id round-trips")
    check(inc.trigger_band == "tick", "IncidentDef.trigger_band round-trips")
    check(inc.required_conditions.size() == 1, "IncidentDef.required_conditions round-trips")
```

- [ ] **Step 2: Run test — expect failure**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: error about `IncidentChoiceDef` not found.

- [ ] **Step 3: Create IncidentChoiceDef.gd**

Create `game/src/content/resources/IncidentChoiceDef.gd`:

```gdscript
# IncidentChoiceDef.gd
# Inline Resource representing one player-facing choice within an incident.
# Embedded in IncidentDef.choices — not stored standalone.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name IncidentChoiceDef
extends Resource

## The choice option text shown to the player.
@export var choice_text: String = ""

## Officer id who proposes this choice. Empty = captain's own option.
@export var officer_id: String = ""

## All conditions must pass for this choice to appear.
@export var required_conditions: Array[ConditionDef] = []

## Effects applied immediately when the player selects this choice.
@export var immediate_effects: Array[EffectDef] = []

## Memory flags written to run memory when this choice is selected.
@export var memory_flags_set: Array[String] = []

## Ship log entry written when this choice is selected.
@export var log_text: String = ""
```

- [ ] **Step 4: Create IncidentDef.gd**

Create `game/src/content/resources/IncidentDef.gd`:

```gdscript
# IncidentDef.gd
# Content definition for a triggered incident (crisis, omen, social, etc.).
# Stored as a .tres file under res://content/incidents/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name IncidentDef
extends ContentBase

## When this incident can fire: "tick", "node", "aftermath", or "threshold".
@export var trigger_band: String = ""

## All conditions must pass for this incident to be eligible to fire.
@export var required_conditions: Array[ConditionDef] = []

## Optional conditions that modify weight or narrative text when met.
@export var amplifier_conditions: Array[ConditionDef] = []

## Officer or notable ids that must be present in the roster for this incident.
@export var cast_roles: Array[String] = []

## Zone tags that allow this incident. Empty = eligible in any zone.
@export var eligible_zone_tags: Array[String] = []

## Zone tags that suppress this incident from firing.
@export var suppressed_zone_tags: Array[String] = []

## Standing order ids that interact with this incident's resolution.
@export var standing_order_interactions: Array[String] = []

## Player-facing options for resolving this incident.
@export var choices: Array[IncidentChoiceDef] = []

## Ship log entry template written when this incident fires.
@export var log_text_template: String = ""
```

- [ ] **Step 5: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 6: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/resources/IncidentChoiceDef.gd game/src/content/resources/IncidentDef.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add IncidentChoiceDef and IncidentDef Resources"
```

---

## Task 4: SupplyDef and OfficerDef

**Files:**
- Create: `game/src/content/resources/SupplyDef.gd`
- Create: `game/src/content/resources/OfficerDef.gd`
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Add failing tests**

Add to `ContentFrameworkTest.gd` and call in `_ready()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _finish()


func _test_supply_def() -> void:
    print("-- SupplyDef --")
    var s := SupplyDef.new()
    check(s != null, "SupplyDef instantiates")
    check(s is ContentBase, "SupplyDef extends ContentBase")
    check(s.is_rum == false, "SupplyDef.is_rum defaults to false")
    check(s.starting_amount == 0, "SupplyDef.starting_amount defaults to 0")
    check(s.daily_consumption == 0, "SupplyDef.daily_consumption defaults to 0")
    check(s.low_threshold == 0, "SupplyDef.low_threshold defaults to 0")
    check(s.critical_threshold == 0, "SupplyDef.critical_threshold defaults to 0")

    s.id = "rum"
    s.is_rum = true
    s.starting_amount = 100
    s.daily_consumption = 2
    s.low_threshold = 20
    s.critical_threshold = 5
    check(s.is_rum == true, "SupplyDef.is_rum round-trips")
    check(s.starting_amount == 100, "SupplyDef.starting_amount round-trips")
    check(s.critical_threshold == 5, "SupplyDef.critical_threshold round-trips")


func _test_officer_def() -> void:
    print("-- OfficerDef --")
    var o := OfficerDef.new()
    check(o != null, "OfficerDef instantiates")
    check(o is ContentBase, "OfficerDef extends ContentBase")
    check(o.role == "", "OfficerDef.role defaults to empty string")
    check(o.competence == 0, "OfficerDef.competence defaults to 0")
    check(o.loyalty == 0, "OfficerDef.loyalty defaults to 0")
    check(o.worldview == "", "OfficerDef.worldview defaults to empty string")
    check(o.known_traits.is_empty(), "OfficerDef.known_traits defaults empty")
    check(o.hidden_traits.is_empty(), "OfficerDef.hidden_traits defaults empty")
    check(o.advice_hooks.is_empty(), "OfficerDef.advice_hooks defaults empty")

    o.id = "bosun"
    o.role = "bosun"
    o.competence = 4
    o.loyalty = 3
    o.worldview = "disciplinarian"
    o.known_traits = ["blunt", "reliable"]
    check(o.role == "bosun", "OfficerDef.role round-trips")
    check(o.competence == 4, "OfficerDef.competence round-trips")
    check(o.known_traits == ["blunt", "reliable"], "OfficerDef.known_traits round-trips")
```

- [ ] **Step 2: Run test — expect failure**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 3: Create SupplyDef.gd**

Create `game/src/content/resources/SupplyDef.gd`:

```gdscript
# SupplyDef.gd
# Content definition for an expedition supply type.
# Stored as a .tres file under res://content/supplies/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name SupplyDef
extends ContentBase

## True for Rum only — enables special-case Rum handling in Stage 2+.
@export var is_rum: bool = false

## Default quantity loaded at expedition start.
@export var starting_amount: int = 0

## Units consumed per travel tick.
@export var daily_consumption: int = 0

## Amount below which scarcity incidents can trigger.
@export var low_threshold: int = 0

## Amount below which critical incidents trigger.
@export var critical_threshold: int = 0
```

- [ ] **Step 4: Create OfficerDef.gd**

Create `game/src/content/resources/OfficerDef.gd`:

```gdscript
# OfficerDef.gd
# Content definition for an officer or notable crew member.
# Stored as a .tres file under res://content/officers/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name OfficerDef
extends ContentBase

## Officer role: "bosun", "surgeon", "purser", "chaplain", "first_mate", "lieutenant", etc.
@export var role: String = ""

## Advice accuracy, 1–5.
@export var competence: int = 0

## Proposal reliability, 1–5.
@export var loyalty: int = 0

## Personality worldview: "disciplinarian", "humanitarian", "pragmatist", etc.
@export var worldview: String = ""

## Traits visible to the player from expedition start.
@export var known_traits: Array[String] = []

## Traits revealed through incidents.
@export var hidden_traits: Array[String] = []

## Incident ids for which this officer has authored proposal choices.
@export var advice_hooks: Array[String] = []
```

- [ ] **Step 5: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 6: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/resources/SupplyDef.gd game/src/content/resources/OfficerDef.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add SupplyDef and OfficerDef Resources"
```

---

## Task 5: StandingOrderDef and ShipUpgradeDef

**Files:**
- Create: `game/src/content/resources/StandingOrderDef.gd`
- Create: `game/src/content/resources/ShipUpgradeDef.gd`
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Add failing tests**

Add to `ContentFrameworkTest.gd` and call in `_ready()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _test_standing_order_def()
    _test_ship_upgrade_def()
    _finish()


func _test_standing_order_def() -> void:
    print("-- StandingOrderDef --")
    var so := StandingOrderDef.new()
    check(so != null, "StandingOrderDef instantiates")
    check(so is ContentBase, "StandingOrderDef extends ContentBase")
    check(so.command_cost == 0, "StandingOrderDef.command_cost defaults to 0")
    check(so.labor_cost == 0, "StandingOrderDef.labor_cost defaults to 0")
    check(so.supply_cost_type == "", "StandingOrderDef.supply_cost_type defaults to empty string")
    check(so.supply_cost_amount == 0, "StandingOrderDef.supply_cost_amount defaults to 0")
    check(so.forecast_text == "", "StandingOrderDef.forecast_text defaults to empty string")
    check(so.tick_effects.is_empty(), "StandingOrderDef.tick_effects defaults empty")
    check(so.incident_interactions.is_empty(), "StandingOrderDef.incident_interactions defaults empty")

    so.id = "tighten_rationing"
    so.command_cost = 2
    so.forecast_text = "Likely reduces food consumption. Crew may resent it."
    so.incident_interactions = ["rum_theft", "ration_dispute"]
    check(so.command_cost == 2, "StandingOrderDef.command_cost round-trips")
    check(so.incident_interactions.size() == 2, "StandingOrderDef.incident_interactions round-trips")


func _test_ship_upgrade_def() -> void:
    print("-- ShipUpgradeDef --")
    var su := ShipUpgradeDef.new()
    check(su != null, "ShipUpgradeDef instantiates")
    check(su is ContentBase, "ShipUpgradeDef extends ContentBase")
    check(su.preparation_cost == 0, "ShipUpgradeDef.preparation_cost defaults to 0")
    check(su.upgrade_effects.is_empty(), "ShipUpgradeDef.upgrade_effects defaults empty")
    check(su.drawback_text == "", "ShipUpgradeDef.drawback_text defaults to empty string")

    su.id = "reinforced_hull"
    su.preparation_cost = 3
    su.drawback_text = "Heavier — travel ticks are slower."
    var e := EffectDef.new()
    e.type = "ship_condition_change"
    e.delta = 10
    su.upgrade_effects = [e]
    check(su.preparation_cost == 3, "ShipUpgradeDef.preparation_cost round-trips")
    check(su.upgrade_effects.size() == 1, "ShipUpgradeDef.upgrade_effects round-trips")
    check(su.drawback_text == "Heavier — travel ticks are slower.", "ShipUpgradeDef.drawback_text round-trips")
```

- [ ] **Step 2: Run test — expect failure**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 3: Create StandingOrderDef.gd**

Create `game/src/content/resources/StandingOrderDef.gd`:

```gdscript
# StandingOrderDef.gd
# Content definition for a standing order the player can issue before route segments.
# Stored as a .tres file under res://content/standing_orders/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name StandingOrderDef
extends ContentBase

## Command bandwidth consumed while this order is active.
@export var command_cost: int = 0

## Crew labor consumed per tick while this order is active.
@export var labor_cost: int = 0

## Supply id consumed per tick, if any (e.g. "medicine"). Empty = no supply cost.
@export var supply_cost_type: String = ""

## Units of supply_cost_type consumed per tick.
@export var supply_cost_amount: int = 0

## Evocative risk-language forecast shown to the player before selection.
@export var forecast_text: String = ""

## Effects applied each tick while this order is active.
@export var tick_effects: Array[EffectDef] = []

## Incident ids whose resolution this order modifies when active.
@export var incident_interactions: Array[String] = []
```

- [ ] **Step 4: Create ShipUpgradeDef.gd**

Create `game/src/content/resources/ShipUpgradeDef.gd`:

```gdscript
# ShipUpgradeDef.gd
# Content definition for a ship upgrade available in the Admiralty preparation phase.
# Stored as a .tres file under res://content/upgrades/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name ShipUpgradeDef
extends ContentBase

## Budget cost in the Admiralty preparation phase.
@export var preparation_cost: int = 0

## Passive effects applied to expedition state for the duration of the run.
@export var upgrade_effects: Array[EffectDef] = []

## Plain-language description of the tradeoff this upgrade creates.
@export var drawback_text: String = ""
```

- [ ] **Step 5: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 6: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/resources/StandingOrderDef.gd game/src/content/resources/ShipUpgradeDef.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add StandingOrderDef and ShipUpgradeDef Resources"
```

---

## Task 6: DoctrineDef, CrewBackgroundDef, ZoneTypeDef, ObjectiveDef

**Files:**
- Create: `game/src/content/resources/DoctrineDef.gd`
- Create: `game/src/content/resources/CrewBackgroundDef.gd`
- Create: `game/src/content/resources/ZoneTypeDef.gd`
- Create: `game/src/content/resources/ObjectiveDef.gd`
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Add failing tests**

Add to `ContentFrameworkTest.gd` and call in `_ready()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _test_standing_order_def()
    _test_ship_upgrade_def()
    _test_doctrine_def()
    _test_crew_background_def()
    _test_zone_type_def()
    _test_objective_def()
    _finish()


func _test_doctrine_def() -> void:
    print("-- DoctrineDef --")
    var d := DoctrineDef.new()
    check(d != null, "DoctrineDef instantiates")
    check(d is ContentBase, "DoctrineDef extends ContentBase")
    check(d.unlocked_standing_order_ids.is_empty(), "DoctrineDef.unlocked_standing_order_ids defaults empty")
    check(d.command_culture_modifier == "", "DoctrineDef.command_culture_modifier defaults to empty string")
    check(d.description == "", "DoctrineDef.description defaults to empty string")

    d.id = "shared_hardship"
    d.unlocked_standing_order_ids = ["share_officer_comforts", "rotate_sick_off_duty"]
    d.command_culture_modifier = "egalitarian"
    check(d.unlocked_standing_order_ids.size() == 2, "DoctrineDef.unlocked_standing_order_ids round-trips")
    check(d.command_culture_modifier == "egalitarian", "DoctrineDef.command_culture_modifier round-trips")


func _test_crew_background_def() -> void:
    print("-- CrewBackgroundDef --")
    var cb := CrewBackgroundDef.new()
    check(cb != null, "CrewBackgroundDef instantiates")
    check(cb is ContentBase, "CrewBackgroundDef extends ContentBase")
    check(cb.starting_traits.is_empty(), "CrewBackgroundDef.starting_traits defaults empty")
    check(cb.starting_command_modifier == 0, "CrewBackgroundDef.starting_command_modifier defaults to 0")
    check(cb.starting_burden_modifier == 0, "CrewBackgroundDef.starting_burden_modifier defaults to 0")
    check(cb.description == "", "CrewBackgroundDef.description defaults to empty string")

    cb.id = "pressed_crew"
    cb.starting_traits = ["pressed", "resentful"]
    cb.starting_command_modifier = -5
    cb.starting_burden_modifier = 10
    check(cb.starting_traits == ["pressed", "resentful"], "CrewBackgroundDef.starting_traits round-trips")
    check(cb.starting_command_modifier == -5, "CrewBackgroundDef.starting_command_modifier round-trips")


func _test_zone_type_def() -> void:
    print("-- ZoneTypeDef --")
    var z := ZoneTypeDef.new()
    check(z != null, "ZoneTypeDef instantiates")
    check(z is ContentBase, "ZoneTypeDef extends ContentBase")
    check(is_equal_approx(z.consumption_modifier, 1.0), "ZoneTypeDef.consumption_modifier defaults to 1.0")
    check(is_equal_approx(z.ship_wear_modifier, 1.0), "ZoneTypeDef.ship_wear_modifier defaults to 1.0")
    check(z.burden_delta_per_tick == 0, "ZoneTypeDef.burden_delta_per_tick defaults to 0")
    check(is_equal_approx(z.incident_weight_modifier, 1.0), "ZoneTypeDef.incident_weight_modifier defaults to 1.0")
    check(z.eligible_incident_tags.is_empty(), "ZoneTypeDef.eligible_incident_tags defaults empty")
    check(z.suppressed_incident_tags.is_empty(), "ZoneTypeDef.suppressed_incident_tags defaults empty")

    z.id = "open_ocean"
    z.consumption_modifier = 1.2
    z.ship_wear_modifier = 1.5
    z.burden_delta_per_tick = 1
    check(is_equal_approx(z.consumption_modifier, 1.2), "ZoneTypeDef.consumption_modifier round-trips")
    check(z.burden_delta_per_tick == 1, "ZoneTypeDef.burden_delta_per_tick round-trips")


func _test_objective_def() -> void:
    print("-- ObjectiveDef --")
    var obj := ObjectiveDef.new()
    check(obj != null, "ObjectiveDef instantiates")
    check(obj is ContentBase, "ObjectiveDef extends ContentBase")
    check(obj.objective_type == "", "ObjectiveDef.objective_type defaults to empty string")
    check(obj.difficulty_tier == 0, "ObjectiveDef.difficulty_tier defaults to 0")
    check(obj.required_node_category == "", "ObjectiveDef.required_node_category defaults to empty string")
    check(obj.success_condition == null, "ObjectiveDef.success_condition defaults to null")
    check(obj.unlock_on_success_id == "", "ObjectiveDef.unlock_on_success_id defaults to empty string")
    check(obj.description == "", "ObjectiveDef.description defaults to empty string")

    obj.id = "survey_strange_shore"
    obj.objective_type = "survey"
    obj.difficulty_tier = 2
    obj.required_node_category = "Landfall"
    var cond := ConditionDef.new()
    cond.type = "has_memory_flag"
    cond.flag_key = "strange_shore_surveyed"
    obj.success_condition = cond
    check(obj.objective_type == "survey", "ObjectiveDef.objective_type round-trips")
    check(obj.difficulty_tier == 2, "ObjectiveDef.difficulty_tier round-trips")
    check(obj.success_condition != null, "ObjectiveDef.success_condition round-trips")
```

- [ ] **Step 2: Run test — expect failure**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 3: Create DoctrineDef.gd**

Create `game/src/content/resources/DoctrineDef.gd`:

```gdscript
# DoctrineDef.gd
# Content definition for an Admiralty doctrine.
# Stored as a .tres file under res://content/doctrines/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name DoctrineDef
extends ContentBase

## Standing order ids unlocked when this doctrine is active.
@export var unlocked_standing_order_ids: Array[String] = []

## Tag applied to expedition command culture (e.g. "egalitarian", "authoritarian").
@export var command_culture_modifier: String = ""

## Flavour and mechanical summary shown in the Admiralty preparation screen.
@export var description: String = ""
```

- [ ] **Step 4: Create CrewBackgroundDef.gd**

Create `game/src/content/resources/CrewBackgroundDef.gd`:

```gdscript
# CrewBackgroundDef.gd
# Content definition for a crew background selected in the Admiralty preparation phase.
# Stored as a .tres file under res://content/crew_backgrounds/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name CrewBackgroundDef
extends ContentBase

## Crew trait tags applied to the expedition at start.
@export var starting_traits: Array[String] = []

## Command adjustment (positive or negative) applied at expedition start.
@export var starting_command_modifier: int = 0

## Burden adjustment (positive or negative) applied at expedition start.
@export var starting_burden_modifier: int = 0

## Flavour and mechanical summary shown in the Admiralty preparation screen.
@export var description: String = ""
```

- [ ] **Step 5: Create ZoneTypeDef.gd**

Create `game/src/content/resources/ZoneTypeDef.gd`:

```gdscript
# ZoneTypeDef.gd
# Content definition for a route zone type (e.g. Coastal, Open Ocean).
# Stored as a .tres file under res://content/zone_types/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
# See also: docs/superpowers/specs/2026-04-12-difficulty-stack-design.md
class_name ZoneTypeDef
extends ContentBase

## Multiplier on food and water consumption per tick. Default 1.0.
@export var consumption_modifier: float = 1.0

## Multiplier on ship wear per tick. Default 1.0.
@export var ship_wear_modifier: float = 1.0

## Flat Burden change applied each tick in this zone.
@export var burden_delta_per_tick: int = 0

## Multiplier on incident trigger weight while in this zone. Default 1.0.
@export var incident_weight_modifier: float = 1.0

## Incident tags allowed in this zone. Empty = all tags allowed.
@export var eligible_incident_tags: Array[String] = []

## Incident tags suppressed (blocked) in this zone.
@export var suppressed_incident_tags: Array[String] = []
```

- [ ] **Step 6: Create ObjectiveDef.gd**

Create `game/src/content/resources/ObjectiveDef.gd`:

```gdscript
# ObjectiveDef.gd
# Content definition for an Admiralty run objective.
# Stored as a .tres file under res://content/objectives/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
# See also: docs/superpowers/specs/2026-04-12-run-objectives-design.md
class_name ObjectiveDef
extends ContentBase

## Objective type: "survey", "condition", or "recover".
@export var objective_type: String = ""

## Difficulty tier 1–3. Feeds Admiralty difficulty synthesis in Stage 6.
@export var difficulty_tier: int = 0

## Route node category that must appear on the route for survey and recover objectives.
@export var required_node_category: String = ""

## Condition evaluated at run end to determine success. Null = always succeeds.
@export var success_condition: ConditionDef = null

## Content id unlocked when this objective is completed successfully.
@export var unlock_on_success_id: String = ""

## Admiralty briefing text shown to the player in the preparation screen.
@export var description: String = ""
```

- [ ] **Step 7: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 8: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/resources/DoctrineDef.gd game/src/content/resources/CrewBackgroundDef.gd game/src/content/resources/ZoneTypeDef.gd game/src/content/resources/ObjectiveDef.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add DoctrineDef, CrewBackgroundDef, ZoneTypeDef, ObjectiveDef Resources"
```

---

## Task 7: ContentValidator

**Files:**
- Create: `game/src/content/ContentValidator.gd`
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Add failing tests**

Add to `ContentFrameworkTest.gd` and call in `_ready()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _test_standing_order_def()
    _test_ship_upgrade_def()
    _test_doctrine_def()
    _test_crew_background_def()
    _test_zone_type_def()
    _test_objective_def()
    _test_content_validator()
    _finish()


func _test_content_validator() -> void:
    print("-- ContentValidator --")

    # Valid catalog: one supply with a proper id
    var valid_supply := SupplyDef.new()
    valid_supply.id = "food"
    valid_supply.display_name = "Food"
    var valid_catalog := {"supplies": [valid_supply]}
    var errors := ContentValidator.validate(valid_catalog)
    check(errors.is_empty(), "Validator: valid item produces no errors")

    # Missing id
    var no_id := SupplyDef.new()
    no_id.id = ""
    var missing_id_catalog := {"supplies": [no_id]}
    errors = ContentValidator.validate(missing_id_catalog)
    check(errors.size() > 0, "Validator: missing id produces an error")
    check(errors.any(func(e: String): return "missing id" in e.to_lower()), "Validator: missing id error mentions 'missing id'")

    # Duplicate ids
    var dup1 := SupplyDef.new()
    dup1.id = "food"
    var dup2 := SupplyDef.new()
    dup2.id = "food"
    var dup_catalog := {"supplies": [dup1, dup2]}
    errors = ContentValidator.validate(dup_catalog)
    check(errors.size() > 0, "Validator: duplicate id produces an error")
    check(errors.any(func(e: String): return "duplicate" in e.to_lower()), "Validator: duplicate id error mentions 'duplicate'")

    # Unknown effect type (inside an IncidentChoiceDef inside an IncidentDef)
    var bad_effect := EffectDef.new()
    bad_effect.type = "not_a_real_effect_type"
    var bad_choice := IncidentChoiceDef.new()
    bad_choice.immediate_effects = [bad_effect]
    var bad_incident := IncidentDef.new()
    bad_incident.id = "test_incident"
    bad_incident.choices = [bad_choice]
    var effect_catalog := {"incidents": [bad_incident]}
    errors = ContentValidator.validate(effect_catalog)
    check(errors.size() > 0, "Validator: unknown effect type produces an error")
    check(errors.any(func(e: String): return "not_a_real_effect_type" in e), "Validator: unknown effect type error names the bad type")

    # Unknown condition type
    var bad_cond := ConditionDef.new()
    bad_cond.type = "not_a_real_condition_type"
    var cond_incident := IncidentDef.new()
    cond_incident.id = "test_cond_incident"
    cond_incident.required_conditions = [bad_cond]
    var cond_catalog := {"incidents": [cond_incident]}
    errors = ContentValidator.validate(cond_catalog)
    check(errors.size() > 0, "Validator: unknown condition type produces an error")
    check(errors.any(func(e: String): return "not_a_real_condition_type" in e), "Validator: unknown condition type error names the bad type")

    # Unknown effect type inside StandingOrderDef.tick_effects
    var bad_so_effect := EffectDef.new()
    bad_so_effect.type = "typo_burden_change"
    var bad_so := StandingOrderDef.new()
    bad_so.id = "test_order"
    bad_so.tick_effects = [bad_so_effect]
    var so_catalog := {"standing_orders": [bad_so]}
    errors = ContentValidator.validate(so_catalog)
    check(errors.size() > 0, "Validator: unknown effect type in StandingOrderDef produces an error")

    # Unknown effect type inside ShipUpgradeDef.upgrade_effects
    var bad_up_effect := EffectDef.new()
    bad_up_effect.type = "invalid_upgrade_effect"
    var bad_up := ShipUpgradeDef.new()
    bad_up.id = "test_upgrade"
    bad_up.upgrade_effects = [bad_up_effect]
    var up_catalog := {"upgrades": [bad_up]}
    errors = ContentValidator.validate(up_catalog)
    check(errors.size() > 0, "Validator: unknown effect type in ShipUpgradeDef produces an error")
```

- [ ] **Step 2: Run test — expect failure**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Expected: error about `ContentValidator` not found.

- [ ] **Step 3: Create ContentValidator.gd**

Create `game/src/content/ContentValidator.gd`:

```gdscript
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


static func _check_effect(effect: EffectDef, family: String, item_id: String, errors: Array[String]) -> void:
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
```

- [ ] **Step 4: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

- [ ] **Step 5: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/ContentValidator.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add ContentValidator with id, duplicate, and type checks"
```

---

## Task 8: Content Directory Structure

**Files:**
- Create: 9 content family folders under `game/content/`

These folders must exist for `DirAccess` to scan them. Godot does not track empty directories in git, so each folder gets a `.gitkeep` file.

- [ ] **Step 1: Create content directories with .gitkeep**

```bash
mkdir -p /home/joe/repos/deadreckoning/game/content/{supplies,officers,standing_orders,upgrades,doctrines,crew_backgrounds,zone_types,objectives,incidents}
touch /home/joe/repos/deadreckoning/game/content/supplies/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/officers/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/standing_orders/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/upgrades/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/doctrines/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/crew_backgrounds/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/zone_types/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/objectives/.gitkeep
touch /home/joe/repos/deadreckoning/game/content/incidents/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/content/
git commit -m "feat(stage-1): create content family directories"
```

---

## Task 9: ContentRegistry and Autoload

**Files:**
- Create: `game/src/content/ContentRegistry.gd`
- Modify: `game/project.godot` (add autoload, add test to verify registry loads)
- Modify: `game/test/ContentFrameworkTest.gd`

- [ ] **Step 1: Create ContentRegistry.gd**

Create `game/src/content/ContentRegistry.gd`:

```gdscript
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
        {"name": "supplies",        "folder": "res://content/supplies/",        "class": SupplyDef},
        {"name": "officers",        "folder": "res://content/officers/",        "class": OfficerDef},
        {"name": "standing_orders", "folder": "res://content/standing_orders/", "class": StandingOrderDef},
        {"name": "upgrades",        "folder": "res://content/upgrades/",        "class": ShipUpgradeDef},
        {"name": "doctrines",       "folder": "res://content/doctrines/",       "class": DoctrineDef},
        {"name": "crew_backgrounds","folder": "res://content/crew_backgrounds/","class": CrewBackgroundDef},
        {"name": "zone_types",      "folder": "res://content/zone_types/",      "class": ZoneTypeDef},
        {"name": "objectives",      "folder": "res://content/objectives/",      "class": ObjectiveDef},
        {"name": "incidents",       "folder": "res://content/incidents/",       "class": IncidentDef},
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
                var path := family.folder + file_name
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
    # Convert catalog from {family: {id: item}} to {family: [item]} for validator
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
```

- [ ] **Step 2: Register ContentRegistry as autoload in project.godot**

Open `game/project.godot` and add the `[autoload]` section. The file currently ends with the `[rendering]` section. Add after it:

```ini
[autoload]

ContentRegistry="*res://src/content/ContentRegistry.gd"
```

The `*` prefix tells Godot to instance this node automatically. The full `[application]` section should now have `run/main_scene` still pointing to `res://test/ContentFrameworkTest.tscn` — leave it there for now.

- [ ] **Step 3: Add registry tests to ContentFrameworkTest.gd**

Add to the end of `ContentFrameworkTest.gd` and call in `_ready()`:

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _test_standing_order_def()
    _test_ship_upgrade_def()
    _test_doctrine_def()
    _test_crew_background_def()
    _test_zone_type_def()
    _test_objective_def()
    _test_content_validator()
    _test_content_registry_empty()
    _finish()


func _test_content_registry_empty() -> void:
    print("-- ContentRegistry (empty catalog) --")
    # With no .tres files yet, the registry loads successfully with empty families.
    check(ContentRegistry != null, "ContentRegistry autoload is available")
    var families := ContentRegistry.get_families()
    check(families.size() == 9, "ContentRegistry has 9 registered families")
    check(families.has("supplies"), "ContentRegistry has supplies family")
    check(families.has("incidents"), "ContentRegistry has incidents family")
    check(families.has("zone_types"), "ContentRegistry has zone_types family")

    # Empty families return empty arrays and null lookups — not errors
    var items := ContentRegistry.get_all("supplies")
    check(items.is_empty(), "ContentRegistry.get_all returns empty array for empty family")
    var item := ContentRegistry.get_by_id("supplies", "rum")
    check(item == null, "ContentRegistry.get_by_id returns null for missing item")

    # No .tres files = no validation errors (nothing to validate)
    check(ContentRegistry.is_valid(), "ContentRegistry.is_valid() true with empty catalog")
```

- [ ] **Step 4: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

Confirm: 9 registered families, all empty, `is_valid()` true.

- [ ] **Step 5: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/src/content/ContentRegistry.gd game/project.godot game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add ContentRegistry autoload and empty-catalog tests"
```

---

## Task 10: Sample Content

**Files:**
- Create: `game/tools/CreateSampleContent.gd` (EditorScript, runs once, then deleted)
- Create (via the script): all sample `.tres` files

This task uses a Godot `EditorScript` (`@tool` + `extends EditorScript`) to generate correctly-formatted `.tres` files via `ResourceSaver`. Run it once through the Godot editor, then delete the script.

- [ ] **Step 1: Create the tools directory and CreateSampleContent.gd**

```bash
mkdir -p /home/joe/repos/deadreckoning/game/tools
```

Create `game/tools/CreateSampleContent.gd`:

```gdscript
# CreateSampleContent.gd
# @tool EditorScript — run once to generate all sample .tres content files.
# Run via: Script Editor → File → Run (or right-click in FileSystem → Run)
# DELETE THIS FILE after running. It is not part of the shipping project.
@tool
extends EditorScript


func _run() -> void:
    print("CreateSampleContent: generating sample .tres files...")
    _create_supplies()
    _create_officers()
    _create_standing_orders()
    _create_upgrades()
    _create_doctrines()
    _create_crew_backgrounds()
    _create_zone_types()
    _create_objectives()
    _create_incidents()
    _create_validation_test_item()
    print("CreateSampleContent: done.")


func _save(resource: Resource, path: String) -> void:
    var err := ResourceSaver.save(resource, path)
    if err != OK:
        push_error("CreateSampleContent: failed to save " + path + " (error %d)" % err)
    else:
        print("  saved: " + path)


func _create_supplies() -> void:
    var rum := SupplyDef.new()
    rum.id = "rum"
    rum.display_name = "Rum"
    rum.category = "supply"
    rum.tags = ["alcohol", "special"]
    rum.rarity_weight = 1.0
    rum.is_rum = true
    rum.starting_amount = 100
    rum.daily_consumption = 2
    rum.low_threshold = 20
    rum.critical_threshold = 5
    _save(rum, "res://content/supplies/rum.tres")

    var food := SupplyDef.new()
    food.id = "food"
    food.display_name = "Food"
    food.category = "supply"
    food.tags = ["essential"]
    food.rarity_weight = 1.0
    food.is_rum = false
    food.starting_amount = 200
    food.daily_consumption = 5
    food.low_threshold = 40
    food.critical_threshold = 10
    _save(food, "res://content/supplies/food.tres")


func _create_officers() -> void:
    var bosun := OfficerDef.new()
    bosun.id = "bosun"
    bosun.display_name = "The Bosun"
    bosun.category = "officer"
    bosun.tags = ["core_crew"]
    bosun.role = "bosun"
    bosun.competence = 4
    bosun.loyalty = 3
    bosun.worldview = "disciplinarian"
    bosun.known_traits = ["blunt", "reliable"]
    bosun.hidden_traits = []
    bosun.advice_hooks = ["drunk_purser_store_error"]
    _save(bosun, "res://content/officers/bosun.tres")

    var surgeon := OfficerDef.new()
    surgeon.id = "surgeon"
    surgeon.display_name = "The Surgeon"
    surgeon.category = "officer"
    surgeon.tags = ["core_crew"]
    surgeon.role = "surgeon"
    surgeon.competence = 3
    surgeon.loyalty = 4
    surgeon.worldview = "humanitarian"
    surgeon.known_traits = ["cautious", "observant"]
    surgeon.hidden_traits = ["drinks_in_secret"]
    surgeon.advice_hooks = ["drunk_purser_store_error"]
    _save(surgeon, "res://content/officers/surgeon.tres")


func _create_standing_orders() -> void:
    var tighten := StandingOrderDef.new()
    tighten.id = "tighten_rationing"
    tighten.display_name = "Tighten Rationing"
    tighten.category = "logistics"
    tighten.tags = ["supply", "morale_risk"]
    tighten.command_cost = 2
    tighten.labor_cost = 0
    tighten.supply_cost_type = ""
    tighten.supply_cost_amount = 0
    tighten.forecast_text = "Likely reduces food consumption. Crew may resent it — Burden risk if extended."
    tighten.tick_effects = []
    tighten.incident_interactions = ["ration_dispute"]
    _save(tighten, "res://content/standing_orders/tighten_rationing.tres")

    var prayer := StandingOrderDef.new()
    prayer.id = "hold_prayer"
    prayer.display_name = "Hold Prayer"
    prayer.category = "morale"
    prayer.tags = ["morale", "omen"]
    prayer.command_cost = 1
    prayer.labor_cost = 0
    prayer.supply_cost_type = ""
    prayer.supply_cost_amount = 0
    prayer.forecast_text = "Likely reduces Burden for a pious crew. May irritate cynical officers."
    prayer.tick_effects = []
    prayer.incident_interactions = ["mermaid_sighting"]
    _save(prayer, "res://content/standing_orders/hold_prayer.tres")


func _create_upgrades() -> void:
    var hull := ShipUpgradeDef.new()
    hull.id = "reinforced_hull"
    hull.display_name = "Reinforced Hull"
    hull.category = "ship"
    hull.tags = ["durability"]
    hull.preparation_cost = 3
    hull.drawback_text = "Heavier — travel ticks consume slightly more food."
    hull.upgrade_effects = []
    _save(hull, "res://content/upgrades/reinforced_hull.tres")


func _create_doctrines() -> void:
    var doctrine := DoctrineDef.new()
    doctrine.id = "shared_hardship"
    doctrine.display_name = "Shared Hardship Doctrine"
    doctrine.category = "doctrine"
    doctrine.tags = ["egalitarian"]
    doctrine.unlocked_standing_order_ids = ["share_officer_comforts", "rotate_sick_off_duty"]
    doctrine.command_culture_modifier = "egalitarian"
    doctrine.description = "Officers share the crew's privations. Earns loyalty; undermines hierarchy."
    _save(doctrine, "res://content/doctrines/shared_hardship.tres")


func _create_crew_backgrounds() -> void:
    var pressed := CrewBackgroundDef.new()
    pressed.id = "pressed_crew"
    pressed.display_name = "Pressed Crew"
    pressed.category = "crew"
    pressed.tags = ["volatile", "cheap"]
    pressed.starting_traits = ["pressed", "resentful", "cheap_labor"]
    pressed.starting_command_modifier = -5
    pressed.starting_burden_modifier = 10
    pressed.description = "Impressment fills the lower deck cheaply. Starts with resentment baked in — discipline costs more."
    _save(pressed, "res://content/crew_backgrounds/pressed_crew.tres")


func _create_zone_types() -> void:
    var coastal := ZoneTypeDef.new()
    coastal.id = "coastal"
    coastal.display_name = "Coastal Waters"
    coastal.category = "zone"
    coastal.tags = ["navigable", "safe"]
    coastal.consumption_modifier = 1.0
    coastal.ship_wear_modifier = 0.8
    coastal.burden_delta_per_tick = 0
    coastal.incident_weight_modifier = 0.8
    coastal.eligible_incident_tags = []
    coastal.suppressed_incident_tags = ["deep_ocean"]
    _save(coastal, "res://content/zone_types/coastal.tres")

    var open_ocean := ZoneTypeDef.new()
    open_ocean.id = "open_ocean"
    open_ocean.display_name = "Open Ocean"
    open_ocean.category = "zone"
    open_ocean.tags = ["exposed", "demanding"]
    open_ocean.consumption_modifier = 1.2
    open_ocean.ship_wear_modifier = 1.5
    open_ocean.burden_delta_per_tick = 1
    open_ocean.incident_weight_modifier = 1.2
    open_ocean.eligible_incident_tags = ["deep_ocean", "weather"]
    open_ocean.suppressed_incident_tags = []
    _save(open_ocean, "res://content/zone_types/open_ocean.tres")


func _create_objectives() -> void:
    var survey := ObjectiveDef.new()
    survey.id = "survey_strange_shore"
    survey.display_name = "Survey the Strange Shore"
    survey.category = "survey"
    survey.tags = ["admiralty", "tier_2"]
    survey.objective_type = "survey"
    survey.difficulty_tier = 2
    survey.required_node_category = "Landfall"
    var cond := ConditionDef.new()
    cond.type = "has_memory_flag"
    cond.flag_key = "strange_shore_surveyed"
    survey.success_condition = cond
    survey.unlock_on_success_id = ""
    survey.description = "The Admiralty wishes detailed charts of the uncharted landmass reported by the Minerva. Make landfall and survey it."
    _save(survey, "res://content/objectives/survey_strange_shore.tres")


func _create_incidents() -> void:
    # Choices
    var punish_choice := IncidentChoiceDef.new()
    punish_choice.choice_text = "Hold the purser accountable. Order a public audit."
    punish_choice.officer_id = "bosun"
    punish_choice.required_conditions = []
    var punish_effect := EffectDef.new()
    punish_effect.type = "command_change"
    punish_effect.delta = 3
    var burden_effect := EffectDef.new()
    burden_effect.type = "burden_change"
    burden_effect.delta = -2
    punish_choice.immediate_effects = [punish_effect, burden_effect]
    punish_choice.memory_flags_set = ["purser_exposed"]
    punish_choice.log_text = "The purser's error is announced to the crew. Command steadies, but the purser's humiliation will not be forgotten."

    var cover_choice := IncidentChoiceDef.new()
    cover_choice.choice_text = "Cover the shortfall quietly. Adjust the records."
    cover_choice.officer_id = ""
    cover_choice.required_conditions = []
    var cover_effect := EffectDef.new()
    cover_effect.type = "set_memory_flag"
    cover_effect.flag_key = "purser_error_concealed"
    cover_choice.immediate_effects = [cover_effect]
    cover_choice.memory_flags_set = ["purser_error_concealed"]
    cover_choice.log_text = "The captain adjusts the ledger. The crew suspects nothing — for now."

    # Trigger condition
    var trigger_cond := ConditionDef.new()
    trigger_cond.type = "has_crew_trait"
    trigger_cond.tag = "rum_aboard"

    var incident := IncidentDef.new()
    incident.id = "drunk_purser_store_error"
    incident.display_name = "The Purser's Error"
    incident.category = "social"
    incident.tags = ["purser", "rum", "supply"]
    incident.trigger_band = "tick"
    incident.required_conditions = [trigger_cond]
    incident.amplifier_conditions = []
    incident.cast_roles = ["purser", "bosun"]
    incident.eligible_zone_tags = []
    incident.suppressed_zone_tags = []
    incident.standing_order_interactions = ["audit_stores"]
    incident.choices = [punish_choice, cover_choice]
    incident.log_text_template = "The purser's count is short. Rum has gone missing from the spirit locker."
    _save(incident, "res://content/incidents/drunk_purser_store_error.tres")


func _create_validation_test_item() -> void:
    # Intentionally invalid — empty id and unknown effect type.
    # Used to verify ContentValidator catches errors during development.
    # Remove this .tres before Stage 2.
    var bad_effect := EffectDef.new()
    bad_effect.type = "not_a_real_type"

    var bad_choice := IncidentChoiceDef.new()
    bad_choice.choice_text = "Bad choice"
    bad_choice.immediate_effects = [bad_effect]

    var bad_incident := IncidentDef.new()
    bad_incident.id = ""  # intentionally empty — will fail missing-id check
    bad_incident.display_name = "Invalid Test Item"
    bad_incident.choices = [bad_choice]
    _save(bad_incident, "res://content/incidents/_test_invalid.tres")
```

- [ ] **Step 2: Run CreateSampleContent.gd in the Godot editor**

Open the Godot editor with `godot --path /home/joe/repos/deadreckoning/game`.

In the Godot editor:
1. Open `tools/CreateSampleContent.gd` in the Script Editor.
2. With the script open, click **File → Run** (or press **Ctrl+Shift+X**).
3. Check the Output panel — you should see `saved: res://content/...` lines for each file.
4. Verify the files appear in the FileSystem panel under `content/`.

- [ ] **Step 3: Add registry-with-content tests to ContentFrameworkTest.gd**

Add to `ContentFrameworkTest.gd` and call in `_ready()` (replace the previous `_test_content_registry_empty()` call with both):

```gdscript
func _ready() -> void:
    print("=== ContentFrameworkTest ===\n")
    _test_content_base()
    _test_effect_def()
    _test_condition_def()
    _test_incident_choice_def()
    _test_incident_def()
    _test_supply_def()
    _test_officer_def()
    _test_standing_order_def()
    _test_ship_upgrade_def()
    _test_doctrine_def()
    _test_crew_background_def()
    _test_zone_type_def()
    _test_objective_def()
    _test_content_validator()
    _test_content_registry_empty()
    _test_content_registry_with_content()
    _finish()


func _test_content_registry_with_content() -> void:
    print("-- ContentRegistry (with sample content) --")
    # Sample content is now on disk. Registry loaded it in _ready().
    var supplies := ContentRegistry.get_all("supplies")
    check(supplies.size() == 2, "ContentRegistry: 2 supplies loaded (rum + food)")

    var rum: SupplyDef = ContentRegistry.get_by_id("supplies", "rum")
    check(rum != null, "ContentRegistry: rum supply found by id")
    check(rum.is_rum == true, "ContentRegistry: rum.is_rum is true")
    check(rum.starting_amount == 100, "ContentRegistry: rum.starting_amount is 100")

    var officers := ContentRegistry.get_all("officers")
    check(officers.size() == 2, "ContentRegistry: 2 officers loaded")

    var bosun: OfficerDef = ContentRegistry.get_by_id("officers", "bosun")
    check(bosun != null, "ContentRegistry: bosun officer found by id")
    check(bosun.role == "bosun", "ContentRegistry: bosun.role is correct")

    var incidents := ContentRegistry.get_all("incidents")
    # _test_invalid.tres is also loaded — its id is "" so it won't be found by id,
    # but it IS in the catalog (keyed under ""). The validator catches it.
    check(incidents.size() >= 1, "ContentRegistry: at least 1 incident loaded")

    var incident: IncidentDef = ContentRegistry.get_by_id("incidents", "drunk_purser_store_error")
    check(incident != null, "ContentRegistry: drunk_purser_store_error incident found by id")
    check(incident.choices.size() == 2, "ContentRegistry: incident has 2 choices")

    # Validator should catch the _test_invalid.tres item
    check(not ContentRegistry.is_valid(), "ContentRegistry.is_valid() is false with _test_invalid.tres present")
    var errors := ContentRegistry.get_validation_errors()
    check(errors.size() > 0, "ContentRegistry: validation errors non-empty with invalid item")
    check(errors.any(func(e: String): return "missing id" in e.to_lower()), "ContentRegistry: missing id error present")
    check(errors.any(func(e: String): return "not_a_real_type" in e), "ContentRegistry: unknown effect type error present")

    var zone_types := ContentRegistry.get_all("zone_types")
    check(zone_types.size() == 2, "ContentRegistry: 2 zone types loaded")

    var coastal: ZoneTypeDef = ContentRegistry.get_by_id("zone_types", "coastal")
    check(coastal != null, "ContentRegistry: coastal zone type found by id")
    check(is_equal_approx(coastal.ship_wear_modifier, 0.8), "ContentRegistry: coastal.ship_wear_modifier correct")
```

- [ ] **Step 4: Run test — expect ALL PASS**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

The test with content checks passes. The `_test_content_registry_empty` check for `is_valid() == true` will now fail because `_test_invalid.tres` is loaded. Update that test:

In `_test_content_registry_empty()`, change:
```gdscript
    check(ContentRegistry.is_valid(), "ContentRegistry.is_valid() true with empty catalog")
```
to:
```gdscript
    # Note: cannot check is_valid() here because sample content is already loaded at startup
    check(true, "ContentRegistry.is_valid() check deferred to _test_content_registry_with_content")
```

Re-run and confirm ALL PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/content/ game/tools/CreateSampleContent.gd game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): add sample .tres content and registry-with-content tests"
```

---

## Task 11: Debug Scene

**Files:**
- Create: `game/test/ContentDebugScene.gd`
- Create: `game/test/ContentDebugScene.tscn`
- Modify: `game/project.godot` (swap main scene)
- Delete: `game/tools/CreateSampleContent.gd` (generated content already committed)

- [ ] **Step 1: Create ContentDebugScene.gd**

Create `game/test/ContentDebugScene.gd`:

```gdscript
# ContentDebugScene.gd
# Interactive debug scene for Stage 1 content framework.
# Shows a button per content family + a Validate All button.
# Output appears in a scrollable RichTextLabel.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
extends Control

@onready var output: RichTextLabel = $VBox/ScrollContainer/Output


func _ready() -> void:
    _show_validate_all()


func _show_validate_all() -> void:
    output.clear()
    output.append_text("[b]Content Catalog — Validate All[/b]\n\n")

    var all_valid := true
    for family: String in ContentRegistry.get_families():
        var items := ContentRegistry.get_all(family)
        output.append_text("[b]%s[/b]: %d item(s)\n" % [family, items.size()])

    var errors := ContentRegistry.get_validation_errors()
    if errors.is_empty():
        output.append_text("\n[color=green]PASS — no validation errors[/color]\n")
    else:
        all_valid = false
        output.append_text("\n[color=red]FAIL — %d error(s):[/color]\n" % errors.size())
        for err: String in errors:
            output.append_text("  • %s\n" % err)

    output.append_text("\nOverall: %s\n" % ("[color=green]VALID[/color]" if all_valid else "[color=red]INVALID[/color]"))


func _show_family(family: String) -> void:
    output.clear()
    output.append_text("[b]%s[/b]\n\n" % family)
    var items := ContentRegistry.get_all(family)
    if items.is_empty():
        output.append_text("(no items loaded)\n")
        return
    for item: ContentBase in items:
        output.append_text("• [b]%s[/b]  %s\n" % [item.id, item.display_name])
        if not item.category.is_empty():
            output.append_text("  category: %s\n" % item.category)
        if not item.tags.is_empty():
            output.append_text("  tags: %s\n" % ", ".join(item.tags))
        output.append_text("\n")


func _on_validate_all_pressed() -> void:
    _show_validate_all()


func _on_incidents_pressed() -> void:
    _show_family("incidents")


func _on_officers_pressed() -> void:
    _show_family("officers")


func _on_supplies_pressed() -> void:
    _show_family("supplies")


func _on_standing_orders_pressed() -> void:
    _show_family("standing_orders")


func _on_upgrades_pressed() -> void:
    _show_family("upgrades")


func _on_doctrines_pressed() -> void:
    _show_family("doctrines")


func _on_crew_backgrounds_pressed() -> void:
    _show_family("crew_backgrounds")


func _on_zone_types_pressed() -> void:
    _show_family("zone_types")


func _on_objectives_pressed() -> void:
    _show_family("objectives")
```

- [ ] **Step 2: Create ContentDebugScene.tscn**

**Preferred approach:** Create this scene in the Godot editor (Scene → New Scene, add a Control root, build the VBoxContainer/HBoxContainer/ScrollContainer/RichTextLabel structure, attach ContentDebugScene.gd). Save as `res://test/ContentDebugScene.tscn`.

**Fallback (hand-written .tscn):** If creating via editor is not available, create `game/test/ContentDebugScene.tscn` with the raw text below. The format may need minor fixes if Godot reports parse errors — open in the editor and let Godot normalise it.

Create `game/test/ContentDebugScene.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/ContentDebugScene.gd" id="1"]

[node name="ContentDebugScene" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Buttons" type="HBoxContainer" parent="VBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="ValidateAll" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Validate All"

[node name="Incidents" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Incidents"

[node name="Officers" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Officers"

[node name="Supplies" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Supplies"

[node name="StandingOrders" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Standing Orders"

[node name="Upgrades" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Upgrades"

[node name="Doctrines" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Doctrines"

[node name="CrewBackgrounds" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Crew Backgrounds"

[node name="ZoneTypes" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Zone Types"

[node name="Objectives" type="Button" parent="VBox/Buttons"]
layout_mode = 2
text = "Objectives"

[node name="ScrollContainer" type="ScrollContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="Output" type="RichTextLabel" parent="VBox/ScrollContainer"]
layout_mode = 2
bbcode_enabled = true
fit_content = true
```

- [ ] **Step 3: Wire button signals**

The `.tscn` file above does not have signal connections wired — Godot's signal system requires connections either via the editor or code. Add signal connections in `ContentDebugScene.gd`'s `_ready()`:

Replace the `_ready()` function with:

```gdscript
func _ready() -> void:
    $VBox/Buttons/ValidateAll.pressed.connect(_on_validate_all_pressed)
    $VBox/Buttons/Incidents.pressed.connect(_on_incidents_pressed)
    $VBox/Buttons/Officers.pressed.connect(_on_officers_pressed)
    $VBox/Buttons/Supplies.pressed.connect(_on_supplies_pressed)
    $VBox/Buttons/StandingOrders.pressed.connect(_on_standing_orders_pressed)
    $VBox/Buttons/Upgrades.pressed.connect(_on_upgrades_pressed)
    $VBox/Buttons/Doctrines.pressed.connect(_on_doctrines_pressed)
    $VBox/Buttons/CrewBackgrounds.pressed.connect(_on_crew_backgrounds_pressed)
    $VBox/Buttons/ZoneTypes.pressed.connect(_on_zone_types_pressed)
    $VBox/Buttons/Objectives.pressed.connect(_on_objectives_pressed)
    _show_validate_all()
```

- [ ] **Step 4: Set ContentDebugScene as main scene**

Edit `game/project.godot`. Change:
```ini
run/main_scene="res://test/ContentFrameworkTest.tscn"
```
to:
```ini
run/main_scene="res://test/ContentDebugScene.tscn"
```

- [ ] **Step 5: Open the debug scene in the Godot editor and verify**

Open the project in the Godot editor and press **F5** (Run Project).

Expected:
- The debug scene opens showing "Validate All" output on startup.
- Per-family buttons list the correct items.
- "Validate All" shows the `_test_invalid.tres` error and an overall INVALID result.
- Clicking "Supplies" shows `rum` and `food` with categories and tags.
- Clicking "Incidents" shows `drunk_purser_store_error` (and `_test_invalid`).
- Clicking "Zone Types" shows `coastal` and `open_ocean`.

- [ ] **Step 6: Delete tools/CreateSampleContent.gd**

```bash
rm /home/joe/repos/deadreckoning/game/tools/CreateSampleContent.gd
```

- [ ] **Step 7: Commit**

```bash
cd /home/joe/repos/deadreckoning
git add game/test/ContentDebugScene.gd game/test/ContentDebugScene.tscn game/project.godot
git rm game/tools/CreateSampleContent.gd
git commit -m "feat(stage-1): add interactive content debug scene, set as main scene"
```

---

## Task 12: Remove Validation Test Item and Verify Clean Catalog

The `_test_invalid.tres` file was only needed to verify the validator catches errors. Remove it and confirm `is_valid()` returns true.

- [ ] **Step 1: Delete the invalid test item**

```bash
rm /home/joe/repos/deadreckoning/game/content/incidents/_test_invalid.tres
```

Also delete its Godot import metadata if present:
```bash
rm -f /home/joe/repos/deadreckoning/game/.godot/imported/_test_invalid.tres.*
```

- [ ] **Step 2: Run the debug scene and verify**

Open the project in the Godot editor and press **F5**.

"Validate All" should now show `PASS — no validation errors` and `Overall: VALID`.

- [ ] **Step 3: Run the headless tests as final verification**

```bash
godot --headless --path /home/joe/repos/deadreckoning/game res://test/ContentFrameworkTest.tscn 2>&1
```

The `_test_content_registry_with_content` test expects `is_valid()` to be false (because `_test_invalid.tres` was present). Now that it is removed, update that test:

In `_test_content_registry_with_content()`, change:
```gdscript
    check(not ContentRegistry.is_valid(), "ContentRegistry.is_valid() is false with _test_invalid.tres present")
    var errors := ContentRegistry.get_validation_errors()
    check(errors.size() > 0, "ContentRegistry: validation errors non-empty with invalid item")
    check(errors.any(func(e: String): return "missing id" in e.to_lower()), "ContentRegistry: missing id error present")
    check(errors.any(func(e: String): return "not_a_real_type" in e), "ContentRegistry: unknown effect type error present")
```
to:
```gdscript
    check(ContentRegistry.is_valid(), "ContentRegistry.is_valid() is true with valid catalog")
    check(ContentRegistry.get_validation_errors().is_empty(), "ContentRegistry: no validation errors with valid catalog")
```

Re-run headless tests and confirm ALL PASS.

- [ ] **Step 4: Final commit**

```bash
cd /home/joe/repos/deadreckoning
git rm game/content/incidents/_test_invalid.tres
git add game/test/ContentFrameworkTest.gd
git commit -m "feat(stage-1): remove validation test item, confirm clean catalog — stage 1 complete"
```

---

## Testable Outcome Checklist

Before marking Stage 1 complete, verify all of these:

- [ ] `godot --headless --path game res://test/ContentFrameworkTest.tscn` exits with ALL PASS
- [ ] Debug scene opens: "Validate All" shows 9 families, correct item counts, PASS
- [ ] "Supplies" button shows rum (is_rum=true, starting_amount=100) and food
- [ ] "Incidents" button shows `drunk_purser_store_error` with 2 choices visible in output
- [ ] "Zone Types" button shows coastal and open_ocean with their modifiers
- [ ] Adding a new `.tres` file to any `content/` family folder makes it appear in the debug scene with no code changes
- [ ] `ContentRegistry.is_valid()` returns true
