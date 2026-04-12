# Dead Reckoning Art Direction Design

## Purpose

This document defines the visual identity, asset pipeline, font choices, platform targets, and long-term art plan for Dead Reckoning. It is intended to be read alongside the refined game design spec and the implementation roadmap.

## Visual Style

Dead Reckoning uses **dark pixel art at Stardew Valley density**. The aesthetic is not decorative — art carries narrative weight. Every background communicates the state of the expedition before the UI says a word.

**Palette:** Deep ocean blues, storm grays, amber and lantern-gold accents. The palette is kept deliberately limited. Every colour choice is load-bearing. Amber and lantern-gold function simultaneously as warmth and danger. Red is blood, fever, and fire — never a casual UI accent.

**Pixel density:** Stardew Valley level. Chunky, readable, deliberately low-resolution. Atmosphere comes from palette and subject matter, not fine detail.

**Mood:** Oppressive and foreboding. The sea is always larger than the ship. Authority is fragile. The game should feel like things are already going wrong.

**Reference touchstones:**
- Darkest Dungeon — narrative through art, expressionistic characters, environmental storytelling
- Stardew Valley — pixel density and readability
- Dredge — palette mood and maritime atmosphere

## Narrative Through Art

Art in Dead Reckoning is not wallpaper. Every piece has emotional intent.

**Scene backgrounds** communicate before the text does. A calm anchorage at dawn feels fragile, not safe. A storm background is existential threat, not weather. Backgrounds use dramatic asymmetric lighting — lantern glow, moonlight through cloud, lightning at the horizon. Heavy vignetting and darkened edges pull focus inward.

Each event category has a distinct emotional register:
- **Crisis** — chaotic and disorienting
- **Omen** — still and wrong
- **Landfall** — ambiguous, relief and threat in the same frame
- **Social** — enclosed, pressured, human
- **Boon** — temporary and untrustworthy
- **Admiralty** — cold, institutional, distant
- **Unknown** — featureless and threatening

**Officer portraits** show psychological state through posture and expression, even at low pixel resolution. The purser's reddened nose. The bosun's flat stare. The chaplain's hollow eyes. A loyal first mate stands square. An ambitious lieutenant leans in. Officers look like people who have been at sea too long.

**The Admiralty screen** contrasts the expedition's conditions against institutional comfort. Opulent and suffocating.

**The route map** makes distance look hard. Nodes feel like destinations of dread. The sea between nodes is dark and featureless.

## Technical Specification

| Parameter | Value |
|---|---|
| Base tile size | 16×16 px |
| Scene background native resolution | 320×180 px |
| Officer portrait size | 48×64 px |
| Godot pixel rendering | Nearest-neighbour filtering, integer scaling, no anti-aliasing |
| Orientation | Landscape only (forced) |
| Colour palette size | 16–32 colours, locked before asset production begins |

## Asset Pipeline

All art is generated through a **single Scenario.com custom-trained generator**, trained once on a curated reference set before any coding begins. The trained generator is the consistency anchor — everything produced from it shares the same visual language.

### Stage 0 Workflow

1. Curate ~15–20 reference images that define the target look: dark, maritime, pixel art, correct palette mood. Sources must be properly licensed for use as AI training data (see Licensing section).
2. Train the Scenario generator on those references.
3. Lock the palette (16–32 colours), pixel density, and resolution standard.
4. Run test generations for each asset surface type to validate output.
5. Document prompt templates that produce correct results. This becomes the **art production guide**, saved to `docs/art-production-guide.md` — the definitive reference for generating new assets consistently.
6. Generate the full MVP asset set (see below).

### MVP Asset Set

| Asset | Type | Quantity | Notes |
|---|---|---|---|
| Event backgrounds | Scene illustration | 7 | One per event category |
| Officer portraits | Character bust (48×64) | 4 | One per MVP officer role |
| Ship view | Scene illustration | 1 | Persistent travel/tick screen background |
| Route map background texture | Texture | 1 | Underlies the Godot-drawn node graph |
| Admiralty interior | Scene illustration | 1 | Between-run screen |

### Godot Asset Organisation

```
res://assets/backgrounds/    — scene illustrations
res://assets/portraits/      — officer and notable portraits
res://assets/textures/       — UI textures, map backgrounds
res://assets/fonts/          — embedded font files
```

## Font Direction

Two fonts are used across all screens. Both are free for commercial use under the SIL Open Font Licence (OFL 1.1).

| Role | Font | Source |
|---|---|---|
| Headers, UI labels, choices, meters | **Cinzel** | Google Fonts |
| Narrative text, incident descriptions, ship log, officer speech | **Crimson Pro** | Google Fonts |

**Usage rules:**
- Cinzel carries institutional weight — used wherever the game speaks in an authoritative, structural voice.
- Crimson Pro carries narrative weight — used wherever the game tells a story or reports a consequence.
- Minimum font sizes are defined in Stage 0 to ensure legibility at landscape mobile scale.
- Both fonts are embedded in the Godot project at build time. No runtime dependency on Google Fonts.

## Platform and Orientation

| Platform | Orientation |
|---|---|
| PC / Mac / Linux | Landscape |
| iOS | Landscape (forced — players rotate device) |
| Android | Landscape (forced — players rotate device) |

Landscape is the natural mode for a text-heavy strategy game of this type. A single layout is designed and maintained across all platforms. Players who pick up this game on mobile will rotate without complaint.

Godot project settings lock screen orientation to landscape. No portrait layout is designed or maintained for MVP or release.

**Touch targets:** All interactive elements (choices, map nodes, officer portraits, UI buttons) must meet a minimum 44×44 dp touch target from the start. This is not retrofitted — it is built into the UI from Stage 1.

## Roadmap Integration

Art direction is a new **Stage 0** that runs before any coding stages begin.

### Stage 0: Art Direction and Asset Pipeline

**Goal:** Establish the visual identity and produce the MVP asset set before any game screens are built.

**Deliverables:**

1. Scenario.com account set up, custom generator trained on curated reference set.
2. Palette locked (16–32 colours), saved as a Godot colour constant file and as a Scenario palette constraint.
3. Resolution standard and pixel density documented.
4. Prompt templates documented in `docs/art-production-guide.md`.
5. Full MVP asset set generated and reviewed: 7 backgrounds, 4 portraits, ship view, map texture, Admiralty interior.
6. Godot project configured for pixel art rendering: nearest-neighbour filtering, integer scaling, landscape orientation lock, correct viewport size.
7. Asset folders created under `res://assets/` with naming conventions documented.
8. Minimum font sizes defined and documented for landscape mobile legibility.
9. Licensing checklist completed (see below).

**Relationship to coding stages:**
- Stage 1 (Content Framework) receives the Godot pixel art rendering setup and asset folder structure from Stage 0.
- Stage 3 (Route Map and Travel Ticks) integrates the map background texture and ship view.
- Stage 4 (Standing Orders and Officer Council) integrates officer portraits.
- Stage 5 (Incident System) integrates event backgrounds.
- Stage 6A (Admiralty Preparation) integrates the Admiralty interior.

Art is not retrofitted at the end. Each coding stage integrates its relevant assets as the screen is built.

## Long-Term Artist Plan

When Dead Reckoning shows enough legs to bring in a hired pixel artist, the handoff is already prepared:

- The trained Scenario generator is handed to the artist as the style reference — they run it to understand the visual language.
- The locked palette, tile size, and resolution standard are non-negotiable constraints they work within.
- The prompt templates and existing generated assets are direct examples to match or improve.
- The artist does not invent the style from scratch — they extend an established language.

**Priority order for artist replacement of AI-generated assets:**

1. Officer portraits — most player-facing, most repeated per run, most character-defining.
2. Event backgrounds — seen every run, highest narrative impact.
3. Route map nodes and icons — small but seen constantly.
4. Ship view and Admiralty interior — atmospheric, less frequently the focus.

**Contract requirement:** Any commissioned pixel art must use a work-for-hire agreement with explicit full IP assignment to the developer. This must be specified in writing before work begins.

## Licensing Checklist

This checklist must be completed before the game is submitted to any storefront (Steam, App Store, Google Play).

### Pre-Production (Complete in Stage 0)

- [ ] **Scenario.com plan confirmed:** Verify the active subscription tier explicitly grants commercial rights to generated output assets.
- [ ] **Scenario.com indemnification confirmed:** Verify Scenario's terms of service include indemnification against upstream training data claims on their base models.
- [ ] **Custom generator training data audited:** Every reference image used to train the custom generator is either created by the developer, explicitly CC0-licensed, or explicitly licensed for use as AI training data. Document the source of each reference image.
- [ ] **Cinzel licence confirmed:** SIL OFL 1.1 — embedded in commercial product ✓. No further action required, but retain a copy of the licence file in `res://assets/fonts/`.
- [ ] **Crimson Pro licence confirmed:** SIL OFL 1.1 — embedded in commercial product ✓. Retain licence file in `res://assets/fonts/`.
- [ ] **Godot Engine licence confirmed:** MIT — commercial use ✓. No further action required.

### Pre-Ship (Complete Before Storefront Submission)

- [ ] **All shipped assets audited:** Every asset in the final build is either generated through the licensed Scenario generator, created by the developer, or covered by a confirmed commercial licence.
- [ ] **Commissioned artist contracts filed:** If any pixel art was commissioned, work-for-hire agreements with full IP assignment are signed and retained.
- [ ] **Scenario.com subscription active at ship time:** Confirm the commercial licence remains valid under the active plan at the time of submission.
- [ ] **Font licence files included in build:** OFL requires the licence text to be distributed alongside the fonts if distributed separately. Embedding in a compiled game binary is generally considered compliant, but include licence files in the project repository as documentation.
- [ ] **Legal review (optional but recommended):** If the game reaches commercial scale, have a games lawyer review the AI art licensing position. The legal landscape around AI-generated assets is still evolving.
