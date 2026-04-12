# Dead Reckoning Refined Design

## Purpose

This document refines the initial game concept into a tighter next-iteration design for a solo-developed, simulation-driven maritime roguelike.

The design draws inspiration from the local research on *FTL*, *Darkest Dungeon*, *Frostpunk*, *Sunless Sea*, *This War of Mine*, and *Help Will Come Tomorrow*, but does not directly lift their systems. The goal is a coherent game about captaincy, scarcity, authority, and emergent expedition stories.

## High Concept

*Dead Reckoning* is a simulation-driven maritime roguelike about commanding a doomed age-of-sail expedition as authority collapses under hardship.

The player is not a sailor-avatar or a direct ship pilot. The player is the captain: they choose routes, set standing orders, rely on officers, ration supplies, interpret omens, enforce discipline, make promises, conceal failures, and decide what the crew must endure.

Each run is a finite expedition arc. The ship moves across a branching route map, major events occur at visible node categories, and the squares between those nodes are simulation ticks where the voyage grinds down supplies, ship condition, crew endurance, and command authority.

The core promise:

> Choose a route, prepare the ship, survive the ticks, face incidents, preserve or spend your Command, and see what kind of captain the crew says you became.

## Design Pillars

### Human Conflict First

The primary challenge is not combat. It is keeping a crew functional when hunger, fear, exhaustion, grief, class tension, superstition, and command failure make obedience uncertain.

### Emergent Story Through Systems

The game should produce retellable moments such as:

- a superstitious lookout seeing a mermaid in the fog
- a drunk purser miscounting stores before a ration cut
- a fight between midshipmen ending in murder
- a chaplain turning an omen into resolve, or panic
- an ambitious officer using a failed punishment to question the captain

These moments come from authored incident templates triggered by simulation state, not from a fully freeform story generator.

### Authority As A Resource

The captain can solve problems through command, but every method changes how command is understood. Harsh discipline may suppress immediate disorder while making the crew brittle. Shared hardship may preserve loyalty but weaken hierarchy. Deception may avoid panic now and become scandal later.

### Elegant Scope

The game should not begin as a full colony sim, social graph sim, open-world sailing game, tactical combat game, and deckbuilder at once. The next iteration should center on the route map, travel ticks, Burden, Command, standing orders, officer council choices, and incident generation.

### Framework-Driven Content

The game should be built around a data-driven content framework. Incidents, major events, ship upgrades, supplies, standing orders, officer types, crew traits, Admiralty doctrines, route node categories, and unlocks should be defined in YAML or an equivalent engine-readable data format rather than hard-coded as one-off branches.

This is a core production requirement, not a later convenience. The design depends on being able to add, tune, and recombine content over time without rewriting the underlying game logic.

### Loss Is Story

Failure should not feel like invalid play. Mutiny, abandonment, shipwreck, scandal, rescue, and compromised arrival should become ship-log material and feed the Admiralty layer.

## Core State

### Burden

Burden is the crew and ship's accumulated breaking load. It is the in-universe player-facing name for what might be called pressure or strain internally.

Burden rises from:

- hunger and thirst
- storms and cold
- sickness and injury
- overwork and fatigue
- deaths, bad burials, and missing crew
- terrifying discoveries and omens
- failed promises
- unfair rationing
- exposed deception
- humiliating retreat or visible incompetence

Burden falls through:

- rest
- food and water security
- fair distribution
- rituals and burial
- good landfall
- safe weather
- successful repairs
- comforting goods
- credible officer intervention
- meaningful victories

High Burden does not mean the crew is simply "insane." It means the expedition is near a breaking point.

### Command

Command is the crew's belief that the captain's orders should still be followed. It is the in-universe player-facing name for legitimacy.

Command rises when the captain appears:

- competent
- fair
- courageous
- lucky or divinely favored
- honest when honesty matters
- willing to share hardship
- decisive in crisis

Command falls through:

- broken promises
- obvious incompetence
- cruelty without payoff
- favoritism
- concealed truth discovered later
- avoidable deaths
- cowardice
- scandal
- officer dissent
- public humiliation

The interaction between Burden and Command is the heart of the mutiny model:

- High Burden + high Command: grim endurance.
- Low Burden + low Command: political instability without immediate hardship.
- High Burden + low Command: refusal, sabotage, factional challenge, or mutiny.
- Low Burden + high Command: stable command, but not safety.

### Supplies

Use a compact set of multi-meaning resources:

- food
- water
- medicine
- repair materials
- comforts
- Rum

Each resource should have more than one use. Medicine is healing, trade leverage, mercy, and theft temptation. Comforts can reduce Burden, reward favorites, or create resentment if distributed unfairly. Repair materials can preserve the ship, patch boats, or buy cooperation.

Rum should be a first-class supply type rather than being folded into generic comforts. It gives the ship a strong maritime pressure valve:

- reduces Burden after hardship when distributed as a ration or reward
- can preserve Command if shared fairly
- can damage Command if officers hoard it or the captain breaks expected ration custom
- creates incidents around theft, drunkenness, spirit-store break-ins, purser negligence, and punishment
- can become a dependency, where running out raises Burden because the crew expected the ration
- can become an Admiralty or ship-upgrade tradeoff through larger spirit lockers, stricter locks, or temperance doctrine

Avoid a large inventory taxonomy until the core loop proves it needs one.

### Ship Condition

Track one overall ship condition value, supported by temporary damage tags.

Possible damage tags:

- hull strained
- rigging damaged
- stores wet
- galley damaged
- sick bay unusable
- lifeboat lost
- charts spoiled

This creates event hooks without requiring a full FTL-style subsystem model.

### Crew And Notables

The crew should be modeled mostly at the group level, with individual texture from officers and notable crew.

Crew-level traits might include:

- superstitious
- veteran
- pressed
- class-divided
- pious
- foreign-born
- prize-hungry
- disease-weakened

Notable people might include:

- loyal first mate
- ambitious lieutenant
- steady bosun
- popular surgeon
- zealous chaplain
- drunk purser
- uncanny lookout
- cowardly midshipman

These traits and notables modify Burden and Command changes, unlock or complicate incident templates, and shape officer council options.

## Route Map

The voyage uses a Slay the Spire-style branching route map, not freeform sailing.

Each run generates a route network with:

- major event nodes
- travel squares between nodes
- visible node categories
- partial route metadata
- a final destination, disaster, rescue, or judgment node

The player chooses a path. Once committed, the ship must endure the intervening travel ticks.

### Major Event Categories

Major event nodes show a category, not exact contents.

**Crisis**: direct danger such as storm, fire, disease, hull breach, injury, food spoilage, violent dispute.

**Landfall**: opportunity with risk, such as island, settlement, wreck, hunting ground, freshwater source, strange shore.

**Social**: crew and authority event, such as grievance, theft accusation, officer dispute, rumor, faction tension, punishment demand.

**Omen**: ambiguous atmospheric event, such as strange lights, dead birds, ghost ship rumor, dream, impossible current, superstition.

**Boon**: mostly beneficial opportunity, such as fair wind, good catch, calm anchorage, floating salvage, recovered stores, favorable current.

**Admiralty**: mission or political node, such as sealed orders, survey target, rival vessel, evidence, official objective, reputational complication.

**? / Unknown**: uncertain event category that may become crisis, landfall, social, omen, boon, or rare unique incident.

### Travel Ticks

Each square between major nodes is a simulation tick. Ticks update:

- food and water consumption
- fatigue
- sickness progression
- ship wear
- weather exposure
- Burden
- Command
- incident trigger checks

The strategic question is not only "which node do I want?" It is:

> Can this crew survive the distance and conditions between this node and the next?

A longer safe-looking path may destroy a hungry, exhausted crew. A short crisis-heavy route may be better if the ship cannot endure many ticks. A route with omens may be dangerous with a superstitious crew but manageable with a trusted chaplain.

### Route Visibility

Show partial route information:

- event category
- approximate distance in ticks
- broad weather or sea condition
- possible supply opportunity
- known hazard marker, if any

The map should support strategic planning without becoming perfect information.

## Command System

The design should not start as a full deckbuilder. Cards could later become a UI representation, but the foundational system should be more grounded: standing orders plus officer council.

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

Standing orders cost limited command bandwidth, labor, time, or supplies. They create advantages and liabilities.

Examples:

- Double watches may catch sabotage but increase fatigue.
- Audit stores may reveal theft early but anger the purser or expose officer corruption.
- Hold prayer may reduce Burden for a pious crew but damage Command with cynical officers.
- Tighten rationing preserves food while raising Burden and making future food incidents sharper.

### Decision Feedback

Standing orders and officer council choices should show tradeoffs in a way that is legible, tense, and in-world.

Before a choice, the player should see a forecast rather than a spreadsheet. The forecast can use evocative risk language:

- likely lowers Burden
- risks fatigue
- may preserve supplies
- Command may suffer if discovered
- the bosun is confident
- the purser may be concealing something
- exact risk unknown without better charts or officer expertise

After a choice, the player should receive a short narrated consequence plus clear state changes:

> The men obey, but the lower deck goes quiet. Burden +4. Command -2.

The goal is to keep decisions game-like without turning them into dry optimization. Exact numbers can appear when the fiction supports certainty. Uncertain choices should communicate risk bands or officer confidence instead of exact odds.

### Officer Council

Officer council is the crisis-resolution layer. During major events, relevant officers or notables propose actions based on their role, personality, loyalty, and state.

Example during a ration theft:

- Bosun: make an example of the thief.
- Surgeon: reduce labor before punishment; the crew is starving.
- Purser: audit stores before judgment.
- Chaplain: allow confession without naming names.
- First mate: conceal the theft until landfall.

Officer proposals are not dialogue flavor. They are mechanical options with costs, reliability, and consequences for Burden, Command, supplies, ship condition, leadership pattern, and future incidents.

Officer advice should also carry uncertainty. A surgeon may be accurate about sickness risk but politically naive. A bosun may be reliable about discipline but underestimate moral backlash. A purser may be competent, drunk, corrupt, or frightened. Officer competence, loyalty, worldview, and current state should affect both the advice and the real outcome.

### Promises

Promises are a formal mechanic that turns leadership into future debt.

Examples:

- "We will make landfall within three days."
- "No man will go without water."
- "The thief will be judged fairly."
- "The dead will receive proper burial."
- "The officers will share the ration cut."

Making a promise can raise Command immediately, reduce Burden temporarily, or prevent a crisis from escalating. Keeping it should reinforce Command and reduce future incident risk. Breaking it should damage Command, increase Burden, and create ship-log memory.

Promises should be data-defined like other content. A promise entry needs conditions, timer or success criteria, immediate effects, kept effects, broken effects, visibility, log hooks, and possible Admiralty report hooks.

## Incident System

The incident system creates emergent-feeling story moments from controlled authored templates.

Each incident is built from:

- trigger band: tick, node, aftermath, threshold crossing
- required conditions: high Burden, low Command, storm damage, omen route, low water, etc.
- optional amplifiers: superstitious, drunk, ambitious, loyal, popular, injured, guilty, class-divided
- cast roles: lookout, purser, surgeon, bosun, chaplain, midshipman, anonymous sailor
- leadership choices: grounded captain actions
- consequences: Burden, Command, supplies, damage, trait changes, future flags
- narrative memory: ship log entry, rumor, callback, Admiralty report hook

Incident templates must be expandable through YAML or an equivalent data format. The incident system should support new incidents without custom code for each one.

Each incident definition should include:

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

This does not mean every incident must be generic. It means bespoke writing should sit inside a consistent structure the engine can read and combine with the simulation.

Examples:

### Superstitious Lookout Sees A Mermaid

Conditions:

- omen node or night/fog tick
- high Burden
- superstitious crew or lookout
- low visibility

Possible responses:

- dismiss it
- hold ritual
- punish rumor-spreading
- investigate
- conceal from crew

Consequences:

- Burden changes
- Command changes
- superstition flag
- possible route reveal
- ship log entry

### Drunk Purser Miscounts Stores

Conditions:

- comforts or alcohol present
- purser notable
- fatigue or low Command
- recent ration dispute

Possible responses:

- punish the purser
- cover it up
- audit stores
- blame theft
- reduce rations

Consequences:

- supplies corrected or lost
- Burden spike if rations are cut
- Command loss if concealment is exposed later
- future social incident risk

### Midshipmen Fight Ends In Murder

Conditions:

- high Burden
- low Command
- class-divided crew or recent favoritism
- social node or bad tick

Possible responses:

- court-martial
- public hanging
- quiet burial
- blame madness
- protect a favorite
- let the crew decide

Consequences:

- Burden and Command shift
- leadership tags
- officer loyalty changes
- possible faction seed
- ship log scar

## Run Memory

The game should retain lightweight memory flags during a run so later incidents can refer back to earlier choices without requiring a full narrative planner.

Examples:

- botched_hanging
- rum_theft_unresolved
- burial_denied
- officers_shared_rations
- mermaid_rumor_spread
- surgeon_publicly_overruled
- purser_exposed
- promised_landfall_broken

Run memory flags should feed:

- incident eligibility
- officer council advice
- Burden and Command changes
- ship log entries
- end-of-run summary
- Admiralty report options

This is the main continuity layer for emergent storytelling.

## Leadership Pattern

Track recent leadership behavior through hidden tags. Do not present a static class like "Authoritarian Level 3."

Possible tags:

- harsh / merciful
- honest / deceptive
- fair / favoritist
- cautious / reckless
- pious / pragmatic
- collective / authoritarian

These tags should influence:

- officer proposals
- incident text
- crew interpretation
- ship log tone
- Admiralty report options
- future event weighting

Leadership identity should emerge from repeated decisions over time, and the player should feel it through consequences rather than a label.

## Admiralty Layer

The Admiralty is the between-run political, progression, and memory layer. It should not be the in-run killer mechanic, but it should frame how runs are remembered and how future tools become available.

The Admiralty loop:

1. Review the ship log: what actually happened.
2. Submit an official report: what the captain claims happened.
3. Admiralty evaluates the report according to its biases and current politics.
4. Receive a preparation budget and constraints for the next expedition.
5. Choose ship upgrades, officers, crew background, supply package, doctrine, and route intel.
6. Political events and institutional memory shape the next expedition.

### Report Framing

After a run, the player chooses how to frame the voyage:

- blame weather
- blame crew
- emphasize discipline
- conceal misconduct
- admit command failure
- glorify sacrifice
- suppress mutiny
- accuse a rival officer

The report should affect future options and pressures. If the player repeatedly claims discipline solved everything, the Admiralty may unlock harsher disciplinary doctrine and assign more pressed crews. If the player conceals mutiny, scandal risk may return later. If the player admits failure, they may lose influence but unlock reformist doctrine or better preparation.

### Unlock Categories

Unlocks add tradeoffs, not raw power.

**Doctrines** unlock standing orders and change the command culture.

Examples:

- Articles of Emergency Discipline
- Scientific Survey Protocol
- Pious Expedition Charter
- Shared Hardship Doctrine
- Sealed Orders Authority

**Officer Pools** unlock new officer archetypes.

Examples:

- chaplain
- naturalist
- surgeon
- quartermaster
- marine lieutenant
- navigator
- political observer

**Crew Backgrounds** change starting crew problems.

Examples:

- pressed men: more labor, lower starting Command
- veteran crew: lower Burden spikes, stronger demands for competence
- mixed-nationality crew: route and social incidents differ
- prize-hungry crew: stronger Landfall incentives, weaker discipline under scarcity

**Logistics Packages** change starting supplies with drawbacks.

Examples:

- extra medicine but fewer comforts
- preserved food but scurvy risk
- better boats but less repair stock
- more charts but lower water reserves

**Route Intel** reveals or distorts map information.

Examples:

- reveal one hidden node category per act
- identify likely Landfall rewards
- mark Admiralty objective routes
- introduce false confidence from outdated charts

### Expedition Preparation Budget

Before a run, the Admiralty layer should ask the player to prepare an expedition from a limited budget. This is where ship upgrades and crew selection create strategic tension before the route map begins.

Preparation choices should include:

- ship upgrades
- officer selection
- notable crew or crew background
- supply and logistics packages
- doctrine or standing order access
- route intelligence
- Admiralty objective or political constraint

Each preparation option should have a cost, a benefit, and a drawback.

Examples:

- Reinforced hull: less ship wear, slower travel or less cargo room.
- Expanded spirit locker: more Rum, higher theft and drunkenness risk.
- Better boats: safer Landfall outcomes, less repair stock.
- Extra marines: stronger discipline, lower starting Command among pressed crew.
- Veteran bosun: stronger Command in crises, less tolerance for incompetence.
- Popular surgeon: better sickness control, larger Command loss if they die or are overruled.
- Pressed crew: more labor for less budget, lower starting Command.
- Pious charter: stronger Omen and burial tools, weaker fit for cynical or mixed-faith crews.

Preparation should make the player select future problems, not buy safety.

Rule:

> Every unlock asks: what new problem does this new tool create?

## Content Framework

The game should treat most content as data definitions loaded by the engine. YAML is the preferred authoring format unless the engine later provides a better equivalent.

Content families should include:

- incidents
- major event nodes
- standing orders
- officer roles
- officer traits
- crew traits and backgrounds
- supplies
- ship upgrades
- ship damage tags
- Admiralty doctrines
- logistics packages
- route intel modifiers
- promises
- unlocks

Each content entry should use a consistent contract where practical:

- id
- display name
- category
- tags
- requirements
- cost
- immediate effects
- delayed effects
- visibility rules
- unlock source
- incident hooks
- log hooks
- Admiralty report hooks
- weighting or rarity
- incompatible tags, if needed

The framework should support adding new content without changing core game code in most cases. Core code should evaluate conditions, apply effects, present visibility, write log entries, and select eligible incidents from data.

This is especially important for long-term development. The game lives or dies on a growing library of events, upgrades, officers, route modifiers, and incident callbacks.

## Player Visibility

The design should be explicit about what is visible, partially visible, and hidden.

Visible to the player:

- Burden
- Command
- supplies, including Rum
- ship condition and known damage tags
- visible route node categories
- approximate travel tick distance
- known weather or hazard hints
- known crew traits and officer traits
- active standing orders
- promises made and their deadlines
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

The goal is traction, not total transparency. The player should understand why outcomes happened after the fact, while still feeling uncertainty before the decision.

## What To Avoid

Avoid full freeform sailing in the next iteration. It risks traversal grind and content sprawl.

Avoid full individual simulation for every sailor. Use group-level Burden and Command with notable crew as catalysts.

Avoid a large deckbuilder unless deckbuilding becomes clearly necessary. Cards can return later as a representation of standing orders or officer proposals.

Avoid pure branching narrative. Choices must be constrained by route state, supplies, standing orders, officers, ship condition, Burden, Command, and prior promises.

Avoid generic upgrades. Admiralty progression should expand choices and political liabilities, not make the player stronger in a linear way.

Avoid opaque social math. Players do not need every formula, but they must understand why Burden rose, why Command faltered, and why a mutiny became plausible.

Avoid hard-coding most content. The simulation rules should be stable, while content should be expandable through YAML definitions and reusable hooks.

## Minimum Viable Design Target

The smallest version worth prototyping:

1. A branching route map with visible node categories and travel ticks.
2. Burden and Command as the two central crew-state meters.
3. A compact supply model: food, water, medicine, repair materials, comforts, Rum.
4. One ship condition value plus temporary damage tags.
5. Standing orders before route segments.
6. Officer council choices at major events.
7. A small incident-template library triggered by state.
8. A ship log that records consequential events and leadership tone.
9. A simple Admiralty report screen that unlocks tradeoff-based options for later runs.
10. A preparation budget screen for ship upgrades, officer selection, crew background, supplies, and doctrine.
11. YAML-defined content for the first vertical slice.

Suggested vertical-slice content cap:

- 7 node categories
- 6 supplies, including Rum
- 6 standing orders
- 4 officer roles
- 12 incidents
- 6 ship upgrades
- 3 Admiralty doctrines
- 3 crew backgrounds
- 3 promises

If this prototype produces stories players want to retell, the design is working.
