# Against the Storm - Design Research Report

Research date: 2026-04-15

## Overview

Against the Storm is a dark fantasy roguelite city builder by Eremite Games, published by Hooded Horse. It launched in Steam Early Access on 2022-11-01, reached PC 1.0 on 2023-12-08, and came to PS4, PS5, Xbox One, Xbox Series X/S, and Nintendo Switch on 2025-06-26 according to Gematsu's report of the Hooded Horse announcement. As of this research pass, the game has two major DLCs: Keepers of the Stone, released 2024-09-26, and Nightwatchers, released 2025-07-31.

The pitch is "Banished meets Slay the Spire": build a sequence of temporary settlements in a storm-ravaged fantasy world, win each settlement before the Queen's Impatience fills, and carry meta-progression back to the Smoldering City. Metacritic lists the PC version at 91 Metascore and 7.9 user score from 246 ratings. OpenCritic mirrors consistently classify it as a high-scoring "Mighty" release around the high-80s/low-90s critic average, but crawled sources disagree on the current recommendation percentage, so Metacritic and Steam are the firmer aggregate references.

## Market Performance

- The strongest public sales milestone is over 1 million Steam copies, reported by PC Gamer from Eremite/Hooded Horse in March 2024. Later owner counts are third-party estimates: SteamDB's snapshot lists about 1.39M by VG Insights, 1.48M by Gamalytic, and 2.08M by PlayTracker, so the defensible range is "1M+ confirmed, likely materially above that on Steam."
- SteamDB snapshot on 2026-04-15 showed 950 players live, 1,595 24-hour peak, and an all-time peak of 12,832 on 2023-12-10. That indicates a healthy long tail for a premium single-player strategy game rather than a launch-only spike.
- SteamDB lists 35,639 Steam reviews and a 92.79% SteamDB rating, with 33,749 positive and 1,890 negative reviews. Metacritic is more muted at 7.9 user score, with some negative user comments criticizing repetition and reset fatigue.
- DLC reception appears positive but smaller scale. Steam pages list Keepers of the Stone as Very Positive at 82% of 390 reviews and Nightwatchers as Very Positive at roughly 85% of about 190 reviews. This suggests an engaged expert audience rather than mass-market DLC conversion.
- Current content footprint is still expanding: DLC added Frogs, Bats, four DLC biomes, new orders, new world events, new buildings, and new meta upgrades. The game is not live-service structured, but its post-launch support materially deepened build variety.

## Design Lineage

Against the Storm inherits city-builder resource chains from Banished, Anno, Settlers, and survival builders; pressure management and civic triage from Frostpunk; procedural run adaptation from roguelites; and draft-driven build planning from deckbuilders. The key departure is that it rejects the genre fantasy of the permanent city. PC Gamer frames each settlement as doomed by the Blightstorm, while OpenCritic's excerpts repeatedly praise the city-builder/roguelite hybrid as the novelty.

The closest design move is not "make a city builder harder"; it is "make the city builder finite." A run ends when reputation is secured or impatience fails, so the game can ask for sharp, irreversible economic choices without asking the player to preserve a beautiful city forever.

## Audience & Commercial Context

The target audience is core strategy players who enjoy optimization, adaptation, and procedural problem solving. It is approachable compared with Dwarf Fortress or Workers & Resources, but still dense: NintendoWorldReport's console review, via OpenCritic, praised the port while warning that the learning curve is steep and controller play adds friction.

The game is a breakout for a small studio in a niche segment. It won strong critic consensus, sold over 1M Steam copies, and retained a substantial review base. It also has unusually high appeal to players who like roguelites but do not normally commit to long city-builder campaigns, because the settlement cadence creates a repeated "fresh start" hook.

## Game Systems

### Player Role & Agency

The player is the Queen's Viceroy: not a mayor caring for one beloved city, but a state agent building extraction outposts for the Smoldering City. This framing makes harsh optimization emotionally coherent. You are expected to prioritize survival, tribute, and progress across a cycle, not local permanence. The role also justifies the main pressure meters: reputation is proof of usefulness, while Queen's Impatience is the recall timer.

Agency is mostly medium-frequency strategic triage. Every few minutes, the player chooses blueprints, orders, glade openings, fuel policy, worker allocation, species favoritism, trade, consumption rules, and whether to convert danger into reputation. The Viceroy role makes those tradeoffs feel like expedition command rather than urban beautification.

### Settlement Win/Loss Pressure

Settlements are won by filling the Reputation bar. The official wiki says normal biomes require 12 reputation on Settler, 14 on Pioneer through Viceroy, and 18 on Prestige 1+, with reputation earned through orders, caches, glade events, high Resolve, traders, and cornerstones. Queen's Impatience is the loss clock: the official wiki states it rises every minute, has a maximum of 14, and is reduced by reputation by default.

This creates a strong dual-meter race. Progress lowers pressure, but slow play raises risk. Crucially, Impatience also reduces Hostility, so the loss clock has a partial rubber-band effect that can keep a struggling run playable.

### Hostility, Seasons, and Forest Mysteries

Hostility is the forest's escalating resistance. The official wiki says every Hostility level above 0 lowers global Resolve by 2 and triggers negative Forest Mysteries during Storm season. Hostility rises from time, opened glades, villagers, and active woodcutters, with higher difficulty scaling those inputs.

The hook is that expansion is both necessary and dangerous. More glades mean food, events, geysers, and resources, but also worse storms and lower Resolve. Players engage because the forest is not just a map generator; it is an opponent that prices curiosity.

### Species, Resolve, and Needs

Each settlement has only three species, determined at embarkation. The official wiki currently lists Humans, Beavers, Lizards, Harpies, Foxes, Frogs, and Bats, each with different base Resolve, resilience, demand threshold, decadence, hunger tolerance, needs, and specializations. Resolve below 1 causes villagers to leave; high Resolve can generate reputation.

This system makes population composition a strategic constraint rather than flavor. Food, housing, services, and work assignments are not universally good in the same way for every group. PC Gamer specifically praised the race-specific needs as both an economic puzzle and a source of personality.

### Drafted Blueprints and Production Chains

The official wiki states that viceroys start with essential blueprints, then gain new blueprint choices by earning reputation; traders can also sell blueprints. This turns production chains into a draft. The player may need flour, tools, coats, or luxury goods, but cannot assume the ideal building appears.

The system was received as central to the game's replayability. PC Gamer highlights the frustration and delight of wanting baked goods but lacking a mill, concluding that the run forces adaptation instead of a comfortable routine.

### Orders, Glade Events, and Reputation Routes

Orders are semi-random objectives that grant reputation and rewards. Glade Events are discoveries in opened glades; the official wiki says most offer two choices, usually converting a risk into resources, survivors, Amber, or reputation, with an investigation cost or temporary penalty.

This gives the game multiple victory paths. A run can win through orders, Resolve, cache turn-ins, glade events, trade synergies, or cornerstones. The strongest runs usually stack several routes rather than relying on one.

### World Map, Cycles, and Meta-Progression

The World Map is where players choose missions outward from the Smoldering City toward Seals. The official wiki states that completed settlements reveal nearby tiles, tiles have minimum difficulties at distance thresholds, and biome/modifier rewards feed Citadel upgrades. Upgrades spend Citadel resources and improve future settlements through permanent bonuses, unlocks, embarkation range, trader speed, housing, rainpunk, and other systems.

The retention trick is that a failed or mediocre run still teaches and usually advances the account. PC Gamer specifically praised the Smoldering City tree for making the next expedition better equipped.

### Trade and Economy

Trade works as both safety valve and engine. Traders can sell missing resources, perks, and sometimes blueprints, while trade routes and Amber open alternative ways to convert excess goods into missing links. Higher-level play often uses trade to patch draft gaps, turn pack production into reputation, or buy tempo before a storm.

The design value is that scarcity is rarely absolute. The player is squeezed, but there are enough conversion systems to feel clever instead of doomed.

### Rainpunk and Blightrot

Rainpunk lets players use rainwater to boost buildings. The official wiki says rainwater comes from collectors and geysers, and engines can increase production speed, double-yield chance, or worker Resolve. The tradeoff is Blightrot generation and extra management.

This is an elegant mid-game layer: the same storm that threatens the settlement becomes a power source. It reinforces theme while adding a high-risk optimization lever for expert players.

### UI and Information Design

The PC UI carries a heavy amount of data: recipes, ingredients, worker travel, needs, hostility, storm effects, blueprint pools, and event costs. Critics largely found it readable on PC, but console reviewers noted added control friction. The design succeeds because most systems expose their numbers, but the amount of information still contributes to the learning cliff.

## What It Did Well

- Turned "temporary cities" from a potential loss of attachment into the central hook. PC Gamer and OpenCritic excerpts repeatedly praise how finite settlements make the genre feel fresh.
- Built a dense but legible web of tradeoffs. Reputation lowers Impatience; Impatience lowers Hostility; Hostility lowers Resolve; Resolve can produce Reputation. The loops interlock cleanly.
- Used drafting to force adaptation without making runs feel random-only. Blueprint uncertainty changes plans, while traders, orders, embarkation choices, and meta upgrades provide agency.
- Made factions matter mechanically. Species needs, thresholds, specializations, and resilience create real population identities.
- Kept long-term motivation through meta-progression that expands options rather than only inflating numbers.
- Achieved strong market fit for a niche hybrid: 91 Metacritic, "Mighty" OpenCritic consensus, 1M+ confirmed Steam sales, and a persistent Steam player base.

## What It Did Poorly

- Reset fatigue is the main recurring criticism. Some Metacritic user reviews and Reddit discussion argue that repeatedly starting settlements can become formulaic, especially when early build orders converge.
- Complexity can overwhelm new players. OpenCritic's NintendoWorldReport excerpt notes a steep learning curve, and console controls make the density more noticeable.
- The city-builder fantasy of permanent growth is intentionally sacrificed. This is a strength for roguelite pacing but a dealbreaker for players who want to watch one city mature.
- Balance can push players toward known strong patterns. Reddit strategy discussion points to repeated early setups and high-value production paths, such as building materials, fuel, and tools, becoming dominant.
- DLC reception is positive but less emphatic than the base game. Keepers of the Stone was generally liked by existing players, but its review volume and scores suggest expansion content is mostly for the converted.

## Standout Mechanics

### Reputation vs. Queen's Impatience

How it works: Reputation is the win bar; Queen's Impatience is the loss bar. Reputation is earned through objectives, glade events, caches, high Resolve, trade, and cornerstones. Impatience rises over time to 14 and falls when reputation is gained.

Why it works: The design converts a long-form city-builder into a timed expedition. The player is not optimizing for forever; they are optimizing for enough success before recall. The Impatience/Hostility inverse relationship adds nuance because pressure can also lower forest danger.

What people loved: Critics praised the constant decision pressure and finite-run structure. PC Gamer's 91 review calls the game a "well-designed, charming, enthralling roguelike city builder."

What people criticized: Players who want traditional city permanence find the reset structure unsatisfying.

### Hostility-Priced Exploration

How it works: Opening glades provides resources and events but increases Hostility; years, population, and active woodcutters also raise it. During Storm season, Hostility triggers negative mysteries and Resolve penalties.

Why it works: It makes map expansion a real bet. The forest is not empty space to exploit; it is a risk budget. This prevents the dominant city-builder instinct of expanding as fast as possible.

What people loved: PC Gamer highlights the tension around how fast to cut into the forest. Reddit discussion also centers on glade timing and the risk/reward of dangerous openings.

What people criticized: Once players internalize high-value patterns, exploration can become less mysterious and more optimization-scripted.

### Blueprint Drafting

How it works: The player has a small essential build set, then drafts new blueprints from limited choices when reputation thresholds are hit. This determines which production chains are practical in the current run.

Why it works: It creates roguelite variability without abandoning city-builder logic. The run is not "can I execute my favorite economy," but "what economy can I build from this hand."

What people loved: PC Gamer explicitly identifies semi-randomized workshops as the source of the resource puzzle and replayability.

What people criticized: Some players dislike when missing blueprints block the most satisfying solution to a known need.

### Species Resolve as Economy and Characterization

How it works: Species have different needs, thresholds, resilience, and work bonuses. Satisfying needs raises Resolve; high Resolve generates reputation; low Resolve can cause departures and impatience penalties.

Why it works: The same system does three jobs: emotional texture, resource demand, and victory path. Favoring one species can be a strategic act rather than a moral cosmetic choice.

What people loved: Reviews praise the personality and balancing act created by species-specific desires.

What people criticized: Needs multiply the information load, especially when three species, multiple food chains, and storm penalties collide.

### Finite Settlements with Persistent Account Growth

How it works: Each city is temporary, but Citadel resources, upgrades, unlocked blueprints, deeds, and world-map progress persist. The official wiki lists seven great work projects that permanently improve future settlements.

Why it works: It resolves a common roguelite problem: failure still has value, but the run itself remains tense because the settlement can be lost. The account grows horizontally through options and resilience.

What people loved: PC Gamer called the incremental Smoldering City progress a major motivation to keep playing.

What people criticized: Meta upgrades can make early-game repetition feel more visible, because players are often replaying the same settlement opening with slightly different bonuses.

## Player Retention Mechanics

- Run novelty: biome, map modifier, species trio, blueprint draft, orders, glade events, traders, and forest mysteries vary each settlement.
- Medium-session cadence: settlements are long enough to build attachment but short enough to finish without campaign sprawl.
- Meta-progression: Citadel upgrades add permanent bonuses, unlock systems, and widen the viable starting envelope.
- Skill progression: players learn how to time glades, stack Resolve, exploit trade, and pivot around missing blueprints.
- Difficulty ladder: higher difficulties and Prestige modifiers add mechanical constraints rather than just numerical health scaling.
- Seals and cycles: world-map route planning gives runs a campaign context and a reason to push outward.
- DLC species and biomes: Frogs, Bats, Coastal Grove, Ashen Thicket, Rocky Ravine, and Bamboo Flats add new constraints for expert players.

## Community Sentiment Over Time

Sentiment has remained strongly positive from 1.0 through the 2025 console and DLC releases. The base game has broad critic acclaim and strong Steam review volume. Community criticism is not mainly about bugs or broken promises; it is about taste and repetition: whether a roguelite city builder remains exciting after the player solves its early settlement patterns.

The console release broadened the audience, but reviews note that PC remains the cleaner fit because the UI and management density favor mouse and keyboard. DLC sentiment is positive but more specialized, suggesting the game retained a loyal expert base rather than repeatedly resetting the market.

## Comparable Games

- Banished: shared survival settlement DNA, but Banished is about sustaining one town; Against the Storm is about repeated finite settlements.
- Slay the Spire: shared draft-and-adapt structure, but Against the Storm translates "deck" variance into buildings, orders, and resource chains.
- Frostpunk: shared civic pressure and moral triage, but Frostpunk is authored and campaign-like; Against the Storm is procedural and repeatable.
- Northgard: shared compact RTS/city-builder hybrid pressure, but Northgard is more territorial and adversarial; Against the Storm is more economic and roguelite.
- Timberborn: shared beaver-adjacent survival building and water pressure, but Timberborn emphasizes engineering permanence while Against the Storm emphasizes expedition tempo.

## Design Takeaways

- A city builder can use impermanence as a feature if the fiction, win condition, and meta-progression all agree that the city is an expedition, not a home.
- Pairing a win clock with a loss clock creates clear tension; linking those clocks to secondary systems creates comeback texture instead of pure punishment.
- Drafted infrastructure is a powerful way to create replayability in management games, but players need fallback conversion systems so randomness feels like adaptation rather than denial.
- Population types become memorable when their identity changes production math, morale thresholds, and victory routes at the same time.
- Exploration is more interesting when new space has an explicit systemic price. "Open the map" becomes a strategic wager, not a default action.
- Meta-progression should unlock new tools and planning dimensions, not just raise passive stats. Against the Storm does both, but its best unlocks are new systems and blueprint possibilities.
- Finite-session strategy games can support deeper complexity than endless builders because players are repeatedly re-onboarded into a new problem space.
- The main design risk of procedural management is opening repetition. If early minutes converge too strongly, players notice the reset loop more than the run variety.

## Sources

- Metacritic - Against the Storm PC scores and user reviews - https://www.metacritic.com/game/against-the-storm/
- OpenCritic - Against The Storm review aggregate and critic excerpts - https://opencritic.com/game/13940/against-the-storm
- PC Gamer - Len Hafer - Against the Storm review - https://www.pcgamer.com/against-the-storm-review/
- PC Gamer - Christopher Livingston - 1M Steam sales milestone - https://www.pcgamer.com/games/city-builder/one-of-our-favorite-city-builders-has-sold-over-a-million-copies-on-steam-and-theres-an-expansion-on-the-way/
- PC Gamer - Phil Savage - 2024 feature on the game's city-builder design - https://www.pcgamer.com/games/strategy/against-the-storm-looks-charming-and-cosy-but-its-actually-the-best-and-most-fiendish-city-builder-ive-played-in-years/
- Rock Paper Shotgun - Liam Richardson - Against The Storm review, cited via OpenCritic excerpt - https://opencritic.com/game/13940/against-the-storm/reviews
- GameSpot/GameFAQs - platform listing; no GameSpot editorial review found in search - https://gamefaqs.gamespot.com/ps5/524212-against-the-storm
- IGN Benelux - console review excerpt via Metacritic Switch critic page - https://www.metacritic.com/game/against-the-storm/critic-reviews/?platform=nintendo-switch
- Steam - Against the Storm store page - https://store.steampowered.com/app/1336490/Against_the_Storm/
- SteamDB - Against the Storm charts, reviews, and owner estimates - https://steamdb.info/app/1336490/charts/
- Steam - Keepers of the Stone DLC page - https://store.steampowered.com/app/3075500/Against_the_Storm__Keepers_of_the_Stone/
- Steam - Nightwatchers DLC page - https://store.steampowered.com/app/3725110/Against_the_Storm__Nightwatchers/
- Gematsu - Sal Romano - console release announcement - https://www.gematsu.com/2025/04/against-the-storm-coming-to-ps5-xbox-series-ps4-xbox-one-and-switch-on-june-26
- Official Against the Storm Wiki - Reputation - https://wiki.hoodedhorse.com/Against_the_Storm/Reputation
- Official Against the Storm Wiki - Queen's Impatience - https://wiki.hoodedhorse.com/Against_the_Storm/Queen%27s_Impatience
- Official Against the Storm Wiki - Hostility - https://wiki.hoodedhorse.com/Against_the_Storm/Hostility
- Official Against the Storm Wiki - Resolve - https://wiki.hoodedhorse.com/Against_the_Storm/Resolve
- Official Against the Storm Wiki - Villagers and species - https://wiki.hoodedhorse.com/Against_the_Storm/Species
- Official Against the Storm Wiki - Blueprints - https://wiki.hoodedhorse.com/Against_the_Storm/Blueprints
- Official Against the Storm Wiki - Glade Events - https://wiki.hoodedhorse.com/Against_the_Storm/Glade_Events
- Official Against the Storm Wiki - Rainpunk - https://wiki.hoodedhorse.com/Against_the_Storm/Rainpunk
- Official Against the Storm Wiki - Upgrades - https://wiki.hoodedhorse.com/Against_the_Storm/Upgrades
- Official Against the Storm Wiki - World Map - https://wiki.hoodedhorse.com/Against_the_Storm/World_Map
- Reddit - r/truegaming discussion on city-builder roguelite repetition - https://www.reddit.com/r/truegaming/comments/1bhtp1n
- Eremite Games YouTube - Nightwatchers release date trailer and feature list - https://www.youtube.com/watch?v=7tms4xhzjPs
