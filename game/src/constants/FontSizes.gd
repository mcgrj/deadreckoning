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
