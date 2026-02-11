extends Node
class_name NilDevKeyboardInput2D

func get_normalized_input_vector() -> Vector2:
	var v := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		v.x += 1
	if Input.is_action_pressed("move_left"):
		v.x -= 1
	if Input.is_action_pressed("move_down"):
		v.y += 1
	if Input.is_action_pressed("move_up"):
		v.y -= 1
        
	return v.normalized()