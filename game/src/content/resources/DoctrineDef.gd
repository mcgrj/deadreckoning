# DoctrineDef.gd
# Content definition for an Admiralty doctrine.
# Stored as a .tres file under res://content/doctrines/.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
class_name DoctrineDef
extends ContentBase

## Standing order ids unlocked when this doctrine is active.
@export var unlocked_standing_order_ids: Array[String] = []

## Tag applied to expedition command culture (e.g. "egalitarian", "authoritarian").
@export var command_culture_modifier: String = ""

## Flavour and mechanical summary shown in the Admiralty preparation screen.
@export var description: String = ""
