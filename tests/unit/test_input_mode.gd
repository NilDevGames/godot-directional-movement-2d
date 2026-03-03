extends GutTest
## Unit tests for NilDevInputMode enum.

func test_keyboard_value_is_zero():
	assert_eq(NilDevInputMode.Mode.KEYBOARD, 0, "KEYBOARD should be 0")

func test_mouse_value_is_one():
	assert_eq(NilDevInputMode.Mode.MOUSE, 1, "MOUSE should be 1")

func test_touch_value_is_two():
	assert_eq(NilDevInputMode.Mode.TOUCH, 2, "TOUCH should be 2")

func test_auto_value_is_three():
	assert_eq(NilDevInputMode.Mode.AUTO, 3, "AUTO should be 3")

func test_enum_has_four_values():
	assert_eq(NilDevInputMode.Mode.size(), 4, "Mode enum should have exactly 4 values")
