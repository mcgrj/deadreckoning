# Dead Reckoning: Impactful Choices Design

**Date:** 2026-04-14
**Status:** Approved
**Scope:** All decision layers — route selection, standing orders, incident resolution, Admiralty prep

---

## Purpose

This document defines the unified framework for designing compelling, non-trivial choices across every layer of Dead Reckoning. It is a design reference to be consulted whenever new content is authored — incidents, standing orders, officer definitions, ship upgrades, Admiralty objectives, or route nodes.

The core premise: **you cannot solve problems in Dead Reckoning, only defer or transform them.** Every positive action takes a loan against a specific future vulnerability. No choice should be easy.

---

## 1. The Authoring Test

Before any choice is finalised — incident option, standing order, route fork, officer selection, prep purchase — it must pass three gates:

### Gate 1: Value Gate
Does this choice put two things the player simultaneously cares about in direct opposition?

Not Burden vs Command as abstract meters, but something the player *holds as a value*: mercy vs order, honesty vs stability, loyalty vs duty, individual welfare vs collective survival.

If a choice only asks "pay resource X to get benefit Y," it fails the value gate. It must ask "which thing I care about am I willing to betray?"

### Gate 2: Debt Gate
Does taking the positive of this choice plant a specific, named future vulnerability?

Not "bad things might happen" but a concrete mechanism with a named debt type (see Section 3). The debt type must be identifiable at authoring time and a specific counter-incident or consequence must be designed to collect it.

### Gate 3: Information Gate
Is the consequence *partially* legible before the choice?

The immediate cost is always visible. A competent officer hints at the medium-term risk. The delayed consequence emerges only through play. If the full consequence is visible, there is no tension. If none of it is visible, the choice is arbitrary punishment.

**If a choice fails any gate, it must be redesigned — not rejected.** A failed value gate means mechanical filler. A failed debt gate means an inconsequential choice. A failed information gate means an unfair surprise.

---

## 2. Value Collision Pairs

Dead Reckoning's drama lives in six recurring tensions. Every choice across all layers should map to at least one of these, ideally two in combination.

| Tension | What the player sacrifices either way |
|---|---|
| **Command vs Burden** | Enforce authority → crew resentment rises. Ease up → discipline erodes. |
| **Individual vs collective** | Save one officer's reputation → crew loses trust in fairness. Sacrifice them → loyalty risk. |
| **Honesty vs stability** | Tell the crew the truth about supplies → Burden spikes. Conceal it → Command risk when it surfaces. |
| **Mercy vs order** | Pardon the offender → precedent set, discipline weakens. Punish harshly → Burden rises, resentment deepens. |
| **Short-term survival vs long-term trust** | Ration cut now → food preserved, Burden spikes. Don't cut → food runs out later, crisis is worse. |
| **Speed vs endurance** | Push hard → reach the node faster, crew exhausted. Go slow → crew recovers, supplies drain further. |

---

## 3. Debt Taxonomy

Every choice that passes the debt gate creates one of four debt types. Authors must name the debt type explicitly so callbacks can be designed to match.

### Expectation Debt
A player action establishes a crew expectation. Violating it later triggers a sharper incident than would otherwise fire.

*Example:* Distributed rum ration once → crew expects it → running dry triggers an incident it would not otherwise, at higher Burden impact.

### Trust Debt
A promise or repeated pattern is established. Breaking it damages Command non-linearly — more than a baseline loss.

*Example:* Told the crew landfall in three days → missed it → Command loss is doubled because the promise was made publicly.

### Resentment Debt
Suppressed Burden does not disappear. It accumulates behind a threshold. A single later provocation releases it all at once.

*Example:* Harsh discipline holds order for two acts → resentment is banked → a minor injustice in Act 3 releases all banked resentment simultaneously.

### Exposure Debt
A concealed truth is stored as a memory flag. A later incident has a chance to surface it, compounding damage beyond what the original incident would have caused.

*Example:* Covered up the purser's miscount → audit incident in Act 2 can expose it → Command loss is the original deception plus the cover-up.

---

## 4. Information Asymmetry

Information asymmetry is the delivery mechanism that makes debt feel fair rather than arbitrary. Every choice has three tiers of visible consequence:

| Tier | What is shown | How it is shown |
|---|---|---|
| **Immediate** | Direct state changes | Effects preview on choice (always visible) |
| **Medium-term** | Debt type hint, risk signal | Officer risk text, scaled by officer competence and loyalty |
| **Delayed** | Consequence that only emerges in play | Memory flags, counter-incident triggers, callback incidents |

The player should understand *why* an outcome happened after the fact. They should feel uncertainty *before* the decision. This distinction — retrospective clarity, prospective fog — is what makes loss feel like learning rather than punishment.

---

## 5. Run Structure and Decision Budget

### Target Run Length
**30 minutes** is the design target. 20 minutes represents a fast or failed run. 40 minutes is a slow, careful run. The original 45–60 minute target has been revised down.

*Rationale:* Cognitive research indicates sustained high-stakes decision-making degrades after 20–25 minutes. FTL, the closest structural analogue, was explicitly designed as short-form (PC Gamer 2012 Best Short-Form Game). At 30 minutes, players finish a run and immediately want to process it or retry — the optimal loop for replayability.

### Three-Act Arc

**Act 1 — Control (~8 minutes)**
Ship leaves port. Resources feel adequate. First standing orders set. First route segment chosen. 1–2 low-pressure incidents. This is the *investment phase* — the player plants seeds for the run's arc. Debts taken here must close in Act 2 or Act 3.

**Act 2 — Fracture (~14 minutes)**
Resources start biting. Standing orders from Act 1 create counter-pressures. 2–3 harder incidents fire. The officer council becomes politically loaded. The player is managing problems they partly created. This is the longest act because tension compounds here.

**Act 3 — Collapse (~8 minutes)**
The run converges on its ending. 1–2 high-weight decisions remain, carrying the accumulated consequence of Acts 1 and 2. Memory flags from earlier surface. The ship log is writing itself.

### Decision Budget

| Decision type | Count per run | Timing |
|---|---|---|
| Admiralty prep | 1 | Before the run |
| Route selection | 2–3 | Between acts / segments |
| Standing orders | 3 sets (one per act) | Before each segment |
| Incident choices | 5–7 | Distributed across all acts |
| **Total** | **~12–15** | — |

Every decision must earn its place. There is no room for filler in a 30-minute run.

### Debt Window Rule
**All debts planted within a run must be collected within the same run.** Memory flags should trigger callbacks within 2–4 nodes of being set. Standing order consequences should hit within the same act or the following one. A gun placed on the mantle in Act 1 fires before the run ends.

The Admiralty layer carries run-to-run debt — reputation, political consequences, exposure from filed reports. The within-run arc must be complete and satisfying on its own.

---

## 6. Layer-by-Layer Application

### Route Selection

Route selection is primarily a **short-term survival vs long-term trust** and **speed vs endurance** collision. The choice is never "safe path vs dangerous path" — it is "which kind of problem do I want?"

Every route fork offers:
- A shorter path with a visible cost (crisis node, hazard marker, omen)
- A longer path with an invisible cost (more ticks = passive Burden rise, supplies burn, fatigue accumulates, expectation debt builds)

The player who takes the "safe" long route is not playing safely. They are taking expectation debt (crew expects a rest at landfall that may not come) and resentment debt (passive Burden from grinding ticks means any incident that fires hits harder).

**Authoring rule:** A shorter path makes the threat legible. A longer path makes the threat gradual. Neither is safe.

Route visibility should show enough to make the tradeoff felt — approximate ticks, weather hint, node category — but not enough to defuse it. The player should be able to articulate why they chose a path and be wrong about it.

---

### Standing Orders

Standing orders are the primary expectation debt mechanism. Every order tells the crew something about how this voyage is run. That pattern, once established, becomes a liability if broken.

**Authoring rule:** Every order plants the seed of its own counter-incident. The benefit is immediate. The counter-incident is named at authoring time and fires if the order's expectation is violated or if the order's natural pressure is not relieved.

| Order | Immediate benefit | Debt type | Counter-incident trigger |
|---|---|---|---|
| Tighten rationing | Food preserved | Expectation debt | Any future food incident hits at +Burden because the crew was already hungry |
| Double watches | Sabotage/theft risk reduced | Resentment debt | Fatigue incident becomes eligible; if it fires, Burden spike is larger than baseline |
| Hold prayer | Burden reduced (pious crew) | Exposure debt | Cynical officer dissent is stored; surfaces as Command loss if a later omen is dismissed |
| Distribute rum ration | Burden reduced, morale spike | Expectation debt | Running out of rum now triggers an incident it would not otherwise |
| Suppress rumors | Panic incident suppressed | Exposure debt | Suppressed rumor compounds into a larger incident if an omen or crisis fires later |
| Share officer comforts | Command stabilized | Trust debt | Captain later taking comforts for themselves doubles Command loss |

Standing orders must also map to value collision pairs. "Hold prayer" forces a mercy vs order tension with cynical officers. "Suppress rumors" forces honesty vs stability. The player should feel the values at stake when choosing, not just the resource cost.

---

### Incident Choices (Officer Council)

The officer council is not a menu of mechanical options. It is a **council of competing value systems**. Each officer proposes what their values say is correct. They are each right within their framework. They are each wrong in a different way.

**Authoring rule:** Each officer option must be correct within its value system and costly within a different value system. No option is objectively better. The player's leadership pattern (tags) determines which cost they are most exposed to.

**Example — Ration theft incident:**

| Officer | Proposal | Value system | Immediate cost | Debt planted |
|---|---|---|---|---|
| Bosun | Make an example publicly | Order | Burden +4 | Resentment debt: fear suppresses dissent, banks resentment |
| Surgeon | Reduce labor first — the man is starving | Welfare | Supplies −2 | Trust debt: crew expects mercy standard going forward |
| Purser | Audit stores before judgment | Fairness | Time cost, possible self-exposure | Exposure debt: audit may reveal purser's own negligence |
| Chaplain | Allow confession without naming names | Meaning | Command −2 (captain looks weak) | Expectation debt: crew expects absolution to be available again |
| First mate | Conceal it until landfall | Stability | None immediately | Exposure debt: if crew discovers the captain knew, Command loss is severe |
| Captain acts alone | No officer option | Authority | Command −1 (officers feel bypassed) | Trust debt: repeated bypassing erodes officer loyalty |

**Information tiers on every option:**
- The `effects_preview` field shows immediate visible cost: "Burden +4, Command −1"
- The `risk_text` field (scaled by officer competence) hints at the medium-term debt: "the crew won't forget this"
- `memory_flags_set` on selection carry the delayed consequence, surfacing only when a later incident references them

**Leadership pattern interaction:** The player's accumulated leadership tags affect how legible each option's real cost is. A captain with a "merciful" tag gets clearer surgeon hints about trust debt. A captain with a "harsh" tag gets clearer bosun warnings about resentment debt. Playing against your established pattern is always more opaque — by design.

---

### Admiralty Prep

Admiralty prep is where value collision operates at the meta-level. The player is not choosing between good and bad options — they are choosing which *type of run* they are signing up for. Each prep selection pre-loads a specific value tension into the voyage.

**Authoring rule:** Every prep selection makes one value collision easier to navigate and one harder.

| Selection | Easier collision | Harder collision |
|---|---|---|
| Veteran bosun | Harsh/merciful (bosun absorbs discipline pressure) | Honest/deceptive (bosun publicly challenges cover-ups) |
| Popular surgeon | Mercy/order (crew forgives hardship if surgeon trusted) | Individual/collective (surgeon demands resources for sick even when ship needs them elsewhere) |
| Pressed crew | Speed/endurance (more labor) | Command/Burden (lower starting Command, resentment banked from day one) |
| Expanded spirit locker | Expectation debt management (rum available longer) | Expectation debt risk (crew expects it longer; running out is worse) |
| Pious charter | Omen/fear incidents defused | Honest/deceptive (chaplain makes concealment more costly) |

---

## 7. Officer Selection Mechanics

### Quality-vs-Debt Spectrum

Every crew always has a full complement of officer roles. The decision is not whether to have a Master but **which Master**. Each officer slot presents a quality-vs-debt tradeoff:

- A **high-quality officer** gives better, more accurate intelligence in their domain and handles incidents in their area more reliably — but carries a named flaw that plants a specific debt
- A **lower-quality officer** gives reduced or less accurate intelligence and handles incidents less reliably — but brings no planted debt

### Officer Information Domains

Different officer roles unlock different types of information about the objective and route. The quality of the officer in that role determines the fidelity of that intelligence.

| Officer role | Information domain |
|---|---|
| Master / Navigator | Route detail — tick distances, hazard marker accuracy, hidden node categories |
| Purser | Supply opportunity visibility — what resources may appear at nodes |
| Surgeon | Crew risk forecasting — Burden trajectory, sickness probability on this route |
| Chaplain | Omen/threat interpretation — omen nodes partially revealed rather than "?" |
| Bosun | Discipline risk signals — social incident probability hints |

### Budget Constraint

Officers are selected within a fixed Admiralty prep budget. Taking an expensive experienced officer in one slot means accepting a cheaper officer elsewhere. The player decides not just which officer quality they want per slot, but **where they want their intelligence clarity and where they are willing to fly partially blind.**

### Known / Rumoured / Hidden Trait Tiers

Officer flaws are not always fully disclosed at hire time. Every officer has a trait disclosure level:

**Disclosed:** The flaw is on record. The player knows the Master drinks before hiring him. The tradeoff is fully legible. Typical of officers with a long naval history or prior scandals.

**Rumoured:** Something is mentioned but unconfirmed. The Purser "has had questions raised about his accounting before." Could be nothing. Could be worse than expected. The player is taking an information risk alongside the quality tradeoff.

**Hidden:** No indication at hire time. The trait surfaces only under specific in-voyage conditions — typically when a relevant incident fires or when the voyage reaches a threshold state.

**The known-devil dynamic:** An officer sailed with on a previous expedition has a fully revealed record — their hidden trait is now disclosed. A new officer is a gamble. This creates a meta-progression tension: take familiar officers with known debts, or try new ones with unknown risks and potentially better upside. Experienced players learn the officer pool across runs, which is the knowledge accumulation that drives long-term replayability.

**Accuracy vs volume:** A lower-quality officer may show *fewer* details in their domain. A compromised or flawed officer — particularly one whose debt has been triggered mid-voyage — may show details that are *wrong*. The alcoholic Master's charts are not always inaccurate, but if a drunkenness incident fires and is not resolved, his reliability in a subsequent navigation incident degrades. His flaw is dormant until the debt is called.

### Pre-Voyage Promises to Officers

The promise mechanic extends into the prep layer. Some officers agree to sail on terms — the captain must make a promise to secure their service. These promises are mechanically tracked through the voyage using the same promise system as in-voyage promises.

*Examples:*
- Alcoholic Master: will sail if the captain promises not to restrict spirit locker access during the voyage
- Veteran Bosun: will sail if the captain promises pressed men will be disciplined by the book
- Popular Surgeon: will sail if the captain promises the sick bay will not be stripped for cargo space

**Design intent:** The value collision is present before the route is even seen. The player has already made a promise that will create pressure. The debt is real from the first screen, not from the first incident.

Pre-voyage promises follow the same rules as in-voyage promises: making a promise raises Command immediately or secures the officer, keeping it reinforces Command, breaking it damages Command and creates a run memory flag. The difference is that pre-voyage promises are made with full knowledge of the officer's disclosed traits — and no knowledge of their hidden ones.

### Pre-Departure Officer Stances

Before departure, one or two officers register a pre-departure stance on the objective, route, or a visible threat. This uses the existing officer council architecture at the prep stage.

*Examples:*
- The experienced Bosun: *"Sir, I've sailed those waters. The omen node on the northern route is not what the charts suggest."*
- The green Surgeon: *"I'm not certain I have enough medicine for a long passage, sir."*
- The ambitious Lieutenant: *"The Admiralty objective leaves us exposed on the southern flank. I recommend we reconsider the route."*

**Design intent:** Officers feel like characters with opinions before the voyage starts — not stat modifiers revealed at incidents. Pre-departure stances plant a narrative hook that pays off when the officer's warning proves right or wrong during the voyage. A Bosun who warned about the omen node and was ignored has a different incident-council dynamic than one who said nothing.

Pre-departure stances are not mandatory guidance — they are information signals with a source and a bias. The Bosun's concern about the omen route may reflect genuine experience or his own superstition. The Surgeon's uncertainty may reflect genuine unpreparedness or excessive caution. The player reads the officer, not just the message.

---

## 8. Authoring Checklists

### For every choice across all layers

- [ ] Does this choice force a collision between two values the player holds simultaneously? (Value Gate)
- [ ] Does taking the positive option plant a specific named debt? (Debt Gate)
- [ ] Is the immediate cost visible? Is the medium-term risk hinted at by an officer? Does the delayed consequence emerge through play? (Information Gate)
- [ ] Is there a dominant strategy — one option that is always better? If so, redesign.
- [ ] Does the counter-incident or debt callback close within the same run?

### For standing orders

- [ ] What crew expectation does this order establish?
- [ ] What is the named counter-incident if that expectation is violated or if the order's pressure goes unrelieved?
- [ ] Which value collision pair does this order engage?
- [ ] Does this order interact with any officer's flaw or disclosed trait?

### For incident choices

- [ ] Does each officer option reflect their value system correctly?
- [ ] Is each option wrong in a different way from the others?
- [ ] What memory flag does each option set?
- [ ] What counter-incident or callback does each memory flag enable?
- [ ] Is the `risk_text` calibrated to officer competence — clearer from a trusted, skilled officer; vaguer from a compromised or inexperienced one?

### For officer definitions

- [ ] What is the officer's quality level in their information domain?
- [ ] What is their disclosed trait (if any)?
- [ ] What is their rumoured trait (if any)?
- [ ] What is their hidden trait, and under what condition does it surface?
- [ ] What pre-voyage promise do they request (if any)?
- [ ] What pre-departure stance do they register on a given objective type?
- [ ] What debt type does their flaw plant, and what is the named counter-incident?

### For Admiralty prep options

- [ ] Which value collision does this option make easier?
- [ ] Which value collision does this option make harder?
- [ ] What new problem does this option create? (The design rule: every unlock asks what new problem it introduces — not what it prevents.)
- [ ] Does this option interact with any officer's trait or the crew background?

---

## 9. Sources and Research Grounding

The framework synthesises findings from the following:

- **Sid Meier (GDC 2012):** No single option clearly dominant; options not equally attractive; player can make an informed choice. All three must be true.
- **Frostpunk — creeping normality:** Each locally justified choice escalates the aggregate. Authority is mechanically useful and morally expensive.
- **This War of Mine:** Scarcity as multi-meaning. Resources with multiple uses generate moral weight without explicit authoring. Failure becomes authored material.
- **Darkest Dungeon:** Loss is progress. Characters break in distinct ways. Attachment comes from investment, not backstory.
- **FTL:** Short-form run design. Knowledge accumulation across runs drives replayability. Emergent attachment from thin characters.
- **Sunless Sea:** Officer secrets and hidden traits as narrative catalysts. Partial information as atmospheric mechanic.
- **Academic research (CHI Play 2018, SAGE 2019, ResearchGate 2024):** Most memorable choices are good-vs-good or survival-vs-virtue, not good-vs-evil. False affordances frustrate players. Agency as commitment to meaning.
- **Roguelike design (Grid Sage Games / Cogmind):** Richest tradeoffs operate at route/faction scale. Short-term vs long-term is the most potent tradeoff category.
