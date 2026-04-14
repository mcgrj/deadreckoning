# Debug UI Redesign
**Date:** 2026-04-14
**Scope:** RunScene, IncidentResolutionScene, ContentDebugScene

---

## Overview

The existing debug UI has four problems: no persistent stats panel, a text-based route map that's hard to read, RunScene is barely functional (plain Label dumps), and ContentDebugScene outputs unstructured text walls. This spec redesigns all three screens into a cohesive, scannable debug UI.

---

## Shared Component Architecture

Two reusable scenes are extracted and shared between RunScene and IncidentResolutionScene. ContentDebugScene is a separate dev tool and shares nothing.

### `StatsBar.tscn` / `StatsBar.gd`
Persistent top bar. Never rebuilt, only updated via `refresh(state: ExpeditionState)`.

**Left section — secondary stats (HBoxContainer):**
- Ship condition, Food, Water, Rum — each a small VBoxContainer with a value Label and a key Label (9px, uppercase, muted)

**Centre section — world clock:**
- Small SVG-style horizon arc rendered via `_draw()` on a custom Control node
- Sun position computed from `tick_count`: `day = tick / 2 + 1`, `period = "DAWN" if tick % 2 == 0 else "DUSK"`
- Sun colour: warm amber at dawn, orange-red at dusk
- Label below: "Day N · DAWN/DUSK"

**Right section — primary bars (HBoxContainer, margin-left: auto):**
- Burden bar: label + value + filled bar. Gradient left→right: dark orange → bright orange. Bad if high.
- Command bar: label + value + filled bar. Gradient: dark blue → bright blue. Bad if low.
- Each bar is a StyleBox-filled ColorRect sized by `value / 100.0 * max_width`

---

### `LogPanel.tscn` / `LogPanel.gd`
Left panel, fixed width ~270px. Append-only log feed. Never cleared mid-run.

**Layout:** VBoxContainer with a header row ("SHIP'S LOG · ● live") and a ScrollContainer containing a VBoxContainer of log entries.

**Log entry structure** (each is an HBoxContainer):
- Tick label (28px, muted)
- VBoxContainer: source label (9px, uppercase, colour-coded) + message label (11px, autowrap)
- Inline effect tags rendered as small Labels with StyleBox backgrounds appended to the message container

**Entry colour coding:**
| Type | Source colour | Message colour |
|------|--------------|----------------|
| `incident` | `#804020` | `#ffaa66` |
| `resolved` | `#3a6040` | `#66aa66` |
| `warn` | `#806040` | `#cc9944` |
| `event` | `#4a6a8a` | `#7a9aaa` |
| `effect` | `#2a3a4a` | `#4a7080` |

**Inline effect tags:** small Labels with coloured StyleBox. Colour by type: burden = orange, command = blue, supply = green, damage = amber.

**Auto-scroll:** on append, scroll to bottom unless user has manually scrolled up.

---

## RunScene

**File:** `game/src/ui/RunScene.tscn` / `RunScene.gd`

### Layout
```
┌──────────────────────────────────────────────────────┐
│  StatsBar (shared)                                    │
├────────────────────┬─────────────────────────────────┤
│  LogPanel (shared) │  Right slot                     │
│                    │  (RouteMapNode or               │
│                    │   IncidentResolutionScene)       │
└────────────────────┴─────────────────────────────────┘
```

Shell is an HBoxContainer inside a VBoxContainer. The right slot is a plain `Control` container node — `RouteMapNode` is added as a child at `_ready`, replaced by `IncidentResolutionScene` when an incident fires, restored on resolution.

### Right slot header strip
A thin HBoxContainer above the right slot content (inside the slot container):
- Breadcrumb: "Route · Stage N of M · In transit — N days remaining" or "Route · Choose your heading"
- Right-aligned: active damage tags shown as small coloured Labels

---

### `RouteMapNode.tscn` / `RouteMapNode.gd`

The vertical Slay the Spire-style node map. Renders entirely via a single `_draw()` call — no child nodes for the map content itself.

#### Coordinate system
Fixed logical canvas: **300 × 520 units**, centred within the available space using `_draw()` with an offset. Nodes and paths are positioned in this space. On resize, the canvas is re-centred.

**Stage row Y positions (computed):**
The canvas height is fixed at 520 units. Depart is pinned at Y=490, Arrival at Y=80. Intermediate stages are distributed evenly between them:

```gdscript
func _stage_y(stage_index: int, total_stages: int) -> float:
    # stage_index 0 = first travel stage, total_stages excludes depart/arrival
    var usable := 490.0 - 80.0  # 410 units between depart and arrival
    var step := usable / (total_stages + 1)
    return 490.0 - step * (stage_index + 1)
```

Node X positions within a stage are spread evenly across the canvas width (e.g. 2 nodes: 95, 205; 3 nodes: 65, 150, 235). With up to 3 nodes per stage this fits comfortably in the 300-unit canvas.

#### Drawing order
1. Bezier path lines (`draw_line` approximated by cubic bezier segments)
2. Tick dots on paths
3. Boat marker at current position
4. Node circles
5. Node icons (emoji via `draw_string` with emoji font) and labels
6. Stage labels (right edge)

#### Bezier path lines
Each path `M P0 C P1 P2 P3` is drawn as N short line segments (N=20 for smooth curves) via the cubic bezier formula. Colour and opacity vary by path state:

| State | Colour | Opacity | Dash |
|-------|--------|---------|------|
| Taken (past) | category colour | 0.4 | solid |
| Reachable (next choices) | category colour | 0.25 | solid |
| Locked (other branch) | white | 0.06 | dashed 3/5 |
| Future (distant stages) | white | 0.04 | dashed |

#### Tick dots on paths
For each path, place N dots equidistantly along the bezier where N = `tick_distance` of the destination node. Dots are positioned by sampling the bezier at `t = (i + 0.5) / tick_distance` for i in 0..N-1 (centred between nodes, not at endpoints).

| Dot state | Radius | Fill | Opacity |
|-----------|--------|------|---------|
| Completed day (past) | 4.5 | category colour | 0.9 |
| Current day (boat position) | — | boat icon instead | — |
| Future day on active leg | 4.5 | none (stroke only) | 0.5 |
| Reachable next path | 4.0 | category colour | 0.4 |
| Locked/future path | 2.5 | category colour | 0.08–0.13 |

#### Boat marker
Rendered at the bezier position for the current day on the active leg: `t = (current_day - 0.5) / tick_distance`. Uses a ship emoji (⛵) via `draw_string`. A dashed circle ring (radius 9, opacity 0.4, `#aad4ff`) is drawn underneath.

#### Node circles
Each node is a filled circle (radius 26) with a coloured stroke. State-dependent rendering:

| State | Opacity | Stroke width | Animation |
|-------|---------|--------------|-----------|
| Visited | 0.22 | 2 | none |
| Current | 1.0 | 3 | glow pulse (CanvasItem modulate or shader) |
| Reachable | 1.0 | 2 | gentle breathe glow |
| Locked | 0.13 | 2 | none |

**Category colours:**
| Category | Background | Stroke |
|----------|-----------|--------|
| crisis | `#2a1200` | `#ff9966` |
| landfall | `#001800` | `#88ff88` |
| social | `#1a1400` | `#ffdd66` |
| omen | `#180a28` | `#cc88ff` |
| boon | `#001a05` | `#aaffaa` |
| admiralty | `#1a0f00` | `#ffccaa` |
| start | `#0a1a2a` | `#4a7aaa` |
| arrival | `#1a1a00` | `#ffffaa` |

Glow effects are achieved via a per-node `ShaderMaterial` with a simple drop-shadow shader, or via `PointLight2D` nodes positioned at reachable/current node locations.

#### Interaction
`_input_event` or `_gui_input` is not available on a raw `Control` using `_draw()`. Instead, override `_unhandled_input` and hit-test against node positions manually: if a click falls within radius 26 of a `reachable` node, call `_on_node_selected(node)`.

Hover state is tracked in `_process` via `get_global_mouse_position()` and used to set a `hovered_node` variable, which triggers `queue_redraw()`.

#### Public API
```gdscript
func setup(route: RouteMap, state: ExpeditionState, log: SimulationLog) -> void
func refresh() -> void  # called after each tick or state change
```

---

### RunScene shell behaviour

```gdscript
func _on_advance() -> void:
    # ... tick logic unchanged ...
    _stats_bar.refresh(_state)
    _log_panel.append_tick_entries(_log, _state.tick_count)
    _route_map.refresh()
    if _state.pending_incident_id != "":
        _show_incident()

func _show_incident() -> void:
    _route_map.hide()
    var scene := IncidentResolutionScene.instantiate()
    scene.setup(_state, _log)
    scene.resolved.connect(_on_incident_resolved)
    _right_slot.add_child(scene)

func _on_incident_resolved() -> void:
    for child in _right_slot.get_children():
        if child != _route_map_node:
            child.queue_free()
    _route_map_node.show()
    _stats_bar.refresh(_state)
    _log_panel.append_latest(_log)
```

---

## IncidentResolutionScene

**File:** `game/src/ui/IncidentResolutionScene.tscn` / `IncidentResolutionScene.gd`

Fills the right slot. Does not instantiate StatsBar or LogPanel — it relies on RunScene's shell.

### Layout
ScrollContainer containing a VBoxContainer:

1. **Header strip** (in right slot header, not inside this scene): incident category badge + "Day N · In transit"
2. **Incident title** — 18px, bold, category colour
3. **Flavour text** — 12px, italic, left-bordered with category colour, 16px margin-bottom
4. **"THE OFFICERS ADVISE" label** — 9px, uppercase, muted
5. **Officer proposal cards** (one per proposal from `OfficerCouncil.get_proposals`)
6. **Direct order card** (always last, slightly different background)

### Officer proposal card layout
HBoxContainer:
- Officer name + worldview subtitle (80px column)
- Choice text + effect tags + optional risk text (flex)
- `›` arrow (right-aligned, muted, brightens on hover)

**Proposal types:**
- `officer` — normal card with name, choice text, leadership tag, effects preview
- `silence` — dashed border, italic text, greyed, not clickable
- `direct_order` — darker background, no officer name shown (Captain / Direct Order)

### Signal
```gdscript
signal resolved
```
Emitted after a choice is selected and effects applied. RunScene listens and restores the route map.

---

## ContentDebugScene

**File:** `game/test/ContentDebugScene.tscn` / `ContentDebugScene.gd`

Standalone dev tool. Does not use StatsBar or LogPanel.

### Layout
```
┌─────────────┬──────────────────────────────────────┐
│  Sidebar    │  Tab bar                             │
│  (controls) ├──────────────────────────────────────┤
│             │  Tab content area                    │
└─────────────┴──────────────────────────────────────┘
```

HBoxContainer root. Left sidebar fixed ~150px. Right area is a VBoxContainer with a tab bar and content panel.

**Tab bar implementation:** a custom HBoxContainer of `Button` nodes (not Godot's built-in `TabContainer`). Each button sets its own `flat` style and a bottom-border highlight when active. The content panel below is a single `Control` whose children are swapped by `_activate_tab(name: String)` — all tab panes are pre-instantiated and shown/hidden, not rebuilt on each switch.

### Sidebar button groups
Buttons grouped by `Label` dividers:
- **EXPEDITION:** New Expedition, Show State, Tick, Show Log
- **EFFECTS:** Apply Effect, Check Condition
- **PROMISES:** Make Promise, Keep Promise, Break Promise
- **FLAGS:** Toggle Damage Tag, Set Memory Flag
- **ORDERS:** Toggle Rationing, Toggle Spirit Store
- **ROUTE:** Show Route, Advance Day, Force Incident
- **CONTENT:** Validate All

Each button calls `_activate_tab(tab_name)` and executes its action, then refreshes the active tab content.

### Tabs

**State tab** — 2×2 grid of styled panels:
- Core (Burden bar, Command bar, Ship, Tick)
- Supplies (key→value rows)
- Tags & Flags (damage tags, memory flags, standing orders, officers — each as a row of small coloured tag Labels)
- Rum State + Leadership tags

Active promise shown below the grid as a styled block with remaining ticks.

**Progression panel** — below the state grid, a separate styled block showing `ProgressionState` fields loaded from `SaveManager`:
- `admiralty_bias` — rendered as a row of small tag Labels (same style as standing orders), one per accumulated bias string
- `scandal_flags` — rendered as a row of tag Labels in amber (same style as damage tags)
- `last_run_difficulty_score` — single value row
- If both arrays are empty, show a muted "(no Admiralty record)" placeholder

This data is read-only in the debug scene — it reflects what `SaveManager` has persisted, not a live `ExpeditionState`.

**Route tab** — embeds the same `RouteMapNode` scene used in RunScene. Shows the current route state. "Show Route" button in sidebar initialises the route if not yet created.

**Log tab** — full-width log table with columns: Tick | Source | Message. All entries, oldest first (or reverse with a toggle). Wider source column than LogPanel since space is available.

**Content tabs (Incidents, Officers, Supplies, etc.)** — a table per family:
- Columns: ID | Display Name | Category | Tags
- Rows are all items from `ContentRegistry.get_all(family)`
- Clicking a row expands it inline to show all fields

**Validate tab** — runs `ContentRegistry.get_validation_errors()` on open, shows PASS (green) or FAIL (red) with error list. Badge on the tab shows error count (red if > 0).

### No shared state with RunScene
ContentDebugScene owns its own `ExpeditionState`, `RouteMap`, and `SimulationLog`. It does not interact with `SaveManager`.

---

## Implementation Notes

### Godot rendering approach for RouteMapNode
The bezier path rendering in `_draw()` requires approximating cubic beziers with polylines. A helper function:

```gdscript
func _draw_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
                  color: Color, width: float, segments: int = 20) -> void:
    var prev := p0
    for i in range(1, segments + 1):
        var t := float(i) / segments
        var q := (1-t)**3 * p0 + 3*(1-t)**2*t * p1 + 3*(1-t)*t**2 * p2 + t**3 * p3
        draw_line(prev, q, color, width)
        prev = q
```

### Glow animation
Use a `Timer` + `queue_redraw()` approach: a timer fires at ~30fps and increments a `_glow_phase` float (0..TAU). Node draw colour is modulated by `sin(_glow_phase)` to pulse intensity. Reachable nodes breathe at a slightly different frequency to the current node.

### LogPanel performance
Log entries are Label nodes. For long runs, limit the visible panel to the last 200 entries (older entries are kept in memory for the Log tab in ContentDebugScene but not rendered in the panel).

---

## Out of Scope
- Pixel-art theming / custom fonts (separate pass)
- Animated transitions between route map and incident overlay
- ContentDebugScene Stage 6B Admiralty views (covered in separate spec)
