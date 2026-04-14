# This War of Mine — Design Research Report

## Overview

**Genre:** Survival management / 2D stealth scavenging / simulation-driven narrative  
**Developer/Publisher:** 11 bit studios  
**Initial release:** November 14, 2014 on Windows, macOS, and Linux; later released on mobile, PlayStation, Xbox, Switch, and newer consoles  
**Core pitch:** A civilian survival game set in a besieged city. Instead of commanding soldiers, the player manages a small household of noncombatants through hunger, illness, injury, depression, raids, winter, scarcity, and morally compromised scavenging.

**Critical reception:** Metacritic lists the original release at **83** with a user score around **8.2**; OpenCritic lists **85 Top Critic Average** and **87% critics recommend**. SteamDB shows roughly **105k Steam reviews** and a **91.49% SteamDB rating** as of April 2026.

**Why it matters for Dead Reckoning:** The game is a useful model for a simulation-driven narrative roguelike because it creates story out of state changes rather than authoring a conventional branching plot. Hunger, fatigue, theft, charity, death, and depression are not flavor; they are the narrative engine.

**Focused research lens for Dead Reckoning:** This report keeps the full research structure, but weights three transferable patterns most heavily:

- **Moral decisions as gameplay:** ethical choices emerge from resource operations, not from separate dialogue-choice morality menus.
- **Scarcity-driven tension:** scarcity is not just low inventory; it is the pressure that makes morally legible decisions unavoidable.
- **Character states impacting outcomes:** hunger, fatigue, injury, illness, and depression change what characters can do, how reliable they are, and how the player interprets their own choices.

Sources: Metacritic, OpenCritic, SteamDB, PC Gamer, GameSpot, Game Developer, 11 bit studios.

## Market Performance

This War of Mine became a long-tail commercial success rather than a small cult artifact. 11 bit studios announced in May 2022 that it had reached **more than 7 million players worldwide** alongside the Final Cut console launch. Earlier reporting in 2019 placed it at **4.5 million copies sold** and noted charity fundraising through DLC for War Child.

SteamDB data as of April 2026:

- **App ID:** 282070
- **Steam release:** November 14, 2014
- **Steam reviews:** about 105k, with about 92.8% positive visible review share
- **24-hour peak at capture:** about 1,190
- **All-time Steam concurrent peak:** 9,503 on June 22, 2017
- **Owner estimates:** approximately 4.32M by VG Insights, 6.46M by Gamalytic, 10.14M by PlayTracker; treat these as estimates, not publisher-confirmed sales

The important commercial lesson is that a severe, non-power-fantasy survival game could reach mass indie scale if its premise was legible and differentiated. Kacper Kwiatkowski, one of the designers and writers, wrote after release that he had expected the game to be niche and learned that players were more open to unusual, difficult ideas than he had assumed.

## Design Lineage

### Inversions Of War Games

This War of Mine is defined by inversion. Where most war games make ruins into cover and civilians into background, this game makes the civilian household the player’s operational center. PC Gamer described it as part life-sim and part 2D stealth action, influenced by Mark of the Ninja and accounts from people in war-torn countries. GameSpot explicitly framed it against games like Call of Duty and Spec Ops: The Line: the central question becomes “What happens when the food runs out?” rather than whether the player can win a firefight.

### Real-World Inspiration

Multiple sources connect the game to civilian experiences in besieged cities, especially Sarajevo and Eastern European wartime memory. The SAGE production-studies article describes 11 bit’s goal as “emotional realism”: not exact military simulation, but a system that represents famine, sickness, death, suffering, boredom, moral ambiguity, and trauma.

### Indie Systems Lineage

Kwiatkowski explicitly cites Papers, Please as inspiration: a “gamey game” with a visible loop whose decisions become the protagonist’s life. That is the closest design lineage for narrative structure. This War of Mine does not need deep dialogue trees because its strongest stories come from operational choices and their consequences.

## Audience & Commercial Context

The target audience is core indie/strategy/survival players who can tolerate bleakness, repetition, and imperfect agency in exchange for unusually strong theme-system alignment. Critics praised its moral force while warning that it could be exhausting, monotonous, or unrelentingly cruel.

This matters for a maritime expedition roguelike: This War of Mine is not a comfort loop. It retains players through personal attachment, systemic uncertainty, run variation, and the promise that “your” version of events will differ from a streamed or reviewed version. Kwiatkowski noted that YouTube and Twitch did not spoil the game the way they might spoil a linear story because viewers still wanted to experience their own playthrough.

## Game Systems

### Player Role & Agency

**What it is:** The player is not a hero, captain, commander, or soldier. The role is closer to household caretaker under siege.

**How it works:** Agency is indirect and constrained. The player assigns survivors to rest, craft, cook, guard, talk, scavenge, steal, trade, or fight, but the game continually narrows the available space through material scarcity, wound states, winter, hunger, and risk. The player’s “power” is mostly prioritization under loss.

**How it was received:** Reviewers saw the role inversion as the central achievement. OpenCritic’s excerpts from IGN and Game Informer praise it as a survival sim and a rejection of soldier glorification. GameSpot called it a survival horror game “of a very different, very literal kind.” Rock Paper Shotgun’s OpenCritic excerpt argued that even if the message was simply “war is hell,” the game carried it carefully and effectively.

**Player hook:** The player is made responsible without being made powerful. That is the key emotional device. In a maritime expedition game, the equivalent is not “be the heroic captain,” but “be the person whose rationing, watch rotations, and route choices make survival possible or impossible.”

### Day/Night Structure

**What it is:** A repeated two-phase loop: shelter management by day, scavenging by night.

**How it works:** During the day, snipers prevent leaving the shelter. Survivors cook, clear rubble, build furniture and survival equipment, repair, rest, treat wounds, trade with visitors, and console each other. At night, one survivor can scavenge a location while others sleep or guard. The wiki lists daytime as 6:00 to 20:00 and nighttime as 21:00 to 5:00, each compressed into about six real-time minutes.

**How it was received:** PC Gamer praised the two-phase structure as simple but effective: daytime confinement creates household pressure, while nighttime scouting creates stealth tension. GameSpot praised the intuitive controls and clear day/night loop but also found the day-by-day routine could become monotonous.

**Player hook:** Alternation creates rhythm and anticipation. The night produces resources and trauma; the day converts both into household consequences. For Dead Reckoning, a comparable loop could be “day at sea / night watch / landfall” or “sailing / maintenance / shore party,” where each phase feeds different state machines.

### Resource Management

**What it is:** The survival economy: food, water, medicine, bandages, fuel, components, weapons, tools, comfort items, trade goods, and building materials.

**How it works:** Food prevents hunger progression. Medicine and bandages address illness and wounds. Fuel heats the shelter and cooks meals. Components and parts become tools, beds, stoves, heaters, traps, water filters, and defensive upgrades. Scarcity forces triage: build a shovel or feed someone, burn a book or save morale, trade cigarettes or satisfy an addict, risk a dangerous location or steal from the vulnerable.

**How it was received:** PC Gamer called the resource management and stealth survival “deftly designed,” while noting that long-term goals like rain filtration or moonshine could feel almost unreachable. GameSpot praised how mundane needs became emotionally charged but criticized monotony once a routine set in.

**Player hook:** The resource layer works because supplies are not abstract points. Each item has moral, bodily, and temporal meaning. A bed is recovery; a book is warmth or sanity; medicine is someone else’s loss if stolen.

### Scarcity-Driven Tension

**What it is:** Scarcity is the central pressure generator. The game does not merely ask whether the player has enough resources; it asks which future failure the player is willing to risk.

**How it works:** Scarcity operates across several timescales. Immediate scarcity asks whether someone eats today, whether a wound gets bandaged, or whether a sick survivor gets medicine. Medium-term scarcity asks whether to build infrastructure, fortify the shelter, make tools, or preserve trade goods. Long-term scarcity asks whether to spend resources now and risk winter, crime waves, or a later raid. Because the same item can serve multiple needs, every spend has opportunity cost: fuel is heat, cooking, and survival; components are infrastructure or tools; medicine is recovery, trade leverage, or theft temptation.

The game reinforces scarcity with constrained collection. Only one survivor scavenges at night, backpack slots are limited, location danger varies, and the player must return before morning. A strong character may carry more but be more valuable at home; a stealthy or fast character may survive a dangerous run but come back exhausted or wounded. Scarcity therefore creates both planning tension and character-selection tension.

**How it was received:** Critics generally saw scarcity as the system that made the anti-war premise work. PC Gamer’s “boot to your throat” summary captures the pacing: pressure rises slowly until it becomes bodily and moral. GameSpot praised the way small household resources became emotionally loaded, while criticizing the same repetition when scarcity became routine rather than surprising.

**Player hook:** Scarcity turns optimization into drama. The most important design move is that “efficient” play can become morally ugly: stealing from an elderly couple may be a rational route to calories and medicine, but the simulation then forces the shelter to live with that rationality.

**Transfer to Dead Reckoning:** Expedition scarcity should not be a single stockpile meter. It should be a web of substitutable, morally charged resources: fresh water, salt meat, medicine, lamp oil, sailcloth, rope, coal, charts, livestock, morale objects, burial shrouds, religious comforts, and crew labor. The key is not “make everything scarce”; it is to make every scarce item answer more than one human need.

### Character State Simulation

**What it is:** Survivors are modeled through interacting condition states: hunger, tiredness, wounds, illness, morale/mood, sleep, addictions, and character traits.

**How it works:** The wiki breaks character states into major categories including mood, hunger, illness, wounded, tiredness, and sleep. Hunger progresses through visible severity levels and worsens other crisis states. Tiredness affects movement and available actions. Mood can degrade from normal to sad, depressed, and broken; at severe levels, characters slow down, refuse orders, become unresponsive, leave, or die by suicide. Characters also have traits, such as better trading, stealth, combat, speed, or carry capacity.

**How it was received:** This was widely recognized as the narrative heart of the game. GameSpot described remorse as tangible: after stealing, survivors may move slower, hang their heads, refuse tasks, sink into depression, or die. PC Gamer likewise described a depressed survivor ignoring commands, turning a resource failure into a character moment.

**Player hook:** Visible mechanical degradation turns “story” into operational friction. A maritime version could model cold, scurvy, faith, superstition, injury, exhaustion, loyalty, homesickness, guilt, and officer credibility as action modifiers rather than status text.

**Outcome impact:** The important design pattern is that states are not passive descriptors. They alter the run. A hungry survivor is not just narratively hungry; hunger worsens vulnerability and increases urgency. A tired survivor is worse at night duty and recovery planning. A wounded or sick survivor changes who can scavenge, who can guard, who needs bed space, and whether medicine is a present need or a trade resource. A depressed survivor can undermine the entire plan by moving slowly, refusing work, leaving, or dying. Character state is therefore a second economy layered over items: the player spends medicine, food, sleep, comfort, and moral compromise to preserve human capacity.

**Transfer to Dead Reckoning:** Crew states should directly affect expedition outcomes: a frostbitten sailor works rigging slowly; a resentful carpenter delays repairs; a guilt-ridden surgeon misjudges treatment; a hungry lookout misses hazards; a superstitious crewman spreads panic after an omen; a loyal but exhausted officer can hold discipline for one more watch at personal cost. The system should avoid states that are only adjectives in a character sheet.

### Moral Decisions As Gameplay

**What it is:** A consequence system where theft, murder, refusal to help, suffering, and death feed back into survivor morale and epilogue outcomes.

**How it works:** The game distinguishes ordinary scavenging from stealing owned supplies. Stealing from civilians or killing innocents can damage morale; helping others can improve it, though often at material cost. The wiki notes that negative moral events, crisis states, and witnessing suffering affect morale, while good deeds, being well fed, comfort furniture, conversation, and alcohol can help.

**How it was received:** The SAGE article identifies ambiguous moral choice as a key design method: altruism costs time and resources, but returning empty-handed can kill members of the shelter. Critics repeatedly praised the game for aligning moral and mechanical pressure, though some noted that the game sometimes denies logical actions or makes systems feel too blunt.

**Player hook:** It avoids “choose good or evil” framing. The player usually chooses between compromised survival options, then watches the crew/survivors interpret the action emotionally.

**Why it is gameplay rather than theme:** Moral decisions are embedded in ordinary verbs: take, leave, trade, help, attack, sleep, guard, feed, burn, build, treat, and return home. The game rarely needs a formal “moral choice” prompt because scarcity and character-state consequences make the action moral. Taking medicine from an occupied house is not a different input from looting an abandoned house; the difference is context, ownership, witness, need, and aftermath. That is the transferable design lesson.

**Outcome impact:** Moral choices change survivor states and available capacity. A successful theft can solve hunger while damaging mood. A generous act can cost supplies while stabilizing morale. Killing can remove a tactical threat while psychologically damaging the killer and the group. This means morality is not a parallel reputation track; it is a set of modifiers that re-enters the survival simulation.

**Transfer to Dead Reckoning:** Maritime moral choices should be operational: cut away a lifeboat to save the main ship, deny water to prisoners, press an exhausted crew into a dangerous repair, abandon a slow shore party before weather turns, burn a sailor’s keepsakes for warmth, conceal bad navigation news, ration by rank or by need, or punish theft to preserve discipline. The game should not label these “good” or “evil”; the crew, log, consequences, and later failures should do that work.

### Scavenging, Stealth, And Combat

**What it is:** A night exploration layer where one survivor searches a location for resources, trades, steals, sneaks, or fights.

**How it works:** Each location signals danger and likely resources. More valuable places are more likely to be inhabited or defended. Survivors have limited backpack slots. Movement and line-of-sight matter: walking is quieter, running creates sound cues, locked doors and rubble require tools, and NPCs may trade, flee, warn, investigate, or attack. Combat is possible but risky and intentionally unpleasant.

**How it was received:** PC Gamer connected the stealth layer to Mark of the Ninja and praised the sound/visibility tension. PCGamesN argued that combat’s unpleasantness was partly thematic but also partly bad design because clumsiness is not the only way to avoid empowerment. GameSpot similarly found moments where the simple interaction model blocked reasonable responses.

**Player hook:** The scavenging layer is strong because it is not just loot acquisition. It is reconnaissance, trespass, risk budgeting, and character selection. For a maritime game, shore parties should not just “roll for supplies”; they should carry reputational, bodily, and social consequences back to the ship.

### Shelter Building And Crafting

**What it is:** A home-base improvement system that transforms scavenged parts into survival infrastructure and small comforts.

**How it works:** Survivors use workstations to build beds, stoves, filters, heaters, traps, chairs, radios, tools, weapons, and other equipment. Improvements reduce future pressure but consume resources needed for immediate survival.

**How it was received:** GameSpot praised how the system made ordinary household tools meaningful; PC Gamer noted that development goals could feel unreachable under constant scarcity.

**Player hook:** The base is not a power fantasy. It is a fragile recovery machine. A maritime translation could treat the ship as the shelter: bilge pumps, galley, sick bay, sails, masts, boats, stores, spiritual comforts, charts, and crew spaces all compete for labor and scarce materials.

### Event And Phase System

**What it is:** A run-state system that changes conditions over time.

**How it works:** The game includes recurring broad events and phases such as winter, crime outbreaks, more violent raids, and changing trade conditions. Endings are reached by surviving to a ceasefire day, which varies by scenario/group. The radio gives advance information about weather, crime, shortages, and ceasefire rumors.

**How it was received:** Critics praised the mounting pressure but often noted the grind. The system is effective because the “same” loop gradually changes its coefficients: cold makes fuel more important, crime makes guarding and defenses more important, and scarcity makes moral costs more tempting.

**Player hook:** Phase changes let a finite set of systems tell a longer story. For a maritime roguelike, analogous run phases might include doldrums, storms, ice, mutiny rumors, disease, landfall scarcity, religious crisis, hull damage, and “rescue or destination nearby” rumors.

### Narrative System

**What it is:** Emergent narrative from mechanical consequences, supported by survivor bios, after-action notes, location vignettes, neighbor events, and epilogues.

**How it works:** The game has authored situations, but the strongest stories arise from who did what, when, under what pressure, and how the simulation responded. A theft is not just a resource transaction: it may appear in character notes, alter mood, change group behavior, and later shape an epilogue.

**How it was received:** Kwiatkowski calls the game’s awareness of itself as a videogame its strongest storytelling device: decisions made as gameplay become the story. GameSpot praised its “gripping, emotional storytelling and character development.” PCGamesN noted that the characters can be sparse on traditional characterization but still become vessels for stories because of what happens to them.

**Player hook:** The player can retell the run as a sequence of hard calls. That is exactly the type of retention a simulation-driven expedition roguelike should target.

### Roguelike / Run Structure

**What it is:** A survival run through a semi-randomized war until ceasefire or collapse.

**How it works:** Runs start with different survivor groups, scenarios, locations, and resource conditions. There is no respawn for dead survivors. Failure is not just a reset state; it is framed as part of the story. Later updates added custom characters, scenarios, modding tools, and story DLC.

**How it was received:** Kwiatkowski wrote that the team did not initially plan failure as a major storytelling device, but discovered through streams that player failure could be the most interesting part of a playthrough. The SAGE article also identifies permanent death and lack of onboarding as intentional design tools aligned with civilian wartime experience.

**Player hook:** The run is not “one more try to optimize a build” as much as “one more life under different conditions.” For Dead Reckoning, the lesson is to make run failure produce a legible expedition history, not just a score screen.

## What It Did Well

- **Theme-system alignment:** Hunger, fatigue, theft, depression, and death all reinforce the civilian-war premise. Critics broadly agreed the message landed because the systems carried it.
- **Role inversion:** The game differentiated itself commercially and critically by rejecting war-game empowerment.
- **Mechanical storytelling:** Kwiatkowski’s design note and Steam/community reception both support the same point: players retell their playthroughs as stories because their decisions have narrative consequences.
- **Moral ambiguity without menu morality:** The best choices are operationally motivated and emotionally judged after the fact.
- **Readable loop:** Day management and night scavenging are easy to understand, which lets emotional complexity sit on top of simple inputs.
- **Failure as content:** Permanent loss and traumatic collapse produce memorable endings instead of feeling purely like invalid play.
- **Atmosphere through pacing:** Slow, repetitive, constrained tasks produce dread and boredom, not just “dark” art direction.

## What It Did Poorly

- **Monotony:** GameSpot and PC Gamer both identify repetition/grind as a real cost. The loop’s atmospheric repetition can become mechanical boredom once the player stabilizes.
- **Clumsy or limited agency:** GameSpot and PCGamesN both note cases where the game’s simple interaction model prevents plausible actions, especially around combat or intervention.
- **Blunt misery curve:** PC Gamer praised the point while warning that the experience is unrelentingly cruel. This limits broad appeal and can exhaust players before mastery emerges.
- **Simple gameplay elements:** Game Informer’s OpenCritic excerpt praised the emotional journey but described the gameplay elements as somewhat simple.
- **Risk of optimal-play erosion:** Once players learn efficient shelter routines, the moral pressure can soften unless events, traits, and scarcity keep destabilizing the run.

## Standout Mechanics

### Civilian Role Framing

**How it works:** The player manages vulnerable civilians rather than fighters. Snipers enforce daytime confinement, scarcity enforces scavenging, and the social/morale model enforces consequence.

**Why it works:** It makes common survival actions morally legible. Taking medicine is not heroic or villainous by category; it depends on who needed it and what it does to the group afterward.

**What people loved:** Critics consistently praised the inversion of war-game norms. OpenCritic excerpts from IGN, Game Informer, Eurogamer, PC Gamer, and GameSpot all describe the game as powerful because it shifts attention away from military glory.

**What people criticised:** The same framing creates emotional fatigue. The game asks for a high tolerance for despair.

**Design tension:** The player must be responsible enough to feel guilt, but not powerful enough to solve the war.

### Morale As A Consequence Engine

**How it works:** Bad events and bad actions degrade survivor mood; good deeds, comfort, food, conversation, and some coping items can improve it. Severe depression turns into mechanical refusal, slowness, breakdown, departure, or suicide.

**Why it works:** It makes story consequences actionable. The “cost” of stealing is not an abstract morality counter; it can be a survivor who cannot work tomorrow.

**What people loved:** GameSpot and PC Gamer both anchor their reviews in moments where emotional state changes become the actual drama.

**What people criticised:** The system can feel punishing or too automatic. It also risks teaching players to optimize around morality once they learn thresholds.

**Design tension:** Hidden psychological math creates emotional plausibility but can frustrate players who want transparent planning.

**Specific lesson for Dead Reckoning:** The strongest version of morale is not a global happiness score. It is a set of stateful reactions that change agency: refusal, panic, silence, confession, desertion, loyalty tests, prayer, violence, malingering, reckless heroism, and social contagion. A ship crew also gives this system spatial and hierarchical texture: a bosun can hold a watch together, a surgeon can mask failures, a cook can become politically powerful through rationing, and an officer’s collapse can damage legitimacy more than an ordinary sailor’s collapse.

### Night Scavenging As Narrative Risk

**How it works:** One survivor leaves the shelter at night, enters a side-view location, and makes stealth/trade/theft/combat decisions under a time limit and inventory cap.

**Why it works:** The single-character expedition focuses risk. If that survivor dies, the household changes. If they steal, the household reacts. If they return empty-handed, someone may starve.

**What people loved:** PC Gamer praised the fog-of-war, sound, and slow stealth pacing; GameSpot praised how scavenging created morally specific stories.

**What people criticised:** Reviewers criticized occasional lack of logical interaction and clumsy combat.

**Design tension:** Combat must be frightening without becoming mechanically sloppy; shore-party design for Dead Reckoning should learn from this.

### Failure As Story

**How it works:** Death, breakdown, and collapse are persistent run outcomes, not temporary reload noise. Epilogues and survivor notes make loss part of the story fabric.

**Why it works:** Kwiatkowski argues that games often erase failure through checkpoints, while This War of Mine lets failure become the most interesting story event.

**What people loved:** Players and reviewers report runs as tragedies rather than merely failed attempts.

**What people criticised:** Constant loss can become emotionally flattening if not balanced by moments of relief, competence, and strange beauty.

**Design tension:** A roguelike expedition should let disasters become legend, but still needs enough tactical agency that players believe they authored the outcome.

### Day/Night Pressure Loop

**How it works:** Day is for repair, care, building, rest, and visitor events. Night is for scavenging, guarding, and sleep. The outcome of one phase sets the crisis of the next.

**Why it works:** It creates strong cadence and clean state transitions. Every night asks, “What risk will we take?” Every morning asks, “What did that cost?”

**What people loved:** Reviewers praised the clarity and effectiveness of the loop.

**What people criticised:** The loop can become a grind. Designers should preserve cadence while varying phase events, resource meanings, and social consequences.

## Player Retention Mechanics

- **Personal attachment:** Survivors gain meaning through what the player makes them do and what happens to them.
- **Run variation:** Different starting groups, location states, and events create retellable playthroughs.
- **Escalating phases:** Winter, crime, scarcity, and ceasefire rumors alter priorities without changing the core interface.
- **Crafting goals:** Beds, heaters, filters, traps, radios, and upgrades create medium-term aspirations.
- **Moral memory:** A run accumulates guilt, sacrifice, help given, and harm done.
- **Community shareability:** Kwiatkowski observed that streams and Steam reviews produced story-sharing rather than simply spoiling content.
- **Post-launch content:** Scenario editor, custom characters, modding tools, The Little Ones, Stories DLC, Anniversary Edition, Final Cut, and the 2024 Forget Celebrations charity DLC extended the game’s lifespan.

## Community Sentiment Over Time

Sentiment appears durable. The game still has a very positive Steam review profile more than a decade after launch, and 11 bit continued to release and promote new editions and charity DLC. Its cultural role also expanded: sources note museum/exhibition attention, charity partnerships, and use in educational contexts in Poland.

The most consistent long-term criticism is not that the core idea aged badly, but that the game can be bleak, repetitive, and sometimes mechanically constrained. That is useful: the lasting value is in the system-message integration, not necessarily in copying the exact interaction model.

## Comparable Games

- **Papers, Please:** The closest design ancestor for everyday bureaucracy/operation as moral narrative. Kwiatkowski explicitly cites it as inspiration.
- **Frostpunk:** 11 bit’s later society-survival game scales the moral management problem from household to city.
- **FTL: Faster Than Light:** Similar short-run crisis structure and crew/ship management, but more tactical and power-fantasy-friendly.
- **Sunless Sea:** Maritime narrative survival with text-heavy discovery and a ship as the primary continuity vessel; more authored/literary than This War of Mine.
- **Darkest Dungeon:** A stronger character-stress and expedition loop model, but with gothic combat party management rather than civilian survival.
- **Pathologic:** Comparable in hunger, illness, scarcity, moral compromise, and oppressive time pressure, but more first-person and authored.

## Design Takeaways

1. **Let mechanical aftermath carry story.** Do not make a moral decision end when the player clicks a choice. Make the ship, crew, log, rituals, relationships, and future options metabolize it.

2. **Use the vessel as the shelter.** This War of Mine’s house works because it is a fragile recovery machine. A maritime game should treat the ship the same way: shelter, economy, prison, symbol, and failure surface.

3. **Make scarcity multi-meaning.** Food is hunger prevention, morale, trade value, fairness, and future planning. In Dead Reckoning, water, coal, lamp oil, medicine, sailcloth, charts, and keepsakes should all have layered meanings.

4. **Frame the player as responsible, not omnipotent.** The strongest drama comes from constrained authority. The expedition leader should set priorities but not erase weather, disease, fear, superstition, incompetence, or grief.

5. **Build run cadence around consequence.** A clean phase loop helps players understand pressure. For maritime play, consider repeated phases like sailing orders, maintenance/care, watch events, shore party, and captain’s log.

6. **Use failure as authored material.** A lost hand, abandoned sailor, mutiny, bad burial, or desperate cannibalism event should become part of the expedition record, not just a reload prompt.

7. **Balance misery with relief and texture.** This War of Mine’s biggest transferable risk is monotony and exhaustion. A nautical roguelike can sustain harshness with moments of competence, awe, superstition, beauty, humor, and ritual.

8. **Keep interaction logic robust.** If the player thinks “why can’t I just do the obvious thing?”, the moral illusion breaks. This is especially important for shore-party encounters, rescues, discipline, and combat.

9. **Let traits create social stories.** This War of Mine’s survivors differ through carry capacity, trade skill, stealth, combat, addictions, and morale reactions. A crew game should give people asymmetric practical value and asymmetric emotional costs.

10. **Design for retelling.** The ideal run summary is not “I won with build X,” but “We reached the ice after Hale stole the quinine, the carpenter stopped speaking, and the chaplain kept the crew from throwing him overboard.”

## Focused Design Patterns For Dead Reckoning

### Moral Decisions As Gameplay

- Use ordinary operational verbs as moral verbs: ration, confiscate, abandon, punish, conceal, overwork, bless, bury, amputate, trade, rescue, and burn.
- Make context decide moral weight. Taking rope from a wreck is different from taking rope from a living settlement; using the ship’s last alcohol as medicine is different from using it to pacify a mutiny.
- Let consequences hit the simulation. A cruel but efficient order should preserve supplies while damaging trust, discipline, faith, or future willingness to volunteer.
- Avoid obvious “good choice / evil choice” UI. Let crew reactions, later failures, rumors, log entries, and epilogues interpret the action.

### Scarcity-Driven Tension

- Give every important resource at least two uses, and ideally one practical use plus one emotional/social use.
- Make scarcity change by phase: calm seas, storm damage, doldrums, ice, sickness, hostile port, failed hunt, lost boat, mutiny scare.
- Force player attention through bottlenecks: limited hands, limited watches, limited storage, limited boats, limited daylight, limited trust.
- Prevent stable routines from becoming solved by adding contextual constraints, not random punishment. Example: a storm does not just remove supplies; it makes tired riggers, torn canvas, wet powder, and injured officers all matter at once.

### Character States Impacting Outcomes

- Treat character state as a capacity economy. Hunger, fatigue, injury, cold, fear, faith, guilt, addiction, and resentment should change what work can be done and how risky it is.
- Let states compound. A hungry sailor on night watch should be more likely to miss signals; an exhausted surgeon should risk mistakes; a grieving officer should lose authority or become reckless.
- Let recovery cost scarce resources and time. Sleep consumes watch coverage, medicine consumes trade value, shore leave risks desertion, ritual costs time but restores cohesion.
- Make severe states change agency. Characters should sometimes refuse, confess, panic, volunteer, sabotage, leave, or die in ways that are legible from prior state buildup.

## Sources

- Metacritic — *This War of Mine* — https://www.metacritic.com/game/this-war-of-mine/
- OpenCritic — *This War of Mine Reviews* — https://opencritic.com/game/929/this-war-of-mine
- SteamDB — *This War of Mine Steam Charts* — https://steamdb.info/app/282070/charts/
- Steam Store — *This War of Mine* — https://store.steampowered.com/app/282070/This_War_of_Mine/
- 11 bit studios — *This War of Mine surpasses 7 million copies sold* — https://11bitstudios.com/pl/this-war-of-mine-surpasses-7-million-copies-sold/
- GameSpot — Justin Clark — *This War of Mine Review* — https://www.gamespot.com/reviews/this-war-of-mine-review/1900-6415963/
- PC Gamer — Tamoor Hussain — *This War of Mine review* — https://www.pcgamer.com/this-war-of-mine-review/
- PCGamesN — Fraser Brown — *This War of Mine review* — https://www.pcgamesn.com/this-war-of-mine/this-war-of-mine-review
- Rock Paper Shotgun via OpenCritic excerpt — Alec Meer — *This War of Mine* review listing — https://opencritic.com/outlet/270/rock-paper-shotgun?page=76
- Game Developer — Kacper Kwiatkowski — *7 things I’ve learnt from designing This War of Mine* — https://www.gamedeveloper.com/design/7-things-i-ve-learnt-from-designing-this-war-of-mine
- SAGE / Games and Culture — Stephanie de Smale, Martijn J. L. Kors, Alyea M. Sandovar — *The Case of This War of Mine: A Production Studies Perspective on Moral Game Design* — https://journals.sagepub.com/doi/10.1177/1555412017725996
- This War of Mine Wiki — *Scavenge* — https://this-war-of-mine.fandom.com/wiki/Scavenge
- This War of Mine Wiki — *Morale* — https://this-war-of-mine.fandom.com/wiki/Morale
- This War of Mine Wiki — *Hunger* — https://this-war-of-mine.fandom.com/wiki/Hunger
- This War of Mine Wiki — *Character States* — https://this-war-of-mine.fandom.com/wiki/Character_States
- This War of Mine Wiki — *Time* — https://this-war-of-mine.fandom.com/wiki/Time
- This War of Mine Wiki — *Endings* — https://this-war-of-mine.fandom.com/wiki/Endings
- This War of Mine Wiki — *Modding* — https://this-war-of-mine.fandom.com/wiki/Modding
- Ars Technica — *War Stories: This War of Mine* transcript/search result — https://arstechnica.com/video/watch/this-war-of-mine-war-stories
- Reddit — r/boardgames discussion mentioning the video game’s moral impact and scenario structure — https://www.reddit.com/r/boardgames/comments/1i1nyv1
