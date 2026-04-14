# Emergent Officers & Expedition Scars — Design Spec

## Overview

This spec defines two interlocking systems: **procedurally generated officers** and **expedition scars**. Together they answer the question "how does each run tell its own story?" not through generated prose, but through characters that carry mechanical history.

The design intent is player attachment through shared authorship. The player doesn't just pick stats — they pick a person whose background is legible, watch that person survive (or not) the choices the player made, and watch them change because of it. Losing an experienced officer after three runs should feel like a genuine loss.

This is not a simulation of individual crew members. The crew remains group-level. This system is an enrichment of the existing **officer/notable layer** — the named texture above the crew mass.

**Reference games:** Darkest Dungeon (quirk accumulation, permanent death stakes), Kingdom Death: Monster (survivor memory across campaign), FTL (attachment through shared danger), Mewgenics (combinatorial generation creating anecdote).

---

## 1. Officer Generation

### Intent

Officers are procedurally assembled at the point they enter the Admiralty pool. The goal is **coherence, not surprise**: the name, background, role, and traits should feel like they belong to the same person. A player looking at a generated officer should be able to form a mental model of who this person is before hiring them.

This system **fully replaces** the authored OfficerDef `.tres` approach. There are no fixed named officers alongside generated ones — every officer in the pool is generated. Keeping both would be pointless complexity. The authored content pools (names, fragments, traits) are what give the generator its character; those are where authorial voice lives, not in hand-crafted individual records.

### Generation inputs

Each officer is assembled from four layers that must be consistent with each other:

**Role** — drawn from the authored role list (`surgeon`, `bosun`, `purser`, `chaplain`, `first_mate`, `lieutenant`, etc.). Role is selected first; all other layers are role-constrained.

**Name** — drawn from a role-appropriate or nationality-appropriate name list. Names are period-authentic (age-of-sail English, with room for Irish, Scottish, and Dutch names reflecting historical crew composition). Name lists are authored data and can be expanded without code changes.

**Background fragment** — a short assembled sentence from authored parts. Structure: `[Origin] · [Past service or defining event] · [Current reputation or known flaw]`. Example outputs:
- *"Devon-born. Served three years under Admiral Pemberton before court-martial for insubordination. Known for accuracy; known for grudges."*
- *"Scottish. Sailed merchant routes to the Indies. Drinks before noon, never after — so far."*
- *"No family record. Recommended by a man who has since died. Quiet."*

Background fragments are assembled from authored pools per role, not generated from scratch. Each pool has three independently authored sub-lists (origins, past service events, reputation/flaw lines) that are combined at generation. The pools should be written to be evocative and specific, not generic. Ambiguity is a feature — "recommended by a man who has since died" implies a story the player will fill in themselves.

**Starting trait combination** — 2–3 traits drawn from role-appropriate pools, with a coherence filter. Traits should not contradict each other and should loosely support the background fragment. A surgeon with `drinks_before_noon` should not also have `strict_self_discipline`. The coherence filter is implemented through exclusion tags on each trait: a trait declares which other traits it cannot appear alongside.

Traits split into two categories following the existing `OfficerDef` model:
- `known_traits` — visible to the player from hire
- `hidden_traits` — revealed through incidents during the run

### Content pools are data-driven and independently expandable

All generation source material lives in authored data files — not in code. Expanding the name pool, adding a new background fragment, or introducing a new trait requires only editing content files. No code changes are needed.

Each pool type is a separate authored list:
- **Name pools** — one list per role (or per nationality archetype, shared across roles). Adding a name = adding a line.
- **Background fragment pools** — three sub-lists per role (origins, past service events, reputation lines). Adding a new background variation = adding one entry to one sub-list.
- **Trait pools** — one list per role, each entry carrying: trait id, display name, whether it is `known` or `hidden`, and an exclusion tag list. Adding a new trait = adding one entry.

The generation system reads these pools at runtime. The format should be chosen for ease of authoring: JSON arrays are appropriate given their simplicity and the volume of short text entries. The existing `.tres` resource format is better for structured objects with many typed fields (like `IncidentDef`); flat text pools are better as JSON.

### Coherence is the priority

The generation system does not need to be complex. A small, well-authored set of pools with a basic coherence filter will produce more convincing results than a complex generator with thin source material. Write the pools carefully; the system handles assembly.

---

## 2. The Admiralty Pool

### Structure

The pool is organised **by role**. Each role maintains **2–3 candidates** at any time. The player picks one candidate per role they want to fill — they do not have to fill every role, but the choice within each role is always meaningful.

Approximate pool size with 6 roles at 2–3 candidates each: **12–18 officers**. This is the number that makes choice feel real. A pool of 6–8 total with no role structure produces either role gaps (no surgeon available) or role gluts (three surgeons, one bosun).

Hiring: before each expedition, the player reviews all role slots and selects one candidate per role. Unhired candidates remain in their slot for the next expedition — they do not disappear if passed over.

### Role balance guarantee

The generator enforces role balance. When replenishing, it checks each role's current candidate count and generates for the role with the fewest candidates first. A role can never drop below 1 candidate; replenishment targets 2–3. This ensures the player always has at least one option per role, and usually a genuine tradeoff within the role.

### Replenishment

When a candidate slot is vacated (officer death, desertion, dismissal, retirement, or the player hired them), a new officer is generated for that role. The pool therefore always offers a mixture of experienced survivors and untested unknowns within each role — this is the core tension of the hiring choice.

### Pool visibility

The player sees all candidates organised by role at the Admiralty preparation stage. Each officer shows:
- Name, role, background fragment
- Known traits
- Competence and loyalty as word-bands, not raw numbers: *unreliable / steady / dependable / exceptional*
- Run history: runs survived, and a short list of notable expedition events that left visible scars

Hidden traits and scar flags not yet surfaced remain hidden at hire. The player is hiring with incomplete information, and that uncertainty is intentional.

---

## 3. Expedition Scars

### Intent

Scars are the mechanical traces of what an officer lived through. They accumulate during a run and are written back to the officer's persistent record at run end. They are the primary mechanism for emotional attachment — an officer with three runs of shared history is not replaceable.

Scars are **not purely negative**. An officer who survived a brutal run and whose advice was heeded is more capable and more committed. The asymmetry is what makes the system interesting: experienced officers are more useful *and* more complicated.

### Three forms a scar takes

**1. Trait tags (primary form)**

A scar is added to `known_traits` or `hidden_traits` on the officer's persistent record. Since the existing incident system already reads officer traits through `required_conditions` and `cast_roles`, most scar-driven behaviour flows through the existing architecture without new systems.

Example scar traits:
- `complicit_in_concealment` — officer was ordered to cover up an incident
- `witnessed_broken_promise` — officer was present when the captain publicly broke a promise
- `publicly_overruled` — officer's advice was refused in front of crew
- `survivor_of_high_losses` — officer survived a run where crew mortality was high
- `respects_hard_authority` — officer saw a brutal call vindicated
- `ration_crisis_veteran` — officer managed a supply crisis; now reads food incidents differently
- `haunted` — applied after high crew loss; officer carries visible grief

Some scar traits surface immediately as `known_traits` (the crew can see the officer has changed). Others are `hidden_traits` revealed through future incidents — the resentment that only shows when tested.

**2. Stat drift (secondary form)**

`competence` and `loyalty` nudge by ±1 after a run based on aggregate run outcomes. Drift is small per run but accumulates over a campaign.

Drift triggers (examples):
- Officer's advice was followed and outcome was positive → loyalty +1
- Officer was overruled in a critical incident → loyalty -1
- Officer's role was relevant to a crisis that was handled well → competence +1
- Officer was blamed for a failure (justified or not) → competence -1

Stats are clamped to the 1–5 range. Drift is not telegraphed explicitly — the player notices the officer has changed when they rehire them and check the word-band display.

**3. Cross-run memory flags (narrative form)**

Certain scar events write a persistent flag to the officer record rather than (or in addition to) a trait tag. These flags can be checked by future incident conditions, allowing incidents to explicitly reference shared history.

Example: if `purser_complicit_concealment` is on an officer's persistent record and they're hired for a new run, an incident condition can check this flag and give the purser different dialogue in any stores-related incident — they remember, and the player knows they remember.

This extends the existing memory flag system, which currently dies with each run, to allow selected flags to persist with officers across runs.

### Scar accumulation timing

Scars are flagged **during the run** (provisional) and **committed at run end** (persistent). This means:
- Incidents fired later in the same run can read provisional scars from earlier in the run (consistency within a run)
- At run end, provisional scars are reviewed and written back to the officer's pool record
- At the start of the next run, the committed scars are present from hire

### What triggers a scar

Scars are triggered by specific incident outcomes and run-end stress indicator thresholds, not by vague time-passing. Each incident choice that should create a scar declares it explicitly in `IncidentChoiceDef` — the same way choices declare effects on Burden and Command today.

Run-end scar checks use `stress_indicators` already tracked in `ExpeditionState`:
- `crew_losses` above threshold → `survivor_of_high_losses` on all surviving officers
- `min_command` fell below threshold → `witnessed_authority_collapse` on all surviving officers
- `peak_burden` above threshold → `endured_extreme_hardship` on all surviving officers

### Officer death and permanent loss

An officer can be permanently lost through:
- Death during a crisis incident (an authored incident outcome)
- Desertion (runs away during high Burden + low Command conditions)
- Court-martial or dismissal (player choice in a disciplinary incident)
- Retirement (after N runs survived, an authored officer may exit the pool with a ship log note)

Permanent loss is devastating precisely because scars have accumulated. The system deliberately creates situations where losing an officer feels like losing a person.

---

## 4. Fit With Existing Architecture

This system does not require new core simulation machinery. It extends what already exists:

| Existing system | Change |
|---|---|
| `OfficerDef` | Still the runtime record for an officer, but now always produced by the generator rather than hand-authored. Scar traits are written back to this record at run end. |
| `IncidentDef` conditions | Can already check officer traits; no change needed. |
| `IncidentChoiceDef` effects | Scar-trigger effects added as a new effect type: `add_officer_scar`. |
| `ExpeditionState` memory flags | Subset of flags become persistent officer flags at run end. |
| `ProgressionState` | Stores the pool: all candidate `OfficerDef` records, their scar histories, and run survival counts. |

The procedural generation system is new but self-contained. It reads authored JSON content pools and produces `OfficerDef` records. Once a record exists in the pool, the rest of the game — incidents, simulation, UI — treats it identically to how it would treat any officer. The generator is invisible to those systems.

Existing authored `OfficerDef` `.tres` files are superseded by this system and should be removed when this feature is implemented.

---

## 5. Scope Boundaries

### In scope for this design

- Procedural officer generation (name, background, starting traits — coherent and role-consistent)
- Admiralty pool organised by role, 2–3 candidates per role, with role-balance guarantee and replenishment
- Data-driven content pools (names, background fragments, traits) expandable without code changes
- Three scar forms: trait tags, stat drift, cross-run memory flags
- Scar triggers from incident choice outcomes and run-end stress thresholds
- Permanent officer loss through authored incident outcomes

### Explicitly deferred

- **Officer-to-officer relationships** — faction dynamics, rivalries, friendships between officers. High complexity, not load-bearing for attachment.
- **Officer ambitions and hidden agendas** — officers with secret goals. Interesting but requires a deeper advisory simulation. Fits a future pass.
- **Officer aging and mandatory retirement arcs** — narrative exits beyond permanent loss. A later enrichment.
- **Natural-language background generation** — the background sentence is assembled from authored fragments. Full NLP generation is out of scope for a single developer.
- **Player-written annotations** — players labelling officers with personal notes. Nice UX, separate feature.
- **Officer promotion or rank change** — officers changing role over a campaign. Deferred; role is set at generation.

### Content volume guidance

For the first implementation pass, the authored pools that feed generation should be small but high quality:

- **Names:** 8–12 entries per role (or per nationality archetype). Enough that repeated names are rare within a session.
- **Background fragments:** 4–6 origins, 4–6 past service events, 4–6 reputation lines per role. Combinatorial — 4×4×4 = 64 possible backgrounds per role before any repetition is noticeable.
- **Starting traits:** 8–12 role-appropriate entries per role, each with coherence exclusion tags. Enough that two candidates of the same role rarely feel identical.
- **Scar traits:** 10–15 definitions covering the most common run events, each with a clear trigger condition.

Do not build large pools before the loop proves the concept. The generation system must be extensible by content alone — adding new entries to any pool requires only editing the authored data files, not touching code.
