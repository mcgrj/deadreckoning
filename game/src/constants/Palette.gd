# Palette.gd
# Locked colour palette for Dead Reckoning. Every colour used in the game UI
# must come from this file. Do not use ad-hoc Color() calls elsewhere.
#
# NOTE: These are placeholder values from the plan. Replace every hex value
# with the actual locked palette extracted in Task 6a (Scenario.com palette
# extraction) and update docs/art-production-guide.md accordingly.
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
