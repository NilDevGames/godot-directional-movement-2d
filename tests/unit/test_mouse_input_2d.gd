extends GutTest
## Unit tests for NilDevMouseInput2D.
##
## We craft InputEvent* objects and feed them directly to _input() to verify
## the node routes mouse events to the DragBasedInput2D base correctly.

var _node: NilDevMouseInput2D


func before_each():
	_node = NilDevMouseInput2D.new()
	add_child_autofree(_node)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_mouse_button(pos: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var ev = InputEventMouseButton.new()
	ev.position = pos
	ev.pressed = pressed
	ev.button_index = button
	return ev


func _make_mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var ev = InputEventMouseMotion.new()
	ev.position = pos
	return ev


# ── Left mouse button starts/stops drag ──────────────────────────────────────

func test_left_press_starts_drag():
	var pos = Vector2(100, 100)
	_node._input(_make_mouse_button(pos, true))
	assert_true(_node._dragging, "Left press should start dragging")
	assert_eq(_node._drag_origin, pos, "Drag origin should match press position")

func test_left_release_stops_drag():
	_node._input(_make_mouse_button(Vector2(100, 100), true))
	_node._input(_make_mouse_button(Vector2(100, 100), false))
	assert_false(_node._dragging, "Left release should stop dragging")
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Input vector should be ZERO after release")


# ── Mouse motion while dragging updates vector ───────────────────────────────

func test_motion_while_dragging_updates_vector():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	_node._input(_make_mouse_button(origin, true))
	_node._input(_make_mouse_motion(Vector2(200, 100)))

	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "X should be positive for rightward drag")
	assert_almost_eq(v.y, 0.0, 0.001, "Y should be near zero for horizontal drag")

func test_motion_while_not_dragging_is_ignored():
	_node._input(_make_mouse_motion(Vector2(200, 200)))
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Motion without drag should be ignored")


# ── Non-left buttons are ignored ──────────────────────────────────────────────

func test_right_button_ignored():
	_node._input(_make_mouse_button(Vector2(100, 100), true, MOUSE_BUTTON_RIGHT))
	assert_false(_node._dragging, "Right button should not start drag")

func test_middle_button_ignored():
	_node._input(_make_mouse_button(Vector2(100, 100), true, MOUSE_BUTTON_MIDDLE))
	assert_false(_node._dragging, "Middle button should not start drag")


# ── Full drag sequence ────────────────────────────────────────────────────────

func test_full_drag_sequence():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)

	# Press
	_node._input(_make_mouse_button(origin, true))
	assert_true(_node.is_pressed, "Should be pressed after click")

	# Drag right
	_node._input(_make_mouse_motion(Vector2(200, 100)))
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.01, 0.01),
		"Full-radius rightward drag should yield (1, 0)")

	# Drag up-right
	_node._input(_make_mouse_motion(Vector2(200, 0)))
	v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "X should be positive")
	assert_lt(v.y, 0.0, "Y should be negative (upward)")

	# Release
	_node._input(_make_mouse_button(Vector2(200, 0), false))
	assert_false(_node.is_pressed, "Should not be pressed after release")
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Vector should be ZERO after release")


# ── Drag vector direction and magnitude ───────────────────────────────────────

func test_drag_downward():
	var origin = Vector2(100, 100)
	_node._input(_make_mouse_button(origin, true))
	_node._input(_make_mouse_motion(Vector2(100, 200)))

	var v = _node.get_input_vector()
	assert_almost_eq(v.x, 0.0, 0.001, "Vertical drag should have near-zero X")
	assert_gt(v.y, 0.0, "Y should be positive for downward drag")

func test_drag_leftward():
	var origin = Vector2(200, 100)
	_node._input(_make_mouse_button(origin, true))
	_node._input(_make_mouse_motion(Vector2(100, 100)))

	var v = _node.get_input_vector()
	assert_lt(v.x, 0.0, "X should be negative for leftward drag")
	assert_almost_eq(v.y, 0.0, 0.001, "Y should be near zero for horizontal drag")


# ── Multiple press/release cycles ────────────────────────────────────────────

func test_second_drag_after_release():
	var origin1 = Vector2(100, 100)
	var origin2 = Vector2(200, 200)

	# First cycle
	_node._input(_make_mouse_button(origin1, true))
	_node._input(_make_mouse_motion(Vector2(200, 100)))
	_node._input(_make_mouse_button(Vector2(200, 100), false))
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Should be zero after first release")

	# Second cycle
	_node._input(_make_mouse_button(origin2, true))
	assert_eq(_node._drag_origin, origin2, "New drag should start from new origin")
	_node._input(_make_mouse_motion(Vector2(200, 300)))
	var v = _node.get_input_vector()
	assert_ne(v, Vector2.ZERO, "Second drag should produce non-zero vector")
