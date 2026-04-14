# Stage 6B: Admiralty Reporting and Political Memory — Design Spec

> **Spec for:** Stage 6B of the Dead Reckoning implementation roadmap.
> **Builds on:** Stage 6A (PreparationScene, RunEndScene, ProgressionState, SaveManager).
> **Playable outcome:** After a run, the player submits an official report framing, sees one or more Admiralty consequences affect the next prep phase, and accumulates a political reputation across runs.

---

## Overview

Stage 6B closes the between-run loop. Stage 6A delivered preparation → run → run-end. Stage 6B adds:

1. A **report framing step** inside RunEndScene — the player chooses how to represent the expedition to the Admiralty.
2. **Accumulated political memory** in ProgressionState — bias and scandal flags that persist across runs.
3. **Visible consequences in PreparationScene** — the Admiralty letter, greyed constraints, and an allocation panel show the player exactly what their report earned or cost.

The design principle throughout: **surface everything in the Admiralty's voice, not the game's voice.** No mechanical readouts. No tooltip language. The institution responds to your report; the player reads that response.

---

## Scene Architecture

No new scene file. All changes sit in `RunEndScene.gd` and `PreparationScene.gd`.

### RunEndScene additions

Three new elements added to `_build_ui()`:

**1. Factual account section** (`_build_log_narrative()`)

A `RichTextLabel` (replacing plain `Label` for this section) renders a short templated prose paragraph assembled from `final_state` at scene load. Key facts — deaths, Command collapse, mutiny, objective failure — are highlighted in Admiralty gold via BBCode. The rest of the paragraph is unformatted context.

Highlighted facts are driven by thresholds:
- `crew_losses > 0` → "N men are dead."
- `min_command < GameConstants.MUTINY_COMMAND_THRESHOLD` → "Command fell to N."
- `run_end_reason == "mutiny"` → "The crew refused orders on day N."
- Objective failed → "The [objective name] was never completed."

Memory flags surface as additional context sentences where relevant (e.g. an unresolved rum dispute appears if `rum_theft_unresolved` is set).

**2. Report framing section** (`_build_report_section()`)

A set of option cards below the factual account. Each card has:
- **Title** — the framing name ("Suppress the Mutiny")
- **Spin text** — 2–3 sentences: what you claim, what you omit, what you blame
- **Admiralty consequence** — one sentence in the Admiralty's voice describing what they will do: *"The Board grants you authority to manage discipline privately. They will be watching for further irregularities."*

The player selects one option. The "Return to Admiralty" button enables only once a selection is made.

**3. `_selected_framing: String`** — tracks the active selection. On "Return to Admiralty", `SaveManager.record_report_framing()` is called before scene transition.

---

## Report Framing Options

Eight options. **Gating is outcome-first**: options are only shown when relevant to how the run ended, with contributing events as secondary conditions. Two options are always available on a failed run to guarantee the player always has at least two choices.

| Option | Primary gate | Secondary condition |
|---|---|---|
| Suppress the Mutiny | `run_end_reason == "mutiny"` | — |
| Blame the Crew | Run failed (mutiny or breakdown) | Always available on failure |
| Admit Command Failure | Run failed | Always available on failure |
| Blame the Weather | Run failed | Storm/hazard incident fired, or Lee Shore / Unknown zone traversed |
| Conceal Misconduct | Run failed | A misconduct memory flag exists (e.g. `rum_theft_unresolved`, `botched_hanging`) |
| Accuse a Rival Officer | Run failed | An officer-related incident fired AND objective failed |
| Glorify the Sacrifice | Any outcome | `crew_losses > 0` |
| Emphasise Discipline | Run succeeded | A discipline standing order was active (`suppress_dissent`, `strict_watches`) |

On a successful run, "Glorify the Sacrifice" and "Emphasise Discipline" are the available options (subject to gates). "Admit Command Failure" is available on success if the objective was failed despite the run completing.

Framing option definitions live as a static dictionary inside `RunEndScene.gd` — no new Resource type at this stage. Each entry contains: `id`, `title`, `spin_text`, `consequence_text`, `bias_string`, `scandal_flag`.

---

## Admiralty Allocation Rewards

Accepting an Admiralty recommendation in PreparationScene earns a starting bonus for that run. Recommendations and rewards are defined per bias string. Rewards stack — accepting all available recommendations applies all bonuses.

Full compliance (all recommendations accepted) appends `compliant` to `admiralty_bias` on sail, which compounds the Admiralty's expectations for the next commission.

| Recommendation accepted | Starting bonus |
|---|---|
| Recommended objective | +10 starting supplies |
| Recommended doctrine | +1 standing order slot during the run (stored in run config, applied when standing orders are selected) |
| Recommended officer variant | That officer role starts with the `loyal` trait |
| Recommended upgrade | Upgrade is free — does not consume an upgrade slot |

The officer reward is a **role trait**, not a named officer. Stored as `officer_starting_traits: Dictionary` in the run config (`{ "first_lieutenant": "loyal" }`). Applied in `ExpeditionState.create_from_config()`. Compatible with future procedural officer generation.

The allocation panel (right sidebar in PreparationScene) displays accepted rewards in real time and updates as selections change. A warning line — *"The Board's expectations for the next commission will reflect this"* — appears only when all available recommendations are accepted.

---

## Data Model

### ProgressionState additions

```gdscript
@export var admiralty_bias: Array[String] = []   # accumulates e.g. ["blamed_crew", "admitted_failure", "blamed_crew"]
@export var scandal_flags: Array[String] = []    # accumulates e.g. ["scandal_suppressed_mutiny", "scandal_blamed_crew"]
```

Both arrays accumulate across runs. `admiralty_bias` tracks the **pattern of framing** — what kind of captain you present yourself as to the Admiralty. `scandal_flags` tracks **specific things on record** that can surface as incident eligibility modifiers in future runs.

Presence is the check for MVP. Frequency weighting (e.g. blaming the crew three times having stronger effects than once) is available without model changes and can be tuned later.

### SaveManager addition

```gdscript
func record_report_framing(framing_id: String, slot_id: String = SLOT_DEFAULT) -> void
```

Loads progression, appends `bias_string` to `admiralty_bias`, appends `scandal_flag` to `scandal_flags`, saves progression.

---

## Bias Effects in PreparationScene

PreparationScene reads `admiralty_bias` on load and applies effects. Effects are additive — multiple bias strings can be active simultaneously. Each known bias string maps to one effect on one of the four prep choices (objective, doctrine, officers, upgrades).

### Bias effect map

| Bias string | Effect |
|---|---|
| `blamed_crew` | Lenient officer variants greyed out; survey objectives weighted down |
| `admitted_failure` | Reformist officer variant surfaced in first lieutenant shortlist |
| `suppressed_mutiny` | Iron Discipline doctrine highlighted as Admiralty-recommended; survey objectives weighted down |
| `sacrifice_on_record` | Medical Stores upgrade highlighted as Admiralty-recommended |
| `discipline_on_record` | Iron Discipline doctrine highlighted as Admiralty-recommended |
| `concealed_misconduct` | No shortlist change — `scandal_concealed_misconduct` flag makes exposure incidents eligible in-run |
| `weather_blamed` | Harder zone / higher difficulty tier objectives weighted up in shortlist |
| `officer_accused` | Accused officer's role has fewer variants available |
| `compliant` | Harder tier objectives weighted further up; Admiralty letter tone becomes more demanding |

### Admiralty letter

A templated prose paragraph at the top of PreparationScene, generated from the current `admiralty_bias` array. Each known bias string contributes one or two sentences. The letter reads as official Admiralty correspondence — clipped, formal, institutional. It names the consequence before the player sees it in the shortlist.

### Greyed options

Unavailable content stays visible but rendered at reduced opacity with a short in-world explanation: *"The Board has not made pressed men available for this commission."* No mechanical language. The player understands the constraint without seeing the system.

---

## Scandal Flags and In-Run Effects

`scandal_flags` are read by `ConditionEvaluator` and `TravelSimulator` as eligibility modifiers for incident templates. This allows past reports to surface as future in-run events.

Examples:
- `scandal_suppressed_mutiny` → mutiny-escalation incidents gain higher trigger weight in future runs
- `scandal_concealed_misconduct` → exposure/revelation incident templates become eligible
- `scandal_blamed_crew` → crew resentment incidents gain higher trigger weight

For Stage 6B, scandal flag reading is wired up but the incident library is small. The mechanic is established; content payoff expands with future incident authoring.

---

## Visibility Design

The player always understands why the shortlist looks different. The chain is explicit:

> Submit report → Admiralty letter names the consequence → shortlist reflects it → greyed options confirm it

Nothing is hidden. The Admiralty's institutional memory is visible, named, and explained in its own voice. What remains partially visible is the Admiralty's *future* intent — the letter hints at rising expectations without specifying exactly what will be demanded next.

This matches the design doc's visibility model:
- **Visible**: active bias effects, greyed constraints, allocation rewards, letter text
- **Partially visible**: how accumulated bias compounds over multiple runs
- **Hidden**: exact incident trigger weight changes from scandal flags

---

## Excluded from Stage 6B

- Deep Admiralty political simulation or faction modelling
- Full campaign unlock economy
- Multiple simultaneous report framings
- Frequency-weighted bias effects (presence is sufficient for MVP)
- Natural-language report generation
- Balancing for long-term progression
