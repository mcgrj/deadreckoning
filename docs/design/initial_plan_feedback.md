Feedback on /home/joe/repos/deadreckoning/docs/superpowers/plans/2026-04-12-dead-reckoning-implementation-roadmap.md

---

This is a well-crafted design document. Here's my honest assessment:

  ---
  What's strong

  The Burden/Command duality is the best design decision in the doc. The four-quadrant interaction matrix (grim endurance / political instability / mutiny /
  stable-but-not-safe) creates genuinely distinct gameplay states. Most games handle this as a single morale bar. Splitting it into accumulated strain vs. legitimacy
  creates situations where solving one axis makes the other worse - that's interesting and realistic.

  The MVP loop statement is unusually sharp. "Travel creates pressure → incident forces judgment → judgment changes Burden, Command, promises, memory → travel resumes."
  That's testable. Many design docs bury the loop in prose. Having it as a single sentence you can verify against every feature decision is good discipline.

  Scope discipline is exceptional. The Early Implementation Simplifications, Deferred Functionality, Vertical Slice Content Cap, and Work Not Yet In Scope sections all
  show someone who has actually shipped something before. The one-active-promise constraint, three leadership axes, simple numeric fatigue - these are the right cuts.

  Rum as a first-class supply is a great call. It reduces Burden and creates Burden risk. It's theft bait and Command lubricant. It's historically accurate and
  mechanically distinct. This is the kind of thing that makes a sim feel textured without adding a whole subsystem.

  Authored incident templates triggered by simulation state is the right architecture for this game. It avoids random event spam and also avoids pre-scripted linearity.
  The three target incidents (mermaid, drunk purser, murder) demonstrate real range and all have credible condition triggers.

  The implementation staging is sensible. Each stage has a concrete playable/testable outcome, which is more than most roadmaps offer.

  ---
  Tensions worth watching

  Stage 1 (content framework) before Stage 2 (simulation rules) carries schema risk. You're defining IncidentDef's contract - trigger bands, cast roles, callback hooks,
  memory flags - before the simulation that consumes it exists. Stage 5 will likely require revisions to what Stage 1 established. That's not fatal, but the Stage 1
  incident schema should be treated as a stub, not a final contract. Design it to be extensible rather than complete.

  The leadership-axes-are-not-morality-meters constraint is the hardest design discipline to maintain in practice. The doc states it clearly: "Harsh, merciful, honest,
  deceptive choices must each sometimes help and sometimes backfire." But as content accumulates, authors will unconsciously drift toward making "good captain" choices
  reward Command and "bad captain" choices punish it. You need an explicit authoring rule and probably a content review pass that checks each axis has incidents where the
   expected-good choice backfires.

  Officer council authored proposals scale poorly. Each incident needs authored proposals per officer role, which is manageable at 6 incidents but painful at 30. The data
   model should probably include fallback proposals by role (what does a bosun generically say in a Crisis-category incident?) that fire when no incident-specific
  proposals exist. This avoids the choice between "shallow officer voices" and "enormous authoring burden."

  Stage 1 won't feel like progress to stakeholders. "Designers can add a new .tres content item without changing core loader code" is a good technical outcome, but it's
  invisible to anyone who wants to see a game. Worth being conscious of morale on this stage - document it as deliberate foundation work, not slow starts.

  ---
  One theoretical observation

  The game's core theory is emergent narrative through simulation state + authored template triggers. This is proven territory (Dwarf Fortress, Caves of Qud, Wildermyth)
  but the authority/legitimacy angle is genuinely fresh. The risk with this architecture is that the simulation eventually produces state combinations the incident
  templates don't cover - you get travel ticks with no incident firing, or incidents that feel disconnected from the state that triggered them. The memory flag system is
  the right mitigation: flags accumulate simulation history and let later incidents reference earlier state, creating perceived continuity. The three example flags in the
   doc (botched_hanging, rum_theft_unresolved, burial_denied) are well-chosen because they're specific enough to have narrative weight.

  ---
  Summary judgment

  The design theory is coherent and the pillars reinforce each other. The implementation plan sequences work correctly and shows real discipline about what not to build.
  The main execution risks are content authoring scale (officer proposals per incident) and schema drift between Stage 1 and Stage 5. Neither is fatal - both are
  addressable with authoring conventions and planned iteration.

  The game concept is strong. The document is unusually good at saying what it won't do.