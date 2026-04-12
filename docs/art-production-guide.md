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
60-gun British fourth-rate man-of-war, three masts fully square-rigged, heavy broad hull, two rows of closed gun ports, high ornate stern gallery with small windows, black-tarred hull, single faded ochre stripe along the gun deck, heavy angled bowsprit, 1730s British naval silhouette
```

Based on HMS Centurion (1732). Use this in every exterior scene that shows the ship. Omit for interior scenes and portrait shots.

### [STYLE] — Style signature

```
detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and dark teal-blue palette, electric blue-white lightning as the sole cold light source, single amber-gold lantern as the only warm accent, diagonal pale blue-grey rain streaks, near-black storm clouds with blue undertones, dark teal choppy sea with pale blue-grey wave crests, ship in near-total silhouette, heavy black vignette at all edges, bioluminescent pale green foam at the waterline, Darkest Dungeon atmosphere, no anti-aliasing, no bright colours, no moonlight, no photorealism
```

The bioluminescent foam is the visual signature of this game — include it in every exterior sea scene. Lightning is the sole cold light source — no moonlight. The amber lantern does all the warmth alone.

### [COMP] — Composition rule

```
3/4 view from port bow, ship moving right to left, horizon in the lower third of the frame, vast dark sky dominant
```

Use for all exterior ship scenes. Interior scenes substitute their own framing.

---

## Prompt Templates

_[Fill in after Task 7]_

### Base Style Prompt

See **Prompt Components** above. All prompts are built from `[SHIP] — [STYLE] — [COMP] — [scene details]`.

### Scene Background — Hero Ship Establishing Shot

> Generate 5–10 of these. Pick the best single output and use it as the IP reference image for all subsequent exterior scenes.

```
[SHIP] — [STYLE] — [COMP] — moderate chop, full sails straining, no other ships visible, lightning illuminating the rigging from above-left, oppressive storm sky filling the upper two thirds
```

### Scene Background — Crisis

```
[SHIP] — [STYLE] with cold blue-white lightning strike replacing moonlight — [COMP] — sails torn, ship listing slightly to starboard, massive wave in foreground, lightning as the dominant light source
```

### Scene Background — Landfall

```
[SHIP] — [STYLE] — viewed from behind and slightly above, jagged rocky coastline in middle distance, rocky cliffs to the right, fog obscuring whether the coast is safe, horizon in the lower third
```

### Scene Background — Social

```
[STYLE] — HMS Centurion main deck at night, heavy timber planking, rigging and mast base visible, six crew in dark oilskins and knitted caps gathered in a tense semicircle, one figure restrained, officer with raised hand in the centre, no faces clearly visible, cinematic wide shot, amber lantern hanging from rigging as the only light source
```

### Scene Background — Omen

```
[SHIP] — detailed 32-bit pixel art, Sea of Stars pixel fidelity, near-black and sickly teal-green palette, no lightning, no lantern visible, bioluminescent pale green foam spreading unnaturally around the entire hull as the only light source, heavy black vignette, Darkest Dungeon atmosphere, no anti-aliasing — [COMP] — perfectly flat sea, sails hanging limp, no rain, no storm, total unnatural stillness, the green glow the only thing visible, something is deeply wrong
```

### Scene Background — Boon

```
[SHIP] — detailed 32-bit pixel art, Sea of Stars pixel fidelity, muted blue-grey and pale ochre palette, soft diffuse daylight from above, no vignette, bioluminescent pale green foam at the waterline, no anti-aliasing — [COMP] — fair weather, full sails, calm sea, pleasant but slightly wrong — sky too uniform, shadows too sharp, a moment of calm that feels borrowed
```

### Scene Background — Admiralty

_[Fill in after Task 7]_

### Scene Background — Unknown

```
[STYLE] — open ocean at night, no ship visible, no horizon line, dense fog from all sides, vast emptiness, faint bioluminescent green glow beneath the surface, nothing to orient by, oppressive and isolating
```

### Scene Background — Ship View

```
[SHIP] — [STYLE] — [COMP] — no crew visible on deck, sparse and isolating, lightning far in the distance providing faint cold light, no rain, ship alone on a dark teal sea
```

### Scene Background — Admiralty Interior

_[Fill in after Task 7]_

### Officer Portrait — First Mate

```
[STYLE] — portrait orientation 3:4, close-up face and shoulders, weathered male ship's officer mid-40s, aged naval coat with worn brass buttons, stern expression, amber lantern light from below as key light, cold blue moonlight as rim light from above-left, salt-worn skin, dark near-black background, Darkest Dungeon portrait composition
```

### Officer Portrait — Bosun

```
[STYLE] — portrait orientation 3:4, close-up face and shoulders, broad-built male bosun late-40s, heavy oilskin coat, suspicious expression, callused hands visible at collar, amber lantern light from below, cold blue rim light from above-left, dark background, Darkest Dungeon portrait composition
```

### Officer Portrait — Purser

```
[STYLE] — portrait orientation 3:4, close-up face and shoulders, lean male purser 30s, ink-stained fingers visible at collar, calculating expression, small round spectacles, amber lantern light from below, cold blue rim light from above-left, dark background, Darkest Dungeon portrait composition
```

### Officer Portrait — Surgeon

```
[STYLE] — portrait orientation 3:4, close-up face and shoulders, gaunt surgeon 50s, dark coat with stained cuffs, haunted expression, sunken eyes, amber lantern light from below giving sickly cast to skin, cold blue rim light from above-left, near-black background, Darkest Dungeon portrait composition
```

### Route Map Background Texture

_[Fill in after Task 7]_

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
