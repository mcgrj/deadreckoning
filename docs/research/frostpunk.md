# Frostpunk — Design Research Report

## Overview

**Genre:** Society survival / city builder / survival management  
**Developer:** 11 bit studios  
**Publisher:** 11 bit studios  
**Release:** April 24, 2018 on Windows; later macOS, console, and mobile ports  
**Platforms:** Windows, macOS, PlayStation 4, Xbox One, Nintendo Switch, mobile  

Frostpunk casts the player as the ruler of humanity's last city, built around a coal-fired generator in a frozen alternate-history apocalypse. Its core identity is not a sandbox city builder but a scenario-driven survival drama: build infrastructure, assign labor, ration scarce resources, pass laws, and decide how far society should go to survive.

11 bit studios calls it "the first society survival game" and frames the player's duty as managing both citizens and infrastructure. The official 11 bit page lists an 84 critic score, matching the broad Metacritic consensus for the PC version. [11 bit studios](https://11bitstudios.com/games/frostpunk/)

**Research note:** IGN, Rock Paper Shotgun, and GameSpot were searched as requested, but the available browser surface did not expose the original 2018 review pages reliably. This report cites accessible professional and primary sources instead: PC Gamer's developer interview, SteamDB, 11 bit studios, Polygon's retrospective comparison via Frostpunk 2, Frostpunk wiki mechanics pages, Reddit community discussion, and Metacritic query results where available.

## Market Performance

Frostpunk was a strong commercial and long-tail success for 11 bit studios. SteamDB reports, as of April 12, 2026, approximately 5,729 players online, a 24-hour peak of 7,230, and an all-time Steam peak of 29,361 concurrent players on April 29, 2018. SteamDB also lists 133,075 Steam reviews, a 91.49% SteamDB rating, and 92.7% positive review share from the reviews it tracks. [SteamDB](https://steamdb.info/app/323190/charts/)

SteamDB owner estimates vary widely, from roughly 3.44 million to 7.83 million owners depending on tracker methodology, so these should be treated as third-party estimates rather than publisher disclosures. [SteamDB](https://steamdb.info/app/323190/charts/)

The game has unusual longevity for a tightly authored city-builder scenario game. Eight years after launch, it still has thousands of daily concurrent players on Steam, and the sequel discussion keeps the original in circulation. Polygon's Frostpunk 2 review explicitly compares the sequel's macro-scale design against the first game's immediacy, arguing that the first Frostpunk made every death, food shortage, cold home, and coal problem feel directly legible. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

## Design Lineage

Frostpunk grows directly out of 11 bit studios' previous work on This War of Mine, but changes the scale. In PC Gamer's developer interview, lead designer Kuba Stokalski says the team wanted to move from individual survival to the level of societies, keeping serious themes and meaningful survival choices while making something larger than a sequel. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

The lineage is best understood as a hybrid of:

- **Survival management:** heat, food, medicine, labor, and shelter are existential rather than optimization-only resources.
- **City building:** layout, production chains, research, labor assignment, and generator coverage are central.
- **Moral-choice narrative games:** the law system and event chains force the player to trade values for survival leverage.
- **Scenario strategy:** A New Home has an authored arc with escalating pressures and a final storm, closer to a survival novel than an endless sandbox.
- **Society simulation:** people are not just anonymous population points; they are workers, children, sick, hungry, faithful, rebellious, and occasionally named in events.

Stokalski explicitly describes the team as less concerned with genre boundaries than with the intended emotional experience. The design questions were whether simulation systems, tech tree content, society decisions, and art converged on the central themes of survival and the limits of society. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

## Audience & Commercial Context

Frostpunk was designed for core strategy and survival players willing to tolerate stress, scarcity, and moral discomfort. It is more approachable than a grand strategy game because the scenario arc is clear and the city footprint is constrained, but harsher than many city builders because failure can cascade quickly and citizen deaths are emotionally foregrounded.

Its audience fit is "designerly hardcore": players who enjoy optimizing production chains but also want the optimization to mean something. The core hook is not merely "can I build a stable economy?" but "what am I willing to normalize in order to keep people alive?"

Commercially, Frostpunk is a breakout rather than a cult title. It had a major launch peak, sustained high Steam review volume, and enough brand strength to support DLC, console/mobile ports, a board game, and Frostpunk 2. The sequel's reception also reveals what players valued in the original: immediacy, personal stakes, and clear consequences at the level of individual citizens. [SteamDB](https://steamdb.info/app/323190/charts/) [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

## Game Systems

### Player Role & Agency

**What it is:** The player is the ruler of the last city, with authority over labor, infrastructure, law, faith/order institutions, scouting, and emergency measures.

**How it works:** Agency is centralized and paternalistic. Citizens make requests and issue ultimatums, but the player chooses work assignments, building priorities, laws, research, scouting targets, rations, and heat allocation. The game gives broad power but attaches visible social meters and event consequences to that power.

**How it was received:** The role framing was central to the game's appeal. PC Gamer's interview emphasizes that the team wanted to ask how far a society and its leader would go under survival pressure. Polygon's retrospective comparison of Frostpunk 2 to Frostpunk suggests the first game's leader role worked because individual problems had fast, concrete effects: cold homes, no food, untreated sickness, and citizen deaths were legible. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/) [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

**Player hooks:** The hook is responsibility. You can usually see how the crisis is partly your fault, and you can usually solve it by crossing some new line: emergency shifts, child labor, soup, propaganda, public penance, or authoritarian control. That creates strong ownership over both survival and moral compromise.

### Heat, Generator, and Weather

**What it is:** Heat is the survival spine of the city. Weather falls over time, the generator consumes coal, and each building's heat level determines sickness risk.

**How it works:** The generator creates a heat zone, later extended by range upgrades or steam hubs. Workplaces and homes also have insulation, heaters, or other modifiers. The Frostpunk wiki records heat bands from Comfortable at 0C and above, through Livable, Chilly, Cold, and Very Cold; those bands affect whether people become ill or gravely ill. A building's effective temperature is a sum of weather, insulation, and heat sources. [Frostpunk Wiki: Heat](https://frostpunk.fandom.com/wiki/Heat)

**How it was received:** Critics and players frequently describe Frostpunk as tense because weather is not backdrop. Polygon's Frostpunk 2 review uses the original as the positive contrast: lack of coal, food, or treatment caused tangible deaths and social consequences. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

**Player hooks:** Heat makes the city physically readable. The circular layout around the generator turns survival into spatial prioritization: who gets warmth first, what can be allowed to freeze, and how much coal security justifies delaying food, medicine, or housing.

### Resource Economy and Labor

**What it is:** The player must produce coal, wood, steel, food, and medical capacity while maintaining enough workers, engineers, and children to staff the economy.

**How it works:** Early play starts with gathering piles and basic buildings, then moves toward mines, sawmills/wall drills, steelworks, hothouses/hunters, cookhouses, medical posts, workshops, and advanced versions through research. Labor classes matter: engineers are needed for workshops and medical posts, workers cover most extraction and industry, and children are initially non-workers unless laws change their role.

**How it was received:** The economy was praised because it feeds moral decisions instead of sitting separate from narrative. PC Gamer's developer interview frames the game's systems as being built in service of theme, not genre purity. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**Player hooks:** The production loop is strong because every surplus is temporary. Coal abundance can vanish when temperature drops, food stores can dissolve after refugees arrive, and sickness can quietly remove labor from the economy until the production plan collapses.

### Book of Laws

**What it is:** The law system lets the player reshape society through Adaptation laws and, later, Purpose laws such as Order or Faith.

**How it works:** Laws unlock new buildings, abilities, social norms, and tradeoffs. Adaptation laws address survival pressure: emergency shifts, extended shifts, child labor or child shelters, soup or food additives, care houses, corpse disposal, radical treatment, and related measures. Purpose laws create ideological infrastructure: Order can build guard stations, propaganda, prisons, and forceful control; Faith can build houses of prayer, shrines, faith keepers, public penance, and a religious social order.

PC Gamer's interview is the key primary source here. Marta Fijak explains that early builds made laws appear mostly as reactive pop-ups, but the team changed this because it did not give the player enough agency over when and how to shape society. The Book of Laws gave the team sequence, escalation, and "creeping normality": each individual step could look defensible, while the full path could become terrifying. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**How it was received:** The law system is one of the game's signature mechanics because it fuses strategy and moral narrative. The player is not simply choosing "good" or "evil"; they are responding to pressure and then watching the city normalize those responses. PC Gamer's interview notes that the team avoided giving players a fixed moral ruler and wanted each player to feel where their own line was. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**Player hooks:** Laws are compelling because they are delayed bargains. A law solves a concrete problem now, opens a branch later, changes citizen expectations, and becomes part of the end-state story of the city.

### Hope and Discontent

**What it is:** Hope and Discontent are the city's two high-level social feedback meters.

**How it works:** Discontent tracks friction from unmet needs and coercive measures: cold, hunger, deaths, overtime, unpopular laws, and similar pressures. Hope tracks whether society believes survival is possible and whether leadership has legitimacy. Both can be high or low rather than being a single happiness axis.

Fijak told PC Gamer that Discontent came naturally from citizens' needs, because the team wanted society to be represented as individuals rather than an abstract mood model. Hope came from survival research: the team found hope to be a recurring factor in stories of people enduring harsh conditions. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**How it was received:** The dual-meter model was widely remembered because it avoids generic happiness. A city can be angry but hopeful, obedient but despairing, or calm because it has been controlled. Polygon's comparison with Frostpunk 2 reinforces that the original's mood feedback worked because specific problems were immediately visible and emotionally connected to individual deaths and citizen needs. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

**Player hooks:** The system lets players read society as a pressure vessel. Discontent asks "how much pain are they tolerating?" Hope asks "do they still believe this is worth it?"

### Sickness, Medicine, and Death

**What it is:** Sickness converts cold and deprivation into labor loss, medical demand, amputations, and death.

**How it works:** Cold homes and workplaces increase illness risk; untreated sick citizens stop working; gravely ill citizens require stronger care or risk dying. Medical posts consume engineers, which competes with research. Laws can alter medical outcomes: radical treatment can save more gravely ill people at the cost of amputations, while sustain life keeps them alive but unproductive until better care is available.

The Heat wiki provides the mechanical bridge between temperature bands and sickness risk; Comfortable conditions avoid illness, Livable has very low risk, Chilly has low risk, and colder bands escalate danger. [Frostpunk Wiki: Heat](https://frostpunk.fandom.com/wiki/Heat)

**How it was received:** This system supports the game's immediacy. Polygon's Frostpunk 2 review says the original let players diagnose and act on sickness through the UI: increase generator heat, feed citizens, or build more hospitals. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

**Player hooks:** Medicine creates a clean strategic bind for maritime expedition design: the same expert class needed for long-term advancement is also needed to stop short-term death. That makes sickness a resource sink, a labor sink, and a narrative wound at once.

### Research and Technology

**What it is:** Workshops staffed by engineers research upgrades across heating, resources, exploration/industry, food/health/shelter, and scenario-specific systems.

**How it works:** Research speed depends on workshop capacity and engineers. Technologies improve generator range/power/efficiency, heaters, steam hubs, gathering, extraction, medical care, food production, housing, scouting, and automation. The tech tree is not moral in the same way as laws, but it determines whether the player can avoid harsher moral compromises later.

The Frostpunk wiki's Technology Tree page categorizes major tech tabs including Heating and Exploration & Industry, with scenario variants. [Frostpunk Wiki: Technology Tree](https://frostpunk.fandom.com/wiki/Technology_Tree)

**How it was received:** Research is usually less discussed than laws, but it is the quiet tempo engine of the game. Its value is that it turns foresight into mercy: better insulation, stronger heat, better medicine, and efficient coal reduce the need for emergency shifts and coercive law.

**Player hooks:** Research gives the player a constant "if I can just survive until this completes" tension. It is also a delayed consequence machine: a missed coal upgrade may not punish the player until the next temperature drop.

### Scouting and Expedition Narrative

**What it is:** Scouts leave the city to explore the Frostland, find survivors, recover supplies, and uncover the world narrative.

**How it works:** Beacon/scouting unlocks the strategic map. Scouts travel between nodes, encounter authored choices, and return or redirect with resources and survivors. Bringing survivors back increases labor and population, but also creates shelter, food, and medical burdens.

**How it was received:** Scouting works because it counterpoints the city loop. It gives narrative texture and surprise without breaking the survival economy. It also expands the apocalypse beyond the player's crater while still converting most discoveries back into city pressures.

**Player hooks:** Scouting offers hope and dread: every node might deliver coal, steam cores, workers, children, or evidence that no help is coming. For maritime expedition design, this maps cleanly to shore parties, wreck discoveries, ice leads, signal fires, abandoned ships, and moral salvage decisions.

### Scenario Structure and Ending Judgment

**What it is:** A New Home is an authored survival arc with phases: initial survival, social fracture, and the final storm.

**How it works:** The game escalates via temperature drops, citizen demands, refugee waves, scripted discoveries, and a final test. It ends with a time-lapse/log that reflects what the player built and what lines were crossed.

Stokalski told PC Gamer that the team wanted the ending to feel like a novel, not a typical endless sandbox. After iteration, an open-ended continuation after the storm felt anticlimactic because the scenario was about surviving something through sacrifice. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**How it was received:** The ending is a major part of the moral impact. PC Gamer's interview notes player defensiveness when the end log questions whether survival was worth the compromises. The developers intended that discomfort and did not want to answer it for the player. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**Player hooks:** The climax makes the whole run cohere. Instead of endless optimization, the game asks whether the player created a society that could survive the storm, then confronts them with what that society became.

## What It Did Well

- **Unified theme and system design.** PC Gamer's developer interview makes clear that economy, law, art, scenario pacing, and mood systems were judged by whether they served the survival-society theme. This is why the game feels coherent rather than like a city-builder with moral pop-ups attached. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)
- **Made consequences legible and fast.** Polygon's comparison to Frostpunk 2 identifies this as a core strength of the original: cold, hunger, sickness, and death were visible, diagnosable, and emotionally connected to the player's decisions. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)
- **Separated anger from belief.** Hope and Discontent create richer state space than a single happiness meter. The city can be furious but still believe in survival, or quiet because it has been controlled.
- **Turned laws into an escalation tree.** The Book of Laws makes each compromise feel small in isolation while giving the whole branch a recognizable moral trajectory. That is directly tied to the team's stated goal of modeling creeping normality. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)
- **Used authored pacing without killing systemic play.** A New Home has a novel-like arc, but the exact path through laws, research, casualties, shortages, and city layout remains systemic.
- **Sustained long-tail interest.** SteamDB's 2026 player and review data show a still-active audience years after release. [SteamDB](https://steamdb.info/app/323190/charts/)

## What It Did Poorly

- **Some systems are exploitable once understood.** A Reddit community post from 2024 describes a discontent exploit around disabling cold housing, showing that the mood system can be gamed in ways that undercut the fiction once players learn implementation details. [Reddit](https://www.reddit.com/r/Frostpunk/comments/1fe9ki3)
- **Replayability is lower than in procedural roguelikes.** Scenario authorship gives Frostpunk its narrative strength, but once players know event timing, storm preparation, and law tradeoffs, some surprise is lost. This is a tradeoff, not a pure flaw.
- **Moral choices can become optimization once mastered.** The first run asks "what am I willing to do?" Later runs can become "which laws are mechanically efficient?" The ending judgment helps, but mastery still compresses moral ambiguity.
- **Population abstraction can reduce individual attachment.** The game foregrounds individual deaths more than many city builders, but most citizens remain interchangeable labor categories. For a narrative roguelike about a maritime expedition, more persistent named characters would likely produce stronger personal consequence.
- **The pressure curve depends heavily on hidden future knowledge.** Delayed consequences are powerful, but players may feel punished for not knowing future temperature drops or event waves. Frostpunk mostly gets away with this through scenario clarity and replay learning, but it is risky in roguelike structures.

## Standout Mechanics

### Book of Laws as Creeping Normality

**How it works:** Laws are player-chosen societal changes with immediate benefits and long-term moral/narrative weight. They are sequenced so that early compromises create the path to later, more extreme institutions.

**Why it works:** The law system respects player agency. The game does not simply ambush the player with moral dilemmas; it lets the player request the tool that changes society. That creates culpability. Fijak's explanation that the system moved away from purely reactive pop-ups is important: the player must feel like an author of society, not just a respondent to designer prompts. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**What people loved:** The system is widely remembered because it makes survival optimization morally expressive. A law is not just a buff; it changes who the player is becoming as a leader.

**What people criticised:** On replays, laws can become a solved build order. If the moral line is known and the mechanical payoffs are known, the system needs scenario variation or character-specific consequences to stay fresh.

**Design tension:** The stronger the mechanical incentive, the easier it is for players to rationalize the moral compromise. That is the point, but it also risks becoming min-maxing if the narrative consequence is not persistent.

### Hope vs Discontent

**How it works:** Hope and Discontent are separate social meters. Discontent reflects pain, anger, and unmet needs. Hope reflects belief in survival and leadership. They move through laws, events, deaths, broken promises, successful promises, and institutional actions.

**Why it works:** The split creates a more useful design vocabulary than happiness. A maritime expedition could similarly separate **Morale** from **Trust**, **Fear** from **Resolve**, or **Order** from **Belief**. One meter measures immediate suffering; the other measures whether the group still accepts the mission's meaning.

**What people loved:** PC Gamer's interview focuses on this design decision because it stood out from standard city-builder happiness. Polygon's comparison with Frostpunk 2 suggests the original succeeded when these meters were tied to concrete causes and clear responses. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/) [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

**What people criticised:** Community exploit discussion shows that abstract mood systems can be manipulated if their triggers are too mechanical and not fictionally robust. [Reddit](https://www.reddit.com/r/Frostpunk/comments/1fe9ki3)

**Design tension:** A social meter must be legible enough to manage but not so mechanical that it loses moral force.

### Delayed Consequences Through Resource Foresight

**How it works:** Many decisions pay off later, not now. Research delays, law cooldowns, coal stockpiles, sickness risk, food reserves, and incoming temperature drops all create lag between choice and consequence.

**Why it works:** The delayed consequence is usually attached to a visible future threat or plausible systemic chain. If you delay coal research, the next cold snap exposes it. If you overwork people, discontent rises and sickness may increase. If you bring refugees back, labor rises but food, shelter, and medical demand also rise.

**What people loved:** The result is tension without relying only on random events. The player often recognizes that a disaster was seeded by earlier priorities.

**What people criticised:** Delays can become harsh for first-time players when future scenario beats are unknown. The lesson is to telegraph enough that failure feels like consequence, not designer ambush.

**Design tension:** Delayed consequences are strongest when the player can reconstruct causality after the fact. If they cannot, the story becomes noise.

### Scenario-as-Novel Structure

**How it works:** Frostpunk's main scenario has a finite dramatic arc and culminates in the storm. The ending log reflects survival and moral choices.

**Why it works:** The fixed endpoint lets the game intensify rather than flatten into endless city-builder equilibrium. Stokalski's "novel" framing explains why the game ends after the climax: continuing would weaken the survival story. [PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)

**What people loved:** The final storm gives the run shape and retrospection. The player does not simply win by optimizing forever; they endure a test and then face what they did.

**What people criticised:** Finite authorship can reduce long-term replay once timings are known. Endless modes help but are not the source of the game's strongest narrative identity.

**Design tension:** Roguelike replayability wants variation; authored survival narrative wants escalation and closure. A maritime roguelike can reconcile this by generating expedition arcs with variable crises but preserving a clear voyage climax.

### Citizen Requests and Promises

**How it works:** Citizens ask for warmth, homes, food, medical care, cemetery rituals, child protections, and other commitments. The player can accept promises, gaining a chance to restore Hope, but failure creates backlash.

**Why it works:** Promises convert abstract needs into social contracts. "Build houses" is an optimization task; "you promised these people shelter" is narrative pressure.

**What people loved:** This reinforces the ruler role and makes production decisions feel accountable.

**What people criticised:** Like other event systems, repeated play can reveal which promises are safe and which are traps.

**Design tension:** Promises are most powerful when optional, specific, and trackable. If they are too frequent or too predictable, players stop reading them as human appeals.

## Player Retention Mechanics

Frostpunk's first-hour hook is the impossible survival fantasy: a generator, a crater, a few freezing citizens, and a list of urgent needs. The mid-game pull is escalation: new laws, new tech, new scouting discoveries, new temperature drops, and new social fractures. The end-game pull is the storm and the moral audit of the player's city.

Longer-term retention comes from:

- **Scenario mastery:** replaying A New Home to save more people, cross fewer lines, or optimize better.
- **Alternate scenarios:** different setups change priorities and social pressures.
- **Endless mode:** serves players who want more city-building survival than authored drama.
- **Moral experimentation:** players try Order vs Faith, harsh vs humane law paths, or challenge runs.
- **High review/community visibility:** the game remains recommended as a reference point for survival city-builders and moral management sims.

For a roguelike, the main lesson is that Frostpunk retention is not loot or meta-progression. It is mastery of pressure, alternate moral paths, and the desire to see whether one can survive with less damage.

## Community Sentiment Over Time

The original Frostpunk has aged well. SteamDB's 2026 data shows high review volume and a very positive review distribution, with thousands of players still active daily. [SteamDB](https://steamdb.info/app/323190/charts/)

The release of Frostpunk 2 sharpened appreciation for the first game's design. Polygon's Frostpunk 2 review argues that the sequel's broader, macro-scale society management lost some of the original's immediacy and personal connection. This is useful evidence for designers: the emotional effect of a survival sim depends heavily on scale, cadence, and the clarity of feedback. [Polygon](https://www.polygon.com/review/451819/frostpunk-2)

Community discussion also reveals mastery-side issues. The Reddit discontent exploit post is not just a bug note; it shows how players eventually reverse-engineer social systems. When the implementation does not match the fiction, high-skill players may break the intended emotional reading. [Reddit](https://www.reddit.com/r/Frostpunk/comments/1fe9ki3)

## Comparable Games

- **This War of Mine:** Same studio, similar moral-survival focus, but intimate household scale instead of society/city scale. Frostpunk converts the human cost of survival into civic authority and infrastructure.
- **Against the Storm:** A roguelite city builder with repeated settlement runs, meta-progression, and pressure systems. It has stronger procedural replayability but less authored moral escalation.
- **Banished:** Survival city-builder with harsh resource and weather pressure, but less explicit narrative and moral law structure.
- **RimWorld:** Colony sim with stronger character simulation and emergent narrative, but less authored scenario pacing and less direct moral-meter framing.
- **Sunless Sea:** Maritime survival narrative with resource pressure, expedition dread, and storylet structure. It is highly relevant for nautical atmosphere, but Frostpunk is more legible as a systemic survival pressure machine.
- **Darkest Dungeon:** Roster stress and expedition attrition create moral pressure at a smaller scale. It is closer to a roguelike expedition loop than Frostpunk, but Frostpunk is stronger on civic law and collective mood.

## Design Takeaways

1. **Use two social meters when the fiction has two different questions.** Frostpunk's Hope/Discontent split works because "are they suffering?" and "do they believe in this?" are not the same. A maritime expedition could separate Fear, Trust, Morale, Discipline, or Resolve instead of collapsing crew state into happiness.

2. **Make authority mechanically useful and morally expensive.** The Book of Laws is powerful because it lets the player solve real problems by changing norms. For an expedition, this could be ration articles, emergency discipline, salvage rights, shore-party rules, burial customs, mutiny procedures, or command privileges.

3. **Let consequences arrive late, but make causality reconstructable.** Frostpunk's best delayed consequences feel seeded: cold creates sickness, sickness removes workers, worker loss reduces coal, coal loss worsens cold. The player can trace the chain. Avoid delayed penalties that feel like unrelated event cards.

4. **Sequence moral compromise.** The law trees work because each step can be justified locally. For a roguelike, small procedural escalations are stronger than one huge "evil choice." Let the player normalize a practice before confronting them with what it became.

5. **Keep scale close enough for responsibility.** Polygon's Frostpunk 2 comparison suggests that zooming out from hundreds of people to thousands can weaken emotional immediacy if feedback becomes less concrete. A maritime expedition has an advantage: a ship's crew can be named, tracked, and remembered.

6. **Tie narrative events to production systems.** Scouting nodes work because discoveries return as resources, survivors, or burdens. For a maritime expedition, islands, wrecks, illnesses, repairs, and omens should feed back into food, hull integrity, morale, crew trust, and route risk.

7. **Use a finite expedition arc, not endless drift.** Frostpunk's "novel" structure gives the run a climax. A maritime roguelike could generate the voyage, but each run should still have a readable beginning, crossing, crisis peak, and arrival/failure judgment.

8. **Audit exploitable abstractions against fiction.** If crew unrest, fear, or trust can be reset by a trick that makes no narrative sense, skilled players will find it and the system's emotional authority will degrade. Social systems need mechanical robustness and fictional robustness.

9. **End with judgment, not exposition.** Frostpunk's ending log matters because it recontextualizes the run as a society the player made. A maritime roguelike can do the same with an expedition ledger: who survived, what rules were adopted, what was abandoned, what truth was suppressed, and whether arrival was worth the cost.

## Sources

- 11 bit studios — Frostpunk official game page — https://11bitstudios.com/games/frostpunk/
- PC Gamer — Christopher Livingston — "Frostpunk developers on hope, misery, and the ultimately terrifying book of laws" — https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/
- SteamDB — Frostpunk Steam charts, reviews, and owner estimates — https://steamdb.info/app/323190/charts/
- Polygon — Nicole Carpenter — Frostpunk 2 review with comparison to Frostpunk's immediacy — https://www.polygon.com/review/451819/frostpunk-2
- Frostpunk Wiki — Heat mechanics — https://frostpunk.fandom.com/wiki/Heat
- Frostpunk Wiki — Technology Tree — https://frostpunk.fandom.com/wiki/Technology_Tree
- Reddit / r/Frostpunk — "Frostpunk's most broken mechanic (and how to abuse it)" — https://www.reddit.com/r/Frostpunk/comments/1fe9ki3
- Metacritic — Frostpunk aggregate page, searched for PC critic/user score — https://www.metacritic.com/game/frostpunk/
- Search query used but original review page not accessible in the browser: `site:ign.com/articles/2018/04/ IGN Frostpunk review 9`
- Search query used but original review page not accessible in the browser: `site:rockpapershotgun.com Frostpunk review Rock Paper Shotgun 2018`
- Search query used but original 2018 review page not accessible in the browser: `site:gamespot.com/reviews/frostpunk-review GameSpot`
