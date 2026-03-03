extends GutTest
## Unit tests for NilDevTouchInput2D.
##
## We craft InputEventScreenTouch / InputEventScreenDrag objects and feed them
## directly to _input() to verify the node routes touch events correctly.

var _node: NilDevTouchInput2D


func before_each():
	_node = NilDevTouchInput2D.new()
	add_child_autofree(_node)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_screen_touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev = InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	return ev


func _make_screen_drag(pos: Vector2) -> InputEventScreenDrag:
	var ev = InputEventScreenDrag.new()
	ev.position = pos
	return ev


# ── Screen touch starts/stops drag ───────────────────────────────────────────

func test_touch_press_starts_drag():
	var pos = Vector2(100, 100)
	_node._input(_make_screen_touch(pos, true))
	assert_true(_node._dragging, "Touch press should start dragging")
	assert_eq(_node._drag_origin, pos, "Drag origin should match touch position")

func test_touch_release_stops_drag():
	_node._input(_make_screen_touch(Vector2(100, 100), true))
	_node._input(_make_screen_touch(Vector2(100, 100), false))
	assert_false(_node._dragging, "Touch release should stop dragging")
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Input vector should be ZERO after release")


# ── Screen drag while dragging updates vector ────────────────────────────────

func test_drag_while_touching_updates_vector():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	_node._input(_make_screen_touch(origin, true))
	_node._input(_make_screen_drag(Vector2(200, 100)))

	var v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "X should be positive for rightward drag")
	assert_almost_eq(v.y, 0.0, 0.001, "Y should be near zero for horizontal drag")

func test_drag_while_not_touching_is_ignored():
	_node._input(_make_screen_drag(Vector2(200, 200)))
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Drag without touch should be ignored")


# ── Full touch sequence ──────────────────────────────────────────────────────

func test_full_touch_sequence():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)

	# Touch down
	_node._input(_make_screen_touch(origin, true))
	assert_true(_node.is_pressed, "Should be pressed after touch")

	# Drag right
	_node._input(_make_screen_drag(Vector2(200, 100)))
	var v = _node.get_input_vector()
	assert_almost_eq(v, Vector2(1, 0), Vector2(0.01, 0.01),
		"Full-radius rightward drag should yield (1, 0)")

	# Drag diagonal
	_node._input(_make_screen_drag(Vector2(200, 0)))
	v = _node.get_input_vector()
	assert_gt(v.x, 0.0, "X should be positive")
	assert_lt(v.y, 0.0, "Y should be negative (upward)")

	# Release
	_node._input(_make_screen_touch(Vector2(200, 0), false))
	assert_false(_node.is_pressed, "Should not be pressed after release")
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Vector should be ZERO after release")


# ── Drag vector direction ────────────────────────────────────────────────────

func test_drag_downward():
	var origin = Vector2(100, 100)
	_node._input(_make_screen_touch(origin, true))
	_node._input(_make_screen_drag(Vector2(100, 200)))

	var v = _node.get_input_vector()
	assert_almost_eq(v.x, 0.0, 0.001, "Vertical drag should have near-zero X")
	assert_gt(v.y, 0.0, "Y should be positive for downward drag")

func test_drag_leftward():
	var origin = Vector2(200, 100)
	_node._input(_make_screen_touch(origin, true))
	_node._input(_make_screen_drag(Vector2(100, 100)))

	var v = _node.get_input_vector()
	assert_lt(v.x, 0.0, "X should be negative for leftward drag")
	assert_almost_eq(v.y, 0.0, 0.001, "Y should be near zero for horizontal drag")

func test_drag_upward():
	var origin = Vector2(100, 200)
	_node._input(_make_screen_touch(origin, true))
	_node._input(_make_screen_drag(Vector2(100, 100)))

	var v = _node.get_input_vector()
	assert_almost_eq(v.x, 0.0, 0.001, "Horizontal component should be near-zero")
	assert_lt(v.y, 0.0, "Y should be negative for upward drag")


# ── Multiple touch cycles ────────────────────────────────────────────────────

func test_second_touch_after_release():
	var origin1 = Vector2(100, 100)
	var origin2 = Vector2(200, 200)

	# First cycle
	_node._input(_make_screen_touch(origin1, true))
	_node._input(_make_screen_drag(Vector2(200, 100)))
	_node._input(_make_screen_touch(Vector2(200, 100), false))
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Should be zero after first release")

	# Second cycle
	_node._input(_make_screen_touch(origin2, true))
	assert_eq(_node._drag_origin, origin2, "New touch should start from new origin")
	_node._input(_make_screen_drag(Vector2(200, 300)))
	var v = _node.get_input_vector()
	assert_ne(v, Vector2.ZERO, "Second drag should produce non-zero vector")


# ── is_pressed tracks touch state ────────────────────────────────────────────

func test_is_pressed_after_touch():
	_node._input(_make_screen_touch(Vector2(100, 100), true))
	assert_true(_node.is_pressed, "is_pressed should be true after touch press")

func test_is_pressed_false_after_release():
	_node._input(_make_screen_touch(Vector2(100, 100), true))
	_node._input(_make_screen_touch(Vector2(100, 100), false))
	assert_false(_node.is_pressed, "is_pressed should be false after release")
