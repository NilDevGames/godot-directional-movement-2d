extends GutTest
## Unit tests for NilDevKeyboardInput2D.
##
## Default keyboard actions are auto-created when missing and can be overridden
## per node via exported action-name properties.

const KeyboardActions = preload("res://addons/nildevgames_directional_movement_2d/internals/keyboard_actions_2d.gd")

const ACTION_RIGHT := KeyboardActions.DEFAULT_MOVE_RIGHT_ACTION
const ACTION_LEFT := KeyboardActions.DEFAULT_MOVE_LEFT_ACTION
const ACTION_UP := KeyboardActions.DEFAULT_MOVE_UP_ACTION
const ACTION_DOWN := KeyboardActions.DEFAULT_MOVE_DOWN_ACTION
const ACTIONS: Array[StringName] = [ACTION_RIGHT, ACTION_LEFT, ACTION_UP, ACTION_DOWN]

var _node: NilDevKeyboardInput2D
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
	_node = NilDevKeyboardInput2D.new()
	add_child_autofree(_node)


func after_each():
	for action_name in _release_actions:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)


func _remember_owned_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name) and not _owned_actions.has(action_name):
		_owned_actions.append(action_name)
	if not _release_actions.has(action_name):
		_release_actions.append(action_name)


func _action_has_physical_key(action_name: StringName, key_code: int) -> bool:
	if not InputMap.has_action(action_name):
		return false

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == key_code:
			return true

	return false


# ── Default state ─────────────────────────────────────────────────────────────

func test_default_action_names_are_prefixed():
	assert_eq(_node.move_right_action, ACTION_RIGHT)
	assert_eq(_node.move_left_action, ACTION_LEFT)
	assert_eq(_node.move_up_action, ACTION_UP)
	assert_eq(_node.move_down_action, ACTION_DOWN)

func test_default_actions_include_wasd_and_arrows():
	assert_true(_action_has_physical_key(ACTION_RIGHT, KEY_D))
	assert_true(_action_has_physical_key(ACTION_RIGHT, KEY_RIGHT))
	assert_true(_action_has_physical_key(ACTION_LEFT, KEY_A))
	assert_true(_action_has_physical_key(ACTION_LEFT, KEY_LEFT))
	assert_true(_action_has_physical_key(ACTION_UP, KEY_W))
	assert_true(_action_has_physical_key(ACTION_UP, KEY_UP))
	assert_true(_action_has_physical_key(ACTION_DOWN, KEY_S))
	assert_true(_action_has_physical_key(ACTION_DOWN, KEY_DOWN))

func test_default_input_vector_is_zero():
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "No keys → ZERO vector")

func test_default_is_pressed_is_false():
	assert_false(_node.is_pressed, "No keys → is_pressed false")

func test_ready_sets_process_mode_disabled():
	assert_eq(_node.process_mode, Node.PROCESS_MODE_DISABLED,
		"process_mode should be DISABLED after _ready")

func test_ready_registers_missing_custom_actions():
	var custom_right := StringName("nildevgames_test_keyboard_right_%s" % get_instance_id())
	var custom_left := StringName("nildevgames_test_keyboard_left_%s" % get_instance_id())
	var custom_up := StringName("nildevgames_test_keyboard_up_%s" % get_instance_id())
	var custom_down := StringName("nildevgames_test_keyboard_down_%s" % get_instance_id())
	_remember_owned_action(custom_right)
	_remember_owned_action(custom_left)
	_remember_owned_action(custom_up)
	_remember_owned_action(custom_down)

	var custom_node := NilDevKeyboardInput2D.new()
	custom_node.move_right_action = custom_right
	custom_node.move_left_action = custom_left
	custom_node.move_up_action = custom_up
	custom_node.move_down_action = custom_down
	add_child_autofree(custom_node)

	assert_true(InputMap.has_action(custom_right))
	assert_true(InputMap.has_action(custom_left))
	assert_true(InputMap.has_action(custom_up))
	assert_true(InputMap.has_action(custom_down))
	assert_true(_action_has_physical_key(custom_right, KEY_D))
	assert_true(_action_has_physical_key(custom_right, KEY_RIGHT))

	Input.action_press(custom_right)
	var v = custom_node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001), "Custom right action should drive rightward movement")

func test_existing_custom_action_is_not_overwritten():
	var custom_right := StringName("nildevgames_test_existing_keyboard_right_%s" % get_instance_id())
	_remember_owned_action(custom_right)
	if not InputMap.has_action(custom_right):
		InputMap.add_action(custom_right)
	var existing_event := InputEventKey.new()
	existing_event.physical_keycode = KEY_L
	InputMap.action_add_event(custom_right, existing_event)

	var custom_node := NilDevKeyboardInput2D.new()
	custom_node.move_right_action = custom_right
	add_child_autofree(custom_node)

	var events = InputMap.action_get_events(custom_right)
	assert_eq(events.size(), 1, "Existing custom action should keep its original event list")
	assert_true(_action_has_physical_key(custom_right, KEY_L))
	assert_false(_action_has_physical_key(custom_right, KEY_D))
	assert_false(_action_has_physical_key(custom_right, KEY_RIGHT))


# ── Single directions ─────────────────────────────────────────────────────────

func test_move_right():
	Input.action_press(ACTION_RIGHT)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001), "Right → (1, 0)")

func test_move_left():
	Input.action_press(ACTION_LEFT)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(-1, 0), Vector2(0.001, 0.001), "Left → (-1, 0)")

func test_move_down():
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, 1), Vector2(0.001, 0.001), "Down → (0, 1)")

func test_move_up():
	Input.action_press(ACTION_UP)
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, -1), Vector2(0.001, 0.001), "Up → (0, -1)")


# ── Diagonal input ────────────────────────────────────────────────────────────

func test_diagonal_right_down():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	var expected = Vector2(1, 1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Right+Down → normalized diagonal")

func test_diagonal_left_up():
	Input.action_press(ACTION_LEFT)
	Input.action_press(ACTION_UP)
	var v = _node.get_input_vector()
	var expected = Vector2(-1, -1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Left+Up → normalized diagonal")

func test_diagonal_right_up():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_UP)
	var v = _node.get_input_vector()
	var expected = Vector2(1, -1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Right+Up → normalized diagonal")

func test_diagonal_left_down():
	Input.action_press(ACTION_LEFT)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	var expected = Vector2(-1, 1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Left+Down → normalized diagonal")


# ── Opposing inputs cancel out ────────────────────────────────────────────────

func test_opposing_horizontal():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_LEFT)
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "Right+Left should cancel to ZERO")

func test_opposing_vertical():
	Input.action_press(ACTION_UP)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "Up+Down should cancel to ZERO")

func test_all_four_directions_cancel():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_LEFT)
	Input.action_press(ACTION_UP)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "All four directions should cancel to ZERO")


# ── is_pressed ────────────────────────────────────────────────────────────────

func test_is_pressed_single_action():
	Input.action_press(ACTION_RIGHT)
	assert_true(_node.is_pressed, "is_pressed true when right is pressed")

func test_is_pressed_multiple_actions():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_UP)
	assert_true(_node.is_pressed, "is_pressed true when multiple actions pressed")

func test_is_pressed_false_after_release():
	Input.action_press(ACTION_RIGHT)
	Input.action_release(ACTION_RIGHT)
	assert_false(_node.is_pressed, "is_pressed false after releasing only action")

func test_is_pressed_true_with_partial_release():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_UP)
	Input.action_release(ACTION_RIGHT)
	assert_true(_node.is_pressed, "is_pressed still true if one action remains pressed")


# ── Normalization ─────────────────────────────────────────────────────────────

func test_single_direction_length_is_one():
	Input.action_press(ACTION_RIGHT)
	var v = _node.get_input_vector()
	assert_almost_eq(v.length(), 1.0, 0.001, "Single direction vector length should be 1.0")

func test_diagonal_length_is_one():
	Input.action_press(ACTION_RIGHT)
	Input.action_press(ACTION_DOWN)
	var v = _node.get_input_vector()
	assert_almost_eq(v.length(), 1.0, 0.001, "Diagonal vector should be normalized to length 1.0")
