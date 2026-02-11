@tool
extends EditorPlugin

func _enter_tree() -> void:
	var keyboard_input_2d_script := preload("res://addons/nildevgames_directional_movement_2d/input/keyboard_input_2d.gd")
	add_custom_type("NilDevKeyboardInput2D", "Node", keyboard_input_2d_script, null)
	print("NilDevGames Directional Movement 2D plugin loaded.")

func _exit_tree() -> void:
	remove_custom_type("NilDevKeyboardInput2D")
	print("NilDevGames Directional Movement 2D plugin unloaded.")