# Emergent Officers & Expedition Scars — Design Spec

## Overview

This spec defines two interlocking systems: **procedurally generated officers** and **expedition scars**. Together they answer the question "how does each run tell its own story?" not through generated prose, but through characters that carry mechanical history.

The design intent is player attachment through shared authorship. The player doesn't just pick stats — they pick a person whose background is legible, watch that person survive (or not) the choices the player made, and watch them change because of it. Losing an experienced officer after three runs should feel like a genuine loss.

This is not a simulation of individual crew members. The crew remains group-level. This system is an enrichment of the existing **officer/notable layer** — the named texture above the crew mass.

**Reference games:** Darkest Dungeon (quirk accumulation, permanent death stakes), Kingdom Death: Monster (survivor memory across campaign), FTL (attachment through shared danger), Mewgenics (combinatorial generation creating anecdote).

**Related specs:**
- `2026-04-14-impactful-choices-design.md` — defines officer selection as a quality-vs-debt choice, officer information domains, three-tier trait disclosure, pre-voyage promises, and pre-departure stances. Section 7 of that spec is the design authority for officer choice mechanics; this spec is the authority for how officers are generated and how their history persists.
- `2026-04-14-stage-6b-admiralty-reporting-design.md` — defines `admiralty_bias` and `scandal_flags` in `ProgressionState`. The `officer_accused` bias string reduces available candidates in the accused role's slot. The officer recommendation reward writes a `loyal` starting trait into the run config — the generation system must be compatible with this injection.

**Implementation ordering:** This spec should be implemented before `impactful-choices-design.md`. The impactful-choices officer mechanics (Section 7) assume the procedural pool exists. Pre-departure stances and pre-voyage promises gain their narrative weight from distinct generated identities. Implement the pool and generation system first, then layer the impactful-choices officer mechanics on top.

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

Traits are assigned one of three disclosure tiers at generation (see Section 2.4 for full disclosure model):
- `disclosed` — the flaw is on record; the player sees it at hire
- `rumoured` — something is mentioned but unconfirmed; the player sees a hint, not the trait
- `hidden` — no indication at hire; surfaces only through specific in-voyage incident conditions

**Information domain** — each role grants a specific type of intelligence during the voyage. Domain and domain fidelity (driven by competence) are set at generation and do not change between runs unless competence drifts via scars. See Section 2.3 for the full domain map.

### Content pools are data-driven and independently expandable

All generation source material lives in authored data files — not in code. Expanding the name pool, adding a new background fragment, or introducing a new trait requires only editing content files. No code changes are needed.

Each pool type is a separate authored list:
- **Name pools** — one list per role (or per nationality archetype, shared across roles). Adding a name = adding a line.
- **Background fragment pools** — three sub-lists per role (origins, past service events, reputation lines). Adding a new background variation = adding one entry to one sub-list.
- **Trait pools** — one list per role, each entry carrying: trait id, display name, disclosure tier (`disclosed` / `rumoured` / `hidden`), and an exclusion tag list. Adding a new trait = adding one entry.

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

## 2.3 Officer Information Domains

Each officer role grants a specific type of intelligence about the route and objective. The quality of the intelligence scales with the officer's competence. A compromised or debt-triggered officer may produce inaccurate intelligence in their domain, not just reduced intelligence.

| Role | Information domain |
|---|---|
| Master / Navigator | Route detail — tick distances, hazard marker accuracy, hidden node category hints |
| Purser | Supply opportunity visibility — resource availability at upcoming nodes |
| Surgeon | Crew risk forecasting — Burden trajectory, sickness probability on this route segment |
| Chaplain | Omen/threat interpretation — omen nodes partially described rather than shown as "?" |
| Bosun | Discipline risk signals — social incident probability hints |

Scars from previous runs can modify domain accuracy. A `ration_crisis_veteran` purser reads supply nodes more accurately than a fresh hire. A `publicly_overruled` surgeon may produce pessimistic crew risk estimates — not wrong, but filtered through resentment.

---

## 2.4 Three-Tier Trait Disclosure

Officer traits are not all visible at hire. Every generated officer has a disclosure tier assigned to each of their traits:

**Disclosed** — the trait is on record. The player sees it in the officer card at hire. Typical of officers with a documented naval history, prior scandals, or known reputations. The tradeoff is fully legible before hire.

**Rumoured** — something is mentioned but unconfirmed. The officer card shows a hint — *"questions have been raised about his accounting"* — not the trait itself. The player is taking an information risk. May be worse than expected; may be nothing.

**Hidden** — no indication at hire. The trait surfaces only under specific in-voyage conditions: when a relevant incident fires, when the voyage reaches a threshold state, or when a scar from a previous run has already revealed it. A returning officer's previously hidden traits are fully known — the expedition history is the disclosure mechanism.

**The known-devil dynamic** sits here: a returning officer with accumulated scars is better understood than a fresh hire. The player chooses between familiarity (known debts, known strengths) and the potential upside of an untested unknown. This is the core tension of the hiring choice within each role slot.

---

## 2.5 Pre-Voyage Officer Mechanics

These mechanics are specified in full in `2026-04-14-impactful-choices-design.md` Section 7. This section records the requirements so the generation system produces officers that support them.

### Pre-voyage promises

Some officers require a promise from the captain to accept the commission. These promises are tracked by the existing promise system from the moment of hire, not from the first incident.

Examples:
- An alcoholic Master will sail only if the captain promises not to restrict spirit locker access during the voyage
- A veteran Bosun will sail only if pressed men are promised discipline by the book
- A popular Surgeon will sail only if the sick bay is promised not to be stripped for cargo

The generation system must be able to flag an officer as requiring a pre-voyage promise, and associate a promise id and promise text with that officer record. The promise id connects to the existing `make_promise` / `keep_promise` / `break_promise` machinery in `ExpeditionState`. Promise requirement is set by the trait pool: a trait entry can declare `requires_promise: true` and supply the promise template.

### Pre-departure stances

Before departure, one or two officers register an opinion on the objective, route, or a visible threat. This uses the existing officer council architecture at the prep stage.

Examples:
- *"Sir, I've sailed those waters. The omen node on the northern route is not what the charts suggest."* (Bosun, experienced)
- *"I'm not certain I have enough medicine for a long passage, sir."* (Surgeon, anxious)
- *"The Admiralty objective leaves us exposed. I recommend we reconsider the route."* (Lieutenant, ambitious)

Pre-departure stances are narrative hooks, not mandatory guidance. The officer's competence and disclosed traits colour whether the player trusts the stance. A Bosun warning about an omen node may reflect genuine experience or personal superstition.

The generation system flags whether an officer will generate a pre-departure stance (driven by worldview and role), and the stance template is drawn from the role's authored stance pool. Stances are expandable in the same data files as other pools.

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

As of Stage 7 (delivered), the full simulation stack exists: `ExpeditionState`, `TravelSimulator`, `EffectProcessor`, `ConditionEvaluator`, `OfficerCouncil`, `IncidentDef` / `IncidentChoiceDef` resources, `ProgressionState`, `SaveManager`, `PreparationScene`, `RunScene`, `IncidentResolutionScene`, and `RunEndScene`. This system does not require new core simulation machinery — it extends what already exists.

| Existing system | Change |
|---|---|
| `OfficerDef` | Still the runtime officer record, now always produced by the generator. Gains: `disclosure_tier` per trait, `information_domain` field, `pre_voyage_promise_id` (optional), `pre_departure_stance_pool` (optional), `provisional_scars` array (cleared at run start, committed at run end), `run_history` summary. |
| `IncidentDef` conditions | Can already check officer traits via `required_conditions`; no change needed. |
| `IncidentChoiceDef` effects | New effect type: `add_officer_scar` — names the scar trait and whether it is disclosed or hidden. |
| `ExpeditionState` memory flags | Subset of flags promoted to officer-persistent flags at run end. Run config gains `officer_starting_traits` dict for Stage 6B `loyal` trait injection. |
| `ProgressionState` | Extended to store the officer pool: all candidate `OfficerDef` records with scar history and run survival counts. Existing `admiralty_bias` and `scandal_flags` arrays (Stage 6B) continue to be read at prep time; `officer_accused` bias reduces candidate count in the accused role's slot. |
| `PreparationScene` | Extended to show the role-organised officer pool, three-tier disclosure presentation, and pre-voyage promise prompt where required. |
| `SaveManager` | Extended to persist pool state alongside existing progression data. |

The procedural generation system is a new addition but is self-contained: a new `OfficerGenerator` class reads JSON content pools and produces `OfficerDef` records. Once a record enters the pool, all existing systems treat it identically to a hand-authored officer. The generator is invisible to the simulation, incident, and UI layers.

**Authored `.tres` files to be removed on implementation:**

The following hand-authored officer files in `game/content/officers/` are superseded and must be deleted when this feature ships:
`bosun.tres`, `chaplain_pragmatic.tres`, `chaplain_orthodox.tres`, `surgeon.tres`, `surgeon_compassionate.tres`, `surgeon_methodical.tres`, `purser_generous.tres`, `purser_frugal.tres`, `master_experienced.tres`, `master_reckless.tres`, `first_lieutenant_lenient.tres`, `first_lieutenant_stern.tres`, `gunner_reliable.tres`, `gunner_disciplined.tres`

Their content (trait combinations, worldviews, competence/loyalty spreads) should inform the authored generation pools — not be preserved as static records.

---

## 5. Scope Boundaries

### In scope for this design

- Procedural officer generation (name, background, starting traits — coherent and role-consistent)
- Admiralty pool organised by role, 2–3 candidates per role, with role-balance guarantee and replenishment
- Data-driven content pools (names, background fragments, traits, stances) expandable without code changes
- Three-tier trait disclosure: disclosed, rumoured, hidden — with the known-devil dynamic for returning officers
- Officer information domains: each role grants specific intelligence, fidelity scales with competence
- Pre-voyage promises: some officers require a promise as a condition of hire
- Pre-departure stances: officers register opinions on objective or route before sailing
- Three scar forms: trait tags, stat drift, cross-run memory flags
- Scar triggers from incident choice outcomes and run-end stress thresholds
- Permanent officer loss through authored incident outcomes
- Stage 6B compatibility: `officer_accused` bias reduces role candidate count; `loyal` starting trait injection via run config

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
