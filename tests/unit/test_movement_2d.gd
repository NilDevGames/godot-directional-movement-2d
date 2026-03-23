extends GutTest
## Unit tests for NilDevMovement2D — the main facade node.
##
## NilDevMovement2D creates child input nodes in _ready(), so it must be added
## to the scene tree. We use add_child_autofree() throughout.

const KeyboardActions = preload("res://addons/nildevgames_directional_movement_2d/internals/keyboard_actions_2d.gd")
const ACTION_RIGHT := KeyboardActions.DEFAULT_MOVE_RIGHT_ACTION
const ACTION_LEFT := KeyboardActions.DEFAULT_MOVE_LEFT_ACTION
const ACTION_UP := KeyboardActions.DEFAULT_MOVE_UP_ACTION
const ACTION_DOWN := KeyboardActions.DEFAULT_MOVE_DOWN_ACTION
const ACTIONS:Array[StringName] = [ACTION_RIGHT, ACTION_LEFT, ACTION_UP, ACTION_DOWN]

var _node: NilDevMovement2D
var _owned_actions: Array[StringName] = []
var _release_actions: Array[StringName] = []


func before_all():
	for action_name in ACTIONS:
		if not InputMap.has_action(action_name):
			_owned_actions.append(action_name)

	KeyboardActions.ensure_runtime_actions(
		KeyboardActions.build_configured_actions(
			ACTION_RIGHT,
			ACTION_LEFT,
			ACTION_UP,
			ACTION_DOWN
		)
	)


func after_all():
	for action_name in _owned_actions:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)


func before_each():
	_release_actions = ACTIONS.duplicate()
	_node = NilDevMovement2D.new()
	add_child_autofree(_node)
	# Wait a frame so _ready() and child nodes are fully set up
	await wait_physics_frames(1)


func after_each():
	for action_name in _release_actions:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)


func _remember_owned_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name) and not _owned_actions.has(action_name):
		_owned_actions.append(action_name)
	if not _release_actions.has(action_name):
		_release_actions.append(action_name)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_mouse_button(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var ev = InputEventMouseButton.new()
	ev.position = pos
	ev.pressed = pressed
	ev.button_index = MOUSE_BUTTON_LEFT
	return ev

func _make_mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var ev = InputEventMouseMotion.new()
	ev.position = pos
	return ev

func _make_screen_touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev = InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	return ev

func _make_screen_drag(pos: Vector2) -> InputEventScreenDrag:
	var ev = InputEventScreenDrag.new()
	ev.position = pos
	return ev


# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT STATE
# ═══════════════════════════════════════════════════════════════════════════════

func test_default_input_mode_is_auto():
	assert_eq(_node.input_mode, NilDevInputMode.Mode.AUTO, "Default input mode should be AUTO")

func test_auto_mode_enables_all_input_methods_by_default():
	assert_true(_node.auto_enable_keyboard, "AUTO should enable keyboard by default")
	assert_true(_node.auto_enable_mouse, "AUTO should enable mouse by default")
	assert_true(_node.auto_enable_touch, "AUTO should enable touch by default")

func test_default_speed_mode_is_uniform():
	assert_eq(_node.speed_mode, NilDevSpeedMode.Mode.UNIFORM, "Default speed mode should be UNIFORM")

func test_default_speed():
	assert_eq(_node.speed, 200.0, "Default speed should be 200.0")

func test_default_cardinal_speeds_match_default_speed():
	assert_eq(_node.cardinal_speed_right, 200.0)
	assert_eq(_node.cardinal_speed_left, 200.0)
	assert_eq(_node.cardinal_speed_up, 200.0)
	assert_eq(_node.cardinal_speed_down, 200.0)

func test_default_velocity_is_zero():
	assert_eq(_node.velocity, Vector2.ZERO, "Default velocity should be ZERO")

func test_default_keyboard_action_names_are_prefixed():
	assert_eq(_node.keyboard_move_right_action, ACTION_RIGHT)
	assert_eq(_node.keyboard_move_left_action, ACTION_LEFT)
	assert_eq(_node.keyboard_move_up_action, ACTION_UP)
	assert_eq(_node.keyboard_move_down_action, ACTION_DOWN)


# ═══════════════════════════════════════════════════════════════════════════════
# _ready PROCESSING FLAGS
# ═══════════════════════════════════════════════════════════════════════════════

func test_ready_disables_process():
	assert_false(_node.is_processing(), "process should be disabled")

func test_ready_disables_physics_process():
	assert_false(_node.is_physics_processing(), "physics_process should be disabled")

func test_ready_enables_input():
	assert_true(_node.is_processing_input(), "input processing should be enabled")


# ═══════════════════════════════════════════════════════════════════════════════
# INPUT MODE — NODE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

func test_auto_mode_creates_all_three_nodes():
	assert_true(is_instance_valid(_node._keyboard_node), "Keyboard node should exist in AUTO")
	assert_true(is_instance_valid(_node._mouse_node), "Mouse node should exist in AUTO")
	assert_true(is_instance_valid(_node._touch_node), "Touch node should exist in AUTO")

func test_auto_mode_only_creates_enabled_input_nodes():
	_node.auto_enable_keyboard = false
	_node.auto_enable_touch = false
	await wait_physics_frames(2)
	assert_false(is_instance_valid(_node._keyboard_node), "Keyboard node should be freed when disabled in AUTO")
	assert_true(is_instance_valid(_node._mouse_node), "Mouse node should remain when enabled in AUTO")
	assert_false(is_instance_valid(_node._touch_node), "Touch node should be freed when disabled in AUTO")

func test_reenabling_auto_input_recreates_node():
	_node.auto_enable_mouse = false
	await wait_physics_frames(2)
	assert_eq(_node._mouse_node, null, "Mouse node reference should be nulled when disabled in AUTO")
	_node.auto_enable_mouse = true
	await wait_physics_frames(2)
	assert_true(is_instance_valid(_node._mouse_node), "Mouse node should be recreated when re-enabled in AUTO")

func test_keyboard_mode_creates_only_keyboard():
	_node.input_mode = NilDevInputMode.Mode.KEYBOARD
	await wait_physics_frames(2)
	assert_true(is_instance_valid(_node._keyboard_node), "Keyboard node should exist")
	assert_false(is_instance_valid(_node._mouse_node), "Mouse node should be freed")
	assert_false(is_instance_valid(_node._touch_node), "Touch node should be freed")

func test_mouse_mode_creates_only_mouse():
	_node.input_mode = NilDevInputMode.Mode.MOUSE
	await wait_physics_frames(2)
	assert_true(is_instance_valid(_node._mouse_node), "Mouse node should exist")
	assert_false(is_instance_valid(_node._keyboard_node), "Keyboard node should be freed")
	assert_false(is_instance_valid(_node._touch_node), "Touch node should be freed")

func test_touch_mode_creates_only_touch():
	_node.input_mode = NilDevInputMode.Mode.TOUCH
	await wait_physics_frames(2)
	assert_true(is_instance_valid(_node._touch_node), "Touch node should exist")
	assert_false(is_instance_valid(_node._keyboard_node), "Keyboard node should be freed")
	assert_false(is_instance_valid(_node._mouse_node), "Mouse node should be freed")

func test_switch_back_to_auto_recreates_all():
	_node.input_mode = NilDevInputMode.Mode.KEYBOARD
	await wait_physics_frames(2)
	_node.input_mode = NilDevInputMode.Mode.AUTO
	await wait_physics_frames(2)
	assert_true(is_instance_valid(_node._keyboard_node), "Keyboard node should exist")
	assert_true(is_instance_valid(_node._mouse_node), "Mouse node should be re-created")
	assert_true(is_instance_valid(_node._touch_node), "Touch node should be re-created")

func test_same_mode_is_noop():
	var kb_ref = _node._keyboard_node
	var mouse_ref = _node._mouse_node
	var touch_ref = _node._touch_node
	_node.input_mode = NilDevInputMode.Mode.AUTO  # same value
	# References should be unchanged (setter early-returns)
	assert_eq(_node._keyboard_node, kb_ref, "Keyboard node reference unchanged")
	assert_eq(_node._mouse_node, mouse_ref, "Mouse node reference unchanged")
	assert_eq(_node._touch_node, touch_ref, "Touch node reference unchanged")


# ═══════════════════════════════════════════════════════════════════════════════
# BUG: DANGLING REFERENCE ON RAPID MODE SWITCH
# ═══════════════════════════════════════════════════════════════════════════════

func test_dangling_reference_on_rapid_mode_switch():
	# Start in AUTO — all nodes exist
	assert_true(is_instance_valid(_node._mouse_node))
	assert_true(is_instance_valid(_node._touch_node))

	# Switch to KEYBOARD → mouse & touch are queue_free()'d but refs NOT nulled
	_node.input_mode = NilDevInputMode.Mode.KEYBOARD
	# Immediately switch back to AUTO → _ensure_*() sees queued-for-deletion
	# nodes as still valid and skips re-creation
	_node.input_mode = NilDevInputMode.Mode.AUTO

	# Wait for queue_free to process
	await wait_physics_frames(2)

	assert_true(is_instance_valid(_node._mouse_node),
		"Mouse node should be recreated after rapid AUTO→KEYBOARD→AUTO switch")
	assert_true(is_instance_valid(_node._touch_node),
		"Touch node should be recreated after rapid AUTO→KEYBOARD→AUTO switch")


# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS PROPAGATION
# ═══════════════════════════════════════════════════════════════════════════════

func test_mouse_deadzone_propagated():
	_node.mouse_deadzone = 25.0
	assert_eq(_node._mouse_node.deadzone, 25.0, "Mouse node deadzone should be updated")

func test_mouse_max_radius_propagated():
	_node.mouse_max_radius = 200.0
	assert_eq(_node._mouse_node.max_radius, 200.0)

func test_mouse_stop_drag_propagated():
	_node.mouse_stop_drag_if_input_stopped = false
	assert_false(_node._mouse_node.stop_drag_if_input_stopped)

func test_mouse_motion_timeout_propagated():
	_node.mouse_motion_timeout = 0.5
	assert_eq(_node._mouse_node.motion_timeout, 0.5)

func test_touch_deadzone_propagated():
	_node.touch_deadzone = 30.0
	assert_eq(_node._touch_node.deadzone, 30.0, "Touch node deadzone should be updated")

func test_touch_max_radius_propagated():
	_node.touch_max_radius = 150.0
	assert_eq(_node._touch_node.max_radius, 150.0)

func test_touch_stop_drag_propagated():
	_node.touch_stop_drag_if_input_stopped = false
	assert_false(_node._touch_node.stop_drag_if_input_stopped)

func test_touch_motion_timeout_propagated():
	_node.touch_motion_timeout = 0.3
	assert_eq(_node._touch_node.motion_timeout, 0.3)

func test_settings_applied_on_node_creation():
	# Set values before mode switch (node doesn't exist yet for MOUSE-only)
	_node.input_mode = NilDevInputMode.Mode.KEYBOARD
	await wait_physics_frames(2)
	_node.mouse_deadzone = 42.0
	_node.mouse_max_radius = 250.0
	# Now switch to mouse — node should be created with our settings
	_node.input_mode = NilDevInputMode.Mode.MOUSE
	await wait_physics_frames(1)
	assert_eq(_node._mouse_node.deadzone, 42.0, "Settings applied on node creation")
	assert_eq(_node._mouse_node.max_radius, 250.0)

func test_keyboard_action_settings_propagated():
	var custom_right := StringName("nildevgames_test_movement_right_%s" % get_instance_id())
	var custom_left := StringName("nildevgames_test_movement_left_%s" % get_instance_id())
	var custom_up := StringName("nildevgames_test_movement_up_%s" % get_instance_id())
	var custom_down := StringName("nildevgames_test_movement_down_%s" % get_instance_id())
	_remember_owned_action(custom_right)
	_remember_owned_action(custom_left)
	_remember_owned_action(custom_up)
	_remember_owned_action(custom_down)

	_node.keyboard_move_right_action = custom_right
	_node.keyboard_move_left_action = custom_left
	_node.keyboard_move_up_action = custom_up
	_node.keyboard_move_down_action = custom_down

	assert_eq(_node._keyboard_node.move_right_action, custom_right)
	assert_eq(_node._keyboard_node.move_left_action, custom_left)
	assert_eq(_node._keyboard_node.move_up_action, custom_up)
	assert_eq(_node._keyboard_node.move_down_action, custom_down)
	assert_true(InputMap.has_action(custom_right))

	Input.action_press(custom_right)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001), "Facade keyboard override should drive the keyboard child")


# ═══════════════════════════════════════════════════════════════════════════════
# get_input_vector — PER MODE
# ═══════════════════════════════════════════════════════════════════════════════

func test_get_input_vector_keyboard_mode():
	_node.input_mode = NilDevInputMode.Mode.KEYBOARD
	await wait_physics_frames(2)
	Input.action_press(ACTION_RIGHT)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001), "Keyboard mode returns keyboard vector")

func test_get_input_vector_mouse_mode():
	_node.input_mode = NilDevInputMode.Mode.MOUSE
	await wait_physics_frames(2)
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "Mouse mode returns mouse vector")

func test_get_input_vector_touch_mode():
	_node.input_mode = NilDevInputMode.Mode.TOUCH
	await wait_physics_frames(2)
	_node._touch_node._start_drag(Vector2(100, 100))
	_node._touch_node._update_drag(Vector2(200, 100))
	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "Touch mode returns touch vector")


# ── AUTO mode priority: touch > mouse > keyboard ─────────────────────────────

func test_auto_priority_keyboard_only():
	Input.action_press(ACTION_RIGHT)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001),
		"AUTO: keyboard input when no touch/mouse")

func test_auto_priority_mouse_over_keyboard():
	Input.action_press(ACTION_RIGHT)
	# Start a mouse drag (leftward to distinguish from keyboard)
	_node._mouse_node._start_drag(Vector2(200, 100))
	_node._mouse_node._update_drag(Vector2(100, 100))
	var v = _node.get_input_vector()
	assert_lt(v.x, 0.0, "AUTO: mouse takes priority over keyboard (leftward)")

func test_auto_priority_touch_over_mouse():
	# Start mouse drag (rightward)
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	# Start touch drag (downward)
	_node._touch_node._start_drag(Vector2(100, 100))
	_node._touch_node._update_drag(Vector2(100, 200))
	var v = _node.get_input_vector()
	assert_gt(v.y, 0.0, "AUTO: touch takes priority over mouse (downward)")
	assert_almost_eq(v.x, 0.0, 0.001, "X near zero since touch is downward")

func test_auto_priority_touch_over_keyboard_and_mouse():
	Input.action_press(ACTION_LEFT)
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	_node._touch_node._start_drag(Vector2(100, 100))
	_node._touch_node._update_drag(Vector2(100, 0))
	var v = _node.get_input_vector()
	assert_lt(v.y, 0.0, "AUTO: touch Y negative (upward) takes highest priority")

func test_auto_priority_skips_disabled_touch_and_uses_mouse():
	_node.auto_enable_touch = false
	await wait_physics_frames(2)
	Input.action_press(ACTION_LEFT)
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "AUTO: mouse should win when touch is disabled")

func test_auto_priority_skips_disabled_mouse_and_uses_keyboard():
	_node.auto_enable_mouse = false
	_node.auto_enable_touch = false
	await wait_physics_frames(2)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, 1), Vector2(0.001, 0.001),
		"AUTO: keyboard should be used when mouse and touch are disabled")

func test_auto_returns_zero_when_all_inputs_disabled():
	_node.auto_enable_keyboard = false
	_node.auto_enable_mouse = false
	_node.auto_enable_touch = false
	await wait_physics_frames(2)
	Input.action_press(ACTION_RIGHT)
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "AUTO: ZERO when all AUTO inputs are disabled")

func test_auto_falls_to_keyboard_when_no_drag():
	# No mouse/touch drag active
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, 1), Vector2(0.001, 0.001),
		"AUTO: keyboard used when no touch/mouse active")

func test_auto_zero_drag_blocks_keyboard_by_default():
	Input.action_press(ACTION_RIGHT)
	_node._mouse_node._start_drag(Vector2(100, 100))
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "AUTO: pressed mouse drag at origin should still block keyboard by default")

func test_auto_zero_drag_falls_through_to_keyboard_when_enabled():
	_node.auto_ignore_zero_drag = true
	Input.action_press(ACTION_RIGHT)
	_node._mouse_node._start_drag(Vector2(100, 100))
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001),
		"AUTO: zero-vector mouse drag should fall through to keyboard when enabled")

func test_auto_zero_touch_falls_through_to_mouse_when_enabled():
	_node.auto_ignore_zero_drag = true
	_node._touch_node._start_drag(Vector2(100, 100))
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "AUTO: zero-vector touch should fall through to active mouse drag when enabled")

func test_auto_non_zero_drag_still_overrides_keyboard_when_fallthrough_enabled():
	_node.auto_ignore_zero_drag = true
	Input.action_press(ACTION_LEFT)
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(200, 100))
	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "AUTO: non-zero mouse drag should still override keyboard when fallthrough is enabled")

func test_auto_returns_zero_when_no_input():
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "AUTO: ZERO when nothing pressed")


# ═══════════════════════════════════════════════════════════════════════════════
# calculate_velocity
# ═══════════════════════════════════════════════════════════════════════════════

func test_calculate_velocity_zero_input():
	var result = _node.calculate_velocity()
	assert_eq(result, Vector2.ZERO, "Zero input → zero velocity")
	assert_eq(_node.velocity, Vector2.ZERO, "velocity getter should stay zero")

func test_calculate_velocity_with_input():
	_node.speed = 200.0
	Input.action_press(ACTION_RIGHT)
	var result = _node.calculate_velocity()
	assert_almost_eq(result, Vector2(200.0, 0.0), Vector2(0.001, 0.001),
		"calculate_velocity returns pixels/sec without delta scaling")
	assert_almost_eq(_node.velocity, result, Vector2(0.001, 0.001),
		"velocity getter should match the latest calculate_velocity result")

func test_calculate_velocity_cardinal_diagonal_uses_per_axis_speeds():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 300.0
	_node.cardinal_speed_down = 120.0
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_DOWN)
	var result = _node.calculate_velocity()
	var input_vec = Vector2(1, 1).normalized()
	var expected_velocity = Vector2(input_vec.x * 300.0, input_vec.y * 120.0)
	assert_almost_eq(result, expected_velocity, Vector2(0.1, 0.1))
	assert_almost_eq(_node.velocity, expected_velocity, Vector2(0.1, 0.1))

func test_calculate_velocity_matches_movement_scaled_by_delta():
	_node.speed = 160.0
	Input.action_press(ACTION_UP)
	var velocity_result = _node.calculate_velocity()
	var delta = 0.25
	var movement_result = _node.calculate_movement(delta)
	assert_almost_eq(movement_result, velocity_result * delta, Vector2(0.001, 0.001),
		"calculate_movement should stay equivalent to calculate_velocity * delta")
	assert_almost_eq(_node.velocity, velocity_result, Vector2(0.001, 0.001),
		"calculate_movement should preserve the same sampled velocity under unchanged input")

func test_calculate_velocity_tracks_latest_input():
	_node.speed = 200.0
	Input.action_press(ACTION_RIGHT)
	var right_velocity = _node.calculate_velocity()
	Input.action_release(ACTION_RIGHT)
	Input.action_press(ACTION_LEFT)
	var left_velocity = _node.calculate_velocity()
	assert_almost_eq(right_velocity, Vector2(200.0, 0.0), Vector2(0.001, 0.001))
	assert_almost_eq(left_velocity, Vector2(-200.0, 0.0), Vector2(0.001, 0.001),
		"calculate_velocity should reflect the most recent input state")
	assert_almost_eq(_node.velocity, left_velocity, Vector2(0.001, 0.001),
		"velocity getter should track the latest calculate_velocity call")


# ═══════════════════════════════════════════════════════════════════════════════
# calculate_movement
# ═══════════════════════════════════════════════════════════════════════════════

func test_calculate_movement_zero_input():
	var result = _node.calculate_movement(0.016)
	assert_eq(result, Vector2.ZERO, "Zero input → zero movement")
	assert_eq(_node.velocity, Vector2.ZERO, "_velocity stays zero")

func test_calculate_movement_with_input():
	_node.speed = 200.0
	Input.action_press(ACTION_RIGHT)
	var delta = 0.016
	var result = _node.calculate_movement(delta)

	# velocity should be input_vector * speed = (1,0) * 200 = (200, 0)
	assert_almost_eq(_node.velocity, Vector2(200, 0), Vector2(0.001, 0.001),
		"_velocity = input_vector * speed")
	# result = velocity * delta
	var expected = Vector2(200, 0) * delta
	assert_almost_eq(result, expected, Vector2(0.001, 0.001),
		"calculate_movement returns velocity * delta")

func test_calculate_movement_diagonal():
	_node.speed = 100.0
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_DOWN)
	var delta = 1.0
	var result = _node.calculate_movement(delta)

	var input_vec = Vector2(1, 1).normalized()
	var expected_velocity = input_vec * 100.0
	assert_almost_eq(_node.velocity, expected_velocity, Vector2(0.1, 0.1))
	assert_almost_eq(result, expected_velocity * delta, Vector2(0.1, 0.1))

func test_calculate_movement_cardinal_right_speed():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 320.0
	Input.action_press(ACTION_RIGHT)
	var result = _node.calculate_movement(0.5)
	assert_almost_eq(_node.velocity, Vector2(320.0, 0.0), Vector2(0.001, 0.001))
	assert_almost_eq(result, Vector2(160.0, 0.0), Vector2(0.001, 0.001))

func test_calculate_movement_cardinal_left_speed():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_left = 180.0
	Input.action_press(ACTION_LEFT)
	_node.calculate_movement(1.0)
	assert_almost_eq(_node.velocity, Vector2(-180.0, 0.0), Vector2(0.001, 0.001))

func test_calculate_movement_cardinal_up_speed():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_up = 90.0
	Input.action_press(ACTION_UP)
	_node.calculate_movement(1.0)
	assert_almost_eq(_node.velocity, Vector2(0.0, -90.0), Vector2(0.001, 0.001))

func test_calculate_movement_cardinal_down_speed():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_down = 240.0
	Input.action_press(ACTION_DOWN)
	_node.calculate_movement(1.0)
	assert_almost_eq(_node.velocity, Vector2(0.0, 240.0), Vector2(0.001, 0.001))

func test_calculate_movement_cardinal_diagonal_uses_per_axis_speeds():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 300.0
	_node.cardinal_speed_down = 120.0
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_DOWN)
	var result = _node.calculate_movement(1.0)
	var input_vec = Vector2(1, 1).normalized()
	var expected_velocity = Vector2(input_vec.x * 300.0, input_vec.y * 120.0)
	assert_almost_eq(_node.velocity, expected_velocity, Vector2(0.1, 0.1))
	assert_almost_eq(result, expected_velocity, Vector2(0.1, 0.1))

func test_calculate_movement_cardinal_mouse_drag_preserves_strength():
	_node.input_mode = NilDevInputMode.Mode.MOUSE
	await wait_physics_frames(2)
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 300.0
	_node._mouse_node._start_drag(Vector2(100, 100))
	_node._mouse_node._update_drag(Vector2(150, 100))
	_node.calculate_movement(1.0)
	assert_almost_eq(_node.velocity, Vector2(150.0, 0.0), Vector2(0.001, 0.001))

func test_switching_to_cardinal_seeds_untouched_speeds_from_speed():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 275.0
	_node.speed_mode = NilDevSpeedMode.Mode.UNIFORM
	_node.speed = 350.0
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	assert_eq(_node.cardinal_speed_right, 275.0)
	assert_eq(_node.cardinal_speed_left, 350.0)
	assert_eq(_node.cardinal_speed_up, 350.0)
	assert_eq(_node.cardinal_speed_down, 350.0)

func test_cardinal_speeds_are_not_reseeded_after_first_switch():
	_node.speed = 280.0
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node.cardinal_speed_right = 410.0
	_node.speed_mode = NilDevSpeedMode.Mode.UNIFORM
	_node.speed = 150.0
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	assert_eq(_node.cardinal_speed_right, 410.0)
	assert_eq(_node.cardinal_speed_left, 280.0)

func test_setting_speed_in_cardinal_mode_pushes_error_and_keeps_value():
	_node.speed_mode = NilDevSpeedMode.Mode.CARDINAL
	var original_speed := _node.speed
	_node.speed = 350.0
	assert_push_error("Cannot set 'speed' while speed_mode is CARDINAL.")
	assert_eq(_node.speed, original_speed)

func test_setting_cardinal_speed_right_in_uniform_mode_pushes_error_and_keeps_value():
	var original_speed := _node.cardinal_speed_right
	_node.cardinal_speed_right = 350.0
	assert_push_error("Cannot set 'cardinal_speed_right' while speed_mode is UNIFORM.")
	assert_eq(_node.cardinal_speed_right, original_speed)

func test_setting_cardinal_speed_left_in_uniform_mode_pushes_error_and_keeps_value():
	var original_speed := _node.cardinal_speed_left
	_node.cardinal_speed_left = 350.0
	assert_push_error("Cannot set 'cardinal_speed_left' while speed_mode is UNIFORM.")
	assert_eq(_node.cardinal_speed_left, original_speed)

func test_setting_cardinal_speed_up_in_uniform_mode_pushes_error_and_keeps_value():
	var original_speed := _node.cardinal_speed_up
	_node.cardinal_speed_up = 350.0
	assert_push_error("Cannot set 'cardinal_speed_up' while speed_mode is UNIFORM.")
	assert_eq(_node.cardinal_speed_up, original_speed)

func test_setting_cardinal_speed_down_in_uniform_mode_pushes_error_and_keeps_value():
	var original_speed := _node.cardinal_speed_down
	_node.cardinal_speed_down = 350.0
	assert_push_error("Cannot set 'cardinal_speed_down' while speed_mode is UNIFORM.")
	assert_eq(_node.cardinal_speed_down, original_speed)

func test_calculate_movement_updates_velocity_side_effect():
	Input.action_press(ACTION_UP)
	_node.calculate_movement(0.016)
	assert_ne(_node.velocity, Vector2.ZERO, "_velocity should be updated as side effect")


# ═══════════════════════════════════════════════════════════════════════════════
# COMPUTED PROPERTIES
# ═══════════════════════════════════════════════════════════════════════════════

# ── velocity getter ───────────────────────────────────────────────────────────

func test_velocity_reflects_calculate_movement():
	Input.action_press(ACTION_RIGHT)
	_node.calculate_movement(0.016)
	assert_gt(_node.velocity.x, 0.0, "velocity.x should be positive after rightward input")

# ── movement_type ─────────────────────────────────────────────────────────────

func test_movement_type_stopped():
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.STOPPED,
		"Movement type should be STOPPED when velocity is zero")

func test_movement_type_horizontal():
	_node._velocity = Vector2(100, 50)
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.HORIZONTAL,
		"abs(x) > abs(y) → HORIZONTAL")

func test_movement_type_vertical():
	_node._velocity = Vector2(50, 100)
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.VERTICAL,
		"abs(y) > abs(x) → VERTICAL")

func test_movement_type_equal_components_is_vertical():
	# When abs(x) == abs(y), the code falls through to VERTICAL
	_node._velocity = Vector2(100, 100)
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.VERTICAL,
		"Equal abs components → VERTICAL (falls through)")

func test_movement_type_negative_horizontal():
	_node._velocity = Vector2(-150, 50)
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.HORIZONTAL,
		"Negative X with abs(x) > abs(y) → HORIZONTAL")

func test_movement_type_negative_vertical():
	_node._velocity = Vector2(10, -200)
	assert_eq(_node.movement_type, NilDevMovement2D.MovementType.VERTICAL,
		"Negative Y with abs(y) > abs(x) → VERTICAL")

# ── directional booleans ─────────────────────────────────────────────────────

func test_moving_left():
	_node._velocity = Vector2(-100, 0)
	assert_true(_node.moving_left, "velocity.x < 0 → moving_left")

func test_not_moving_left_when_zero():
	_node._velocity = Vector2.ZERO
	assert_false(_node.moving_left, "Zero velocity → not moving_left")

func test_not_moving_left_when_right():
	_node._velocity = Vector2(100, 0)
	assert_false(_node.moving_left, "Positive x → not moving_left")

func test_moving_right():
	_node._velocity = Vector2(100, 0)
	assert_true(_node.moving_right, "velocity.x > 0 → moving_right")

func test_not_moving_right_when_zero():
	_node._velocity = Vector2.ZERO
	assert_false(_node.moving_right, "Zero velocity → not moving_right")

func test_not_moving_right_when_left():
	_node._velocity = Vector2(-100, 0)
	assert_false(_node.moving_right, "Negative x → not moving_right")

func test_moving_up():
	_node._velocity = Vector2(0, -100)
	assert_true(_node.moving_up, "velocity.y < 0 → moving_up")

func test_not_moving_up_when_zero():
	_node._velocity = Vector2.ZERO
	assert_false(_node.moving_up, "Zero velocity → not moving_up")

func test_not_moving_up_when_down():
	_node._velocity = Vector2(0, 100)
	assert_false(_node.moving_up, "Positive y → not moving_up")

func test_moving_down():
	_node._velocity = Vector2(0, 100)
	assert_true(_node.moving_down, "velocity.y > 0 → moving_down")

func test_not_moving_down_when_zero():
	_node._velocity = Vector2.ZERO
	assert_false(_node.moving_down, "Zero velocity → not moving_down")

func test_not_moving_down_when_up():
	_node._velocity = Vector2(0, -100)
	assert_false(_node.moving_down, "Negative y → not moving_down")

func test_all_directions_false_when_stopped():
	_node._velocity = Vector2.ZERO
	assert_false(_node.moving_left)
	assert_false(_node.moving_right)
	assert_false(_node.moving_up)
	assert_false(_node.moving_down)


# ═══════════════════════════════════════════════════════════════════════════════
# _validate_property — EDITOR PROPERTY VISIBILITY
# ═══════════════════════════════════════════════════════════════════════════════

func test_validate_property_keyboard_hides_mouse():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var prop = {"name": "mouse_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"KEYBOARD mode should hide mouse_ properties")

func test_validate_property_mouse_hides_keyboard():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	var prop = {"name": "keyboard_move_right_action", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"MOUSE mode should hide keyboard_ properties")

func test_validate_property_auto_shows_keyboard():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	var prop = {"name": "keyboard_move_right_action", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"AUTO mode should keep keyboard_ properties visible")

func test_validate_property_auto_shows_auto_enable_flags():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	var prop = {"name": "auto_enable_keyboard", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"AUTO mode should keep auto_enable_ properties visible")

func test_validate_property_keyboard_hides_auto_enable_flags():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var prop = {"name": "auto_enable_touch", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"Dedicated modes should hide auto_enable_ properties")

func test_validate_property_keyboard_hides_auto_ignore_zero_drag():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var prop = {"name": "auto_ignore_zero_drag", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"Dedicated modes should hide auto_ignore_zero_drag")

func test_validate_property_uniform_hides_cardinal_speeds():
	_node._speed_mode = NilDevSpeedMode.Mode.UNIFORM
	var prop = {"name": "cardinal_speed_right", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"UNIFORM mode should hide cardinal_speed_ properties")

func test_validate_property_cardinal_hides_speed():
	_node._speed_mode = NilDevSpeedMode.Mode.CARDINAL
	var prop = {"name": "speed", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"CARDINAL mode should hide speed")

func test_validate_property_cardinal_shows_cardinal_speeds():
	_node._speed_mode = NilDevSpeedMode.Mode.CARDINAL
	var prop = {"name": "cardinal_speed_down", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"CARDINAL mode should show cardinal_speed_ properties")

func test_validate_property_keyboard_hides_touch():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var prop = {"name": "touch_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"KEYBOARD mode should hide touch_ properties")

func test_validate_property_mouse_hides_touch():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	var prop = {"name": "touch_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"MOUSE mode should hide touch_ properties")

func test_validate_property_mouse_shows_mouse():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	var prop = {"name": "mouse_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"MOUSE mode should keep mouse_ properties visible")

func test_validate_property_touch_hides_mouse():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	var prop = {"name": "mouse_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"TOUCH mode should hide mouse_ properties")

func test_validate_property_touch_shows_touch():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	var prop = {"name": "touch_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"TOUCH mode should keep touch_ properties visible")

func test_validate_property_auto_shows_both():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	var mouse_prop = {"name": "mouse_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	var touch_prop = {"name": "touch_deadzone", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(mouse_prop)
	_node._validate_property(touch_prop)
	assert_eq(mouse_prop.usage, PROPERTY_USAGE_DEFAULT, "AUTO should keep mouse_ visible")
	assert_eq(touch_prop.usage, PROPERTY_USAGE_DEFAULT, "AUTO should keep touch_ visible")

func test_validate_property_mouse_timeout_hidden_when_stop_drag_off():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	_node._mouse_stop_drag_if_input_stopped = false
	var prop = {"name": "mouse_motion_timeout", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"mouse_motion_timeout hidden when mouse_stop_drag_if_input_stopped is false")

func test_validate_property_touch_timeout_hidden_when_stop_drag_off():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	_node._touch_stop_drag_if_input_stopped = false
	var prop = {"name": "touch_motion_timeout", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"touch_motion_timeout hidden when touch_stop_drag_if_input_stopped is false")


# ═══════════════════════════════════════════════════════════════════════════════
# _get_configuration_warnings
# ═══════════════════════════════════════════════════════════════════════════════

func test_warning_speed_zero():
	_node._speed = 0.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Speed must be greater than zero.")

func test_warning_speed_negative():
	_node._speed = -10.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Speed must be greater than zero.")

func test_cardinal_mode_does_not_warn_for_hidden_uniform_speed():
	_node._speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node._speed = 0.0
	_node._cardinal_speed_right = 100.0
	_node._cardinal_speed_left = 100.0
	_node._cardinal_speed_up = 100.0
	_node._cardinal_speed_down = 100.0
	var w = _node._get_configuration_warnings()
	assert_does_not_have(w, "Speed must be greater than zero.")

func test_cardinal_mode_warns_for_invalid_cardinal_speeds():
	_node._speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node._cardinal_speed_right = 0.0
	_node._cardinal_speed_left = -10.0
	_node._cardinal_speed_up = 0.0
	_node._cardinal_speed_down = -5.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Cardinal right speed must be greater than zero.")
	assert_has(w, "Cardinal left speed must be greater than zero.")
	assert_has(w, "Cardinal up speed must be greater than zero.")
	assert_has(w, "Cardinal down speed must be greater than zero.")

func test_cardinal_mode_has_no_speed_warnings_when_all_cardinal_speeds_are_valid():
	_node._speed_mode = NilDevSpeedMode.Mode.CARDINAL
	_node._cardinal_speed_right = 150.0
	_node._cardinal_speed_left = 150.0
	_node._cardinal_speed_up = 150.0
	_node._cardinal_speed_down = 150.0
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var w = _node._get_configuration_warnings()
	assert_does_not_have(w, "Speed must be greater than zero.")
	assert_eq(w.size(), 0, "Valid CARDINAL configuration should not warn")

func test_no_speed_warning_when_positive():
	_node._speed = 100.0
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	var w = _node._get_configuration_warnings()
	assert_does_not_have(w, "Speed must be greater than zero.")

func test_keyboard_mode_only_checks_speed():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	_node._speed = 100.0
	var w = _node._get_configuration_warnings()
	assert_eq(w.size(), 0, "KEYBOARD with valid speed → no warnings")

func test_keyboard_mode_warns_for_custom_keyboard_actions():
	_node._input_mode = NilDevInputMode.Mode.KEYBOARD
	_node._speed = 100.0
	_node.keyboard_move_right_action = &"move_right"
	var w = _node._get_configuration_warnings()
	assert_has(w, "Custom keyboard action names are created at runtime only. Add them to Project Settings -> Input Map if you want them persisted.")

func test_mouse_mode_checks_mouse_deadzone():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	_node._speed = 100.0
	_node._mouse_deadzone = -1.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Mouse deadzone cannot be negative.")

func test_mouse_mode_checks_mouse_max_radius():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	_node._speed = 100.0
	_node._mouse_max_radius = 5.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Mouse max radius should be at least 10.")

func test_mouse_mode_checks_mouse_timeout():
	_node._input_mode = NilDevInputMode.Mode.MOUSE
	_node._speed = 100.0
	_node._mouse_motion_timeout = 0.05
	var w = _node._get_configuration_warnings()
	assert_has(w, "Mouse motion timeout should be at least 0.1 seconds.")

func test_touch_mode_checks_touch_deadzone():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	_node._speed = 100.0
	_node._touch_deadzone = -1.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Touch deadzone cannot be negative.")

func test_touch_mode_checks_touch_max_radius():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	_node._speed = 100.0
	_node._touch_max_radius = 5.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Touch max radius should be at least 10.")

func test_touch_mode_checks_touch_timeout():
	_node._input_mode = NilDevInputMode.Mode.TOUCH
	_node._speed = 100.0
	_node._touch_motion_timeout = 0.05
	var w = _node._get_configuration_warnings()
	assert_has(w, "Touch motion timeout should be at least 0.1 seconds.")

func test_auto_mode_checks_both_mouse_and_touch():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	_node._speed = 100.0
	_node._mouse_deadzone = -1.0
	_node._touch_deadzone = -1.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Mouse deadzone cannot be negative.")
	assert_has(w, "Touch deadzone cannot be negative.")

func test_auto_mode_warns_when_only_one_input_is_enabled():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	_node._auto_enable_keyboard = true
	_node._auto_enable_mouse = false
	_node._auto_enable_touch = false
	var w = _node._get_configuration_warnings()
	assert_has(w, "AUTO mode should have at least two enabled input methods. Select a dedicated input mode if you only need one method.")

func test_auto_mode_warns_when_no_inputs_are_enabled():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	_node._auto_enable_keyboard = false
	_node._auto_enable_mouse = false
	_node._auto_enable_touch = false
	var w = _node._get_configuration_warnings()
	assert_has(w, "AUTO mode should have at least two enabled input methods. Select a dedicated input mode if you only need one method.")

func test_auto_mode_ignores_disabled_mouse_warnings():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	_node._auto_enable_keyboard = true
	_node._auto_enable_mouse = false
	_node._auto_enable_touch = true
	_node._mouse_deadzone = -1.0
	var w = _node._get_configuration_warnings()
	assert_does_not_have(w, "Mouse deadzone cannot be negative.")

func test_no_warnings_with_valid_auto_config():
	_node._input_mode = NilDevInputMode.Mode.AUTO
	_node._speed = 200.0
	_node._auto_enable_keyboard = true
	_node._auto_enable_mouse = true
	_node._auto_enable_touch = true
	_node._mouse_deadzone = 10.0
	_node._mouse_max_radius = 100.0
	_node._mouse_motion_timeout = 0.1
	_node._touch_deadzone = 10.0
	_node._touch_max_radius = 100.0
	_node._touch_motion_timeout = 0.1
	var w = _node._get_configuration_warnings()
	assert_eq(w.size(), 0, "All valid defaults → no warnings")


# ═══════════════════════════════════════════════════════════════════════════════
# PROPERTY SETTER NO-OPS (same value does not trigger update)
# ═══════════════════════════════════════════════════════════════════════════════

func test_speed_setter_noop_on_same_value():
	var original = _node._speed
	_node.speed = original
	assert_eq(_node._speed, original)

func test_speed_mode_setter_noop_on_same_value():
	var original = _node._speed_mode
	_node.speed_mode = original
	assert_eq(_node._speed_mode, original)

func test_cardinal_speed_setter_noop_on_same_value():
	var original = _node._cardinal_speed_right
	_node.cardinal_speed_right = original
	assert_eq(_node._cardinal_speed_right, original)

func test_mouse_deadzone_setter_noop_on_same_value():
	var original = _node._mouse_deadzone
	_node.mouse_deadzone = original
	assert_eq(_node._mouse_deadzone, original)

func test_touch_deadzone_setter_noop_on_same_value():
	var original = _node._touch_deadzone
	_node.touch_deadzone = original
	assert_eq(_node._touch_deadzone, original)

func test_auto_enable_keyboard_setter_noop_on_same_value():
	var original = _node._auto_enable_keyboard
	_node.auto_enable_keyboard = original
	assert_eq(_node._auto_enable_keyboard, original)


# ═══════════════════════════════════════════════════════════════════════════════
# MovementType ENUM VALUES
# ═══════════════════════════════════════════════════════════════════════════════

func test_movement_type_stopped_is_zero():
	assert_eq(NilDevMovement2D.MovementType.STOPPED, 0)

func test_movement_type_horizontal_is_one():
	assert_eq(NilDevMovement2D.MovementType.HORIZONTAL, 1)

func test_movement_type_vertical_is_two():
	assert_eq(NilDevMovement2D.MovementType.VERTICAL, 2)
