# ContentDebugScene.gd
# Interactive debug scene for Stage 1 content framework.
# Sidebar of family buttons on the left, scrollable output on the right.
#
# Spec: docs/superpowers/specs/2026-04-12-stage-1-content-framework-design.md
extends HBoxContainer

@onready var _output: RichTextLabel = $OutputContainer/Output


func _ready() -> void:
	$Sidebar/ValidateAll.pressed.connect(_on_validate_all_pressed)
	$Sidebar/Incidents.pressed.connect(_on_family_pressed.bind("incidents"))
	$Sidebar/Officers.pressed.connect(_on_family_pressed.bind("officers"))
	$Sidebar/Supplies.pressed.connect(_on_family_pressed.bind("supplies"))
	$Sidebar/StandingOrders.pressed.connect(_on_family_pressed.bind("standing_orders"))
	$Sidebar/Upgrades.pressed.connect(_on_family_pressed.bind("upgrades"))
	$Sidebar/Doctrines.pressed.connect(_on_family_pressed.bind("doctrines"))
	$Sidebar/CrewBackgrounds.pressed.connect(_on_family_pressed.bind("crew_backgrounds"))
	$Sidebar/ZoneTypes.pressed.connect(_on_family_pressed.bind("zone_types"))
	$Sidebar/Objectives.pressed.connect(_on_family_pressed.bind("objectives"))
	_show_validate_all()


func _on_validate_all_pressed() -> void:
	_show_validate_all()


func _on_family_pressed(family: String) -> void:
	_show_family(family)


func _show_validate_all() -> void:
	_output.clear()
	$OutputContainer.scroll_vertical = 0
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
	$OutputContainer.scroll_vertical = 0
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
