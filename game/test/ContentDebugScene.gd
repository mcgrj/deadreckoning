# ContentDebugScene.gd
# Interactive debug scene for Stage 1 content framework.
# Shows Validate All + per-family buttons. Output in scrollable RichTextLabel.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
extends Control

@onready var _output: RichTextLabel = $VBox/ScrollContainer/Output


func _ready() -> void:
	$VBox/Buttons/ValidateAll.pressed.connect(_on_validate_all_pressed)
	$VBox/Buttons/Incidents.pressed.connect(_on_family_pressed.bind("incidents"))
	$VBox/Buttons/Officers.pressed.connect(_on_family_pressed.bind("officers"))
	$VBox/Buttons/Supplies.pressed.connect(_on_family_pressed.bind("supplies"))
	$VBox/Buttons/StandingOrders.pressed.connect(_on_family_pressed.bind("standing_orders"))
	$VBox/Buttons/Upgrades.pressed.connect(_on_family_pressed.bind("upgrades"))
	$VBox/Buttons/Doctrines.pressed.connect(_on_family_pressed.bind("doctrines"))
	$VBox/Buttons/CrewBackgrounds.pressed.connect(_on_family_pressed.bind("crew_backgrounds"))
	$VBox/Buttons/ZoneTypes.pressed.connect(_on_family_pressed.bind("zone_types"))
	$VBox/Buttons/Objectives.pressed.connect(_on_family_pressed.bind("objectives"))
	_show_validate_all()


func _on_validate_all_pressed() -> void:
	_show_validate_all()


func _on_family_pressed(family: String) -> void:
	_show_family(family)


func _show_validate_all() -> void:
	_output.clear()
	_output.append_text("[b]Content Catalog — Validate All[/b]\n\n")
	for family: String in ContentRegistry.get_families():
		var items := ContentRegistry.get_all(family)
		_output.append_text("[b]%s[/b]: %d item(s)\n" % [family, items.size()])
	var errors := ContentRegistry.get_validation_errors()
	if errors.is_empty():
		_output.append_text("\n[color=green]PASS — no validation errors[/color]\n")
		_output.append_text("\nOverall: [color=green]VALID[/color]\n")
	else:
		_output.append_text("\n[color=red]FAIL — %d error(s):[/color]\n" % errors.size())
		for err: String in errors:
			_output.append_text("  • %s\n" % err)
		_output.append_text("\nOverall: [color=red]INVALID[/color]\n")


func _show_family(family: String) -> void:
	_output.clear()
	_output.append_text("[b]%s[/b]\n\n" % family)
	var items := ContentRegistry.get_all(family)
	if items.is_empty():
		_output.append_text("(no items loaded)\n")
		return
	for item: ContentBase in items:
		_output.append_text("• [b]%s[/b]  %s\n" % [item.id, item.display_name])
		if not item.category.is_empty():
			_output.append_text("  category: %s\n" % item.category)
		if not item.tags.is_empty():
			_output.append_text("  tags: %s\n" % ", ".join(item.tags))
		_output.append_text("\n")
