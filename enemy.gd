extends PlatformerController2D

class_name Enemy2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var direction = 1  # 1 for moving right, -1 for moving left

@onready var _animated_sprite = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	_animated_sprite.play("idle")
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	velocity.x = direction * SPEED

	move_and_slide()

func _on_screenEdge():
	direction *= -1
