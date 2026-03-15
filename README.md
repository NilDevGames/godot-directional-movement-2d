# godot-directional-movement-2d
Cross-platform 2D directional movement input for Godot (keyboard, mouse, touch)

## Overview

`godot-directional-movement-2d` provides a small, dependency-free set of GDScript helpers for directional input and movement in 2D games. It exposes a single facade node `NilDevMovement2D` which aggregates input from keyboard, mouse (drag), and touch. The addon is lightweight and intended for Godot 4.2+ projects.

**Key features**
- Automatic input mode selection (`AUTO`, `KEYBOARD`, `MOUSE`, `TOUCH`).
- Drag-based mouse and touch input with deadzone / radius tuning.
- Simple integration: call `calculate_movement(delta)` and apply to your player `position` or `velocity`.

## Compatibility

- Tested with Godot 4.2+ (GDScript typed syntax used). If you use an older Godot version you may need to adapt the scripts.

## Installation

Copy the `addons/nildevgames_directional_movement_2d` folder into your project's `addons/` directory.

- If you enable the plugin in Project Settings -> Plugins, it seeds four default keyboard actions into Project Settings -> Input Map.
- If you use the scripts without enabling the plugin, missing configured keyboard actions are still created automatically at runtime.

## Quick Start

1. Add `NilDevMovement2D` to your player scene as a child node. The node script is located at `addons/nildevgames_directional_movement_2d/movement_2d.gd`.
2. In your player's `_physics_process(delta)` use `calculate_movement(delta)` to get a movement vector and apply it.

Example integration (character code):

```gdscript
extends CharacterBody2D

@onready var mover := $NilDevMovement2D

func _physics_process(delta: float) -> void:
	# `calculate_movement(delta)` returns a frame displacement (pixels to move this frame).
	# Physics APIs like `move_and_slide()` expect a velocity (pixels/sec), so convert displacement -> velocity.
	var displacement: Vector2 = mover.calculate_movement(delta)
	velocity = displacement / delta if delta > 0.0 else Vector2.ZERO
	move_and_slide()
```

Or a simpler `position`-based example for Node2D players:

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
	- `speed` — float, default ~200.0 — movement speed multiplier.
	- Mouse/Touch tuning: `*_deadzone`, `*_max_radius`, `*_stop_drag_if_input_stopped`, `*_motion_timeout` (grouped per input type).
- Methods:
	- `get_input_vector() -> Vector2` — current input direction vector (normalized where appropriate).
	- `calculate_movement(delta: float) -> Vector2` — updates internal velocity and returns movement for this frame.
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

When `input_mode` is `AUTO`, the addon prioritizes input sources in this order: touch > mouse > keyboard. You can force a single mode by setting `input_mode` to `KEYBOARD`, `MOUSE`, or `TOUCH`.

## Tuning

- `deadzone`: prevents tiny accidental drags from producing movement.
- `max_radius`: controls drag magnitude after which input clamps to max strength.
- `motion_timeout`: if enabled, pauses drag input after a period of no motion.

Start with default values and tweak to suit your gameplay feel.

## Examples & Tests

Canonical test-based examples live under `tests/unit/` and show how to simulate drag and keyboard input. See:
- [tests/unit/test_movement_2d.gd](tests/unit/test_movement_2d.gd)
- [tests/unit/test_touch_input_2d.gd](tests/unit/test_touch_input_2d.gd)

A runnable repository example lives under `examples/`:
- [examples/player_example.tscn](examples/player_example.tscn) — minimal `Node2D` integration and the default main scene for this repository project.
- [examples/player_example.gd](examples/player_example.gd) — script for the position-based `Node2D` demo.
- [examples/player_character_body_example.tscn](examples/player_character_body_example.tscn) — `CharacterBody2D` demo using `velocity` plus `move_and_slide()`.
- [examples/player_character_body_example.gd](examples/player_character_body_example.gd) — script for the physics-body demo.

The `examples/` folder is kept in the repository for source checkouts and excluded from packaged addon archives via `.gitattributes`.

## Troubleshooting

- The default `nildevgames_move_*` actions are created automatically, with arrows + WASD, when the plugin is enabled or when the keyboard node first runs.
- If you override keyboard action names, the addon will create them at runtime when missing. Add them manually to Project Settings -> Input Map if you want them persisted in the editor.
- If using `AUTO` mode and input seems ignored, confirm touch/mouse events aren’t being captured by UI elements first.
- The input nodes are auto-created on `_ready()` by `NilDevMovement2D`. Avoid switching `input_mode` every frame.

## Development

- Plugin metadata: [addons/nildevgames_directional_movement_2d/plugin.cfg](addons/nildevgames_directional_movement_2d/plugin.cfg)
- License: MIT (`LICENSE`)
- Tests: This repository includes GUT tests under `tests/unit/`. Run using the GUT command-line runner or the editor plugin.

## Credits

Created by NilDevGames. Contributions welcome via PR.

