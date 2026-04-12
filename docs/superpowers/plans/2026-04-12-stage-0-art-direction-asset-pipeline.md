# Stage 0: Art Direction and Asset Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Important:** Tasks 1–3 and Task 6b are automatable Godot/GDScript work. Tasks 4, 5, 6a, 7, and 8 are **manual human tasks** requiring Scenario.com — an agentic worker cannot complete these. The recommended split: run Tasks 1–3 via subagent, hand off to the developer for Tasks 4–8, then return for Task 6b and Task 9.

**Goal:** Establish the visual identity, configure Godot for pixel art rendering, produce the MVP asset set via Scenario.com, embed fonts and colour constants, and gate entry to Stage 1 behind a completed licensing checklist.

**Architecture:** Godot project configuration (pixel art rendering, landscape lock, asset folders) is code. Art production (Scenario.com generator training, asset generation) is manual. The palette and font constants are GDScript files so every subsequent stage can reference them as typed values.

**Tech Stack:** Godot 4.6, GDScript, Scenario.com, Google Fonts (Cinzel, Crimson Pro OFL)

**Spec:** `docs/superpowers/specs/2026-04-12-art-direction-design.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `game/project.godot` | Modify | Pixel art rendering, integer scaling, landscape lock |
| `game/test/PixelArtVerification.tscn` | Create → Delete after Stage 0 | Visual verification scene |
| `game/test/PixelArtVerification.gd` | Create → Delete after Stage 0 | Verification scene script |
| `game/assets/backgrounds/.gitkeep` | Create | Placeholder for scene illustration folder |
| `game/assets/portraits/.gitkeep` | Create | Placeholder for portrait folder |
| `game/assets/textures/.gitkeep` | Create | Placeholder for UI textures folder |
| `game/assets/fonts/Cinzel-Regular.ttf` | Create | Cinzel font binary |
| `game/assets/fonts/CrimsonPro-Regular.ttf` | Create | Crimson Pro regular binary |
| `game/assets/fonts/CrimsonPro-Italic.ttf` | Create | Crimson Pro italic binary |
| `game/assets/fonts/OFL-Cinzel.txt` | Create | Cinzel licence file |
| `game/assets/fonts/OFL-CrimsonPro.txt` | Create | Crimson Pro licence file |
| `game/src/constants/FontSizes.gd` | Create | Minimum font size constants |
| `game/src/constants/Palette.gd` | Create | Locked colour palette constants |
| `docs/art-production-guide.md` | Create | Prompt templates, naming conventions, asset checklist |

---

## Task 1: Configure Godot Project for Pixel Art Rendering

**Files:**
- Modify: `game/project.godot`
- Create: `game/test/PixelArtVerification.tscn`
- Create: `game/test/PixelArtVerification.gd`

The base viewport is 1280×720. Scene backgrounds are generated at 320×180 and imported with nearest-neighbour filtering, then scaled up 4× at runtime. UI is rendered at full 1280×720 resolution so text stays sharp. Integer scaling ensures pixels land on exact boundaries at all window sizes.

- [ ] **Step 1: Open `game/project.godot` and apply rendering settings**

  Open the file directly and add or update these sections. The full updated relevant sections should look like:

  ```ini
  [display]

  window/size/viewport_width=1280
  window/size/viewport_height=720
  window/stretch/mode="canvas_items"
  window/stretch/aspect="keep"
  window/stretch/scale_mode="integer"
  window/handheld/orientation=0

  [rendering]

  textures/canvas_textures/default_texture_filter=0
  ```

  `window/handheld/orientation=0` is SCREEN_LANDSCAPE. `default_texture_filter=0` is Nearest (no interpolation). `scale_mode="integer"` locks scaling to whole-number multiples so pixels stay crisp.

- [ ] **Step 2: Create the test folder**

  ```bash
  mkdir -p /home/joe/repos/deadreckoning/game/test
  ```

- [ ] **Step 3: Create the verification scene script**

  Create `game/test/PixelArtVerification.gd`:

  ```gdscript
  extends Node2D

  # Verification scene for Stage 0 pixel art configuration.
  # Checks: nearest-neighbour filtering, 1280x720 viewport, landscape lock.
  # Delete this file and PixelArtVerification.tscn after Stage 0 is complete.

  func _ready() -> void:
      var viewport_size := get_viewport().get_visible_rect().size
      assert(viewport_size == Vector2(1280, 720), \
          "Viewport must be 1280x720, got %s" % viewport_size)

      var orientation := DisplayServer.screen_get_orientation()
      assert(orientation == DisplayServer.SCREEN_LANDSCAPE or \
             orientation == DisplayServer.SCREEN_SENSOR_LANDSCAPE, \
          "Screen must be landscape, got %d" % orientation)

      print("Stage 0 verification: PASS — viewport %s, orientation %d" \
          % [viewport_size, orientation])
  ```

- [ ] **Step 4: Create the verification scene file**

  Create `game/test/PixelArtVerification.tscn`:

  ```ini
  [gd_scene load_steps=2 format=3 uid="uid://pixel_art_verify"]

  [ext_resource type="Script" path="res://test/PixelArtVerification.gd" id="1"]

  [node name="PixelArtVerification" type="Node2D"]
  script = ExtResource("1")

  [node name="Background" type="ColorRect" parent="."]
  anchors_preset = 15
  anchor_right = 1.0
  anchor_bottom = 1.0
  color = Color(0.027, 0.063, 0.106, 1)

  [node name="Label" type="Label" parent="."]
  offset_left = 40.0
  offset_top = 40.0
  offset_right = 640.0
  offset_bottom = 80.0
  text = "Stage 0 Verification: 1280x720 Landscape Nearest-Neighbour"
  ```

- [ ] **Step 5: Set the verification scene as the main scene temporarily**

  In `game/project.godot`, add:

  ```ini
  [application]

  run/main_scene="res://test/PixelArtVerification.tscn"
  ```

- [ ] **Step 6: Run the project and verify**

  Open Godot 4.6, load the project from `game/`, and press F5 to run.

  Expected: window opens at 1280×720, console prints `Stage 0 verification: PASS — viewport (1280, 720), orientation 0`. No assertion errors.

  If the window opens at a different size or orientation, re-check the `project.godot` values from Step 1.

- [ ] **Step 7: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add game/project.godot game/test/
  git commit -m "feat(stage-0): configure Godot for pixel art rendering and landscape lock"
  ```

---

## Task 2: Create Asset Folder Structure

**Files:**
- Create: `game/assets/backgrounds/.gitkeep`
- Create: `game/assets/portraits/.gitkeep`
- Create: `game/assets/textures/.gitkeep`
- Create: `game/src/constants/.gitkeep`

- [ ] **Step 1: Create the folder structure**

  ```bash
  mkdir -p /home/joe/repos/deadreckoning/game/assets/backgrounds
  mkdir -p /home/joe/repos/deadreckoning/game/assets/portraits
  mkdir -p /home/joe/repos/deadreckoning/game/assets/textures
  mkdir -p /home/joe/repos/deadreckoning/game/assets/fonts
  mkdir -p /home/joe/repos/deadreckoning/game/src/constants
  touch /home/joe/repos/deadreckoning/game/assets/backgrounds/.gitkeep
  touch /home/joe/repos/deadreckoning/game/assets/portraits/.gitkeep
  touch /home/joe/repos/deadreckoning/game/assets/textures/.gitkeep
  touch /home/joe/repos/deadreckoning/game/assets/fonts/.gitkeep
  touch /home/joe/repos/deadreckoning/game/src/constants/.gitkeep
  ```

- [ ] **Step 2: Create the shell art production guide**

  Create `docs/art-production-guide.md`. This shell gets filled in during Task 7.

  ```markdown
  # Dead Reckoning Art Production Guide

  > This document is the canonical reference for generating new assets using the Scenario.com custom generator. All assets in the game must be generated using the prompt templates here and the locked palette.

  **Spec:** `docs/superpowers/specs/2026-04-12-art-direction-design.md`

  ## Generator

  - Scenario.com generator URL: _[fill in after Task 5]_
  - Generator name: _[fill in after Task 5]_

  ## Locked Palette

  _[Fill in after Task 6a — list all hex values]_

  ## Resolution Standards

  | Asset type | Native resolution | Import filter |
  |---|---|---|
  | Scene background | 320×180 px | Nearest |
  | Officer portrait | 48×64 px | Nearest |
  | Route map texture | 320×180 px | Nearest |

  ## Naming Conventions

  | Asset type | Folder | Naming pattern | Example |
  |---|---|---|---|
  | Event background | `assets/backgrounds/` | `bg_<category>.png` | `bg_crisis.png` |
  | Officer portrait | `assets/portraits/` | `portrait_<role>.png` | `portrait_bosun.png` |
  | Route map background | `assets/textures/` | `tex_<name>.png` | `tex_route_map.png` |
  | Ship view | `assets/backgrounds/` | `bg_ship_view.png` | |
  | Admiralty interior | `assets/backgrounds/` | `bg_admiralty.png` | |

  ## Prompt Templates

  _[Fill in after Task 7]_

  ### Base Style Prompt

  _[Fill in]_

  ### Scene Background — Crisis

  _[Fill in]_

  ### Scene Background — Landfall

  _[Fill in]_

  ### Scene Background — Social

  _[Fill in]_

  ### Scene Background — Omen

  _[Fill in]_

  ### Scene Background — Boon

  _[Fill in]_

  ### Scene Background — Admiralty

  _[Fill in]_

  ### Scene Background — Unknown

  _[Fill in]_

  ### Scene Background — Ship View

  _[Fill in]_

  ### Scene Background — Admiralty Interior

  _[Fill in]_

  ### Officer Portrait — First Mate

  _[Fill in]_

  ### Officer Portrait — Bosun

  _[Fill in]_

  ### Officer Portrait — Purser

  _[Fill in]_

  ### Officer Portrait — Surgeon

  _[Fill in]_

  ### Route Map Background Texture

  _[Fill in]_

  ## Asset Checklist

  ### MVP Assets Required Before Stage 3

  - [ ] `assets/backgrounds/bg_ship_view.png`
  - [ ] `assets/textures/tex_route_map.png`

  ### MVP Assets Required Before Stage 4

  - [ ] `assets/portraits/portrait_first_mate.png`
  - [ ] `assets/portraits/portrait_bosun.png`
  - [ ] `assets/portraits/portrait_purser.png`
  - [ ] `assets/portraits/portrait_surgeon.png`

  ### MVP Assets Required Before Stage 5

  - [ ] `assets/backgrounds/bg_crisis.png`
  - [ ] `assets/backgrounds/bg_landfall.png`
  - [ ] `assets/backgrounds/bg_social.png`
  - [ ] `assets/backgrounds/bg_omen.png`
  - [ ] `assets/backgrounds/bg_boon.png`
  - [ ] `assets/backgrounds/bg_unknown.png`

  ### MVP Assets Required Before Stage 6A

  - [ ] `assets/backgrounds/bg_admiralty.png`
  ```

- [ ] **Step 3: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add game/assets/ game/src/ docs/art-production-guide.md
  git commit -m "feat(stage-0): create asset folder structure and art production guide shell"
  ```

---

## Task 3: Download and Embed Fonts

**Files:**
- Create: `game/assets/fonts/Cinzel-Regular.ttf`
- Create: `game/assets/fonts/CrimsonPro-Regular.ttf`
- Create: `game/assets/fonts/CrimsonPro-Italic.ttf`
- Create: `game/assets/fonts/OFL-Cinzel.txt`
- Create: `game/assets/fonts/OFL-CrimsonPro.txt`
- Create: `game/src/constants/FontSizes.gd`

- [ ] **Step 1: Download fonts from Google Fonts**

  Download the following zip files directly from Google Fonts:
  - Cinzel: https://fonts.google.com/specimen/Cinzel — download the family, extract `Cinzel-Regular.ttf`
  - Crimson Pro: https://fonts.google.com/specimen/Crimson+Pro — download the family, extract `CrimsonPro-Regular.ttf` and `CrimsonPro-Italic.ttf`

  Place the `.ttf` files in `game/assets/fonts/`.

- [ ] **Step 2: Save the OFL licence files**

  The SIL Open Font Licence text is the same for both fonts. Save a copy for each.

  Create `game/assets/fonts/OFL-Cinzel.txt` and `game/assets/fonts/OFL-CrimsonPro.txt` with the OFL 1.1 licence text from https://scripts.sil.org/OFL

  Both should contain the standard OFL 1.1 preamble and the font-specific copyright notice from the downloaded package (check the `OFL.txt` file in each downloaded zip).

- [ ] **Step 3: Remove the fonts `.gitkeep`**

  ```bash
  rm /home/joe/repos/deadreckoning/game/assets/fonts/.gitkeep
  ```

- [ ] **Step 4: Create font size constants**

  Create `game/src/constants/FontSizes.gd`:

  ```gdscript
  # FontSizes.gd
  # Minimum font sizes for legibility at 1280x720 landscape across all platforms,
  # including mobile. All sizes are in pixels. Use Cinzel for UI/headers and
  # Crimson Pro for narrative/incident text.
  #
  # Spec: docs/superpowers/specs/2026-04-12-art-direction-design.md
  class_name FontSizes

  ## Cinzel — screen and section titles
  const HEADER_TITLE := 32

  ## Cinzel — choice buttons and primary interactive labels
  const UI_CHOICE := 20

  ## Cinzel — meter labels, secondary UI labels, small uppercase text
  const UI_LABEL := 16

  ## Crimson Pro — main incident and event narrative text
  const NARRATIVE_BODY := 22

  ## Crimson Pro — ship log entries and consequence text
  const NARRATIVE_LOG := 18

  ## Crimson Pro — officer speech and proposal text
  const NARRATIVE_OFFICER := 20
  ```

- [ ] **Step 5: Update the verification scene to test font loading**

  Update `game/test/PixelArtVerification.tscn` to include a Label node using Cinzel and another using Crimson Pro at the minimum body size. Add to the scene (below the existing Label node):

  ```ini
  [node name="CinzelLabel" type="Label" parent="."]
  offset_left = 40.0
  offset_top = 100.0
  offset_right = 800.0
  offset_bottom = 140.0
  text = "Cinzel UI_CHOICE (20px): Make an example of the thief"

  [node name="CrimsonLabel" type="Label" parent="."]
  offset_left = 40.0
  offset_top = 160.0
  offset_right = 1000.0
  offset_bottom = 340.0
  text = "Crimson Pro NARRATIVE_BODY (22px): Someone has been at the spirit locker. The bosun found an empty cask hidden beneath the biscuit stores. The lower deck goes quiet."
  autowrap_mode = 3
  ```

  Then in the Godot editor, set the font on CinzelLabel to `assets/fonts/Cinzel-Regular.ttf` at size 20, and CrimsonLabel to `assets/fonts/CrimsonPro-Regular.ttf` at size 22.

- [ ] **Step 6: Run the verification scene and confirm both fonts render**

  Press F5. Both labels should render clearly at the stated sizes with no fallback/default font. On a simulated small screen (resize the window down toward 854×480, the minimum landscape mobile), text must still be readable.

- [ ] **Step 7: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add game/assets/fonts/ game/src/constants/FontSizes.gd game/test/
  git commit -m "feat(stage-0): embed Cinzel and Crimson Pro fonts with OFL licences and font size constants"
  ```

---

## Task 4: Set Up Scenario.com and Curate Reference Images

> **MANUAL HUMAN TASK — Cannot be automated. Developer action required.**

- [ ] **Step 1: Create a Scenario.com account**

  Go to https://www.scenario.com and create an account. Select a paid plan that explicitly includes commercial use rights for generated assets. Confirm this in their pricing/terms page before proceeding.

- [ ] **Step 2: Verify commercial licensing terms**

  Before training anything, read Scenario's terms of service and confirm:
  - Generated assets are owned by you and may be used commercially.
  - Scenario indemnifies you against upstream training data claims on their base models.

  If either is unclear, contact Scenario support before proceeding. Do not generate commercial assets until confirmed.

  Mark this item in `docs/superpowers/specs/2026-04-12-art-direction-design.md` licensing checklist:
  - [x] Scenario.com plan confirmed
  - [x] Scenario.com indemnification confirmed

- [ ] **Step 3: Curate ~15–20 reference images**

  Collect reference images that define the target visual style: dark maritime pixel art, Stardew Valley pixel density, deep ocean blues, amber/lantern-gold lighting. These are training-only inputs — they are never shipped in the game.

  Sources that are safe to use as AI training references:
  - Pixel art you create yourself in a pixel art editor (LibreSprite is free)
  - Explicitly CC0-licensed pixel art (search itch.io with "CC0 maritime pixel art")
  - Art you explicitly licence for training use

  Do not use random Google Images, itch.io packs without checking licence, or social media pixel art — training data licensing is a legal grey area and you need clean provenance.

- [ ] **Step 4: Document the source of each reference image**

  Create `docs/training-reference-log.md`:

  ```markdown
  # Scenario Generator Training Reference Log

  Each reference image used to train the Dead Reckoning Scenario generator is listed here
  with its source and licence confirmation.

  | Filename | Source | Licence | Confirmed by |
  |---|---|---|---|
  | ref_001.png | [source URL or "self-created"] | CC0 / self-created | [your name] |
  ```

  This document is the audit trail for the licensing checklist.

- [ ] **Step 5: Mark the training data audit item in the licensing checklist**

  In `docs/superpowers/specs/2026-04-12-art-direction-design.md`:
  - [x] Custom generator training data audited

- [ ] **Step 6: Commit the reference log**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add docs/training-reference-log.md
  git commit -m "docs(stage-0): add training reference image log for Scenario generator"
  ```

---

## Task 5: Train the Scenario Generator

> **MANUAL HUMAN TASK — Cannot be automated. Developer action required.**

- [ ] **Step 1: Create a new generator in Scenario.com**

  In the Scenario dashboard, create a new generator. Name it something clear: `dead-reckoning-maritime-pixel-art`.

- [ ] **Step 2: Upload the curated reference images**

  Upload all ~15–20 reference images from Task 4. Tag them consistently in Scenario's interface if tags are available.

- [ ] **Step 3: Configure training settings**

  Use Scenario's pixel art training mode if available. Set training strength to a moderate level — too high and the generator overfits to the references and loses flexibility; too low and it ignores them. Follow Scenario's documentation for recommended settings for pixel art game assets.

- [ ] **Step 4: Run the training and wait for completion**

  Training typically takes 10–30 minutes. Monitor Scenario's dashboard for completion.

- [ ] **Step 5: Run a validation generation**

  Generate one test image per asset type using a simple prompt:
  - `dark maritime pixel art, night sea, lantern glow, Stardew Valley pixel density, deep blue palette`

  Verify the output:
  - Consistent pixel density (Stardew level — chunky, not hyper-detailed)
  - Dark colour palette (blues, storm grays, amber accents)
  - No photorealism or painterly anti-aliasing bleeding in
  - Mood is foreboding, not cheerful

  If the output does not match, adjust the training configuration or add/replace reference images and retrain.

- [ ] **Step 6: Record the generator URL**

  Save the Scenario generator URL to `docs/art-production-guide.md` in the Generator section.

---

## Task 6a: Lock the Colour Palette

> **MANUAL HUMAN TASK — Cannot be automated. Developer action required.**
> Complete after Task 5 (generator validated).

- [ ] **Step 1: Generate a palette-representative image**

  Generate one scene background (e.g. dark night sea with lantern light) from the trained generator. This image becomes the palette source.

- [ ] **Step 2: Extract the palette**

  Open the generated image in any pixel art or image editor (LibreSprite, GIMP, Aseprite). Extract the distinct colours used. The target is 16–32 colours total.

  Group them into:
  - **Darks:** near-black blues for backgrounds and vignettes
  - **Mids:** ocean blues, storm grays
  - **Accents:** amber, lantern-gold
  - **Alert:** desaturated red (for danger, illness, fire — sparingly)
  - **Text/UI:** near-white or pale blue for UI text on dark backgrounds

- [ ] **Step 3: Record the palette as hex values**

  Fill in the Locked Palette section of `docs/art-production-guide.md` with all hex values and their semantic names.

- [ ] **Step 4: Set the palette as a constraint in Scenario.com**

  If Scenario supports palette constraints (check their documentation), apply the locked palette to the generator. This prevents generation from drifting to different colours over time.

---

## Task 6b: Create Palette Constants in GDScript

**Files:**
- Create: `game/src/constants/Palette.gd`

Complete after Task 6a.

- [ ] **Step 1: Create `game/src/constants/Palette.gd`**

  Use the hex values from the art production guide. The example below uses placeholder values — replace every hex with the actual locked palette values from Task 6a.

  ```gdscript
  # Palette.gd
  # Locked colour palette for Dead Reckoning. Every colour used in the game UI
  # must come from this file. Do not use ad-hoc Color() calls elsewhere.
  #
  # Palette source: docs/art-production-guide.md
  # Spec: docs/superpowers/specs/2026-04-12-art-direction-design.md
  class_name Palette

  # --- Darks ---
  ## Near-black blue. Default background for all UI panels and dark scene areas.
  const VOID := Color("0d1b2a")

  ## Deep navy. Secondary background, card backs, panel borders.
  const DEEP_NAVY := Color("06101c")

  # --- Mids ---
  ## Primary ocean blue. Water, mid-range UI elements.
  const OCEAN := Color("1a3a5c")

  ## Storm gray-blue. Overcast sky, neutral UI surfaces.
  const STORM := Color("2e3a4a")

  # --- Accents ---
  ## Lantern gold. Primary accent. Warmth, danger, candlelight.
  const LANTERN := Color("c8a040")

  ## Pale amber. Secondary accent. Aged wood, firelight at distance.
  const AMBER := Color("a07020")

  # --- Alert ---
  ## Desaturated red. Use only for Burden spikes, fire, blood, illness.
  ## Never use as a decorative colour.
  const DANGER := Color("8a3020")

  # --- UI Text ---
  ## Primary text on dark backgrounds. Pale blue-white.
  const TEXT_PRIMARY := Color("c8e0f0")

  ## Secondary text, labels, descriptions. Mid blue-gray.
  const TEXT_SECONDARY := Color("80b0d0")

  ## Dimmed text. Inactive choices, disabled states.
  const TEXT_DIM := Color("4a6a8a")
  ```

- [ ] **Step 2: Verify the palette file loads in Godot**

  In `game/test/PixelArtVerification.gd`, add a palette check to `_ready()`:

  ```gdscript
  # Verify palette constants load without error
  var _void_check := Palette.VOID
  var _lantern_check := Palette.LANTERN
  print("Palette load: PASS — VOID=%s LANTERN=%s" % [Palette.VOID, Palette.LANTERN])
  ```

  Run the verification scene. Expected: no errors, palette values print correctly.

- [ ] **Step 3: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add game/src/constants/Palette.gd game/test/PixelArtVerification.gd \
      docs/art-production-guide.md
  git commit -m "feat(stage-0): add locked colour palette constants and update art production guide"
  ```

---

## Task 7: Document Prompt Templates in Art Production Guide

> **MANUAL HUMAN TASK — Cannot be automated. Developer action required.**
> Complete after Task 5 (generator validated) and Task 6a (palette locked).

- [ ] **Step 1: Develop and test the base style prompt**

  In Scenario.com, iterate on a base style prompt that produces consistently correct output from the trained generator. The base prompt should encode:
  - Pixel art style at Stardew Valley density
  - Dark maritime subject matter
  - The locked palette (if Scenario supports palette prompting, include palette hex or descriptors)
  - Pixel density and resolution expectation

  Example starting point (refine until output is correct):
  > `pixel art, 16x16 tile density, Stardew Valley style, dark maritime, age of sail, [SCENE DESCRIPTION], deep ocean blue palette, amber lantern light, storm gray, heavy vignette, foreboding, no anti-aliasing, chunky pixels`

- [ ] **Step 2: Develop per-asset-type prompt additions**

  For each asset type, develop the additional prompt fragment that produces the correct emotional register. Test each one and iterate.

  Reference the emotional register per event category from the spec:
  - **Crisis:** chaotic and disorienting — use storm elements, chaos, fire, structural damage
  - **Omen:** still and wrong — use impossible calm, wrong colours, dead things, unnatural geometry
  - **Landfall:** ambiguous — use rocky coasts, half-hidden structures, unclear whether safe
  - **Social:** enclosed, pressured, human — use ship interiors, faces, tight spaces
  - **Boon:** temporary and untrustworthy — use fair weather that feels suspicious
  - **Admiralty:** cold, institutional, distant — use formal interiors, maps, cold light
  - **Unknown:** featureless and threatening — use open dark sea, fog, nothing visible

- [ ] **Step 3: Fill in all prompt template sections in `docs/art-production-guide.md`**

  Replace every `_[Fill in]_` placeholder with the validated prompt text from Step 2.

- [ ] **Step 4: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add docs/art-production-guide.md
  git commit -m "docs(stage-0): complete prompt templates in art production guide"
  ```

---

## Task 8: Generate and Place the MVP Asset Set

> **MANUAL HUMAN TASK (generation) + file placement.**
> Complete after Task 7.

- [ ] **Step 1: Generate all 14 MVP assets using the prompt templates**

  Generate each asset using the validated prompt templates from Task 7. Generate 3–5 candidates per asset and select the best. Assets must:
  - Match the locked palette
  - Be at the correct native resolution (320×180 for backgrounds, 48×64 for portraits)
  - Pass the emotional register check for their category

  Assets to generate:
  1. `bg_crisis.png` (320×180)
  2. `bg_landfall.png` (320×180)
  3. `bg_social.png` (320×180)
  4. `bg_omen.png` (320×180)
  5. `bg_boon.png` (320×180)
  6. `bg_admiralty.png` (320×180)
  7. `bg_unknown.png` (320×180)
  8. `bg_ship_view.png` (320×180)
  9. `portrait_first_mate.png` (48×64)
  10. `portrait_bosun.png` (48×64)
  11. `portrait_purser.png` (48×64)
  12. `portrait_surgeon.png` (48×64)
  13. `tex_route_map.png` (320×180)
  14. `bg_admiralty_interior.png` (320×180)

- [ ] **Step 2: Place assets in the correct folders**

  ```
  game/assets/backgrounds/bg_crisis.png
  game/assets/backgrounds/bg_landfall.png
  game/assets/backgrounds/bg_social.png
  game/assets/backgrounds/bg_omen.png
  game/assets/backgrounds/bg_boon.png
  game/assets/backgrounds/bg_admiralty.png
  game/assets/backgrounds/bg_unknown.png
  game/assets/backgrounds/bg_ship_view.png
  game/assets/backgrounds/bg_admiralty_interior.png
  game/assets/portraits/portrait_first_mate.png
  game/assets/portraits/portrait_bosun.png
  game/assets/portraits/portrait_purser.png
  game/assets/portraits/portrait_surgeon.png
  game/assets/textures/tex_route_map.png
  ```

- [ ] **Step 3: Remove `.gitkeep` files now replaced by real assets**

  ```bash
  rm /home/joe/repos/deadreckoning/game/assets/backgrounds/.gitkeep
  rm /home/joe/repos/deadreckoning/game/assets/portraits/.gitkeep
  rm /home/joe/repos/deadreckoning/game/assets/textures/.gitkeep
  ```

- [ ] **Step 4: Verify assets load in Godot with correct nearest-neighbour filtering**

  In Godot 4.6, open the FileSystem panel and select each PNG. In the Import tab, confirm:
  - `Compress > Mode` = Lossless
  - `Flags > Filter` = Off (disabled — this enforces nearest-neighbour)
  - `Flags > Mipmaps` = Off

  If Filter is On for any asset, uncheck it and click Reimport.

  Add a TextureRect to `game/test/PixelArtVerification.tscn` pointing at `bg_crisis.png`. Set its expand mode to fill the screen. Run the project and confirm the image appears pixelated (chunky), not blurred or smoothed.

- [ ] **Step 5: Mark the asset checklist in `docs/art-production-guide.md`**

  Tick all items in the MVP Assets checklist.

- [ ] **Step 6: Commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add game/assets/ docs/art-production-guide.md
  git commit -m "feat(stage-0): add MVP asset set from Scenario generator"
  ```

---

## Task 9: Complete the Licensing Pre-Production Checklist and Finalise

**Files:**
- Modify: `docs/superpowers/specs/2026-04-12-art-direction-design.md`
- Delete: `game/test/PixelArtVerification.tscn`
- Delete: `game/test/PixelArtVerification.gd`
- Delete: `game/test/` (directory, if empty)

- [ ] **Step 1: Work through the pre-production licensing checklist**

  Open `docs/superpowers/specs/2026-04-12-art-direction-design.md` and mark each pre-production checklist item as complete. Items to verify:

  - Scenario.com plan confirmed (done in Task 4, Step 2)
  - Scenario.com indemnification confirmed (done in Task 4, Step 2)
  - Custom generator training data audited (done in Task 4, Step 4 — reference `docs/training-reference-log.md`)
  - Cinzel licence confirmed — open `game/assets/fonts/OFL-Cinzel.txt` and confirm it is the SIL OFL 1.1
  - Crimson Pro licence confirmed — open `game/assets/fonts/OFL-CrimsonPro.txt` and confirm it is the SIL OFL 1.1
  - Godot Engine licence confirmed — MIT, no action needed

- [ ] **Step 2: Remove the temporary verification scene**

  ```bash
  rm /home/joe/repos/deadreckoning/game/test/PixelArtVerification.tscn
  rm /home/joe/repos/deadreckoning/game/test/PixelArtVerification.gd
  rmdir /home/joe/repos/deadreckoning/game/test 2>/dev/null || true
  ```

- [ ] **Step 3: Remove the main scene entry from project.godot**

  Open `game/project.godot` and remove the `run/main_scene` line added in Task 1 Step 5. Stage 1 will set the correct main scene.

  The `[application]` section should be absent or empty after this step.

- [ ] **Step 4: Final run check**

  Open Godot 4.6 and confirm:
  - The project loads without errors
  - No missing resource warnings in the output panel
  - FileSystem panel shows all assets in the correct folders
  - Project settings still show nearest-neighbour filtering and landscape orientation

- [ ] **Step 5: Final commit**

  ```bash
  cd /home/joe/repos/deadreckoning
  git add -A
  git commit -m "feat(stage-0): complete art direction and asset pipeline — Stage 0 done"
  ```

---

## Stage 0 Exit Criteria

Stage 1 may begin when all of the following are true:

- [ ] Godot project renders at 1280×720 with nearest-neighbour filtering and landscape lock
- [ ] `game/assets/` contains all 14 MVP assets in the correct folders
- [ ] `game/src/constants/Palette.gd` contains the locked palette as typed constants
- [ ] `game/src/constants/FontSizes.gd` contains minimum font size constants
- [ ] `game/assets/fonts/` contains Cinzel, Crimson Pro, and both OFL licence files
- [ ] `docs/art-production-guide.md` is complete — no `_[Fill in]_` placeholders remain
- [ ] `docs/training-reference-log.md` documents every training reference image source
- [ ] Pre-production licensing checklist in the art direction spec is fully ticked

**Handoff note to Stage 1:** All interactive UI elements (choices, map nodes, buttons) must meet a minimum 44×44 dp touch target from the first screen built. This is a Stage 1 entry requirement, not a Stage 0 deliverable — but it must not be deferred beyond Stage 1.
