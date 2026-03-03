extends GutTest
## Unit tests for NilDevDragBasedInput2D.
##
## Since NilDevDragBasedInput2D is abstract, we use NilDevMouseInput2D as a
## concrete subclass. All drag/pause/resume/deadzone logic lives in the base
## and is exercised here without routing through _input().

var _node: NilDevMouseInput2D


func before_each():
	_node = NilDevMouseInput2D.new()
	add_child_autofree(_node)


# ── Default state ─────────────────────────────────────────────────────────────

func test_default_deadzone():
	assert_eq(_node.deadzone, 10.0, "Default deadzone should be 10.0")

func test_default_max_radius():
	assert_eq(_node.max_radius, 100.0, "Default max_radius should be 100.0")

func test_default_stop_drag_if_input_stopped():
	assert_true(_node.stop_drag_if_input_stopped, "Default stop_drag_if_input_stopped should be true")

func test_default_motion_timeout():
	assert_eq(_node.motion_timeout, 0.1, "Default motion_timeout should be 0.1")

func test_default_is_pressed_is_false():
	assert_false(_node.is_pressed, "is_pressed should be false by default")

func test_default_input_vector_is_zero():
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Default input vector should be ZERO")

func test_default_dragging_is_false():
	assert_false(_node._dragging, "_dragging should be false by default")

func test_default_paused_is_false():
	assert_false(_node._paused, "_paused should be false by default")


# ── _start_drag ───────────────────────────────────────────────────────────────

func test_start_drag_sets_dragging():
	_node._start_drag(Vector2(50, 50))
	assert_true(_node._dragging, "_dragging should be true after _start_drag")

func test_start_drag_sets_origin():
	var pos = Vector2(123, 456)
	_node._start_drag(pos)
	assert_eq(_node._drag_origin, pos, "Drag origin should match provided position")

func test_start_drag_enables_physics_process_when_stop_drag_enabled():
	_node.stop_drag_if_input_stopped = true
	_node._start_drag(Vector2.ZERO)
	assert_true(_node.is_physics_processing(), "Physics process should be enabled")

func test_start_drag_disables_physics_process_when_stop_drag_disabled():
	_node.stop_drag_if_input_stopped = false
	_node._start_drag(Vector2.ZERO)
	assert_false(_node.is_physics_processing(), "Physics process should stay disabled")


# ── _stop_drag ────────────────────────────────────────────────────────────────

func test_stop_drag_clears_dragging():
	_node._start_drag(Vector2.ZERO)
	_node._stop_drag()
	assert_false(_node._dragging, "_dragging should be false after _stop_drag")

func test_stop_drag_clears_input_vector():
	_node._start_drag(Vector2.ZERO)
	_node._update_drag(Vector2(200, 0))
	_node._stop_drag()
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Input vector should be ZERO after _stop_drag")

func test_stop_drag_disables_physics_process():
	_node._start_drag(Vector2.ZERO)
	_node._stop_drag()
	assert_false(_node.is_physics_processing(), "Physics process should be disabled after _stop_drag")

func test_stop_drag_resets_last_motion_time():
	_node._start_drag(Vector2.ZERO)
	_node._update_drag(Vector2(200, 0))
	_node._stop_drag()
	assert_eq(_node._last_motion_time, -1.0, "_last_motion_time should be -1.0 after _stop_drag")


# ── is_pressed ────────────────────────────────────────────────────────────────

func test_is_pressed_true_when_dragging_and_not_paused():
	_node._start_drag(Vector2.ZERO)
	assert_true(_node.is_pressed, "is_pressed should be true while dragging")

func test_is_pressed_false_when_not_dragging():
	assert_false(_node.is_pressed, "is_pressed should be false when not dragging")

func test_is_pressed_false_when_paused():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	assert_false(_node.is_pressed, "is_pressed should be false when paused")


# ── _update_drag – vector math ────────────────────────────────────────────────

func test_update_drag_zero_distance():
	var origin = Vector2(100, 100)
	_node._start_drag(origin)
	_node._update_drag(origin)
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Zero distance should produce ZERO vector")

func test_update_drag_within_deadzone_partial_strength():
	_node.deadzone = 10.0
	var origin = Vector2(100, 100)
	var target = Vector2(105, 100)  # distance = 5, half of deadzone
	_node._start_drag(origin)
	_node._update_drag(target)

	var expected_strength = 5.0 / 10.0  # 0.5
	var expected = Vector2(1, 0) * expected_strength
	assert_almost_eq(_node.get_input_vector(), expected, Vector2(0.001, 0.001),
		"Within deadzone → normalized * (distance / deadzone)")

func test_update_drag_at_deadzone_boundary():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(110, 100)  # distance = 10 (== deadzone)
	_node._start_drag(origin)
	_node._update_drag(target)

	# distance == deadzone → enters the else branch: strength = min(10,100)/100 = 0.1
	var expected_strength = 10.0 / 100.0
	var expected = Vector2(1, 0) * expected_strength
	assert_almost_eq(_node.get_input_vector(), expected, Vector2(0.001, 0.001),
		"At deadzone boundary → strength = deadzone / max_radius")

func test_update_drag_between_deadzone_and_max_radius():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(150, 100)  # distance = 50
	_node._start_drag(origin)
	_node._update_drag(target)

	var expected_strength = 50.0 / 100.0  # 0.5
	var expected = Vector2(1, 0) * expected_strength
	assert_almost_eq(_node.get_input_vector(), expected, Vector2(0.001, 0.001),
		"Between deadzone and max_radius → distance / max_radius")

func test_update_drag_at_max_radius():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(200, 100)  # distance = 100 (== max_radius)
	_node._start_drag(origin)
	_node._update_drag(target)

	var expected = Vector2(1, 0)  # full strength
	assert_almost_eq(_node.get_input_vector(), expected, Vector2(0.001, 0.001),
		"At max_radius → full strength (1.0)")

func test_update_drag_beyond_max_radius_is_clamped():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(300, 100)  # distance = 200 > max_radius
	_node._start_drag(origin)
	_node._update_drag(target)

	var expected = Vector2(1, 0)  # clamped to 1.0
	assert_almost_eq(_node.get_input_vector(), expected, Vector2(0.001, 0.001),
		"Beyond max_radius → clamped to 1.0")

func test_update_drag_diagonal_direction_preserved():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(200, 200)  # diagonal, distance ≈ 141.42
	_node._start_drag(origin)
	_node._update_drag(target)

	var v = _node.get_input_vector()
	# Direction should be (1,1).normalized = (0.7071, 0.7071)
	var expected_dir = Vector2(1, 1).normalized()
	assert_almost_eq(v.normalized(), expected_dir, Vector2(0.001, 0.001),
		"Diagonal direction should be preserved")
	# Strength is clamped: min(141.42, 100) / 100 = 1.0
	assert_almost_eq(v.length(), 1.0, 0.01, "Strength should be clamped to 1.0")

func test_update_drag_negative_direction():
	_node.deadzone = 10.0
	_node.max_radius = 100.0
	var origin = Vector2(100, 100)
	var target = Vector2(50, 100)  # distance = 50, direction left
	_node._start_drag(origin)
	_node._update_drag(target)

	var v = _node.get_input_vector()
	assert_lt(v.x, 0.0, "X should be negative for leftward drag")
	assert_almost_eq(v.y, 0.0, 0.001, "Y should be near zero for pure horizontal drag")

func test_update_drag_last_motion_time_not_updated_within_deadzone():
	_node.deadzone = 10.0
	var origin = Vector2(100, 100)
	_node._start_drag(origin)
	_node._update_drag(Vector2(105, 100))  # distance = 5 < deadzone
	assert_eq(_node._last_motion_time, -1.0,
		"_last_motion_time should stay -1 when dragging within deadzone")

func test_update_drag_last_motion_time_updated_beyond_deadzone():
	_node.deadzone = 10.0
	var origin = Vector2(100, 100)
	_node._start_drag(origin)
	_node._update_drag(Vector2(200, 100))  # distance = 100 > deadzone
	assert_ne(_node._last_motion_time, -1.0,
		"_last_motion_time should be updated when dragging beyond deadzone")


# ── _pause / _resume ──────────────────────────────────────────────────────────

func test_pause_sets_paused():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	assert_true(_node._paused, "_paused should be true after _pause")

func test_pause_clears_input_vector():
	_node._start_drag(Vector2.ZERO)
	_node._update_drag(Vector2(200, 0))
	_node._pause()
	assert_eq(_node.get_input_vector(), Vector2.ZERO, "Input vector should be ZERO after pause")

func test_pause_disables_physics_process():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	assert_false(_node.is_physics_processing(), "Physics process should be disabled after pause")

func test_resume_clears_paused():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	_node._resume(Vector2(50, 50))
	assert_false(_node._paused, "_paused should be false after _resume")

func test_resume_resets_drag_origin():
	_node._start_drag(Vector2(10, 10))
	_node._pause()
	var new_pos = Vector2(200, 200)
	_node._resume(new_pos)
	assert_eq(_node._drag_origin, new_pos, "Drag origin should be updated on resume")

func test_resume_updates_last_motion_time():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	_node._resume(Vector2(50, 50))
	assert_ne(_node._last_motion_time, -1.0,
		"_last_motion_time should be updated on resume")

func test_update_drag_auto_resumes_when_paused():
	_node._start_drag(Vector2.ZERO)
	_node._pause()
	assert_true(_node._paused, "Should be paused before _update_drag")
	_node._update_drag(Vector2(200, 0))
	assert_false(_node._paused, "_update_drag should auto-resume when paused")


# ── Deadzone timeout (intentional behavior) ──────────────────────────────────

func test_timeout_does_not_trigger_if_only_dragged_within_deadzone():
	# _last_motion_time stays -1 when dragging within deadzone, so
	# _physics_process's guard `_last_motion_time != -1.0` prevents pausing.
	_node.deadzone = 50.0
	_node.stop_drag_if_input_stopped = true
	_node.motion_timeout = 0.1
	_node._start_drag(Vector2(100, 100))
	_node._update_drag(Vector2(110, 100))  # distance 10 < deadzone 50 → _last_motion_time stays -1

	assert_eq(_node._last_motion_time, -1.0,
		"_last_motion_time should be -1 after within-deadzone drag")
	# Manually call _physics_process with a large delta to simulate time passing
	_node._physics_process(1.0)
	assert_false(_node._paused, "Should NOT pause when _last_motion_time is -1 (no beyond-deadzone motion)")


# ── Configuration warnings ────────────────────────────────────────────────────

func test_warning_negative_deadzone():
	_node._deadzone = -1.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Deadzone cannot be negative.")

func test_warning_small_max_radius():
	_node._max_radius = 5.0
	var w = _node._get_configuration_warnings()
	assert_has(w, "Max radius should be at least 10 to allow for meaningful input.")

func test_warning_small_motion_timeout():
	_node._motion_timeout = 0.05
	var w = _node._get_configuration_warnings()
	assert_has(w, "Motion timeout should be at least 0.1 seconds.")

func test_no_warnings_with_valid_config():
	_node._deadzone = 10.0
	_node._max_radius = 100.0
	_node._motion_timeout = 0.1
	var w = _node._get_configuration_warnings()
	assert_eq(w.size(), 0, "There should be no warnings with valid configuration")


# ── _validate_property ────────────────────────────────────────────────────────

func test_motion_timeout_hidden_when_stop_drag_disabled():
	_node.stop_drag_if_input_stopped = false
	var prop = {"name": "motion_timeout", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_NO_EDITOR,
		"motion_timeout should be hidden when stop_drag_if_input_stopped is false")

func test_motion_timeout_visible_when_stop_drag_enabled():
	_node.stop_drag_if_input_stopped = true
	var prop = {"name": "motion_timeout", "usage": PROPERTY_USAGE_DEFAULT}
	_node._validate_property(prop)
	assert_eq(prop.usage, PROPERTY_USAGE_DEFAULT,
		"motion_timeout should stay visible when stop_drag_if_input_stopped is true")


# ── Property setters (no-op on same value) ────────────────────────────────────

func test_deadzone_setter_no_op_on_same_value():
	var original = _node._deadzone
	_node.deadzone = original  # same value
	assert_eq(_node._deadzone, original, "Setter should no-op when value unchanged")

func test_max_radius_setter_no_op_on_same_value():
	var original = _node._max_radius
	_node.max_radius = original
	assert_eq(_node._max_radius, original)

func test_deadzone_setter_updates_value():
	_node.deadzone = 25.0
	assert_eq(_node._deadzone, 25.0, "Setter should update backing field")

func test_max_radius_setter_updates_value():
	_node.max_radius = 200.0
	assert_eq(_node._max_radius, 200.0)

func test_motion_timeout_setter_updates_value():
	_node.motion_timeout = 0.5
	assert_eq(_node._motion_timeout, 0.5)


# ── _ready disables unused processing ────────────────────────────────────────

func test_ready_disables_process():
	assert_false(_node.is_processing(), "process should be disabled after _ready")

func test_ready_disables_physics_process():
	# Physics process starts disabled; _start_drag may enable it
	assert_false(_node.is_physics_processing(), "physics_process should be disabled initially")

func test_ready_enables_input_processing():
	assert_true(_node.is_processing_input(), "input processing should be enabled after _ready")
