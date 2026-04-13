# Stage 6A: Admiralty Preparation Layer — Design Spec

**Date:** 2026-04-13
**Stage:** 6A
**Status:** Approved

---

## Overview

Stage 6A delivers the complete preparation-to-run-end game loop. The player sees a Preparation screen, configures their expedition (officers, ship upgrades, doctrine, objective), launches the run, and lands on a Run End screen when it concludes. A `SaveManager` autoload persists unlocks between sessions. A `GameConstants` static class is the single source of truth for all balance values.

Stage 6B handles report framing, persistent officer relationships, Admiralty political bias, and full meta-progression feedback (unlock reveals). Stage 6A focuses on making the loop structurally complete and playable.

---

## Architecture

### Scene Flow

Three scenes form the full loop:

```
PreparationScene  →  RunScene  →  RunEndScene
       ↑___________________________|
```

- `PreparationScene` is the entry point. The player configures their run and presses "Set Sail".
- `RunScene` hosts the existing `ContentDebugScene` / expedition logic. When the run ends (final route node reached, or mutiny/breakdown threshold), it transitions to `RunEndScene` and passes the completed `ExpeditionState`.
- `RunEndScene` displays outcome, objective result, difficulty score, and a "Return to Admiralty" button that transitions back to `PreparationScene`.

All three scenes live under `res://src/ui/`.

### Autoloads

Two autoloads are added to `project.godot`:

| Autoload | Path | Purpose |
|---|---|---|
| `SaveManager` | `res://src/SaveManager.gd` | Reads/writes ProgressionState and run_state to disk |
| `ContentRegistry` | already exists | No change |

`ProgressionState` is a `Resource` subclass stored at `user://saves/<slot_id>/progression.tres`. Run state (in-progress expedition) is stored at `user://saves/<slot_id>/run_state.tres` and deleted when the run ends.

---

## GameConstants

A static GDScript class at `res://src/constants/GameConstants.gd`. No `extends`, no instantiation — all values are `const`.

```gdscript
class_name GameConstants

# Run-end thresholds
const MUTINY_COMMAND_THRESHOLD: int = 20
const MUTINY_BASE_RATE: float = 0.4
const BREAKDOWN_BURDEN_THRESHOLD: int = 100

# Stat clamp bounds
const BURDEN_MAX: int = 100
const BURDEN_MIN: int = 0
const COMMAND_MAX: int = 100
const COMMAND_MIN: int = 0

# Preparation screen
const MAX_UPGRADES: int = 2
const OBJECTIVE_SHORTLIST_SIZE: int = 3

# Save paths
const SAVE_DIR: String = "user://saves/"
```

Any existing magic numbers in `TravelSimulator`, `ExpeditionState`, or `RumRules` that correspond to these constants are replaced with `GameConstants.<CONST>` references.

---

## Preparation Screen

### Layout

`PreparationScene` is a full-screen scene with a single `VBoxContainer` root.

Sections (top to bottom):

1. **Header** — "Admiralty Briefing" title, flavour subtitle
2. **Objective** — `ObjectiveSlot`: shows 3 objectives drawn from a shortlist; player selects one
3. **Doctrine** — `DoctrineSlot`: shows available doctrines; player selects one (or None)
4. **Officers** — 6 role slots, one per required role (First Lieutenant, Master, Gunner, Purser, Surgeon, Chaplain). Each slot shows the 2 variants for that role. Player picks one per role. Locked slots (insufficient progression unlocks) show a lock icon and unlock condition.
5. **Ship Upgrades** — 2 upgrade slots. Each shows the available `ShipUpgradeDef` options. Locked upgrades are greyed out.
6. **Footer** — resource cost summary (starting Burden, Command, supplies after all officer/upgrade effects apply), "Set Sail" button

### Slot Model

Each slot is a lightweight `PreparationSlot` scene (reused across officer/upgrade/doctrine/objective). It holds:
- `label: String` — role name or slot label
- `options: Array[ContentBase]` — choices available
- `selected_index: int` — currently selected option
- `locked: bool` — whether slot is accessible given current `ProgressionState`

Locking uses `ProgressionState.is_unlocked(content_id: String) -> bool`. For MVP, all officer variants and at least one upgrade and doctrine are unlocked by default so a fresh game is playable.

### Run Configuration Object

When "Set Sail" is pressed, `PreparationScene` assembles a `RunConfig` dictionary:

```gdscript
{
  "objective_id": String,
  "doctrine_id": String,       # "" if none selected
  "officer_ids": Array[String], # one per role, 6 total
  "upgrade_ids": Array[String], # 0–2 entries
}
```

This is passed to `RunScene.start_run(config: Dictionary)`, which calls `ExpeditionState.create_from_config(config)` to build the initial state with all officer/upgrade starting effects applied.

### ExpeditionState.create_from_config

New static factory method alongside `create_default()`:

```gdscript
static func create_from_config(config: Dictionary) -> ExpeditionState:
```

Applies officer `starting_effects` (EffectDefs), upgrade effects, and doctrine's `unlocked_standing_order_ids` to the base state. Doctrine's `command_culture_modifier` is stored on state as `command_culture: String`.

**New fields required on `ExpeditionState`:**
- `run_end_reason: String = ""` — set by `_trigger_run_end`; one of `"completed"`, `"mutiny"`, `"breakdown"`
- `command_culture: String = ""` — set from doctrine's `command_culture_modifier` at run start

**New field required on `OfficerDef`:**
- `@export var role: String = ""` — one of `first_lieutenant`, `master`, `gunner`, `purser`, `surgeon`, `chaplain`; used by `PreparationScene` to group variants into the correct slot

---

## Officer Roles and Variants

### Required Roles (6)

| Role | Mechanical Focus |
|---|---|
| First Lieutenant | Command culture, crew morale incidents |
| Master | Navigation — tick skipping, route visibility, travel speed |
| Gunner | Combat outcomes, powder-store accidents, mutineer suppression |
| Purser | Supply management, rum ration administration |
| Surgeon | Crew health, sickness risk reduction, trauma recovery |
| Chaplain | Burden reduction, morale incidents, promise support |

### Variant Structure

Each role has exactly 2 variants for MVP. Variants differ in:
- `display_name` (e.g. "Stern Bosun" vs "Lenient Bosun" — or proper historical titles)
- `starting_effects` — array of `EffectDef`s applied at run start (e.g. Command −5, or supplies +10, or `add_standing_order: strict_watches`)
- `incident_weight_modifiers` — `WeightModifierDef`s that make certain incidents more or less likely
- `council_proposals` — which incident choices this officer can propose (existing `OfficerCouncil` system)

Starting effect costs create meaningful trade-offs: a better surgeon might cost 5 Burden at start; a reliable gunner might lock a standing order.

### Content Files

12 officer `.tres` files under `res://content/officers/`, named `<role>_<variant>.tres` (e.g. `first_lieutenant_strict.tres`, `first_lieutenant_permissive.tres`).

---

## Mutiny and Run End

### Escalating Mutiny Risk

`TravelSimulator` checks mutiny chance each tick in `_process_rum_rules()` (or a new `_check_run_end_conditions()` call):

```gdscript
if state.command <= GameConstants.MUTINY_COMMAND_THRESHOLD:
    var mutiny_chance: float = (float(state.burden) / 100.0) * GameConstants.MUTINY_BASE_RATE
    if randf() < mutiny_chance:
        _trigger_run_end(state, log, "mutiny")
        return
```

Standing orders can reduce `mutiny_chance` before the roll (e.g. a `suppress_dissent` order applies a multiplier). This reuses the existing `has_standing_order()` check pattern.

### Breakdown

If `state.burden >= GameConstants.BREAKDOWN_BURDEN_THRESHOLD`:

```gdscript
_trigger_run_end(state, log, "breakdown")
```

This fires immediately on the tick burden hits 100, before any further effect processing.

### Final Node

When `TravelSimulator` reaches the final route node and completes its effects, it calls `_trigger_run_end(state, log, "completed")`.

### _trigger_run_end

Sets `state.run_end_reason: String` and emits a `run_ended(state: ExpeditionState)` signal on `TravelSimulator`. `RunScene` connects to this signal and transitions to `RunEndScene`, passing the completed `ExpeditionState`.

---

## Run End Scene

### Layout

`RunEndScene` is a full-screen `VBoxContainer`:

1. **Outcome Header** — large text: "Expedition Complete", "Mutiny", or "Expedition Lost". Flavour line beneath.
2. **Objective Panel** — objective display name + success/failure. One sentence description of result.
3. **Stress Indicators Panel** — 4 values displayed as a simple table: Peak Burden, Min Command, Crew Losses, Supply Depletions.
4. **Difficulty Score** — synthesised integer (0–100) computed from stress indicators. Label: "Admiralty Assessment: [score]/100". Stored on `ProgressionState` but not yet used to gate unlocks (6B).
5. **Return Button** — "Return to Admiralty" → `PreparationScene`

### Difficulty Synthesis (6A)

Simple additive formula, tunable via `GameConstants`:

```
score = (peak_burden * 0.3) + ((100 - min_command) * 0.3) + (crew_losses * 5) + (supply_depletions * 3)
score = clampi(score, 0, 100)
```

Stored as `ProgressionState.last_run_difficulty_score`. Not yet used to unlock content — that's 6B.

### Unlock Processing (6A)

If objective `success_condition` passes, `RunEndScene` calls `SaveManager.record_objective_complete(objective_id)`, which sets `ProgressionState.completed_objective_ids` and calls `ProgressionState.apply_unlock(objective.unlock_on_success_id)`. The unlock is persisted but not shown to the player (6B adds reveal UI).

---

## SaveManager

Autoload at `res://src/SaveManager.gd`. Manages two resources per save slot:

### ProgressionState

`res://src/resources/ProgressionState.gd` — extends `Resource`:

```gdscript
@export var completed_objective_ids: Array[String] = []
@export var unlocked_content_ids: Array[String] = []
@export var last_run_difficulty_score: int = 0
```

`is_unlocked(content_id: String) -> bool` checks `unlocked_content_ids`.

Default unlocked content (fresh game): all 12 officer variants, 1 doctrine, 2 upgrades, 3 objectives — enough to play.

### Save Paths

Single slot for MVP (slot_id = `"default"`):

```
user://saves/default/progression.tres    # persistent across runs
user://saves/default/run_state.tres      # current in-progress run, deleted on run end
```

### SaveManager API

```gdscript
func load_progression() -> ProgressionState
func save_progression(state: ProgressionState) -> void
func save_run_state(state: ExpeditionState) -> void
func load_run_state() -> ExpeditionState  # returns null if no run in progress
func delete_run_state() -> void
func record_objective_complete(objective_id: String) -> void
```

`load_progression()` returns a default `ProgressionState` with all MVP content unlocked if no file exists.

---

## Content Requirements

### Officer .tres Files (12)

Two variants per role × 6 roles = 12 officer content files. Each requires:
- `id`, `display_name`, `category = "officers"`
- `role: String` (one of: `first_lieutenant`, `master`, `gunner`, `purser`, `surgeon`, `chaplain`)
- `starting_effects: Array[EffectDef]`
- Appropriate `incident_weight_modifiers` and `council_proposals` where relevant

### Ship Upgrade .tres Files (3–4)

Existing `ShipUpgradeDef` files, extended with any missing `EffectDef` arrays. At least 3 to give the player a meaningful choice across 2 upgrade slots.

### Objective .tres Files (6–9)

At least 6 objectives across `survey`, `condition`, and `recover` types, spread across difficulty tiers 1–3. `success_condition` uses existing `ConditionDef` evaluation. At least 3 must have `unlock_on_success_id` populated to exercise the unlock path.

### GameConstants.gd (1 file)

As described above. All existing magic numbers in simulation code replaced.

### SaveManager.gd + ProgressionState.gd (2 files)

As described above.

### Scenes (3)

- `PreparationScene.tscn` + `PreparationScene.gd`
- `RunScene.tscn` + `RunScene.gd` (wraps existing expedition logic)
- `RunEndScene.tscn` + `RunEndScene.gd`

---

## 6A vs 6B Boundary

### In 6A

- Full preparation → run → end screen loop
- `ProgressionState` written/loaded correctly
- `GameConstants` as single balance source
- Mutiny/breakdown/completion all trigger run end
- Objective success/failure evaluated and unlock recorded
- Difficulty score calculated and stored

### Deferred to 6B

- **Admiralty report framing** — narrative debrief letter generated from `stress_indicators`
- **Persistent officer relationships** — cross-run trust/resentment memory
- **Admiralty political bias** — shortlist weighting by faction standing
- **Full difficulty gating** — `last_run_difficulty_score` gates content unlocks
- **Unlock reveal UI** — showing the player what they've unlocked and why after a run
- **Multi-slot saves** — single `"default"` slot only in 6A

---

## Testing

### Stage 6A Test File

`game/test/Stage6ATest.gd` — extends `Node`, runs headless assertions:

- `ProgressionState` saves and loads correctly
- `SaveManager.load_progression()` returns default unlocked state when no file exists
- `ExpeditionState.create_from_config()` applies officer starting effects correctly
- `GameConstants` values are accessible from GDScript
- Mutiny triggers when command ≤ threshold and burden is high
- Breakdown triggers when burden hits 100
- Run end sets `run_end_reason` correctly for all three causes
- Objective success condition evaluates and records unlock
- Difficulty score formula produces expected output for known inputs

### Manual Testing

- Full loop: `PreparationScene` → configure officers/doctrine/objective → Set Sail → run to completion → `RunEndScene` → Return → `PreparationScene`
- Mutiny path: set initial state with low command, run to mutiny trigger
- Breakdown path: set initial state with high burden, run to breakdown
- Save persistence: complete a run, restart game, verify `ProgressionState` loads
