# godot-directional-movement-2d
Cross-platform 2D directional movement input for Godot (keyboard, mouse, touch)

## Overview

`godot-directional-movement-2d` provides a small, dependency-free set of GDScript helpers for directional input and movement in 2D games. It exposes a single facade node `NilDevMovement2D` which aggregates input from keyboard, mouse (drag), and touch. The addon is lightweight and intended for Godot 4.2+ projects.

**Key features**
- Automatic input mode selection (`AUTO`, `KEYBOARD`, `MOUSE`, `TOUCH`).
- Choose which input methods participate in `AUTO` mode without changing AUTO priority.
- Optional cardinal speed mode for asymmetric 4-direction movement tuning.
- Drag-based mouse and touch input with deadzone / radius tuning.
- Simple integration: use `calculate_velocity()` for physics bodies or `calculate_movement(delta)` for direct position updates.

## Compatibility

- Tested with Godot 4.2+ (GDScript typed syntax used). If you use an older Godot version you may need to adapt the scripts.

## Installation

Copy the `addons/nildevgames_directional_movement_2d` folder into your project's `addons/` directory.

- If you enable the plugin in Project Settings -> Plugins, it seeds four default keyboard actions into Project Settings -> Input Map.
- If you use the scripts without enabling the plugin, missing configured keyboard actions are still created automatically at runtime.

## Quick Start

1. Add `NilDevMovement2D` to your player scene as a child node. The node script is located at `addons/nildevgames_directional_movement_2d/movement_2d.gd`.
2. In your player's `_physics_process(delta)`, use `calculate_velocity()` for `CharacterBody2D` movement or `calculate_movement(delta)` when you want per-frame displacement for a plain `Node2D`.

Example integration (character code):

```gdscript
extends CharacterBody2D

@onready var mover := $NilDevMovement2D

func _physics_process(delta: float) -> void:
	velocity = mover.calculate_velocity()
	move_and_slide()
```

For `Node2D` players or any manual position update, use the displacement-oriented helper instead:

```gdscript
extends Node2D

@onready var mover := $NilDevMovement2D

func _physics_process(delta: float) -> void:
	position += mover.calculate_movement(delta)
```

## InputMap (recommended)

The keyboard input handler uses four configurable actions. By default, the addon uses prefixed action names to avoid collisions and binds both WASD and arrow keys:

- `nildevgames_move_right`: D, Right
- `nildevgames_move_left`: A, Left
- `nildevgames_move_up`: W, Up
- `nildevgames_move_down`: S, Down

`NilDevKeyboardInput2D` exposes `move_right_action`, `move_left_action`, `move_up_action`, and `move_down_action` so you can override the action names per node. `NilDevMovement2D` mirrors the same settings with `keyboard_move_right_action`, `keyboard_move_left_action`, `keyboard_move_up_action`, and `keyboard_move_down_action` because it auto-creates its keyboard child for you.

If you want to add the default actions manually in Godot 4, use `physical_keycode` and add both bindings per direction:

```gdscript
if not InputMap.has_action("nildevgames_move_right"):
	InputMap.add_action("nildevgames_move_right")

	var wasd_event := InputEventKey.new()
	wasd_event.physical_keycode = Key.D
	InputMap.action_add_event("nildevgames_move_right", wasd_event)

	var arrow_event := InputEventKey.new()
	arrow_event.physical_keycode = Key.Right
	InputMap.action_add_event("nildevgames_move_right", arrow_event)
```

If you override the action names, the addon will auto-create those custom names at runtime when they are missing. Add custom names to Project Settings -> Input Map yourself if you want them to be visible and persisted in the editor.

## API Reference (summary)

Node: `NilDevMovement2D` (`addons/nildevgames_directional_movement_2d/movement_2d.gd`)

- Exports:
	- `input_mode` (enum `NilDevInputMode.Mode`) — `AUTO` by default.
	- `auto_enable_keyboard`, `auto_enable_mouse`, `auto_enable_touch` — choose which methods participate when `input_mode` is `AUTO`.
	- `speed_mode` (enum `NilDevSpeedMode.Mode`) — `UNIFORM` by default.
	- `speed` — float, default ~200.0 — movement speed multiplier used in `UNIFORM` mode. Assigning it while `speed_mode` is `CARDINAL` triggers `push_error()` and leaves the old value unchanged.
	- `cardinal_speed_right`, `cardinal_speed_left`, `cardinal_speed_up`, `cardinal_speed_down` — floats used in `CARDINAL` mode. Assigning any of them while `speed_mode` is `UNIFORM` triggers `push_error()` and leaves the old value unchanged.
	- Mouse/Touch tuning: `*_deadzone`, `*_max_radius`, `*_stop_drag_if_input_stopped`, `*_motion_timeout` (grouped per input type).
- Methods:
	- `get_input_vector() -> Vector2` — current input direction vector (normalized where appropriate).
	- `calculate_velocity() -> Vector2` — updates internal velocity and returns pixels-per-second velocity for physics-driven nodes such as `CharacterBody2D`.
	- `calculate_movement(delta: float) -> Vector2` — updates internal velocity and returns frame displacement, equivalent to `calculate_velocity() * delta` for the sampled input.
- Getters (useful):
	- `velocity` — current velocity Vector2.
	- `movement_type` — enum (`STOPPED`, `HORIZONTAL`, `VERTICAL`).
	- `moving_left`, `moving_right`, `moving_up`, `moving_down` — directional booleans.

Input handlers (brief):
- `NilDevKeyboardInput2D` — reads configurable InputMap actions, defaulting to `nildevgames_move_*`. (`addons/nildevgames_directional_movement_2d/input/keyboard_input_2d.gd`)
- `NilDevMouseInput2D` — drag-based mouse input with deadzone and max radius. (`addons/nildevgames_directional_movement_2d/input/mouse_input_2d.gd`)
- `NilDevTouchInput2D` — similar to mouse but handles screen touch events. (`addons/nildevgames_directional_movement_2d/input/touch_input_2d.gd`)

Internals: `directional_input_2d.gd` and `drag_based_input_2d.gd` implement the abstract behavior used by concrete input nodes.

## Input Mode Behavior

When `input_mode` is `AUTO`, the addon prioritizes input sources in this order: touch > mouse > keyboard.

You can choose which methods participate in `AUTO` with:
- `auto_enable_keyboard`
- `auto_enable_mouse`
- `auto_enable_touch`
- `auto_ignore_zero_drag`

The priority order does not change. Disabled methods are simply skipped, so if you enable only mouse and keyboard, `AUTO` still resolves input as mouse > keyboard.

If `auto_ignore_zero_drag` is enabled, a pressed mouse or touch drag that currently resolves to `Vector2.ZERO` will defer to the next AUTO input source instead of blocking it. This only affects zero-vector drag states, such as an untouched drag origin or a paused drag, and does not change normal non-zero priority.

`AUTO` is intended for mixed-input setups. If fewer than two methods are enabled, the node shows a configuration warning recommending a dedicated mode instead. A single enabled method still works, but using `KEYBOARD`, `MOUSE`, or `TOUCH` directly is clearer in that case.

You can still force a single mode by setting `input_mode` to `KEYBOARD`, `MOUSE`, or `TOUCH`.

## Tuning

- `speed_mode`: `UNIFORM` uses one shared speed, `CARDINAL` applies separate speeds for left/right/up/down.
- `deadzone`: prevents tiny accidental drags from producing movement.
- `max_radius`: controls drag magnitude after which input clamps to max strength.
- `motion_timeout`: if enabled, pauses drag input after a period of no motion.
- `auto_ignore_zero_drag`: in `AUTO`, lets pressed touch or mouse input fall through to the next source when the drag currently resolves to zero.

Use the speed property that matches the active mode. The node now guards mismatched assignments at runtime: `speed` is only valid in `UNIFORM`, and `cardinal_speed_*` values are only valid in `CARDINAL`.

If you want different speeds per direction, switch the movement node to `CARDINAL` mode:

```gdscript
mover.speed_mode = NilDevSpeedMode.Mode.CARDINAL
mover.cardinal_speed_right = 240.0
mover.cardinal_speed_left = 180.0
mover.cardinal_speed_up = 140.0
mover.cardinal_speed_down = 220.0
```

In `CARDINAL` mode the input sources stay the same; only movement scaling changes. Diagonals are weighted per axis, so keyboard, mouse, and touch still share the same input pipeline.

Start with default values and tweak to suit your gameplay feel.

Example: keep desktop-style `AUTO` behavior but ignore touch input:

```gdscript
mover.input_mode = NilDevInputMode.Mode.AUTO
mover.auto_enable_keyboard = true
mover.auto_enable_mouse = true
mover.auto_enable_touch = false
```

That keeps AUTO priority intact for the enabled methods, so mouse still overrides keyboard while touch is excluded entirely.

If you want keyboard input to keep working while a touch or mouse drag is pressed but still at its origin, enable auto_ignore_zero_drag:

```gdscript
mover.input_mode = NilDevInputMode.Mode.AUTO
mover.auto_ignore_zero_drag = true
```

## Examples & Tests

Canonical test-based examples live under `tests/unit/` and show how to simulate drag and keyboard input. See:
- [tests/unit/test_movement_2d.gd](tests/unit/test_movement_2d.gd)
- [tests/unit/test_speed_mode.gd](tests/unit/test_speed_mode.gd)
- [tests/unit/test_touch_input_2d.gd](tests/unit/test_touch_input_2d.gd)

A runnable repository example lives under `examples/`:
- [examples/player_example.tscn](examples/player_example.tscn) — minimal `Node2D` integration and the default main scene for this repository project.
- [examples/player_example.gd](examples/player_example.gd) — script for the displacement-based `Node2D` demo using `calculate_movement(delta)`.
- [examples/player_character_body_example.tscn](examples/player_character_body_example.tscn) — `CharacterBody2D` demo using `calculate_velocity()` plus `move_and_slide()`.
- [examples/player_character_body_example.gd](examples/player_character_body_example.gd) — script for the velocity-based physics-body demo.

Both runnable examples include a live performance panel that shows the whole demo scene's FPS, renderer/GPU information, RAM/VRAM usage, script frame time, fixed physics step time, 2D canvas draw stats, and GPU render-budget load. The panel is there to make the addon's runtime footprint obvious in practice without implying a synthetic "CPU load": `NilDevMovement2D` only resolves an input vector and applies scalar math each frame, so the example stays well within budget unless the surrounding scene work is the bottleneck.

The `examples/` folder is kept in the repository for source checkouts and excluded from packaged addon archives via `.gitattributes`.

## Troubleshooting

- The default `nildevgames_move_*` actions are created automatically, with arrows + WASD, when the plugin is enabled or when the keyboard node first runs.
- If you override keyboard action names, the addon will create them at runtime when missing. Add them manually to Project Settings -> Input Map if you want them persisted in the editor.
- If using `AUTO` mode and input seems ignored, confirm touch/mouse events aren’t being captured by UI elements first.
- The input nodes are auto-created on `_ready()` by `NilDevMovement2D`. Avoid switching `input_mode` every frame.
- If you configure speeds from code, set `speed_mode` first. Assigning `speed` in `CARDINAL` mode or `cardinal_speed_*` in `UNIFORM` mode now emits `push_error()` and preserves the previous value.

## Development

- Plugin metadata: [addons/nildevgames_directional_movement_2d/plugin.cfg](addons/nildevgames_directional_movement_2d/plugin.cfg)
- License: MIT (`LICENSE`)
- Tests: This repository includes GUT tests under `tests/unit/`. Run using the GUT command-line runner or the editor plugin.

## Credits

Created by NilDevGames. Contributions welcome via PR.

