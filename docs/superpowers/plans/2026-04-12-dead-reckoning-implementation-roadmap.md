# Dead Reckoning Implementation Roadmap

> **For agentic workers:** This is a roadmap, not an execution checklist. Use this to choose and write the next detailed implementation plan. Detailed stage plans should use `superpowers:writing-plans` before implementation and `superpowers:subagent-driven-development` or `superpowers:executing-plans` during implementation.

**Goal:** Preserve the full game design direction and sequence the implementation into small, testable Godot development stages.

**Architecture:** Build the game as a framework-driven Godot project. Core simulation rules should be stable code; content should live in Godot-native custom Resource definitions (`.tres`) backed by typed Resource scripts. Each stage must produce a playable or testable vertical slice and avoid hard-coding content that should be expandable later.

**Tech Stack:** Godot 4.6, GDScript, Godot custom Resources (`.tres`), ResourceLoader/ResourceSaver, Godot editor Inspector workflows, optional JSON only for bulk/table-like data where typed editor workflows are less important.

---

## Game Overview

*Dead Reckoning* is a simulation-driven maritime roguelike about commanding a doomed age-of-sail expedition as authority collapses under hardship.

The player is the captain, not a sailor-avatar and not a direct ship pilot. The player chooses routes, prepares the ship, selects officers and crew, sets standing orders, relies on officer advice, rations supplies, interprets omens, enforces discipline, makes promises, conceals failures, and decides what the crew must endure.

Each run is a finite expedition arc. The ship moves across a Slay the Spire-style branching route map. Major route nodes show visible categories but not exact event content. Squares between nodes are travel ticks where the simulation advances supplies, fatigue, sickness, ship wear, weather exposure, Burden, Command, and incident triggers.

The core promise:

> Choose a route, prepare the ship, survive the ticks, face incidents, preserve or spend your Command, and see what kind of captain the crew says you became.

## Design Pillars To Preserve

**Human Conflict First:** The primary challenge is keeping a crew functional under hunger, fear, exhaustion, grief, class tension, superstition, and command failure. Combat is not the core.

**Emergent Story Through Systems:** Retellable moments should emerge from simulation state and incident templates, such as a superstitious lookout seeing a mermaid, a drunk purser miscounting stores, a fight between midshipmen ending in murder, a chaplain turning an omen into resolve or panic, or an ambitious officer using a failed punishment to question the captain.

**Authority As A Resource:** Command solves problems but changes how command is understood. Harsh discipline can suppress immediate disorder while making the crew brittle. Shared hardship can preserve loyalty but weaken hierarchy. Deception can avoid panic now and become scandal later.

**Framework-Driven Content:** Incidents, major events, upgrades, supplies, standing orders, officer types, crew traits, Admiralty doctrines, route node categories, promises, and unlocks should be data-driven through Godot custom Resources by default.

**Loss Is Story:** Mutiny, abandonment, shipwreck, scandal, rescue, and compromised arrival should become ship-log material and feed the Admiralty layer.

**Elegant Scope:** Do not start as a full colony sim, social graph sim, freeform sailing sim, tactical combat game, and deckbuilder. Build toward the core loop first.

## MVP Core Loop

The first playable version should prove one loop before it proves the whole design:

> Travel creates pressure -> an incident forces judgment -> judgment changes Burden, Command, promises, and memory -> travel resumes.

Everything in the early implementation should serve this loop. Ship log, leadership tags, Admiralty nuance, officer reliability nuance, route visibility, and content framework validation are supporting systems. They matter, but they must not compete with the core judgment loop during the MVP.

## Early Implementation Simplifications

These simplifications apply until the core loop is fun:

- Allow at most one active promise at a time.
- Track only three leadership axes: harsh/merciful, honest/deceptive, shared-hardship/privilege.
- Treat fatigue and sickness as simple state values, Burden modifiers, damage tags, or incident triggers; do not build a deep fatigue or medical simulation.
- Treat Rum as a special supply with custom rules for expected ration, spirit-store access, theft, drunkenness, and ration-withheld fallout.
- Keep officer council narrow: use a small authored proposal set per incident instead of a deep advisory simulation.
- Use memory flags as the main narrative glue: flag now, pay off later.
- Keep the ship log as a simple event list early; later it can become a richer narrative artifact.
- Keep Admiralty politics and persistent unlock nuance minimal until the in-run loop works.
- Do not treat leadership axes as morality meters. Harsh, merciful, honest, deceptive, shared-hardship, and privilege choices must each sometimes help and sometimes backfire.

## Deferred Functionality To Preserve

These features are intentionally deferred from the MVP but should remain visible in future planning:

- richer ship log prose and end-of-run narrative summaries
- broader leadership pattern tracking beyond the three early axes
- deeper officer reliability, loyalty, worldview, and hidden motive modeling
- Admiralty hidden politics, scandals, institutional bias, and long-term report distortion
- larger route generation variety and hidden route modifiers
- delayed-outcome/callback machinery beyond simple memory flags
- multiple simultaneous promises
- deeper fatigue, sickness, injury, and recovery systems
- richer Rum economy and spirit-store rules beyond first-pass theft/drunkenness hooks
- larger incident library and rare unique incidents
- full campaign unlock economy
- optional card/deck UI representation if testing later shows it improves standing orders or officer proposals

## Core Design Decisions

### Burden

Burden is the crew and ship's accumulated breaking load. It is the in-universe name for pressure or strain.

Burden rises from hunger, thirst, storms, cold, sickness, injury, overwork, fatigue, deaths, bad burials, missing crew, terrifying discoveries, omens, failed promises, unfair rationing, exposed deception, humiliating retreat, and visible incompetence.

Burden falls through rest, food and water security, fair distribution, rituals, burial, good landfall, safe weather, successful repairs, comforting goods, credible officer intervention, and meaningful victories.

High Burden does not mean the crew is simply insane. It means the expedition is near a breaking point.

### Command

Command is the crew's belief that the captain's orders should still be followed. It is the in-universe name for legitimacy.

Command rises when the captain appears competent, fair, courageous, lucky or divinely favored, honest when honesty matters, willing to share hardship, and decisive in crisis.

Command falls through broken promises, obvious incompetence, cruelty without payoff, favoritism, concealed truth discovered later, avoidable deaths, cowardice, scandal, officer dissent, and public humiliation.

The main state interactions:

- High Burden + high Command: grim endurance.
- Low Burden + low Command: political instability without immediate hardship.
- High Burden + low Command: refusal, sabotage, factional challenge, or mutiny.
- Low Burden + high Command: stable command, but not safety.

### Supplies

The initial supply model should remain compact and multi-meaning:

- food
- water
- medicine
- repair materials
- comforts
- Rum

Medicine is healing, trade leverage, mercy, and theft temptation. Comforts reduce Burden, reward favorites, or create resentment if distributed unfairly. Repair materials preserve the ship, patch boats, or buy cooperation.

Rum is first-class. It reduces Burden after hardship, can preserve Command if shared fairly, can damage Command if hoarded or ration custom is broken, creates spirit-store theft and drunkenness incidents, and can become a dependency where running out raises Burden because the crew expected the ration.

### Ship Condition

Track one overall ship condition value plus temporary damage tags. Use tags for event hooks rather than building a full FTL-style subsystem model.

Example tags:

- hull strained
- rigging damaged
- stores wet
- galley damaged
- sick bay unusable
- lifeboat lost
- charts spoiled

### Crew, Officers, And Notables

The crew should be modeled mostly at the group level. Individual texture comes from officers and notable crew.

Crew-level traits can include superstitious, veteran, pressed, class-divided, pious, foreign-born, prize-hungry, and disease-weakened.

Notables can include loyal first mate, ambitious lieutenant, steady bosun, popular surgeon, zealous chaplain, drunk purser, uncanny lookout, and cowardly midshipman.

Traits and notables modify Burden/Command changes, unlock or complicate incidents, and shape officer council options.

### Route Map

The voyage uses a branching route map, not freeform sailing.

Major node categories:

- Crisis: storm, fire, disease, hull breach, injury, food spoilage, violent dispute.
- Landfall: island, settlement, wreck, hunting ground, freshwater source, strange shore.
- Social: grievance, theft accusation, officer dispute, rumor, faction tension, punishment demand.
- Omen: strange lights, dead birds, ghost ship rumor, dream, impossible current, superstition.
- Boon: fair wind, good catch, calm anchorage, floating salvage, recovered stores, favorable current.
- Admiralty: sealed orders, survey target, rival vessel, evidence, official objective, reputational complication.
- ? / Unknown: uncertain event category that may become crisis, landfall, social, omen, boon, or rare unique incident.

Route visibility should show event category, approximate distance in ticks, broad weather or sea condition, possible supply opportunity, and known hazard marker if any. It should support planning without perfect information.

Travel ticks update food and water consumption, fatigue, sickness progression, ship wear, weather exposure, Burden, Command, and incident trigger checks.

### Standing Orders

Standing orders are the preparation layer. Before a route segment or major node, the player chooses a limited number of orders that shape how the ship handles upcoming ticks and incidents.

Examples:

- tighten rationing
- double watches
- permit shore leave
- keep lanterns low
- prepare boats
- hold prayer
- audit stores
- favor speed over repairs
- suppress rumors
- rotate the sick off duty
- share officer comforts
- prepare salvage parties

Standing orders cost command bandwidth, labor, time, or supplies. They create advantages and liabilities. Double watches may catch sabotage but increase fatigue. Audit stores may reveal theft early but anger the purser or expose officer corruption. Hold prayer may reduce Burden for a pious crew but damage Command with cynical officers.

### Decision Feedback

Do not present decisions as dry spreadsheets. Before a choice, show a forecast in evocative risk language: likely lowers Burden, risks fatigue, may preserve supplies, Command may suffer if discovered, the bosun is confident, the purser may be concealing something, exact risk unknown without better charts or officer expertise.

After a choice, show a short narrated consequence plus clear state deltas:

> The men obey, but the lower deck goes quiet. Burden +4. Command -2.

Exact numbers fit when the fiction supports certainty. Otherwise use risk bands or officer confidence.

### Officer Council

Officer council is the crisis-resolution layer. Officers and notables propose actions based on role, personality, loyalty, competence, worldview, and state.

Example during a ration theft:

- Bosun: make an example of the thief.
- Surgeon: reduce labor before punishment; the crew is starving.
- Purser: audit stores before judgment.
- Chaplain: allow confession without naming names.
- First mate: conceal the theft until landfall.

Advice is mechanical, not just dialogue flavor. A surgeon may be accurate about sickness risk but politically naive. A bosun may understand discipline but underestimate moral backlash. A purser may be competent, drunk, corrupt, or frightened.

### Promises

Promises are a formal mechanic that turns leadership into future debt.

Examples:

- "We will make landfall within three days."
- "No man will go without water."
- "The thief will be judged fairly."
- "The dead will receive proper burial."
- "The officers will share the ration cut."

Making a promise can raise Command immediately, reduce Burden temporarily, or prevent a crisis from escalating. Keeping it reinforces Command and reduces future risk. Breaking it damages Command, raises Burden, and creates ship-log memory.

### Incident System

Incidents are authored templates triggered by simulation state, not fully freeform generated stories and not totally random event spam.

Each incident definition needs:

- id
- category
- trigger band
- required conditions
- optional amplifiers
- cast roles
- route or node context
- standing order interactions
- officer council hooks
- choices
- immediate outcomes
- delayed outcomes
- created memory flags
- log text
- callback hooks
- visibility rules

Example incidents to preserve as initial targets:

- Superstitious lookout sees a mermaid: Omen or night/fog tick, high Burden, superstitious crew/lookout, low visibility. Responses include dismiss, hold ritual, punish rumor-spreading, investigate, or conceal.
- Drunk purser miscounts stores: Rum/comforts present, purser notable, fatigue or low Command, recent ration dispute. Responses include punish, cover up, audit, blame theft, or reduce rations.
- Midshipmen fight ends in murder: high Burden, low Command, class-divided crew or recent favoritism, social node or bad tick. Responses include court-martial, public hanging, quiet burial, blame madness, protect a favorite, or let the crew decide.

### Run Memory

Use lightweight memory flags so later incidents can refer back without requiring a full narrative planner.

Examples:

- botched_hanging
- rum_theft_unresolved
- burial_denied
- officers_shared_rations
- mermaid_rumor_spread
- surgeon_publicly_overruled
- purser_exposed
- promised_landfall_broken

Run memory feeds incident eligibility, officer advice, Burden/Command changes, ship log entries, end-of-run summary, and Admiralty report options.

### Leadership Pattern

Track recent leadership behavior through hidden tags. Do not show a static class like "Authoritarian Level 3."

The MVP should track only three axes:

- harsh/merciful
- honest/deceptive
- shared-hardship/privilege

Future axes can include fair/favoritist, cautious/reckless, pious/pragmatic, and collective/authoritarian if the core loop needs more nuance.

Leadership tags influence officer proposals, incident text, crew interpretation, ship log tone, Admiralty report options, and future event weighting.

### Admiralty Layer

The Admiralty is the between-run political, progression, and memory layer. It is not the in-run killer mechanic.

Loop:

1. Review the ship log: what actually happened.
2. Submit an official report: what the captain claims happened.
3. Admiralty evaluates the report according to biases and current politics.
4. Receive a preparation budget and constraints for the next expedition.
5. Choose ship upgrades, officers, crew background, supply package, doctrine, and route intel.
6. Political events and institutional memory shape the next expedition.

Report framings can blame weather, blame crew, emphasize discipline, conceal misconduct, admit command failure, glorify sacrifice, suppress mutiny, or accuse a rival officer.

Unlocks add tradeoffs, not raw power:

- Doctrines unlock standing orders and change command culture, such as Articles of Emergency Discipline, Scientific Survey Protocol, Pious Expedition Charter, Shared Hardship Doctrine, and Sealed Orders Authority.
- Officer pools unlock chaplain, naturalist, surgeon, quartermaster, marine lieutenant, navigator, and political observer.
- Crew backgrounds change starting problems, such as pressed men, veteran crew, mixed-nationality crew, and prize-hungry crew.
- Logistics packages change starting supplies with drawbacks.
- Route intel reveals or distorts map information.

Preparation budget choices include ship upgrades, officer selection, notable crew or crew background, supply/logistics package, doctrine or standing order access, route intelligence, and Admiralty objective or political constraint.

Examples:

- Reinforced hull: less ship wear, slower travel or less cargo room.
- Expanded spirit locker: more Rum, higher theft and drunkenness risk.
- Better boats: safer Landfall outcomes, less repair stock.
- Extra marines: stronger discipline, lower starting Command among pressed crew.
- Veteran bosun: stronger Command in crises, less tolerance for incompetence.
- Popular surgeon: better sickness control, larger Command loss if they die or are overruled.
- Pressed crew: more labor for less budget, lower starting Command.
- Pious charter: stronger Omen and burial tools, weaker fit for cynical or mixed-faith crews.

Rule:

> Every unlock asks: what new problem does this new tool create?

### Player Visibility

Visible:

- Burden
- Command
- supplies, including Rum
- ship condition and known damage tags
- visible route node categories
- approximate travel tick distance
- known weather or hazard hints
- known crew traits and officer traits
- active standing orders
- promises made and deadlines
- major state changes after decisions

Partially visible:

- incident risks
- exact consequence ranges
- future delayed consequences
- officer reliability
- hidden route modifiers
- Admiralty preferences
- hidden crew tensions

Hidden or inferred:

- exact incident trigger thresholds
- exact event weights
- some leadership pattern tags
- some officer motives
- some Admiralty political biases
- concealed memory flags until they surface in fiction

The player should understand why outcomes happened after the fact while feeling uncertainty before decisions.

## Godot Content Framework Direction

Use Godot custom Resources saved as text `.tres` files by default. Back them with typed Resource scripts. This is more Godot-native than runtime YAML and allows content to be edited through the Inspector while remaining source-control-friendly.

JSON may be used for bulk/table-like data where typed editor workflows matter less. YAML should not be a default runtime dependency because it is not a native Godot format. It can be reconsidered later as an authoring or import format if hand-authored text content becomes painful enough to justify extra tooling.

Suggested content layout:

- `res://content/incidents/*.tres`
- `res://content/standing_orders/*.tres`
- `res://content/officers/*.tres`
- `res://content/upgrades/*.tres`
- `res://content/doctrines/*.tres`
- `res://content/supplies/*.tres`
- `res://content/crew_backgrounds/*.tres`
- `res://content/route_modifiers/*.tres`

Example Resource classes:

- `IncidentDef`
- `IncidentChoiceDef`
- `StandingOrderDef`
- `OfficerDef`
- `ShipUpgradeDef`
- `SupplyDef`
- `DoctrineDef`
- `CrewBackgroundDef`
- `ConditionDef`
- `EffectDef`

Each content entry should use a consistent contract where practical:

- id
- display name
- category
- tags
- visibility rules
- unlock source
- log hooks
- weighting or rarity
- incompatible tags, if needed

Use this as a small shared base, not a forced mega-schema. Type-specific Resources should own their own fields. `IncidentDef` needs trigger bands, cast roles, choices, and memory flags. `ShipUpgradeDef` needs preparation budget cost, upgrade effects, and drawbacks. `SupplyDef` needs starting amount rules and display metadata. `StandingOrderDef` needs command cost, forecast text, tick interactions, and risk hooks.

This avoids over-generalizing content. The framework should share loading, ids, tags, visibility, and validation patterns while letting each content family stay readable in the Godot Inspector.

## Implementation Sequence

### Stage 0: Art Direction and Asset Pipeline

**Goal:** Establish the visual identity and produce the MVP asset set before any game screens are built. Full detail in `docs/superpowers/specs/2026-04-12-art-direction-design.md`.

**Build:**

- Scenario.com account set up and custom generator trained on a curated reference set of ~15–20 properly licensed images.
- Palette locked (16–32 colours), saved as a Godot colour constant file and as a Scenario palette constraint.
- Resolution standard and pixel density documented: 320×180 scene backgrounds, 48×64 portraits, 16×16 base tile.
- Prompt templates documented in `docs/art-production-guide.md`.
- Full MVP asset set generated and reviewed: 7 event backgrounds, 4 officer portraits, 1 ship view, 1 route map background texture, 1 Admiralty interior.
- Godot project configured for pixel art rendering: nearest-neighbour filtering, integer scaling, landscape orientation lock.
- Asset folders created under `res://assets/` with naming conventions documented.
- Minimum font sizes defined for legibility at landscape mobile scale.
- Cinzel and Crimson Pro fonts downloaded, OFL licence files saved to `res://assets/fonts/`.
- Licensing pre-production checklist completed.

**Exclude:**

- Any game logic or content framework work.
- Polished or final art — MVP asset set is good enough to ship for prototype.

**Playable/Testable Outcome:** The Godot project renders pixel art correctly. The MVP asset set exists and is organised. The art production guide allows new assets to be generated consistently. The licensing pre-production checklist is done.

**Art integration by coding stage:**
- Stage 1 receives Godot pixel art rendering setup and asset folder structure.
- Stage 3 integrates map background texture and ship view.
- Stage 4 integrates officer portraits.
- Stage 5 integrates event backgrounds.
- Stage 6A integrates Admiralty interior.

### Stage 1: Godot Content Framework Vertical Slice

**Goal:** Establish the data-driven foundation for the game.

**Build:**

- Typed custom Resource classes for supplies, effects, conditions, standing orders, officers, ship upgrades, doctrines, crew backgrounds, incident choices, incidents, objectives, and zone types.
- A small shared Resource base contract for ids, display names, tags, visibility, unlock source, rarity/weighting, and validation support.
- Type-specific fields for each Resource family rather than one generic mega-schema.
- A content directory structure under `res://content`.
- A registry/loader that can load content definitions from Resource paths.
- A small validation path that catches missing ids, duplicate ids, invalid references, and unsupported effect/condition types.
- Sample content for Rum, one or two supplies, one or two standing orders, one or two officers, one ship upgrade, one doctrine, and one incident.

**Exclude:**

- Procedural route generation.
- Full Burden/Command simulation.
- Full incident resolution UI.
- Admiralty economy.

**Playable/Testable Outcome:** The project can load typed content definitions and show or print a validated content catalog. Designers can add a new `.tres` content item without changing core loader code.

**Next Detailed Plan:** `2026-04-12-godot-content-framework-vertical-slice.md`

### Stage 2: Core Expedition State And Simulation Rules

**Goal:** Implement the core state model that future route ticks and incidents manipulate.

**Build:**

- Expedition state object/model containing Burden, Command, supplies, ship condition, damage tags, crew traits, officers, standing orders, promises, leadership tags, run memory flags, active objective state (accepted / succeeded / failed), and stress indicators (peak Burden, minimum Command, crew losses, supply depletions).
- Effect application system for content-driven changes.
- Condition evaluation system for content-driven requirements.
- Supply model covering food, water, medicine, repair materials, comforts, and Rum.
- Rum special-case state for expected ration, spirit-store locked/unlocked, theft risk, drunkenness risk, and ration-withheld fallout.
- Burden/Command change rules and clamping.
- Ship condition and damage tag operations.
- One-active-promise creation, tracking, kept/broken resolution.
- Run memory flag creation and lookup.
- Debug/explanation log for why effects applied, why conditions passed/failed, why Burden or Command changed, and which memory flags were created.

**Exclude:**

- Route map UI.
- Major incident UI.
- Admiralty meta layer.
- Multiple simultaneous promises.
- Deep fatigue or medical simulation.

**Playable/Testable Outcome:** A scripted simulation can apply effects from content Resources and produce understandable state changes. Rum, Burden, Command, one active promise, and memory flags all work in isolation. The debug/explanation log can answer "why did this happen?" for state changes.

### Stage 3: Route Map And Travel Ticks

**Goal:** Create the run skeleton: branching route map, visible node categories, and travel tick simulation.

**Build:**

- Hand-authored test route map first, with later generation deferred. The test map uses 7 node categories: Crisis, Landfall, Social, Omen, Boon, Admiralty, Unknown.
- Route nodes with category, approximate tick distance, weather/hazard hints, and optional supply opportunity hint.
- Support for a required-node marker so survey and recover objectives can demand a specific node category appears on the route.
- Route segments carry a `zone_type` field referencing a `ZoneTypeDef`. `ZoneTypeDef` tick modifiers (consumption, ship wear, Burden delta, incident weight) applied during travel. See `docs/superpowers/specs/2026-04-12-difficulty-stack-design.md`.
- Hand-authored test route uses all four MVP zone types: Coastal, Open Ocean, Lee Shore, Unknown.
- Ship log entries tagged with `difficulty_signal` category (route_danger, stress_indicator, starting_condition, objective_tier) for Admiralty synthesis.
- Travel between nodes as discrete ticks.
- Tick effects for food/water consumption, travel fatigue as a simple numeric expedition-state value, sickness risk as a simple numeric expedition-state value, ship wear, weather exposure, Burden, Command, and incident trigger checks.
- A forced debug incident hook so a simple crisis can be triggered from travel context before the full incident system exists.
- Basic map UI or debug UI for choosing the next route.

**Exclude:**

- Full event/incident resolution.
- Procedural route generation.
- Admiralty preparation budget.
- Polished visuals.

**Playable/Testable Outcome:** The player can choose a path through a small hand-authored route map, advance through travel ticks, see supplies/ship condition/Burden/Command change, and trigger one forced debug incident from travel pressure.

### Stage 4: Standing Orders And Officer Council

**Goal:** Add player agency beyond route choice without using a deckbuilder.

**Build:**

- Standing order selection before route segments or major nodes.
- Standing order effects and liabilities driven by Resource definitions.
- Officer definitions with role, competence, loyalty, worldview, known traits, and possible advice hooks.
- Authored officer proposal sets for a small set of test crises.
- Decision feedback presentation: in-world forecast before choosing; narrated consequence plus state deltas after choosing.
- Light officer uncertainty only: advice confidence can differ from actual result when a clearly defined officer state or reliability flag warrants it.

**Exclude:**

- Large officer roster.
- Deep advisor simulation.
- Full incident library.
- Full Admiralty meta progression.

**Playable/Testable Outcome:** Before traveling or resolving a simple crisis, the player can choose standing orders and officer-backed options, then see Burden/Command/supplies change through grounded consequences.

### Stage 5: Incident System, Run Memory, And Ship Log

**Goal:** Make emergent-feeling story moments come from the simulation.

**Build:**

- Incident eligibility selection from Resource definitions.
- Trigger bands: tick, node, aftermath, threshold crossing.
- Required conditions and optional amplifiers.
- Active zone type read during eligibility evaluation: `eligible_incident_tags` and `suppressed_incident_tags` from `ZoneTypeDef` gate which incidents can fire.
- Cast role resolution from crew/officer/notable state.
- Incident choices, immediate outcomes, and memory flags.
- Initial incident set targeting the three design examples: mermaid sighting, drunk purser store error, midshipmen murder.
- Ship log entries as a simple event list for decisions, consequences, leadership tone, and memory flags.
- Simple flag-based callbacks so later incidents can refer to previous memory flags.

**Exclude:**

- Large procedural narrative system.
- Natural-language generation.
- Full final epilogue.
- Rich ship-log prose generation.
- Broad delayed-outcome machinery beyond memory flags.

**Playable/Testable Outcome:** A short run can generate at least one state-driven incident, resolve it through officer/command choices, update memory flags, and write a ship log entry that can be referenced later.

### Stage 6A: Admiralty Preparation Layer

**Goal:** Add between-run preparation without persistent political complexity.

**Build:**

- Pre-run preparation budget screen.
- Selection of ship upgrades, officer/crew background, supply/logistics package, doctrine, route intel, and Admiralty objective/constraint.
- Admiralty objective shortlist: 2–3 objectives filtered from available `ObjectiveDef` Resources by unlock state and run history. Player picks one. See `docs/superpowers/specs/2026-04-12-run-objectives-design.md`.
- Active objective displayed on the HUD alongside promises, Burden, and Command.
- Objective success/failure resolution at run end: unlock delivery on success, Admiralty report pressure on failure.
- Basic Admiralty difficulty synthesis: objective tier + route danger signals from ship log. Report framing options shaped by difficulty read. See `docs/superpowers/specs/2026-04-12-difficulty-stack-design.md`.
- Tradeoff-based content definitions for reinforced hull, expanded spirit locker, better boats, extra marines, veteran bosun, popular surgeon, pressed crew, and pious charter.
- Initial objective content: 2–3 objectives per type (survey, condition, recover), each with one tradeoff-based unlock attached.
- Prepared expedition state passed into the next route run.

**Exclude:**

- End-of-run report framing.
- Persistent politics.
- Scandal/unlock distortion.
- Admiralty political bias on shortlist weighting (Stage 6B).
- Full campaign economy.
- Large unlock tree.
- Balancing for long-term progression.

**Playable/Testable Outcome:** The player can prepare an expedition from a limited budget, accept an Admiralty objective, pursue it during the run, and see a tradeoff-based unlock delivered on success or Admiralty report pressure applied on failure.

### Stage 6B: Admiralty Reporting And Political Memory

**Goal:** Add report framing, institutional memory, and first-pass persistent consequences after the preparation loop works.

**Build:**

- End-of-run report framing: blame weather, blame crew, emphasize discipline, conceal misconduct, admit command failure, glorify sacrifice, suppress mutiny, accuse a rival officer.
- Objective outcome feeds report framing: success makes credible claims available; failure requires explanation, concealment, or blame.
- Full multi-signal Admiralty difficulty synthesis: starting conditions and run stress indicators added to objective tier and route danger. Shortlist weighting by accumulated run difficulty across sessions.
- Unlock state that expands future options without raw power creep.
- Political/scandal flags from concealed truth or report distortions.
- Simple Admiralty bias state that affects one future preparation constraint or unlock, including objective shortlist weighting.

**Exclude:**

- Full campaign economy.
- Large unlock tree.
- Balancing for long-term progression.
- Deep hidden politics simulation.

**Playable/Testable Outcome:** After a short run, the player can submit an official report and see one tradeoff-based option, constraint, scandal flag, or political bias affect the next preparation phase.

## Vertical Slice Content Cap

For the first integrated prototype, keep the content cap deliberately small:

- 7 node categories
- 6 supplies, including Rum
- 6 standing orders
- 4 officer roles
- 6 incidents
- 6 ship upgrades
- 3 Admiralty doctrines
- 3 crew backgrounds
- 3 promises
- 6–9 run objectives (2–3 per type: survey, condition, recover)
- 4 zone types (Coastal, Open Ocean, Lee Shore, Unknown)

These caps are not final game limits. They are a protection against building a content swamp before the framework proves the loop.

## Work Not Yet In Scope

- Full freeform sailing.
- Full individual simulation for every sailor.
- Tactical combat.
- A full deckbuilder.
- Full social graph or faction simulation.
- Full Admiralty campaign economy.
- Polished art and animation.
- Natural-language generated story.
- Large event library.

Cards can return later as a UI representation of standing orders or officer proposals if testing shows that it helps, but deckbuilding is not a foundational pillar for the current implementation path.

## Next Action

Write the detailed implementation plan for Stage 1: Godot Content Framework Vertical Slice.
