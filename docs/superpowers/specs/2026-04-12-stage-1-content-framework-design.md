# Stage 1: Godot Content Framework — Design Spec

**Goal:** Establish the data-driven foundation for Dead Reckoning. All game content — supplies, effects, conditions, standing orders, officers, upgrades, doctrines, crew backgrounds, incidents, objectives, zone types — is defined in typed Godot custom Resources loaded and validated by a single registry. A debug scene lets you browse and validate the full catalog interactively.

---

## File Structure

```
res://
  src/
    content/
      ContentBase.gd          ← shared base Resource script
      ContentRegistry.gd      ← autoload singleton
      ContentValidator.gd     ← validation logic
      resources/
        ConditionDef.gd
        CrewBackgroundDef.gd
        DoctrineDef.gd
        EffectDef.gd
        IncidentChoiceDef.gd
        IncidentDef.gd
        ObjectiveDef.gd
        OfficerDef.gd
        ShipUpgradeDef.gd
        StandingOrderDef.gd
        SupplyDef.gd
        ZoneTypeDef.gd
  content/
    crew_backgrounds/
    doctrines/
    incidents/
    objectives/
    officers/
    standing_orders/
    supplies/
    upgrades/
    zone_types/
  test/
    ContentDebugScene.tscn
    ContentDebugScene.gd
```

---

## Resource Class Hierarchy

### ContentBase

All content Resources extend `ContentBase`. Shared fields:

| Field | Type | Notes |
|---|---|---|
| `id` | String | Unique within family. Snake_case. Required. |
| `display_name` | String | Human-readable label shown in UI. |
| `category` | String | Family-specific category tag (e.g. "crisis", "boon"). |
| `tags` | Array[String] | Arbitrary searchable tags. |
| `visibility_rules` | Array[String] | Strings evaluated by game code to gate display. |
| `unlock_source` | String | Id of the unlock that gates this content. Empty = always available. |
| `rarity_weight` | float | Relative weighting for random selection. Default 1.0. |

### Type-Specific Resource Classes

Each class extends `ContentBase` and adds only its own fields. No mega-schema.

**EffectDef** — an inline resource embedded in choices and other content. Not stored in a `content/` folder — embedded directly in parent Resources.

| Field | Type | Notes |
|---|---|---|
| `type` | String | One of the known effect types (see Validation). |
| `delta` | int | Numeric change where applicable. |
| `flag_key` | String | Memory flag to set, for flag-type effects. |
| `tag` | String | Damage tag to apply, for tag-type effects. |

**ConditionDef** — inline resource embedded in incident trigger bands and choice requirements.

| Field | Type | Notes |
|---|---|---|
| `type` | String | One of the known condition types (see Validation). |
| `threshold` | int | Numeric threshold where applicable. |
| `flag_key` | String | Memory flag to test, for flag-type conditions. |
| `tag` | String | Tag to test presence of, for tag-type conditions. |

**IncidentChoiceDef** — inline resource embedded in `IncidentDef`.

| Field | Type | Notes |
|---|---|---|
| `choice_text` | String | The option shown to the player. |
| `officer_id` | String | Officer who proposes this choice. Empty = captain's own option. |
| `required_conditions` | Array[ConditionDef] | All must pass for the choice to be available. |
| `immediate_effects` | Array[EffectDef] | Applied on selection. |
| `memory_flags_set` | Array[String] | Flags written to run memory on selection. |
| `log_text` | String | Ship log entry written on selection. |

**IncidentDef**

| Field | Type | Notes |
|---|---|---|
| `trigger_band` | String | When this can fire: `tick`, `node`, `aftermath`, `threshold`. |
| `required_conditions` | Array[ConditionDef] | All must pass for incident to be eligible. |
| `amplifier_conditions` | Array[ConditionDef] | Optional conditions that modify weight or text. |
| `cast_roles` | Array[String] | Officer/notable ids that must be present in roster. |
| `eligible_zone_tags` | Array[String] | Zone tags that allow this incident. Empty = any zone. |
| `suppressed_zone_tags` | Array[String] | Zone tags that block this incident. |
| `standing_order_interactions` | Array[String] | Standing order ids that modify this incident. |
| `choices` | Array[IncidentChoiceDef] | Player-facing options. |
| `log_text_template` | String | Ship log entry written when incident fires. |

**SupplyDef**

| Field | Type | Notes |
|---|---|---|
| `is_rum` | bool | Marks Rum for special-case handling. |
| `starting_amount` | int | Default quantity at expedition start. |
| `daily_consumption` | int | Units consumed per tick per crew. |
| `low_threshold` | int | Amount below which scarcity events trigger. |
| `critical_threshold` | int | Amount below which critical events trigger. |

**OfficerDef**

| Field | Type | Notes |
|---|---|---|
| `role` | String | e.g. `bosun`, `surgeon`, `purser`, `chaplain`, `first_mate`. |
| `competence` | int | 1–5 scale. Affects advice accuracy. |
| `loyalty` | int | 1–5 scale. Affects proposal reliability. |
| `worldview` | String | e.g. `disciplinarian`, `humanitarian`, `pragmatist`. |
| `known_traits` | Array[String] | Traits visible to the player from the start. |
| `hidden_traits` | Array[String] | Traits revealed through incidents. |
| `advice_hooks` | Array[String] | Incident ids this officer has authored proposals for. |

**StandingOrderDef**

| Field | Type | Notes |
|---|---|---|
| `command_cost` | int | Command bandwidth consumed while active. |
| `labor_cost` | int | Crew labor consumed per tick. |
| `supply_cost_type` | String | Supply id consumed, if any. |
| `supply_cost_amount` | int | Units consumed per tick, if any. |
| `forecast_text` | String | Evocative risk-language preview shown before selection. |
| `tick_effects` | Array[EffectDef] | Applied each tick while active. |
| `incident_interactions` | Array[String] | Incident ids this order modifies. |

**ShipUpgradeDef**

| Field | Type | Notes |
|---|---|---|
| `preparation_cost` | int | Budget cost in Admiralty preparation phase. |
| `upgrade_effects` | Array[EffectDef] | Passive effects applied to expedition state. |
| `drawback_text` | String | Plain-language description of the tradeoff. |

**DoctrineDef**

| Field | Type | Notes |
|---|---|---|
| `unlocked_standing_order_ids` | Array[String] | Standing order ids made available by this doctrine. |
| `command_culture_modifier` | String | Tag applied to expedition command culture. |
| `description` | String | Flavour and mechanical summary. |

**CrewBackgroundDef**

| Field | Type | Notes |
|---|---|---|
| `starting_traits` | Array[String] | Crew trait tags applied at expedition start. |
| `starting_command_modifier` | int | Positive or negative Command adjustment at start. |
| `starting_burden_modifier` | int | Positive or negative Burden adjustment at start. |
| `description` | String | Flavour and mechanical summary. |

**ZoneTypeDef**

| Field | Type | Notes |
|---|---|---|
| `consumption_modifier` | float | Multiplier on food/water consumption per tick. |
| `ship_wear_modifier` | float | Multiplier on ship wear per tick. |
| `burden_delta_per_tick` | int | Flat Burden change each tick in this zone. |
| `incident_weight_modifier` | float | Multiplier on incident trigger weight. |
| `eligible_incident_tags` | Array[String] | Incident tags allowed in this zone. |
| `suppressed_incident_tags` | Array[String] | Incident tags blocked in this zone. |

**ObjectiveDef**

| Field | Type | Notes |
|---|---|---|
| `objective_type` | String | One of: `survey`, `condition`, `recover`. |
| `difficulty_tier` | int | 1–3. Feeds Admiralty difficulty synthesis. |
| `required_node_category` | String | Route node category that must appear for survey/recover types. |
| `success_condition` | ConditionDef | Evaluated at run end to determine success. |
| `unlock_on_success_id` | String | Content id unlocked on success. |
| `description` | String | Admiralty briefing text shown to player. |

---

## ContentRegistry

Registered as an autoload named `ContentRegistry` in `project.godot`.

### Family Registration

Families are declared as an internal Array of Dictionaries:

```gdscript
{ "name": "incidents", "folder": "res://content/incidents/", "class": IncidentDef }
```

Adding a new content family = adding one entry. No other code changes required.

### Load Sequence (`_ready`)

1. For each registered family, use `DirAccess` to list all `.tres` files in the family folder.
2. Load each file with `ResourceLoader.load()`. If loading fails or the result is not an instance of the expected class, log an error and continue (no crash).
3. Store loaded items in a per-family Dictionary keyed by `id`.
4. Pass the full catalog to `ContentValidator`. Store the returned error list.
5. If errors exist, print a summary to the Godot Output panel.

### Public API

```gdscript
ContentRegistry.get_all("incidents") → Array[ContentBase]
ContentRegistry.get_by_id("incidents", "drunk_purser") → IncidentDef or null
ContentRegistry.get_families() → Array[String]
ContentRegistry.get_validation_errors() → Array[String]
ContentRegistry.is_valid() → bool
```

The catalog is read-only after `_ready()`. No reload at runtime.

---

## ContentValidator

Runs after all families are loaded. Returns `Array[String]` of error messages.

### Checks

1. **Missing id** — `id` is empty string or null.
2. **Duplicate id** — two items in the same family share an id.
3. **Type integrity** — loaded Resource is not an instance of the family's expected class.
4. **Unknown effect type** — any `EffectDef.type` not in the known-valid set.
5. **Unknown condition type** — any `ConditionDef.type` not in the known-valid set.

### Known Effect Types (initial set)

`burden_change`, `command_change`, `supply_change`, `ship_condition_change`, `add_damage_tag`, `remove_damage_tag`, `set_memory_flag`, `add_crew_trait`, `remove_crew_trait`

### Known Condition Types (initial set)

`burden_above`, `burden_below`, `command_above`, `command_below`, `supply_below`, `has_damage_tag`, `has_memory_flag`, `has_crew_trait`, `officer_present`, `zone_type_is`

### Error Format

`[family/id] description` — e.g. `[incidents/rum_theft] EffectDef has unknown type: "burden_raise"`

---

## Debug Scene

**Location:** `res://test/ContentDebugScene.tscn` (startup scene during Stage 1).

**Layout:**
- Top: horizontal button row
- Bottom: `ScrollContainer` containing a `RichTextLabel`

**Buttons:** `Validate All` | `Incidents` | `Officers` | `Supplies` | `Standing Orders` | `Upgrades` | `Doctrines` | `Crew Backgrounds` | `Zone Types` | `Objectives`

**Validate All:** Clears output. Prints per-family summary (item count, error count). Prints all errors. Shows overall PASS or FAIL.

**Per-type buttons:** Clears output. Prints a formatted list of every item in that family: `id`, `display_name`, `category`, `tags`.

---

## Sample Content

Authored `.tres` files covering every Resource class. Enough to exercise the loader and validator.

| Family | Files |
|---|---|
| supplies | `rum.tres`, `food.tres` |
| effects | *(inline — no standalone folder)* |
| conditions | *(inline — no standalone folder)* |
| standing_orders | `tighten_rationing.tres`, `hold_prayer.tres` |
| officers | `bosun.tres`, `surgeon.tres` |
| upgrades | `reinforced_hull.tres` |
| doctrines | `shared_hardship.tres` |
| crew_backgrounds | `pressed_crew.tres` |
| zone_types | `coastal.tres`, `open_ocean.tres` |
| objectives | `survey_strange_shore.tres` |
| incidents | `drunk_purser_store_error.tres` (two choices: punish / cover up) |

A file `_test_invalid.tres` placed directly in `content/incidents/` holds one intentionally invalid item (empty id, unknown effect type) for validator development. Removed before Stage 2.

---

## Testable Outcome

- The Godot project starts, `ContentRegistry` loads the full sample catalog without crashing.
- `Validate All` shows each family's item count and flags the intentional error in `_test_invalid.tres`.
- Per-type buttons display the correct items for each family.
- Adding a new `.tres` file to a content folder makes it appear in the debug scene with no code changes.
- Removing the `_validation_test/` item clears all errors and `is_valid()` returns true.
