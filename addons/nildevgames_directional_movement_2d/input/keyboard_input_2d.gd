@icon("res://addons/nildevgames_directional_movement_2d/icons/keyboard_input_2d_icon.svg")
class_name NilDevKeyboardInput2D
extends NilDevDirectionalInput2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func get_input_vector() -> Vector2:
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