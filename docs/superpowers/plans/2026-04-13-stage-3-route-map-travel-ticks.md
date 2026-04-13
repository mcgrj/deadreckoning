# Stage 3: Route Map and Travel Ticks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the run skeleton — RouteNode/RouteMap data structures, TravelSimulator tick processor, two new zone types, and an extended debug scene showing a BBCode route map with daily travel mechanics.

**Architecture:** Pure RefCounted data classes (RouteNode, RouteMap) with a static factory method for future procedural-generation swap-in. TravelSimulator is a stateless static class extending Stage 2 simulation. The debug scene is extended with Route Map buttons and a BBCode route diagram using RichTextLabel meta-links for node selection.

**Tech Stack:** GDScript 4, Godot 4.6 headless, `.tres` Resources, ContentRegistry autoload, Stage 2 classes (ExpeditionState, EffectProcessor, ConditionEvaluator, RumRules, SimulationLog).

---

## File Map

**Create:**
- `game/src/expedition/RouteNode.gd` — single route node data class (RefCounted)
- `game/src/expedition/RouteMap.gd` — full map: stages, position, factory, navigation
- `game/src/expedition/TravelSimulator.gd` — stateless tick processor
- `game/content/supplies/water.tres` — water supply (required by TravelSimulator)
- `game/content/zone_types/lee_shore.tres` — Lee Shore zone
- `game/content/zone_types/unknown_zone.tres` — Unknown Waters zone
- `game/test/RouteMapTest.gd` — headless test script (grows across Tasks 1–8)
- `game/test/RouteMapTest.tscn` — headless test scene

**Modify:**
- `game/src/expedition/ExpeditionState.gd` — add travel_fatigue, sickness_risk, pending_incident_id
- `game/test/ContentDebugScene.gd` — add Route Map section
- `game/test/ContentDebugScene.tscn` — add Route Map sidebar buttons

---

### Task 1: RouteNode + test infrastructure

**Files:**
- Create: `game/test/RouteMapTest.tscn`
- Create: `game/test/RouteMapTest.gd`
- Create: `game/src/expedition/RouteNode.gd`

- [ ] **Step 1: Create test scene**

Write `game/test/RouteMapTest.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test/RouteMapTest.gd" id="1"]

[node name="RouteMapTest" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Write failing tests for RouteNode**

Write `game/test/RouteMapTest.gd`:
```gdscript
# RouteMapTest.gd
# Headless test suite for Stage 3: Route Map and Travel Ticks.
# Run: godot --headless --path game res://test/RouteMapTest.tscn
extends Node

var _pass = 0
var _fail = 0


func check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
		_pass += 1
	else:
		push_error("  FAIL: " + label)
		_fail += 1


func _ready() -> void:
	print("=== RouteMapTest ===\n")
	_test_route_node()
	_finish()


func _finish() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass, _fail])
	if _fail > 0:
		OS.crash("Tests failed")
	print("ALL PASS")
	get_tree().quit(0)


# --- Helpers ---

func _make_zone(consumption: float = 1.0, wear: float = 1.0, burden_delta: int = 0) -> ZoneTypeDef:
	var z = ZoneTypeDef.new()
	z.consumption_modifier = consumption
	z.ship_wear_modifier = wear
	z.burden_delta_per_tick = burden_delta
	return z


func _make_state():
	return ExpeditionState.create_default()


func _make_log():
	return SimulationLog.new()


# --- RouteNode ---

func _test_route_node() -> void:
	print("-- RouteNode --")

	var n = RouteNode.new()
	check(n.id == "", "id default empty")
	check(n.category == "", "category default empty")
	check(n.tick_distance == 0, "tick_distance default 0")
	check(n.zone_type_id == "", "zone_type_id default empty")
	check(n.hints.is_empty(), "hints default empty")
	check(n.is_objective_node == false, "is_objective_node default false")
	check(n.required_node_category == "", "required_node_category default empty")

	var node = RouteNode.make("stage1_crisis", "crisis", 3, "coastal")
	check(node.id == "stage1_crisis", "make() sets id")
	check(node.category == "crisis", "make() sets category")
	check(node.tick_distance == 3, "make() sets tick_distance")
	check(node.zone_type_id == "coastal", "make() sets zone_type_id")
	check(node.hints.is_empty(), "make() hints default empty")
	check(node.is_objective_node == false, "make() is_objective_node default false")
	check(node.required_node_category == "", "make() required_node_category default empty")

	var node2 = RouteNode.make(
		"stage3_admiralty", "admiralty", 4, "open_ocean",
		["Survey coordinates confirmed."], true, "admiralty"
	)
	check(node2.hints.size() == 1, "make() hints populated")
	check(node2.hints[0] == "Survey coordinates confirmed.", "make() hint content correct")
	check(node2.is_objective_node == true, "make() is_objective_node set")
	check(node2.required_node_category == "admiralty", "make() required_node_category set")
```

- [ ] **Step 3: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: error like `Parse Error: Identifier "RouteNode" not found`

- [ ] **Step 4: Create RouteNode.gd**

Write `game/src/expedition/RouteNode.gd`:
```gdscript
# RouteNode.gd
# Single route node in a RouteMap. RefCounted data class — not a Resource.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name RouteNode
extends RefCounted

var id: String = ""
var category: String = ""
var tick_distance: int = 0
var zone_type_id: String = ""
var hints: Array[String] = []
var is_objective_node: bool = false
var required_node_category: String = ""


static func make(
	id: String,
	category: String,
	tick_distance: int,
	zone_type_id: String,
	hints: Array[String] = [],
	is_objective_node: bool = false,
	required_node_category: String = ""
) -> RouteNode:
	var node = RouteNode.new()
	node.id = id
	node.category = category
	node.tick_distance = tick_distance
	node.zone_type_id = zone_type_id
	node.hints = hints
	node.is_objective_node = is_objective_node
	node.required_node_category = required_node_category
	return node
```

- [ ] **Step 5: Register class and run tests**

```
godot --headless --path game --import
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS` (14 assertions)

- [ ] **Step 6: Commit**

```bash
git add game/test/RouteMapTest.tscn game/test/RouteMapTest.gd game/src/expedition/RouteNode.gd
git commit -m "feat(stage-3): add RouteNode data class and test infrastructure"
```

---

### Task 2: RouteMap factory and navigation

**Files:**
- Create: `game/src/expedition/RouteMap.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add RouteMap tests to RouteMapTest.gd**

Add the following functions to `game/test/RouteMapTest.gd`. Also add calls to `_ready()`:

In `_ready()`, add after `_test_route_node()`:
```gdscript
	_test_route_map_factory()
	_test_route_map_navigation()
```

Add these functions:
```gdscript
# --- RouteMap factory ---

func _test_route_map_factory() -> void:
	print("-- RouteMap factory --")

	var map = RouteMap.create_test_map()
	check(map.stages.size() == 4, "test map has 4 stages")
	check(map.current_stage_index == 0, "starts at stage 0")
	check(map.selected_path.is_empty(), "selected_path starts empty")
	check(map.active_node == null, "active_node starts null")
	check(map.ticks_remaining == 0, "ticks_remaining starts 0")

	# Stage 1 — 3 nodes, all coastal
	var s1: Array = map.stages[0]
	check(s1.size() == 3, "stage 1 has 3 nodes")
	check(s1[0].id == "stage1_crisis",   "stage1 node 0 id")
	check(s1[0].category == "crisis",    "stage1 node 0 category")
	check(s1[0].tick_distance == 3,      "stage1 node 0 tick_distance")
	check(s1[0].zone_type_id == "coastal", "stage1 node 0 zone")
	check(s1[1].id == "stage1_landfall", "stage1 node 1 id")
	check(s1[2].id == "stage1_omen",     "stage1 node 2 id")

	# Stage 2 — 2 nodes, open_ocean
	var s2: Array = map.stages[1]
	check(s2.size() == 2, "stage 2 has 2 nodes")
	check(s2[0].zone_type_id == "open_ocean", "stage2 node 0 zone")
	check(s2[1].zone_type_id == "open_ocean", "stage2 node 1 zone")

	# Stage 3 — boon (lee_shore) + admiralty (open_ocean), admiralty is objective
	var s3: Array = map.stages[2]
	check(s3.size() == 2, "stage 3 has 2 nodes")
	check(s3[0].zone_type_id == "lee_shore",  "stage3 boon zone is lee_shore")
	check(s3[1].zone_type_id == "open_ocean", "stage3 admiralty zone is open_ocean")
	check(s3[1].is_objective_node == true,     "stage3 admiralty is objective node")

	# Stage 4 — 2 nodes, unknown_zone
	var s4: Array = map.stages[3]
	check(s4.size() == 2, "stage 4 has 2 nodes")
	check(s4[0].zone_type_id == "unknown_zone", "stage4 node 0 zone")
	check(s4[1].zone_type_id == "unknown_zone", "stage4 node 1 zone")

	# All 7 categories present
	var all_categories: Array = []
	for stage in map.stages:
		for node in stage:
			if node.category not in all_categories:
				all_categories.append(node.category)
	for cat in ["crisis", "landfall", "omen", "social", "unknown", "boon", "admiralty"]:
		check(cat in all_categories, "category present: %s" % cat)

	# All 4 zone types present
	var all_zones: Array = []
	for stage in map.stages:
		for node in stage:
			if node.zone_type_id not in all_zones:
				all_zones.append(node.zone_type_id)
	for zone in ["coastal", "open_ocean", "lee_shore", "unknown_zone"]:
		check(zone in all_zones, "zone type present: %s" % zone)


# --- RouteMap navigation ---

func _test_route_map_navigation() -> void:
	print("-- RouteMap navigation --")

	var map = RouteMap.create_test_map()

	# get_current_stage returns stage 0 nodes
	var stage = map.get_current_stage()
	check(stage.size() == 3, "get_current_stage returns 3 nodes at start")

	# Not travelling, not complete at start
	check(map.is_travelling() == false, "not travelling at start")
	check(map.is_complete() == false, "not complete at start")

	# select_node sets active_node and ticks_remaining
	var node = stage[0]  # stage1_crisis, 3 days
	map.select_node(node)
	check(map.active_node == node, "select_node sets active_node")
	check(map.ticks_remaining == 3, "select_node sets ticks_remaining to 3")
	check(map.is_travelling() == true, "is_travelling true after select_node")

	# advance_tick decrements ticks_remaining
	map.advance_tick()
	check(map.ticks_remaining == 2, "advance_tick decrements to 2")
	check(map.is_travelling() == true, "still travelling at 2")

	map.advance_tick()
	check(map.ticks_remaining == 1, "advance_tick decrements to 1")

	# Final tick: arrive
	map.advance_tick()
	check(map.ticks_remaining == 0, "ticks_remaining 0 after arrival")
	check(map.active_node == null, "active_node null after arrival")
	check(map.selected_path.size() == 1, "selected_path has 1 entry after first arrival")
	check(map.selected_path[0].id == "stage1_crisis", "selected_path[0] is stage1_crisis")
	check(map.current_stage_index == 1, "current_stage_index advanced to 1")
	check(map.is_travelling() == false, "not travelling after arrival")
	check(map.is_complete() == false, "not complete after stage 1")

	# get_current_stage now returns stage 1 (index 1)
	var stage2 = map.get_current_stage()
	check(stage2.size() == 2, "stage 2 has 2 nodes")

	# get_active_zone returns null when not travelling
	var zone = map.get_active_zone()
	check(zone == null, "get_active_zone null when not travelling")

	# Travel through all remaining stages to reach completion
	for i in range(3):
		var s = map.get_current_stage()
		map.select_node(s[0])
		for _t in range(s[0].tick_distance):
			map.advance_tick()

	check(map.is_complete() == true, "is_complete after all 4 stages")
	check(map.selected_path.size() == 4, "selected_path has 4 entries")
	check(map.get_current_stage().is_empty(), "get_current_stage empty when complete")

	# advance_tick is a no-op when not travelling
	map.advance_tick()
	check(map.ticks_remaining == 0, "advance_tick no-op when not travelling")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: error — `Identifier "RouteMap" not found`

- [ ] **Step 3: Create RouteMap.gd**

Write `game/src/expedition/RouteMap.gd`:
```gdscript
# RouteMap.gd
# Full route structure for one expedition run.
# Holds stages (Array of Array[RouteNode]), tracks position, exposes navigation.
# Static factory creates hand-authored test map; swap for generate() in future.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name RouteMap
extends RefCounted

# Array of Array[RouteNode] — each inner array is one stage's node choices
var stages: Array = []
var current_stage_index: int = 0
var selected_path: Array = []  # Array[RouteNode], one per completed stage
var active_node = null          # RouteNode currently being travelled to, or null
var ticks_remaining: int = 0


static func create_test_map() -> RouteMap:
	var map = RouteMap.new()
	map.stages = [
		# Stage 1 — coastal
		[
			RouteNode.make("stage1_crisis",   "crisis",   3, "coastal",
				["Fog reported on the approach.", "Hazard: reef shelf."]),
			RouteNode.make("stage1_landfall", "landfall", 4, "coastal",
				["Supply opportunity: fresh water.", "A sheltered cove to the west."]),
			RouteNode.make("stage1_omen",     "omen",     2, "coastal",
				["Strange lights at the headland."]),
		],
		# Stage 2 — open ocean
		[
			RouteNode.make("stage2_social",  "social",  2, "open_ocean",
				["A trading vessel on the horizon."]),
			RouteNode.make("stage2_unknown", "unknown", 3, "open_ocean",
				["Uncharted waters. Proceed with caution."]),
		],
		# Stage 3 — lee shore + open ocean
		[
			RouteNode.make("stage3_boon",      "boon",      2, "lee_shore",
				["A fishing village willing to trade."]),
			RouteNode.make("stage3_admiralty", "admiralty", 4, "open_ocean",
				["Signal from an Admiralty patrol vessel.", "Survey coordinates confirmed."],
				true),
		],
		# Stage 4 — unknown waters
		[
			RouteNode.make("stage4_crisis",   "crisis",   2, "unknown_zone",
				["Strange currents. The compass spins."]),
			RouteNode.make("stage4_landfall", "landfall", 3, "unknown_zone",
				["Uncharted coast ahead.", "Hazard: shifting sandbars."]),
		],
	]
	return map


func get_current_stage() -> Array:
	if current_stage_index >= stages.size():
		return []
	return stages[current_stage_index]


func select_node(node: RouteNode) -> void:
	active_node = node
	ticks_remaining = node.tick_distance


func is_travelling() -> bool:
	return ticks_remaining > 0


func is_complete() -> bool:
	return current_stage_index >= stages.size() and not is_travelling()


func advance_tick() -> void:
	if ticks_remaining <= 0:
		return
	ticks_remaining -= 1
	if ticks_remaining == 0:
		selected_path.append(active_node)
		current_stage_index += 1
		active_node = null


func get_active_zone() -> ZoneTypeDef:
	if active_node == null:
		return null
	return ContentRegistry.get_by_id("zone_types", active_node.zone_type_id) as ZoneTypeDef
```

- [ ] **Step 4: Register and run tests**

```
godot --headless --path game --import
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/RouteMap.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): add RouteMap factory and navigation"
```

---

### Task 3: Water supply + zone type content

**Files:**
- Create: `game/content/supplies/water.tres`
- Create: `game/content/zone_types/lee_shore.tres`
- Create: `game/content/zone_types/unknown_zone.tres`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add zone type tests to RouteMapTest.gd**

In `_ready()`, add after `_test_route_map_navigation()`:
```gdscript
	_test_zone_types()
```

Add this function:
```gdscript
# --- Zone types ---

func _test_zone_types() -> void:
	print("-- Zone types --")

	var lee = ContentRegistry.get_by_id("zone_types", "lee_shore") as ZoneTypeDef
	check(lee != null, "lee_shore loads from ContentRegistry")
	check(lee.id == "lee_shore", "lee_shore id correct")
	check(lee.display_name == "Lee Shore", "lee_shore display_name correct")
	check(lee.category == "hazard", "lee_shore category is hazard")
	check(is_equal_approx(lee.consumption_modifier, 1.0), "lee_shore consumption_modifier 1.0")
	check(is_equal_approx(lee.ship_wear_modifier, 1.8), "lee_shore ship_wear_modifier 1.8")
	check(lee.burden_delta_per_tick == 1, "lee_shore burden_delta_per_tick 1")
	check(is_equal_approx(lee.incident_weight_modifier, 1.4), "lee_shore incident_weight_modifier 1.4")
	check("storm" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has storm")
	check("navigation" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has navigation")
	check("crisis" in lee.eligible_incident_tags, "lee_shore eligible_incident_tags has crisis")

	var unk = ContentRegistry.get_by_id("zone_types", "unknown_zone") as ZoneTypeDef
	check(unk != null, "unknown_zone loads from ContentRegistry")
	check(unk.id == "unknown_zone", "unknown_zone id correct")
	check(unk.display_name == "Unknown Waters", "unknown_zone display_name correct")
	check(unk.category == "unknown", "unknown_zone category is unknown")
	check(is_equal_approx(unk.consumption_modifier, 1.1), "unknown_zone consumption_modifier 1.1")
	check(is_equal_approx(unk.ship_wear_modifier, 1.3), "unknown_zone ship_wear_modifier 1.3")
	check(unk.burden_delta_per_tick == 2, "unknown_zone burden_delta_per_tick 2")
	check(is_equal_approx(unk.incident_weight_modifier, 2.0), "unknown_zone incident_weight_modifier 2.0")

	var water = ContentRegistry.get_by_id("supplies", "water") as SupplyDef
	check(water != null, "water supply loads from ContentRegistry")
	check(water.id == "water", "water id correct")
	check(water.daily_consumption > 0, "water daily_consumption > 0")
	check(water.critical_threshold > 0, "water critical_threshold > 0")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: failures on lee_shore, unknown_zone, water not loading.

- [ ] **Step 3: Create water.tres**

Write `game/content/supplies/water.tres`:
```
[gd_resource type="Resource" script_class="SupplyDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/SupplyDef.gd" id="1_water"]

[resource]
script = ExtResource("1_water")
starting_amount = 150
daily_consumption = 3
low_threshold = 30
critical_threshold = 15
id = "water"
display_name = "Water"
category = "supply"
tags = Array[String](["essential"])
```

- [ ] **Step 4: Create lee_shore.tres**

Write `game/content/zone_types/lee_shore.tres`:
```
[gd_resource type="Resource" script_class="ZoneTypeDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ZoneTypeDef.gd" id="1_leesh"]

[resource]
script = ExtResource("1_leesh")
consumption_modifier = 1.0
ship_wear_modifier = 1.8
burden_delta_per_tick = 1
incident_weight_modifier = 1.4
eligible_incident_tags = Array[String](["storm", "navigation", "crisis"])
id = "lee_shore"
display_name = "Lee Shore"
category = "hazard"
tags = Array[String](["hazard", "coastal"])
```

- [ ] **Step 5: Create unknown_zone.tres**

Write `game/content/zone_types/unknown_zone.tres`:
```
[gd_resource type="Resource" script_class="ZoneTypeDef" format=3]

[ext_resource type="Script" path="res://src/content/resources/ZoneTypeDef.gd" id="1_unkzn"]

[resource]
script = ExtResource("1_unkzn")
consumption_modifier = 1.1
ship_wear_modifier = 1.3
burden_delta_per_tick = 2
incident_weight_modifier = 2.0
eligible_incident_tags = Array[String]([])
suppressed_incident_tags = Array[String]([])
id = "unknown_zone"
display_name = "Unknown Waters"
category = "unknown"
tags = Array[String](["unknown", "dangerous"])
```

- [ ] **Step 6: Register and run tests**

```
godot --headless --path game --import
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 7: Verify Stage 1 and Stage 2 tests still pass**

```
godot --headless --path game res://test/ContentFrameworkTest.tscn
godot --headless --path game res://test/ExpeditionStateTest.tscn
```
Expected: both `ALL PASS`

- [ ] **Step 8: Commit**

```bash
git add game/content/supplies/water.tres game/content/zone_types/lee_shore.tres game/content/zone_types/unknown_zone.tres game/test/RouteMapTest.gd
git commit -m "feat(stage-3): add water supply and lee_shore/unknown_zone content"
```

---

### Task 4: ExpeditionState additions

**Files:**
- Modify: `game/src/expedition/ExpeditionState.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add new-field tests to RouteMapTest.gd**

In `_ready()`, add after `_test_zone_types()`:
```gdscript
	_test_expedition_state_additions()
```

Add this function:
```gdscript
# --- ExpeditionState additions ---

func _test_expedition_state_additions() -> void:
	print("-- ExpeditionState additions --")

	var state = _make_state()
	check(state.travel_fatigue == 0, "travel_fatigue default 0")
	check(state.sickness_risk == 0, "sickness_risk default 0")
	check(state.pending_incident_id == "", "pending_incident_id default empty")

	# Clamping
	state.travel_fatigue = 200
	state.travel_fatigue = clampi(state.travel_fatigue, 0, 100)
	check(state.travel_fatigue == 100, "travel_fatigue clamped to 100")

	state.sickness_risk = -5
	state.sickness_risk = clampi(state.sickness_risk, 0, 100)
	check(state.sickness_risk == 0, "sickness_risk clamped to 0")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: failures on travel_fatigue, sickness_risk, pending_incident_id not found.

- [ ] **Step 3: Add fields to ExpeditionState.gd**

In `game/src/expedition/ExpeditionState.gd`, add three fields after the existing `tick_count` line (line 29):
```gdscript
var travel_fatigue: int = 0      # 0–100. Accumulates each travel tick. Feeds incident conditions (Stage 5).
var sickness_risk: int = 0       # 0–100. Rises when food or water critically low. Feeds incident conditions (Stage 5).
var pending_incident_id: String = ""  # Set by TravelSimulator when a tick-band incident becomes eligible.
```

- [ ] **Step 4: Run tests**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Verify Stage 2 tests still pass**

```
godot --headless --path game res://test/ExpeditionStateTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 6: Commit**

```bash
git add game/src/expedition/ExpeditionState.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): add travel_fatigue, sickness_risk, pending_incident_id to ExpeditionState"
```

---

### Task 5: TravelSimulator — food and water consumption

**Files:**
- Create: `game/src/expedition/TravelSimulator.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add consumption tests to RouteMapTest.gd**

In `_ready()`, add after `_test_expedition_state_additions()`:
```gdscript
	_test_travel_simulator_food_water()
```

Add this function:
```gdscript
# --- TravelSimulator: food/water consumption ---

func _test_travel_simulator_food_water() -> void:
	print("-- TravelSimulator food/water consumption --")

	var state = _make_state()
	var log = _make_log()
	var zone = _make_zone(1.0)  # consumption_modifier = 1.0

	var food_before := state.get_supply("food")   # 200
	var water_before := state.get_supply("water")  # 150

	TravelSimulator.process_tick(state, zone, log)

	# food: daily_consumption=5, modifier=1.0 → -ceil(5*1.0)=-5
	check(state.get_supply("food") == food_before - 5, "food decreases by 5 with 1.0 modifier")
	# water: daily_consumption=3, modifier=1.0 → -ceil(3*1.0)=-3
	check(state.get_supply("water") == water_before - 3, "water decreases by 3 with 1.0 modifier")

	# Test with consumption_modifier = 1.2 (open_ocean style)
	var state2 = _make_state()
	var log2 = _make_log()
	var zone2 = _make_zone(1.2)  # open_ocean

	var food2_before := state2.get_supply("food")
	var water2_before := state2.get_supply("water")
	TravelSimulator.process_tick(state2, zone2, log2)

	# food: ceil(5*1.2) = ceil(6.0) = 6
	check(state2.get_supply("food") == food2_before - 6, "food decreases by 6 with 1.2 modifier")
	# water: ceil(3*1.2) = ceil(3.6) = 4
	check(state2.get_supply("water") == water2_before - 4, "water decreases by 4 with 1.2 modifier")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `Identifier "TravelSimulator" not found`

- [ ] **Step 3: Create TravelSimulator.gd with food/water steps**

Write `game/src/expedition/TravelSimulator.gd`:
```gdscript
# TravelSimulator.gd
# Stateless tick processor for expedition travel.
# Applies food/water consumption, ship wear, zone burden, fatigue,
# sickness risk, rum rules, and incident trigger checks each day.
#
# Spec: docs/superpowers/specs/2026-04-13-stage-3-route-map-travel-ticks-design.md
class_name TravelSimulator


static func process_tick(state: ExpeditionState, zone: ZoneTypeDef, log: SimulationLog) -> void:
	# Step 1: Food consumption
	var food_def = ContentRegistry.get_by_id("supplies", "food") as SupplyDef
	if food_def != null:
		var food_before := state.get_supply(food_def.id)
		var food_effect = EffectDef.new()
		food_effect.type = "supply_change"
		food_effect.delta = -ceili(food_def.daily_consumption * zone.consumption_modifier)
		food_effect.target_id = food_def.id
		EffectProcessor.apply(state, food_effect, log)
		if food_before > 0 and state.get_supply(food_def.id) == 0:
			var b = EffectDef.new()
			b.type = "burden_change"
			b.delta = 6
			EffectProcessor.apply(state, b, log)
			var f = EffectDef.new()
			f.type = "set_memory_flag"
			f.flag_key = "food_exhausted"
			EffectProcessor.apply(state, f, log)

	# Step 2: Water consumption
	var water_def = ContentRegistry.get_by_id("supplies", "water") as SupplyDef
	if water_def != null:
		var water_before := state.get_supply(water_def.id)
		var water_effect = EffectDef.new()
		water_effect.type = "supply_change"
		water_effect.delta = -ceili(water_def.daily_consumption * zone.consumption_modifier)
		water_effect.target_id = water_def.id
		EffectProcessor.apply(state, water_effect, log)
		if water_before > 0 and state.get_supply(water_def.id) == 0:
			var b = EffectDef.new()
			b.type = "burden_change"
			b.delta = 8
			EffectProcessor.apply(state, b, log)
			var f = EffectDef.new()
			f.type = "set_memory_flag"
			f.flag_key = "water_exhausted"
			EffectProcessor.apply(state, f, log)

	# Steps 3–8 added in Tasks 6–8
```

- [ ] **Step 4: Register and run tests**

```
godot --headless --path game --import
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): add TravelSimulator with food/water consumption"
```

---

### Task 6: TravelSimulator — ship wear, burden delta, travel fatigue

**Files:**
- Modify: `game/src/expedition/TravelSimulator.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add tests to RouteMapTest.gd**

In `_ready()`, add after `_test_travel_simulator_food_water()`:
```gdscript
	_test_travel_simulator_ship_wear()
	_test_travel_simulator_burden_fatigue()
```

Add these functions:
```gdscript
# --- TravelSimulator: ship wear ---

func _test_travel_simulator_ship_wear() -> void:
	print("-- TravelSimulator ship wear --")

	# wear_modifier=1.0 → floor(-1*1.0)=-1
	var state = _make_state()
	var log = _make_log()
	TravelSimulator.process_tick(state, _make_zone(1.0, 1.0), log)
	check(state.ship_condition == 99, "ship condition -1 with 1.0 wear modifier")

	# wear_modifier=1.8 → floor(-1*1.8)=floor(-1.8)=-2
	var state2 = _make_state()
	var log2 = _make_log()
	TravelSimulator.process_tick(state2, _make_zone(1.0, 1.8), log2)
	check(state2.ship_condition == 98, "ship condition -2 with 1.8 wear modifier")

	# wear_modifier=0.5 → floor(-0.5)=-1 (minimum -1 applies)
	var state3 = _make_state()
	var log3 = _make_log()
	TravelSimulator.process_tick(state3, _make_zone(1.0, 0.5), log3)
	check(state3.ship_condition == 99, "ship condition -1 with 0.5 wear modifier (minimum)")

	# wear_modifier=0.0 → floor(0)=0, but minimum -1 applies
	var state4 = _make_state()
	var log4 = _make_log()
	TravelSimulator.process_tick(state4, _make_zone(1.0, 0.0), log4)
	check(state4.ship_condition == 99, "ship condition -1 with 0.0 wear modifier (minimum enforced)")


# --- TravelSimulator: burden delta + travel fatigue ---

func _test_travel_simulator_burden_fatigue() -> void:
	print("-- TravelSimulator burden delta + fatigue --")

	# burden_delta_per_tick=2 → burden increases by 2
	var state = _make_state()
	var log = _make_log()
	var burden_before := state.burden  # 20
	TravelSimulator.process_tick(state, _make_zone(1.0, 1.0, 2), log)
	check(state.burden == burden_before + 2, "burden increases by zone burden_delta_per_tick")

	# burden_delta_per_tick=0 → burden unchanged by zone
	var state2 = _make_state()
	var log2 = _make_log()
	var burden2_before := state2.burden
	TravelSimulator.process_tick(state2, _make_zone(1.0, 1.0, 0), log2)
	check(state2.burden == burden2_before, "burden unchanged when burden_delta_per_tick is 0")

	# travel_fatigue increments each tick, clamped to 100
	var state3 = _make_state()
	var log3 = _make_log()
	check(state3.travel_fatigue == 0, "fatigue starts at 0")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 1, "fatigue increments to 1 after first tick")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 2, "fatigue increments to 2 after second tick")

	# Fatigue clamped at 100
	state3.travel_fatigue = 99
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 100, "fatigue reaches 100")
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.travel_fatigue == 100, "fatigue stays at 100 (clamped)")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: failures on ship_condition and travel_fatigue (steps 3–5 not yet implemented).

- [ ] **Step 3: Extend TravelSimulator.gd — add steps 3–5**

Replace the `# Steps 3–8 added in Tasks 6–8` comment in `game/src/expedition/TravelSimulator.gd` with:
```gdscript
	# Step 3: Ship wear
	var wear_delta := mini(floori(-1.0 * zone.ship_wear_modifier), -1)
	var wear_effect = EffectDef.new()
	wear_effect.type = "ship_condition_change"
	wear_effect.delta = wear_delta
	EffectProcessor.apply(state, wear_effect, log)

	# Step 4: Zone Burden delta
	if zone.burden_delta_per_tick != 0:
		var zone_burden = EffectDef.new()
		zone_burden.type = "burden_change"
		zone_burden.delta = zone.burden_delta_per_tick
		EffectProcessor.apply(state, zone_burden, log)

	# Step 5: Travel fatigue
	state.travel_fatigue = clampi(state.travel_fatigue + 1, 0, 100)
	log.log_event(state.tick_count, "TravelSimulator",
		"Travel fatigue: %d" % state.travel_fatigue,
		{"travel_fatigue": state.travel_fatigue})

	# Steps 6–8 added in Tasks 7–8
```

- [ ] **Step 4: Run tests**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): TravelSimulator ship wear, burden delta, travel fatigue"
```

---

### Task 7: TravelSimulator — sickness risk and supply exhaustion

**Files:**
- Modify: `game/src/expedition/TravelSimulator.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add sickness risk and exhaustion tests to RouteMapTest.gd**

In `_ready()`, add after `_test_travel_simulator_burden_fatigue()`:
```gdscript
	_test_travel_simulator_sickness_risk()
	_test_travel_simulator_exhaustion()
```

Add these functions:
```gdscript
# --- TravelSimulator: sickness risk ---

func _test_travel_simulator_sickness_risk() -> void:
	print("-- TravelSimulator sickness risk --")

	# Supplies above critical → sickness_risk decays (0 stays 0)
	var state = _make_state()  # food=200 (>15 critical), water=150 (>15 critical)
	var log = _make_log()
	check(state.sickness_risk == 0, "sickness_risk starts 0")
	TravelSimulator.process_tick(state, _make_zone(), log)
	check(state.sickness_risk == 0, "sickness_risk stays 0 when supplies healthy")

	# Set sickness_risk to 5, decay by 1 when supplies healthy
	state.sickness_risk = 5
	TravelSimulator.process_tick(state, _make_zone(), log)
	check(state.sickness_risk == 4, "sickness_risk decays by 1 when supplies healthy")

	# Set food below critical_threshold (15) → sickness rises
	var state2 = _make_state()
	var log2 = _make_log()
	state2.set_supply("food", 5)  # below critical_threshold=15
	TravelSimulator.process_tick(state2, _make_zone(), log2)
	check(state2.sickness_risk == 3, "sickness_risk rises by 3 when food below critical")

	# Set water below critical_threshold (15) → sickness rises
	var state3 = _make_state()
	var log3 = _make_log()
	state3.set_supply("water", 5)  # below critical_threshold=15
	TravelSimulator.process_tick(state3, _make_zone(), log3)
	check(state3.sickness_risk == 3, "sickness_risk rises by 3 when water below critical")

	# Sickness risk clamped at 100
	var state4 = _make_state()
	var log4 = _make_log()
	state4.sickness_risk = 99
	state4.set_supply("food", 5)
	TravelSimulator.process_tick(state4, _make_zone(), log4)
	check(state4.sickness_risk == 100, "sickness_risk clamped to 100")


# --- TravelSimulator: supply exhaustion ---

func _test_travel_simulator_exhaustion() -> void:
	print("-- TravelSimulator supply exhaustion --")

	# Food hits 0 → Burden +6, memory flag food_exhausted
	var state = _make_state()
	var log = _make_log()
	state.set_supply("food", 1)  # ceil(3 * 1.0) = 3 consumed, so 1 → clamped to 0
	var burden_before := state.burden
	TravelSimulator.process_tick(state, _make_zone(1.0), log)
	check(state.get_supply("food") == 0, "food hits 0")
	check(state.burden == burden_before + 6, "food exhaustion adds Burden +6")
	check(state.has_memory_flag("food_exhausted"), "food_exhausted memory flag set")

	# Food already at 0 before tick → no extra exhaustion spike
	var state2 = _make_state()
	var log2 = _make_log()
	state2.set_supply("food", 0)
	var burden2_before := state2.burden
	TravelSimulator.process_tick(state2, _make_zone(1.0), log2)
	check(not state2.has_memory_flag("food_exhausted"), "no exhaustion flag when food was already 0")
	check(state2.burden == burden2_before, "no Burden spike when food was already 0")

	# Water hits 0 → Burden +8, memory flag water_exhausted
	var state3 = _make_state()
	var log3 = _make_log()
	state3.set_supply("water", 1)  # ceil(3 * 1.0) = 3 consumed, 1 → 0
	var burden3_before := state3.burden
	TravelSimulator.process_tick(state3, _make_zone(1.0), log3)
	check(state3.get_supply("water") == 0, "water hits 0")
	check(state3.burden == burden3_before + 8, "water exhaustion adds Burden +8")
	check(state3.has_memory_flag("water_exhausted"), "water_exhausted memory flag set")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: failures on sickness_risk not changing.

- [ ] **Step 3: Extend TravelSimulator.gd — add step 6**

Replace `# Steps 6–8 added in Tasks 7–8` with:
```gdscript
	# Step 6: Sickness risk
	var food_amount := state.get_supply("food")
	var water_amount := state.get_supply("water")
	var food_critical := food_def.critical_threshold if food_def != null else 0
	var water_critical := water_def.critical_threshold if water_def != null else 0
	if food_amount < food_critical or water_amount < water_critical:
		state.sickness_risk = clampi(state.sickness_risk + 3, 0, 100)
	else:
		state.sickness_risk = clampi(state.sickness_risk - 1, 0, 100)
	log.log_event(state.tick_count, "TravelSimulator",
		"Sickness risk: %d" % state.sickness_risk,
		{"sickness_risk": state.sickness_risk})

	# Steps 7–8 added in Task 8
```

- [ ] **Step 4: Run tests**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): TravelSimulator sickness risk and supply exhaustion"
```

---

### Task 8: TravelSimulator — rum tick and incident trigger

**Files:**
- Modify: `game/src/expedition/TravelSimulator.gd`
- Modify: `game/test/RouteMapTest.gd`

- [ ] **Step 1: Add rum + incident tests to RouteMapTest.gd**

In `_ready()`, add after `_test_travel_simulator_exhaustion()`:
```gdscript
	_test_travel_simulator_incident_trigger()
```

Add this function:
```gdscript
# --- TravelSimulator: incident trigger ---

func _test_travel_simulator_incident_trigger() -> void:
	print("-- TravelSimulator incident trigger --")

	# No incident triggers when conditions not met (fresh default state)
	var state = _make_state()
	var log = _make_log()
	TravelSimulator.process_tick(state, _make_zone(), log)
	check(state.pending_incident_id == "", "no incident triggered on clean state")

	# drunk_purser_store_error requires has_crew_trait "rum_aboard"
	# Add trait and verify incident triggers
	var state2 = _make_state()
	var log2 = _make_log()
	state2.add_crew_trait("rum_aboard")
	TravelSimulator.process_tick(state2, _make_zone(), log2)
	check(state2.pending_incident_id == "drunk_purser_store_error",
		"drunk_purser_store_error triggered when rum_aboard trait present")

	# Second tick does NOT overwrite pending_incident_id
	TravelSimulator.process_tick(state2, _make_zone(), log2)
	check(state2.pending_incident_id == "drunk_purser_store_error",
		"pending_incident_id not overwritten on second tick")

	# Clear pending_incident_id and verify trigger works again
	state2.pending_incident_id = ""
	TravelSimulator.process_tick(state2, _make_zone(), log2)
	check(state2.pending_incident_id == "drunk_purser_store_error",
		"incident triggers again after pending_incident_id cleared")
```

- [ ] **Step 2: Run tests — expect FAIL**

```
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: failure on incident trigger (steps 7–8 not yet added).

- [ ] **Step 3: Complete TravelSimulator.gd — add steps 7–8**

Replace `# Steps 7–8 added in Task 8` with:
```gdscript
	# Step 7: Rum tick
	RumRules.update_on_tick(state, log)

	# Step 8: Incident trigger check
	if state.pending_incident_id.is_empty():
		var incidents := ContentRegistry.get_all("incidents")
		for item: ContentBase in incidents:
			var incident = item as IncidentDef
			if incident == null or incident.trigger_band != "tick":
				continue
			if ConditionEvaluator.all_met(state, incident.required_conditions, log):
				state.pending_incident_id = incident.id
				log.log_event(state.tick_count, "TravelSimulator",
					"Incident triggered: %s" % incident.id,
					{"incident_id": incident.id})
				break
```

- [ ] **Step 4: Run all tests**

```
godot --headless --path game res://test/RouteMapTest.tscn
godot --headless --path game res://test/ExpeditionStateTest.tscn
godot --headless --path game res://test/ContentFrameworkTest.tscn
```
Expected: all `ALL PASS`

- [ ] **Step 5: Commit**

```bash
git add game/src/expedition/TravelSimulator.gd game/test/RouteMapTest.gd
git commit -m "feat(stage-3): complete TravelSimulator with rum tick and incident trigger"
```

---

### Task 9: Debug scene — sidebar and route map rendering

**Files:**
- Modify: `game/test/ContentDebugScene.tscn`
- Modify: `game/test/ContentDebugScene.gd`

- [ ] **Step 1: Add Route Map sidebar nodes to ContentDebugScene.tscn**

In `game/test/ContentDebugScene.tscn`, add these nodes after the `ShowLog` button (before the `OutputContainer` node):
```
[node name="RouteSeparator" type="HSeparator" parent="Sidebar"]
layout_mode = 2

[node name="RouteLabel" type="Label" parent="Sidebar"]
layout_mode = 2
text = "Route Map"

[node name="ShowRoute" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Show Route"

[node name="AdvanceDay" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Advance Day"

[node name="ForceIncident" type="Button" parent="Sidebar"]
layout_mode = 2
size_flags_horizontal = 3
text = "Force Incident"
```

- [ ] **Step 2: Add route map state variables and wire up connections in ContentDebugScene.gd**

At the top of `game/test/ContentDebugScene.gd`, add after `var _condition_index: int = 0`:
```gdscript
var _route_map: RouteMap = null
```

In `_ready()`, add after the Stage 2 button connections (after `$Sidebar/ShowLog.pressed.connect(_on_show_log)`):
```gdscript
	# Stage 3 — route map controls
	$Sidebar/ShowRoute.pressed.connect(_on_show_route)
	$Sidebar/AdvanceDay.pressed.connect(_on_advance_day)
	$Sidebar/ForceIncident.pressed.connect(_on_force_incident)
	_output.meta_clicked.connect(_on_route_meta_clicked)
```

- [ ] **Step 3: Implement route map rendering in ContentDebugScene.gd**

Add these functions to `game/test/ContentDebugScene.gd`:

```gdscript
# --- Stage 3: Route Map ---

func _on_show_route() -> void:
	if _route_map == null:
		_route_map = RouteMap.create_test_map()
	if _state == null:
		_state = ExpeditionState.create_default()
		_log = SimulationLog.new()
	_clear_output()
	_render_route_map()


func _on_advance_day() -> void:
	if _route_map == null or _state == null:
		_clear_output()
		_output.append_text("[color=yellow]Press 'Show Route' first.[/color]\n")
		return
	if not _route_map.is_travelling():
		_clear_output()
		_output.append_text("[color=yellow]Not travelling — select a node from the route map first.[/color]\n")
		_render_route_map()
		return
	var zone = _route_map.get_active_zone()
	if zone == null:
		_clear_output()
		_output.append_text("[color=red]Error: active zone not found.[/color]\n")
		return
	_state.tick_count += 1
	TravelSimulator.process_tick(_state, zone, _log)
	_route_map.advance_tick()
	_clear_output()
	_render_route_map()


func _on_route_meta_clicked(meta: String) -> void:
	if not meta.begins_with("take_"):
		return
	var node_id := meta.substr(5)
	var stage := _route_map.get_current_stage()
	for node: RouteNode in stage:
		if node.id == node_id:
			_route_map.select_node(node)
			_clear_output()
			_render_route_map()
			return


func _render_route_map() -> void:
	# Category colour map
	var cat_colors := {
		"crisis":    "#ff9966",
		"landfall":  "#88ff88",
		"social":    "#ffdd66",
		"omen":      "#cc88ff",
		"boon":      "#aaffaa",
		"admiralty": "#ffccaa",
		"unknown":   "#88ccff",
	}

	# Header block
	var zone = _route_map.get_active_zone()
	var zone_name := zone.display_name if zone != null else "(at choice)"
	var wear_str := "%.1f× wear" % zone.ship_wear_modifier if zone != null else ""
	_output.append_text("[b]SHIP'S LOG[/b]\nDay %d\n\n" % _state.tick_count)
	_output.append_text("ZONE              STATE\n")
	_output.append_text("%-18s[color=#ff9966]Burden[/color] %d   [color=#88ccff]Command[/color] %d\n" % [
		zone_name, _state.burden, _state.command])
	if wear_str != "":
		_output.append_text("%-18s[color=#88ff88]Food[/color] %d     [color=#88ccff]Water[/color] %d\n" % [
			wear_str, _state.get_supply("food"), _state.get_supply("water")])
	else:
		_output.append_text("%-18s[color=#88ff88]Food[/color] %d     [color=#88ccff]Water[/color] %d\n" % [
			"", _state.get_supply("food"), _state.get_supply("water")])
	_output.append_text("\n")

	if _route_map.is_complete():
		_output.append_text("[color=#ffaaff][b]ARRIVED[/b][/color]\n\nThe expedition is complete.\n")
		return

	# Travelling progress indicator
	if _route_map.is_travelling():
		var an: RouteNode = _route_map.active_node
		var cat_color: String = cat_colors.get(an.category, "#ffffff")
		var progress := an.tick_distance - _route_map.ticks_remaining
		var bar := "█".repeat(progress) + "░".repeat(_route_map.ticks_remaining)
		var arrival_str := "arrival tomorrow" if _route_map.ticks_remaining == 1 else "%d days remaining" % _route_map.ticks_remaining
		_output.append_text("Travelling to [color=%s][b]%s[/b][/color] (%s)\n" % [
			cat_color, an.category.to_upper(), zone_name])
		_output.append_text("Day %d of %d  %s  %s\n\n" % [
			progress + 1, an.tick_distance, bar, arrival_str])

	# Route diagram
	_render_route_diagram(cat_colors)


func _render_route_diagram(cat_colors: Dictionary) -> void:
	var current_idx := _route_map.current_stage_index

	for s_idx in range(_route_map.stages.size()):
		var stage: Array = _route_map.stages[s_idx]
		var is_current := s_idx == current_idx
		var is_past := s_idx < current_idx

		if is_past:
			# Show completed node from selected_path
			var done_node: RouteNode = _route_map.selected_path[s_idx]
			var col: String = cat_colors.get(done_node.category, "#555555")
			_output.append_text("[color=#333333]  ✓ [b]%s[/b] (%d days)[/color]\n" % [
				done_node.category.to_upper(), done_node.tick_distance])
		elif is_current and not _route_map.is_travelling():
			# Choice point — full brightness
			_output.append_text("[b]CHOOSE:[/b]\n")
			for node: RouteNode in stage:
				var col: String = cat_colors.get(node.category, "#ffffff")
				var bar := "█".repeat(node.tick_distance)
				_output.append_text("  [color=%s][b]%s[/b][/color]  %s  %d days\n" % [
					col, node.category.to_upper(), bar, node.tick_distance])
				if not node.hints.is_empty():
					_output.append_text("    [color=#888888]%s[/color]\n" % node.hints[0])
		else:
			# Future stage — faded
			_output.append_text("[color=#333333]  Stage %d: " % (s_idx + 1))
			var labels: Array[String] = []
			for node: RouteNode in stage:
				labels.append("%s(%d)" % [node.category.to_upper(), node.tick_distance])
			_output.append_text(", ".join(labels) + "[/color]\n")

		# Arrow spacer between stages
		if s_idx < _route_map.stages.size() - 1:
			var next_stage: Array = _route_map.stages[s_idx + 1]
			var min_dist := 9999
			for node: RouteNode in next_stage:
				if node.tick_distance < min_dist:
					min_dist = node.tick_distance
			var arrows := clampi(min_dist / 2, 1, 4)
			var arrow_color := "#555555" if s_idx >= current_idx else "#222222"
			for _a in range(arrows):
				_output.append_text("[color=%s]  ↓[/color]\n" % arrow_color)

	# Arrival
	_output.append_text("[color=#1a1a1a]  ARRIVAL[/color]\n")

	# Selection buttons (meta links) if at a choice point
	if not _route_map.is_travelling() and not _route_map.is_complete():
		_output.append_text("\n")
		var stage: Array = _route_map.get_current_stage()
		for node: RouteNode in stage:
			_output.append_text('[url="take_%s"][color=#88aaff][ Take %s — %d days ][/color][/url]   ' % [
				node.id, node.category.to_upper(), node.tick_distance])
		_output.append_text("\n")
```

- [ ] **Step 4: Manual test — run the debug scene**

```
godot --path game res://test/ContentDebugScene.tscn
```

Verify:
1. "Show Route" renders the ship's log header + route diagram
2. Choice stage shows nodes with colour-coded categories and distance bars
3. "Take X" links (in brackets) are clickable and select a node
4. After selecting a node, the display switches to travelling mode
5. "Advance Day" decrements ticks_remaining and updates the display
6. After all days pass, the stage advances and next choice is shown
7. Existing Stage 1 and Stage 2 buttons still work normally

- [ ] **Step 5: Commit**

```bash
git add game/test/ContentDebugScene.tscn game/test/ContentDebugScene.gd
git commit -m "feat(stage-3): add route map rendering to debug scene"
```

---

### Task 10: Debug scene — Force Incident + final validation

**Files:**
- Modify: `game/test/ContentDebugScene.gd`

- [ ] **Step 1: Implement _on_force_incident in ContentDebugScene.gd**

Add this function to `game/test/ContentDebugScene.gd`:
```gdscript
func _on_force_incident() -> void:
	if _state == null:
		_clear_output()
		_output.append_text("[color=yellow]No expedition active. Press 'Show Route' first.[/color]\n")
		return

	_clear_output()

	# Case 1: pending_incident_id is set — apply first choice of that incident
	if not _state.pending_incident_id.is_empty():
		var incident = ContentRegistry.get_by_id("incidents", _state.pending_incident_id) as IncidentDef
		if incident != null and not incident.choices.is_empty():
			var choice: IncidentChoiceDef = incident.choices[0]
			EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
			for flag: String in choice.memory_flags_set:
				_state.add_memory_flag(flag)
			_log.log_event(_state.tick_count, "ForceIncident",
				"[%s] %s" % [incident.display_name, choice.log_text],
				{"incident_id": incident.id})
			_state.pending_incident_id = ""
			_output.append_text("[b]Incident resolved: %s[/b]\n[color=#88ccff]%s[/color]\n\n" % [
				incident.display_name, choice.log_text])
			_show_state_summary()
			return

	# Case 2: scan for any eligible tick-band incident
	var triggered := false
	var incidents := ContentRegistry.get_all("incidents")
	for item: ContentBase in incidents:
		var incident = item as IncidentDef
		if incident == null or incident.trigger_band != "tick":
			continue
		if ConditionEvaluator.all_met(_state, incident.required_conditions, _log):
			if not incident.choices.is_empty():
				var choice: IncidentChoiceDef = incident.choices[0]
				EffectProcessor.apply_effects(_state, choice.immediate_effects, _log)
				for flag: String in choice.memory_flags_set:
					_state.add_memory_flag(flag)
				_log.log_event(_state.tick_count, "ForceIncident",
					"[%s] %s" % [incident.display_name, choice.log_text],
					{"incident_id": incident.id})
				_output.append_text("[b]Force-triggered: %s[/b]\n[color=#88ccff]%s[/color]\n\n" % [
					incident.display_name, choice.log_text])
				triggered = true
				break

	# Case 3: fallback — hardcoded squall
	if not triggered:
		var b = EffectDef.new()
		b.type = "burden_change"
		b.delta = 5
		EffectProcessor.apply(_state, b, _log)
		var d = EffectDef.new()
		d.type = "add_damage_tag"
		d.tag = "storm_damage"
		EffectProcessor.apply(_state, d, _log)
		_log.log_event(_state.tick_count, "ForceIncident",
			"A squall strikes without warning.", {})
		_output.append_text("[b]Fallback incident:[/b]\n[color=#ff9966]A squall strikes without warning. (Burden +5, storm_damage)[/color]\n\n")

	_show_state_summary()
```

- [ ] **Step 2: Manual test — Force Incident**

```
godot --path game res://test/ContentDebugScene.tscn
```

Verify:
1. Start expedition, show route, advance a few days without setting up an incident — "Force Incident" applies the fallback squall (Burden +5, storm_damage tag)
2. In a new expedition, set `rum_aboard` crew trait by pressing "Apply Effect" until it cycles to one that adds a trait — or just verify the squall fallback works reliably
3. After `pending_incident_id` is set (visible in Show State), "Force Incident" applies the first choice and clears the id
4. "Show State" after Force Incident shows updated burden and memory flags

- [ ] **Step 3: Run all headless tests — final confirmation**

```
godot --headless --path game res://test/ContentFrameworkTest.tscn
godot --headless --path game res://test/ExpeditionStateTest.tscn
godot --headless --path game res://test/RouteMapTest.tscn
```
Expected: all three suites `ALL PASS`

- [ ] **Step 4: Commit**

```bash
git add game/test/ContentDebugScene.gd
git commit -m "feat(stage-3): Force Incident debug button — stage 3 complete"
```

---

## Self-Review Checklist (for the implementer, before marking stage complete)

- [ ] `RouteMapTest.tscn` runs headless with `ALL PASS`
- [ ] `ExpeditionStateTest.tscn` still passes (no regressions)
- [ ] `ContentFrameworkTest.tscn` still passes
- [ ] Debug scene: Show Route renders the diagram with colour-coded nodes
- [ ] Debug scene: Take X links select a node and switch to travelling mode
- [ ] Debug scene: Advance Day processes a tick and updates the display
- [ ] Debug scene: arriving at a node advances to the next stage's choice
- [ ] Debug scene: Force Incident shows fallback squall when no incident pending
- [ ] All 4 zone types appear in the test map (coastal, open_ocean, lee_shore, unknown_zone)
- [ ] All 7 node categories appear in the test map
