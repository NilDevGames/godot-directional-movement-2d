extends GutTest
## Unit tests for NilDevSpeedMode enum.

func test_uniform_value_is_zero():
	assert_eq(NilDevSpeedMode.Mode.UNIFORM, 0, "UNIFORM should be 0")

func test_cardinal_value_is_one():
	assert_eq(NilDevSpeedMode.Mode.CARDINAL, 1, "CARDINAL should be 1")

func test_enum_has_two_values():
	assert_eq(NilDevSpeedMode.Mode.size(), 2, "Mode enum should have exactly 2 values")