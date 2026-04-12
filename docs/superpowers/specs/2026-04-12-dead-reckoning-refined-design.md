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

Each resource should have more than one use. Medicine is healing, trade leverage, mercy, and theft temptation. Comforts can reduce Burden, reward favorites, or create resentment if distributed unfairly. Repair materials can preserve the ship, patch boats, or buy cooperation.

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

### Officer Council

Officer council is the crisis-resolution layer. During major events, relevant officers or notables propose actions based on their role, personality, loyalty, and state.

Example during a ration theft:

- Bosun: make an example of the thief.
- Surgeon: reduce labor before punishment; the crew is starving.
- Purser: audit stores before judgment.
- Chaplain: allow confession without naming names.
- First mate: conceal the theft until landfall.

Officer proposals are not dialogue flavor. They are mechanical options with costs, reliability, and consequences for Burden, Command, supplies, ship condition, leadership pattern, and future incidents.

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
4. Unlock new doctrines, officers, orders, crew backgrounds, route intel, and starting conditions.
5. Political events and institutional memory shape the next expedition.

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

Rule:

> Every unlock asks: what new problem does this new tool create?

## What To Avoid

Avoid full freeform sailing in the next iteration. It risks traversal grind and content sprawl.

Avoid full individual simulation for every sailor. Use group-level Burden and Command with notable crew as catalysts.

Avoid a large deckbuilder unless deckbuilding becomes clearly necessary. Cards can return later as a representation of standing orders or officer proposals.

Avoid pure branching narrative. Choices must be constrained by route state, supplies, standing orders, officers, ship condition, Burden, Command, and prior promises.

Avoid generic upgrades. Admiralty progression should expand choices and political liabilities, not make the player stronger in a linear way.

Avoid opaque social math. Players do not need every formula, but they must understand why Burden rose, why Command faltered, and why a mutiny became plausible.

## Minimum Viable Design Target

The smallest version worth prototyping:

1. A branching route map with visible node categories and travel ticks.
2. Burden and Command as the two central crew-state meters.
3. A compact supply model: food, water, medicine, repair materials, comforts.
4. One ship condition value plus temporary damage tags.
5. Standing orders before route segments.
6. Officer council choices at major events.
7. A small incident-template library triggered by state.
8. A ship log that records consequential events and leadership tone.
9. A simple Admiralty report screen that unlocks tradeoff-based options for later runs.

If this prototype produces stories players want to retell, the design is working.
