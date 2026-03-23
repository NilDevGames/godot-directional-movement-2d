extends CharacterBody2D

const PLAYER_RADIUS := 20.0
const ExamplePerformancePanel = preload("res://examples/example_performance_panel.gd")

@onready var mover: NilDevMovement2D = $NilDevMovement2D
@onready var visuals: Node2D = $Visuals
@onready var status_label: Label = $Hud/StatusLabel

var _performance_panel = ExamplePerformancePanel.new()


func _ready() -> void:
	position = get_viewport_rect().size * 0.5
	_performance_panel.setup(get_viewport())
	_update_status()


func _physics_process(delta: float) -> void:
	velocity = mover.calculate_velocity()
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
	status_label.text = "CharacterBody2D example\nMovement API: calculate_velocity()\nMove: WASD / Arrow keys\nDrag: Left mouse button or touch\nInput: (%.2f, %.2f)\nVelocity: (%.1f, %.1f)\n\n%s" % [
		input_vector.x,
		input_vector.y,
		velocity.x,
		velocity.y,
		_performance_panel.get_text(),
	]