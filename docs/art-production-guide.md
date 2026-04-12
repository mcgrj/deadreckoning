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

## Prompt Components

These three strings are the invariant foundation of every prompt. Copy them verbatim — changing any word will shift the output style. Combine them as: `[SHIP] — [STYLE] — [COMP] — [scene-specific details]`.

### [SHIP] — Ship description

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery with small windows, black-tarred hull, single faded ochre stripe along the gun deck, heavy angled bowsprit, 1730s British naval silhouette, single taffrail lantern mounted at the very top of the stern above the gallery windows visible only as a small amber glow at the far aft of the ship partially obscured by the stern cabin structure
```

Based on HMS Centurion (1732). Use this in every exterior scene that shows the ship. Omit for interior scenes and portrait shots.

### [STYLE] — Style signature

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, electric blue-white lightning as the sole cold light source, single amber-gold taffrail lantern at the extreme rear top of the stern only — not on the masts, not at the bow, not mid-ship — a feeble barely-visible warm glow at the far aft edge of the hull partially hidden behind the stern cabin, ship rendered small and insignificant against the vast hostile environment, diagonal pale blue-grey rain streaks, near-black storm clouds with crushing mass pressing down, dark teal sea that feels alive and indifferent to human survival, heavy black vignette consuming all edges, bioluminescent pale green foam at the waterline suggesting something beneath the surface, Darkest Dungeon nihilism, oppressive and inescapable atmosphere, no refuge visible anywhere in the frame, no anti-aliasing, no bright colours, no moonlight, no photorealism
```

The bioluminescent foam is the visual signature of this game — include it in every exterior sea scene. Lightning is the sole cold light source — no moonlight. The taffrail lantern is always at the extreme stern, partially obscured — never mid-ship or on the masts.

### [COMP] — Composition rule

```
3/4 view from port bow, ship occupying no more than one third of the frame, moving right to left toward something worse, horizon buried and invisible, vast hostile sky and sea dominant, no safe space in the composition, the ship heading deeper into danger not away from it
```

Use for all exterior ship scenes. Interior scenes substitute their own framing.

---

## Prompt Templates

### Base Style Prompt

All prompts are built from `[SHIP] — [STYLE] — [COMP] — [scene details]`. The components above are the complete base style — do not add additional style words outside of scene-specific details.

### Scene Background — Hero Ship Establishing Shot

> Generate 5–10 of these. Pick the best single output and use it as the IP reference image for all subsequent exterior scenes. You are looking for the clearest ship silhouette with the strongest contrast between ship and sky.

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery with small windows, black-tarred hull, single faded ochre stripe along the gun deck, heavy angled bowsprit, 1730s British naval silhouette, single taffrail lantern mounted at the very top of the stern above the gallery windows visible only as a small amber glow at the far aft of the ship partially obscured by the stern cabin structure — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, massive wall of forked lightning on the horizon illuminating a storm system of overwhelming scale, the ship a tiny dark silhouette against the electric flash, single amber-gold taffrail lantern at the extreme rear top of the stern only — not on the masts, not at the bow, not mid-ship — a feeble barely-visible warm pinprick at the far aft edge of the hull partially hidden behind the stern cabin, ship rendered small and insignificant against the vast hostile environment, heavy diagonal pale blue-grey rain, near-black storm clouds with crushing mass pressing down, dark teal sea heaving with enormous swells dwarfing the ship, bioluminescent pale green foam churned across the surface suggesting movement below, heavy black vignette consuming all edges, something vast and dark implied in the cloud formations above, Darkest Dungeon nihilism, no refuge anywhere in the frame, no anti-aliasing, no photorealism — 3/4 view from port bow, ship occupying the lower left third of the frame only, moving right to left into the heart of the storm, horizon invisible beneath massive swells, the storm wall filling the entire right half of the frame, the ship heading directly into it with no escape implied
```

### Scene Background — Crisis

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery with small windows, black-tarred hull, single faded ochre stripe along the gun deck, heavy angled bowsprit, 1730s British naval silhouette, single taffrail lantern mounted at the very top of the stern above the gallery windows partially obscured by the stern cabin — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, lightning strike directly behind the mainmast as the dominant backlight casting electric blue-white light across torn rigging, single amber-gold taffrail lantern at the extreme rear top of the stern only barely visible, ship rendered small against the overwhelming storm, heavy diagonal rain, near-black storm clouds pressing down, dark teal sea with massive breaking waves, bioluminescent pale green foam churned violently, heavy black vignette consuming all edges, Darkest Dungeon nihilism, no refuge in the frame, no anti-aliasing, no photorealism — 3/4 view from port bow, ship occupying the lower left third, listing 15 degrees to starboard, bow plunging into a massive wave, sails torn, horizon invisible
```

### Scene Background — Landfall

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery, black-tarred hull, 1730s British naval silhouette, single taffrail lantern at the very top of the stern above the gallery windows partially obscured by the stern cabin — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, electric blue-white lightning illuminating the scene from above, single amber-gold taffrail lantern at the extreme rear top of the stern only, diagonal pale blue-grey rain, near-black storm clouds pressing down, heavy black vignette consuming all edges, bioluminescent pale green foam at the waterline, Darkest Dungeon nihilism, no refuge anywhere in the frame, no anti-aliasing, no photorealism — ship occupying the right third of the frame moving left toward a jagged black coastline, enormous dark cliffs filling the left half, white surf breaking at their base, no lighthouse, no safe harbour implied, the ship closing on rocks with no escape route visible, horizon invisible
```

### Scene Background — Social

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, single tallow candle on an upturned barrel as the only light source — a feeble amber-gold glow that barely reaches the walls, heavy black vignette consuming all edges, Darkest Dungeon nihilism, oppressive and inescapable atmosphere, no anti-aliasing, no photorealism — cramped ship lower deck, low timber ceiling pressing down, thick oak ribs and hull planking visible, six crew in dark oilskins crowded into a suffocating space, two figures facing each other in confrontation, others watching in silence from deep shadow, faces barely visible, the candle flame the only warm thing in the frame, the darkness beyond it absolute, water trickling down the hull planks
```

### Scene Background — Omen

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery, black-tarred hull, 1730s British naval silhouette, taffrail lantern extinguished and dark — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with sickly green undertone, no lightning, no rain, no wind, no lantern, bioluminescent pale green foam spreading unnaturally from the hull in all directions as the only light source casting a sickly glow, heavy black vignette consuming all edges, something vast implied moving slowly beneath the surface, Darkest Dungeon nihilism, absolute wrongness, no anti-aliasing, no photorealism — 3/4 view from port bow, ship stationary and listing slightly, sails hanging limp, mirror-flat sea, the green bioluminescence the only illumination, the ship stopped in the middle of nothing with nowhere to go
```

### Scene Background — Boon

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery, black-tarred hull, single faded ochre stripe along the gun deck, 1730s British naval silhouette, single taffrail lantern unlit in daylight — detailed 32-bit pixel art, Sea of Stars pixel fidelity, muted cold blue-grey and pale ochre palette, soft diffuse overcast daylight from above, no vignette, bioluminescent pale green foam at the waterline barely visible in the daylight, no anti-aliasing, no photorealism — 3/4 view from port bow, ship moving right to left, full sails, calm sea, horizon visible and low, the scene superficially calmer than all others but sky too uniform, shadows too sharp, the calm feeling borrowed and temporary, something still wrong beneath the surface
```

### Scene Background — Unknown

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with the faintest teal undertone, no lightning, no lantern, no ship, heavy black vignette consuming all edges, bioluminescent pale green light faintly pulsing beneath the surface as the only illumination, something vast and dark suggested in movement below the waterline, Darkest Dungeon nihilism, no refuge anywhere in the frame, no anti-aliasing, no photorealism — open ocean at night viewed from just above the waterline, no horizon visible, dense black fog from all sides, the sea surface near-black with faint green light shifting beneath it, vast emptiness in every direction, nothing to navigate by, nothing to hold onto
```

### Scene Background — Ship View

```
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery with small windows, black-tarred hull, single faded ochre stripe along the gun deck, heavy angled bowsprit, 1730s British naval silhouette, single taffrail lantern mounted at the very top of the stern above the gallery windows partially obscured by the stern cabin — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette crushed toward black, electric blue-white lightning far in the distance as the sole cold light source, single amber-gold taffrail lantern at the extreme rear top of the stern only barely visible, no crew on deck, ship rendered small and isolating against a vast dark teal sea, heavy black vignette consuming all edges, bioluminescent pale green foam at the waterline, Darkest Dungeon nihilism, oppressive and inescapable atmosphere, no anti-aliasing, no photorealism — 3/4 view from port bow, ship occupying no more than one third of the frame, moving right to left, horizon barely visible, the ship alone with nothing around it in any direction
```

### Scene Background — Admiralty Interior

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and cold slate-grey palette, two tall narrow windows providing cold grey daylight as the only light source, no warmth anywhere in the frame, heavy black vignette consuming all edges, Darkest Dungeon nihilism, oppressive and inescapable atmosphere, no anti-aliasing, no photorealism — formal Georgian admiralty chamber, high stone walls, heavy oak table covered in charts and sealed orders, empty high-backed chair behind the desk implying presence through absence, iron candelabra unlit, maps pinned to the walls showing routes that end at the edge of known water, cold grey light falling on the empty chair, the room where decisions are made by people who will never experience their consequences, no people visible, the power entirely implied
```

### Officer Portrait — First Mate

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with cold teal undertone, electric blue-white lightning from a porthole as cold rim light from above-left, no warm light source, heavy black vignette consuming all edges, Darkest Dungeon portrait composition, no anti-aliasing, no photorealism — portrait orientation 3:4, extreme close-up face and upper shoulders only, weathered male first mate mid-40s, hollow cheeks, eyes that have seen too much, aged naval coat collar rain-soaked, lightning flash catching the side of his face in cold blue-white, the rest in near-total shadow, expression of a man who knows what is coming and sees no way to stop it, near-black background consuming everything outside the lightning rim
```

### Officer Portrait — Bosun

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with cold teal undertone, electric blue-white lightning from a porthole as cold rim light from above-left, no warm light source, heavy black vignette consuming all edges, Darkest Dungeon portrait composition, no anti-aliasing, no photorealism — portrait orientation 3:4, extreme close-up face and upper shoulders only, broad-built male bosun late-40s, heavy oilskin coat, suspicious expression that has curdled into something darker, callused hands visible at collar, lightning catching the hard planes of his face, the rest in shadow, a man whose loyalty is to survival not principle, near-black background
```

### Officer Portrait — Purser

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with cold teal undertone, electric blue-white lightning from a porthole as cold rim light from above-left, no warm light source, heavy black vignette consuming all edges, Darkest Dungeon portrait composition, no anti-aliasing, no photorealism — portrait orientation 3:4, extreme close-up face and upper shoulders only, lean male purser 30s, ink-stained fingers visible at collar, calculating expression, small round spectacles catching the lightning flash, the eyes behind them unreadable, a man who knows exactly what everything costs including the things that shouldn't have a price, near-black background
```

### Officer Portrait — Surgeon

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black palette with cold teal undertone, electric blue-white lightning from a porthole as cold rim light from above-left, no warm light source, heavy black vignette consuming all edges, Darkest Dungeon portrait composition, no anti-aliasing, no photorealism — portrait orientation 3:4, extreme close-up face and upper shoulders only, gaunt surgeon 50s, dark coat with stained cuffs, haunted expression, sunken eyes that have watched too many people die and stopped being troubled by it, lightning catching the angles of a face that has been hollowed out by what it has seen, near-black background consuming everything
```

### Route Map Background Texture

_[Fill in after Task 7]_

---

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
