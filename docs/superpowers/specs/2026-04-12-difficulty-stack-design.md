# Difficulty Stack Design

## Purpose

This document defines the emergent difficulty system for Dead Reckoning — how run difficulty is constructed from compounding player choices, tracked implicitly through the ship log, and synthesised by the Admiralty into a read of how hard the run actually was.

There is no explicit difficulty setting. The player never selects Easy, Normal, or Hard. Difficulty emerges from the choices made at preparation and during the run: which objective was accepted, which route was chosen, which zone types were traversed, how lean supplies were, and how badly things went. The Admiralty reads the log and draws its own conclusions.

This document also defines sea zone types as first-class route segment properties — the primary driver of route danger and a meaningful input to the tick simulation.

## Design Principle

Difficulty is not a label. It is the cumulative state the player has created through their choices.

A player who accepts an Arduous commission, crosses Open Ocean and a Lee Shore, starts with a pressed crew and lean supplies, and watches Burden spike toward breaking point has constructed a brutal run. A player who accepts a Standard commission, hugs the coast, and loads up on medicine has constructed a manageable one. The game responds differently to each without ever naming the difference.

This is consistent with the game's core design identity: every choice creates a problem, and the stack of problems you have chosen determines how hard survival is.

## The Difficulty Signals

The ship log is the source of truth. Difficulty is not tracked in a separate system — it is read from what the log already records. Four signal categories are captured.

### Objective Tier

Recorded at objective accept. Standard, Demanding, or Arduous. The highest-weight signal because it represents the player's explicit commitment to a harder commission before the run begins.

### Route Danger

Captured during travel and node resolution. The log records:

- Zone types traversed and their danger ratings
- Tick counts spent in each zone type
- Unknown node resolutions
- Adverse weather and hazard marker encounters

A run that crosses Open Ocean and a Lee Shore reads as significantly more dangerous than one that stays coastal, regardless of how well the player managed it.

### Starting Conditions

A preparation summary entry written at run start. The log records:

- Supply levels at departure (lean supplies below a threshold)
- Crew background (pressed, disease-weakened, or other high-difficulty backgrounds)
- Officer gaps (missing key roles)
- Upgrade count and quality

A player who departed with minimal medicine, a pressed crew, and no surgeon chose a harder starting position. The Admiralty notes this.

### Run Stress Indicators

Captured throughout the run via existing memory flags and log hooks:

- Peak Burden reached during the run
- Minimum Command reached during the run
- Crew losses (deaths and desertions)
- Supply depletion events (a resource hitting zero)
- Ship damage sustained (damage tags acquired)

These record what actually happened, not what the player chose. A player who made hard choices and managed them well will show different stress indicators than one who made the same choices and was overwhelmed. Both matter to the Admiralty's assessment.

## Sea Zone Types

Zone types are properties of route segments — the stretches between major nodes, not the nodes themselves. Each segment has a zone type. The zone type affects tick simulation, incident eligibility, and route danger signal contribution.

### MVP Taxonomy

Four zone types for the MVP.

**Coastal** — safe, predictable, slow. Modest consumption rates, low weather exposure, reduced Burden accumulation from travel. The default low-danger route. Fewer supply crises but slower progress means more ticks to endure before reaching nodes.

**Open Ocean** — fast, exposed, isolating. Higher food and water consumption per tick. Elevated weather exposure and Burden accumulation from isolation, physical hardship, and the psychological weight of open water. Broader incident eligibility: scurvy risk, major weather crises, crew psychological strain, and isolation-driven social incidents.

**Lee Shore** — a coast the ship is being blown toward. The most punishing zone for a damaged or ill-prepared ship. Constant ship wear per tick. Hull and rigging damage incident eligibility. Difficult forward progress — high tick cost to traverse. Elevated crew stress from sustained danger. A ship caught here in bad condition is at serious risk.

**Unknown Waters** — high variance, partially hidden. The zone type resolves at route generation to an underlying profile (one of the above, or a unique modifier combination), but the player sees only Unknown. Route visibility is reduced. Charts spoiled or absent make traversal worse. Unique omen and discovery incident eligibility. The danger rating is hidden until the zone is entered.

### Zone Type Tick Effect Profiles

Each zone type modifies base tick effects. These are data-driven — the simulation reads the active zone type's `ZoneTypeDef` and applies its modifiers.

| Effect | Coastal | Open Ocean | Lee Shore | Unknown |
|---|---|---|---|---|
| Food/water consumption | Base | Base +1 | Base | Variable |
| Weather exposure | Low | High | High | Variable |
| Ship wear per tick | Low | Medium | High | Variable |
| Burden delta | Low | Medium | High | Variable |
| Incident trigger weight | Standard | Elevated | Elevated | High variance |

Variable on Unknown means the resolved underlying profile drives the actual values, which the player cannot see until they are in the zone.

### ZoneTypeDef Content Framework

Zone types are defined as Godot custom Resources under `res://content/zone_types/*.tres`. Adding a new zone type requires one `.tres` file. No core code changes.

**ZoneTypeDef contract:**

| Field | Type | Purpose |
|---|---|---|
| `id` | String | Unique identifier |
| `display_name` | String | Shown on route map (if visible) |
| `danger_rating` | Enum | low / medium / high / extreme — used by Admiralty synthesis |
| `consumption_modifier` | float | Multiplier on food and water consumption per tick |
| `weather_exposure` | Enum | low / medium / high — drives weather incident eligibility |
| `ship_wear_per_tick` | int | Flat modifier on ship condition per tick |
| `burden_delta_modifier` | float | Adjusts Burden accumulation per tick |
| `incident_weight_modifier` | float | Scales incident trigger frequency |
| `eligible_incident_tags` | Array[String] | Incident categories that can fire in this zone |
| `suppressed_incident_tags` | Array[String] | Incident categories that cannot fire in this zone |
| `visibility_modifier` | Enum | full / partial / hidden — how much route information is visible |
| `log_hooks` | Array[LogHookDef] | Log entries written on zone entry and exit |

## Admiralty Synthesis

The Admiralty does not calculate a difficulty score. It reads the log and draws conclusions. The implicit difficulty read is an internal value — never surfaced to the player — used for three purposes.

### Signal Weighting

| Signal | Weight | Rationale |
|---|---|---|
| Objective tier | High | Explicit pre-run commitment to a harder commission |
| Route danger | High | Zone types and danger ratings accumulated during travel |
| Starting conditions | Medium | Preparation choices that created disadvantage |
| Run stress | Medium | What actually happened — how close to breaking the run came |

### What The Synthesis Affects

**Report framing options.** What the player can credibly claim in the Admiralty report scales with what the log shows. Surviving a Lee Shore crossing with a pressed crew on an Arduous commission makes different claims credible than a clean coastal Standard run. The `admiralty_report_hooks` on `ObjectiveDef` and `ZoneTypeDef` entries define what framing options become available.

**Unlock reward significance.** At MVP, unlock significance is set by objective tier — the tier already reflects expected difficulty. Post-MVP, if run stress signals show the player exceeded the expected difficulty for their tier, this could surface a more significant variant unlock. Deferred.

**Future shortlist weighting.** The Admiralty notes accumulated run difficulty across sessions. Consistently hard runs weight the shortlist toward Demanding and Arduous objectives. Consistent Standard runs keep the shortlist weighted toward accessible options. Experienced players naturally see harder commissions without the game ever labelling them as such. This is the soft difficulty progression signal — it emerges from play history, not a setting.

### MVP Synthesis Scope

For the MVP, Admiralty synthesis is deliberately simple:

- Objective tier + route danger signals only
- Full multi-signal synthesis (starting conditions + run stress) is a Stage 6B addition
- Shortlist weighting by accumulated difficulty is a Stage 6B addition

The synthesis does not need to be complex to be meaningful. Objective tier and zone danger ratings already capture most of the player's intentional difficulty choices.

## Integration With Existing Systems

### Run Objectives

Zone types and difficulty synthesis are the mechanical substrate beneath run objectives. An Arduous objective implies a harder route — the shortlist and route generator should weight toward segments containing Open Ocean or Lee Shore for Demanding and Arduous commissions. The objective tier is the primary difficulty signal; the zone types traversed confirm or exceed that baseline.

### Route Map

Route segments carry a `zone_type` field. The route generator places zone types on segments according to route category (coastal routes weight toward Coastal zone type; open ocean routes weight toward Open Ocean; unknown waters use Unknown). A hand-authored route map in Stage 3 defines zone types explicitly.

Partial route visibility already exists in the design. Zone type visibility follows the same rule: Coastal and Open Ocean are visible on the route map. Lee Shore may be partially hidden behind a hazard marker. Unknown Waters hides the underlying zone type until entered.

### Incident System

The incident system reads `eligible_incident_tags` and `suppressed_incident_tags` from the active `ZoneTypeDef` when evaluating incident eligibility. A scurvy incident requires Open Ocean zone context. A grounding incident requires Lee Shore. A mermaid sighting requires an Omen node or night/fog tick — but its probability is elevated in Unknown Waters.

### Ship Log

Log entries that carry difficulty-relevant signals are tagged with a `difficulty_signal` category:

- `objective_tier` — written at objective accept
- `route_danger` — written on zone entry, zone exit, and hazard encounters
- `starting_condition` — written as a preparation summary at run start
- `stress_indicator` — written when stress thresholds are crossed (peak Burden, minimum Command, crew loss, supply depletion)

The `difficulty_signal` tag allows the Admiralty synthesis pass to identify relevant entries without reading the full log.

## Implementation Staging

This system lands across existing stages. It does not require a dedicated new stage.

| Stage | Work |
|---|---|
| Stage 1 | `ZoneTypeDef` Resource class added to content framework alongside other content families. Log entry `difficulty_signal` tag field added. |
| Stage 2 | Expedition state tracks stress indicators: peak Burden, minimum Command, crew losses, supply depletion events. |
| Stage 3 | Route segments carry `zone_type` field. `ZoneTypeDef` tick modifiers applied during travel ticks. Log entries written on zone entry and exit with `route_danger` signal tag. Hand-authored test route uses all four zone types. |
| Stage 5 | Incident eligibility evaluation reads `eligible_incident_tags` and `suppressed_incident_tags` from active zone type. |
| Stage 6A | Basic Admiralty synthesis: objective tier + route danger signals. Report framing options shaped by difficulty read. |
| Stage 6B | Full multi-signal synthesis including starting conditions and run stress. Shortlist weighting by accumulated run difficulty. Variant unlock significance for runs that exceeded tier expectations (deferred). |

## MVP Content Cap

Consistent with the vertical slice content cap:

- 4 `ZoneTypeDef` files: Coastal, Open Ocean, Lee Shore, Unknown
- Difficulty synthesis at Stage 6A uses objective tier and route danger only
- Full synthesis deferred to Stage 6B

## What To Avoid

Do not surface the implicit difficulty read to the player. No difficulty score, no run rating, no label. Players infer difficulty from the Admiralty's tone and report options — not from a number.

Do not make zone types the only route danger signal. A heavily ticked Coastal route is still grinding. A short Lee Shore crossing with full supplies and a veteran crew is survivable. The synthesis reads the full picture.

Do not gate content behind difficulty tiers explicitly. The shortlist weighting shifts naturally — it is not a lock. A new player can still see a Demanding objective if the weighting surfaces one. The progression is soft, not a wall.
