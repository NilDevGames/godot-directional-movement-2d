extends CharacterBody2D

const PLAYER_RADIUS := 20.0

@onready var mover: NilDevMovement2D = $NilDevMovement2D
@onready var visuals: Node2D = $Visuals
@onready var status_label: Label = $Hud/StatusLabel


func _ready() -> void:
	position = get_viewport_rect().size * 0.5
	_update_status()


func _physics_process(delta: float) -> void:
	var displacement := mover.calculate_movement(delta)
	velocity = displacement / delta if delta > 0.0 else Vector2.ZERO
	move_and_slide()
	_clamp_to_viewport()
	if velocity != Vector2.ZERO:
		visuals.rotation = velocity.angle()
	_update_status()


func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	position.x = clampf(position.x, PLAYER_RADIUS, viewport_size.x - PLAYER_RADIUS)
	position.y = clampf(position.y, PLAYER_RADIUS, viewport_size.y - PLAYER_RADIUS)


func _update_status() -> void:
	var input_vector := mover.get_input_vector()
	status_label.text = "CharacterBody2D example\nMove: WASD / Arrow keys\nDrag: Left mouse button or touch\nInput: (%.2f, %.2f)\nVelocity: (%.1f, %.1f)" % [
		input_vector.x,
		input_vector.y,
		velocity.x,
		velocity.y,
	]