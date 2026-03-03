extends GutTest
## Unit tests for NilDevKeyboardInput2D.
##
## Input actions are registered dynamically via InputMap since they are not
## defined in project.godot — the library expects users to set them up.

var _node: NilDevKeyboardInput2D

const ACTIONS = ["move_right", "move_left", "move_up", "move_down"]


func before_all():
	for action_name in ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var ev = InputEventKey.new()
			match action_name:
				"move_right": ev.keycode = KEY_D
				"move_left":  ev.keycode = KEY_A
				"move_up":    ev.keycode = KEY_W
				"move_down":  ev.keycode = KEY_S
			InputMap.action_add_event(action_name, ev)


func after_all():
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)


func before_each():
	_node = NilDevKeyboardInput2D.new()
	add_child_autofree(_node)


func after_each():
	# Release all actions to avoid contaminating other tests
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)


# ── Default state ─────────────────────────────────────────────────────────────

func test_default_input_vector_is_zero():
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "No keys → ZERO vector")

func test_default_is_pressed_is_false():
	assert_false(_node.is_pressed, "No keys → is_pressed false")

func test_ready_sets_process_mode_disabled():
	assert_eq(_node.process_mode, Node.PROCESS_MODE_DISABLED,
		"process_mode should be DISABLED after _ready")


# ── Single directions ─────────────────────────────────────────────────────────

func test_move_right():
	Input.action_press("move_right")
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.001, 0.001), "Right → (1, 0)")

func test_move_left():
	Input.action_press("move_left")
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(-1, 0), Vector2(0.001, 0.001), "Left → (-1, 0)")

func test_move_down():
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, 1), Vector2(0.001, 0.001), "Down → (0, 1)")

func test_move_up():
	Input.action_press("move_up")
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(0, -1), Vector2(0.001, 0.001), "Up → (0, -1)")


# ── Diagonal input ────────────────────────────────────────────────────────────

func test_diagonal_right_down():
	Input.action_press("move_right")
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	var expected = Vector2(1, 1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Right+Down → normalized diagonal")

func test_diagonal_left_up():
	Input.action_press("move_left")
	Input.action_press("move_up")
	var v = _node.get_input_vector()
	var expected = Vector2(-1, -1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Left+Up → normalized diagonal")

func test_diagonal_right_up():
	Input.action_press("move_right")
	Input.action_press("move_up")
	var v = _node.get_input_vector()
	var expected = Vector2(1, -1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Right+Up → normalized diagonal")

func test_diagonal_left_down():
	Input.action_press("move_left")
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	var expected = Vector2(-1, 1).normalized()
	assert_almost_eq(v, expected, Vector2(0.001, 0.001), "Left+Down → normalized diagonal")


# ── Opposing inputs cancel out ────────────────────────────────────────────────

func test_opposing_horizontal():
	Input.action_press("move_right")
	Input.action_press("move_left")
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "Right+Left should cancel to ZERO")

func test_opposing_vertical():
	Input.action_press("move_up")
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "Up+Down should cancel to ZERO")

func test_all_four_directions_cancel():
	Input.action_press("move_right")
	Input.action_press("move_left")
	Input.action_press("move_up")
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	assert_eq(v, Vector2.ZERO, "All four directions should cancel to ZERO")


# ── is_pressed ────────────────────────────────────────────────────────────────

func test_is_pressed_single_action():
	Input.action_press("move_right")
	assert_true(_node.is_pressed, "is_pressed true when right is pressed")

func test_is_pressed_multiple_actions():
	Input.action_press("move_right")
	Input.action_press("move_up")
	assert_true(_node.is_pressed, "is_pressed true when multiple actions pressed")

func test_is_pressed_false_after_release():
	Input.action_press("move_right")
	Input.action_release("move_right")
	assert_false(_node.is_pressed, "is_pressed false after releasing only action")

func test_is_pressed_true_with_partial_release():
	Input.action_press("move_right")
	Input.action_press("move_up")
	Input.action_release("move_right")
	assert_true(_node.is_pressed, "is_pressed still true if one action remains pressed")


# ── Normalization ─────────────────────────────────────────────────────────────

func test_single_direction_length_is_one():
	Input.action_press("move_right")
	var v = _node.get_input_vector()
	assert_almost_eq(v.length(), 1.0, 0.001, "Single direction vector length should be 1.0")

func test_diagonal_length_is_one():
	Input.action_press("move_right")
	Input.action_press("move_down")
	var v = _node.get_input_vector()
	assert_almost_eq(v.length(), 1.0, 0.001, "Diagonal vector should be normalized to length 1.0")
